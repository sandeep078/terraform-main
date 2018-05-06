# ----- Golden ami ----

#random ami id

#resource "random_id" "golden_ami" {
#  byte_length = 3
#}

# ami

resource "aws_ami_from_instance" "wp_golden" {
  name               = "wp_ami-apache"
  source_instance_id = "${aws_instance.bastion.id}"
}
