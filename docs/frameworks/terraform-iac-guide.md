# Terraform IaC Guide - Video Window

**Version:** Terraform 1.7.x  
**Last Updated:** 2025-11-03  
**Status:** ⏳ Planned - Post-MVP (Epic 01 Phase 2)

---

## Overview

Terraform will provision AWS infrastructure for Video Window production deployment. **NOT USED IN SPRINT 1** (local Docker only).

---

## Planned Infrastructure

### AWS Resources (Future)

```
VPC
├── Public Subnets (ALB, NAT Gateways)
├── Private Subnets (ECS, RDS, ElastiCache)
└── S3 (Video storage)
    └── CloudFront (CDN)

Services:
- ECS Fargate (Serverpod containers)
- RDS PostgreSQL (Database)
- ElastiCache Redis (Cache)
- S3 + CloudFront (Video delivery)
- Secrets Manager (API keys)
```

---

## Directory Structure (Planned)

```
video_window_server/terraform/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider versions
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars
│   ├── staging/
│   │   └── terraform.tfvars
│   └── production/
│       └── terraform.tfvars
└── modules/
    ├── networking/      # VPC, subnets
    ├── compute/         # ECS, Fargate
    ├── database/        # RDS
    ├── cache/           # ElastiCache
    └── storage/         # S3, CloudFront
```

---

## Sample Module (VPC)

```hcl
# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.environment}-video-window-vpc"
    Environment = var.environment
    Project     = "video-window"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}
```

---

## Deployment Workflow (Future)

```bash
# Initialize
cd video_window_server/terraform/environments/dev
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy (DANGEROUS)
terraform destroy
```

---

## State Management (Future)

```hcl
# Backend configuration for remote state
terraform {
  backend "s3" {
    bucket         = "video-window-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

---

## Video Window Conventions

### Tagging Strategy
```hcl
tags = {
  Environment = var.environment  # dev, staging, production
  Project     = "video-window"
  ManagedBy   = "terraform"
  Epic        = "01"  # Epic number
}
```

### Naming Convention
```
{environment}-{project}-{resource}
Example: production-video-window-ecs-cluster
```

---

## Sprint 1 Status

**NOT IMPLEMENTED** - Sprint 1 uses local Docker only.

**Planned for:** Epic 01 Phase 2 (Production deployment)

---

## Reference

- **Terraform Docs:** https://www.terraform.io/docs
- **AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

**Last Updated:** 2025-11-03 by Winston  
**Status:** Planning phase - implementation in later sprint
