# infra-gateway

Repositório contendo a infraestrutura do API Gateway central para o projeto nexTimeFood, utilizando AWS API Gateway HTTP v2 com integração a Lambdas (autenticação/autorização) e backend EKS.

## 📋 Descrição

Este projeto provisiona um API Gateway HTTP v2 na AWS que atua como ponto de entrada centralizado para os serviços do nexTimeFood. O gateway integra:

- **Lambda Functions**: Para autenticação (login) e registro de usuários
- **EKS Backend**: Para roteamento de requisições aos microserviços (ms-production, ms-order, ms-payment)
- **Authorizer Customizado**: Para proteção de rotas com autenticação baseada em token

## 🏗️ Arquitetura

O projeto utiliza Terraform para provisionar:

1. **API Gateway HTTP v2**: Gateway central com protocolo HTTP
2. **Integrações Lambda**:
   - Lambda Authorizer (login)
   - Lambda Registration (cadastro)
3. **Integração HTTP com EKS**: Proxy HTTP para o ALB do cluster EKS
4. **Authorizer REQUEST**: Validação de tokens JWT via header Authorization
5. **Rotas Públicas**: Login, registro e endpoints de monitoramento
6. **Rotas EKS**: Endpoints dos microserviços (production, order, payment)

## 📁 Estrutura do Projeto

```
infra-gateway/
├── infra/
│   ├── main.tf                    # Módulo principal
│   ├── variables.tf               # Variáveis do módulo raiz
│   ├── outputs.tf                 # Outputs do módulo raiz
│   ├── data.tf                    # Data sources (remote state)
│   ├── terraform.tfvars          # Valores das variáveis
│   └── modules/
│       └── api_gateway/
│           ├── main.tf            # Recursos do API Gateway
│           ├── variables.tf       # Variáveis do módulo
│           └── outputs.tf         # Outputs do módulo
├── .github/
│   └── workflows/
│       ├── deploy.yml             # CI/CD para deploy
│       └── destroy.yml            # CI/CD para destroy
└── README.md
```

## 🔧 Pré-requisitos

- **Terraform** >= 1.6.6
- **AWS CLI** configurado com credenciais apropriadas
- **Acesso ao S3** para remote state (`nextime-food-state-bucket`)
- **Remote State Lambda**: O projeto depende do remote state do módulo Lambda para obter os ARNs das funções

## ⚙️ Configuração

### 1. Configurar variáveis

Edite o arquivo `infra/terraform.tfvars`:

```hcl
api_gw_name        = "nexTimeFood-api-gateway"
api_gw_description = "Gateway central nexTimeFood (EKS + Authorizer)"
api_gw_stage_name  = "dev"

# DNS do ALB do EKS (opcional, deixe vazio se não estiver usando)
eks_alb_dns_name = "seu-alb-dns-name.elb.amazonaws.com"
```

### 2. Configurar backend do Terraform

O projeto utiliza remote state do S3. Certifique-se de que o bucket `nextime-food-state-bucket` existe e está acessível.

### 3. Dependências

O módulo depende do remote state do módulo Lambda para obter:
- `lambda_authorizer_function_name`
- `lambda_authorizer_invoke_arn`
- `lambda_registration_function_name`
- `lambda_registration_invoke_arn`

## 🚀 Como Usar

### Inicializar o Terraform

```bash
cd infra
terraform init
```

### Planejar as mudanças

```bash
terraform plan
```

### Aplicar a infraestrutura

```bash
terraform apply
```

### Destruir a infraestrutura

```bash
terraform destroy
```

## 🛣️ Rotas Configuradas

### Rotas Públicas (Sem Autenticação)

#### Autenticação e Registro
- `POST /auth/login` - Login de usuário (Lambda Authorizer)
- `POST /auth/register` - Registro de novo usuário (Lambda Registration)

#### Monitoramento
- `GET /swagger-ui` - Documentação Swagger
- `GET /actuator` - Health check/actuator

