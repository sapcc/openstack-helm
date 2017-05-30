label deploy
kernel http://{{.Values.global.ironic_tftp_ip}}:{{.Values.conductor.deploy.port}}/{{"{{"}} pxe_options.deployment_aki_path {{"}}"}}
append initrd=http://{{.Values.global.ironic_tftp_ip}}:{{.Values.conductor.deploy.port}}/{{"{{"}} pxe_options.deployment_ari_path {{"}}"}} selinux=0 troubleshoot=0 text {{"{{"}} pxe_options.pxe_append_params|default("", true) {{"}}"}} ipa-api-url={{"{{"}} pxe_options['ipa-api-url'] {{"}}"}} coreos.configdrive=0
ipappend 3


label boot_partition
kernel http://{{.Values.global.ironic_tftp_ip}}:{{.Values.conductor.deploy.port}}/{{"{{"}} pxe_options.aki_path {{"}}"}}
append initrd=http://{{.Values.global.ironic_tftp_ip}}:{{.Values.conductor.deploy.port}}/{{"{{"}} pxe_options.ari_path {{"}}"}} root={{"{{"}} ROOT {{"}}"}} ro text {{"{{"}} pxe_options.pxe_append_params|default("", true) {{"}}"}}


label boot_whole_disk
COM32 chain.c32
append mbr:{{"{{"}} DISK_IDENTIFIER {{"}}"}}

label trusted_boot
kernel mboot
append tboot.gz --- http://{{.Values.global.ironic_tftp_ip}}:{{.Values.conductor.deploy.port}}/{{"{{"}}pxe_options.aki_path{{"}}"}} root={{"{{"}} ROOT {{"}}"}} ro text {{"{{"}} pxe_options.pxe_append_params|default("", true) {{"}}"}} intel_iommu=on --- http://{{.Values.global.ironic_tftp_ip}}:{{.Values.conductor.deploy.port}}/{{"{{"}}pxe_options.ari_path{{"}}"}}
