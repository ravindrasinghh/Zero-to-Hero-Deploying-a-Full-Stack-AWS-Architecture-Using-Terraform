locals {
  ssm_policies = {
    "ssm_managed_instance_core" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "ssm_full_access"           = "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "ec2_role_for_ssm"          = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    "session_manager"           = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
  }
  target_subnet_id = { for k, s in aws_subnet.public : k => s.id if s.cidr_block == "10.0.1.0/24" }
}
