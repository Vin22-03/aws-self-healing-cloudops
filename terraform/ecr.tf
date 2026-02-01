resource "aws_ecr_repository" "self_healing" {
  name = "self-healing-cloudops"

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project     = "Self-Healing-CloudOps"
    ManagedBy   = "Terraform"
    Environment = "demo"
  }
}
