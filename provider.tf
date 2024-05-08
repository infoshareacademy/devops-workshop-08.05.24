terraform {
  backend "s3" {
    region  = "eu-west-1"
    bucket  = "850480876735-demo-tfstate"
    key     = "workshop-demo.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region  = "eu-west-1"
}