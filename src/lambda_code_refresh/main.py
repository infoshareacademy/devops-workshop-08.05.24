import json
import boto3
import os
from aws_lambda_powertools import Logger

logger = Logger()

def lambda_handler(event, context):

    launch_template_id = os.environ['LaunchTemplateId']
    owner = os.environ['Owner']
    image_prefix = os.environ['ImagePrefix'] + "-*"
    
    ec2 = boto3.client("ec2")
    filters = [
      { "Name" : "name", "Values" : [image_prefix] },
      { "Name" : "virtualization-type", "Values" : ["hvm"] },
      { "Name" : "state", "Values" : ["available"] }
    ]
    images = ec2.describe_images(Owners=[owner], Filters=filters)
    images = sorted(images['Images'], key=lambda x : x['CreationDate'])
    images.reverse()
    logger.info(f"ImageId: {images[0]['ImageId']}")
    response = ec2.describe_launch_templates(
        LaunchTemplateIds=[launch_template_id]
        )
    latest_version_lt = response['LaunchTemplates'][0]['LatestVersionNumber']
    logger.info(f"Launch Template latest version: {latest_version_lt}")
    lt = ec2.create_launch_template_version(
        LaunchTemplateData={
            'ImageId': images[0]['ImageId']
            },
        LaunchTemplateId=launch_template_id,
        SourceVersion=str(latest_version_lt)
    )
    return {'LaunchTemplateVersion': lt['LaunchTemplateVersion']['VersionNumber']}