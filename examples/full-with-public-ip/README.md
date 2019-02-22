This example shows a complete setup for a new `bastion` service with all needed parts using a single AWS account:

* a new VPC,
* private subnet(s) inside the VPC,
* an internet gateway and route tables.

Before applying, create a key pair in the requested region named 'bastion-demo'.

Because of Terraform limitations (v0.11.x) it can't compute count/length of new resources so it can't generate the `aws_subnets` data block in  [`security_group.tf`](../../security_group.tf). A hack is to first create the VPC and then the rest of the bastion host: comment out the `ssh-bastion-service` module, `terraform apply`, uncomment and `apply` again.
