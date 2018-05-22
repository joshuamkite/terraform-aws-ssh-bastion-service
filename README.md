This Terraform deploys an sshd bastion service on AWS:
===================================

# Overview

This plan provides socket-activated sshd-containers with one container instantiated per connection and destroyed on connection termination or else after 12 hours- to deter things like reverse tunnels etc. The host assumes an IAM role, inherited by the containers, allowing it to query IAM users and request their ssh public keys lodged with AWS. The actual call for public keys is made with a GO binary,which is built during host launch and made available via shared volume in the docker image. In use the Docker container queries AWS for users with ssh keys at runtime, creates local linux user accounts for them and handles their login. The users who may access the bastion service must be members of a defined AWS IAM group which is not set up or managed by this plan.  When the connection is closed the container exits. This means that users log in _as themselves_ and manage their own ssh keys using the AWS web console or CLI. For any given session they will arrive in a vanilla Ubuntu container with passwordless sudo and can install whatever applications and frameworks might be required for that session. Because the IAM identity checking and user account population is done at container run time and the containers are called on demand, there is no delay between creating an account with a public ssh key on AWS and being able to access the bastion. If users have more than one ssh public key then their account will be set up so that any of them may be used- AWS allows up to 5 keys per user.

**With thanks to  Piotr Jaromin for his excellent contributions to this project**


This plan creates a load balancer and autoscaling group with a dns entry for the service of the format

  	name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service.${var.dns_domain}"

e.g.

	dev-eu-west-1-vpc_12345688-bastion-service.yourdomain.com

this ensures a consistent and obvious naming format for each combination of AWS account and region that does not collide if multiple vpcs are deployed per region.

The container shell prompt is set similarly but with a systemd incremented counter, e.g. for 'aws_user'

    aws_user@dev-eu-west-1_1-172:~$

and a subsequent container would have

    aws_user@dev-eu-west-1_2-172:~$

etc. Sadly the -172 (digits will vary) part is an artefact of systemd unit templating that appears difficult to avoid.

