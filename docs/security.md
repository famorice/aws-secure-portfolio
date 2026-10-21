# Security Architecture

**Author:** Famory Sissoko  
**Project:** AWS Secure Portfolio

## 1. Overview

AWS Secure Portfolio follows a defense-in-depth approach using AWS-managed security controls, private storage, encrypted communications, and least-privilege access.

The security architecture focuses on protecting website content, securing deployment credentials, and reducing unnecessary exposure while maintaining a cost-optimized infrastructure.

## 2. S3 Origin Security

The portfolio website is stored in a private Amazon S3 bucket in `ca-central-1`.

The following controls are implemented:

- **Block Public Access:** All four S3 public access block settings are enabled.
- **Object ownership:** `BucketOwnerEnforced` disables ACLs and uses bucket policies for access management.
- **Origin Access Control (OAC):** CloudFront signs requests to S3 using AWS Signature Version 4 (SigV4).
- **Restricted bucket policy:** The CloudFront service principal receives `s3:GetObject` permission, restricted to the designated distribution ARN.

These controls prevent anonymous public access to website objects through S3.

Website visitors access content through CloudFront rather than directly through the S3 origin.

## 3. Encryption

### 3.1 Encryption in Transit

Amazon CloudFront provides HTTPS delivery using an ACM-managed TLS certificate for `it.famory-sissoko.com`.

The CloudFront distribution is configured with:

- HTTP-to-HTTPS redirection.
- Minimum TLS security policy: `TLSv1.2_2021`.
- Server Name Indication (SNI) for certificate selection.
- CloudFront OAC uses SigV4 to authenticate origin requests, while HTTPS protects communication between CloudFront and S3.

The ACM certificate is provisioned in `us-east-1`, as required for CloudFront custom-domain certificates.

### 3.2 Encryption at Rest

The S3 bucket uses server-side encryption with Amazon S3-managed keys (SSE-S3).

- **Encryption algorithm:** AES-256.
- **Key management:** Managed by Amazon S3.
- **Additional AWS KMS key:** Not required.

This provides encryption at rest without the additional cost or operational overhead of customer-managed KMS keys.

## 4. Identity and Access Management

### 4.1 Principle of Least Privilege

The GitHub Actions deployment role grants only the permissions required to publish website content:

| Permission | Scope | Purpose |
|---|---|---|
| `s3:ListBucket` | Portfolio S3 bucket | List existing objects during synchronization |
| `s3:PutObject` | Objects within the portfolio bucket | Upload website files |
| `s3:DeleteObject` | Objects within the portfolio bucket | Remove obsolete website files |
| `cloudfront:CreateInvalidation` | Designated CloudFront distribution | Refresh cached content after deployment |

The deployment role does not grant permissions to modify IAM policies, S3 bucket configuration, or other AWS infrastructure.

### 4.2 GitHub OIDC Authentication

GitHub Actions authenticates to AWS through OpenID Connect (OIDC), using temporary AWS credentials rather than long-lived IAM user access keys.

The IAM role trust policy restricts role assumption to:

- GitHub's OIDC identity provider: `https://token.actions.githubusercontent.com`.
- Audience: `sts.amazonaws.com`.
- Authorized private GitHub repository.
- Branch: `refs/heads/main`.

AWS Security Token Service (STS) issues temporary credentials when the workflow successfully assumes the deployment role.

### 4.3 Separation of Responsibilities

Infrastructure provisioning and website deployment are managed separately.

- **Public infrastructure repository:** Terraform configuration and architecture documentation.
- **Private website repository:** Website source code and GitHub Actions deployment workflow.
- **Deployment IAM role:** Limited to S3 object operations and CloudFront cache invalidation.

This separation reduces the permissions required by the deployment pipeline.

## 5. DDoS Protection

AWS Shield Standard provides automatic DDoS protection for Amazon CloudFront.

AWS WAF is not deployed in the initial architecture.

This decision reflects the website's static nature, limited expected traffic, and cost-optimization requirements.

AWS WAF can be introduced later if additional application-layer request filtering becomes necessary.

## 6. Monitoring and Security Notifications

Amazon CloudWatch monitors the CloudFront `5xxErrorRate` metric.

The alarm configuration includes:

| Parameter | Configuration |
|---|---|
| Region | `us-east-1` |
| Metric | `AWS/CloudFront` — `5xxErrorRate` |
| Statistic | Average |
| Threshold | Greater than 5% |
| Period | 300 seconds |
| Evaluation periods | 1 |
| Missing data | `notBreaching` |

When the alarm enters the `ALARM` state, Amazon SNS sends an email notification to the confirmed subscriber.

This monitoring detects elevated server-side error rates but does not constitute comprehensive security threat detection.

## 7. Data Protection and Recovery

S3 versioning is enabled to retain previous object versions following file overwrites or deletions.

A lifecycle policy expires noncurrent object versions after 30 days.

This provides limited recovery capabilities for accidental changes and faulty deployments.

It does not replace a comprehensive backup or disaster recovery strategy.

## 8. Secrets and Sensitive Configuration

Terraform state files and local variable values are excluded from the public Git repository through `.gitignore`.

Sensitive or environment-specific configuration, including the monitoring email address and private GitHub repository identifier, is stored outside tracked Terraform source files.

The GitHub Actions deployment workflow uses OIDC instead of stored AWS access keys.

Terraform state must still be protected because it may contain sensitive infrastructure information.

## 9. Security Limitations and Future Improvements

The current architecture intentionally excludes certain optional security and operational capabilities.

| Capability | Current status | Potential improvement |
|---|---|---|
| AWS WAF | Not deployed | Add managed rules and request filtering |
| CloudFront access logging | Not enabled | Enable request-level security analysis |
| S3 access logging | Not enabled | Add origin access audit capabilities |
| Synthetic availability monitoring | Not configured | Add external availability checks |
| Cross-region disaster recovery | Not configured | Add secondary origin and failover |
| Automated security scanning | Not configured | Add security checks to CI/CD |

These enhancements can be prioritized as the website's traffic, functionality, and security requirements evolve.

## 10. Security Summary

The AWS Secure Portfolio architecture implements the following security principles:

- **Defense in depth:** Multiple security controls protect content delivery, storage, and deployment.
- **Principle of least privilege:** IAM permissions are restricted to necessary actions and resources.
- **Secure authentication:** GitHub Actions uses temporary credentials through OIDC.
- **Encryption:** HTTPS protects data in transit, while SSE-S3 protects stored objects.
- **Private origin:** S3 content is accessible through the designated CloudFront distribution.
- **Managed protection:** AWS Shield Standard provides baseline DDoS protection.
- **Cost-aware security:** Additional controls are evaluated according to risk and operational requirements.

The resulting architecture provides a security-focused foundation for a static professional portfolio website while remaining relatively simple to operate and maintain.