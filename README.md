This document describes how to build a Jenkins with Docker environment in an AWS VPC using Terraform.

The repository here has three major components.

* Customzied AMI
* Docker environment
* Jenkins

```
              ┌──────────────────────────────┐                  
 ┌───┐  ┌───┐ │ Docker VPC                   │                  
 │ R │  │ E │ │     ┌───────────────────┐    │  ┌──────────────┐
 │ 5 │─▶│ L │─┼────▶│       Node 0      │────┼─▶│ EBS Jenkins  │
 │ 3 │  │ B │ │     └───────────────────┘    │  └──────────────┘
 └───┘  └───┘ │     ┌───────────────────┐    │  ┌──────────────┐
              │     │      Bastion      │────┼─▶│ S3 Registry  │
              │     └─────┬─────────────┘    │  └──────────────┘
 ┌───┐        └───────────┼──────────────────┘                  
 │ R │            .───────▼───────────.                         
 │ 5 │──────────▶(  Private Registry   )                        
 │ 3 │            `───────────────────'                         
 └───┘                                                          
```
## Customzied AMI
It comes in git-submodule and uses [packer.io](https://www.packer.io/) to build our own base image in AWS. The base path for this submodule is under `.packer-docker`

Take a look at `docker.json` to see detailed configuration for the customized AMI. Briefly it takes ubnunt 16.10, docker ce_17.06, docker-machine, docker-compose and AWS CLI installed.

`docker.options` enables `experimental=true` and `insecure-registry` to `10.0.0.0/8`， `192.0.0.0/8` and `172.0.0.0/8` for testing purpose.

### Prerequisites
> Install awscli in your local machine and configure your access key secret token.

### Command
```bash
git submodule init --update
cd .packer-docker
packer build docker.json
```

###### Note 1: For building your own AMI, you need to update three parameters. `region`, `security_group_ids`, `subnet_id`.
###### Note 2: Update README.md and commit into repository when you produce a new AMI.

## Docker Environment
It build up the infrastructure in AWS.
#### Terraform Module [VPC](https://github.com/lancekuo/tf-vpc)
This module build up the fundamental of infrastructure including `VPC`, `Subnet`, `Gateway` and `Route table`.
Also, this module would build up the infrastrucutre for the specific environment and project. For example: `continuous-integration` environment for project `ci`.

You can change/update the environment profile by using Terraform's command.
```bash
terraform workspace -help
```

You can change `project` name and `region` by update `variable.tf`
```bash
variable "project" {
    default = "ci"
}
variable "region" {
    default = "us-east-1"
}
```

#### Terraform Module [Jenkins](https://github.com/lancekuo/tf-jenkins)
This is the primary Terraform module to build the infrastructure for Jenkins. This module would create resources includes,

| Resource        | Purpose                          |
| --------------- | -------------------------------- |
| Bastion         | With EIP                         |
| Node            | With Docker engine ready         |
| Security Groups | Restrict policy                  |
| EBS             | Persist storage attached on Node |
| ELB             | For Jenkins:8080                 |

There are a few parameters that you will need to know.
0. `jenkins_node_count`, how many `node` will be created in total? Default is 1.

###### Those parameters can be found in [VPC module](https://github.com/lancekuo/tf-vpc).

The algorism will spread EC2 instance to all subnets that created by VPC module to make sure we use every availbility zone in specific region to have best HA.

Check [here](https://github.com/lancekuo/tf-jenkins/blob/master/ebs.tf) to know how to fdisk and mount to EC2 instance in first time.

#### Terraform Module [Registry](https://github.com/lancekuo/tf-registry)
This module creates private registry and store images in S3 bucket and the container runs on Bastion machine.
Default Route53_record for private registry is `{ENV}-registry.{PROJECT}.internal`.

| Resource | Purpose                         |
| -------- | ------------------------------- |
| S3       | Private registry run on Bastion |
| Route53  | Point to private registry dns   |

#### Important Note
> Add `/docker` folder under root of the bucket for registry, this is the bug of registry.
```hcl
Bucket: registry.hub.internal
        /docker
```

#### Terraform Module [Script](https://github.com/lancekuo/tf-tools)
Most beautiful feature here, it generate your ssh config file from Terraform state file.
This version comes with Bastion server settings.

### Prerequisites
> Make sure you are able to access the S3 bucket that setup in `variable.tf`
```hcl
terraform {
    backend "s3" {
        bucket = "tf.ci.internal"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
}
```

### Command
**Initialize Terraform**
(one time job)
```bash
terraform get
terraform init
```
**Generate SSH key for bastion and node instance**
(one time job)
```bash
ssh-keygen -q -t rsa -b 4096 -f keys/node -N ''
ssh-keygen -q -t rsa -b 4096 -f keys/bastion -N ''
```
**Import the persistent stroage**

Terraform 0.11.0 has an issue that `import` command couldn't be attached with different aws profile even you have declared in module. Probably I need to rewrite provider section in every module, but that's just in case. If you have multiple AWS profile, move the one you used in creating the resource under `default` section in your `.aws/credential` file before you run `terraform import`.

```bash
terraform import module.jenkins.aws_ebs_volume.storage-jenkins vol-01940bea2da8fd949
terraform import module.registry.aws_s3_bucket.registry hub.private.registry
terraform import module.registry.aws_s3_bucket_object.docker docker/
```
**Modify variable from default.tfvars.example**
```bash
cp default.tfvars.exmaple default.tfvars
```
**Apply**
```bash
terraform apply
```

### Additional

**Update your ssh config**
```bash
ruby keys/ssh_config_*.rb
```

**Teardown the infrastructure**
```bash
terraform state rm module.jenkins.aws_ebs_volume.storage-jenkins
terraform state rm module.registry.aws_s3_bucket.registry
terraform state rm module.registry.aws_s3_bucket_object.docker
terraform destroy
```

## Jenkins
Those docker-compose file brings you the completed Jenkins.

### Command
**Spin up**
```bash
cd jenkins
docker-compose up -d
```

###### tags: amazons web service, aws, terraform, docker, docker swarm