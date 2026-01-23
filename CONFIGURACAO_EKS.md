# Configuração da Integração EKS

## Problemas Identificados e Corrigidos

### 1. **Integração criada com placeholder inválido**
**Problema:** A integração EKS estava sendo criada mesmo sem um DNS válido, usando `http://placeholder.eks.alb`

**Solução:** Adicionado `count` condicional - a integração só é criada se `eks_alb_dns_name` for fornecido.

### 2. **Rotas criadas sem integração válida**
**Problema:** As rotas EKS eram criadas mesmo quando não havia um backend válido configurado.

**Solução:** Todas as rotas EKS agora usam `for_each` condicional - só são criadas se `eks_alb_dns_name` estiver configurado.

### 3. **URI de integração incorreta**
**Problema:** A URI não estava formatada corretamente para HTTP_PROXY.

**Solução:** Alterado de `http://${var.eks_alb_dns_name}` para `http://${var.eks_alb_dns_name}/{proxy}` com `payload_format_version = "1.0"`.

### 4. **Falta de dependências explícitas**
**Problema:** As rotas podiam ser criadas antes do stage estar pronto.

**Solução:** Adicionado `depends_on` nas rotas EKS para garantir ordem correta de criação.

## Como Configurar

### Passo 1: Obter o DNS do ALB do EKS

Execute no terminal (ou no console AWS):

```bash
# Listar ALBs
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName]' --output table

# Ou se souber o nome do ALB
aws elbv2 describe-load-balancers --names seu-alb-name --query 'LoadBalancers[0].DNSName' --output text
```

### Passo 2: Configurar no terraform.tfvars

Edite o arquivo `infra/terraform.tfvars`:

```hcl
# DNS do ALB do EKS (obrigatório para habilitar rotas EKS)
eks_alb_dns_name = "k8s-default-ingressn-xxxxx-xxxxxxxxxx.us-east-1.elb.amazonaws.com"
```

**IMPORTANTE:** 
- Use APENAS o DNS do ALB, SEM `http://` ou `https://`
- Exemplo correto: `k8s-default-ingressn-xxxxx.us-east-1.elb.amazonaws.com`
- Exemplo errado: `http://k8s-default-ingressn-xxxxx.us-east-1.elb.amazonaws.com`

### Passo 3: Aplicar as mudanças

```bash
cd infra
terraform plan
terraform apply
```

### Passo 4: Verificar no Console AWS

Após o apply:

1. Acesse o console AWS → API Gateway
2. Selecione `nexTimeFood-api-gateway`
3. Vá em **Routes** - você deve ver:
   - Rotas Lambda (login, register, swagger-ui, actuator)
   - **Rotas EKS** (order, payment, production) - se o DNS foi configurado

4. Vá em **Integrations** - você deve ver:
   - `lambda_authorizer`
   - `lambda_registration`
   - **`eks_backend`** (HTTP_PROXY) - se o DNS foi configurado

## Testando as Rotas

### 1. Obter a URL do API Gateway

```bash
cd infra
terraform output api_gateway_endpoint
```

Ou no console AWS → API Gateway → Stages → dev → Invoke URL

### 2. Testar rotas Lambda (devem funcionar sempre)

```bash
# Login
curl -X POST https://seu-api-id.execute-api.us-east-1.amazonaws.com/dev/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Actuator
curl https://seu-api-id.execute-api.us-east-1.amazonaws.com/dev/actuator
```

### 3. Testar rotas EKS (só funcionam se DNS configurado)

```bash
# Production - Listar pedidos
curl https://seu-api-id.execute-api.us-east-1.amazonaws.com/dev/order

# Order - Criar pedido
curl -X POST https://seu-api-id.execute-api.us-east-1.amazonaws.com/dev/api/order/create \
  -H "Content-Type: application/json" \
  -d '{"customerId":"123","items":[]}'

# Payment - Buscar pagamento
curl https://seu-api-id.execute-api.us-east-1.amazonaws.com/dev/payment/123
```

## Verificar Status da Integração EKS

```bash
cd infra
terraform output eks_integration_enabled
terraform output eks_integration_id
```

**Saída esperada:**

- Se **configurado**: 
  - `eks_integration_enabled = true`
  - `eks_integration_id = "xxxxx"`

- Se **NÃO configurado**:
  - `eks_integration_enabled = false`
  - `eks_integration_id = "N/A - Configure eks_alb_dns_name"`

## Rotas Disponíveis (quando EKS configurado)

### ms-production
- `GET /order` - Lista pedidos de produção
- `PUT /order/{orderId}/complete` - Completa pedido
- `PUT /order/{orderId}/ready` - Marca pedido como pronto

### ms-order
- `POST /api/order/create` - Cria novo pedido
- `GET /api/order` - Lista todos os pedidos
- `GET /api/order/status` - Lista pedidos por status
- `GET /api/event/filter` - Busca evento por filtros
- `GET /api/event/all` - Lista todos os eventos

### ms-payment
- `GET /payment/{orderId}` - Busca pagamento por orderId

## Troubleshooting

### Rotas não aparecem no console

**Causa:** `eks_alb_dns_name` está vazio ou não foi aplicado

**Solução:**
1. Verifique `infra/terraform.tfvars` - certifique-se que `eks_alb_dns_name` tem um valor
2. Execute `terraform apply` novamente
3. Verifique `terraform output eks_integration_enabled` - deve retornar `true`

### Erro 503 Service Unavailable

**Causa:** ALB do EKS não está acessível ou DNS incorreto

**Solução:**
1. Verifique se o ALB está ativo: `aws elbv2 describe-load-balancers`
2. Teste o ALB diretamente: `curl http://seu-alb-dns.elb.amazonaws.com/order`
3. Verifique security groups do ALB - deve permitir tráfego HTTP (porta 80)

### Erro 404 Not Found

**Causa:** Rota não existe no backend EKS ou path incorreto

**Solução:**
1. Verifique se o serviço está rodando no EKS
2. Teste diretamente no ALB para confirmar que a rota existe
3. Verifique os Ingress rules no EKS

### Timeout

**Causa:** ALB não está acessível pela internet ou security group bloqueando

**Solução:**
1. Verifique se o ALB é `internet-facing`
2. Verifique security groups do ALB
3. Verifique se o API Gateway consegue acessar o ALB (deve estar em subnet pública)

## Desabilitar Integração EKS

Para desabilitar temporariamente as rotas EKS:

```hcl
# infra/terraform.tfvars
eks_alb_dns_name = ""
```

Execute `terraform apply` - as rotas EKS serão removidas automaticamente.

## Logs e Debugging

### Habilitar logs no API Gateway (opcional)

Adicione ao `infra/modules/api_gateway/main.tf`:

```hcl
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = 7
}
```

### Ver logs no CloudWatch

```bash
aws logs tail /aws/apigateway/nexTimeFood-api-gateway --follow
```
