output "vpc_id" {
  description = "Project details"
  value = var.project_name
}

output "networking_details" {
  description = "Consolidated networking details"
  value = {
    vpc_id = module.vpc.vpc_id
    internet_gateway = module.vpc.igw_id
    
    public_subnets = [
      module.vpc.pub_sub_1a_id
    ]
    private_subnets = [
      module.vpc.pvt_sub_1a_id,
      module.vpc.pvt_sub_1b_id
    ]
    public_route_table = [
      module.vpc.public_rt_id
    ]
    private_route_tables = [
      module.vpc.private_rt_1a_id, 
      module.vpc.private_rt_1b_id
    ]
    public_sg_id  = module.vpc.public_sg_id
    private_sg_id = module.vpc.private_sg_id
    
    nat_elastic_ips = [
      module.vpc.eip_1a,
      module.vpc.eip_1b
    ]
    nat_gateways = [
      module.vpc.nat_gw_1a_id,
      module.vpc.nat_gw_1b_id
    ]
  }
}

  # public IPs of public EC2s

output "computing_details" {
  description = "Consolidated computing details"
  value = {
    iam_instance_profile = module.compute.iam_profile_name
    
    public_instance_ips = [
      # module.compute.ec2_pub_1a_ip,
      # module.compute.ec2_pub_1b_ip
    ]
    public_instance_ids = [
      # module.compute.ec2_pub_1a_id,
      # module.compute.ec2_pub_1b_id,
    ]

    # using ASG now, wont need static ec2 provioned IDs
    private_instance_ids = [
      # module.compute.ec2_pvt_1a_id,
      # module.compute.ec2_pvt_1b_id
    ]

    asg_name = module.asg.asg_name
    ami_used = module.compute.ubuntu_ami_id
  }
}
  

#======================================
# Load Balancer & API Endpoint
#======================================
output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "api_endpoint_base_url" {
  description = "The base URL for the Angular Frontend to hit the .NET API"
  value       = "http://${module.alb.alb_dns_name}"
}



#======================================
# Compute & Scaling Outputs
#======================================
# output "asg_name" {
#   description = "The name of the Auto Scaling Group"
#   value       = module.asg.asg_name
# }

# output "instance_iam_profile" {
#   description = "The IAM Instance Profile assigned to the EC2s"
#   value       = aws_iam_instance_profile.instance_profile.name
# }

#======================================
# CloudFront OAC
#======================================

output "cloudfront_s3_oac_policy_json" {
  description = "Copy this JSON into your S3 Bucket Policy if not using Terraform to manage the policy"
  value       = aws_s3_bucket_policy.oac_policy.policy
}

output "frontend_url" {
  description = "the frontend application url to be used by client"
  value = "https://${var.subdomain_app}"
}

