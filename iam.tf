#aws iam role for host -same account queries

resource "aws_iam_role" "bastion_service_role" {
  name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"

  count = "${local.assume_role_no}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#########################
#Instance profile to assume role
#########################

resource "aws_iam_instance_profile" "bastion_service_profile" {
  name  = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"
  count = "${local.assume_role_no}"

  role = "${aws_iam_role.bastion_service_role.name}"
}

resource "aws_iam_policy" "check_ssh_authorized_keys" {
  name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_check_ssh_authorized_keys"

  description = "Allow querying aws to obtain list of users with their ssh public keys"
  count       = "${local.assume_role_no}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers",
                "iam:GetGroup",
                "iam:GetSSHPublicKey",
                "iam:ListSSHPublicKeys",
                "iam:GetUser",
                "iam:ListGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeTags",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "check_ssh_authorized_keys" {
  role       = "${aws_iam_role.bastion_service_role.name}"
  count      = "${local.assume_role_no}"
  policy_arn = "${aws_iam_policy.check_ssh_authorized_keys.arn}"
}
