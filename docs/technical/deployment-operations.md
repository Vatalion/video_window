# Deployment and Operations Guide

## Overview

This guide provides comprehensive procedures for deploying and operating the Craft Video Marketplace platform across different environments. It covers infrastructure provisioning, application deployment, monitoring, and maintenance procedures to ensure reliable and scalable operations.

## Architecture Overview

### Deployment Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │     Staging     │    │   Production    │
│   Environment   │    │   Environment   │    │   Environment   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Dev Cluster   │    │  Staging Cluster │    │  Prod Cluster   │
│   (Single Node) │    │   (Multi-AZ)    │    │ (Auto-scaling)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack
- **Container Orchestration**: Amazon ECS with Fargate
- **Load Balancer**: Application Load Balancer (ALB)
- **Database**: Amazon RDS PostgreSQL 15
- **Cache**: Amazon ElastiCache Redis 7
- **Storage**: Amazon S3 with CloudFront CDN
- **Monitoring**: CloudWatch, OpenTelemetry
- **CI/CD**: GitHub Actions
- **Infrastructure as Code**: Terraform

## Infrastructure as Code

### 1. Terraform Configuration

#### Project Structure
```
infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/
│   │   ├── ecs/
│   │   ├── rds/
│   │   ├── redis/
│   │   ├── s3/
│   │   └── monitoring/
│   ├── shared/
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── main.tf
```

#### Provider Configuration
Create `infrastructure/terraform/shared/providers.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket = "craft-marketplace-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "craft-marketplace"
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "craft-marketplace"
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}
```

#### ECS Module
Create `infrastructure/terraform/modules/ecs/main.tf`:
```hcl
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-app"
      image = "${var.repository_url}:${var.image_tag}"

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DATABASE_URL"
          value = var.database_url
        },
        {
          name  = "REDIS_URL"
          value = var.redis_url
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      secrets = [
        {
          name      = "STRIPE_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.stripe_secret.arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = aws_secretsmanager_secret.jwt_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
      }

      dependsOn = [
        {
          containerName = "${var.project_name}-app"
          condition     = "START"
        }
      ]
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-task"
  })
}

# Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-app"
    container_port   = var.container_port
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 50
  }

  depends_on = [aws_lb_listener.app]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-service"
  })
}

# Auto Scaling
resource "aws_appautoscaling_target" "app" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.project_name}-${var.environment}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "scale_up_memory" {
  name               = "${var.project_name}-${var.environment}-scale-up-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
```

#### Load Balancer Configuration
```hcl
# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tg"
  })
}

# HTTP Listener
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

#### Database Module
Create `infrastructure/terraform/modules/rds/main.tf`:
```hcl
# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-subnet-group"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_username
  password = var.database_password

  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot" : null

  deletion_protection = var.environment == "prod" ? true : false

  performance_insights_enabled = var.environment == "prod" ? true : false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.project_name}-${var.environment}-pg"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}
```

### 2. Environment-Specific Configuration

#### Development Environment
Create `infrastructure/terraform/environments/dev/variables.tf`:
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "craft-marketplace"
}

variable "task_cpu" {
  description = "CPU units for task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired count of tasks"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for database"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for database"
  type        = number
  default     = 100
}
```

#### Production Environment
Create `infrastructure/terraform/environments/prod/variables.tf`:
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "task_cpu" {
  description = "CPU units for task"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory for task"
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Desired count of tasks"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = number
  default     = 10
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.m6g.large"
}

variable "allocated_storage" {
  description = "Allocated storage for database"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for database"
  type        = number
  default     = 1000
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}
```

## CI/CD Pipeline

### 1. GitHub Actions Workflow

#### Build and Deploy Pipeline
Create `.github/workflows/deploy.yml`:
```yaml
name: Build and Deploy

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]

