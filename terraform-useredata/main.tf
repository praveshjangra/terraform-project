provider "aws" {
  region = "ap-south-1"
}

resource "aws_ebs_volume" "example" {
  availability_zone = "ap-south-1b"
  size              = 8

  tags = {
    Name = "HelloWorld"
  }
  lifecycle {
    prevent_destroy = false
  }
}



resource "aws_instance" "myinstance" {
  ami                         = "ami-0447a12f28fddb066"
  subnet_id                   = "subnet-c4729289"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  availability_zone           = "ap-south-1b"
  #user_data = "${data.template_file.mutate_files.rendered}"
  key_name = aws_key_pair.deployer.key_name
}

resource "aws_instance" "myinstance2" {
  ami                         = "ami-0447a12f28fddb066"
  subnet_id                   = "subnet-c4729289"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  availability_zone           = "ap-south-1b"
  user_data                   = "${data.template_file.mutate_files.rendered}"
  key_name                    = aws_key_pair.deployer.key_name
}

variable "INSTANCE_DEVICE_NAME" {
  default = "/dev/xvdh"
}

data "template_file" "mutate_files" {
  template = "${file("users.tpl")}"
  vars = {
    DEVICE    = var.INSTANCE_DEVICE_NAME
    master_ip = aws_instance.myinstance.private_ip
  }
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = var.INSTANCE_DEVICE_NAME
  volume_id   = "${aws_ebs_volume.example.id}"
  instance_id = "${aws_instance.myinstance.id}"
  provisioner "local-exec" {
    command = "sleep 30"
    when    = destroy
  }
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = file(var.key_pair_path["public_key_path"])
}

variable "key_pair_path" {
  type = map
  default = {
    public_key_path  = "/home/pjangra/.ssh/id_rsa.pub"
    private_key_path = "/home/pjangra/.ssh/id_rsa"
  }
}