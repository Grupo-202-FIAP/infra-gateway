variable "api_gw_name" {
  type        = string
  description = "Nome da API Gateway"
}

variable "api_gw_description" {
  type        = string
  description = "Descrição da API Gateway"
}

variable "api_gw_stage_name" {
  type        = string
  description = "Nome do stage da API Gateway"
}

variable "eks_alb_dns_name" {
  type        = string
  description = "DNS do ALB que faz proxy para o backend no EKS"
  default     = ""
}

variable "terraform_state_bucket" {
  type        = string
  description = "Nome do bucket S3 onde está armazenado o estado do Terraform do módulo Lambda"
}

variable "terraform_state_key" {
  type        = string
  description = "Chave (caminho) do arquivo de estado no bucket S3"
}

variable "terraform_state_region" {
  type        = string
  description = "Região AWS onde está localizado o bucket S3 do estado do Terraform"
  default     = "us-east-1"
}

variable "authorizer_name" {
  type        = string
  description = "Nome do authorizer customizado"
  default     = "nexTimeFood-authorizer"
}
