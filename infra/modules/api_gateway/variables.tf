# Nome da API Gateway
variable "name" {
  type        = string
  description = "Nome da API Gateway HTTP v2"
}

# Descrição da API
variable "description" {
  type        = string
  description = "Descrição da API Gateway"
  default     = "Gateway central nexTimeFood (EKS + Authorizer)"
}

# Nome do stage
variable "stage_name" {
  type        = string
  description = "Nome do stage da API Gateway"
  default     = "dev"
}

# variable "eks_alb_dns_name" {
#   type        = string
#   description = "DNS do ALB que faz proxy para o backend no EKS"
#   default     = ""
# }

variable "lambda_authorizer_function_name" {
  type        = string
  description = "Nome da Lambda Authorizer (login)"
}

variable "lambda_authorizer_invoke_arn" {
  type        = string
  description = "ARN de invocação da Lambda Authorizer"
}

# Lambda Registration
variable "lambda_registration_function_name" {
  type        = string
  description = "Nome da Lambda Registration (cadastro)"
}

variable "lambda_registration_invoke_arn" {
  type        = string
  description = "ARN de invocação da Lambda Registration"
}
