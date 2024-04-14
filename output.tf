output "alb_arn" {
  value       = aws_lb.app_alb.arn
  description = "The ARN of the Application Load Balancer"
}

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "waf_web_acl_arn" {
  value       = aws_wafv2_web_acl.main_acl.arn
  description = "The ARN of the Web ACL associated with the ALB"
}

output "security_group_id" {
  value       = aws_security_group.alb_sg.id
  description = "The ID of the security group attached to the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app_tg.arn
  description = "The ARN of the target group used with the ALB"
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "db_username" {
  value = aws_db_instance.db.username
}

output "db_password_ssm" {
  value = aws_ssm_parameter.db_password.name
}

output "db_name" {
  value = aws_db_instance.db.identifier
}

output "db_id" {
  value = aws_db_instance.db.id
}

output "efs_file_system_id" {
  value = aws_efs_file_system.app_efs.id
}
