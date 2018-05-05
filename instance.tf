resource "aws_instance" "webserver" {
  ami             = "ami-43a15f3e"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["${aws_security_group.wp_public_sg.id}"]
  subnet_id       = "${aws_subnet.wp_public1_subnet.id}"
 user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
-EOF


  provisioner "local-exec" {
    command = "echo 'hisandy' > /var/www/html/index.html"
  }
 provisioner "local-exec" {
    command = "sudo service apache2 restart"
  }


  tags {
    Name = "webserver"
  }
}

resource "aws_instance" "appserver" {
  ami             = "ami-467ca739"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["${aws_security_group.wp_public_sg.id}"]
  subnet_id       = "${aws_subnet.wp_public2_subnet.id}"

  tags {
    Name = "appserver"
  }
}


