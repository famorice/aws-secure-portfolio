# Architecture Decision Records

This document explains the key architectural decisions behind AWS Secure Portfolio, including the alternatives considered and the trade-offs involved.

## ADR-001: Use Amazon S3 and CloudFront Instead of Amazon EC2

**Status:** Accepted

### Context

The portfolio website consists of static HTML, CSS, JavaScript, images, and other assets. It does not require server-side application processing or a continuously running web server.

The architecture must prioritize security, reliability, simplicity, and cost optimization.

### Decision

Host the website files in a private Amazon S3 bucket and distribute them globally through Amazon CloudFront.

Use CloudFront Origin Access Control (OAC) to securely access the S3 origin without exposing the bucket publicly.

### Rationale

- **Cost optimization:** S3 and CloudFront use consumption-based pricing, avoiding the cost of a continuously running EC2 instance.
- **Operational simplicity:** No operating system, web server, patching, or instance maintenance is required.
- **Resilience:** S3 provides multi-Availability Zone redundancy, while CloudFront distributes and caches content through its global edge network.
- **Performance:** CloudFront serves cached content closer to visitors, reducing latency.
- **Security:** The S3 bucket remains private, with access restricted to the designated CloudFront distribution.

### Alternatives Considered

**Amazon EC2**

An EC2 instance running NGINX or Apache could serve the website but would introduce additional server management, patching, and infrastructure costs.

**AWS Amplify Hosting**

A managed alternative offering static website hosting and integrated deployment workflows. However, S3 and CloudFront were selected to provide more direct control over the underlying AWS infrastructure and demonstrate infrastructure design skills.

### Trade-offs

- The architecture does not support server-side application processing without additional services.
- S3 is deployed in a single AWS Region; cross-region disaster recovery is not implemented.
- CloudFront cache invalidations or appropriate cache-control policies are needed to ensure visitors receive updated content.

### Outcome

The selected architecture provides a secure, low-maintenance, and cost-optimized foundation for a static professional portfolio website.

## ADR-002: Use Terraform for Infrastructure as Code

**Status:** Accepted

### Context

The AWS infrastructure includes S3, CloudFront, Route 53, ACM, IAM, CloudWatch, and SNS.

The infrastructure must be reproducible, version-controlled, and maintainable.

Several Infrastructure as Code (IaC) solutions were considered.

### Decision

Use **Terraform** to provision and manage AWS infrastructure.

Store the Terraform configuration in a public GitHub repository to demonstrate infrastructure design and implementation skills.

### Rationale

- **Declarative configuration:** Infrastructure is defined using HashiCorp Configuration Language (HCL).
- **Execution planning:** `terraform plan` previews proposed infrastructure changes before they are applied.
- **Reproducibility:** Infrastructure can be provisioned consistently across environments.
- **Modularity:** Resources can be organized into separate configuration files and reusable modules.
- **Multi-cloud support:** Terraform supports multiple cloud providers, although this project uses AWS exclusively.
- **Portfolio value:** Terraform demonstrates transferable Infrastructure as Code skills.

### Alternatives Considered

**AWS CloudFormation**

A native AWS IaC service that uses JSON or YAML templates and integrates directly with AWS.

It was not selected because Terraform provides a provider-independent workflow and broader multi-cloud applicability.

**AWS Cloud Development Kit (CDK)**

Allows infrastructure to be defined using programming languages such as TypeScript, Python, and C#.

It was not selected because Terraform's declarative HCL configuration was preferred for this project's infrastructure management.

### Trade-offs

- Terraform requires state management to track infrastructure resources.
- State files may contain sensitive information and must be protected.
- Terraform and provider versions must be managed to maintain compatibility.
- Terraform introduces an additional tool outside the native AWS ecosystem.

### Outcome

Terraform provides a consistent, version-controlled approach to managing the AWS Secure Portfolio infrastructure.

The Terraform configuration is publicly available, while state files and sensitive variable values remain excluded from Git.

