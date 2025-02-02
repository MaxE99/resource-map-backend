# ========================================================================================================================
# S3 Bucket
# ========================================================================================================================

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "bucket" {
  comment = "${var.bucket_name}-origin"
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.main.bucket
  policy = jsonencode({
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.main.arn}/*"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.bucket.iam_arn
        }
      },
      {
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.main.arn
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.bucket.iam_arn
        }
      }
    ],
    Version = "2012-10-17"
  })
}

# ========================================================================================================================
# Website/ Media Specific Configurations
# ========================================================================================================================

resource "aws_cloudfront_distribution" "bucket" {
  enabled             = true
  default_root_object = var.is_media ? null : "index.html"
  aliases             = var.is_media ? [] : [var.cloudfront_args["domain"]]

  origin {
    origin_id   = var.is_media ? "${var.bucket_name}-origin" : "${var.cloudfront_args["domain"]}-origin"
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.bucket.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id = var.is_media ? "${var.bucket_name}-origin" : "${var.cloudfront_args["domain"]}-origin"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.is_media ? 86400 : 3600      # 1 day for media, 1 hour for website
    default_ttl            = var.is_media ? 31536000 : 86400  # 1 year for media, 1 day for website
    max_ttl                = var.is_media ? 31536000 : 604800 # 1 year for media, 7 days for website
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 5
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.is_media ? null : var.cloudfront_args["acm_certificate_arn"]
    ssl_support_method             = var.is_media ? null : "sni-only"
    cloudfront_default_certificate = var.is_media ? true : false # use acm_certificate for media if you don't want to use the default cloudfront domain
  }

  price_class = "PriceClass_100"
  tags        = var.tags
}

resource "aws_route53_record" "domain_record" {
  count = !var.is_media ? 1 : 0

  name    = var.cloudfront_args["domain"]
  type    = "A"
  zone_id = var.cloudfront_args["zone_id"]

  alias {
    name                   = aws_cloudfront_distribution.bucket.domain_name
    zone_id                = aws_cloudfront_distribution.bucket.hosted_zone_id
    evaluate_target_health = false
  }
}