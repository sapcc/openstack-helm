# Copyright 2014 Cisco Systems, Inc.  All rights reserved.
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

import datetime

from oslo_config import cfg
from oslo_log import log as logging
from oslo_utils import timeutils

from networking_cisco.plugins.cisco.cfg_agent import cfg_exceptions
import networking_cisco.plugins.cisco.common.cisco_constants as cc
from neutron.agent.linux import utils as linux_utils

from neutron._i18n import _
from neutron._i18n import _LI
from neutron._i18n import _LW

import pprint


LOG = logging.getLogger(__name__)


STATUS_OPTS = [
    cfg.IntOpt('device_connection_timeout', default=30,
               help=_("Time in seconds for connecting to a hosting device")),
    cfg.IntOpt('hosting_device_dead_timeout', default=300,
               help=_("The time in seconds until a backlogged hosting device "
                      "is presumed dead. This value should be set up high "
                      "enough to recover from a period of connectivity loss "
                      "or high load when the device may not be responding.")),
]

cfg.CONF.register_opts(STATUS_OPTS, "cfg_agent")


def _is_pingable(ip):
    """Checks whether an IP address is reachable by pinging.

    Use linux utils to execute the ping (ICMP ECHO) command.
    Sends 5 packets with an interval of 0.2 seconds and timeout of 1
    seconds. Runtime error implies unreachability else IP is pingable.
    :param ip: IP to check
    :return: bool - True or False depending on pingability.
    """
    ping_cmd = ['ping',
                '-c', '5',
                '-W', '1',
                '-i', '0.2',
                ip]
    try:
        linux_utils.execute(ping_cmd, check_exit_code=True)
        return True
    except RuntimeError:
        LOG.warning(_LW("Cannot ping ip address: %s"), ip)
        return False