## ADR-003: Use GitHub Actions with OIDC for Secure Deployment

**Status:** Accepted

### Context

The portfolio website requires a CI/CD pipeline to automatically deploy changes from its private GitHub repository to Amazon S3 and invalidate the CloudFront cache.

The pipeline must authenticate securely to AWS without exposing permanent credentials.

### Decision

Use **GitHub Actions** for automated deployment and **OpenID Connect (OIDC)** for authentication to AWS.

Configure an AWS IAM role that GitHub Actions can assume using temporary credentials.

Restrict role assumption to the authorized GitHub repository and its `main` branch.

### Rationale

- **Keyless authentication:** Eliminates the need to store long-lived AWS access keys in GitHub secrets.
- **Temporary credentials:** AWS Security Token Service (STS) issues credentials with a limited lifetime.
- **Least privilege:** The deployment role is restricted to the required S3 operations and CloudFront cache invalidation.
- **Repository and branch restrictions:** The IAM trust policy limits which GitHub Actions workflows can assume the role.
- **Automation:** Website changes can be deployed automatically when pushed or merged into `main`.
- **Separation of responsibilities:** The deployment role manages website content without granting permission to modify AWS infrastructure.

### Alternatives Considered

**IAM User with Access Keys**

Store an AWS access key ID and secret access key in GitHub Actions secrets.

This approach was rejected because it requires managing, rotating, and protecting long-lived credentials.

**Manual Deployment Using AWS CLI**

Upload website files directly to S3 and invalidate CloudFront manually.

This approach avoids CI/CD configuration but introduces repetitive manual work and increases the risk of inconsistent deployments.

### Trade-offs

- OIDC requires additional IAM configuration, including an identity provider and role trust policy.
- Incorrect trust policy conditions could allow unauthorized role assumption.
- Deployment depends on GitHub Actions availability.
- Automatic deployment requires appropriate branch protection and code review practices to reduce the risk of publishing unintended changes.

### Outcome

GitHub Actions provides a repeatable deployment process using temporary AWS credentials.

The IAM deployment role is restricted to the portfolio S3 bucket and CloudFront distribution, reducing the security risks associated with permanent access keys.

## ADR-004: Use a Private S3 Bucket with CloudFront Origin Access Control

**Status:** Accepted

### Context

Amazon S3 can serve static website content through a public website endpoint. However, this approach requires publicly accessible content and does not provide native HTTPS support through the S3 website endpoint.

The portfolio architecture requires secure HTTPS delivery while preventing visitors from accessing website files directly through S3.

### Decision

Use a **private Amazon S3 bucket** as the CloudFront origin, with **Origin Access Control (OAC)** to authenticate CloudFront requests to S3.

Configure the S3 bucket to block public access and restrict object retrieval to the designated CloudFront distribution.

### Rationale

- **Private origin:** Website objects are not publicly accessible through S3 URLs.
- **Authenticated origin requests:** CloudFront uses AWS Signature Version 4 (SigV4) to sign requests to S3.
- **Principle of least privilege:** The S3 bucket policy grants `s3:GetObject` permission to the CloudFront service principal, restricted by the distribution ARN.
- **HTTPS delivery:** CloudFront provides HTTPS access using an ACM-managed certificate.
- **Centralized delivery:** Visitors retrieve website content through CloudFront rather than directly from S3.
- **Reduced exposure:** S3 Block Public Access and disabled ACLs help prevent accidental public exposure of objects.

### Alternatives Considered

**Public S3 Static Website Hosting**

Enable S3 static website hosting and allow public access to website objects.

This approach is simple but exposes the S3 website endpoint publicly and does not support HTTPS directly.

**CloudFront with Origin Access Identity (OAI)**

Use the legacy CloudFront mechanism for restricting access to an S3 origin.

OAI was not selected because AWS recommends OAC for new implementations. OAC supports SigV4 request signing and provides broader functionality.

### Trade-offs

