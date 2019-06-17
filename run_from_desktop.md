## To Run (from desktop):

 If you are running this as a standalone plan then **You must _thoroughly_ reinitialise the terraform state before running the plan again in a different region of the same AWS account** Failure to do this will result in terraform destroying the IAM policies for the previous host. 

* Set aws-profile for first region
* Initialise backend (for remote state)


	terraform init -backend-config=config/?/config.remote


* Apply terraform plan


	terraform apply -var-file=config/?/config.tfvars


* next region (see note below)

	rm -rf .terraform


* Set aws-profile for next region
* init backend for next region


	terraform init -backend -backend-config=config/?/config.remote


* run plan


	terraform apply -var-file=config/?/config.tfvars

**Note**
During terraform init there can be the question:
Do you want to copy existing state to the new backend?
Just say "no"
It is an issue when switching from different backend inside the same directory
As alternative before you run terraform init you can run "rm -rf .terraform" then this question will not popup