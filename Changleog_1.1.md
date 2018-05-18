Thanks to Piotr Jaromin for implementing these features

* S3 bucket is no longer necessary, golang script for iam-authorized-command is stored inside this repository.
* IAM roles are generated based on region and environment role, so there should be no more conflicts.
* Added additional user-data file to output variables, it can be used to populate ecs/k8s nodes(based on amazon linux image), to allow sshing from bastion into nodes.
* Added tags variable ( it will attach additional tags to aws resources)