- CloudFront and OAC require additional configuration compared with public S3 website hosting.
- The S3 REST endpoint does not provide the same website-specific behavior as the S3 website endpoint, including automatic directory index resolution.
- Custom error responses or URL rewriting may be required for certain website routing patterns.
- CloudFront introduces additional CDN-related costs, although caching can reduce origin requests.

### Outcome

The architecture keeps the S3 bucket private while delivering website content securely through CloudFront.

The bucket policy restricts read access to the designated CloudFront distribution, and public access remains blocked.

## ADR-005: Use a Single AWS Region with Global CloudFront Distribution

**Status:** Accepted

### Context

The portfolio website is a static application with relatively low traffic and no critical business transactions.

The architecture must provide reliable content delivery while minimizing infrastructure complexity and operational costs.

A multi-region architecture could improve disaster recovery capabilities but would introduce additional infrastructure and management overhead.

### Decision

Store website content in a single Amazon S3 bucket in **Canada (Central), `ca-central-1`**, and distribute it globally using Amazon CloudFront.

Use AWS-managed service redundancy rather than implementing cross-region replication and failover.

### Rationale

- **Managed-service resilience:** Amazon S3 redundantly stores objects across multiple Availability Zones within the selected Region.
- **Global content delivery:** CloudFront caches and delivers website content through its distributed edge network.
- **Cost optimization:** Avoids the additional storage, replication, and infrastructure costs of a multi-region architecture.
- **Operational simplicity:** Eliminates the need to configure and maintain cross-region replication and origin failover.
- **Regional preference:** Keeps the primary website storage infrastructure in Canada.

### Alternatives Considered

**Multi-Region S3 Replication**

Replicate website content to a second S3 bucket in another AWS Region.

This could improve disaster recovery capabilities but would introduce additional storage, replication, and configuration costs.

**CloudFront Origin Failover**

Configure a CloudFront origin group with primary and secondary S3 origins in different Regions.

This could improve availability during certain origin failures but would require additional infrastructure and failover configuration.

### Trade-offs

- The S3 origin remains dependent on a single AWS Region.
- A regional S3 outage could affect requests that cannot be satisfied from CloudFront's cache.
- No automatic cross-region failover is implemented.
- Recovery from a major regional outage would require additional procedures or infrastructure.

### Outcome

The architecture benefits from S3's multi-AZ redundancy and CloudFront's globally distributed content delivery without the cost and complexity of a multi-region deployment.

This provides an appropriate balance between resilience, simplicity, and cost optimization for a professional portfolio website.

## ADR-006: Defer AWS WAF and Access Logging for Cost Optimization

**Status:** Accepted

### Context

The portfolio website is a public-facing static application with limited expected traffic and no authentication, sensitive user data, or server-side business logic.

AWS WAF and access logging could provide additional security controls and operational visibility. However, these capabilities may introduce recurring costs that are disproportionate to the project's current requirements.

The architecture must balance security, observability, and cost optimization.

### Decision

Defer the implementation of **AWS WAF and access logging** during the initial deployment.

Retain the following baseline protections and monitoring capabilities:

- AWS Shield Standard for automatic DDoS protection.
- CloudFront HTTPS delivery using an ACM-managed certificate.
- Private S3 bucket with Origin Access Control (OAC).
- CloudWatch monitoring of CloudFront 5xx error rates.
- Amazon SNS email notifications for CloudWatch alarms.
- AWS Budgets for cost monitoring.

### Rationale

- **Cost optimization:** Avoids additional recurring costs associated with AWS WAF and log storage or processing.
- **Risk-based security:** The static website has a relatively small attack surface compared with applications that process user input or execute server-side logic.
- **Existing protection:** AWS Shield Standard provides baseline DDoS protection for CloudFront.
- **Operational simplicity:** Reduces the number of services, policies, and monitoring configurations to maintain.
- **Incremental architecture:** Additional controls can be introduced when traffic, security requirements, or operational needs justify them.

