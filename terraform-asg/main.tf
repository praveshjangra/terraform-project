provider "aws" {
  region = "ap-south-1"
}

resource "aws_launch_template" "mylaunch" {
   name = "my_launch"
  # subnet_id = "subnet-c4729289"
   key_name = "test"
   instance_type = "t2.micro"
   image_id = "ami-0447a12f28fddb066"
   	network_interfaces  {
		security_groups = ["sg-00468d285e4398ddf"]
		delete_on_termination 		= true
		subnet_id = "subnet-c4729289"
		description = "Primary"
		device_index = 0
		associate_public_ip_address = true
	}
}

resource "aws_autoscaling_group" "myautos" {
    availability_zones = ["ap-south-1b","ap-south-1a"]
    desired_capacity   = 1
    max_size           = 2
    min_size           = 1

    launch_template  {
      id      = "${aws_launch_template.mylaunch.id}"
      version = "$Latest"
    }
}