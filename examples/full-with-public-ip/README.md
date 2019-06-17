This example shows a complete setup for a new `bastion` service with all needed parts using a single AWS account:

* a new VPC,
* private subnet(s) inside the VPC,
* an internet gateway and route tables.

To create the bastion service, subnets need to already exist
This is currently a limitation of Terraform: https://github.com/hashicorp/terraform/issues/12570
Since Terraform version 0.12.0 you can either: 
Comment out the bastion service, apply, uncomment and apply again (as for Terraform 0.11.x)
Or simply run the plan twice - first time will give an error like below, simply run again

    Error: Provider produced inconsistent final plan

    When expanding the plan for
    module.ssh-bastion-service.aws_autoscaling_group.bastion-service to include
    new values learned so far during apply, provider "aws" produced an invalid new
    value for .availability_zones: was known, but now unknown.

    This is a bug in the provider, which should be reported in the provider's own
    issue tracker.
