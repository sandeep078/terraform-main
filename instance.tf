resource "aws_instance" "webserver" {
  ami             = "ami-43a15f3e"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["${aws_security_group.wp_sg.id}"]
  subnet_id       = "${aws_subnet.wp_private1_subnet.id}"

  user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
-EOF

  tags {
    Name = "webserver"
  }
}

resource "aws_instance" "bastion" {
  ami             = "ami-43a15f3e"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["${aws_security_group.wp_sg.id}"]
  subnet_id       = "${aws_subnet.wp_public1_subnet.id}"


  tags {
    Name = "bastion"
  }
}
