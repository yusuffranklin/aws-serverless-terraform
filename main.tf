# Provision DynamoDB via Module
module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = "PowerOfMathDatabase"
  hash_key = "id"

  attributes = [
    {
      name = "id"
      type = "N"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}

resource "aws_iam_role" "aws_lambda_function_role" {
    name = var.lambda_role_name
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
            "Effect": "Allow",
            "Sid": ""
            }
        ]
    }
EOF
}

resource "aws_iam_policy" "aws_lambda_function_policy" {
    name = var.lambda_policy_name
    path = "/"
    description = "AWS IAM Policy for managing aws lambda role"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "dynamodb:PutItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:GetItem",
                    "dynamodb:Scan",
                    "dynamodb:Query",
                    "dynamodb:UpdateItem"
                ]
                Effect = "Allow"
                Resource = "${module.dynamodb_table.dynamodb_table_arn}"
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role = aws_iam_role.aws_lambda_function_role.name
    policy_arn = aws_iam_policy.aws_lambda_function_policy.arn
}

# Provision AWS Amplify
resource "aws_amplify_app" "powerofmath_html" {
    name = var.aws_amplify_name
    repository = var.aws_amplify_repository
    oauth_token = var.github_token
    platform = "WEB"
}

resource "aws_amplify_branch" "amplify_branch" {
    app_id = aws_amplify_app.powerofmath_html.id
    branch_name = "master"
}

# Provision AWS Lambda Function
resource "aws_lambda_function" "powerofmath_function" {
    filename = "${path.module}/App/powerofmath.zip"
    function_name = var.aws_lambda_function_name
    role = aws_iam_role.aws_lambda_function_role.arn
    handler = "PowerOfMathFunction.lambda_handler"
    runtime = "python3.9"
    depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

# Provision AWS API Gateway
resource "aws_api_gateway_rest_api" "powerofmath_rest_api" {
    name = var.rest_api_name
}

resource "aws_api_gateway_resource" "powerofmath_api_resource" {
    rest_api_id = aws_api_gateway_rest_api.powerofmath_rest_api.id
    parent_id = aws_api_gateway_rest_api.powerofmath_rest_api.root_resource_id
    path_part = "conversion"
}

resource "aws_api_gateway_method" "powerofmath_api_method" {
    rest_api_id = aws_api_gateway_rest_api.powerofmath_rest_api.id
    resource_id = aws_api_gateway_resource.powerofmath_api_resource.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
    rest_api_id = aws_api_gateway_rest_api.powerofmath_rest_api.id
    resource_id = aws_api_gateway_resource.powerofmath_api_resource.id
    http_method = aws_api_gateway_method.powerofmath_api_method.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.powerofmath_function.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.powerofmath_function.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:${var.my_region}:${var.accountId}:${aws_api_gateway_rest_api.powerofmath_rest_api.id}/*/${aws_api_gateway_method.powerofmath_api_method.http_method}${aws_api_gateway_resource.powerofmath_api_resource.path}"
}

resource "aws_api_gateway_deployment" "powerofmath_deployment" {
    rest_api_id = aws_api_gateway_rest_api.powerofmath_rest_api.id
    triggers = {
        redeployment = sha1(jsonencode(aws_api_gateway_rest_api.powerofmath_rest_api.body))
    }
    lifecycle {
        create_before_destroy = true
    }
    depends_on = [aws_api_gateway_method.powerofmath_api_method, aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_stage" "powerofmath_stage" {
    deployment_id = aws_api_gateway_deployment.powerofmath_deployment.id
    rest_api_id = aws_api_gateway_rest_api.powerofmath_rest_api.id
    stage_name = "dev"
}