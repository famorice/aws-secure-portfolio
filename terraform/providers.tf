provider "aws" {
  region = "ca-central-1"
}

# Required for ACM certificates used by CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}