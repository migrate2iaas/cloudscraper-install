endpoint = portal.4d-cloud.com
datastore = 9
port = 80
minipad_template = 384
vm_build_timeout = 10000
s3bucket=ireland-cloudmigration-bucket
s3user = AKIAIELF7Z5RPG242BSA
s3secret = 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
s3region=eu-west-1
wintemplate_size=20
template_size_linux=5
minipad_linux_template=385
vm_boot_timeout=1360
network_id=1

