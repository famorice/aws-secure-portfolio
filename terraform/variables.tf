variable "alert_email" {
  description = "Email address receiving CloudWatch alerts"
  type        = string
  sensitive   = true
}
variable "github_repository" {
  description = "GitHub repository authorized to deploy the website"
  type        = string
}