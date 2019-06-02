**N.B.**

# 5.0

**Change:**  Updated to Terraform 0.12/HCL2. **This is a Breaking change** 

**For Terraform 0.11. Pin module version to ~> v4.0**

**Change:** The Tags 'Name', 'Environment' and 'Region' are no longer automatically created, populated and applied to the autoscaling group. This change is due to a combination of:

* Difficult to port old behaviour to Terraform 12
* It wasn't a great idea to pre-determine tags for users
* Since this release is a breaking change anyway, it's a good opportunity to change this. 

The tags given in var.tags are rendered to the Autoscaling group as before

# 4.xx

**This series is compatible with Terraform version 0.11.xx - Pin module version to ~> v4.0**

**It is not possible to successfully apply module version >/= 4.0 over versions </= 3.xx due to change from classic to network load balancer**

**You will need to terraform destroy; terraform apply in such case**

# 4.9

**Feature:** Added variable `${route53_fqdn}` (default `""`to preserve module historic behaviour by default). If creating a public DNS entry with this module then you may override the default constructed DNS entry by supplying a fully qualified domain name here.

**Feature:** Added output target group arn. - Thanks Kevin Green

# 4.8

**Feature:** Added variable `${var.service_name}` (default "`bastion-service`" to preserve module historic behaviour by default). Set this to a different value to avoid resource name collision when deploying more than one service using this module per vpc.

**Change:** Removed module version number and empty outputs from examples/full-with-public-ip

# 4.7

**Feature:** Add output "lb_arn"

**Change:** All policies are now rendered with `aws_iam_policy_document` rather than as json blobs

**Feature:** Add tags to roles

**Feature:** Increment module version and add outputs for simple example

# 4.6

**Bugfix:** Change quote style for ssh_populate scripts to avoid early interpolation (Thanks KevinGreen)

# 4.5.1

**Feature:** Maintenance release - documentation changes and bump module version in example only

# 4.5

**Feature:** Bastion load balancer can now be internal (Thanks Instacart)
**Feature:** Bastion can now be assigned a public IP - permits use of module without NAT gateway (Thanks Ivan Mesic navi7)
**Feature:** Example of simple use of module with a public IP (Thanks Ivan Mesic navi7)
**Bugfix:** Populate user data with default if empty (Thanks Ivan Mesic navi7)

# 4.4

**Feature:** Adds a new variable so that the hostname can be overridden completely
**Feature:** Removes the 'provider' so that it can set by the plan calling this module (as per Terraform guidelines)
**Feature:** Adds a shebang as the default content for the shell script multipart mime types. This is so that, when using custom userdata, systemd doesn't report errors.

# 4.3

**Feature:** You can now specify a list of one or more security groups to attach to the host instance launch configuration. This can be supplied together with or instead of a whitelisted range of CIDR blocks. **N.B. This is _not_ aws_security_group_rule/source_security_group_id!** If you wish to append your own 'security_group_id' rules then you will need to attach these from a plan caling this module (using output "bastion_sg_id") or as part of a separate security group which you then attach. 

It may be useful in an enterprise setting to have security groups with rules managed separately from the bastion plan but of course if you do not assign a suitable security group or whitelist then you may not be able to reach the service!

**Change:** The code has been DRYed significantly in locals.tf (to remove unused logic evaluations) and main.tf (to condense 2 seperate aws_launch_configuration and aws_autoscaling_group blocks into one each). This makes code maintenence much easier and less error prone **BUT** it does mean that these resources are now 'new' so if you are deploying over an older version of this plan then you can expect them to be recreated - as lifecycle 'create before destroy' is specified, deployment will be a bit longer but downtime should be brief.

**Bugfix:** Previously the Golang code used for obtaining users and ssh public keys limited the number of users returned to 100 _if_ an IAM group was specified. This has now been increased to 1000 and the code change accepted upstream. 

# 4.2

**Bugfix:** Make load balancer and target group names unique to support multiple environments in one account

# 4.1

**Feature:** You can now specify a custom base AMI to use for the service host if you wish with var.custom_ami_id. Tested and working without other changes using Ubuntu 18.04

