#role in child account

resource "aws_iam_role" "bastion_service_assume_role" {
  name = var.service_name == "bastion-service" ? format(
    "%s-%s-%s_bastion",
    var.environment_name,
    data.aws_region.current.name,
    var.vpc,
  ) : var.service_name
  count              = local.assume_role_yes
  assume_role_policy = data.aws_iam_policy_document.bastion_service_assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "bastion_service_assume_role" {
  count = local.assume_role_yes

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
  name = var.service_name == "bastion-service" ? format(
    "%s-%s-%s_bastion",
    var.environment_name,
    data.aws_region.current.name,
    var.vpc,
  ) : var.service_name
  count = local.assume_role_yes
  role  = aws_iam_role.bastion_service_assume_role[0].name
}

data "aws_iam_policy_document" "bastion_service_assume_role_in_parent" {
  count = local.assume_role_yes

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      var.assume_role_arn,
    ]
  }
}

resource "aws_iam_policy" "bastion_service_assume_role_in_parent" {
  count = local.assume_role_yes
  name = var.service_name == "bastion-service" ? format(
    "%s-%s-%s_bastion",
    var.environment_name,
    data.aws_region.current.name,
    var.vpc,
  ) : var.service_name
  policy = data.aws_iam_policy_document.bastion_service_assume_role_in_parent[0].json
}

resource "aws_iam_role_policy_attachment" "bastion_service_assume_role" {
  role       = aws_iam_role.bastion_service_assume_role[0].name
  count      = local.assume_role_yes
  policy_arn = aws_iam_policy.bastion_service_assume_role_in_parent[0].arn
}

