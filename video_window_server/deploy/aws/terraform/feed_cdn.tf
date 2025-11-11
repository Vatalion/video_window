# CloudFront distribution for feed video delivery
# AC3: CloudFront cache with signed cookies for secure video delivery

locals {
  feed_s3_origin_id = "${var.project_name}-feed-videos"
}

# S3 bucket for feed videos
resource "aws_s3_bucket" "feed_videos" {
  bucket = "${var.project_name}-feed-hls"
  force_destroy = true

  tags = {
    Name        = "${var.project_name} feed videos"
    Environment = var.environment
    Epic        = "4"
  }
}

resource "aws_s3_bucket_acl" "feed_videos" {
  bucket = aws_s3_bucket.feed_videos.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "feed_videos" {
  bucket = aws_s3_bucket.feed_videos.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudFront origin access identity for S3
resource "aws_cloudfront_origin_access_identity" "feed_videos" {
  comment = "Feed videos OAI"
}

# CloudFront distribution for feed videos
resource "aws_cloudfront_distribution" "feed_videos" {
  origin {
    origin_id   = local.feed_s3_origin_id
    domain_name = aws_s3_bucket.feed_videos.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.feed_videos.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Feed video delivery CDN"
  default_root_object = "index.html"

  aliases = ["${var.subdomain_feed}.${var.top_domain}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.feed_s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      cookies {
        forward = "none"
      }
    }

    # AC3: Cache TTL 120 seconds default
    min_ttl     = 0
    default_ttl = 120
    max_ttl     = 3600

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Cache behavior for HLS manifests and segments
  ordered_cache_behavior {
    path_pattern     = "*.m3u8"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.feed_s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 60
    max_ttl     = 300

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "${var.project_name}-feed-cdn"
    Environment = var.environment
    Epic        = "4"
  }
}

# S3 bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "feed_videos" {
  bucket = aws_s3_bucket.feed_videos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.feed_videos.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.feed_videos.arn}/*"
      }
    ]
  })
}

# Route53 record for feed CDN
resource "aws_route53_record" "feed_cdn" {
  zone_id = var.hosted_zone_id
  name    = "${var.subdomain_feed}.${var.top_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.feed_videos.domain_name
    zone_id                = aws_cloudfront_distribution.feed_videos.hosted_zone_id
    evaluate_target_health = false
  }
}

# IAM role for signed cookie generation (used by Serverpod)
resource "aws_iam_role" "feed_signed_cookie" {
  name = "${var.project_name}-feed-signed-cookie-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-feed-signed-cookie-role"
    Epic = "4"
  }
}

# IAM policy for CloudFront signed cookie generation
resource "aws_iam_role_policy" "feed_signed_cookie" {
  name = "${var.project_name}-feed-signed-cookie-policy"
  role = aws_iam_role.feed_signed_cookie.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateSignedUrl",
          "cloudfront:CreateSignedCookie"
        ]
        Resource = aws_cloudfront_distribution.feed_videos.arn
      }
    ]
  })
}

