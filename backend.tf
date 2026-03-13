terraform {
  backend "s3" {
    bucket = "millstack-terraform-state" 
    key = "vpc-foundation/terraform.tfstate" 
    region = "ap-south-1" # Mumbai
    encrypt = true 
    dynamodb_table = "millstack-terraform-lock-state" # for state locking
  }
}