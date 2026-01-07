output "api_gateway_id" {
  description = "ID da API Gateway HTTP v2"
  value       = aws_apigatewayv2_api.this.id
}

output "api_gateway_arn" {
  description = "ARN da API Gateway HTTP v2"
  value       = aws_apigatewayv2_api.this.arn
}

output "api_gateway_execution_arn" {
  description = "ARN de execução da API Gateway HTTP v2"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "api_gateway_endpoint" {
  description = "URL de endpoint da API Gateway"
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "stage_name" {
  description = "Nome do stage da API Gateway"
  value       = aws_apigatewayv2_stage.this.name
}

output "authorizer_id" {
  description = "ID do authorizer customizado"
  value       = aws_apigatewayv2_authorizer.this.id
}

