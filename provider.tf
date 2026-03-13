terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  # safeguard for running the wrong tfvars file in the wrong workspace
  # example: workspace: (dev), but terraform apply -var-files=prod.tfvars
  env = terraform.workspace
}

# validate workspace to match the targeted .tfvars file
resource "null_resource" "workspace_check" {
  lifecycle {
    precondition {
      condition     = local.env == var.environment
      error_message = "ERROR: You are in the '${local.env}' workspace, but your var-file is for '${var.environment}'!"
    }
  }
}