env:
  AWS_REGION: us-east-1
  ECR_REGISTRY: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
  ECR_REPOSITORY: craft-marketplace
  CONTAINER_NAME: craft-marketplace-app

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  build-flutter:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'

      - name: Build Flutter web
        run: |
          flutter build web --release --web-renderer canvaskit
          tar -czf build.tar.gz build/web

      - name: Upload web build
        uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: build.tar.gz

  build-server:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push Docker image
        env:
          ECR_PASSWORD: ${{ steps.login-ecr.outputs.password }}
        run: |
          # Build Docker image
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA $ECR_REGISTRY/$ECR_REPOSITORY:latest

          # Push to ECR
          echo $ECR_PASSWORD | docker login -u AWS --password-stdin $ECR_REGISTRY
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Store image version
        run: echo "IMAGE_VERSION=$GITHUB_SHA" >> $GITHUB_ENV

  deploy-dev:
    runs-on: ubuntu-latest
    needs: [build-flutter, build-server]
    if: github.ref == 'refs/heads/develop'
    environment: development
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Download web build
        uses: actions/download-artifact@v3
        with:
          name: web-build

      - name: Deploy to S3
        run: |
          aws s3 sync build/web/ s3://${{ secrets.DEV_S3_BUCKET }} --delete
          aws cloudfront create-invalidation --distribution-id ${{ secrets.DEV_CLOUDFRONT_ID }} --paths "/*"

      - name: Deploy infrastructure
        run: |
          cd infrastructure/terraform/environments/dev
          terraform init
          terraform plan -var="image_tag=${{ needs.build-server.outputs.IMAGE_VERSION }}" -out=tfplan
          terraform apply -auto-approve tfplan

  deploy-staging:
    runs-on: ubuntu-latest
    needs: [build-flutter, build-server]
    if: github.ref == 'refs/heads/main'
    environment: staging
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy infrastructure
        run: |
          cd infrastructure/terraform/environments/staging
          terraform init
          terraform plan -var="image_tag=${{ needs.build-server.outputs.IMAGE_VERSION }}" -out=tfplan
          terraform apply -auto-approve tfplan

  deploy-prod:
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Manual approval
        uses: trstringer/manual-approval@v1
        with:
          secret: ${{ github.TOKEN }}
          approvers: team-lead, devops-team
          minimum-approvals: 2

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy infrastructure
        run: |
          cd infrastructure/terraform/environments/prod
          terraform init
          terraform plan -var="image_tag=${{ needs.build-server.outputs.IMAGE_VERSION }}" -out=tfplan
          terraform apply -auto-approve tfplan

      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 2. Docker Configuration

#### Multi-stage Dockerfile
```dockerfile
# Base image
FROM dart:3.8.0-sdk AS base
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Builder stage
FROM base AS builder
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Production stage
FROM scratch AS production
COPY --from=builder /app/bin/server /app/
COPY --from=builder /app/web /app/web

EXPOSE 8080
ENTRYPOINT ["/app/server"]
```

#### Docker Compose for Development
Create `docker-compose.dev.yml`:
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
      - "3000:3000"
    environment:
      - FLUTTER_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/craft_dev
      - REDIS_URL=redis://redis:6379
    volumes:
      - .:/app
      - /app/build
    depends_on:
      - db
      - redis
    command: dart run bin/server.dart --mode development

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=craft_dev
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/migrations:/docker-entrypoint-initdb.d

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app

volumes:
  postgres_data:
  redis_data:
```

## Monitoring and Observability

### 1. CloudWatch Integration

#### CloudWatch Configuration
Create `infrastructure/terraform/modules/monitoring/main.tf`:
```hcl
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

# Application Metrics
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [var.sns_topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = [var.sns_topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Target5XXError"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors application error rate"
  alarm_actions       = [var.sns_topic_arn]

  tags = var.tags
}

# Custom Metrics Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.app.name],
            [".", "MemoryUtilization", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Service Metrics"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Load Balancer Metrics"
        }
      }
    ]
  })
}
```

### 2. OpenTelemetry Integration

#### Application Observability
Create `lib/observability/telemetry.dart`:
```dart
import 'package:opentelemetry_api/api.dart';
import 'package:opentelemetry_sdk/sdk.dart';

/// Telemetry configuration and setup
class TelemetryService {
  static TracerProvider? _tracerProvider;
  static MeterProvider? _meterProvider;

