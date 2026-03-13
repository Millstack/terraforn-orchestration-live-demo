
# project identity
environment = "default"
project_name = "millstack-tf"
aws_region   = "ap-south-1"

# networking
vpc_cidr = "10.0.0.0/16"
pub_sub_1a_cidr = "10.0.1.0/24"
pub_sub_1b_cidr = "10.0.3.0/24"
pvt_sub_1a_cidr = "10.0.2.0/24"
pvt_sub_1b_cidr = "10.0.3.0/24"

# compute
instance_type = "t3.micro"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdXnmE9jyR8aaMRw8q6ESlosb049AQ63oh5KpgvHESUeZdXIqO73c0BOUF9FBW14dsLyNHiZjZ+ESJTrF1WYOkyPAxSjWhFMTXJ0VDL1RXzggpJAggY7fbpskh6GySZ3GphcK/76mKNutmxeUdOWFqGrAVOmYJ7/7RUroWAGSnJonQ0HDo97/P0F6lkcVgTOQsWHxFbY+3AwJdgIZm2KNL/q+n+XLzTXnW5x4b185T0j1hqwNIC5hKTaYY4V/EQT7+JnF9O0k2yx39MWx8zBiMoCxQFr39XG86gqq6E//A/I5wIB3E5T0whW6MGKRcwi830v9nv6AD443MO/GoDQLf"


# new iam role policies
new_iam_role_policies = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  # "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  # "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
]
# existing iam role name
existing_iam_role = "ec2-s3-role"

# Security Group Values
public_sg_rules = [
  { port = 22,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH" },
  { port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
  # { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" }
]

# Only allow specific internal traffic
private_sg_ingress = [
  { port = 80,   protocol = "tcp", description = "App traffic from Web" },
  { port = 3306, protocol = "tcp", description = "Aurora MySQL DB traffic" },
#   { port = 22,   protocol = "tcp", description = "SSH Bastion access" }
]
# Allow HTTPS for updates and DNS for name resolution
private_sg_egress = [
  { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS updates via NAT" },
  # { port = 53,  protocol = "udp", cidr_blocks = ["0.0.0.0/0"], description = "DNS via NAT" }
]
