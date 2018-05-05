# ----- Golden ami ----

#random ami id

resource "random_id" "golden_ami" {
  byte_length = 3
}

# ami

resource "aws_ami_from_instance" "wp_golden" {
  name               = "wp_ami-${random_id.golden_ami.b64}"
  source_instance_id = "${aws_instance.webserver.id}"

  provisioner "local-exec" {
    command = "sudo apt update -y && sudo apt install apache2 -y"
  }
}
