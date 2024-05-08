terraform {
  backend "s3" {
    region  = "eu-west-1"
    bucket  = "850480876735-demo-tfstate"
    key     = "workshop-cicd.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region  = "eu-west-1"
}

##################################

data "aws_iam_policy_document" "trust" {
  statement {
    sid    = "TrustGitHub"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:infoshareacademy/devops-workshop-08.05.24:*"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "github_actions_demo" {
  name               = "github-actions-demo"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions_demo.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
  client_id_list  = ["sts.amazonaws.com"]
}