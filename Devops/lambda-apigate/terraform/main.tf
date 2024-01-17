provider "aws" {
  region = "ap-southeast-2"


}

terraform {
  backend "s3" {
    bucket = "techscrum-tfstate-bucket"
    key    = "lambda-tfstate/terraform.tfstate"
    region = "ap-southeast-2"

    # Enable during Step-09     
    # For State Locking
    dynamodb_table = "techscrum-lock-table"
  }
}