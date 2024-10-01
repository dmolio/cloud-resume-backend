provider "aws" {
  region = var.region
  profile = "default"
}

terraform {
  backend "s3" {
    profile = "default"
    bucket  = "dmolio-terraform"
    key     = "cloud-resume/terraform.tfstate"
    region  = "us-east-1"
  }
}


resource "aws_dynamodb_table" "resume_challenge" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = var.dynamodb_table_name
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "dynamodb_policy"
  description = "Policy to allow Lambda function to access DynamoDB table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.resume_challenge.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_lambda_function" "visitor_count" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  filename      = "${path.module}/main.zip"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.resume_challenge.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_iam_role_policy_attachment.dynamodb_policy_attachment
  ]
}

resource "null_resource" "lambda_zip" {
  provisioner "local-exec" {
    command = "cd lambda_function && zip -r ../main.zip ."
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_api_gateway_rest_api" "visitor_count_api" {
  name        = var.api_gateway_name
  description = "API for visitor count"
}

resource "aws_api_gateway_resource" "visitor_count_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  path_part   = "visitor-count"
}

resource "aws_api_gateway_method" "visitor_count_method" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor_count_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "visitor_count_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id             = aws_api_gateway_resource.visitor_count_resource.id
  http_method             = aws_api_gateway_method.visitor_count_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.visitor_count.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = jsonencode({
      "statusCode" = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "visitor_count_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.visitor_count_method.http_method
  status_code = "200"
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_method_response" "visitor_count_method_response" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor_count_resource.id
  http_method = aws_api_gateway_method.visitor_count_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_count_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "visitor_count_deployment" {
  depends_on = [
    aws_api_gateway_integration.visitor_count_integration,
    aws_api_gateway_integration_response.visitor_count_integration_response,
    aws_api_gateway_method_response.visitor_count_method_response
  ]

  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  stage_name  = "prod"
}
