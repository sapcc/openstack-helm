# configuration for openstack-watcher-middleware
custom_actions:
  os-snapshots:
    - method: GET
      action_type: read/list

  os-volumes:
    - method: GET
      action_type: read/list

  os-volume-types:
    - method: GET
      action_type: read/list

  extensions:
    - method: GET
      action_type: read/list

  servers:
    - method: GET
      action_type: read/list

    - server:
      - metadata:
        - method: GET
          action_type: read/list

      - ips:
        - method: GET
          action_type: read/list

        - label:
          - method: GET
            action_type: read/list

      - os-security-groups:
        - method: GET
          action_type: read/list

      - os-server-password:
        - method: POST
          action_type: update

      - os-virtual-interfaces:
        - method: GET
          action_type: read/list

      - os-volume_attachments:
        - method: GET
          action_type: read/list

      - os-instance-actions:
        - method: GET
          action_type: read/list

  flavors:
    - method: GET
      action_type: read/list

    - flavor:
      - os-flavor-access:
        - method: GET
          action_type: read/list

      - os-extra_specs:
        - method: GET
          action_type: read/list

  images:
    - method: GET
      action_type: read/list

    - image:
      - metadata:
        - method: GET
          action_type: read/list

  limits:
    - method: GET
      action_type: read/list

  os-agents:
    - method: GET
      action_type: read/list

  os-aggregates:
    - method: GET
      action_type: read/list

  os-certificates:
    - method: GET
      action_type: read/list

  os-cloudpipe:
    - method: GET
      action_type: read/list
    - configure-project: update

  os-coverage:
    - action:
      - report: update/report
      - start: update/start
      - stopt: update/stop

  os-fixed-ips:
    - ip:
      - action:
        - reserve: update/reserve

  os-floating-ip-dns:
    - method: GET
      action_type: read/list
    - domain:
      - entries:
        - entry:
          - method: GET
            action_type: read/list

  os-floating-ip-pools:
    - method: GET
      action_type: read/list

  os-floating-ips:
    - method: GET
      action_type: read/list

  os-floating-ips-bulk:
    - method: GET
      action_type: read/list

  os-hosts:
    - method: GET
      action_type: read/list

    - host:
      - shutdown: stop/shutdown
      - reboot: start/reboot

  os-hypervisors:
    - method: GET
      action_type: read/list

    - statistics:
      - method: GET
        action_type: read/list

    - hypervisors:
      - servers:
        - method: GET
          action_type: read/list

  os-keypairs:
    - method: GET
      action_type: read/list

  os-networks:
    - method: GET
      action_type: read/list

  os-quota-sets:
    - method: GET
      action_type: read/list

  os-services:
    - method: GET
      action_type: read/list

    - enable:
      - method: PUT
        action_type: enable

    - disable:
      - method: PUT
        action_type: disable

  os-security-groups:
    - method: GET
      action_type: read/list

  os-simple-tenant-usage:
    - method: GET
      action_type: read/list
