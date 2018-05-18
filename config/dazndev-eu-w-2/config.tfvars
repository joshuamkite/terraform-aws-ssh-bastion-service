vpc = "vpc-00453ec9c0195958e"
subnets_elb = ["subnet-0c2132c52d390bc43"]
subnets_asg= ["subnet-0c2132c52d390bc43"]
bastion_service_host_key_name = "dazndev-joshua-kite"
iam_authorized_keys_command_url = "s3://dazn-dev-eu-w-2-bastion-service-files/iam-authorized-keys-command"
s3_bucket_name = "dazn-dev-eu-w-2-bastion-service-files"
cidr_blocks_whitelist_service = ["217.111.163.174/32", "84.92.40.27/32"]
dns_domain = "dazndev.com"
route53_zone_id = "Z11O5UHZCWYOX"
environment_name = "dazndev"


# asg_max = "3"
# asg_min  = "2"
# asg_desired  = "2"