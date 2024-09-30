output "dynamodb_table_name" {
  value = aws_dynamodb_table.resume_challenge.name
}

output "lambda_function_name" {
  value = aws_lambda_function.visitor_count.function_name
}

output "api_gateway_url" {
  value = "${aws_api_gateway_rest_api.visitor_count_api.execution_arn}/prod/visitor-count"
}
