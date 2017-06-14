module "vpc" {
    source  = "github.com/lancekuo/tf-vpc"

    project = "${var.project}"
    region  = "${var.region}"
}

module "jenkins" {
    source                   = "github.com/lancekuo/tf-jenkins"

    project                  = "${var.project}"
    region                   = "${var.region}"

    ami                      = "${var.docker-ami}"
    domain                   = "lancekuo.com"
    vpc_default_id           = "${module.vpc.vpc_default_id}"

    bastion_public_key_path  = "${var.bastion-key["public_key_path"]}"
    bastion_private_key_path = "${var.bastion-key["private_key_path"]}"
    bastion_aws_key_name     = "${var.bastion-key["aws_key_name"]}"
    node_public_key_path     = "${var.node-key["public_key_path"]}"
    node_private_key_path    = "${var.node-key["private_key_path"]}"
    node_aws_key_name        = "${var.node-key["aws_key_name"]}"

    subnet_public            = "${module.vpc.subnet_public}"
    subnet_public_app        = "${module.vpc.subnet_public_app}"
    subnet_private           = "${module.vpc.subnet_private}"

    availability_zones       = "${module.vpc.availability_zones}"
    subnet_per_zone          = "${module.vpc.subnet_per_zone}"
    instance_per_subnet      = "${module.vpc.instance_per_subnet}"
    subnet_on_public         = "${module.vpc.subnet_on_public}"

    jenkins_node_count       = "1"
}

module "registry" {
    source                   = "github.com/lancekuo/tf-registry"

    project                  = "${var.project}"
    region                   = "${var.region}"

    vpc_default_id           = "${module.vpc.vpc_default_id}"
    bastion_public_ip        = "${module.jenkins.bastion_public_ip}"
    bastion_private_ip       = "${module.jenkins.bastion_private_ip}"
    bastion_private_key_path = "${var.bastion-key["private_key_path"]}"

}

module "script" {
    source                   = "github.com/lancekuo/tf-tools"

    project                  = "${var.project}"
    region                   = "${var.region}"
    bucket_name              = "${var.s3-bucket_name}"
    filename                 = "${var.s3-filename}"
    s3-region                = "${var.s3-region}"
    node_list                = "${module.jenkins.node_private_ip}"
}

