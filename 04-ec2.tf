resource "aws_launch_template" "template" {
  name          = var.name
  ebs_optimized = true
  image_id      = data.aws_ami.amazonlinux2.id
  instance_type = "t3.micro"
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }
  private_dns_name_options {
    hostname_type = "resource-name"
  }
  network_interfaces {
    subnet_id                   = module.vpc.private_subnets[0]
    security_groups             = [aws_security_group.private.id, module.efs.security_group_id]
    associate_public_ip_address = false
  }
  lifecycle {
    ignore_changes = [image_id]
  }
}

data "aws_ami" "amazonlinux2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"]
}
