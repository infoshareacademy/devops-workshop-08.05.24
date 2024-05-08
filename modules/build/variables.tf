output "instance_security_group_id" {
  value       = aws_security_group.instance_build_sg.id
  description = "ID of build instance security group"
}

output "aws_ssm_parameter_cloudwatch_config" {
  value       = aws_ssm_parameter.cloudwatch.name
  description = "Name of the SSM Parameter which has CloudWatch Agent Configuration"
}
