output "openproject_url" {
  description = "URL to access OpenProject"
  value       = "http://${aws_eip.openproject.public_ip}"
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.openproject.id
}

output "public_ip" {
  description = "Elastic IP of the instance"
  value       = aws_eip.openproject.public_ip
}
