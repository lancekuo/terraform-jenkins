# Terraform with Jenkins
##0. Install awscli with profile setup
Install awscli and configure your access key secret token into it.
##1. Initialize Terraform module
```language
terraform get
```
##2. Initialize Terraform backend
Make sure you are able to access the S3 bucket that setup in variable.tf
```language
terraform {
    backend "s3" {
        bucket = "tf.ci.internal"
        key    = "terraform.tfstate"
        region = "us-east-2"
    }
}

```
Then,
```language
terraform init
```
##3. Generate SSH key for bastion and node instance
```language
ssh-keygen -t rsa -b 4096 -f keys/node
ssh-keygen -t rsa -b 4096 -f keys/bastion
```
##4. Persistent stroage
Import predefined resources
```language
terraform import module.registry.aws_s3_bucket.registry registry.hub.internal
terraform import module.jenkins.aws_ebs_volume.storage-jenkins
```
##5. Apply~~
```language
terraform apply
```

##6. Get ssh config
```language
ruby keys/ssh_config_ci-continuous-integration.rb
ssh continuous-integration-ci-bastion-0
```

##Additional
Teardown steps
```language
terraform state rm module.registry.aws_s3_bucket.registry
terraform state rm module.jenkins.aws_ebs_volume.storage-jenkins
terrafrom destroy
```