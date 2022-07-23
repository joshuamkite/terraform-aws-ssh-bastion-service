This example shows a complete setup for a new `bastion` service with all needed parts using a single AWS account:

* a new VPC,
* private subnet(s) inside the VPC,
* an internet gateway and route tables.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.22.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ssh-bastion-service"></a> [ssh-bastion-service](#module\_ssh-bastion-service) | joshuamkite/ssh-bastion-service/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.bastion-ipv4-out](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Default AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_cidr-start"></a> [cidr-start](#input\_cidr-start) | Default CIDR block | `string` | `"10.50"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | n/a | `string` | `"demo"` | no |
| <a name="input_everyone_cidr"></a> [everyone\_cidr](#input\_everyone\_cidr) | Everyone | `string` | `"0.0.0.0/0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags aplied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_service_role_name"></a> [bastion\_service\_role\_name](#output\_bastion\_service\_role\_name) | role created for service host asg - if created without assume role |
| <a name="output_bastion_sg_id"></a> [bastion\_sg\_id](#output\_bastion\_sg\_id) | Security Group id of the bastion host |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | aws load balancer arn |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | aws load balancer dns |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | n/a |
