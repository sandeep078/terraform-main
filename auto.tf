#launch configuration

resource "aws_launch_configuration" "wp_lc" {
  name_prefix   = "wp_lc-"
  image_id      = "${aws_ami_from_instance.wp_golden.id}"
  instance_type = "t2.micro"

  security_groups = ["${aws_security_group.wp_sg.id}"]

  key_name                    = "terraform"
 # associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install apache2 python python-pip python-apt ansible -y

echo "done with epel release and now updating the system"
sudo apt update -y

echo "install java"
sudo apt-get install default-jdk -y

echo "installed java and adding the group tomcat"
sudo groupadd tomcat

echo "creating directory"
sudo mkdir -p /opt/tomcat

echo "creating user tomcat"
sudo useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat

cd ~
echo "downloading the zip file"
sudo wget http://mirror.stjschools.org/public/apache/tomcat/tomcat-8/v8.5.30/bin/apache-tomcat-8.5.30.tar.gz

echo "extracting it"
sudo tar -xzvf apache-tomcat-8.5.30.tar.gz

echo "moving the directory"
sudo mv apache-tomcat-8.5.30 /opt/tomcat/

echo "adding permisions to .sh files"
chmod 700 /opt/tomcat/apache-tomcat-8.5.30/bin/*.sh

echo "linking the startup for tomcat"
ln -s /opt/tomcat/apache-tomcat-8.5.30/bin/startup.sh /usr/bin/tomcatup
tomcatup

-EOF

  lifecycle {
    create_before_destroy = true
  }
}

#autoscaling

resource "aws_autoscaling_group" "wp_asg" {
  launch_configuration = "${aws_launch_configuration.wp_lc.name}"

  vpc_zone_identifier = ["${aws_subnet.wp_private1_subnet.id}",
    "${aws_subnet.wp_private2_subnet.id}",
  ]

  min_size          = 1
  max_size          = 4
  load_balancers    = ["${aws_elb.wp_elb.id}"]
  health_check_type = "EC2"

  tags {
    key                 = "Name"
    value               = "wp_asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "CpuPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.wp_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "monitor_cpu" {
  namespace           = "CPUwatch"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWSec2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wp_asg.name}"
  }

  alarm_name    = "cpuwatch-asg"
  alarm_actions = ["${aws_autoscaling_policy.cpu_policy.arn}"]
}

resource "aws_autoscaling_policy" "policy_down" {
  name                   = "downPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.wp_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "monitor_down" {
  namespace           = "downwatch"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWSec2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wp_asg.name}"
  }

  alarm_name    = "downwatch-asg"
  alarm_actions = ["${aws_autoscaling_policy.cpu_policy.arn}"]
}
