output "api_gateway_id" {
  description = "ID da API Gateway HTTP v2"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_arn" {
  description = "ARN da API Gateway HTTP v2"
  value       = module.api_gateway.api_gateway_arn
}

output "api_gateway_endpoint" {
  description = "URL de endpoint da API Gateway"
  value       = module.api_gateway.api_gateway_endpoint
}

output "api_gateway_execution_arn" {
  description = "ARN de execução da API Gateway HTTP v2"
  value       = module.api_gateway.api_gateway_execution_arn
}

output "stage_name" {
  description = "Nome do stage da API Gateway"
  value       = module.api_gateway.stage_name
}

output "authorizer_id" {
  description = "ID do authorizer customizado"
  value       = module.api_gateway.authorizer_id
}