**Feature:** Userdata has been divided into sections which are now individually applicable. Each is now a HEREDOC and may be excluded by assigning any non-empty value to the relevant section variable. The value given is used simply for a logic test and not passed into userdata. If you ignore these variables then historic/ default behaviour continues and everything is built on the host instance on first boot (allow 3 minutes on t2.medium).

The variables for these sections are:

* **custom_ssh_populate** - any value excludes default ssh_populate script used on container launch from userdata

* **custom_authorized_keys_command** - any value excludes default Go binary to get IAM authorized keys built from source in userdata

* **custom_docker_setup** - any value excludes default docker installation and container build from userdata

* **custom_systemd** - any value excludes default systemd and hostname change from userdata

If you exclude any section then you must replace it with equivalent functionality, either in your base AMI or extra_user_data. Especially if you are not replacing all sections then be mindful that the systemd service expects docker to be installed and to be able to call the docker container as 'sshd_worker'. The service container in turn references the 'ssh_populate' script which calls 'iam-authorized-keys' from a specific location.

# 4.0

**New major version increment because of breaking changes** It is not possible to apply this version of this module over earlier versions

**Feature:** Move from Classic Load Balancer to Network Load Balancer. 
* elb_idle_timeout and elb_timeout variables have been removed as they are not supported in this configuration. 

* Configurable load balancer variables naming now prefixed 'lb'. Unfortunately the change in load balancer type breaks backward compatibilty with deployments using earlier versions of this module anyway so the opportunity is being taken to update the variable names for future sanity.

**Feature:** Security group rules apply 'description' tag

**Change:**  New code now in seperate files to assist readabilty. locals also moved to seperate file.

**Change:**  Security group name for EC2 instance now name_prefix and simplified

# 3.10

**Bugfix:**  Join bastion_service names to prevent error when route53_zone_id is not defined. With thanks to tpesce

# 3.9

**Feature:** Extensible tagging for Autoscaling groups

**Bugfix:** Region now correctly interpolated for autoscaling group tag

# 3.8

**Feature:** Implement appendable user data - you can now add userdata from an encompassing plan

**Feature:** The role created by this module is now available as an output so that an encompassing plan may use it e.g. for additional policies attachment

* Both changes make it easier to set up your logging solution of choice, e.g. cloudwatch

**Change:**  EC2 healthcheck port now defaults to 2222 - this avoids scaling issues with IAM in large deployments

# 3.7

**Feature:** ELB health check port may be optionally set to either port 22 (containerised service; default) or port 2222 (EC2 host sshd). If you are deploying a large number of bastion instances, all of them checking into the same parent account for IAM queries in reponse to load balancer health checks on port 22 causes IAM rate limiting from AWS. Using the modified EC2 host sshd of port 2222 avoids this issue and is recommended for larger deployments. The host sshd is set to port 2222 as part of the service setup so this heathcheck is not entirely invalid. Security group rules are conditionally created to support any combination of access/healthceck on port 2222 or not.

**Feature:** Friendlier DNS and hostnaming. You can now define the last part of the hostname. By default this is the vpc ID via the magic default value of 'vpc_id' but you can pass a custom string, or an empty value to omit this. e.g. 

 module default: `dev-ap-northeast-1-vpc-1a23b456d7890-bastion-service.yourdomain.com`
 
  `bastion_vpc_name  = "compute"` gives `dev-ap-northeast-1-compute-bastion-service.yourdomain.com`

  `bastion_vpc_name = ""` gives ` dev-ap-northeast-1-bastion-service.yourdomain.com`

  In the last case the service container shell prompt is set similar to `you@dev-ap-northeast-1_3`

**Feature:** Route 53 record creation is now optional. If you do not supply a value for route53_zone_id then no record will be created. Value for dns_domain has also been made optional in support of this. New outputs: elb_dns_name and elb_zone_id have been made available to support alternative options.

**Feature:** Service container Ubuntu version is now a variable. Tested with 16.04 (default) and 18.04. With other releases YMMV.

