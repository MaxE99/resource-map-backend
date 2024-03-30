resource "random_string" "main" {
  length  = 5
  special = false
  upper   = false
}

locals {
  bucket_name = "${var.project}-react-app-${random_string.main.result}"
}

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Project = var.project
    Name    = "Main S3 Bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.main, aws_s3_bucket_public_access_block.main]
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "react-app"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain]

  origin {
    origin_id   = "${local.bucket_name}-origin"
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id = "${local.bucket_name}-origin"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

  tags = {
    Project = var.project
    Name    = "Main Cloudfront Distribution"
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.main.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_s3_bucket" "images" {
  bucket = "${var.domain}-images"

  tags = {
    Project = var.project
    Name    = "Image S3 Bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "images" {
  bucket = aws_s3_bucket.images.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.images, aws_s3_bucket_public_access_block.images]
}

resource "aws_s3_bucket_policy" "images" {
  bucket = aws_s3_bucket.images.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.images.bucket}/*"
      }
    ]
  })
}