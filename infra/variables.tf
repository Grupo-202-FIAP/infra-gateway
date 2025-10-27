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
}
