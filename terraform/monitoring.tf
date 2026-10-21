# Monitor CloudFront server-side errors.
# CloudFront publishes its metrics in us-east-1.

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx" {
  provider = aws.us_east_1

  alarm_name          = "portfolio-cloudfront-5xx-errors"
  alarm_description   = "Detects CloudFront server-side errors"
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.portfolio.id
    Region         = "Global"
  }

  treat_missing_data = "notBreaching"
}