class DeviceStatus(object):
    """Device status and backlog processing."""

    _instance = None

    def __new__(cls):
        if not cls._instance:
            cls._instance = super(DeviceStatus, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        self.backlog_hosting_devices = {}
        self.enable_heartbeat = False

    def get_backlogged_hosting_devices(self):
        return self.backlog_hosting_devices.keys()

    def get_backlogged_hosting_devices_info(self):
        resp = self.get_monitored_hosting_devices_info(hd_state_filter='Dead')
        return resp

    def get_dead_hosting_devices_info(self):
        """
        Get a list of hosting devices that have been marked dead
        :return: List of dead hosting device ids
        """
        res = []
        for hd_id in self.backlog_hosting_devices:
            hd = self.backlog_hosting_devices[hd_id]['hd']
            if hd['hd_state'] == cc.HD_DEAD:
                res.append(hd['id'])
        return res

    def get_monitored_hosting_devices_info(self, hd_state_filter=None):
        """
        This function returns a list of all hosting devices monitored
        by this agent
        """
        wait_time = datetime.timedelta(
            seconds=cfg.CONF.cfg_agent.hosting_device_dead_timeout)
        resp = []
        for hd_id in self.backlog_hosting_devices:
            hd = self.backlog_hosting_devices[hd_id]['hd']

            display_hd = True

            if hd_state_filter is not None:
                if hd['hd_state'] == hd_state_filter:
                    display_hd = True
                else:
                    display_hd = False

            if display_hd:
                created_time = hd['created_at']
                boottime = datetime.timedelta(seconds=hd['booting_time'])
                backlogged_at = hd['backlog_insertion_ts']
                booted_at = created_time + boottime
                dead_at = backlogged_at + wait_time
                resp.append({'host id': hd['id'],
                             'hd_state': hd['hd_state'],
                             'created at': str(created_time),
                             'backlogged at': str(backlogged_at),
                             'estimate booted at': str(booted_at),
                             'considered dead at': str(dead_at)})
            else:
                continue
        return resp

    def is_hosting_device_reachable(self, hosting_device):
        """Check the hosting device which hosts this resource is reachable.

        If the resource is not reachable, it is added to the backlog.

        * heartbeat revision
        We want to enqueue all hosting-devices into the backlog for
        monitoring purposes

        adds key/value pairs to  hd (aka hosting_device dictionary)

        _is_pingable : if it returns true,
            hd['hd_state']='Active'
        _is_pingable : if it returns false,
            hd['hd_state']='Unknown'

        :param hosting_device : dict of the hosting device
        :return True if device is reachable, else None
        """
        ret_val = False

        hd = hosting_device
        hd_id = hosting_device['id']
        hd_mgmt_ip = hosting_device['management_ip_address']

        dead_hd_list = self.get_dead_hosting_devices_info()
        if hd_id in dead_hd_list:
            LOG.debug("Hosting device: %(hd_id)s@%(ip)s is already marked as"
                      " Dead. It is assigned as non-reachable",
                      {'hd_id': hd_id, 'ip': hd_mgmt_ip})
            return False

        # Modifying the 'created_at' to a date time object if it is not
        if not isinstance(hd['created_at'], datetime.datetime):
            hd['created_at'] = datetime.datetime.strptime(hd['created_at'],
                                                          '%Y-%m-%d %H:%M:%S')

        if _is_pingable(hd_mgmt_ip):
            LOG.debug("Hosting device: %(hd_id)s@%(ip)s is reachable.",
                      {'hd_id': hd_id, 'ip': hd_mgmt_ip})
            hd['hd_state'] = cc.HD_ACTIVE
            ret_val = True
        else:
            LOG.debug("Hosting device: %(hd_id)s@%(ip)s is NOT reachable.",
                      {'hd_id': hd_id, 'ip': hd_mgmt_ip})
            hd['hd_state'] = cc.HD_NOT_RESPONDING
            ret_val = False

        if (self.enable_heartbeat is True or ret_val is False):

            if hd_id not in self.backlog_hosting_devices:
                hd['backlog_insertion_ts'] = max(
                    timeutils.utcnow(),
                    hd['created_at'] +
                    datetime.timedelta(seconds=hd['booting_time']))

                self.backlog_hosting_devices[hd_id] = {'hd': hd}
                LOG.debug("Hosting device: %(hd_id)s @ %(ip)s is now added "
                      "to backlog", {'hd_id': hd_id, 'ip': hd_mgmt_ip})

        return ret_val

    def check_backlogged_hosting_devices(self, driver_mgr):
        """"Checks the status of backlogged hosting devices.

        Skips newly spun up instances during their booting time as specified
        in the boot time parameter.

        Each hosting-device tracked has a key, hd_state, that represents the
        last known state for the hosting device.  Valid values for hd_state
        are ['Active', 'Unknown', 'Dead']

        Each time check_backlogged_hosting_devices is invoked, a ping-test
        is performed to determine the current state.  If the current state
        differs, hd_state is updated.

        The hd_state transitions/actions are represented by the following
        table.

        current /    Active                 Unknown          Dead
        last state
        Active       Device is reachable.   Device was       Dead device
                     No state change        temporarily      recovered.
                                            unreachable.     Trigger resync
        Unknown      Device connectivity    Device           Not a valid
                     test failed.  Set      connectivity     state
                     backlog timestamp      test failed.     transition.
                     and wait for dead      Dead timeout
                     timeout to occur.      has not
                                            occurred yet.
        Dead         Not a valid state      Dead timeout     Device is
                     transition.            for device has   still dead.
                                            elapsed.         No state
                                            Notify plugin    change.

        :return A dict of the format:
        {'reachable': [<hd_id>,..],'dead':[<hd_id>,..],'revived':[<hd_id>,..]}
        reachable - a list of hosting devices that are now reachable
        dead      - a list of hosting devices deemed dead
        revived   - a list of hosting devices (dead to active)
        """
        response_dict = {'reachable': [], 'revived': [], 'dead': []}
        LOG.debug("Current Backlogged hosting devices: \n%s\n",
                  self.backlog_hosting_devices.keys())
        for hd_id in self.backlog_hosting_devices.keys():
            hd = self.backlog_hosting_devices[hd_id]['hd']
            if not timeutils.is_older_than(hd['created_at'],
                                           hd['booting_time']):
                LOG.info(_LI("Hosting device: %(hd_id)s @ %(ip)s hasn't "
                             "passed minimum boot time. Skipping it. "),
                         {'hd_id': hd_id, 'ip': hd['management_ip_address']})
                continue
            LOG.info(_LI("Checking hosting device: %(hd_id)s @ %(ip)s for "
                         "reachability."), {'hd_id': hd_id,
                                            'ip': hd['management_ip_address']})
            hd_state = hd['hd_state']
            if _is_pingable(hd['management_ip_address']):
                if hd_state == cc.HD_NOT_RESPONDING:
                    LOG.debug("hosting devices revived & reachable, %s" %
                              (pprint.pformat(hd)))
                    hd['hd_state'] = cc.HD_ACTIVE
                    # hosting device state
                    response_dict['reachable'].append(hd_id)
                elif hd_state == cc.HD_DEAD:
                    # test if netconf is actually ready
                    driver = driver_mgr.get_driver_for_hosting_device(hd_id)
                    try:
                        driver.send_empty_cfg()
                        LOG.debug("Dead hosting devices revived %s" %
                              (pprint.pformat(hd)))
                        hd['hd_state'] = cc.HD_ACTIVE
                        response_dict['revived'].append(hd_id)
                    except cfg_exceptions.DriverException as e:
                        LOG.debug("netconf not ready on device yet. "
                                  "Error is %s", e)
                else:
                    LOG.debug("No-op."
                              "_is_pingable is True and current"
                              " hd['hd_state']=%s" % (hd_state))

                LOG.info(_LI("Hosting device: %(hd_id)s @ %(ip)s is now "
                             "reachable. Adding it to response"),
                         {'hd_id': hd_id, 'ip': hd['management_ip_address']})
            else:
                LOG.info(_LI("Hosting device: %(hd_id)s %(hd_state)s"
                             " @ %(ip)s not reachable "),
                         {'hd_id': hd_id,
                          'hd_state': hd['hd_state'],
                          'ip': hd['management_ip_address']})
                if hd_state == cc.HD_ACTIVE:
                    LOG.debug("hosting device lost connectivity, %s" %
                              (pprint.pformat(hd)))
                    hd['backlog_insertion_ts'] = timeutils.utcnow()
                    hd['hd_state'] = cc.HD_NOT_RESPONDING

                elif hd_state == cc.HD_NOT_RESPONDING:
                    if timeutils.is_older_than(
                            hd['backlog_insertion_ts'],
                            cfg.CONF.cfg_agent.hosting_device_dead_timeout):
                        # current hd_state is now dead, previous state: Unknown
                        hd['hd_state'] = cc.HD_DEAD
                        LOG.debug("Hosting device: %(hd_id)s @ %(ip)s hasn't "
                                  "been reachable for the "
                                  "last %(time)d seconds. "
                                  "Marking it dead.",
                                  {'hd_id': hd_id,
                                   'ip': hd['management_ip_address'],
                                   'time': cfg.CONF.cfg_agent.
                                   hosting_device_dead_timeout})
                        response_dict['dead'].append(hd_id)
        LOG.debug("Response: %s", response_dict)
        return response_dict
