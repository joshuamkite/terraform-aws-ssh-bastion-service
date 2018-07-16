**N.B. It is not possible to successfully apply module version >/=3.4 over version </=3.3 due to change from 'aws_security_group' to aws_security_group_rules' you will need to terraform destroy; terraform apply in this case**

# 3.7

**Feature:** ELB health check port may be optionally set to either port 22 (containerised service; default) or port 2222 (EC2 host sshd). If you are deploying a large number of bastion instances, all of them checking into the same parent account for IAM queries in reponse to load balancer health checks on port 22 causes IAM rate limiting from AWS. Using the modified EC2 host sshd of port 2222 avoids this issue and is recommended for larger deployments. The host sshd is set to port 2222 as part of the service setup so this heathcheck is not entirely invalid. Security group rules are conditionally created to support any combination of access/healthceck on port 2222 or not.

**Feature:** Friendlier DNS and hostnaming. You can now define the last part of the hostname. By default this is the vpc ID via the magic default value of 'vpc_id' but you can pass a custom string, or an empty value to omit this. e.g. 

 default: dev-ap-northeast-1-vpc-1a23b456d7890-bastion-service.yourdomain.com
 
  `bastion_vpc_name  = "compute"` gives `dev-ap-northeast-1-compute-bastion-service.yourdomain.com`


**Feature:** Route 53 record creation is now optional. If you do not supply a value for route53_zone_id then no record will be created. Value for dns_domain has also been made optional in support of this. New outputs: elb_dns_name and elb_zone_id have been made available to support alternative options.

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