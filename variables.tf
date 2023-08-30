variable "lambda_role_name" {
    default = "lambda_function_role"
}

variable "lambda_policy_name" {
    default = "lambda_function_policy"
    description = "AWS IAM Policy for managing aws lambda role"
}

variable "aws_amplify_name" {
    default = "frontend_amplify"
}

variable "aws_amplify_repository" {
    type = string
    default = "https://github.com/yusuffranklin/aws-serverless-terraform.git"
}

variable "github_token" {
    type = string
    default = "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"
}

variable "rest_api_name" {
    description = "REST API for Lambda Function"
    default = "powerofmath_rest_api_gateway"
}

variable "aws_lambda_function_name" {
    default = "powerofmath_function"
}

variable "my_region" {
    default = "ap-southeast-1"
}

variable "accountId" {
    type = string
}