variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used by the scripts inside the instance)"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the instance is launched"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group attached to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Size in GB of the root EBS volume"
  type        = number
}

variable "openproject_version" {
  description = "Tag of the openproject/openproject Docker image"
  type        = string
}

variable "db_host" {
  description = "RDS hostname"
  type        = string
}

variable "db_port" {
  description = "RDS port"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN with the RDS master credentials"
  type        = string
}

variable "cache_endpoint" {
  description = "host:port of the memcached node"
  type        = string
}

variable "app_log_group" {
  description = "CloudWatch log group for the OpenProject container"
  type        = string
}

variable "system_log_group" {
  description = "CloudWatch log group for the instance system logs"
  type        = string
}

variable "metrics_namespace" {
  description = "CloudWatch namespace for the agent custom metrics"
  type        = string
}
