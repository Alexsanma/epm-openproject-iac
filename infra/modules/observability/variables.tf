variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the dashboard widgets"
  type        = string
}

variable "metrics_namespace" {
  description = "CloudWatch namespace for custom metrics"
  type        = string
}

variable "log_retention_days" {
  description = "Retention of the log groups"
  type        = number
}

variable "alert_email" {
  description = "Email subscribed to the alerts topic (empty = no subscription)"
  type        = string
  default     = ""
}

variable "instance_id" {
  description = "EC2 instance ID"
  type        = string
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "cache_cluster_id" {
  description = "ElastiCache cluster ID"
  type        = string
}
