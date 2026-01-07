# ============================================
# Configuracoes da API Gateway
# ============================================
api_gw_name        = "nexTimeFood-api-gateway"
api_gw_description = "Gateway central nexTimeFood (EKS + Authorizer)"
api_gw_stage_name  = "dev"

# Nome do authorizer (opcional, padrao: "nexTimeFood-authorizer")
# authorizer_name = "nexTimeFood-authorizer"

# ============================================
# Configuracoes opcionais
# ============================================
# DNS do ALB do EKS (opcional, deixe vazio se nao estiver usando)
eks_alb_dns_name = ""
