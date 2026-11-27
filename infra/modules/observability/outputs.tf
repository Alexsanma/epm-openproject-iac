output "app_log_group" {
  description = "Log group of the OpenProject container"
  value       = aws_cloudwatch_log_group.app.name
}

output "system_log_group" {
  description = "Log group of the instance system logs"
  value       = aws_cloudwatch_log_group.system.name
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alerts_topic_arn" {
  description = "SNS topic for alarms"
  value       = aws_sns_topic.alerts.arn
}
