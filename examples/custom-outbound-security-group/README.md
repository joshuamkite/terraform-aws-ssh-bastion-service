This example for more advanced use shows a complete setup for a new `bastion` service with all needed parts using a single AWS account similar to the sibling `examples/full-with-public-ip`.:

* a new VPC,
* private subnet(s) inside the VPC,
* an internet gateway and route tables.

**Additionally** a custom security group is substituted for all external IP ingress/egress, permitting only:

VPC egress ports:

- 53(UDP)
- 80(TCP)
- 443(TCP) 

open for 0.0.0.0/0

VPC ingress: 

- port 443(TCP)

open for 0.0.0.0/0

ssh is configured in the container to run on port 443 so connect with 

```bash
ssh -p 443 user@load_balancer_dns_output_value
```

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
| [aws_security_group.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.in_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.out_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.out_53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.out_80_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Default AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_bastion_service_port"></a> [bastion\_service\_port](#input\_bastion\_service\_port) | Port for containerised ssh daemon | `number` | `443` | no |
| <a name="input_cidr-start"></a> [cidr-start](#input\_cidr-start) | Default CIDR block | `string` | `"10.50"` | no |
| <a name="input_custom_cidr"></a> [custom\_cidr](#input\_custom\_cidr) | CIDR for custom security gtoup ingress | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | n/a | `string` | `"demo"` | no |
| <a name="input_everyone_cidr"></a> [everyone\_cidr](#input\_everyone\_cidr) | Everyone | `string` | `"0.0.0.0/0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags aplied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_service_role_name"></a> [bastion\_service\_role\_name](#output\_bastion\_service\_role\_name) | role created for service host asg - if created without assume role |
| <a name="output_bastion_sg_id_custom"></a> [bastion\_sg\_id\_custom](#output\_bastion\_sg\_id\_custom) | Custom (external) Security Group id of the bastion host |
| <a name="output_bastion_sg_id_module"></a> [bastion\_sg\_id\_module](#output\_bastion\_sg\_id\_module) | Sbuilt-in security Group id of the bastion host |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | aws load balancer arn |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | aws load balancer dns |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | n/a |
