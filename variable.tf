terraform {
    backend "s3" {
        bucket = "tf.ci.internal"
        key    = "terraform.tfstate"
        region = "us-east-2"
    }
}
variable "region" {
    default = "us-east-2"
}

variable "docker-ami" {
    default = "ami-d63610b3"
}

variable "project" {
    default = "ci"
}

variable "bastion-key" {
    default = {
        "public_key_path"  = "/keys/bastion.pub"
        "private_key_path" = "/keys/bastion"
        "aws_key_name"     = "bastion"
    }
}
variable "node-key" {
    default = {
        "public_key_path"  = "/keys/node.pub"
        "private_key_path" = "/keys/node"
        "aws_key_name"     = "node"
    }
}
