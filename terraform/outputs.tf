#--------------------------------------------------
# Public Application URL
#--------------------------------------------------
output "website_url" {
  description = "Public URL of the application"

  value = "http://${aws_lb.public.dns_name}"
}

#--------------------------------------------------
# Load Balancers
#--------------------------------------------------
output "public_alb_dns_name" {
  description = "Public Application Load Balancer"

  value = aws_lb.public.dns_name
}

output "internal_alb_dns_name" {
  description = "Internal Application Load Balancer"

  value = aws_lb.internal.dns_name
}

#--------------------------------------------------
# Auto Scaling Groups
#--------------------------------------------------

output "frontend_asg" {
  description = "Frontend Auto Scaling Group"

  value = aws_autoscaling_group.frontend.name
}

output "backend_asg" {
  description = "Backend Auto Scaling Group"

  value = aws_autoscaling_group.backend.name
}

#--------------------------------------------------
# Target Groups
#--------------------------------------------------

output "frontend_target_group" {
  description = "Frontend Target Group ARN"

  value = aws_lb_target_group.frontend.arn
}

output "backend_target_group" {
  description = "Backend Target Group ARN"

  value = aws_lb_target_group.backend.arn
}

#--------------------------------------------------
# Database
#--------------------------------------------------

output "database_endpoint" {
  description = "PostgreSQL endpoint"

  value     = aws_db_instance.postgres.endpoint
  sensitive = true
}

output "database_name" {
  description = "Database name"

  value = aws_db_instance.postgres.db_name
}