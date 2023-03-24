#Create Launch Tamplate
resource "aws_launch_template" "aws-launch-template" { 
  name                   = "launch-template"
  image_id               = var.image-id
  instance_type          = var.instance-type
  vpc_security_group_ids = [aws_security_group.autoscaling-sg.id]
  lifecycle {
    create_before_destroy = true
  }
}

#Create Autoscaling Group
resource "aws_autoscaling_group" "web" {
  name                      = "autoscaling"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [var.priv-sub-A , var.priv-sub-B]
  load_balancers            = [var.load-balancer]
  launch_template {
    id = aws_launch_template.aws-launch-template.id
  }
}


#Create Autoscaling Policie up
resource "aws_autoscaling_policy" "atoscaling-policy-up" {
  name                   = "web-policy-up"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

#Crete Scale UP Alarm
resource "aws_cloudwatch_metric_alarm" "scale-up-alarm" {
  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.scale-up-period
  statistic           = "Average"
  threshold           = var.scale-up-threshold
  dimensions = {
    "autoscalinggroupname" = aws_autoscaling_group.web.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization up"
  alarm_actions     = [aws_autoscaling_policy.atoscaling-policy-up.arn]
}

#Create Autoscaling Policie down
resource "aws_autoscaling_policy" "atoscaling-policy-down" {
  name                   = "web-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "SimpleScaling"
}

#Crete Scale DOWN Alarm
resource "aws_cloudwatch_metric_alarm" "scale-down-alarm" {
  alarm_name          = "scale-down-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.scale-down-period
  statistic           = "Average"
  threshold           = var.scale-down-threshold
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization down"
  alarm_actions     = [aws_autoscaling_policy.atoscaling-policy-down.arn]
}


#Autoscaling SECURITY GROUP
resource "aws_security_group" "autoscaling-sg" {
  name        = "autoscaling-sg"
  vpc_id      = var.vpc
  description = "Allow http"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.lb-sg]
#    security_groups = [aws_security_group.lb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web server sg"
  }
}

resource "aws_security_group_rule" "example" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
  source_security_group_id = aws_security_group.autoscaling-sg.id
#   self =  [aws_security_group.test.id]
# security_group_id = data.terraform_remote_state.backend.outputs.sg-id
  security_group_id = var.db-sg
}



