module "api_gateway" {
  source      = "./modules/api_gateway"
  name        = var.api_gw_name
  description = var.api_gw_description
  stage_name  = var.api_gw_stage_name

  authorizer_name = var.authorizer_name

  lambda_authorizer_function_name = data.terraform_remote_state.lambda.outputs.lambda_authorizer_function_name
  lambda_authorizer_invoke_arn    = data.terraform_remote_state.lambda.outputs.lambda_authorizer_invoke_arn

  lambda_registration_function_name = data.terraform_remote_state.lambda.outputs.lambda_registration_function_name
  lambda_registration_invoke_arn    = data.terraform_remote_state.lambda.outputs.lambda_registration_invoke_arn

  # Backend EKS
  eks_alb_dns_name = var.eks_alb_dns_name
}