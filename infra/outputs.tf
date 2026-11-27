output "openproject_url" {
  description = "URL to access OpenProject (first boot takes several minutes)"
  value       = module.compute.openproject_url
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "rds_endpoint" {
  description = "Private endpoint of RDS PostgreSQL"
  value       = "${module.database.address}:${module.database.port}"
}

output "elasticache_endpoint" {
  description = "Private endpoint of ElastiCache Memcached"
  value       = module.cache.endpoint
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards/dashboard/${module.observability.dashboard_name}"
}

output "ssm_connect_command" {
  description = "Command to open a shell on the instance through SSM Session Manager"
  value       = "aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region}"
}
