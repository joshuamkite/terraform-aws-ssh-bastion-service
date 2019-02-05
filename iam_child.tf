#role in child account

resource "aws_iam_role" "bastion_service_assume_role" {
  name = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"

  count              = "${local.assume_role_yes}"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_service_assume_role.json}"
  tags               = "${var.tags}"
}

data "aws_iam_policy_document" "bastion_service_assume_role" {
  count = "${local.assume_role_yes}"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

#Instance profile
resource "aws_iam_instance_profile" "bastion_service_assume_role_profile" {
  name  = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"
  count = "${local.assume_role_yes}"
  role  = "${aws_iam_role.bastion_service_assume_role.name}"
}

data "aws_iam_policy_document" "bastion_service_assume_role_in_parent" {
  count = "${local.assume_role_yes}"

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "${var.assume_role_arn}",
    ]
  }
}

resource "aws_iam_policy" "bastion_service_assume_role_in_parent" {
  count  = "${local.assume_role_yes}"
  name   = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}_bastion"
  policy = "${data.aws_iam_policy_document.bastion_service_assume_role_in_parent.json}"
}

resource "aws_iam_role_policy_attachment" "bastion_service_assume_role" {
  role       = "${aws_iam_role.bastion_service_assume_role.name}"
  count      = "${local.assume_role_yes}"
  policy_arn = "${aws_iam_policy.bastion_service_assume_role_in_parent.arn}"
}
