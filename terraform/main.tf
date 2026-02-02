# -----------------------------
# Networking (USE EXISTING VPC + SUBNETS)
# -----------------------------

data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = data.aws_vpc.main.id

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

  tags = {
    Name = "${var.project}-ecs-sg"
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

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

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
# ECS Service (SELF-HEALING LEVEL-1)
# -----------------------------
resource "aws_ecs_service" "service" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.public.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}
