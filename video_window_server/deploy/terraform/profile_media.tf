# Terraform configuration for profile media S3 bucket and CloudFront distribution
# Implements Story 3-2: Avatar & Media Upload System
# AC3: Stores S3 object under profile-media/{userId}/avatar.webp
# AC5: Bucket encryption SSE-KMS, block public access, lifecycle rules

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 bucket for profile media
resource "aws_s3_bucket" "profile_media" {
  bucket = "video-window-profile-media"

  tags = {
    Name        = "Video Window Profile Media"
    Environment = var.environment
    Story       = "3-2-avatar-media-upload-system"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "profile_media" {
  bucket = aws_s3_bucket.profile_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets  = true
}

# SSE-KMS encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "profile_media" {
  bucket = aws_s3_bucket.profile_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.profile_media.arn
    }
    bucket_key_enabled = true
  }
}

# KMS key for encryption
resource "aws_kms_key" "profile_media" {
  description             = "KMS key for Video Window profile media encryption"
  deletion_window_in_days = 30

  tags = {
    Name  = "video-window-profile-media-key"
    Story = "3-2-avatar-media-upload-system"
  }
}

resource "aws_kms_alias" "profile_media" {
  name          = "alias/video-window-profile"
  target_key_id = aws_kms_key.profile_media.key_id
}

# Lifecycle rule to purge temp uploads after 24h
resource "aws_s3_bucket_lifecycle_configuration" "profile_media" {
  bucket = aws_s3_bucket.profile_media.id

  rule {
    id     = "purge-temp-uploads"
    status = "Enabled"

    filter {
      prefix = "profile-media/*/temp/"
    }

    expiration {
      days = 1
    }
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "profile_media" {
  origin {
    domain_name = aws_s3_bucket.profile_media.bucket_regional_domain_name
    origin_id   = "S3-profile-media"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.profile_media.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Video Window Profile Media CDN"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-profile-media"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name  = "Video Window Profile Media CDN"
    Story = "3-2-avatar-media-upload-system"
  }
}

resource "aws_cloudfront_origin_access_identity" "profile_media" {
  comment = "OAI for Video Window Profile Media"
}

# SNS topic for virus scan callbacks
resource "aws_sns_topic" "virus_scan_callback" {
  name = "video-window-virus-scan-callback"

  tags = {
    Name  = "Virus Scan Callback"
    Story = "3-2-avatar-media-upload-system"
  }
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

