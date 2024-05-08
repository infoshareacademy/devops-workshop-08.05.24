data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowAutomationAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_build_custom_policy" {
  statement {
    sid = "AllowAddtionalAccess"
    actions = [
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = [
      "*"
    ]
  }
}


data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    sid     = "AllowAutomationAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ami_automation_additional_permissions" {
  statement {
    sid = "GrantIAMPassRole"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.ami_build_ec2_instance_role.arn
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch_trigger_assume_role" {
  statement {
    sid     = "AllowAutomationAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "cloudwatch_trigger_role_policy" {
  statement {
    sid = "GrantTriggerSSM"

    actions = [
      "ssm:StartAutomationExecution",
    ]

    resources = [
      join(":", [replace(aws_ssm_document.ami_build.arn, "document/", "automation-definition/"), "$DEFAULT"])
    ]
  }

  statement {
    sid = "GrantPassRole"

    actions = [
      "iam:PassRole",
    ]

    resources = [aws_iam_role.ami_build_ssm_role.arn]

    condition {
      test     = "StringLikeIfExists"
      variable = "iam:PassedToService"

      values = [
        "ssm.amazonaws.com",
      ]
    }
  }
}
