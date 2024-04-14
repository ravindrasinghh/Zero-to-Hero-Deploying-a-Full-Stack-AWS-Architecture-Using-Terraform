resource "aws_efs_file_system" "app_efs" {
  creation_token = "appEFS"

  tags = {
    Name = "${var.env}-efs"
  }
}

resource "aws_efs_mount_target" "efs_mt" {
  for_each        = { for idx, subnet in aws_subnet.private : idx => subnet }
  file_system_id  = aws_efs_file_system.app_efs.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name        = "${var.env}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Allowing NFS traffic from instance SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
