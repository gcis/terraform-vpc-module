##########
# Outputs
##########

# VPC
output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.main.cidr_block}"
}

# Public networks
output "subnet_public_ids" {
  value = ["${aws_subnet.public.*.id}"]
}

output "subnet_public_cidrs" {
  value = ["${aws_subnet.public.*.cidr_block}"]
}

# Private networks
output "subnet_private_ids" {
  value = ["${aws_subnet.private.*.id}"]
}

output "subnet_private_cidrs" {
  value = ["${aws_subnet.private.*.cidr_block}"]
}

# DB networks
output "subnet_database_ids" {
  value = ["${aws_subnet.database.*.id}"]
}

output "subnet_database_cidrs" {
  value = ["${aws_subnet.database.*.cidr_block}"]
}

# Internet Gateway
output "ig_id" {
  value = "${aws_internet_gateway.main.id}"
}
