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
  name                              = "nexTimeFood-authorizer"
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
    "POST /auth/login"    = "auth_login"
    "POST /auth/register" = "auth_register"
    "GET /swagger-ui"     = "swagger_ui"
    "GET /actuator"       = "actuator"
  }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key

  target = "integrations/${lookup(
    {
      "POST /auth/login"    = aws_apigatewayv2_integration.lambda_authorizer.id
      "POST /auth/register" = aws_apigatewayv2_integration.lambda_registration.id
      "GET /swagger-ui"     = aws_apigatewayv2_integration.lambda_registration.id
      "GET /actuator"       = aws_apigatewayv2_integration.lambda_registration.id
    },
    each.key
  )}"

  authorization_type = "NONE"
}

# =========================
# 6️⃣ Rotas protegidas (EKS)
# =========================
# resource "aws_apigatewayv2_route" "protected_routes" {
#   for_each = {
#     "GET /product"    = "product_get"
#     "POST /product"   = "product_post"
#     "PUT /product"    = "product_put"
#     "DELETE /product" = "product_delete"

#     "GET /order"  = "order_get"
#     "POST /order" = "order_post"

#     "GET /customer"  = "customer_get"
#     "POST /customer" = "customer_post"

#     "GET /payment"  = "payment_get"
#     "POST /payment" = "payment_post"
#   }

#   api_id    = aws_apigatewayv2_api.this.id
#   route_key = each.key
#   target    = "integrations/${var.eks_backend_integration_id}" # precisa passar o ID do integration do EKS

#   authorizer_id      = aws_apigatewayv2_authorizer.this.id
#   authorization_type = "CUSTOM"
# }

# =========================
# 7️⃣ Stage
# =========================
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
}

# =========================
# 8️⃣ Permissões Lambda
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
