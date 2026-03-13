
# project identity
environment = "dev"
project_name = "millstack-tf"
aws_region   = "ap-south-1"

# networking
vpc_cidr = "10.0.0.0/16"
pub_sub_1a_cidr = "10.0.1.0/24"
pub_sub_1b_cidr = "10.0.3.0/24"
pvt_sub_1a_cidr = "10.0.2.0/24"
pvt_sub_1b_cidr = "10.0.4.0/24"

# compute
instance_type = "t3.micro"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdXnmE9jyR8aaMRw8q6ESlosb049AQ63oh5KpgvHESUeZdXIqO73c0BOUF9FBW14dsLyNHiZjZ+ESJTrF1WYOkyPAxSjWhFMTXJ0VDL1RXzggpJAggY7fbpskh6GySZ3GphcK/76mKNutmxeUdOWFqGrAVOmYJ7/7RUroWAGSnJonQ0HDo97/P0F6lkcVgTOQsWHxFbY+3AwJdgIZm2KNL/q+n+XLzTXnW5x4b185T0j1hqwNIC5hKTaYY4V/EQT7+JnF9O0k2yx39MWx8zBiMoCxQFr39XG86gqq6E//A/I5wIB3E5T0whW6MGKRcwi830v9nv6AD443MO/GoDQLf"

# ec2 user data script variables
api_s3_bucket       = "millstack-aspnet-web-api"
api_artifact_name   = "Millstack_Published_v1.0.1.zip"
api_artifact_folder = "Millstack_Published_v1.0.1"

app_s3_bucket = "millstack-aspnet-web-api"
app_artifact_name = ".env"

# new iam role policies
new_iam_role_policies = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  # "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
]
# existing iam role name
existing_iam_role = ""



# Security Group Values
public_sg_rules = [
  { port = 22,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH" },
  { port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" }, # for ALB with http listener
  { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" } # for ALB DNS using subdomains
]

# Only allow specific internal traffic
private_sg_ingress = [
  { port = 80,   protocol = "tcp", description = "App traffic from Web" },
  { port = 3306, protocol = "tcp", description = "Aurora MySQL DB traffic" },
  { port = 7080, protocol = "tcp", description = ".Net Core Web API App" },
]
private_sg_egress = [
  { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS updates via NAT" },
  { port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP updates/mirrors" },
  { port = 53,  protocol = "udp", cidr_blocks = ["0.0.0.0/0"], description = "DNS (UDP)" },
  { port = 53,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "DNS (TCP)" },
  { port = 1433, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "External MS SQL Server DB" }
]

# domain & security (ACM & Route 53)
# for ALB
acm_certificate_arn_regional = "arn:aws:acm:ap-south-1:147602583479:certificate/fc9d9b4f-0479-4ce5-aef7-cffb032f2c49"
# for cloudfront
acm_certificate_arn_global = "arn:aws:acm:us-east-1:147602583479:certificate/fa570144-ddf1-4437-bba7-64aa63aa42f5"
route53_hosted_zone_id = "Z05130331IRA9BWWR4SNX"
domain_name = "millstack.in"
subdomain_app = "app.millstack.in"
subdomain_api = "api.millstack.in"


#==========================
# Auto Scaling Group
#==========================

asg_min_size = 2
asg_max_size = 4
asg_desired_capacity = 2

# asg scaling metric policy varaible values
asg_cpu_target = 70.0 # 70%
asg_req_count_target = 1000.0 # 1000 i/o request counts

# cloudfront and s3 bucket
existing_s3_bucket_name = "millstack-s3"


