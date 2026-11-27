variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the cache subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the cache cluster"
  type        = string
}

variable "engine_version" {
  description = "Memcached engine version"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
}