# 3.6 (tested!) 
## With special thanks to Luis Silva for his excellent contributions

**Bugfix:** This version fixes breakage bugs in 3.4; 3.5 and has been tested!

**Feature:** This release introduces separate security groups for the load balancer and for the service EC2 host. It is now only possible to reach the ec2 host via the load balancer, even on a public subnet. This is true for both the containerised ssh service on port 22 and the ecs host sshd on port 2222 (if enabled). No public IP address is assigned.

**Feature:** New output: bastion_sg_id gives the Security Group id of the bastion host which may be useful for other services

**Documentation:** update readme to reflect new ouptputs and names; acknowledgements

# 3.5 (broken, withdrawn)

**Bugfix:** Remove parentheses from the name of the sample policy ouptut to make it parsable when called from module

# 3.4 (broken, withdrawn)

**N.B. This change means that it is not possible to successfully apply module version 3.4 over version 3.3- you will need to terraform destroy; terraform apply in this case**

**Feature/Bugfix:** This version moves from using 'aws_security_group' to 'aws_security_group_rule' for ingress and egress rules. This supports the use of conditional logic in Terraform to evaluate creating a security group rule on ec2-host-sshd access. If a cidr range or list of ranges is given for cidr_blocks_whitelist_host then this rule will be created and appended to the security group. If no value is given then this rule will not be created. This resolves the undesirable behaviour where if no value was given for cidr_blocks_whitelist_host Terraform would want to recreate the security group each time. Although this worked it relied on silent failure which is inelegant and noisy. 

# 3.3

**Feature (backward compatible):** make service host pem key optional as supported by AWS

# 3.2

**Bugfix:** Correct template paths so that plan can be successfully called as a module and not just standalone.

# 3.1

**Feature (backward compatible):** Improvements to example asssume role policy generation - making it easier to copy and paste from Terraform output to AWS web console

# 3.0

With version 3 series (backward compatible with version 2) the ability to assume a role in another account has now been integrated with conditional logic. If you supply the ARN for a role for the bastion service to assume in another account ${var.assume_role_arn} then this plan will create an instance profile, role and policy along with each bastion to make use of it. A matching sample policy and trust relationship is given as an output from the plan to assist with application in the other account. If you do not supply this arn then this plan presumes IAM lookups in the same account and creates an appropriate instance profile, role and policies for each bastion in the same AWS account. 'Each bastion' here refers to a combination of environment, AWS account, AWS region and VPCID determined by deployment. Since this is a high availabilty service, it is not envisaged that there would be reason for more than one independent deployment within such a combination. 

Also with version 3 the IAM policy generation and user data have been moved from modules back into the main plan. User data is no longer displayed. 

If you are seeking a solution for ECS hosts then you are recommended to either the [Widdix project]((https://github.com/widdix/aws-ec2-ssh)) directly or my [Ansible-galaxy respin of it](https://galaxy.ansible.com/joshuamkite/aws-ecs-iam-users-tags/). This offers a range of features, suitable for a long-lived stateful host built.

# 2.0 

Breaking Changes from version 1.x series
In version 1.0 (download this release if you want it!) this plan deployed a simple static host. With the version 2 branch a move has been made to make this a high availability service with an autoscaling group, health checks and a load balancer. This has necessitated the removal of the feature in version 1.x of creating and attaching to the container host an Elastic Network Interface for each additional subnet specified. With the new branch additional subnets are supplied instead to the autoscaling group and load balancer. The expectation is that separation will be managed by vpc rather than segregated subnet. The VPC-id is also integrated into the DNS entry to permit multiple deployments to different vpc's within a single region.

# 1.1

## Thanks to Piotr Jaromin for implementing these features

* S3 bucket is no longer necessary, golang script for iam-authorized-command is stored inside this repository.
* IAM roles are generated based on region and environment role, so there should be no more conflicts.
* Added additional user-data file to output variables, it can be used to populate ecs/k8s nodes(based on amazon linux image), to allow sshing from bastion into nodes.
* Added tags variable ( it will attach additional tags to aws resources)
