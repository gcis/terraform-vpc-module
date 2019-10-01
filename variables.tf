variable "name" {
  description = "VPC name, also used for tags"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  default     = ""
}

variable "dns_hostnames" {
  description = "Enable DNS hostnames for the VPC"
  default     = true
}

variable "dns_support" {
  description = "Enable DNS support for the VPC"
  default     = true
}

variable "enable_ipv6" {
  description = "The CIDR block for the VPC"
  default     = false
}

variable "public_subnets_cidrs" {
  description = "A list of public subnets inside the VPC"
  default     = []
}

variable "private_subnets_cidrs" {
  description = "A list of private subnets inside the VPC"
  default     = []
}

variable "database_subnets_cidrs" {
  type        = "list"
  description = "A list of database subnets"
  default     = []
}

variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created"
  default     = true
}

variable "create_nat_gateways" {
  description = "Wheter create or not the NAT gateway"
  default     = true
}

variable "single_nat_gateway" {
  description = "Specify if a single nat should be created"
  default     = false
}

variable "restric_db_subnets" {
  description = "Restrics db subnets access just to private networks using NACL"
  default     = true
}

variable "vpc_tags" {
  description = "Map of tags for the VPC and resources"
  default     = {}
}
