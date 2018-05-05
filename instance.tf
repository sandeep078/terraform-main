resource "aws_instance" "webserver" {
  ami             = "ami-43a15f3e"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["defaultterraform"]

  tags {
    Name = "webserver"
  }
}

resource "aws_instance" "appserver" {
  ami             = "ami-467ca739"
  instance_type   = "t2.micro"
  key_name        = "terraform"
  security_groups = ["default-terraform"]

  tags {
    Name = "appserver"
  }
}
