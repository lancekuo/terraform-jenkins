module "vpc" {
    source  = "./vpc/"

    project = "${var.project}"
    region  = "${var.region}"
}

module "jenkins" {
    source                   = "./jenkins"

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

output "registry" {
    value = "${module.jenkins.registry}"
}
