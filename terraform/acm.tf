# TLS certificate for the IT portfolio CloudFront distribution
resource "aws_acm_certificate" "portfolio" {
  provider = aws.us_east_1

  domain_name       = "it.famory-sissoko.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "it-portfolio-certificate"
  }
}
# Reference the existing Route 53 public hosted zone
data "aws_route53_zone" "portfolio" {
  name         = "famory-sissoko.com"
  private_zone = false
}
# Create the DNS record required to validate the ACM certificate
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.portfolio.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

# Wait until ACM confirms domain ownership
resource "aws_acm_certificate_validation" "portfolio" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.portfolio.arn

  validation_record_fqdns = [
    for record in aws_route53_record.acm_validation : record.fqdn
  ]
}