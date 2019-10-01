terraform {
  required_version = ">= 0.11.8" # introduction of Local Values configuration language feature
}

######################################################
# Get the availability zones for the specified region
######################################################
data "aws_availability_zones" "available" {}

locals {
  azs = "${data.aws_availability_zones.available.names}"
}

######
# VPC 
######
resource "aws_vpc" "main" {
  cidr_block                       = "${var.cidr}"
  enable_dns_hostnames             = "${var.dns_hostnames}"
  enable_dns_support               = "${var.dns_support}"
  assign_generated_ipv6_cidr_block = "${var.enable_ipv6}"

  tags = "${merge(
            var.vpc_tags,
            map("Name", format("%s", var.name))
          )}"
}

#################
# Public subnets
#################
resource "aws_subnet" "public" {
  count                   = "${length(local.azs)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.public_subnets_cidrs, count.index)}"
  availability_zone       = "${element(local.azs, count.index)}"
  map_public_ip_on_launch = true

  tags = "${merge(
            var.vpc_tags,
            map("Type", "public-subnet"),
            map("Name", format("%s-public-%s", var.name, element(local.azs, count.index)))
          )}"
}

##################
# Private subnets
##################
resource "aws_subnet" "private" {
  count                   = "${length(local.azs)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.private_subnets_cidrs, count.index)}"
  availability_zone       = "${element(local.azs, count.index)}"
  map_public_ip_on_launch = false

  tags = "${merge(
            var.vpc_tags,
            map("Type", "private-subnet"),
            map("Name", format("%s-private-%s", var.name, element(local.azs, count.index)))
          )}"
}

###################
# Database subnets
###################
resource "aws_subnet" "database" {
  count                   = "${length(local.azs)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.database_subnets_cidrs, count.index)}"
  availability_zone       = "${element(local.azs, count.index)}"
  map_public_ip_on_launch = false

  tags = "${merge(
            var.vpc_tags,
            map("Type", "database-subnet"),
            map("Name", format("%s-database-%s", var.name, element(local.azs, count.index)))
          )}"
}

################################
# Database default subnet group
################################
resource "aws_db_subnet_group" "default" {
  count       = "${var.create_database_subnet_group ? 1 : 0}"
  name        = "${format("%s-db-subnet-group", lower(var.name))}"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = ["${aws_subnet.database.*.id}"]

  tags = "${merge(
                  var.vpc_tags, 
                  map("Name", format("%s-db-subnet-group", var.name))
              )}"
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(
              var.vpc_tags,
              map("Type", "internet-gateway"),
              map("Name", format("%s-internet-gateway", var.name))
            )}"
}

###############################
# Elastic IPs and Nat Gateways
###############################
locals {
  num_nat = "${var.single_nat_gateway ? 1 : length(local.azs)}"
}

resource "aws_eip" "nat_ip" {
  count = "${var.create_nat_gateways ? local.num_nat : 0}"
  vpc   = true

  tags = "${merge(
            var.vpc_tags, 
            map("Name", format("%s-%s", var.name, element(local.azs, count.index)))
          )}"
}

resource "aws_nat_gateway" "main" {
  count         = "${var.create_nat_gateways ? local.num_nat : 0}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat_ip.*.id, count.index)}"

  tags = "${merge(
            var.vpc_tags, 
            map("Name", format("%s-%s", var.name, element(local.azs, count.index)))
          )}"
}

#####################
# Public route table
#####################
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(
            var.vpc_tags, 
            map("Name", format("%s-public", var.name))
          )}"
}

resource "aws_route" "public_default" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

#######################
# Private route tables
#######################
resource "aws_route_table" "private" {
  count  = "${local.num_nat}"
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(
            var.vpc_tags, 
            map("Name", format("%s-private", var.name))
          )}"
}

resource "aws_route" "private_default" {
  count                  = "${var.create_nat_gateways ? local.num_nat : 0}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.main.*.id, count.index)}"
}

##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count          = "${length(local.azs)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index))}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(local.azs)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

###############################################
# Create NACL to restrict access to DB subnets
###############################################
resource "aws_network_acl" "database" {
  count  = "${var.restric_db_subnets ? 1 : 0}"
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(
            var.vpc_tags, 
            map("Name", format("%s-db-nacl", var.name))
          )}"
}

resource "aws_network_acl_rule" "database_in" {
  count          = "${var.restric_db_subnets ? length(local.azs) : 0}"
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = "${100 + count.index}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${element(aws_subnet.private.*.cidr_block, count.index)}"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "database_out" {
  count          = "${var.restric_db_subnets ? length(local.azs) : 0}"
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = "${100 + count.index}"
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${element(aws_subnet.private.*.cidr_block, count.index)}"
  from_port      = 0
  to_port        = 0
}
