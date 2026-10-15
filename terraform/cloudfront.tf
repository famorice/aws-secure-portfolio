# Allow CloudFront to securely access the private S3 bucket.
# OAC uses signed requests instead of making the bucket public.
resource "aws_cloudfront_origin_access_control" "portfolio" {
  name                              = "aws-secure-portfolio-oac"
  description                       = "OAC for the portfolio S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribute the static website globally through CloudFront.
resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AWS Secure Portfolio Website"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id                = "portfolio-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio.id
  }

  default_cache_behavior {
    target_origin_id       = "portfolio-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

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
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = "AWS Secure Portfolio"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Grant read-only access to the specific CloudFront distribution.
# The S3 bucket remains private and public access blocking stays enabled.
data "aws_iam_policy_document" "cloudfront_s3_access" {
  statement {
    sid = "AllowCloudFrontReadOnly"

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.portfolio.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.portfolio.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.portfolio.id
  policy = data.aws_iam_policy_document.cloudfront_s3_access.json
}