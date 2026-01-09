# =========================
# 1️⃣ Criação da API Gateway HTTP (v2)
# =========================
resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
  description   = var.description
}

# =========================
# 2️⃣ Integração com Lambda Authorizer (login)
# =========================
resource "aws_apigatewayv2_integration" "lambda_authorizer" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_authorizer_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# =========================
# 3️⃣ Integração com Lambda Registration (cadastro)
# =========================
resource "aws_apigatewayv2_integration" "lambda_registration" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_registration_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# =========================
# 4️⃣ Authorizer customizado (REQUEST)
# =========================
resource "aws_apigatewayv2_authorizer" "this" {
  name                              = var.authorizer_name
  api_id                            = aws_apigatewayv2_api.this.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = var.lambda_authorizer_invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  authorizer_payload_format_version = "2.0"
}

# =========================
# 5️⃣ Rotas públicas (login e cadastro)
# =========================
resource "aws_apigatewayv2_route" "public_routes" {
  for_each = {
    "POST /auth/login"    = aws_apigatewayv2_integration.lambda_authorizer.id
    "POST /auth/register" = aws_apigatewayv2_integration.lambda_registration.id
    "GET /swagger-ui"     = aws_apigatewayv2_integration.lambda_registration.id
    "GET /actuator"       = aws_apigatewayv2_integration.lambda_registration.id
  }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${each.value}"

  authorization_type = "NONE"
}

# =========================
# 6️⃣ Integração HTTP com ALB do EKS
# =========================
resource "aws_apigatewayv2_integration" "eks_backend" {
  count = var.eks_alb_dns_name != "" ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "http://${var.eks_alb_dns_name}"
  integration_method = "ANY"
  
  connection_type = "INTERNET"
  
  # Preserva o path e query string original
  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# =========================
# 7️⃣ Rotas protegidas (EKS) - ms-production
# =========================
resource "aws_apigatewayv2_route" "production_routes" {
  for_each = var.eks_alb_dns_name != "" ? {
    "GET /order"                    = "Lista pedidos de produção"
    "PUT /order/{orderId}/complete" = "Completa pedido"
    "PUT /order/{orderId}/ready"    = "Marca pedido como pronto"
  } : {}

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.eks_backend[0].id}"

  authorizer_id      = aws_apigatewayv2_authorizer.this.id
  authorization_type = "CUSTOM"
}

# =========================
# 8️⃣ Rotas protegidas (EKS) - ms-order
# =========================
resource "aws_apigatewayv2_route" "order_routes" {
  for_each = var.eks_alb_dns_name != "" ? {
    "POST /api/order/create" = "Cria novo pedido"
    "GET /api/order"         = "Lista todos os pedidos"
    "GET /api/order/status"  = "Lista pedidos por status"
    "GET /api/event/filter"  = "Busca evento por filtros"
    "GET /api/event/all"     = "Lista todos os eventos"
  } : {}

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.eks_backend[0].id}"

  authorizer_id      = aws_apigatewayv2_authorizer.this.id
  authorization_type = "CUSTOM"
}

# =========================
# 9️⃣ Rotas protegidas (EKS) - ms-payment
# =========================
resource "aws_apigatewayv2_route" "payment_routes" {
  for_each = var.eks_alb_dns_name != "" ? {
    "GET /payment/{orderId}" = "Busca pagamento por orderId"
  } : {}

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.eks_backend[0].id}"

  authorizer_id      = aws_apigatewayv2_authorizer.this.id
  authorization_type = "CUSTOM"
}

# =========================
# 🔟 Stage
# =========================
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
}

# =========================
# 1️⃣1️⃣ Permissões Lambda
# =========================
resource "aws_lambda_permission" "allow_invoke" {
  for_each = {
    authorizer   = var.lambda_authorizer_function_name
    registration = var.lambda_registration_function_name
  }

  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
