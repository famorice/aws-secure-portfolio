# AWS Secure Portfolio — Architecture

## 1. Architecture Overview

AWS Secure Portfolio is a serverless static website architecture designed around security, managed-service resilience, automated deployment, and cost optimization.

The solution uses Amazon CloudFront as the public entry point for website content, with a private Amazon S3 bucket as the origin. Infrastructure is provisioned and managed using Terraform.

![AWS Secure Portfolio Architecture](architecture.png)

## 2. Request Flow

1. A visitor accesses `https://it.famory-sissoko.com`.
2. Amazon Route 53 resolves the custom domain to the CloudFront distribution.
3. The visitor establishes an HTTPS connection with CloudFront using a TLS certificate issued through AWS Certificate Manager (ACM).
4. CloudFront serves cached content from an edge location when available.
5. On a cache miss, CloudFront retrieves the requested object from the private S3 bucket using Origin Access Control (OAC) with signed requests.
6. CloudFront returns the content to the visitor and caches it according to the configured caching behavior.

The S3 bucket is not publicly accessible. Website content is delivered through CloudFront.

## 3. Regional Design

| Service | Location |
|---|---|
| Amazon S3 | `ca-central-1` |
| Amazon CloudFront | Global |
| Amazon Route 53 | Global |
| AWS Certificate Manager | `us-east-1` |
| Amazon CloudWatch (CloudFront alarm) | `us-east-1` |
| Amazon SNS (alarm notifications) | `us-east-1` |
| AWS IAM | Global |

CloudFront requires its custom HTTPS certificate to be provisioned in `us-east-1`.

## 4. Security Architecture

### 4.1 Network and Origin Security

The S3 bucket blocks public access and permits object retrieval only through the designated CloudFront distribution.

CloudFront uses Origin Access Control (OAC) to sign origin requests using AWS Signature Version 4.

The S3 bucket policy restricts read access using the CloudFront distribution ARN.

### 4.2 Encryption

**Encryption in transit**

Visitors access the website over HTTPS using a custom domain and an ACM-managed TLS certificate.

**Encryption at rest**

Amazon S3 uses server-side encryption with Amazon S3-managed keys (SSE-S3, AES-256).

### 4.3 Identity and Access Management

The GitHub Actions deployment workflow authenticates using OpenID Connect (OIDC), obtaining temporary AWS credentials.

The IAM trust policy restricts role assumption to the authorized private GitHub repository and its `main` branch.

The deployment role grants only the permissions necessary to:

- List objects in the portfolio S3 bucket.
- Upload and delete website objects.
- Create cache invalidations for the designated CloudFront distribution.

No long-lived AWS access keys are required.

### 4.4 DDoS Protection

AWS Shield Standard provides automatic DDoS protection for CloudFront.

AWS WAF is optional and is not included in the current implementation to avoid additional recurring costs.

## 5. Monitoring and Notifications

Amazon CloudWatch monitors the CloudFront `5xxErrorRate` metric.

The configured alarm uses:

| Parameter | Value |
|---|---|
| Metric | `5xxErrorRate` |
| Threshold | Greater than 5% |
| Evaluation period | 5 minutes |
| Number of periods | 1 |
| Missing data | Treated as not breaching |

When the alarm enters the `ALARM` state, Amazon SNS sends an email notification to the confirmed subscriber.

CloudFront access logging and S3 server access logging are not enabled in the current cost-optimized implementation.

## 6. Continuous Deployment

Website source code is maintained in a separate private GitHub repository.

The target deployment workflow runs automatically when changes are merged into the `main` branch.

The workflow:

1. Checks out the website source code.
2. Authenticates to AWS using GitHub OIDC.
3. Synchronizes website files to Amazon S3.
4. Creates a CloudFront cache invalidation to refresh cached content.

The deployment workflow uses temporary credentials and a least-privilege IAM role.

## 7. Storage and Lifecycle Management

The S3 bucket has versioning enabled to retain previous object versions when website files are replaced or deleted.

A lifecycle rule automatically expires noncurrent object versions after 30 days.

Current object versions are not affected by this lifecycle rule.

## 8. Cost Optimization

The architecture minimizes ongoing infrastructure costs through:

- Serverless static website hosting without EC2 instances or continuously running application servers.
- CloudFront caching to reduce repeated origin requests.
- S3 lifecycle management to limit retained object versions.
- Standard CloudFront and CloudWatch metrics rather than additional paid monitoring features.
- AWS Budgets for spending alerts.
- Deferring optional WAF and access logging services.

## 9. Infrastructure as Code

Terraform manages the AWS infrastructure, including storage, CDN, DNS, TLS certificates, IAM, monitoring, and notifications.

The infrastructure configuration is organized in the `terraform/` directory and uses two AWS provider configurations:

- `ca-central-1` — primary region.
- `us-east-1` — ACM and CloudFront monitoring resources.

Terraform state and local variable values are excluded from the public Git repository.