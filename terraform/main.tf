terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    bucket = "pklawit-tfstate"
    key = "state/terraform.tfstate"
    region = "eu-west-3"
    encrypt = true
  }
}

provider "aws" {
  region = var.region #"eu-west-3"
}


resource "aws_vpc" "testvpc" {
  cidr_block = var.vpc_cidr #"192.168.1.0/24"
  enable_dns_support   = "true" #internal domain name
  enable_dns_hostnames = "true" #internal host name
  instance_tenancy = "default"
}

# Create public subnet for EC2 holding WordPress
resource "aws_subnet" "public-subnet1" {
  vpc_id = aws_vpc.testvpc.id
  cidr_block = var.subnet1_cidr
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone = var.availability_zone1 # "eu-west-3a"
}

# Create private subnet for RDS
resource "aws_subnet" "private-subnet1" {
  vpc_id = aws_vpc.testvpc.id
  cidr_block = var.subnet2_cidr
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone = var.availability_zone1
}

# Create 2nd private subnet for RDS
resource "aws_subnet" "private-subnet2" {
  vpc_id = aws_vpc.testvpc.id
  cidr_block = var.subnet3_cidr
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone = var.availability_zone2
}

# Create Internet Gateway
resource "aws_internet_gateway" "testgw" {
  vpc_id = aws_vpc.testvpc.id
}

# Create route table for the internet gateway
resource "aws_route_table" "testrt" {
  vpc_id = aws_vpc.testvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testgw.id
  }
}

# Associating route tabe to public subnet
resource "aws_route_table_association" "route-table-association-subnet-1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.testrt.id
}

# Security group for EC2 machine
resource "aws_security_group" "ec2-sg" {
  name = "ec2-sg"
  description = "allow inbound traffic for ports 80,22"
  vpc_id = aws_vpc.testvpc.id

  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "mysql"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ping"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for RDS instance
resource "aws_security_group" "rds-sg" {
  name = "rds-sg"
  description = "allow traffic from wordpress ec2 instance to mysql"
  vpc_id = aws_vpc.testvpc.id

  ingress {
    description = "mysql"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }

  # allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [ aws_security_group.ec2-sg ]
}

# Create RDS Subnet group
resource "aws_db_subnet_group" "RDS_subnetgrp" {
  subnet_ids = ["${aws_subnet.private-subnet1.id}", "${aws_subnet.private-subnet2.id}"]
}

# Create RDS instance
resource "aws_db_instance" "wordpress-db" {
  allocated_storage = 10
  engine = "mysql"
  engine_version = "5.7"
  instance_class = var.db_instance_class
  db_subnet_group_name = aws_db_subnet_group.RDS_subnetgrp.id
  vpc_security_group_ids = ["${aws_security_group.rds-sg.id}"]
  db_name = var.database_name
  username = var.database_user
  password = var.database_password
  skip_final_snapshot = true

 # make sure rds manual password changes are ignored
  lifecycle {
     ignore_changes = [password]
   }
}

# change USERDATA variables value after grabbing RDS endpoint info
data "template_file" "user_data" {
  template = file("${path.module}/ec2_userdata.tpl")
  vars = {
    db_username = var.database_user
    db_user_password = var.database_password
    db_name = var.database_name
    db_RDS = aws_db_instance.wordpress-db.endpoint
  }
}


# Create EC2 (once RDS is provisioned)
resource "aws_instance" "wordpress-ec2" {
  ami = var.ec2_image_id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.public-subnet1.id
  vpc_security_group_ids = ["${aws_security_group.ec2-sg.id}"]
  user_data = data.template_file.user_data.rendered
  key_name = aws_key_pair.mykey-pair.id
  tags = {
    Name = "Wordpress.web"
  }

  root_block_device {
    volume_size = var.root_volume_size # in GB 
  }

  # this will stop creating EC2 before RDS is provisioned
  depends_on = [aws_db_instance.wordpress-db]
}

// Sends your public key to the instance
resource "aws_key_pair" "mykey-pair" {
  key_name   = "mykey-pair"
  public_key = file(var.PUBLIC_KEY_PATH)
}

# creating Elastic IP for EC2
resource "aws_eip" "eip" {
  instance = aws_instance.wordpress-ec2.id
}

output "IP" {
  value = aws_eip.eip.public_ip
}
output "RDS-Endpoint" {
  value = aws_db_instance.wordpress-db.endpoint
}

output "INFO" {
  value = "Deployment completed. Go to http://${aws_eip.eip.public_ip}"
}
