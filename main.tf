# git:: prefix is a best practice as it explicitly tells Terraform to use the Git installer
module "vpc" {
  # source = "./modules/vpc"
  source = "git::https://github.com/Millstack/terraform-aws-vpc.git?ref=v1.1.3"

  # project and vpc
  environment  = var.environment
  aws_region   = var.aws_region
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr

  # cidr blocks for subnets
  pub_sub_1a_cidr  = var.pub_sub_1a_cidr
  pub_sub_1b_cidr  = var.pub_sub_1b_cidr
  pvt_sub_1a_cidr = var.pvt_sub_1a_cidr
  pvt_sub_1b_cidr = var.pvt_sub_1b_cidr

  # sg rules
  public_sg_rules    = var.public_sg_rules
  private_sg_ingress = var.private_sg_ingress
  private_sg_egress  = var.private_sg_egress
}


module "compute" {
  # source = "./modules/compute"
  source = "git::https://github.com/Millstack/terraform-aws-compute.git?ref=v1.1.5"

  environment   = var.environment
  project_name  = var.project_name
  instance_type = var.instance_type
  public_key    = var.public_key

  # iam role and policies
  new_iam_role_policies = var.new_iam_role_policies
  existing_iam_role     = var.existing_iam_role

  # mapping subnet IDs
  pub_sub_1a_id  = module.vpc.pub_sub_1a_id
  pub_sub_1b_id  = module.vpc.pub_sub_1b_id
  pvt_sub_1a_id  = module.vpc.pvt_sub_1a_id
  pvt_sub_1b_id  = module.vpc.pvt_sub_1b_id

  # mapping sg IDs
  public_sg_id  = module.vpc.public_sg_id
  private_sg_id = module.vpc.private_sg_id

  # ec2 user data script variables
  app_s3_bucket       = var.app_s3_bucket
  app_artifact_name   = var.app_artifact_name
  api_s3_bucket       = var.api_s3_bucket
  api_artifact_name   = var.api_artifact_name
  api_artifact_folder = var.api_artifact_folder
}


module "alb" {
  # source = "./modules/alb"
  source = "git::https://github.com/Millstack/terraform-aws-alb.git?ref=v1.0.3"

  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.vpc.public_sg_id

  # now asg will handle the ec2s via target group arn, inside asg module
  # private_ec2_ids   = module.compute.private_ec2_ids # private ec2 IDs
  acm_certificate_arn_regional = var.acm_certificate_arn_regional
}

module "asg" {
  # source                    = "./modules/asg"
  source = "git::https://github.com/Millstack/terraform-aws-asg.git?ref=v1.0.0"

  environment               = var.environment
  project_name              = var.project_name
  private_subnet_ids        = module.vpc.private_subnet_ids
  private_sg_id             = module.vpc.private_sg_id
  target_group_arn          = module.alb.target_group_arn

  # sam ubuntu ami used for ec2 isntance provision
  ami_id                    = module.compute.ubuntu_ami_id
  instance_type             = var.instance_type
  key_name                  = module.compute.key_pair_name
  iam_instance_profile_name = module.compute.iam_profile_name

  # ec2 user data
  # user_data_script          = file("${path.module}/scripts/install_app.sh")
  # terraform's templatefile function allows to pass variables to script
  user_data_script          = templatefile("${path.module}/scripts/install_app.sh", {
                                api_s3_bucket       = var.api_s3_bucket
                                api_artifact_name   = var.api_artifact_name
                                api_artifact_folder = var.api_artifact_folder
                                app_s3_bucket       = var.app_s3_bucket
                                app_artifact_name   = var.app_artifact_name
                              })
  
  # asg scaling policy variables
  asg_min_size              = var.asg_min_size
  asg_max_size              = var.asg_max_size
  asg_desired_capacity      = var.asg_desired_capacity
  
  # asg target variables values
  asg_cpu_target            = var.asg_cpu_target
  asg_req_count_target      = var.asg_req_count_target

  # asg i/o req count based metric's resource lable variables
  alb_arn_suffix            = module.alb.alb_arn_suffix
  alb_tg_arn_suffix         = module.alb.alb_tg_arn_suffix

  # Explicit dependency to ensure ALB exists before ASG tries to link to it
  depends_on                = [module.alb] 
}


data "aws_s3_bucket" "existing_bucket" {
  bucket = var.existing_s3_bucket_name
}

module "cloudfront" {
  # source = "./modules/cloudfront"
  source = "git::https://github.com/Millstack/terraform-aws-cloudfront.git?ref=v1.0.0"

  environment                    = var.environment
  project_name                   = var.project_name
  s3_bucket_id                   = data.aws_s3_bucket.existing_bucket.id
  s3_bucket_regional_domain_name = data.aws_s3_bucket.existing_bucket.bucket_regional_domain_name
  acm_certificate_arn_regional   = var.acm_certificate_arn_global
  route53_hosted_zone_id         = var.route53_hosted_zone_id
  domain_name                    = var.domain_name # e.g. "millstack.in"
  subdomain_app                  = var.subdomain_app # e.g. "app.millstack.in"
  subdomain_api                  = var.subdomain_api # e.g. "api.millstack.in"
}

# Apply the OAC Policy to your manual bucket
resource "aws_s3_bucket_policy" "oac_policy" {
  bucket = data.aws_s3_bucket.existing_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadOnly"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${data.aws_s3_bucket.existing_bucket.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = module.cloudfront.cloudfront_arn
        }
      }
    }]
  })
}



# cloudwatch line graph

resource "aws_cloudwatch_dashboard" "cw_dashboard" {
  dashboard_name = "${var.environment}-${var.project_name}-cw-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/EC2", 
              "CPUUtilization", 
              "AutoScalingGroupName", 
              "${module.asg.asg_name}"]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ASG Average CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ApplicationELB", 
              "RequestCountPerTarget", 
              "TargetGroup", 
              "${module.alb.alb_tg_arn_suffix}"]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Requests Per Target"
        }
      }
    ]
  })
}


