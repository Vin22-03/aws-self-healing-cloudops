variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "self-healing-cloudops"
}

variable "ecr_repo" {
  type    = string
  default = "self-healing-cloudops"
}

# IMPORTANT: GitHub Actions will pass this (github.sha)
variable "image_tag" {
  type        = string
  description = "ECR image tag to deploy (e.g., GitHub commit SHA)"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnet_a_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "public_subnet_b_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "fargate_cpu" {
  type    = number
  default = 256
}

variable "fargate_memory" {
  type    = number
  default = 512
}
