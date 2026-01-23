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

output "eks_integration_enabled" {
  description = "Indica se a integração com EKS está ativa"
  value       = var.eks_alb_dns_name != "" ? true : false
}

output "eks_integration_id" {
  description = "ID da integração com EKS (se ativa)"
  value       = var.eks_alb_dns_name != "" ? aws_apigatewayv2_integration.eks_backend[0].id : "N/A - Configure eks_alb_dns_name"
}
