output "s3_bucket_name" {
  description = "Name of the private portfolio bucket"
  value       = aws_s3_bucket.portfolio.id
}