### Alternatives Considered

**Enable AWS WAF Immediately**

Associate a Web ACL with CloudFront and configure managed rule groups to filter malicious HTTP requests.

This would provide additional application-layer protection but introduce costs and require ongoing rule management.

**Enable CloudFront and S3 Access Logging**

Collect detailed request logs for troubleshooting, traffic analysis, and security investigations.

This would improve observability but introduce storage and potentially processing costs, depending on the logging configuration and usage.

### Trade-offs

- Without AWS WAF, the architecture lacks configurable application-layer request filtering.
- Without access logging, detailed request-level information is unavailable for historical analysis and security investigations.
- CloudWatch 5xx monitoring detects certain availability issues but does not provide complete visibility into website traffic or security events.
- AWS Shield Standard does not replace the application-layer protections provided by AWS WAF.

### Reassessment Criteria

The decision should be revisited if:

- Website traffic increases significantly.
- Suspicious or abusive request patterns emerge.
- More detailed troubleshooting or security investigations become necessary.
- The website introduces dynamic functionality, authentication, or user-submitted data.
- Additional security or compliance requirements arise.

### Outcome

The initial architecture maintains baseline AWS security protections and operational monitoring while avoiding optional recurring costs.

AWS WAF and access logging remain potential future enhancements rather than components of the current implementation.

## ADR-007: Enable S3 Versioning with a 30-Day Lifecycle Policy

**Status:** Accepted

### Context

The portfolio website is deployed to Amazon S3 through a GitHub Actions CI/CD pipeline.

Each deployment may replace or delete existing website files. An incorrect deployment could introduce broken content or accidentally remove important assets.

The architecture requires a simple recovery mechanism while minimizing long-term storage costs.

### Decision

Enable **S3 Versioning** on the portfolio bucket and configure an S3 lifecycle rule to automatically expire noncurrent object versions after 30 days.

Current object versions are not subject to this expiration rule.

### Rationale

- **Recovery:** Previous object versions can be restored following accidental overwrites or deletions, provided they have not expired under the 30-day lifecycle policy.
- **Deployment safety:** Versioning provides a recovery mechanism when a deployment introduces incorrect website files.
- **Cost optimization:** Automatically removing noncurrent versions after 30 days limits the accumulation of historical objects.
- **Operational simplicity:** S3 manages object versions and lifecycle expiration without requiring additional infrastructure.
- **Automation:** The lifecycle policy operates automatically after configuration.

### Alternatives Considered

**Disable S3 Versioning**

Store only the latest version of each website object.

This would minimize version-related storage costs but eliminate the ability to recover previous object versions directly from S3.

**Enable Versioning Without Lifecycle Expiration**

Retain all historical object versions indefinitely.

This would provide a longer recovery window but could lead to increasing storage costs as deployments accumulate.

**Use Cross-Region Replication**

Replicate objects to a secondary S3 bucket in another AWS Region.

This could provide additional disaster recovery capabilities but would introduce extra infrastructure, storage, and replication costs.

### Trade-offs

- S3 versioning increases storage consumption because previous object versions are retained.
- Noncurrent versions are eligible for expiration after 30 days, limiting the recovery window.
- Versioning does not provide automatic application rollback; restoring a previous website state requires additional actions.
- The lifecycle policy does not protect against complete bucket deletion or all forms of administrative error.
- S3 lifecycle expiration is asynchronous, so eligible versions may not be physically removed immediately.

### Outcome

S3 versioning provides a lightweight recovery mechanism for accidental file modifications and faulty deployments.

The 30-day lifecycle policy balances short-term recoverability with long-term storage cost optimization.

## ADR-008: Use Amazon CloudWatch and SNS for Lightweight Monitoring

**Status:** Accepted

### Context

The portfolio website is a static application delivered through Amazon CloudFront, with Amazon S3 serving as its private origin.

The architecture requires basic operational monitoring to detect server-side errors and notify the website owner when an issue occurs.

