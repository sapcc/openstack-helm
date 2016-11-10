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


import abc
from datetime import timedelta
from operator import itemgetter
import random
import six

from oslo_log import log as logging
from sqlalchemy import func
from sqlalchemy.sql import expression as expr

from networking_cisco.plugins.cisco.common import cisco_constants
from networking_cisco.plugins.cisco.db.device_manager import hd_models

LOG = logging.getLogger(__name__)

ROUTER_ROLE_HA_REDUNDANCY = cisco_constants.ROUTER_ROLE_HA_REDUNDANCY
# Maximum allowed minute difference in creation time
# for hosting devices to be considered equal
EQUIVALENCE_TIME_DIFF = 7


@six.add_metaclass(abc.ABCMeta)
class L3RouterHostingDeviceBaseScheduler(object):
    """Slot-aware base scheduler of Neutron routers to hosting devices."""

    def get_candidates(self, plugin, context, r_hd_binding_db):
        """Selection criteria: Hosting devices that...
               ... are based on the template required by router's type
               AND
               ... are administratively up
               AND
               ... are active (i.e., has status HD_ACTIVE)
               AND
               ... are bound to tenant owning router OR is unbound
               AND
               ... are enough slots available to host the router

            Among hosting devices meeting these criteria the device with
            less allocated slots is preferred.
        """
        # SELECT hosting_device_id, created_at, sum(num_allocated)
        # FROM hostingdevices AS hd
        # LEFT OUTER JOIN slotallocations AS sa ON hd.id=sa.hosting_device_id
        # WHERE
        #    hd.template_id='11111111-2222-3333-4444-555555555555' AND
        #    hd.admin_state_up=TRUE AND
        #    hd.status='ACTIVE' AND
        # <<<sharing case:>>>
        #    (hd.tenant_bound IS NULL OR hd.tenant_bound='t10')
        # <<<non-sharing case:>>>
        #    (sa.tenant_bound='t10' OR
        #     (sa.tenant_bound IS NULL AND sa.logical_resource_owner='t10') OR
        #     hd.tenant_bound='t10' OR
        #     (hd.tenant_bound IS NULL AND sa.hosting_device_id IS NULL))
        # GROUP BY hosting_device_id
        # HAVING sum(num_allocated) <= 8 OR sum(num_allocated) IS NULL
        # ORDER BY created_at;
        router = r_hd_binding_db.router
        tenant_id = router['tenant_id']
        router_type_db = r_hd_binding_db.router_type
        template_id = router_type_db['template_id']
        template_db = router_type_db.template
        slot_threshold = template_db.slot_capacity - router_type_db.slot_need

        query = context.session.query(
            hd_models.HostingDevice.id, hd_models.HostingDevice.created_at,
            func.sum(hd_models.SlotAllocation.num_allocated))
        query = query.outerjoin(
            hd_models.SlotAllocation,
            hd_models.HostingDevice.id ==
            hd_models.SlotAllocation.hosting_device_id)
        query = query.filter(
            hd_models.HostingDevice.template_id == template_id,
            hd_models.HostingDevice.admin_state_up == expr.true(),
            hd_models.HostingDevice.status == cisco_constants.HD_ACTIVE)
        if r_hd_binding_db.share_hosting_device:
            query = query.filter(
                expr.or_(hd_models.HostingDevice.tenant_bound == expr.null(),
                         hd_models.HostingDevice.tenant_bound == tenant_id))
        else:
            query = query.filter(
                expr.or_(
                    hd_models.SlotAllocation.tenant_bound == tenant_id,
                    expr.and_(
                        hd_models.SlotAllocation.tenant_bound == expr.null(),
                        hd_models.SlotAllocation.logical_resource_owner ==
                        tenant_id),
                    hd_models.HostingDevice.tenant_bound == tenant_id,
                    expr.and_(
                        hd_models.HostingDevice.tenant_bound == expr.null(),
                        hd_models.SlotAllocation.hosting_device_id ==
                        expr.null())))
        query = query.group_by(hd_models.HostingDevice.id)
        query = query.having(
            expr.or_(func.sum(
                hd_models.SlotAllocation.num_allocated) <= slot_threshold,
                func.sum(hd_models.SlotAllocation.num_allocated ==
                         expr.null())))
        query = query.order_by(hd_models.HostingDevice.created_at)
        return query.all()

    @abc.abstractmethod
    def schedule_router(self, plugin, context, r_hd_binding_db):
        # As this is a base scheduler that is not supposed to be used
        # directly we make this method abstract
        pass

    @abc.abstractmethod
    def unschedule_router(self, plugin, context, r_hd_binding_db):
        # As this is a base scheduler that is not supposed to be used
        # directly we make this method abstract
        pass


