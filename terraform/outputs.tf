# ==============================================================================
# DeployForge Infrastructure Outputs
# ==============================================================================

output "ecr_repository_url" {
  description = "The URL of the Amazon ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "The name of the Amazon ECR repository"
  value       = aws_ecr_repository.app.name
}

output "ecs_cluster_name" {
  description = "The name of the Amazon ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "The ARN of the Amazon ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_task_definition_arn" {
  description = "The ARN of the Amazon ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "ecs_task_definition_family" {
  description = "The family of the Amazon ECS task definition"
  value       = aws_ecs_task_definition.app.family
}

output "ecs_execution_role_arn" {
  description = "The ARN of the IAM task execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

# ------------------------------------------------------------------------------
# Networking Outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}

output "ecs_security_group_id" {
  description = "The ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "availability_zones" {
  description = "The availability zones used for the public and private subnets"
  value = [
    aws_subnet.public.availability_zone,
    aws_subnet.private.availability_zone,
  ]
}

# ------------------------------------------------------------------------------
# NAT Instance Outputs
# ------------------------------------------------------------------------------
output "nat_instance_id" {
  description = "The ID of the NAT EC2 instance"
  value       = aws_instance.nat.id
}

output "nat_instance_private_ip" {
  description = "The private IP address of the NAT instance"
  value       = aws_instance.nat.private_ip
}

output "nat_instance_public_ip" {
  description = "The public IP address of the NAT instance"
  value       = aws_instance.nat.public_ip
}

output "nat_security_group_id" {
  description = "The ID of the NAT instance security group"
  value       = aws_security_group.nat.id
}