A comprehensive observability solution could provide additional visibility but would introduce unnecessary complexity and potentially higher costs for the project's current requirements.

### Decision

Use **Amazon CloudWatch** to monitor CloudFront's `5xxErrorRate` metric and **Amazon SNS** to deliver email notifications when the configured alarm enters the `ALARM` state.

Configure the CloudWatch alarm with the following parameters:

- **Metric:** `AWS/CloudFront` — `5xxErrorRate`
- **Statistic:** Average
- **Threshold:** Greater than 5%
- **Period:** 300 seconds (5 minutes)
- **Evaluation periods:** 1
- **Missing data:** Treated as not breaching
- **Region:** `us-east-1`

Configure the SNS topic and email subscription in `us-east-1`.

### Rationale

- **Managed monitoring:** CloudWatch provides native integration with CloudFront metrics.
- **Automated notifications:** SNS delivers email alerts when the CloudWatch alarm enters the alarm state.
- **Operational simplicity:** No monitoring servers, agents, or additional infrastructure are required.
- **Cost optimization:** Uses standard CloudFront metrics and a minimal number of monitoring resources.
- **Infrastructure as Code:** CloudWatch alarms and SNS resources are provisioned and managed through Terraform.
- **Regional consistency:** CloudFront metrics, the CloudWatch alarm, and the SNS topic are configured in `us-east-1`.

### Alternatives Considered

**Amazon CloudWatch with Additional Metrics and Dashboards**

Monitor additional CloudFront metrics, including 4xx errors, request volume, and traffic patterns, using custom dashboards and multiple alarms.

This would provide greater operational visibility but increase monitoring configuration and potentially recurring costs.

**Amazon CloudWatch Synthetics**

Configure canaries to periodically test website availability and functionality.

This could detect failures that do not generate CloudFront 5xx errors but would introduce additional monitoring costs.

**Third-Party Monitoring Solutions**

Use an external monitoring platform for availability checks, alerting, and performance analysis.

This could provide more comprehensive observability but would introduce additional integrations and potentially subscription costs.

### Trade-offs

- Monitoring is limited to CloudFront server-side error rates.
- HTTP 4xx errors are not monitored by the configured alarm.
- The alarm does not detect all DNS, connectivity, or application-content failures.
- No synthetic availability checks are configured.
- Without access logging, detailed historical request analysis is unavailable.
- The alarm detects errors after they occur rather than preventing them.

### Reassessment Criteria

The monitoring strategy should be revisited if:

- Website traffic or operational requirements increase.
- More comprehensive availability monitoring becomes necessary.
- Additional website functionality is introduced.
- Detailed performance analysis or request-level troubleshooting is required.
- Security or reliability requirements justify additional monitoring costs.

### Outcome

CloudWatch and SNS provide a lightweight, automated monitoring solution appropriate for the portfolio's current requirements.

The architecture can evolve toward more comprehensive observability as operational needs increase.

## ADR-009: Use CloudFront PriceClass_100 for Cost Optimization

**Status:** Accepted

### Context

Amazon CloudFront distributes website content through a global network of edge locations, improving performance by serving cached content closer to visitors.

CloudFront offers different price classes that determine which edge locations are used to deliver content.

The portfolio website primarily targets recruiters, employers, and professional contacts in North America, with potential visitors from other regions.

The architecture must balance global accessibility, content delivery performance, and cost optimization.

### Decision

Configure the CloudFront distribution with **`PriceClass_100`**, limiting content delivery to the lowest-cost price class, primarily covering North America and Europe.

### Rationale

- **Cost optimization:** Limits content delivery to a subset of CloudFront edge locations to help control data transfer costs.
- **Target audience:** Prioritizes geographic regions where most expected visitors are located.
- **Global accessibility:** Visitors from other regions can still access the website.
- **Performance:** CloudFront caching reduces repeated requests to the S3 origin and improves content delivery latency.
- **Operational simplicity:** Price class selection is managed directly through Terraform without additional infrastructure.