class L3RouterHostingDeviceLongestRunningScheduler(
        L3RouterHostingDeviceBaseScheduler):
    """Schedules a Neutron router on a hosting device.

        Selection criteria:
            The longest running hosting device that
            has enough slots available to host the router

            Hosting devices with creation date/time less than
            EQUIVALENCE_TIME_DIFF are considered equally old.

            Among hosting devices meeting these criteria and
            that are of same age the device with less allocated
            slots is preferred.
    """
    def schedule_router(self, plugin, context, r_hd_binding_db):
        candidates = self._filtered_candidates(plugin, context,
                                               r_hd_binding_db)
        if len(candidates) == 0:
            # report unsuccessful scheduling
            return
        # determine oldest candidates considered equally old
        oldest_candidates = []
        minute_limit = timedelta(minutes=EQUIVALENCE_TIME_DIFF)
        for candidate in candidates:
            if candidate[1] - candidates[0][1] < minute_limit:
                oldest_candidates.append(candidate)
            else:
                # we're only interested in the longest running devices
                break
        # sort on least number of used slots
        sorted_candidates = sorted(oldest_candidates, key=itemgetter(2))
        return sorted_candidates[0]

    def unschedule_router(self, plugin, context, r_hd_binding_db):
        return True

    def _filtered_candidates(self, plugin, context, r_hd_binding_db):
        return self.get_candidates(plugin, context, r_hd_binding_db)


class CandidatesHAFilterMixin(object):

    def _filtered_candidates(self, plugin, context, r_hd_binding_db):
        candidates_dict = {c.id: c for c in self.get_candidates(
            plugin, context, r_hd_binding_db)}
        if candidates_dict:
            r_b = r_hd_binding_db.router.redundancy_binding
            if r_b:
                # this is a redundancy router so we need to exclude the hosting
                # devices of the user visible router and the other redundancy
                # routers
                if r_b.user_router.hosting_info.hosting_device_id:
                    del candidates_dict[
                        r_b.user_router.hosting_info.hosting_device_id]
                for rr_b in r_b.user_router.redundancy_bindings:
                    rr = rr_b.redundancy_router
                    if (rr.id != r_b.redundancy_router_id and
                            rr.hosting_info.hosting_device_id):
                        del candidates_dict[rr.hosting_info.hosting_device_id]
            elif r_hd_binding_db.role == ROUTER_ROLE_HA_REDUNDANCY:
                # redundancy binding has not been persisted to db yet
                # so we abort this scheduling attempt and retry later
                return []
            for rr_b in r_hd_binding_db.router.redundancy_bindings:
                # this is a user visible router so we need to exclude the
                # hosting devices of its redundancy routers
                rr = rr_b.redundancy_router
                if rr.hosting_info.hosting_device_id:
                    del candidates_dict[rr.hosting_info.hosting_device_id]
        return candidates_dict.values()


class L3RouterHostingDeviceHALongestRunningScheduler(
        CandidatesHAFilterMixin, L3RouterHostingDeviceLongestRunningScheduler):
    """Schedules a Neutron router on a hosting device.

        The scheduler is HA aware and will ignore hosting device candidates
        that are used by other Neutron routers in the same HA group.

        Selection criteria:
            The longest running hosting device that is not already hosting a
            router in the HA group and which has enough slots available to
            host the router.

            Hosting devices with creation date/time less than
            EQUIVALENCE_TIME_DIFF are considered equally old.

            Among hosting devices meeting these criteria and
            that are of same age the device with less allocated
            slots is preferred.
    """
    pass


class L3RouterHostingDeviceRandomScheduler(L3RouterHostingDeviceBaseScheduler):
    """Schedules a Neutron router on a hosting device.

        Selection criteria:
            A randomly selected hosting device that has enough slots available
            to host the router.
    """
    def schedule_router(self, plugin, context, r_hd_binding_db):
        candidates = self._filtered_candidates(plugin, context,
                                               r_hd_binding_db)
        if len(candidates) == 0:
            # report unsuccessful scheduling
            return
        return random.choice(list(candidates))

    def unschedule_router(self, plugin, context, r_hd_binding_db):
        return True

    def _filtered_candidates(self, plugin, context, r_hd_binding):
        return self.get_candidates(plugin, context, r_hd_binding)


class L3RouterHostingDeviceHARandomScheduler(
        CandidatesHAFilterMixin, L3RouterHostingDeviceRandomScheduler):
    """Schedules a Neutron router on a hosting device.

        The scheduler is HA aware and will ignore hosting device candidates
        that are used by other Neutron routers in the same HA group.

        Selection criteria:
            A randomly selected hosting device that is not already hosting a
            router in the HA group and which has enough slots available to
            host the router.
    """
    pass
