{{define "rabbitmq_host"}}rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "memcached_host"}}memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "nova_db_host"}}postgres-nova.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "nova_api_endpoint_host_admin"}}nova-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "nova_api_endpoint_host_internal"}}nova-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "nova_api_endpoint_host_public"}}compute-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "nova_console_endpoint_host_public"}}compute-console-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "horizon_endpoint_host"}}horizon-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}



{{define "keystone_db_host"}}postgres-keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_api_endpoint_host_admin"}}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_api_endpoint_host_internal"}}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_api_endpoint_host_public"}}identity-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_api_endpoint_host_admin_ext"}}identity-admin-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "glance_db_host"}}postgres-glance.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "glance_api_endpoint_host_admin"}}glance.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "glance_api_endpoint_host_internal"}}glance.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "glance_api_endpoint_host_public"}}image-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "neutron_db_host"}}postgres-neutron.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "neutron_api_endpoint_host_admin"}}neutron-server.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "neutron_api_endpoint_host_internal"}}neutron-server.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "neutron_api_endpoint_host_public"}}network-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "ironic_db_host"}}postgres-ironic.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_api_endpoint_host_admin"}}ironic-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_api_endpoint_host_internal"}}ironic-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_api_endpoint_host_public"}}baremetal-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "ironic_inspector_endpoint_host_admin"}}ironic-inspector.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_inspector_endpoint_host_internal"}}ironic-inspector.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_inspector_endpoint_host_public"}}baremetal-inspector-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "barbican_db_host"}}postgres-barbican.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "barbican_api_endpoint_host_admin"}}barbican-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "barbican_api_endpoint_host_internal"}}barbican-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "barbican_api_endpoint_host_public"}}keymanager-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "cinder_db_host"}}postgres-cinder.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "cinder_api_endpoint_host_admin"}}cinder-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "cinder_api_endpoint_host_internal"}}cinder-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "cinder_api_endpoint_host_public"}}volume-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "manila_db_host"}}postgres-manila.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "manila_api_endpoint_host_admin"}}manila-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "manila_api_endpoint_host_internal"}}manila-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "manila_api_endpoint_host_public"}}share-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "designate_db_host"}}designate-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "designate_api_endpoint_host_admin"}}designate-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "designate_api_endpoint_host_internal"}}designate-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "designate_api_endpoint_host_public"}}dns-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}


{{define "arc_api_endpoint_host_public"}}arc.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "lyra_api_endpoint_host_public"}}lyra.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "billing_api_endpoint_host_public"}}sapcc-billing.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "webcli_api_endpoint_host_public"}}webcli.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_router_api_endpoint_host_public"}}identity.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "monasca_api_endpoint_host_admin"}}monasca-api.monasca.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "monasca_api_endpoint_host_internal"}}monasca-api.monasca.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "monasca_api_endpoint_host_public"}}monitoring.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "swift_endpoint_host"}}objectstore.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "cfm_api_endpoint_host_public"}}cfm.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
