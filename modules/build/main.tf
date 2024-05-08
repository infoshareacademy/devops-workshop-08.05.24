locals {
  userdata          = base64encode(var.build_ami_userdata)
  project_name      = lower(var.project_name)
  ssm_template_file = var.ssm_template_file == "" ? "${path.module}/ami_build.yaml" : var.ssm_template_file
}

resource "random_id" "hex" {
  byte_length = 8
}

# IAM Roles
# EC2
resource "aws_iam_role" "ami_build_ec2_instance_role" {
  name               = "${local.project_name}_ami_build_${random_id.hex.hex}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ami_ec2_build_amzn2" {
  role       = aws_iam_role.ami_build_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ec2_custom_policy" {
  policy = data.aws_iam_policy_document.ec2_build_custom_policy.json
}

resource "aws_iam_role_policy_attachment" "ami_ec2_build_amzn2_custom" {
  role       = aws_iam_role.ami_build_ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_custom_policy.arn
}

resource "aws_iam_instance_profile" "build_instance_profile" {
  name = "${local.project_name}_ami_build_${random_id.hex.hex}"
  role = aws_iam_role.ami_build_ec2_instance_role.name
}

resource "aws_iam_role" "cloudwatch_trigger_ssm_role" {
  name               = "${local.project_name}_cw_trigger_ssm_role_${random_id.hex.hex}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_trigger_assume_role.json
}

resource "aws_iam_policy" "cloudwatch_ssm_trigger_policy" {
  name        = "${local.project_name}_cw_trigger_policy_${random_id.hex.hex}"
  description = "Allow CloudWatch to trigger and passrole to SSM"
  path        = "/"
  policy      = data.aws_iam_policy_document.cloudwatch_trigger_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_ssm_trigger" {
  role       = aws_iam_role.cloudwatch_trigger_ssm_role.name
  policy_arn = aws_iam_policy.cloudwatch_ssm_trigger_policy.arn
}

# SSM Automation
resource "aws_iam_role" "ami_build_ssm_role" {
  name               = "${local.project_name}_ssm_automation_role_${random_id.hex.hex}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ami_build_managed_automation" {
  role       = aws_iam_role.ami_build_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_policy" "additional_ssm_automation" {
  name        = "${local.project_name}_additional_grants_${random_id.hex.hex}"
  description = "Allow ssm automation to perform additional actions"
  path        = "/"
  policy      = data.aws_iam_policy_document.ami_automation_additional_permissions.json
}

resource "aws_iam_role_policy_attachment" "additional_ssm_automation" {
  role       = aws_iam_role.ami_build_ssm_role.name
  policy_arn = aws_iam_policy.additional_ssm_automation.arn
}

# CloudWatch Logs and Event Triggers
resource "aws_cloudwatch_event_rule" "cron" {
  schedule_expression = var.build_cycle_cron
  name                = "trigger-${var.project_name}-${random_id.hex.hex}"
}
resource "aws_cloudwatch_event_target" "cron_target" {
  arn      = replace(aws_ssm_document.ami_build.arn, "document/", "automation-definition/")
  rule     = aws_cloudwatch_event_rule.cron.name
  role_arn = aws_iam_role.cloudwatch_trigger_ssm_role.arn
}

resource "aws_cloudwatch_log_group" "ssm_logs" {
  name = "${local.project_name}-logs-${random_id.hex.hex}"
}

resource "aws_security_group" "instance_build_sg" {
  name_prefix = "${local.project_name}_build_sg_"
  description = "For Image Building-${local.project_name}"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-build"
    }
  )
}

resource "aws_ssm_document" "ami_build" {
  name            = "${local.project_name}-build-${random_id.hex.hex}"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile(local.ssm_template_file, {
    project_name      = local.project_name
    image_name_prefix = var.image_name_prefix
    automation_role   = aws_iam_role.ami_build_ssm_role.arn
    instance_profile  = aws_iam_instance_profile.build_instance_profile.name
    security_group    = aws_security_group.instance_build_sg.id
    subnet_id         = element(var.private_subnets_ids, 1)
    instance_userdata = local.userdata
    log_group         = aws_cloudwatch_log_group.ssm_logs.name
    efs_id            = var.efs_id
  })
}

# SSM Parameter Store - CloudWatch Agent Configuration
resource "aws_ssm_parameter" "cloudwatch" {
  name  = "AmazonCloudWatch-${local.project_name}"
  type  = "String"
  value = data.local_file.AmazonCloudWatchConfig.content
}

data "local_file" "AmazonCloudWatchConfig" {
  filename = "${path.module}/AmazonCloudWatchConfig.json"
}