  /// Initialize OpenTelemetry
  static Future<void> initialize() async {
    final resource = Resource([
      Attribute.fromKeyValue('service.name', 'craft-marketplace'),
      Attribute.fromKeyValue('service.version', '1.0.0'),
      Attribute.fromKeyValue('environment', Platform.environment['ENVIRONMENT'] ?? 'unknown'),
    ]);

    // Initialize tracing
    _tracerProvider = TracerProviderBuilder()
        .addResource(resource)
        .addSpanProcessor(
          BatchSpanProcessor.builder(
            CollectorExporter(
              endpoint: 'https://otel-collector.craft.marketplace/v1/traces',
            ),
          ).build(),
        )
        .build();

    // Initialize metrics
    _meterProvider = MeterProviderBuilder()
        .addResource(resource)
        .addMetricReader(
          PeriodicMetricReader.builder(
            PrometheusExporter(),
          ).build(),
        )
        .build();

    global.setTracerProvider(_tracerProvider!);
    global.setMeterProvider(_meterProvider!);
  }

  /// Get tracer for instrumentation
  static Tracer getTracer(String name) {
    return global.getTracerProvider().getTracer(name);
  }

  /// Get meter for metrics
  static Meter getMeter(String name) {
    return global.getMeterProvider().getMeter(name);
  }

  /// Create span with automatic exception handling
  static Future<T> traceAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final tracer = getTracer('craft-marketplace');
    final span = tracer.startSpan(name);

    if (attributes != null) {
      attributes.forEach((key, value) {
        span.setAttribute(key, value);
      });
    }

    try {
      final result = await tracer.withSpan(span, operation);
      span.setStatus(StatusCode.ok);
      return result;
    } catch (error, stackTrace) {
      span.recordException(error, stackTrace);
      span.setStatus(StatusCode.error, error.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}
```

## Security and Compliance

### 1. Security Configuration

#### Security Groups
Create `infrastructure/terraform/modules/security/main.tf`:
```hcl
# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
}

# ECS Service Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  })
}

# Database Security Group
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })
}
```

#### Secrets Management
```hcl
# Secrets Manager
resource "aws_secretsmanager_secret" "stripe_secret" {
  name                    = "${var.project_name}/${var.environment}/stripe-secret"
  description             = "Stripe secret key"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-stripe-secret"
  })
}

resource "aws_secretsmanager_secret_version" "stripe_secret" {
  secret_id = aws_secretsmanager_secret.stripe_secret.id
  secret_string = jsonencode({
    stripe_secret_key = var.stripe_secret_key
    stripe_webhook_secret = var.stripe_webhook_secret
  })
}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "${var.project_name} ${var.environment} encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECS Service"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-kms-key"
  })
}
```

### 2. Compliance and Auditing

#### AWS Config Rules
```hcl
# AWS Config for compliance monitoring
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id
}

# Compliance rules
resource "aws_config_config_rule" "encryption_enabled" {
  name = "${var.project_name}-${var.environment}-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Volume"]
  }
}
```

## Backup and Disaster Recovery

### 1. Backup Strategy

#### Database Backups
```hcl
# Automated backup configuration
resource "aws_db_instance" "main" {
  # ... other configuration ...

  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Cross-region backup for production
  backup_retention_period = var.environment == "prod" ? 30 : 7

  tags = merge(var.tags, {
    Backup = "enabled"
  })
}

# Backup verification
resource "aws_cloudwatch_event_rule" "backup_verification" {
  name                = "${var.project_name}-${var.environment}-backup-verification"
  description         = "Trigger backup verification daily"
  schedule_expression = "cron(0 5 * * ? *)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "backup_verification" {
  rule      = aws_cloudwatch_event_rule.backup_verification.name
  target_id = "BackupVerificationLambda"
  arn       = aws_lambda_function.backup_verification.arn
}
```

#### S3 Backup Configuration
```hcl
# S3 bucket with versioning and lifecycle
resource "aws_s3_bucket" "media" {
  bucket = "${var.project_name}-${var.environment}-media"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id     = "media_lifecycle"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(var.tags, {
    Purpose = "Media Storage"
  })
}

