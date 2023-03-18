#Create Launch Tamplate
resource "aws_launch_template" "exo-aws_launch_template" {
  name                   = "wordpress-LT"
  description            = "lauch tamplate with terraform"
  image_id               = data.aws_ami.wordpress-image.image_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.terraform_remote_state.backend.outputs.autoscaling-id]
  lifecycle {
    create_before_destroy = true
  }
}
#image-data
data "aws_ami" "wordpress-image" {
  filter {
    name   = "name"
    values = ["exo-image"]
  }
}

#remote-state-data
data "terraform_remote_state" "backend" {
  backend = "s3"
  config  = {
    bucket = "tfstate-wordpress"
    key    = "main"
    region = "us-east-1"
  }

}

#Create Autoscaling Group
resource "aws_autoscaling_group" "web" {
  name                      = "exo-autoscaling"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [data.terraform_remote_state.backend.outputs.priv-sub-A , data.terraform_remote_state.backend.outputs.priv-sub-B]
  load_balancers            = [data.terraform_remote_state.backend.outputs.loadbalancer]
  launch_template {
    id = aws_launch_template.exo-aws_launch_template.id
  }
}


#Create Autoscaling Policie up
resource "aws_autoscaling_policy" "exo-atoscaling-policy-up" {
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
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  dimensions = {
    "autoscalinggroupname" = aws_autoscaling_group.web.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization up"
  alarm_actions     = [aws_autoscaling_policy.exo-atoscaling-policy-up.arn]
}

#Create Autoscaling Policie down
resource "aws_autoscaling_policy" "exo-atoscaling-policy-down" {
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
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization down"
  alarm_actions     = [aws_autoscaling_policy.exo-atoscaling-policy-down.arn]
}

