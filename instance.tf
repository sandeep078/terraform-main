resource "aws_instance" "webserver" {
  ami             = "ami-43a15f3e"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["${aws_security_group.wp_sg.id}"]
  subnet_id       = "${aws_subnet.wp_private1_subnet.id}"

  user_data = <<-EOF
#!/bin/bash


echo "done with epel release and now updating the system"
sudo apt update -y

echo "install java"
sudo apt-get install default-jdk apache2 python python-pip python-apt ansible -y

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


  tags {
    Name = "webserver"
  }
}
resource "aws_elb_attachment" "baz" {
  elb      = "${aws_elb.wp_elb.id}"
  instance = "${aws_instance.webserver.id}"
}



resource "aws_instance" "bastion" {
  ami             = "ami-43a15f3e"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["${aws_security_group.wp_sg.id}"]
  subnet_id       = "${aws_subnet.wp_public1_subnet.id}"
  user_data = <<-EOF
#!/bin/bash

echo "done with epel release and now updating the system"
sudo apt update -y

echo "install java"
sudo apt-get install default-jdk python python-pip python-apt ansible -y

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

  tags {
    Name = "bastion"
  }
}
