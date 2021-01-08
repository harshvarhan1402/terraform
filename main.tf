provider "aws" {
  version = "~> 2.0"
  region     = "us-east-1"
  access_key = "AKIAUMK5PR7EIB5QO6X7"
  secret_key = "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"
}
# resource "aws_instance" "my_first_tf_server" {
#   ami = "ami-0a0ddd875a1ea2c7f"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "My_Instance_tf"
#   }
# }
#### CREATING VPC ########
resource "aws_vpc" "my-tf-vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "my-tf-vpc"
  }
}
###### CREATING INTERNET GATEWAY ########
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my-tf-vpc.id
  tags = {
    Name = "my-tf-ig"
  }
}
####### CREATING ROUTE TABLE ##########
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.my-tf-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "my-tf-rt"
  }
}
######### CREATING SUBNET ##########
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.my-tf-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tf-subnet"
  }
}
######## ASSOCIATE WITH ROUTE TABLE ######
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.r.id
}

####### SECURITY GROUP #######
resource "aws_security_group" "allow_tls" {
  name        = "allow_web_traffic"
  description = "Allow wev inbound traffic"
  vpc_id      = aws_vpc.my-tf-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
###### CREATING NETWORK INTERFACE #########
resource "aws_network_interface" "web" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]
}
####### ELASTIC IP########
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
######## CREATE INSTANCE #######
resource "aws_instance" "my_first_tf_server" {
  ami = "ami-0a0ddd875a1ea2c7f"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "drillers"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web.id
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install nginx -y
              sudo bash -c 'echo MY FIRST TF SERVER ON NEW VPC > /var/www/html/index.nginx-debian.html'
              sudo service nginx restart
              sudo apt install docker.io -y
              sudo docker pull ubuntu
              EOF
  tags = {
    Name = "My_Instance_tf"
  }
}
