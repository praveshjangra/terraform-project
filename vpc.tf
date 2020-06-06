data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "custome_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name  = "Custom VPC"
    Owner = "Pravesh Kumar"
  }
}

resource "aws_subnet" "custom_subnet_public" {
  count                   = var.env == "prod" ? 2 : 1
  vpc_id                  = aws_vpc.custome_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name  = "Public Subnet - ${count.index + 1}"
    Owner = "Pravesh Kumar"
  }
}
resource "aws_subnet" "custom_subnet_private" {
  count             = var.env == "prod" ? 2 : 1
  vpc_id            = aws_vpc.custome_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name  = "Private Subnet - ${count.index + 1}"
    Owner = "Pravesh Kumar"
  }
}

resource "aws_internet_gateway" "custom_gw" {
  vpc_id = aws_vpc.custome_vpc.id
  tags = {
    Name  = "Custom IG"
    Owner = "Pravesh Kumar"
  }
}

resource "aws_route_table" "custom_public_rt" {
  vpc_id = aws_vpc.custome_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_gw.id
  }
  tags = {
    Name = "Custom Public RT"
  }
}

resource "aws_route_table" "custom_private_rt" {
  vpc_id = aws_vpc.custome_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.custom_nat_gw.id
  }
  tags = {
    Name = "Custom private RT"
  }
}


resource "aws_route_table_association" "custom_private_associ" {
  count          = length(aws_subnet.custom_subnet_private)
  subnet_id      = aws_subnet.custom_subnet_private.*.id[count.index]
  route_table_id = aws_route_table.custom_private_rt.id
  depends_on     = [aws_route_table.custom_private_rt, aws_subnet.custom_subnet_private]
}

resource "aws_route_table_association" "custom_public_associ" {
  count          = length(aws_subnet.custom_subnet_public)
  subnet_id      = aws_subnet.custom_subnet_public.*.id[count.index]
  route_table_id = aws_route_table.custom_public_rt.id
  depends_on     = [aws_route_table.custom_public_rt, aws_subnet.custom_subnet_public]
}

resource "aws_security_group" "public_ssh" {
  name        = "ssh_access"
  description = "Public SSH access"
  vpc_id      = aws_vpc.custome_vpc.id
  ingress {
    from_port   = "22"
    protocol    = "tcp"
    to_port     = "22"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    protocol    = "-1"
    to_port     = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "jumpbox_ssh" {
  name        = "internal_ssh_access"
  description = "SSH access from jumpbox"
  vpc_id      = aws_vpc.custome_vpc.id
  ingress {
    from_port   = "22"
    protocol    = "tcp"
    to_port     = "22"
    cidr_blocks = [aws_vpc.custome_vpc.cidr_block]
  }
  egress {
    from_port   = "0"
    protocol    = "-1"
    to_port     = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = file(var.key_pair_path["public_key_path"])
}

resource "aws_instance" "custom_private_ec2" {
  count           = var.env == "prod" ? 2 : 1
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  subnet_id      = element(aws_subnet.custom_subnet_private.*.id,count.index)
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.jumpbox_ssh.id]
 tags = {
   Name = "Private EC2 - ${count.index+1}"    
}
}

resource "aws_instance" "custom_public_ec2" {
  count           = var.env == "prod" ? 2 : 1
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  subnet_id      = element(aws_subnet.custom_subnet_public.*.id,count.index)
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.public_ssh.id]
 tags = {
   Name = "Public EC2 - ${count.index+1}"    
}
}

resource "aws_eip" "custom_natip" {
  vpc = true
}
resource "aws_nat_gateway" "custom_nat_gw" {
  allocation_id = aws_eip.custom_natip.id
  subnet_id     = aws_subnet.custom_subnet_public.*.id[0]
  depends_on    = [aws_internet_gateway.custom_gw]
}

