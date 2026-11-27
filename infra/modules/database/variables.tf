variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the RDS instance"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "log_retention_days" {
  description = "Retention of the PostgreSQL log group"
  type        = number
}

variable "db_username" {
  description = "Master username"
  type        = string
}