### Rotas EKS - ms-production

- `GET /order` - Lista pedidos de produção
- `PUT /order/{orderId}/complete` - Completa pedido
- `PUT /order/{orderId}/ready` - Marca pedido como pronto

### Rotas EKS - ms-order

- `POST /api/order/create` - Cria novo pedido
- `GET /api/order` - Lista todos os pedidos
- `GET /api/order/status` - Lista pedidos por status
- `GET /api/event/filter` - Busca evento por filtros
- `GET /api/event/all` - Lista todos os eventos

### Rotas EKS - ms-payment

- `GET /payment/{orderId}` - Busca pagamento por orderId

> **Nota**: Todas as rotas EKS são públicas no momento. Para adicionar autenticação, descomente e configure as rotas protegidas no arquivo `infra/modules/api_gateway/main.tf`.

## 🔐 Authorizer

O projeto inclui um authorizer customizado do tipo REQUEST que:
- Valida tokens JWT no header `Authorization`
- Utiliza a Lambda Authorizer para validação
- Pode ser aplicado a rotas protegidas (atualmente comentado)

Para habilitar rotas protegidas, descomente a seção de rotas protegidas no `main.tf` do módulo.

## 📤 Outputs do Terraform

Após o deploy, os seguintes outputs estarão disponíveis:

- `api_gateway_id` - ID da API Gateway HTTP v2
- `api_gateway_arn` - ARN da API Gateway
- `api_gateway_endpoint` - URL de endpoint da API Gateway
- `api_gateway_execution_arn` - ARN de execução da API Gateway
- `stage_name` - Nome do stage configurado
- `authorizer_id` - ID do authorizer customizado

## 🔄 CI/CD

O projeto inclui workflows GitHub Actions para deploy automático:

### Deploy (`deploy.yml`)
- Trigger: Push para branch `dev`
- Executa: `terraform fmt`, `terraform validate`, `terraform plan` e `terraform apply`
- Autenticação: OIDC com IAM Role (`github-action-role`)
- Região: `us-east-1`

### Destroy (`destroy.yml`)
- Workflow para destruição da infraestrutura (quando necessário)

## 📝 Variáveis Principais

### Módulo Raiz (`infra/variables.tf`)

| Variável | Tipo | Descrição | Padrão |
|----------|------|-----------|--------|
| `api_gw_name` | string | Nome da API Gateway | - |
| `api_gw_description` | string | Descrição da API Gateway | - |
| `api_gw_stage_name` | string | Nome do stage | - |
| `eks_alb_dns_name` | string | DNS do ALB do EKS | `""` |
| `authorizer_name` | string | Nome do authorizer | `"nexTimeFood-authorizer"` |

## 🔗 Dependências

- **Remote State Lambda**: O projeto busca informações das Lambdas de um remote state no S3
- **Bucket S3**: `nextime-food-state-bucket` (região: `us-east-1`)
- **IAM Role**: `github-action-role` (para CI/CD)

## 📚 Recursos AWS Criados

- `aws_apigatewayv2_api` - API Gateway HTTP v2
- `aws_apigatewayv2_integration` - Integrações com Lambda e EKS
- `aws_apigatewayv2_authorizer` - Authorizer customizado
- `aws_apigatewayv2_route` - Rotas da API
- `aws_apigatewayv2_stage` - Stage de deploy
- `aws_lambda_permission` - Permissões para invocar Lambdas

## 🐛 Troubleshooting

### Erro ao buscar remote state
Verifique se o bucket S3 `nextime-food-state-bucket` existe e está acessível.

### Erro ao invocar Lambdas
Certifique-se de que as Lambdas (authorizer e registration) foram criadas e seus ARNs estão corretos no remote state.

### Rotas EKS não funcionam
Verifique se o `eks_alb_dns_name` está configurado corretamente no `terraform.tfvars` e se o ALB está acessível.

## 📄 Licença

Este projeto faz parte da infraestrutura do nexTimeFood.
