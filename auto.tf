#launch configuration

resource "aws_launch_configuration" "wp_lc" {
  name_prefix    = "wp_lc-"
  image_id       = "${aws_ami_from_instance.wp_golden.id}"
  instance_type  = "t2.micro"
  security_groups = ["${aws_security_group.wp_private_sg.id}",
      "${aws_security_group.wp_public_sg.id}" 
]
  key_name       = "terraform"
  associate_public_ip_address = true
  user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
-EOF


  lifecycle {
    create_before_destroy = true
  }
}

#autoscaling

resource "aws_autoscaling_group" "wp_asg" {
  launch_configuration = "${aws_launch_configuration.wp_lc.name}"
 vpc_zone_identifier = ["${aws_subnet.wp_private1_subnet.id}",
    "${aws_subnet.wp_public2_subnet.id}"
  ]
  min_size                  = 1
  max_size                  = 4
  enabled_metrics = [“GroupMinSize”, “GroupMaxSize”, “GroupDesiredCapacity”, “GroupInServiceInstances”, “GroupTotalInstances”]
  metrics_granularity = ”1Minute”
  load_balancers            = ["${aws_elb.wp_elb.id}"]
  health_check_type         = "EC2"
tag {
    key                 = "Name"
    value               = "wp_asg-instance"
    propagate_at_launch = true
  }

}


resource "aws_autoscaling_policy" "cpu_policy" {

  name = "CpuPolicy"
  scaling_adjustment
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.wp_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "monitor_cpu" {
  namespace = "CPUwatch"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWSec2"
  period = "120"
  statistic = "Average"
  threshold = "50"
 dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wp_asg.name}"
  }

  alarm_name          = "cpuwatch-asg"
  alarm_actions = ["${aws_autoscaling_policy.cpu_policy.arn}"]

}

resource “aws_autoscaling_policy” “policy_down” {
name = “downPolicy”
scaling_adjustment = -1
adjustment_type = “ChangeInCapacity”
cooldown = 300
autoscaling_group_name = “${aws_autoscaling_group.wp_asg.name}”
}

resource “aws_cloudwatch_metric_alarm” “monitor-down” {
alarm_name = “downwatch”
comparison_operator = “LessThanOrEqualToThreshold”
evaluation_periods = “2”
metric_name = “CPUUtilization”
namespace = “AWSec2”
period = “120”
statistic = “Average”
threshold = “10”

dimensions {
AutoScalingGroupName = “${aws_autoscaling_group.wp_asg.name}”
}
alarm_name = "downwatch-asg"
alarm_description = “This metric monitor EC2 instance cpu utilization”
alarm_actions = [“${aws_autoscaling_policy.policy_down.arn}”]
}
}


