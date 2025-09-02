resource "aws_ecr_repository" "this" {
  name = var.ecr_name

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  image_tag_mutability = "MUTABLE"
  tags                 = var.tags
}


resource "aws_ecr_repository_policy" "repo_policy" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "AllowEC2ContainerServicePull",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}