**The host is set to run the latest patch release at deployment of Debian Stretch**. Debian was chosen because the socket activation requires systemd but Ubuntu 16.04 does not automatically set up dhcp for additional elastic network interfaces. **The login username is 'admin'**. The host sshd is available on port 2222 and uses standard ec2 ssh keying. If you do not whitelist any access to this port directly from the outside world (plan default) then it may be convenient to access from a container, e.g. with

    sudo apt install -y curl; ssh -p2222 admin@`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

**Make sure that your agency forwarding is active before attempting this**

# Breaking Changes from version 1.x series

In version 1.0 (download this release if you want it!) this plan deployed a simple static host. With the version 2 branch a move has been made to make this a high availabilty service with an autoscaling group, health checks and a load balancer. This has necessitated the removal of the feature in version 1.x of creating and attaching to the container host an Elastic Network Interface for each additional subnet specified. With the new branch additional subnets are supplied instead to the autoscaling group and load balancer. The expectation is that separation will be managed by vpc rather than segregated subnet. 

# In Use

## IAM user names and Linux user names

*with thanks to [michaelwittig](https://github.com/widdix/aws-ec2-ssh)*

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

* They are logging on _as themselves_ using an identiy _based on_ their AWS IAM identity
* They must manage their own ssh keys using the AWS interface(s), e.g. in the web console under **IAM/Users/Security credentials** and 'Upload SSH public key'.
* The ssh server key is set at container build time. This means that it will change whenever the bastion host is respawned

The following is referenced in "message of the day" on the container:

* They have an Ubuntu userland with passwordless sudo within the container, so they can install whatever they find useful for that session
* Every connection is given a newly instanced container, nothing persists to subsequent connections. Even if they make a second connection to the service from the same machine at the same time it will be a seperate container.
* When they close their connection that container terminates and is removed
* If they leave their connection open then the host will kill the container after 12 hours

## Logging

The sshd-worker container is launched with `v /dev/log:/dev/log` This causes logging information to be recorded in the host systemd journal which is not directly accessible from the container. It is thus simple to see who logged in and when by interrogating the host, e.g.

	journalctl | grep 'Accepted publickey'

gives information such as

	April 27 14:05:02 dev-eu-west-1-bastion-host sshd[7294]: Accepted publickey for aws_user from UNKNOWN port 65535 ssh2: RSA SHA256:*****************************

## Note that:

* ssh keys are called only at login- if an account or ssh public key is deleted from AWS whilst a user is logged in then that session will continue until otherwise terminated.
* At present logging is confined to the host machine- if it is respawned then so are the logs. A remote logging solution is considered beyond the scope of this plan.

# Notes for deployment

## To Run:

 If you are running this as a standalone plan then **You must _thoroughly_ reinitialise the terraform state before running the plan again in a different region of the same AWS account** Failure to do this will result in terraform destroying the IAM policies for the previous host. 

* Set aws-profile for first region
* Initialise backend 


	terraform init -backend -backend-config=config/?/config.remote


* Apply terraform plan


	terraform apply -var-file=config/?/config.tfvars


* next region (see note below)

	rm -rf .terraform


* Set aws-profile for next region
* init backend for next region


	terraform init -backend -backend-config=config/?/config.remote


* run plan


	terraform apply -var-file=config/?/config.tfvars

**Note**
During terraform init there can be the question:
Do you want to copy existing state to the new backend?
Just say "no"
It is an issue when switching from different backend inside the same directory
As alternative before you run terraform init you can run "rm -rf .terraform" then this question will not popup

## Components

**EC2 Host OS (debian) with:**

* awscli
* Systemd docker unit
* Systemd service template unit
* IAM Profile connected to EC2 host
* golang
* go binary compiled from code included in plan and supplied as user data - [sourced from Fullscreen project](https://github.com/Fullscreen/iam-authorized-keys-command)

**IAM Role module**

All of the above are prefixed with the bastion service host name to ensure uniqueness

* IAM role
* IAM policies
* IAM instance profile

**Docker container** 'sshd_worker' - built at host launch time using generic ubuntu image, we add sshd and sudo.

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
* `iam-authorized-keys-command` is the Go binary that gets the users and ssh public keys from aws it is built during bastion deployment
* `ssh_populate.sh` is the container entry point and populates the local user accounts using the go binary
* `sshd_worker/Dockerfile` is obviously the docker build configuration. It uses a static release of Ubuntu (16.04 in dev) from the public Docker registry.

## Outputs useful for other services

Additionally this project contains helper module called `user-data` inside it there are two templates

	/user-data
	└── user_data_template
	    ├── bastion_host_cloudinit_config.tpl
	    └── node_cloudinit_ami_linux.tpl

* `bastion_host_cloudinit_config` is user-data which will be used during bastion startup and is created for debian ec2 images(root module uses it). This config can be obtained as `user_data_bastion` output variable.
* `node_cloudinit_ami_linux` is user-data which can be used by ecs or kubernetes nodes, you can append this user data to your instances and then you will be able to ssh into this nodes using an IAM identity simailr to the bastion service. This user-data file is intended for logging directly into ecs ec2 instances (not inside docker container). It is created for `ami_linux` optimized machines. For now users are updated every 15 minutes, and old ones are not removed. Remember that instances using this user-data should have following policies:
  * iam:ListUsers
  * iam:GetGroup
  * iam:GetSSHPublicKey
  * iam:ListSSHPublicKeys
  * iam:GetUser
  * iam:ListGroups

## Input Variables

These have been generated with [terraform-docs](https://github.com/segmentio/terraform-docs)

A template.tfvars file is included for convenience

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| asg_desired | Desired numbers of bastion-service hosts in ASG | string | `1` | no |
| asg_max | Max numbers of bastion-service hosts in ASG | string | `2` | no |
| asg_min | Min numbers of bastion-service hosts in ASG | string | `1` | no |
| bastion_allowed_iam_group | Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile | string | - | yes |
| bastion_instance_type | The virtual hardware to be used for the bastion service host | string | `t2.micro` | no |
| bastion_service_host_key_name | AWS ssh key *.pem to be used for ssh access to the bastion service host | string | - | yes |
| cidr_blocks_whitelist_host | range(s) of incoming IP addresses to whitelist for the HOST | list | `<list>` | no |
| cidr_blocks_whitelist_service | range(s) of incoming IP addresses to whitelist for the SERVICE | list | - | yes |
| create_iam_service_role | create bastion service role and policies (standalone account) boolean | string | `0` | no |
| dns_domain | The domain used for Route53 records | string | - | yes |
| elb_healthy_threshold | Healthy threshold for ELB | string | `2` | no |
| elb_idle_timeout | The time in seconds that the connection is allowed to be idle | string | `300` | no |
| elb_interval | interval for ELB health check | string | `30` | no |
| elb_timeout | timeout for ELB | string | `3` | no |
| elb_unhealthy_threshold | Unhealthy threshold for ELB | string | `2` | no |
| environment_name | the name of the environment that we are deploying to | string | `staging` | no |
| route53_zone_id | Route53 zoneId | string | - | yes |
| subnets_asg | list of subnets for autoscaling group | list | `<list>` | no |
| subnets_elb | list of subnets for load balancer | list | `<list>` | no |
| tags | AWS tags that should be associated with created resources (except autoscaling group!) | map | `<map>` | no |
| vpc | ID for Virtual Private Cloud to apply security policy and deploy stack to | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| service_dns_entry | dns-registered url for service and host |
| user_data_ami_linux | cloud-config user data used to initialize ami linux instances which are run as ecs/k8s nodes |
| user_data_bastion | cloud-config user data used to initialize bastion at start up |