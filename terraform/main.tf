# -----------------------------
# Networking (VPC + 2 public subnets)
# -----------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project}-public-rt" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-b" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# EXISTING CloudWatch Log Group
# -----------------------------
data "aws_cloudwatch_log_group" "app" {
  name = "/ecs/self-healing-cloudops"
}

# -----------------------------
# ECS Cluster
# -----------------------------
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster"
}

# -----------------------------
# EXISTING IAM Execution Role
# -----------------------------
data "aws_iam_role" "task_execution" {
  name = "${var.project}-task-exec-role"
}

# -----------------------------
# ECS Task Definition
# -----------------------------
data "aws_caller_identity" "current" {}

locals {
  ecr_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo}:${var.image_tag}"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.fargate_cpu)
  memory                   = tostring(var.fargate_memory)
  execution_role_arn        = data.aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = local.ecr_image
      essential = true

      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = data.aws_cloudwatch_log_group.app.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# -----------------------------
# ECS Service
# -----------------------------
resource "aws_ecs_service" "service" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_internet_gateway.igw]
}
