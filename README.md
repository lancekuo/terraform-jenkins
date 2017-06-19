# Terraform with Jenkins
## Import Resources
Import predefined resources before you `terraform apply`
- module.registry.aws_s3_bucket.registry registry.hub.internal
- module.jenkins.aws_ebs_volume.storage-jenkins