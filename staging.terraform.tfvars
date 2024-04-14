# Basic Environment Settings
env = "staging"
vpc_conf = {
  cidr                 = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
}
region = "ap-south-1"

# Subnet Configurations - Specify CIDR blocks and map them to availability zones
public_subnets = {
  "ap-south-1a" = "10.0.1.0/24"
  "ap-south-1b" = "10.0.2.0/24"
}

private_subnets = {
  "ap-south-1a" = "10.0.3.0/24"
  "ap-south-1b" = "10.0.4.0/24"
}

# EC2 and AMI Configuration
instance_type = "t3a.medium"
ami_id        = "ami-09298640a92b2d12c" # Replace with a valid AMI ID for your region


#ALB

alb_sg_ingress_rules = {
  https = {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  },
  http = {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}
alb_sg_egress_rules = {
  all = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
ec2_sg_ingress_rules = {
  https = {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  },
  http = {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}
ec2_sg_egress_rules = {
  all = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
rds_conf = {
  instance_class          = "db.t3.xlarge"
  engine                  = "mysql"
  engine_version          = "8.0.35"
  allocated_storage       = 20
  storage_type            = "gp2"
  multi_az                = true
  username                = "admin"
  db_name                 = "mydb"
  storage_encrypted       = true
  publicly_accessible     = false
  backup_retention_period = 7
}
rds_sg_ingress_rules = {
  https = {
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }
}
rds_sg_egress_rules = {
  https = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
