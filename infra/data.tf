data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = "nextime-food-state-bucket"
    key    = "lambda/infra.tfstate"
    region = "us-east-1"
  }
}