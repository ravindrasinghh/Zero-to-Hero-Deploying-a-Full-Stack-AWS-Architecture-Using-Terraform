
#Auto Scaling Group and Launch Template with IAM Role
resource "aws_iam_role" "ssm_role" {
  name = "${var.env}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })

  tags = {
    Name = "${var.env}-SSMRole"
  }
}
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${var.env}-ec2-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_policies" {
  for_each   = local.ssm_policies
  role       = aws_iam_role.ssm_role.name
  policy_arn = each.value

  # Each key is used to create a unique name context for the resource
  # This helps in identifying the policy attached clearly in the Terraform state file.
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.env}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ssm_instance_profile.arn
  }
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = tolist(values(aws_subnet.private))[0].id
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-instance"
    }
  }
  lifecycle {
    create_before_destroy = true

  }
  update_default_version = true

}

data "template_file" "user_data" {
  template = file("templates/user_data.tpl")
  vars = {
    efs_file_system_id = aws_efs_file_system.app_efs.id
  }
}
resource "aws_lb" "app_alb" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(aws_subnet.public).*.id

  tags = {
    Name = "${var.env}-ApplicationLB"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.env}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = {
    Name = "${var.env}-TargetGroup"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # Update as needed
  certificate_arn   = aws_acm_certificate.example_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "${var.env}-alb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = aws_vpc.main.id
  dynamic "ingress" {
    for_each = var.alb_sg_ingress_rules
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
    for_each = var.alb_sg_egress_rules
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
    Name = "${var.env}-ALBSecurityGroup"
  }
}

resource "aws_autoscaling_group" "app_asg" {
  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  min_size            = 2
  max_size            = 3
  desired_capacity    = 3
  vpc_zone_identifier = values(aws_subnet.private).*.id
  health_check_type   = "ELB"
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  lifecycle {
    create_before_destroy = true
  }
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"


  tag {
    key                 = "Name"
    value               = "${var.env}-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.env}-ec2-sg"
  description = "Security group for EC2 instances in the ASG"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ec2_sg_ingress_rules
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
    for_each = var.ec2_sg_egress_rules
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

resource "aws_autoscaling_policy" "web_policy_up" {

  name                   = "web_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.app_asg.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_up.arn}"]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.app_asg.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_down.arn}"]
}
