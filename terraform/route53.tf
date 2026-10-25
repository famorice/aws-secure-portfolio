# Point the IT subdomain to the existing CloudFront distribution
resource "aws_route53_record" "portfolio" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = "it.famory-sissoko.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.portfolio.domain_name
    zone_id                = aws_cloudfront_distribution.portfolio.hosted_zone_id
    evaluate_target_health = false
  }
}

# Redirect the root domain to the dedicated CloudFront distribution.
resource "aws_route53_record" "root_redirect" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = "famory-sissoko.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

# Redirect the www subdomain to the same CloudFront distribution.
resource "aws_route53_record" "www_redirect" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = "www.famory-sissoko.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}