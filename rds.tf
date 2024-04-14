data "aws_kms_key" "db_kms_key" {
  key_id = "alias/aws/rds"
}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.env}-rds-ssubnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "My DB Subnet Group in ${var.env}"
  }
}

resource "random_password" "root_password" {
  length      = 16
  special     = false
  min_numeric = 5
}

resource "aws_db_instance" "db" {
  depends_on              = [aws_db_subnet_group.rds_subnet_group]
  identifier              = "${var.env}-rds"
  allocated_storage       = var.rds_conf.allocated_storage
  storage_type            = var.rds_conf.storage_type
  engine                  = var.rds_conf.engine
  engine_version          = var.rds_conf.engine_version
  instance_class          = var.rds_conf.instance_class
  multi_az                = var.rds_conf.multi_az
  username                = var.rds_conf.username
  password                = aws_ssm_parameter.db_password.value
  storage_encrypted       = var.rds_conf.storage_encrypted
  kms_key_id              = var.rds_conf.storage_encrypted == true ? data.aws_kms_key.db_kms_key.arn : null
  vpc_security_group_ids  = ["${aws_security_group.rds_sg.id}"]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible     = var.rds_conf.publicly_accessible
  backup_retention_period = var.rds_conf.backup_retention_period
  skip_final_snapshot     = true
}

resource "aws_ssm_parameter" "db_password" {
  name   = "/rds/${var.env}-rds/password"
  value  = var.rds_conf.multi_az == true ? random_password.root_password.result : "test"
  type   = "SecureString"
  key_id = "alias/aws/ssm"
}
resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-rds-sg"
  description = "Security group for rds instances in the ASG"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.rds_sg_ingress_rules
    content {
      description     = format("Allow access for %s", ingress.key)
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = lookup(ingress.value, "protocol", "tcp")
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", [])
      security_groups = lookup(ingress.value, "security_groups", [])
    }
  }
  dynamic "egress" {
    for_each = var.rds_sg_egress_rules
    content {
      description     = format("Allow access for %s", egress.key)
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = lookup(egress.value, "protocol", "tcp")
      cidr_blocks     = lookup(egress.value, "cidr_blocks", [])
      security_groups = lookup(egress.value, "security_groups", [])
    }
  }

  tags = {
    Name = "${var.env}-EC2SecurityGroup"
  }
}
