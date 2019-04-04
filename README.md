This Terraform deploys a stateless containerised sshd bastion service on AWS with IAM based authentication:
===================================

**N.B. If you are using a newer version of this module when you have an older version deployed, please review the changelog!**

# Overview

This plan provides socket-activated sshd-containers with one container instantiated per connection and destroyed on connection termination or else after 12 hours- to deter things like reverse tunnels etc. The host assumes an IAM role, inherited by the containers, allowing it to query IAM users and request their ssh public keys lodged with AWS. 

**It is possible to replace the components in userdata and the base AMI with components of your own choosing. The following describes deployment with all sections as provided by module defaults.**

The actual call for public keys is made with a [GO binary](https://github.com/Fullscreen/iam-authorized-keys-command), which is built during host instance intial launch and made available via shared volume in the docker image. In use the Docker container queries AWS for users with ssh keys at runtime, creates local linux user accounts for them and handles their login. The users who may access the bastion service may be restricted to membership of a defined AWS IAM group which is not set up or managed by this plan.  When the connection is closed the container exits. This means that users log in _as themselves_ and manage their own ssh keys using the AWS web console or CLI. For any given session they will arrive in a vanilla Ubuntu container with passwordless sudo and can install whatever applications and frameworks might be required for that session. Because the IAM identity checking and user account population is done at container run time and the containers are called on demand, there is no delay between creating an account with a public ssh key on AWS and being able to access the bastion. If users have more than one ssh public key then their account will be set up so that any of them may be used- AWS allows up to 5 keys per user. Aside from the resources provided by AWS and remote public repositories this plan is entirely self contained. There is no reliance on registries, build chains etc.

# This plan is also published on the Terraform Community Module Registry

You may find it more convenient to call it in your plan [directly from the Terraform Community Module Registry](https://registry.terraform.io/modules/joshuamkite/ssh-bastion-service/)

## With thanks and acknowledgments to all contributors!

# Quick start

Ivan Mesic has kindly contributed an example use of this module creating a VPC and a bastion instance within it - see `/examples`

# Custom sections:

You can now **specify a custom base AMI** to use for the service host if you wish with var.custom_ami_id. Tested and working using Ubuntu 18.04 as an example ;)

 **Userdata has been divided into sections which are now individually applicable**. Each is now a HEREDOC and may be excluded by assigning any non-empty value to the relevant section variable. The value given is used simply for a logic test and not passed into userdata. If you ignore all of these variables then historic/ default behaviour continues and everything is built on the host instance on first boot (allow 3 minutes on t2.medium).

The variables for these sections are:

* **custom_ssh_populate** - any value excludes default ssh_populate script used on container launch from userdata

* **custom_authorized_keys_command** - any value excludes default Go binary iam-authorized-keys built from source from userdata

* **custom_docker_setup** - any value excludes default docker installation and container build from userdata

* **custom_systemd** - any value excludes default systemd and hostname change from userdata

If you exclude any section then you must replace it with equivalent functionality, either in your base AMI or extra_user_data for a working service. Especially if you are not replacing all sections then be mindful that the systemd service expects docker to be installed and to be able to call the docker container as 'sshd_worker'. The service container in turn references the 'ssh_populate' script which calls 'iam-authorized-keys' from a specific location.

# Ability to assume a role in another account

The ability to assume a role to source IAM users from another account has been integrated with conditional logic. If you supply the ARN for a role for the bastion service to assume in another account ${var.assume_role_arn} then this plan will create an instance profile, role and policy along with each bastion to make use of it. A matching sample policy and trust relationship is given as an output from the plan to assist with application in the other account. If you do not supply this arn then this plan presumes IAM lookups in the same account and creates an appropriate instance profile, role and policies for each bastion in the same AWS account. 'Each bastion' here refers to a combination of environment, AWS account, AWS region and VPCID determined by deployment. This is a high availabilty service, but if you are making more than one independent deployment using this same module within such a combination you can specify "service_name" to avoid resource collision. 

If you are seeking a solution for ECS hosts then you are recommended to  the [Widdix project](https://github.com/widdix/aws-ec2-ssh). This offers IAM authentication for local users with a range of features suitable for a long-lived stateful host built as an AMI or with configuratino management tools.

# Service deployed by this plan (presuming default userdata)

This plan creates a network load balancer and autoscaling group with an **optional** DNS entry and an **optional** public IP for the service. 

## Default, partial and complete customisation of hostname

You can overwrite the suggested hostname entirely with `var.bastion_host_name.` 

You can customise just the last part of the hostname if you like. By default this is the vpc ID via the magic default value of 'vpc_id' with the format

  	name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service.${var.dns_domain}"

e.g.

   module default: `dev-ap-northeast-1-vpc-1a23b456d7890-bastion-service.yourdomain.com`
   
but you can pass a custom string, or an empty value to omit this. e.g.    
 
  `bastion_vpc_name  = "compute"` gives `dev-ap-northeast-1-compute-bastion-service.yourdomain.com`

  `bastion_vpc_name = ""` gives ` dev-ap-northeast-1-bastion-service.yourdomain.com`

In any event this ensures a consistent and obvious naming format for each combination of AWS account and region that does not collide if multiple vpcs are deployed per region.

The container shell prompt is set similarly but with a systemd incremented counter, e.g. for 'aws_user'
	
	aws_user@dev-eu-west-1-vpc_12345688-172:~$

and a subsequent container might have

	aws_user@dev-eu-west-1-vpc_12345688-180:~$

In the case that `bastion_vpc_name = ""` the service container shell prompt is set similar to `you@dev-ap-northeast-1_3`

# In use

It is considered normal to see very highly incremented counters if the load blancer health checks are conducted on the service port.

**It is essential to limit incoming service traffic to whitelisted ports** If you do not then internet background noise will exhaust the host resources and/ or lead to rate limiting from amazon on the IAM identity calls- resulting in denial of service.

The host is set to run the latest patch release at deployment of Debian Stretch - unless you specify a custom AMI. Debian was chosen because the socket activation requires systemd but Ubuntu 16.04 did not automatically set up DHCP for additional elastic network interfaces (see version 1 series). **The login username is 'admin'**. The host sshd is available on port 2222 and uses standard ec2 ssh keying. If you do not whitelist any access to this port directly from the outside world (plan default) then it may be convenient to access from a container, e.g. with

    sudo apt install -y curl; ssh -p2222 admin@`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

**Make sure that your agent forwarding is active before attempting this!**


If you are interested in specifying your own AMI then be aware that there are many subtle differences in systemd implemntations between different versions, e.g. it is not possible to use Amazon Linux 2 because we need (from Systemd):

* RunTimeMaxSec to limit the service container lifetime. This was introduced with Systemd version 229 (feb 2016) whereas Amazon Linux 2 uses version 219 (Feb 2015) This is a critical requirement.
* Ability to pass through hostname and increment (-- hostname foo%i) from systemd to docker, which does not appear to be supported on Amazon Linux 2. Ths is a 'nice to have' feature.

## IAM user names and Linux user names

*with thanks to michaelwittig and the [Widdix project](https://github.com/widdix/aws-ec2-ssh)*

IAM user names may be up to 64 characters long.

Linux user names may only be up to 32 characters long.

Allowed characters for IAM user names are:
> alphanumeric, including the following common characters: plus (+), equal (=), comma (,), period (.), at (@), underscore (_), and hyphen (-).

Allowed characters for Linux user names are (POSIX ("Portable Operating System Interface for Unix") standard (IEEE Standard 1003.1 2008)):
> alphanumeric, including the following common characters: period (.), underscore (_), and hyphen (-).

Therefore, characters that are allowed in IAM user names but not in Linux user names:
> plus (+), equal (=), comma (,), at (@).

This solution will use the following mapping for those special characters in iam usernames when creating linux user accounts on the sshd_worker container:

* `+` => `plus`
* `=` => `equal`
* `,` => `comma`
* `@` => `at`

So for example if we have an iam user called `test@+=,test` (which uses all of the disputed characters)

this username would translate to `testatplusequalcommatest` and they would need to shell in, e.g. with

`ssh testatplusequalcommatest@dev-eu-west-1-bastion-service.yourdomain.com`

## Users should be aware that:

* They are logging on _as themselves_ using an identity _based on_ their AWS IAM identity
* They must manage their own ssh keys using the AWS interface(s), e.g. in the web console under **IAM/Users/Security credentials** and 'Upload SSH public key'.
* The ssh server key is set at container build time. This means that it will change whenever the bastion host is respawned

The following is referenced in "message of the day" on the container:

* They have an Ubuntu userland with passwordless sudo within the container, so they can install whatever they find useful for that session
* Every connection is given a newly instanced container, nothing persists to subsequent connections. Even if they make a second connection to the service from the same machine at the same time it will be a seperate container.
* When they close their connection that container terminates and is removed
* If they leave their connection open then the host will kill the container after 12 hours

## Logging

The sshd-worker container is launched with `-v /dev/log:/dev/log` This causes logging information to be recorded in the host systemd journal which is not directly accessible from the container. It is thus simple to see who logged in and when by interrogating the host, e.g.

	journalctl | grep 'Accepted publickey'

gives information such as

	April 27 14:05:02 dev-eu-west-1-bastion-host sshd[7294]: Accepted publickey for aws_user from 192.168.168.0 port 65535 ssh2: RSA SHA256:*****************************

Starting with release 3.8 it is possible to use the output giving the name of the role created for the service and to appeand addtional user data. This means that you can call this module from a plan specifiying your preferred logging solution, e.g. AWS cloudwatch.

## Note that:

* ssh keys are called only at login- if an account or ssh public key is deleted from AWS whilst a user is logged in then that session will continue until otherwise terminated.

# Notes for deployment

Load Balancer health check port may be optionally set to either port 22 (containerised service) or port 2222 (EC2 host sshd). Port 2222 is the default. If you are deploying a large number of bastion instances, all of them checking into the same parent account for IAM queries in reponse to load balancer health checks on port 22 causes IAM rate limiting from AWS. Using the modified EC2 host sshd of port 2222 avoids this issue, is recommended for larger deployments and is now default. The host sshd is set to port 2222 as part of the service setup so this heathcheck is not entirely invalid. Security group rules, target groups and load balancer listeners are conditionally created to support any combination of access/healthcheck on port 2222 or not.

You can a list of one or more security groups to attach to the host instance launch configuration within the module if you wish. This can be supplied together with or instead of a whitelisted range of CIDR blocks. It may be useful in an enterprise setting to have security groups with rules managed separately from the bastion plan but of course if you do not assign either a suitable security group or whitelist then you may not be able to reach the service!

## Components (using default userdata)

**EC2 Host OS (debian) with:**

* Systemd docker unit
* Systemd service template unit
* IAM Profile connected to EC2 host
* golang
* go binary compiled from code included in plan and supplied as user data - [sourced from Fullscreen project](https://github.com/Fullscreen/iam-authorized-keys-command)

**IAM Role**

This and all of the following are prefixed with the bastion service host name to ensure uniqueness. An appropriate set is created depending on whether or not another aws account is referenced for IAM identity checks.

* IAM role
* IAM policies
* IAM instance profile

**Docker container** 'sshd_worker' - built at host launch time using generic ubuntu image, we add awscli; sshd and sudo.

**[Go binary](https://github.com/Fullscreen/iam-authorized-keys-command)** and [forked to a companion repo](https://github.com/joshuamkite/iam-authorized-keys-command).

The files in question on the host deploy thus:

	/opt
	├── golang
	│   ├── bin
	│   ├── pkg
	│   └── src
	├── iam_helper
	│   ├── iam-authorized-keys-command
	│   └── ssh_populate.sh
	└── sshd_worker
	    └── Dockerfile

* `golang` is the source and build directory for the go binary
* `iam-helper` is made available as a read-only volume to the docker container as /opt.
* `iam-authorized-keys-command` is the Go binary that gets the users and ssh public keys from aws - it is built during bastion deployment
* `ssh_populate.sh` is the container entry point and populates the local user accounts using the go binary
* `sshd_worker/Dockerfile` is obviously the docker build configuration. It uses Ubuntu 16.04/18.04 from the public Docker registry and installs additional public packages.

## Sample policy for other accounts
 
If you supply the ARN for a role for the bastion service to assume in another account ${var.assume_role_arn} then a matching sample policy and trust relationship is given as an output from the plan to assist with application in that other account. 

The DNS entry (if created) for the service is also displayed as an output of the format

  	name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service.${var.dns_domain}"

## Inputs and Outputs

These have been generated with [terraform-docs](https://github.com/segmentio/terraform-docs)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| asg_desired | Desired numbers of bastion-service hosts in ASG | string | `1` | no |
| asg_max | Max numbers of bastion-service hosts in ASG | string | `2` | no |
| asg_min | Min numbers of bastion-service hosts in ASG | string | `1` | no |
| assume_role_arn | arn for role to assume in separate identity account if used | string | `` | no |
| aws_profile |  | string | - | yes |
| aws_region |  | string | - | yes |
| bastion_allowed_iam_group | Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile | string | `` | no |
| bastion_host_name | The hostname to give to the bastion instance | string | `` | no |
| bastion_instance_type | The virtual hardware to be used for the bastion service host | string | `t2.micro` | no |
| bastion_service_host_key_name | AWS ssh key *.pem to be used for ssh access to the bastion service host | string | `` | no |
| bastion_vpc_name | define the last part of the hostname, by default this is the vpc ID with magic default value of 'vpc_id' but you can pass a custom string, or an empty value to omit this | string | `vpc_id` | no |
| cidr_blocks_whitelist_host | range(s) of incoming IP addresses to whitelist for the HOST | list | `<list>` | no |
| cidr_blocks_whitelist_service | range(s) of incoming IP addresses to whitelist for the SERVICE | list | `<list>` | no |
| container_ubuntu_version | ubuntu version to use for service container. Tested with 16.04 and 18.04 | string | `16.04` | no |
| custom_ami_id | id for custom ami if used | string | `` | no |
| custom_authorized_keys_command | any value excludes default Go binary iam-authorized-keys built from source from userdata | string | `` | no |
| custom_docker_setup | any value excludes default docker installation and container build from userdata | string | `` | no |
| custom_ssh_populate | any value excludes default ssh_populate script used on container launch from userdata | string | `` | no |
| custom_systemd | any value excludes default systemd and hostname change from userdata | string | `` | no |
| dns_domain | The domain used for Route53 records | string | `` | no |
| environment_name | the name of the environment that we are deploying to | string | `staging` | no |
| extra_user_data_content | Extra user-data to add to the default built-in | string | `` | no |
| extra_user_data_content_type | What format is content in - eg 'text/cloud-config' or 'text/x-shellscript' | string | `text/x-shellscript` | no |
| extra_user_data_merge_type | Control how cloud-init merges user-data sections | string | `str(append)` | no |
| lb_healthcheck_port | TCP port to conduct lb target group healthchecks. Acceptable values are 22 or 2222 | string | `2222` | no |
| lb_healthy_threshold | Healthy threshold for lb target group | string | `2` | no |
| lb_interval | interval for lb target group health check | string | `30` | no |
| lb_is_internal | whether the lb will be internal | string | `false` | no |
| lb_unhealthy_threshold | Unhealthy threshold for lb target group | string | `2` | no |
| public_ip | Associate a public IP with the host instance when launching | string | `false` | no |
| route53_zone_id | Route53 zoneId | string | `` | no |
| security_groups_additional | additional security group IDs to attach to host instance | list | `<list>` | no |
| service_name | Unique name per vpc for associated resources- set to some non-default value for multiple deployments per vpc | string | `bastion-service` | no |
| subnets_asg | list of subnets for autoscaling group - availability zones must match subnets_lb | list | `<list>` | no |
| subnets_lb | list of subnets for load balancer - availability zones must match subnets_asg | list | `<list>` | no |
| tags | AWS tags that should be associated with created resources | map | `<map>` | no |
| vpc | ID for Virtual Private Cloud to apply security policy and deploy stack to | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bastion_service_assume_role_name | role created for service host asg - if created with assume role |
| bastion_service_role_name | role created for service host asg - if created without assume role |
| bastion_sg_id | Security Group id of the bastion host |
| lb_arn | aws load balancer arn |
| lb_dns_name | aws load balancer dns |
| lb_zone_id |  |
| policy_example_for_parent_account_empty_if_not_used | You must apply an IAM policy with trust relationship identical or compatible with this in your other AWS account for IAM lookups to function there with STS:AssumeRole and allow users to login |
| service_dns_entry | dns-registered url for service and host |