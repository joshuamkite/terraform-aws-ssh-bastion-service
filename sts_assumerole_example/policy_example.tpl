
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
          "AWS": "${assume_role_arn}"
        },
        "Action": "sts:AssumeRole",
        "Condition": {}
      }
    ]
  }