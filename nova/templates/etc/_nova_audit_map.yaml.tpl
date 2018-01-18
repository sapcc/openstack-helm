service_type: 'compute'
service_name: 'nova'
# this works for DevStack only
# prefix: '/compute/v2.1'
prefix: '/v2[0-9\.]*(?:/[0-9a-f\-]+)?'

resources:
    # NOTE: proxy-kind API are ignored
    agents:
        api_name: os-agents
        custom_id: 'agent_id'
    aggregates:
        api_name: os-aggregates
        custom_id: 'aggregate_id'
        custom_actions:
            add_host: update/add-host
            remove_host: update/remove-host
            set_metadata: update/metadata
    availability-zone:
        api_name: os-availability-zone
        singleton: true
        custom_actions:
            detail: read/list/details
    # cells: omitted
    consoles:
        custom_id: 'console_id'
    flavors:
        custom_actions:
            detail: read/list/details
            addTenantAccess: allow/project-access
            removeTenantAccess: deny/project-access

        children:
            os-flavor-access:
                singleton: true
            os-extra_specs:
                singleton: true
    limits:
        singleton: true
    hypervisors:
        api_name: os-hypervisors
        custom_actions:
            detail: read/list/details
        children:
            uptime:
                singleton: true
    instance-usage-audit-log:
        api_name: os-instance-usage-audit-log
        singleton: true
        custom_actions:
            # last path segment is used as filter parameter for list
            'GET:*': 'read'
    keypairs:
        api_name: os-keypairs
        custom_id: name
    migrations:
    migrations/legacy:
        api_name: os-migrations
    os-server-external-events:
        type_uri: compute/servers/external-events
        type_name: events
        custom_id: tag
        custom_attributes:
          server_uuid: compute/server
    os-volumes_boot:
        # this is a legacy alternative to POST /servers used still in Devstack
        type_uri: compute/servers
        type_name: servers
    quotas:
        api_name: os-quota-sets
        children:
            defaults:
                singleton: true
            detail:
                singleton: true
    quota-classes:
        api_name: os-quota-class-sets
        el_type_uri: compute/quota-class
    servers:
        custom_actions:
            # server actions
            addFloatingIp: update/add/floatingip
            addSecurityGroup: update/add/security-group
            changePassword: update/set/admin-password
            confirmResize: update/confirm-resize
            createBackup: backup
            createImage: create/image
            forceDelete: delete/forced
            evacuate: capture/evacuate
            lock: disable/lock
            migrate: update/migrate
            os-getConsoleOutput: read/console
            os-migrateLive: update/migrate/live
            os-resetState: update/set/status
            os-start: start
            os-stop: stop
            pause: disable/pause
            reboot: update/reboot
            rebuild: update/rebuild
            remote-consoles: create/console
            removeFloatingIp: update/remove/floatingip
            removeSecurityGroup: update/remove/security-group
            rescue: update/rescue
            resetNetwork: update/reset/network
            resize: update/resize
            resume: enable/resume
            restore: restore/soft-deleted
            revertResize: update/revert-resize
            shelve: undeploy/shelve
            shelveOffload: undeploy/offload-shelved
            suspend: disable/suspend
            trigger_crash_dump: update/trigger-crash-dump
            unlock: enable/unlock
            unpause: enable/unpause
            unrescue: update/unrescue
            unshelve: restore/unshelve
            # global actions
            detail: read/list/details
        children:
            diagnostics:
                singleton: true
            ips:
            metadata:
                singleton: true
                type_name: meta
            migrations:
                custom_actions:
                    force_complete: update/force-completion
            interfaces:
                api_name: os-interface
                type_name: interfaceAttachments
                custom_id: port_id
            instance-actions:
                api_name: os-instance-actions
                type_name: instanceActions
            security-groups:
                api_name: os-security-groups
                type_name: securityGroups
                singleton: true
            server-password:
                api_name: os-server-password
                singleton: true
            tags:
            volume-attachments:
                api_name: os-volume_attachments
                type_name: volumeAttachments
    server-groups:
        api_name: os-server-groups
    services:
        api_name: os-services
        custom_actions:
            disable: disable
            disable-log-reason: disable
            enable: enable
    usage:
        api_name: os-simple-tenant-usage

