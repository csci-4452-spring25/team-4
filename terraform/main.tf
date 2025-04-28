provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {}

locals {
  public_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.public :
    subnet_id if subnet.map_public_ip_on_launch == true
  ]
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "storage" {
  bucket = "web-app-storage-${random_id.bucket_id.hex}"
}

resource "aws_ecs_cluster" "main" {
  name = "web-app-cluster"
}

resource "aws_iam_role" "ecs_execution" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_logs" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/web-app"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "spring-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name  = "spring-app"
      image = "${aws_ecr_repository.app.repository_url}:latest"
      environment = [
        {
          name  = "AWS_S3_ENDPOINT"
          value = "https://s3.${var.aws_region}.amazonaws.com"
        },
        {
          name  = "AWS_S3_REGION"
          value = var.aws_region
        },
        {
          name  = "AWS_S3_BUCKET"
          value = aws_s3_bucket.storage.bucket
        },
        {
          name = "OPEN_WEATHER_APP_ID"
          value = var.open_weather_app_id
        },
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  execution_role_arn = aws_iam_role.ecs_execution.arn
}

resource "aws_ecr_repository" "app" {
  name = "web-app"
}

resource "aws_security_group" "ecr_service_security_group" {
  name        = "web-app-ecr-sg"
  description = "Security group for ECR service"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "ECR access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "app" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.public_subnet_ids
    security_groups  = [aws_security_group.ecr_service_security_group.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.app]
}
