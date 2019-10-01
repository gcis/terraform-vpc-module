module "vpc" {
  source = "git::ssh://git@github.com/gcis/terraform-vpc-module.git?ref=v0.1"
  name                   = "Default-terraform-VPC"
  cidr                   = "172.18.0.0/16"
  public_subnets_cidrs   = ["172.18.0.0/24", "172.18.1.0/24", "172.18.2.0/24"]
  private_subnets_cidrs  = ["172.18.4.0/23", "172.18.6.0/23", "172.18.8.0/23"]
  database_subnets_cidrs = ["172.18.10.0/24", "172.18.11.128/24", "172.18.12.0/24"]
  single_nat_gateway     = true

  vpc_tags = {
    Environment = "standard-vpc"
    Terraform   = "true"
    Type        = "vpc"
    Billing     = "standard-vpc"
  }
}

#################################################################
# TODO
# Entry for route tables needs to be added through data objects
# https://www.terraform.io/docs/providers/aws/d/route_table.html
# get subnets from output and route tables for each subnet
#################################################################


###############################################################
# The output is not inherited from the module *yet*
# See issue https://github.com/hashicorp/terraform/issues/1940
###############################################################
output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnets_ids" {
  value = "${module.vpc.subnet_public_ids}"
}

output "public_subnets_cidrs" {
  value = "${module.vpc.subnet_public_cidrs}"
}

output "private_subnets_ids" {
  value = "${module.vpc.subnet_private_ids}"
}

output "private_subnets_cidrs" {
  value = "${module.vpc.subnet_private_cidrs}"
}

output "database_subnets" {
  value = "${module.vpc.subnet_database_ids}"
}

output "vpc_cidr" {
  value = "${module.vpc.vpc_cidr}"
}