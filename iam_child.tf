#role in child account

data "aws_iam_policy_document" "bastion_service_assume_role" {
  count = "${local.assume_role_yes}"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "ec2:*",
    ]
  }
}

resource "aws_iam_role" "bastion_service_assume_role" {
  name               = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion_service_role"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_service_assume_role.json}"
}

#Instance profile
resource "aws_iam_instance_profile" "bastion_service_assume_role_profile" {
  name  = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion_service_asume_role_profile"
  count = "${local.assume_role_yes}"

  role = "${aws_iam_role.bastion_service_assume_role.name}"
}

#policy to parent account
resource "aws_iam_policy" "bastion_service_assume_role_policy" {
  name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_lookup_users_in_parent_account"

  description = "Allow querying parent AWS account to obtain list of users with their ssh public keys"
  count       = "${local.assume_role_yes}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": [
                "arn:aws:iam::144992683770:role/bastion-assume-role-poc"
            ]
        }
    ]
}
EOF
}
