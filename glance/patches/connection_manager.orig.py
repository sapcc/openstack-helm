# Copyright 2010-2015 OpenStack Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

"""Connection Manager for Swift connections that responsible for providing
connection with valid credentials and updated token"""

import logging

from keystoneclient import exceptions as ks_exceptions
from oslo_utils import encodeutils

from glance_store import exceptions
from glance_store.i18n import _
from glance_store.i18n import _LI

LOG = logging.getLogger(__name__)


class SwiftConnectionManager(object):
    """Connection Manager class responsible for initializing and managing
    swiftclient connections in store. The instance of that class can provide
    swift connections with a valid(and refreshed) user token if the token is
    going to expire soon.
    """

    AUTH_HEADER_NAME = 'X-Auth-Token'

    def __init__(self, store, store_location, context=None,
                 allow_reauth=False):
        """Initialize manager with parameters required to establish connection.

        Initialize store and prepare it for interacting with swift. Also
        initialize keystone client that need to be used for authentication if
        allow_reauth is True.
        The method invariant is the following: if method was executed
        successfully and self.allow_reauth is True users can safely request
        valid(no expiration) swift connections any time. Otherwise, connection
        manager initialize a connection once and always returns that connection
        to users.

        :param store: store that provides connections
        :param store_location: image location in store
        :param context: user context to access data in Swift
        :param allow_reauth: defines if re-authentication need to be executed
        when a user request the connection
        """
        self._client = None
        self.store = store
        self.location = store_location
        self.context = context
        self.allow_reauth = allow_reauth
        self.storage_url = self._get_storage_url()
        self.connection = self._init_connection()

    def get_connection(self):
        """Get swift client connection.

        Returns swift client connection. If allow_reauth is True and
        connection token is going to expire soon then the method returns
        updated connection.
        The method invariant is the following: if self.allow_reauth is False
        then the method returns the same connection for every call. So the
        connection may expire. If self.allow_reauth is True the returned
        swift connection is always valid and cannot expire at least for
        swift_store_expire_soon_interval.
        """
        if self.allow_reauth:
            # we are refreshing token only and if only connection manager
            # re-authentication is allowed. Token refreshing is setup by
            # connection manager users. Also we disable re-authentication
            # if there is not way to execute it (cannot initialize trusts for
            # multi-tenant or auth_version is not 3)
            auth_ref = self.client.session.auth.get_auth_ref(
                self.client.session)
            # if connection token is going to expire soon (keystone checks
            # is token is going to expire or expired already)
            if auth_ref.will_expire_soon(
                self.store.conf.glance_store.swift_store_expire_soon_interval
            ):
                LOG.info(_LI("Requesting new token for swift connection."))
                # request new token with session and client provided by store
                auth_token = self.client.session.get_auth_headers().get(
                    self.AUTH_HEADER_NAME)
                LOG.info(_LI("Token has been successfully requested. "
                             "Refreshing swift connection."))
                # initialize new switclient connection with fresh token
                self.connection = self.store.get_store_connection(
                    auth_token, self.storage_url)
        return self.connection

    @property
    def client(self):
        """Return keystone client to request a  new token.

        Initialize a client lazily from the method provided by glance_store.
        The method invariant is the following: if client cannot be
        initialized raise exception otherwise return initialized client that
        can be used for re-authentication any time.
        """
        if self._client is None:
            self._client = self._init_client()
        return self._client

    def _init_connection(self):
        """Initialize and return valid Swift connection."""
        auth_token = self.client.session.get_auth_headers().get(
            self.AUTH_HEADER_NAME)
        return self.store.get_store_connection(
            auth_token, self.storage_url)

    def _init_client(self):
        """Initialize Keystone client."""
        return self.store.init_client(location=self.location,
                                      context=self.context)

    def _get_storage_url(self):
        """Request swift storage url."""
        raise NotImplementedError()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass


class SingleTenantConnectionManager(SwiftConnectionManager):
    def _get_storage_url(self):
        """Get swift endpoint from keystone

        Return endpoint for swift from service catalog. The method works only
        Keystone v3. If you are using different version (1 or 2)
        it returns None.
        :return: swift endpoint
        """
        if self.store.auth_version == '3':
            try:
                return self.client.session.get_endpoint(
                    service_type=self.store.service_type,
                    interface=self.store.endpoint_type,
                    region_name=self.store.region
                )
            except Exception as e:
                # do the same that swift driver does
                # when catching ClientException
                msg = _("Cannot find swift service endpoint : "
                        "%s") % encodeutils.exception_to_unicode(e)
                raise exceptions.BackendException(msg)

    def _init_connection(self):
        if self.store.auth_version == '3':
            return super(SingleTenantConnectionManager,
                         self)._init_connection()
        else:
            # no re-authentication for v1 and v2
            self.allow_reauth = False
            # use good old connection initialization
            return self.store.get_connection(self.location, self.context)


class MultiTenantConnectionManager(SwiftConnectionManager):

    def __init__(self, store, store_location, context=None,
                 allow_reauth=False):
        # no context - no party
        if context is None:
            reason = _("Multi-tenant Swift storage requires a user context.")
            raise exceptions.BadStoreConfiguration(store_name="swift",
                                                   reason=reason)
        super(MultiTenantConnectionManager, self).__init__(
            store, store_location, context, allow_reauth)

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self._client and self.client.trust_id:
            # client has been initialized - need to cleanup resources
            LOG.info(_LI("Revoking trust %s"), self.client.trust_id)
            self.client.trusts.delete(self.client.trust_id)

    def _get_storage_url(self):
        try:
            return self.store._get_endpoint(self.context)
        except (exceptions.BadStoreConfiguration,
                ks_exceptions.EndpointNotFound) as e:
            LOG.debug("Cannot obtain endpoint from context: %s. Use location "
                      "value from database to obtain swift_url.", e)
            return self.location.swift_url

    def _init_connection(self):
        if self.allow_reauth:
            try:
                return super(MultiTenantConnectionManager,
                             self)._init_connection()
            except Exception as e:
                LOG.debug("Cannot initialize swift connection for multi-tenant"
                          " store with trustee token: %s. Using user token for"
                          " connection initialization.", e)
                # for multi-tenant store we have a token, so we can use it
                # for connection initialization but we cannot fetch new token
                # with client
                self.allow_reauth = False

        return self.store.get_store_connection(
            self.context.auth_token, self.storage_url)
