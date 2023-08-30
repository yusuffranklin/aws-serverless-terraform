terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}

data "archive_file" "zip_the_app" {
    type = "zip"
    source_dir = "${path.module}/App/Python"
    output_path = "${path.module}/App/powerofmath.zip"
}