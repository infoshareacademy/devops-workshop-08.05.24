data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  lambda_name = "${var.name}-ami-refresh"
  region_name = data.aws_region.current.name
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.4.0"

  function_name = local.lambda_name
  description   = "Function to refresh ami id in Launch Template"
  handler       = "main.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  publish       = true
  layers        = ["arn:aws:lambda:${local.region_name}:017000801446:layer:AWSLambdaPowertoolsPythonV2:69"]
  environment_variables = {
    LaunchTemplateId        = aws_launch_template.template.id
    Owner                   = data.aws_caller_identity.current.account_id
    ImagePrefix             = var.image_name_prefix
    POWERTOOLS_SERVICE_NAME = local.lambda_name
  }
  source_path = "./src/lambda_code_refresh"
  allowed_triggers = {
    TriggerLambda = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.trigger_lambda.arn
    }
  }
  tags = merge(
    var.common_tags,
    {
      Name = local.lambda_name
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_cloudwatch_event_rule" "trigger_lambda" {
  name                = "trigger-${local.lambda_name}-${random_id.hex.hex}"
  description         = "Trigger ${local.lambda_name} lambda function"
  schedule_expression = "cron(0 20 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_function" {
  rule = aws_cloudwatch_event_rule.trigger_lambda.name
  arn  = module.lambda_function.lambda_function_arn
}

resource "random_id" "hex" {
  byte_length = 8
}
