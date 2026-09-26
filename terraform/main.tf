# ==============================================================================
# DeployForge AWS Infrastructure (Minimal & Cost-Conscious)
# ==============================================================================

# ------------------------------------------------------------------------------
# Amazon ECR: Container Registry
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecr"
  }
}

# Cost control: Automatically clean untagged images and retain only recent images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Retain at most 10 recent tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Logs: Container Logging
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-log-group"
  }
}

# ------------------------------------------------------------------------------
# IAM: ECS Task Execution Role
# ------------------------------------------------------------------------------
# Execution role allows ECS agent to pull container images from ECR and publish logs to CloudWatch
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------------------------
# Amazon ECS: Cluster
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  }
}

# ------------------------------------------------------------------------------
# Amazon ECS: Task Definition
# ------------------------------------------------------------------------------
# Prepared for the FastAPI application listening on container_port (8000)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-app"
      image     = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "PORT"
          value = tostring(var.container_port)
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-task-def"
  }
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ------------------------------------------------------------------------------
# Networking: VPC & Internet Gateway
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ------------------------------------------------------------------------------
# Networking: Subnets (Public & Private across distinct AZs)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet"
  }
}

# ------------------------------------------------------------------------------
# Networking: Route Tables & Subnet Associations
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Cost control: Private route table with default route via NAT instance
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}


resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------------------
# Security Group: ECS Tasks
# ------------------------------------------------------------------------------
# Ingress allows container port (8000) from within the VPC (for future ALB forwarding).
# Port 8000 is not directly exposed to the public internet (0.0.0.0/0).
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks allowing ingress from VPC on container port"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound traffic on container port from VPC (for future ALB)"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  }
}

# ------------------------------------------------------------------------------
# Security Group: NAT Instance
# ------------------------------------------------------------------------------
# Allows inbound traffic from VPC/private subnet for NAT forwarding.
# No inbound SSH is allowed, and no ports are exposed to the public internet (0.0.0.0/0).
resource "aws_security_group" "nat" {
  name        = "${var.project_name}-${var.environment}-nat-sg"
  description = "Security group for NAT instance allowing inbound traffic from VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound traffic from VPC for NAT routing"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-sg"
  }
}

# ------------------------------------------------------------------------------
# EC2: NAT Instance (Cost-Conscious NAT Gateway Alternative)
# ------------------------------------------------------------------------------
resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nat.id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail

              # Enable persistent IP forwarding in sysctl
              echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-nat.conf
              sysctl -p /etc/sysctl.d/99-nat.conf

              # Write configure-nat script to be executed on startup
              cat << 'NAT_SCRIPT' > /usr/local/sbin/configure-nat.sh
              #!/bin/bash
              set -euo pipefail

              # Enable IP forwarding
              sysctl -w net.ipv4.ip_forward=1

              # Detect primary outbound network interface
              PRIMARY_IFACE=$$(ip -o -4 route show to default | awk '{print $$5}')
              while [ -z "$$PRIMARY_IFACE" ]; do
                sleep 1
                PRIMARY_IFACE=$$(ip -o -4 route show to default | awk '{print $$5}')
              done

              # Apply iptables NAT masquerade rule for VPC CIDR
              iptables -t nat -C POSTROUTING -o "$$PRIMARY_IFACE" -s ${aws_vpc.main.cidr_block} -j MASQUERADE 2>/dev/null || \
                iptables -t nat -A POSTROUTING -o "$$PRIMARY_IFACE" -s ${aws_vpc.main.cidr_block} -j MASQUERADE

              # Allow established / related forwarded connections
              iptables -C FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
                iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

              # Allow forwarding from VPC CIDR out the primary interface
              iptables -C FORWARD -s ${aws_vpc.main.cidr_block} -o "$$PRIMARY_IFACE" -j ACCEPT 2>/dev/null || \
                iptables -A FORWARD -s ${aws_vpc.main.cidr_block} -o "$$PRIMARY_IFACE" -j ACCEPT
              NAT_SCRIPT

              chmod +x /usr/local/sbin/configure-nat.sh

              # Create systemd service for persistence across reboot
              cat << 'SYSTEMD' > /etc/systemd/system/nat.service
              [Unit]
              Description=NAT Instance IP Forwarding and Masquerading
              After=network.target network-online.target
              Wants=network-online.target

              [Service]
              Type=oneshot
              ExecStart=/usr/local/sbin/configure-nat.sh
              RemainAfterExit=yes

              [Install]
              WantedBy=multi-user.target
              SYSTEMD

              systemctl daemon-reload
              systemctl enable --now nat.service
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-instance"
  }
}


