variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ, at least two)"
  type        = list(string)
}

variable "http_allowed_cidrs" {
  description = "CIDR blocks allowed to reach OpenProject over HTTP"
  type        = list(string)
}
