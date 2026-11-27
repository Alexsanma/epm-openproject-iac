variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
  default     = "epm-openproject"
}

# ---------- Red ----------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.2.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (RDS and ElastiCache)"
  type        = list(string)
  default     = ["10.2.11.0/24", "10.2.12.0/24"]
}

variable "http_allowed_cidrs" {
  description = "CIDR blocks allowed to reach OpenProject over HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------- Computo ----------
variable "instance_type" {
  description = "EC2 instance type (OpenProject recommends 4 GB of RAM)"
  type        = string
  default     = "c7i-flex.large"
}

variable "root_volume_size" {
  description = "Size in GB of the root EBS volume"
  type        = number
  default     = 30
}

variable "openproject_version" {
  description = "Tag of the openproject/openproject Docker image"
  type        = string
  default     = "16"
}

# ---------- Base de datos relacional (RDS) ----------
variable "db_engine_version" {
  description = "PostgreSQL major version for RDS"
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name for OpenProject"
  type        = string
  default     = "openproject"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "openproject"
}

# ---------- Base en memoria (ElastiCache) ----------
variable "cache_engine_version" {
  description = "Memcached engine version"
  type        = string
  default     = "1.6.22"
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

# ---------- Observabilidad ----------
variable "metrics_namespace" {
  description = "CloudWatch namespace for custom metrics"
  type        = string
  default     = "EPM/OpenProject"
}

variable "log_retention_days" {
  description = "Retention in days for CloudWatch log groups"
  type        = number
  default     = 7
}

variable "alert_email" {
  description = "Email to receive alarm notifications (empty = none)"
  type        = string
  default     = ""
}
