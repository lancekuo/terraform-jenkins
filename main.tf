module "vpc" {
    source                         = "github.com/lancekuo/tf-vpc"

    project                        = "${var.project}"
    aws_region                     = "${var.aws_region}"
    aws_profile                    = "${var.aws_profile}"

    count_bastion_subnet_on_public = "${var.count_bastion_subnet_on_public}"
    count_public_subnet_per_az     = "${var.count_public_subnet_per_az}"
    count_private_subnet_per_az    = "${var.count_private_subnet_per_az}"
}

module "jenkins" {
    source                         = "github.com/lancekuo/tf-jenkins"

    project                        = "${var.project}"
    aws_region                     = "${var.aws_region}"
    aws_profile                    = "${var.aws_profile}"

    aws_ami_docker                 = "${var.aws_ami_docker}"
    domain                         = "lancekuo.com"
    vpc_default_id                 = "${module.vpc.vpc_default_id}"

    instance_type_bastion          = "${var.instance_type_bastion}"
    instance_type_node             = "${var.instance_type_node}"

    rsa_key_bastion                = "${var.rsa_key_bastion}"
    rsa_key_node                   = "${var.rsa_key_node}"

    subnet_public_bastion_ids      = "${module.vpc.subnet_public_bastion_ids}"
    subnet_public_app_ids          = "${module.vpc.subnet_public_app_ids}"
    subnet_private_ids             = "${module.vpc.subnet_private_ids}"
    availability_zones             = "${module.vpc.availability_zones}"

    count_bastion_subnet_on_public = "${var.count_bastion_subnet_on_public}"
    count_instance_per_az          = "${var.count_instance_per_az}"
    count_jenkins_node             = "1"
}

module "registry" {
    source                   = "github.com/lancekuo/tf-registry"

    project                  = "${var.project}"
    aws_region               = "${var.aws_region}"
    aws_profile              = "${var.aws_profile}"


    vpc_default_id           = "${module.vpc.vpc_default_id}"
    security_group_node_id   = "${module.jenkins.security_group_node_id}"
    bastion_public_ip        = "${module.jenkins.bastion_public_ip}"
    bastion_private_ip       = "${module.jenkins.bastion_private_ip}"
    rsa_key_bastion          = "${var.rsa_key_bastion}"

    route53_internal_zone_id = "${module.vpc.route53_internal_zone_id}"
    s3_bucketname_registry   = "${var.s3_bucketname_registry}"
}

module "script" {
    source                   = "github.com/lancekuo/tf-tools"

    project                  = "${var.project}"
    region                   = "${var.aws_region}"
    bucket_name              = "${var.terraform_backend_s3_bucketname}"
    filename                 = "${var.terraform_backend_s3_filename}"
    s3-region                = "${var.terraform_backend_s3_region}"
    node_list                = "${module.jenkins.node_private_ip}"

    enable_s3_backend        = false
}

output "Jenkins-DNS" {
    value = "${module.jenkins.elb_jenkins_dns}"
}
output "Registry-pull-access" {
    value = "${module.registry.access}"
}
output "Registry-pull-secret" {
    value = "${module.registry.secret}"
}
output "Registry-Internal-DNS" {
    value = "${module.registry.registry_internal_dns}"
}
output "SSH-Config" {
    value = "${module.script.ssh_config}"
}