# Cross-region replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "backup_replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.media_backup.arn
      storage_class = "STANDARD"
    }
  }
}
```

### 2. Disaster Recovery Plan

#### Multi-Region Setup
```hcl
# Primary region resources
module "primary" {
  source = "../../modules/infrastructure"

  providers = {
    aws = aws.primary
  }

  environment  = "prod"
  aws_region   = "us-east-1"
  is_primary   = true
  project_name = var.project_name
}

# Backup region resources
module "backup" {
  source = "../../modules/infrastructure"

  providers = {
    aws = aws.backup
  }

  environment  = "prod-backup"
  aws_region   = "us-west-2"
  is_primary   = false
  project_name = var.project_name
}

# Route53 failover configuration
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.craft.marketplace"
  type    = "A"

  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = module.primary.alb_dns_name
    zone_id               = module.primary.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "backup" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.craft.marketplace"
  type    = "A"

  set_identifier = "backup"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = module.backup.alb_dns_name
    zone_id               = module.backup.alb_zone_id
    evaluate_target_health = true
  }
}
```

## Performance Optimization

### 1. CDN Configuration

#### CloudFront Setup
```hcl
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.media.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.media.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.ssl_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cdn"
  })
}
```

### 2. Caching Strategy

#### Redis Configuration
```hcl
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  description                = "Redis cluster for ${var.project_name}"

  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"

  num_cache_clusters         = var.redis_num_nodes
  automatic_failover_enabled = var.redis_num_nodes > 1

  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.redis_security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  snapshot_retention_limit   = 7
  snapshot_window           = "03:00-05:00"
  maintenance_window        = "sun:05:00-sun:06:00"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redis"
  })
}
```

## Troubleshooting Guide

### 1. Common Issues

#### Application Won't Start
```bash
# Check ECS service events
aws ecs describe-services --cluster craft-marketplace-prod-cluster --services craft-marketplace-prod-service

# Check task logs
aws logs tail /ecs/craft-marketplace-prod --follow

# Check health endpoint
curl https://api.craft.marketplace/health
```

#### Database Connection Issues
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier craft-marketplace-prod-db

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Test connection from ECS task
aws ecs execute-command \
  --cluster craft-marketplace-prod-cluster \
  --task task-id \
  --container craft-marketplace-app \
  --command "/bin/bash" \
  --interactive
```

#### Performance Issues
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=craft-marketplace-prod-service

# Check ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/craft-marketplace-prod-alb
```

### 2. Emergency Procedures

#### Service Rollback
```bash
# Force new deployment with previous image
aws ecs update-service \
  --cluster craft-marketplace-prod-cluster \
  --service craft-marketplace-prod-service \
  --force-new-deployment \
  --task-definition previous-task-definition-arn

# Scale down to zero
aws ecs update-service \
  --cluster craft-marketplace-prod-cluster \
  --service craft-marketplace-prod-service \
  --desired-count 0

# Scale back up with new configuration
aws ecs update-service \
  --cluster craft-marketplace-prod-cluster \
  --service craft-marketplace-prod-service \
  --desired-count 3
```

#### Database Failover
```bash
# Trigger manual failover
aws rds reboot-db-instance \
  --db-instance-identifier craft-marketplace-prod-db \
  --force-failover

# Monitor failover status
aws rds describe-db-instances \
  --db-instance-identifier craft-marketplace-prod-db
```

## Validation Checklist

### Pre-deployment
- [ ] All tests passing in CI/CD
- [ ] Security scans completed
- [ ] Infrastructure changes reviewed
- [ ] Backup procedures verified
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured
- [ ] Performance benchmarks met

### Post-deployment
- [ ] Health checks passing
- [ ] Monitoring dashboards operational
- [ ] Log aggregation working
- [ ] Error rates within thresholds
- [ ] Performance metrics normal
- [ ] Security configurations verified
- [ ] Documentation updated

This comprehensive deployment and operations guide ensures reliable, secure, and scalable operations for the Craft Video Marketplace platform across all environments.