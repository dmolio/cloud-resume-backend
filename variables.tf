variable "region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  default     = "resume-challenge"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  default     = "VisitorCountFunction"
}

variable "api_gateway_name" {
  description = "The name of the API Gateway"
  default     = "VisitorCountAPI"
}
