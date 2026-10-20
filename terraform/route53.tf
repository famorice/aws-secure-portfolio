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