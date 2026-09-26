variable "aws_region" {
  description = "AWS region for DeployForge infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name identifier used for prefixing resource names"
  type        = string
  default     = "deployforge"
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "container_port" {
  description = "Port exposed by the DeployForge FastAPI container"
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "CPU units for the ECS Fargate task (256 = 0.25 vCPU for minimal cost)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory (in MB) for the ECS Fargate task (512 = 0.5 GB for minimal cost)"
  type        = string
  default     = "512"
}

variable "image_tag" {
  description = "Docker image tag for the ECS task definition"
  type        = string
  default     = "latest"
}

variable "vpc_cidr" {
  description = "CIDR block for the DeployForge VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "nat_instance_type" {
  description = "EC2 instance type for the NAT instance (cost-conscious minimal instance)"
  type        = string
  default     = "t3.micro"
}


