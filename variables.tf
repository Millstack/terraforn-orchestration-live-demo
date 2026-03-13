
#==========================
# Environment & Project
#==========================
variable "environment" {
  type        = string
  description = "The environment name (dev, test, prod)"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type = string
}

#==========================
# Networking (Manual CIDRs)
#==========================
variable "vpc_cidr" { type = string }

variable "pub_sub_1a_cidr" { type = string }
variable "pub_sub_1b_cidr" { type = string }
variable "pvt_sub_1a_cidr" { type = string }
variable "pvt_sub_1b_cidr" { type = string }

#==========================
# IAM & Compute
#==========================
variable "existing_iam_role" { type = string }
variable "new_iam_role_policies" { type = list(string) }
variable "public_key" { type = string }
variable "instance_type" { type = string }

# user data script variables
variable "api_s3_bucket" { type = string }
variable "api_artifact_name" { type = string }
variable "api_artifact_folder" { type = string }
variable "app_s3_bucket" { type = string }
variable "app_artifact_name" { type = string }

#==========================
# Security Group Rules
#==========================
variable "public_sg_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "private_sg_ingress" {
  type = list(object({
    port        = number
    protocol    = string
    description = string
  }))
}

variable "private_sg_egress" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}


#==========================
# Auto Scaling Group
#==========================

# asg scaling policy variables
variable "asg_min_size" { type = number }
variable "asg_max_size" { type = number }
variable "asg_desired_capacity" { type = number }

# asg metric - req count base i/o metric needed reource label
# variable "alb_arn_suffix" { type = string }
# variable "alb_tg_arn_suffix" { type = string }

# asg target values
variable "asg_cpu_target" { type = number}
variable "asg_req_count_target" { type = number}



#===================================
# Domain & Security (ACM & Route 53)
#===================================

variable "acm_certificate_arn_regional" { type = string } # for ALB
variable "acm_certificate_arn_global" { type = string } # for cloudfront
variable "route53_hosted_zone_id" { type = string }
variable "domain_name" { type = string }
variable "subdomain_app" { type = string }
variable "subdomain_api" { type = string }


#=========================================================
# Frontend Storage (S3)
#=========================================================

variable "existing_s3_bucket_name" { type = string }

