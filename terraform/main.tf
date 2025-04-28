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

# Ensure at least two subnets in different AZs for RDS
locals {
  # Only consider private subnets (map_public_ip_on_launch = false)
  private_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.selected :
    subnet_id if subnet.map_public_ip_on_launch == false
  ]
  az_to_private_subnets = {
    for subnet_id in local.private_subnet_ids :
      data.aws_subnet.selected[subnet_id].availability_zone => subnet_id
      ...
  }
  azs = keys(local.az_to_private_subnets)
  az_count = length(local.azs)
  # Use only the dedicated RDS subnets if they are created, otherwise use private subnets in different AZs
  effective_subnet_ids = length(aws_subnet.rds.*.id) > 0 ? aws_subnet.rds.*.id : (
    local.az_count >= 2 ? slice([for az in local.azs : local.az_to_private_subnets[az][0]], 0, 2) : []
  )
}

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

resource "aws_subnet" "rds" {
  count             = local.az_count < 2 ? 2 : 0
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "rds-subnet-${count.index}"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "storage" {
  bucket = "web-app-storage-${random_id.bucket_id.hex}"
}

resource "aws_db_subnet_group" "main" {
  name        = "web-app-db-subnet-group-${random_id.bucket_id.hex}"
  description = "Database subnet group for application"
  subnet_ids  = local.effective_subnet_ids
  depends_on  = [aws_subnet.rds]
}

resource "aws_db_instance" "postgres" {
  identifier        = "postgres"
  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  skip_final_snapshot = true
}

resource "aws_security_group" "database" {
  name        = "web-app-database-sg"
  description = "Security group for RDS database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "PostgreSQL access"
    from_port   = 5432
    to_port     = 5432
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

resource "aws_elasticache_subnet_group" "main" {
  name        = "web-app-cache-subnet-group"
  description = "Subnet group for Elasticache Redis cluster"
  subnet_ids  = data.aws_subnets.default.ids
}

resource "aws_security_group" "redis" {
  name        = "web-app-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Redis access"
    from_port   = 6379
    to_port     = 6379
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

resource "aws_elasticache_cluster" "redis" {
  cluster_id      = "web-app-redis"
  engine          = "redis"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  port            = 6379

  security_group_ids = [aws_security_group.redis.id]
  subnet_group_name  = aws_elasticache_subnet_group.main.name
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
          name  = "AWS_DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
        },
        {
          name  = "AWS_REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
        },
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
