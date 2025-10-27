data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-nextime"
    key    = "lambda/infra.tfstate"
    region = "us-east-1"
  }
}