# Allow GitHub Actions to authenticate with AWS using OIDC.
# No long-lived AWS access keys are required.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

# Allow GitHub Actions from our private website repository
# to assume this role, restricted to the main branch.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "portfolio-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

# Permissions required to deploy website files to S3
# and invalidate the CloudFront cache.
data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "ListPortfolioBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.portfolio.arn
    ]
  }

  statement {
    sid    = "ManagePortfolioObjects"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.portfolio.arn}/*"
    ]
  }

  statement {
    sid    = "InvalidatePortfolioCloudFront"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      aws_cloudfront_distribution.portfolio.arn
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "portfolio-deployment-policy"
  role = aws_iam_role.github_actions_deploy.id

  policy = data.aws_iam_policy_document.github_actions_deploy.json
}