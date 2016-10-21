#    Copyright 2015 Rackspace
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

from keystoneclient.auth.identity import v2 as v2_client
from keystoneclient.auth.identity import v3 as v3_client
from keystoneclient import session
from oslo_config import cfg
from oslo_log import log as logging
from oslo_utils import excutils

from neutron_lbaas._i18n import _LE


LOG = logging.getLogger(__name__)

_SESSION = None
OPTS = [
    cfg.StrOpt(
        'auth_url',
        default='http://127.0.0.1:5000/v2.0',
        help=_('Authentication endpoint'),
    ),
    cfg.StrOpt(
        'admin_user',
        default='admin',
        help=_('The service admin user name'),
    ),
    cfg.StrOpt(
        'admin_tenant_name',
        default='admin',
        help=_('The service admin tenant name'),
    ),
    cfg.StrOpt(
        'admin_password',
        default='password',
        help=_('The service admin password'),
    ),
    cfg.StrOpt(
        'admin_user_domain',
        default='admin',
        help=_('The admin user domain name'),
    ),
    cfg.StrOpt(
        'admin_project_domain',
        default='admin',
        help=_('The admin project domain name'),
    ),
    cfg.StrOpt(
        'region',
        default='RegionOne',
        help=_('The deployment region'),
    ),
    cfg.StrOpt(
        'service_name',
        default='lbaas',
        help=_('The name of the service'),
    ),
    cfg.StrOpt(
        'auth_version',
        default='2',
        help=_('The auth version used to authenticate'),
    )
]

cfg.CONF.register_opts(OPTS, 'service_auth')


def get_session():
    """Initializes a Keystone session.

    :returns: a Keystone Session object
    :raises Exception: if the session cannot be established
    """
    global _SESSION
    if not _SESSION:

        auth_url = cfg.CONF.service_auth.auth_url
        kwargs = {'auth_url': auth_url,
                  'username': cfg.CONF.service_auth.admin_user,
                  'password': cfg.CONF.service_auth.admin_password}

        if cfg.CONF.service_auth.auth_version == '2':
            client = v2_client
            kwargs['tenant_name'] = cfg.CONF.service_auth.admin_tenant_name
        elif cfg.CONF.service_auth.auth_version == '3':
            client = v3_client
            kwargs['project_name'] = cfg.CONF.service_auth.admin_tenant_name
            kwargs['user_domain_name'] = (cfg.CONF.service_auth.
                                          admin_user_domain)
            kwargs['project_domain_name'] = (cfg.CONF.service_auth.
                                             admin_project_domain)
        else:
            raise Exception('Unknown keystone version!')

        try:
            kc = client.Password(**kwargs)
            _SESSION = session.Session(auth=kc)
        except Exception:
            with excutils.save_and_reraise_exception():
                LOG.exception(_LE("Error creating Keystone session."))

    return _SESSION
