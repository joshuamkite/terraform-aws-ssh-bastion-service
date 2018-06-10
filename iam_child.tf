#role in child account

resource "aws_iam_role" "bastion_service_assume_role" {
  name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"

  count = "${local.assume_role_yes}"

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

# resource "aws_iam_role" "bastion_service_assume_role" {
#   count              = "${local.assume_role_yes}"
#   name               = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"
#   assume_role_policy = "${data.aws_iam_policy_document.bastion_service_assume_role_policy.json}"
# }

#Instance profile
resource "aws_iam_instance_profile" "bastion_service_assume_role_profile" {
  name  = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"
  count = "${local.assume_role_yes}"
  role  = "${aws_iam_role.bastion_service_assume_role.name}"
}

#policy to parent account
resource "aws_iam_policy" "bastion_service_assume_role_in_parent" {
  name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_lookup"

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

resource "aws_iam_role_policy_attachment" "bastion_service_assume_role" {
  role       = "${aws_iam_role.bastion_service_assume_role.name}"
  count      = "${local.assume_role_yes}"
  policy_arn = "${aws_iam_policy.bastion_service_assume_role_in_parent.arn}"
}
