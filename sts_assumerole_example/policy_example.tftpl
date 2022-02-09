
#############################
#In order for Bastion service to work with child role  you need to supply the arn of a role in the parent account with a policy similar to the below
#############################
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
            "Resource": [
                "*"
            ]
        }
    ]
}

#############################
#and a trust relationship similar to the below
#############################

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${aws_profile}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}

##############################

Users must be in the ${bastion_allowed_iam_group} group in that account and the role name must match the role name given here (after the '/'):

${assume_role_arn}
