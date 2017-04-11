[DEFAULT]
# default target endpoint type
# should match the endpoint type defined in service catalog
target_endpoint_type = None

[custom_actions]
enable = enable
disable = disable
delete = delete
startup = start/startup
shutdown = stop/shutdown
reboot = start/reboot
os-migrations/get = read
os-server-password/post = update

# possible end path of api requests
[path_keywords]
add = None
action = None
enable = None
disable = None
configure-project = None
defaults = None
delete = None
detail = None
diagnostics = None
entries = entry
extensions = alias
flavors = flavor
images = image
ips = label
limits = None
metadata = key
os-agents = os-agent
os-aggregates = os-aggregate
os-availability-zone = None
os-certificates = None
os-cloudpipe = None
os-fixed-ips = ip
os-extra_specs = key
os-flavor-access = None
os-floating-ip-dns = domain
os-floating-ips-bulk = host
os-floating-ip-pools = None
os-floating-ips = floating-ip
os-hosts = host
os-hypervisors = hypervisor
os-instance-actions = instance-action
os-keypairs = keypair
os-migrations = None
os-networks = network
os-quota-sets = tenant
os-security-groups = security_group
os-security-group-rules = rule
os-server-password = None
os-services = None
os-simple-tenant-usage = tenant
os-virtual-interfaces = None
os-volume_attachments = attachment
os-volumes_boot = None
os-volumes = volume
os-volume-types = volume-type
os-snapshots = snapshot
reboot = None
servers = server
shutdown = None
startup = None
statistics = None

# map endpoint type defined in service catalog to CADF typeURI
[service_endpoints]
compute = service/compute
