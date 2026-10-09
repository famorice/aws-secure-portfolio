# Create a dedicated S3 bucket to store the static portfolio website.
# The bucket name uses a generated suffix to ensure global uniqueness.
resource "aws_s3_bucket" "portfolio" {
  bucket_prefix = "aws-secure-portfolio-"

  tags = {
    Project     = "AWS Secure Portfolio"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Keep the bucket private. Website visitors will access content through
# CloudFront using Origin Access Control (OAC), not public S3 URLs.
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Disable ACLs and use bucket policies for access management.
# This simplifies permissions and ensures the bucket owner controls objects.
resource "aws_s3_bucket_ownership_controls" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Explicitly configure SSE-S3 encryption to document our security baseline.
# AES256 uses S3-managed keys without additional AWS KMS key charges.
resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Preserve previous object versions to support recovery from accidental
# deletion or faulty website deployments.
resource "aws_s3_bucket_versioning" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Limit storage costs by automatically removing noncurrent object versions
# after 30 days. Current versions are not affected by this rule.
resource "aws_s3_bucket_lifecycle_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

}