### Alternatives Considered

**PriceClass_200**

Provides access to a broader selection of edge locations, including additional geographic regions.

This could improve performance for visitors outside North America and Europe but may increase content delivery costs.

**PriceClass_All**

Uses all available CloudFront edge locations, providing the broadest geographic coverage.

This could offer better performance for a globally distributed audience but may introduce higher costs in certain regions.

### Trade-offs

- Visitors outside the selected price class may experience higher latency because requests are served through more distant edge locations.
- The architecture prioritizes cost efficiency over maximum global edge coverage.
- CloudFront performance may vary depending on visitor location and network conditions.
- The price class may need to be reconsidered if the website attracts significant traffic from other geographic regions.

### Reassessment Criteria

The decision should be revisited if:

- Website traffic increases significantly.
- Analytics indicate substantial traffic from regions outside North America and Europe.
- Users experience unacceptable latency.
- Performance requirements become more important than minimizing delivery costs.

### Outcome

`PriceClass_100` provides an appropriate balance between content delivery performance and cost optimization for the portfolio's expected audience.

The configuration can be changed through Terraform if geographic traffic patterns or performance requirements evolve.

## ADR-010: Use Amazon Route 53 and AWS Certificate Manager for DNS and HTTPS

**Status:** Accepted

### Context

The portfolio website requires a professional custom domain (`it.famory-sissoko.com`) and secure HTTPS access.

The architecture must provide reliable DNS resolution, TLS certificate management, and seamless integration with Amazon CloudFront while minimizing operational complexity.

### Decision

Use **Amazon Route 53** to manage DNS records and **AWS Certificate Manager (ACM)** to provision and manage the TLS certificate.

Configure:

- A public Route 53 hosted zone for `famory-sissoko.com`.
- An alias A record pointing `it.famory-sissoko.com` to the CloudFront distribution.
- An ACM certificate for `it.famory-sissoko.com` in `us-east-1`.
- DNS-based certificate validation through Route 53.
- CloudFront HTTPS delivery using the ACM certificate.
- HTTP-to-HTTPS redirection through CloudFront.

### Rationale

- **AWS integration:** Route 53 and ACM integrate directly with CloudFront and Terraform.
- **Managed TLS certificates:** ACM provides certificate issuance and managed renewal for eligible certificates without requiring manual certificate installation.
- **Secure communication:** HTTPS encrypts traffic between visitors and CloudFront.
- **Automated validation:** Terraform creates the DNS validation records required by ACM.
- **Reliable DNS:** Route 53 provides a highly available, managed DNS service.
- **Operational simplicity:** DNS configuration and certificate resources are managed through Infrastructure as Code.
- **Cost optimization:** ACM public certificates used with integrated AWS services such as CloudFront generally do not incur an additional certificate charge.

### Alternatives Considered

**External DNS Provider**

Manage DNS records through a third-party registrar or DNS hosting provider.

This could provide equivalent DNS functionality but would require additional integration or manual configuration outside the project's AWS infrastructure.

**Third-Party TLS Certificate**

Obtain and manage a TLS certificate from an external certificate authority.

This could provide secure HTTPS access but introduce additional certificate installation, renewal, and maintenance responsibilities.

### Trade-offs

- Route 53 public hosted zones incur recurring charges.
- Domain registration and renewal introduce additional costs.
- CloudFront requires its ACM certificate to be provisioned in `us-east-1`, introducing a regional dependency.
- DNS propagation and certificate validation may introduce delays during initial provisioning or configuration changes.
- The architecture depends on AWS-managed DNS and certificate services.

### Outcome

Route 53 and ACM provide integrated DNS and HTTPS management for the portfolio website.

The custom domain resolves to CloudFront, while ACM provides a managed TLS certificate for secure visitor connections.

Terraform manages the DNS records, certificate provisioning, and validation configuration.