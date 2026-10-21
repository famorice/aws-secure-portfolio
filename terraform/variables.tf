variable "alert_email" {
  description = "Email address receiving CloudWatch alerts"
  type        = string
  sensitive   = true
}