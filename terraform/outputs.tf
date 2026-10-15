output "s3_bucket_name" {
  description = "Name of the private portfolio bucket"
  value       = aws_s3_bucket.portfolio.id
}

output "cloudfront_url" {
  description = "Public HTTPS URL of the portfolio website"
  value       = "https://${aws_cloudfront_distribution.portfolio.domain_name}"
}