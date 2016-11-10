# coding=utf-8
# Copyright 2016 F5 Networks Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

try:
    from barbicanclient.client import Client
except ImportError:
    raise ImportError("Missing Python library barbicanclient."
                      "Install barbicanclient and restart the agent.")
try:
    # Try keystoneuath1 first as OpenStack is migrating from keystoneclient
    # to keystoneauth1. Some systems, particularly liberty, may not
    # have keystoneauth1 installed. If ImportError, try keystoneclient.
    from keystoneauth1.identity import v2
    from keystoneauth1.identity import v3
    from keystoneauth1.session import Session

except ImportError:
    try:
        # no keystoneauth1 -- try keystoneclient
        from keystoneclient.auth.identity import v2
        from keystoneclient.auth.identity import v3
        from keystoneclient.session import Session
    except ImportError:
        raise ImportError("Missing Python library keystoneclient."
                          "Install keystoneclient and restart the agent.")

from oslo_log import log as logging
import time

from f5_openstack_agent.lbaasv2.drivers.bigip import cert_manager


LOG = logging.getLogger(__name__)


class InvalidBarbicanConfig(Exception):
    pass


class BarbicanCertManager(cert_manager.CertManagerBase):
    """Concrete class for retrieving certs/keys from Barbican service."""

    def __init__(self, conf):
        super(BarbicanCertManager, self).__init__()

        if not conf:
            raise InvalidBarbicanConfig

        self.username = conf.os_username
        self.password = conf.os_password
        self.auth_url = conf.os_auth_url
        self.auth_version = conf.auth_version

        if self.auth_version == "v3":
            self.user_domain_name = conf.os_user_domain_name
            self.project_domain_name = conf.os_project_domain_name
            self.project_name = conf.os_project_name
        else:
            self.tenant_name = conf.os_tenant_name

        self._init_barbican_client()

    def _init_barbican_client(self):
        """Creates barbican client instance.

        Verifies that client can communicate with Barbican, retrying
        multiple times in case either Barbican or Keystone services are
        still starting up.
        """
        max_attempts = 5
        sleep_time = 5
        n_attempts = 0
        while n_attempts <= max_attempts:
            n_attempts += 1
            try:
                if self.auth_version == "v3":
                    auth = v3.Password(
                        username=self.username,
                        password=self.password,
                        auth_url=self.auth_url,
                        user_domain_name=self.user_domain_name,
                        project_domain_name=self.project_domain_name,
                        project_name=self.project_name)

                else:
                    # assume v2 auth
                    auth = v2.Password(
                        username=self.username,
                        password=self.password,
                        auth_url=self.auth_url,
                        tenant_name=self.tenant_name)

                # NOTE: Session is deprecated in keystoneclient 2.1.0
                # and will be removed in a future keystoneclient release.
                sess = Session(auth=auth)
                self.barbican = Client(session=sess)

                # test barbican service
                self.barbican.containers.list()

                # success
                LOG.debug(
                    "Barbican client initialized using Keystone %s "
                    "authentication." % self.auth_version)
                break

            except Exception as exc:
                if n_attempts < max_attempts:
                    LOG.debug("Barbican client initialization failed. "
                              "Trying again.")
                    time.sleep(sleep_time)
                else:
                    raise InvalidBarbicanConfig(
                        "Unable to initialize Barbican client. %s" %
                        exc.message)

    def get_certificate(self, container_ref):
        """Retrieves certificate from certificate manager.

        :param string container_ref: Reference to certificate stored in a
        certificate manager.
        :returns string: Certificate data.
        """
        container = self.barbican.containers.get(container_ref)
        return container.certificate.payload

    def get_private_key(self, container_ref):
        """Retrieves key from certificate manager.

        :param string container_ref: Reference to key stored in a
        certificate manager.
        :returns string: Key data.
        """
        container = self.barbican.containers.get(container_ref)
        return container.private_key.payload

    def get_name(self, container_ref, prefix):
        """Returns a name that uniquely identifies cert/key pair.

        Barbican containers have a name attribute, but there is
        no guarantee that the name is unique. Instead of using the
        container name, create a unique name by parsing UUID from
        container_ref and prepending prefix.

        :param string container_ref: Reference to certificate/key container
        stored in a certificate manager.
        :param string prefix: The environment prefix. Can be optionally
        used to
        :returns string: Name. Unique name with prefix.
        """

        i = container_ref.rindex("/") + 1
        return prefix + container_ref[i:]
