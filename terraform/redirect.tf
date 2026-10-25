# CloudFront Function for temporary redirects to the IT portfolio.
resource "aws_cloudfront_function" "redirect" {
  name    = "famory-root-domain-redirect"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect root and www domains to the IT portfolio"
  publish = true

  code = file("${path.module}/redirect.js")
}

# CloudFront distribution for root and www domain redirects.
resource "aws_cloudfront_distribution" "redirect" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Redirect root and www domains to the IT portfolio"

  aliases     = ["famory-sissoko.com", "www.famory-sissoko.com"]
  price_class = "PriceClass_100"

  # CloudFront requires an origin, even though the function
  # returns a redirect before the origin is contacted.
  origin {
    domain_name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id   = "redirect-placeholder-origin"
  }

  default_cache_behavior {
    target_origin_id       = "redirect-placeholder-origin"
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
    default_ttl = 0
    max_ttl     = 0

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.redirect.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Project     = "AWS Secure Portfolio"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Domain Redirect"
  }
}