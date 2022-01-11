# This Terraform deploys a stateless containerised sshd bastion service on AWS with IAM based authentication:

**This module requires Terraform 0.13**

- Terraform 0.12.x was _previously_ supported with module version to ~> v5.0
- Terraform 0.11.x was _previously_ supported with module version to ~> v4.0

**N.B. If you are using a newer version of this module when you have an older version deployed, please review the changelog!**

# Overview

This plan provides socket-activated sshd-containers with one container instantiated per connection and destroyed on connection termination or else after 12 hours- to deter things like reverse tunnels etc. The host assumes an IAM role, inherited by the containers, allowing it to query IAM users and request their ssh public keys lodged with AWS.

**It is essential to limit incoming service traffic to whitelisted ports.** If you do not then internet background noise will exhaust the host resources and/ or lead to rate limiting from amazon on the IAM identity calls- resulting in denial of service.

**It is possible to replace the components in userdata and the base AMI with components of your own choosing. The following describes deployment with all sections as provided by module defaults.**

The actual call for public keys is made with a [GO binary](https://github.com/Fullscreen/iam-authorized-keys-command), which is built during host instance intial launch and made available via shared volume in the docker image. In use the Docker container queries AWS for users with ssh keys at runtime, creates local linux user accounts for them and handles their login. The users who may access the bastion service may be restricted to membership of a defined AWS IAM group which is not set up or managed by this plan. When the connection is closed the container exits. This means that users log in _as themselves_ and manage their own ssh keys using the AWS web console or CLI. For any given session they will arrive in a vanilla Ubuntu container with passwordless sudo and can install whatever applications and frameworks might be required for that session. Because the IAM identity checking and user account population is done at container run time and the containers are called on demand, there is no delay between creating an account with a public ssh key on AWS and being able to access the bastion. If users have more than one ssh public key then their account will be set up so that any of them may be used- AWS allows up to 5 keys per user. Aside from the resources provided by AWS and remote public repositories this plan is entirely self contained. There is no reliance on registries, build chains etc.

# This plan is also published on the Terraform Community Module Registry

You may find it more convenient to call it in your plan [directly from the Terraform Community Module Registry](https://registry.terraform.io/modules/joshuamkite/ssh-bastion-service/)

## With thanks and acknowledgments to all contributors!

# Quick start

Ivan Mesic has kindly contributed an example use of this module creating a VPC and a bastion instance within it - see `/examples`

# Custom sections:

You can **specify a custom base AMI** to use for the service host if you wish with var.custom_ami_id. Tested and working using Ubuntu 18.04 as an example ;)

**Userdata has been divided into sections which are individually applicable**. Each is a HEREDOC and may be excluded by assigning any non-empty value to the relevant section variable. The value given is used simply for a logic test and not passed into userdata. If you ignore all of these variables then historic/ default behaviour continues and everything is built on the host instance on first boot (allow 3 minutes on t2.medium).

The variables for these sections are:

- **custom_ssh_populate** - any value excludes default ssh_populate script used on container launch from userdata

- **custom_authorized_keys_command** - any value excludes default Go binary iam-authorized-keys built from source from userdata

- **custom_docker_setup** - any value excludes default docker installation and container build from userdata

- **custom_systemd** - any value excludes default systemd and hostname change from userdata

If you exclude any section then you must replace it with equivalent functionality, either in your base AMI or extra_user_data for a working service. Especially if you are not replacing all sections then be mindful that the systemd service expects docker to be installed and to be able to call the docker container as 'sshd_worker'. The service container in turn references the 'ssh_populate' script which calls 'iam-authorized-keys' from a specific location.

# Ability to assume a role in another account

The ability to assume a role to source IAM users from another account has been integrated with conditional logic. If you supply the ARN for a role for the bastion service to assume (typically in another account) ${var.assume_role_arn} then this plan will create an instance profile, role and policy along with each bastion to make use of it. A matching sample policy and trust relationship is given as an output from the plan to assist with application in the other account. If you do not supply this arn then this plan presumes IAM lookups in the same account and creates an appropriate instance profile, role and policies for each bastion in the same AWS account. 'Each bastion' here refers to a combination of environment, AWS account, AWS region and VPCID determined by deployment. This is a high availabilty service, but if you are making more than one independent deployment using this same module within such a combination then you can specify "service_name" to avoid resource collision.

If you are seeking a solution for ECS hosts then you are recommended to the [Widdix project](https://github.com/widdix/aws-ec2-ssh). This offers IAM authentication for local users with a range of features suitable for a long-lived stateful host built as an AMI or with configuration management tools.

# Service deployed by this plan (presuming default userdata)

This plan creates a network load balancer and autoscaling group with an **optional** DNS entry and an **optional** public IP for the service.

## Default, partial and complete customisation of hostname

You can overwrite the suggested hostname entirely with `var.bastion_host_name.`

You can _instead_ customise just the last part of the hostname if you like with `bastion_vpc_name`. By default this is the vpc ID via the magic default value of 'vpc_id' with the format

name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service.${var.dns_domain}"

e.g.

module default: `dev-ap-northeast-1-vpc-1a23b456d7890-bastion-service.yourdomain.com`

but you can pass a custom string, or an empty value to omit this. e.g.

`bastion_vpc_name = "compute"` gives `dev-ap-northeast-1-compute-bastion-service.yourdomain.com`

`bastion_vpc_name = ""` gives ` dev-ap-northeast-1-bastion-service.yourdomain.com`

In any event this ensures a consistent and obvious naming format for each combination of AWS account and region that does not collide if multiple vpcs are deployed per region.

The container shell prompt is set similarly but with a systemd incremented counter, e.g. for 'aws_user'
aws_user@dev-eu-west-1-vpc_12345688-172:~$

and a subsequent container might have

    aws_user@dev-eu-west-1-vpc_12345688-180:~$

In the case that `bastion_vpc_name = ""` the service container shell prompt is set similar to `you@dev-ap-northeast-1_3`

# In use

It is considered normal to see very highly incremented counters if the load blancer health checks are conducted on the service port.

**It is essential to limit incoming service traffic to whitelisted ports.** If you do not then internet background noise will exhaust the host resources and/ or lead to rate limiting from amazon on the IAM identity calls- resulting in denial of service.

The host is set to run the latest patch release at deployment of Debian Stretch - unless you specify a custom AMI. This Terraform has also been tested working with Ubuntu 18.04 'latest' host, e.g.:

## For Ubuntu 18.04 'latest' host

```bash
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

custom_ami_id = data.aws_ami.ubuntu.id
```

Debian was chosen originally because the socket activation requires systemd but Ubuntu 16.04 did not automatically set up DHCP for additional elastic network interfaces (see version 1 series). Both Debian 10.x 'Buster' and Ubuntu 20.04 'Focal' have breaking changes around repository/package naming and Golang behaviour - look for support for these in a future release - contributions very welcome!

The host sshd is available on port 2222 and uses standard ec2 ssh keying. **The default login username for Debian AMI's is 'admin'**. If you do not whitelist any access to this port directly from the outside world (plan default) then it may be convenient to access from a container during development, e.g. with

    sudo apt install -y curl; ssh -p2222 admin@`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

**Make sure that your agent forwarding is active before attempting this!**

It is advised to deploy to production _without_ ec2 keys to increase security.

If you are interested in specifying your own AMI then be aware that there are many subtle differences in systemd implemntations between different versions, e.g. it is not possible to use Amazon Linux 2 because we need (from Systemd):

- RunTimeMaxSec to limit the service container lifetime. This was introduced with Systemd version 229 (feb 2016) whereas Amazon Linux 2 uses version 219 (Feb 2015) This is a critical requirement.
- Ability to pass through hostname and increment (-- hostname foo%i) from systemd to docker, which does not appear to be supported on Amazon Linux 2. Ths is a 'nice to have' feature.

## IAM user names and Linux user names

_with thanks to michaelwittig and the [Widdix project](https://github.com/widdix/aws-ec2-ssh)_

IAM user names may be up to 64 characters long.

Linux user names may only be up to 32 characters long.

Allowed characters for IAM user names are:

> alphanumeric, including the following common characters: plus (+), equal (=), comma (,), period (.), at (@), underscore (\_), and hyphen (-).

Allowed characters for Linux user names are (POSIX ("Portable Operating System Interface for Unix") standard (IEEE Standard 1003.1 2008)):

> alphanumeric, including the following common characters: period (.), underscore (\_), and hyphen (-).

Therefore, characters that are allowed in IAM user names but not in Linux user names:

> plus (+), equal (=), comma (,), at (@).

This solution will use the following mapping for those special characters in iam usernames when creating linux user accounts on the sshd_worker container:

- `+` => `plus`
- `=` => `equal`
- `,` => `comma`
- `@` => `at`

So for example if we have an iam user called `test@+=,test` (which uses all of the disputed characters)

this username would translate to `testatplusequalcommatest` and they would need to shell in, e.g. with

`ssh testatplusequalcommatest@dev-eu-west-1-bastion-service.yourdomain.com`

## Users should be aware that:

- They are logging on _as themselves_ using an identity _based on_ their AWS IAM identity
- They must manage their own ssh keys using the AWS interface(s), e.g. in the web console under **IAM/Users/Security credentials** and 'Upload SSH public key'.
- The ssh server key is set at container build time. This means that it will change whenever the bastion host is respawned

The following is referenced in "message of the day" on the container:

- They have an Ubuntu userland with passwordless sudo within the container, so they can install whatever they find useful for that session
- Every connection is given a newly instanced container, nothing persists to subsequent connections. Even if they make a second connection to the service from the same machine at the same time it will be a seperate container.
- When they close their connection that container terminates and is removed
- If they leave their connection open then the host will kill the container after 12 hours

## Logging

The sshd-worker container is launched with `-v /dev/log:/dev/log` This causes logging information to be recorded in the host systemd journal which is not directly accessible from the container. It is thus simple to see who logged in and when by interrogating the host, e.g.

    journalctl | grep 'Accepted publickey'

gives information such as

    April 27 14:05:02 dev-eu-west-1-bastion-host sshd[7294]: Accepted publickey for aws_user from 192.168.168.0 port 65535 ssh2: RSA SHA256:*****************************

Starting with release 3.8 it is possible to use the output giving the name of the role created for the service and to appeand addtional user data. This means that you can call this module from a plan specifiying your preferred logging solution, e.g. AWS cloudwatch.

## Note that:

- ssh keys are called only at login- if an account or ssh public key is deleted from AWS whilst a user is logged in then that session will continue until otherwise terminated.

# Notes for deployment

Load Balancer health check port may be optionally set to either port 22 (containerised service) or port 2222 (EC2 host sshd). Port 2222 is the default. If you are deploying a large number of bastion instances, all of them checking into the same parent account for IAM queries in reponse to load balancer health checks on port 22 causes IAM rate limiting from AWS. Using the modified EC2 host sshd of port 2222 avoids this issue, is recommended for larger deployments and is now default. The host sshd is set to port 2222 as part of the service setup so this heathcheck is not entirely invalid. Security group rules, target groups and load balancer listeners are conditionally created to support any combination of access/healthcheck on port 2222 or not.

You can supply list of one or more security groups to attach to the host instance launch configuration within the module if you wish. This can be supplied together with or instead of a whitelisted range of CIDR blocks. It may be useful in an enterprise setting to have security groups with rules managed separately from the bastion plan but of course if you do not assign either a suitable security group or whitelist then you may not be able to reach the service!

## Components (using default userdata)

**EC2 Host OS (debian) with:**

- Systemd docker unit
- Systemd service template unit
- IAM Profile connected to EC2 host
- golang
- go binary compiled from code included in plan and supplied as user data - [sourced from Fullscreen project](https://github.com/Fullscreen/iam-authorized-keys-command)

**IAM Role**

This and all of the following are prefixed with `${var.service_name}` to ensure uniqueness. An appropriate set is created depending on whether or not an external role to assume is referenced for IAM identity checks.

- IAM role
- IAM policies
- IAM instance profile

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

- `golang` is the source and build directory for the go binary
- `iam-helper` is made available as a read-only volume to the docker container as /opt.
- `iam-authorized-keys-command` is the Go binary that gets the users and ssh public keys from aws - it is built during bastion deployment
- `ssh_populate.sh` is the container entry point and populates the local user accounts using the go binary
- `sshd_worker/Dockerfile` is obviously the docker build configuration. It uses Ubuntu 16.04/18.04 from the public Docker registry and installs additional public packages.

## Sample policy for other accounts

If you supply the ARN for an external role for the bastion service to assume `${var.assume_role_arn}` then a matching sample policy and trust relationship is given as an output from the plan to assist with application in that other account for typical operation.

The DNS entry (if created) for the service is also displayed as an output of the format

name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service.${var.dns_domain}"

## Inputs and Outputs

These have been generated with [terraform-docs](https://github.com/segmentio/terraform-docs)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.71.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.bastion-service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.bastion_service_assume_role_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.bastion_service_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.bastion_service_assume_role_in_parent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.check_ssh_authorized_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.bastion_service_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.bastion_service_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.bastion_service_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.check_ssh_authorized_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.bastion-service-host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.bastion-service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.bastion-host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.bastion-service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.bastion-host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.bastion-service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.bastion_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.bastion_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.bastion_host_out](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.host_ssh_in_cond](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_healthcheck_in](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.service_ssh_in](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.debian](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.bastion_service_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bastion_service_assume_role_in_parent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bastion_service_role_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.check_ssh_authorized_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.lb_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [null_data_source.asg-tags](https://registry.terraform.io/providers/hashicorp/null/latest/docs/data-sources/data_source) | data source |
| [template_cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_desired"></a> [asg\_desired](#input\_asg\_desired) | Desired numbers of bastion-service hosts in ASG | `string` | `"1"` | no |
| <a name="input_asg_max"></a> [asg\_max](#input\_asg\_max) | Max numbers of bastion-service hosts in ASG | `string` | `"2"` | no |
| <a name="input_asg_min"></a> [asg\_min](#input\_asg\_min) | Min numbers of bastion-service hosts in ASG | `string` | `"1"` | no |
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | arn for role to assume in separate identity account if used | `string` | `""` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | n/a | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `any` | n/a | yes |
| <a name="input_bastion_allowed_iam_group"></a> [bastion\_allowed\_iam\_group](#input\_bastion\_allowed\_iam\_group) | Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile | `string` | `""` | no |
| <a name="input_bastion_ebs_device_name"></a> [bastion\_ebs\_device\_name](#input\_bastion\_ebs\_device\_name) | Name of bastion instance block device | `string` | `"xvda"` | no |
| <a name="input_bastion_ebs_size"></a> [bastion\_ebs\_size](#input\_bastion\_ebs\_size) | Size of EBS attached to the bastion instance | `number` | `8` | no |
| <a name="input_bastion_host_name"></a> [bastion\_host\_name](#input\_bastion\_host\_name) | The hostname to give to the bastion instance | `string` | `""` | no |
| <a name="input_bastion_instance_types"></a> [bastion\_instance\_types](#input\_bastion\_instance\_types) | List of ec2 types for the bastion host, used by aws\_launch\_template (first from the list) and in aws\_autoscaling\_group | `list` | <pre>[<br>  "t2.small",<br>  "t2.medium",<br>  "t2.large"<br>]</pre> | no |
| <a name="input_bastion_service_host_key_name"></a> [bastion\_service\_host\_key\_name](#input\_bastion\_service\_host\_key\_name) | AWS ssh key *.pem to be used for ssh access to the bastion service host | `string` | `""` | no |
| <a name="input_bastion_vpc_name"></a> [bastion\_vpc\_name](#input\_bastion\_vpc\_name) | define the last part of the hostname, by default this is the vpc ID with magic default value of 'vpc\_id' but you can pass a custom string, or an empty value to omit this | `string` | `"vpc_id"` | no |
| <a name="input_cidr_blocks_whitelist_host"></a> [cidr\_blocks\_whitelist\_host](#input\_cidr\_blocks\_whitelist\_host) | range(s) of incoming IP addresses to whitelist for the HOST | `list(string)` | `[]` | no |
| <a name="input_cidr_blocks_whitelist_service"></a> [cidr\_blocks\_whitelist\_service](#input\_cidr\_blocks\_whitelist\_service) | range(s) of incoming IP addresses to whitelist for the SERVICE | `list(string)` | `[]` | no |
| <a name="input_container_ubuntu_version"></a> [container\_ubuntu\_version](#input\_container\_ubuntu\_version) | ubuntu version to use for service container. Tested with 16.04; 18.04; 20.04 | `string` | `"20.04"` | no |
| <a name="input_custom_ami_id"></a> [custom\_ami\_id](#input\_custom\_ami\_id) | id for custom ami if used | `string` | `""` | no |
| <a name="input_custom_authorized_keys_command"></a> [custom\_authorized\_keys\_command](#input\_custom\_authorized\_keys\_command) | any value excludes default Go binary iam-authorized-keys built from source from userdata | `string` | `""` | no |
| <a name="input_custom_docker_setup"></a> [custom\_docker\_setup](#input\_custom\_docker\_setup) | any value excludes default docker installation and container build from userdata | `string` | `""` | no |
| <a name="input_custom_ssh_populate"></a> [custom\_ssh\_populate](#input\_custom\_ssh\_populate) | any value excludes default ssh\_populate script used on container launch from userdata | `string` | `""` | no |
| <a name="input_custom_systemd"></a> [custom\_systemd](#input\_custom\_systemd) | any value excludes default systemd and hostname change from userdata | `string` | `""` | no |
| <a name="input_delete_network_interface_on_termination"></a> [delete\_network\_interface\_on\_termination](#input\_delete\_network\_interface\_on\_termination) | if network interface created for bastion host should be deleted when instance in terminated. Setting propagated to aws\_launch\_template.network\_interfaces.delete\_on\_termination | `bool` | `true` | no |
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | The domain used for Route53 records | `string` | `""` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | the name of the environment that we are deploying to, used in tagging. Overwritten if var.service\_name and var.bastion\_host\_name values are changed | `string` | `"staging"` | no |
| <a name="input_extra_user_data_content"></a> [extra\_user\_data\_content](#input\_extra\_user\_data\_content) | Extra user-data to add to the default built-in | `string` | `""` | no |
| <a name="input_extra_user_data_content_type"></a> [extra\_user\_data\_content\_type](#input\_extra\_user\_data\_content\_type) | What format is content in - eg 'text/cloud-config' or 'text/x-shellscript' | `string` | `"text/x-shellscript"` | no |
| <a name="input_extra_user_data_merge_type"></a> [extra\_user\_data\_merge\_type](#input\_extra\_user\_data\_merge\_type) | Control how cloud-init merges user-data sections | `string` | `"str(append)"` | no |
| <a name="input_lb_healthcheck_port"></a> [lb\_healthcheck\_port](#input\_lb\_healthcheck\_port) | TCP port to conduct lb target group healthchecks. Acceptable values are 22 or 2222 | `string` | `"2222"` | no |
| <a name="input_lb_healthy_threshold"></a> [lb\_healthy\_threshold](#input\_lb\_healthy\_threshold) | Healthy threshold for lb target group | `string` | `"2"` | no |
| <a name="input_lb_interval"></a> [lb\_interval](#input\_lb\_interval) | interval for lb target group health check | `string` | `"30"` | no |
| <a name="input_lb_is_internal"></a> [lb\_is\_internal](#input\_lb\_is\_internal) | whether the lb will be internal | `string` | `false` | no |
| <a name="input_lb_unhealthy_threshold"></a> [lb\_unhealthy\_threshold](#input\_lb\_unhealthy\_threshold) | Unhealthy threshold for lb target group | `string` | `"2"` | no |
| <a name="input_on_demand_base_capacity"></a> [on\_demand\_base\_capacity](#input\_on\_demand\_base\_capacity) | allows a base level of on demand when using spot | `number` | `0` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Associate a public IP with the host instance when launching | `bool` | `false` | no |
| <a name="input_route53_fqdn"></a> [route53\_fqdn](#input\_route53\_fqdn) | If creating a public DNS entry with this module then you may override the default constructed DNS entry by supplying a fully qualified domain name here which will be used verbatim | `string` | `""` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route53 zoneId | `string` | `""` | no |
| <a name="input_security_groups_additional"></a> [security\_groups\_additional](#input\_security\_groups\_additional) | additional security group IDs to attach to host instance | `list(string)` | `[]` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Unique name per vpc for associated resources- set to some non-default value for multiple deployments per vpc | `string` | `"bastion-service"` | no |
| <a name="input_subnets_asg"></a> [subnets\_asg](#input\_subnets\_asg) | list of subnets for autoscaling group - availability zones must match subnets\_lb | `list(string)` | `[]` | no |
| <a name="input_subnets_lb"></a> [subnets\_lb](#input\_subnets\_lb) | list of subnets for load balancer - availability zones must match subnets\_asg | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS tags that should be associated with created resources | `map(string)` | `{}` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | ID for Virtual Private Cloud to apply security policy and deploy stack to | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_service_assume_role_name"></a> [bastion\_service\_assume\_role\_name](#output\_bastion\_service\_assume\_role\_name) | role created for service host asg - if created with assume role |
| <a name="output_bastion_service_role_name"></a> [bastion\_service\_role\_name](#output\_bastion\_service\_role\_name) | role created for service host asg - if created without assume role |
| <a name="output_bastion_sg_id"></a> [bastion\_sg\_id](#output\_bastion\_sg\_id) | Security Group id of the bastion host |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | aws load balancer arn |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | aws load balancer dns |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | n/a |
| <a name="output_policy_example_for_parent_account_empty_if_not_used"></a> [policy\_example\_for\_parent\_account\_empty\_if\_not\_used](#output\_policy\_example\_for\_parent\_account\_empty\_if\_not\_used) | You must apply an IAM policy with trust relationship identical or compatible with this in your other AWS account for IAM lookups to function there with STS:AssumeRole and allow users to login |
| <a name="output_service_dns_entry"></a> [service\_dns\_entry](#output\_service\_dns\_entry) | dns-registered url for service and host |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | aws load balancer target group arn |
