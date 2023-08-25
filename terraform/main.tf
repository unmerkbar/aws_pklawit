terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"

}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_vpc" "testvpc" {
  cidr_block = "192.168.1.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "test-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.testvpc.id
  cidr_block = "192.168.1.0/25"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.testvpc.id
  cidr_block = "192.168.1.128/25"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "subnet2"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "testgw" {
  vpc_id = aws_vpc.testvpc.id

  tags = {
    Name = "test-gw"
  }
}

# route table for the internet gateway
resource "aws_route_table" "testrt" {
  vpc_id = aws_vpc.testvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testgw.id
  }

  tags = {
    Name = "test-rt"
  }
}

# Security group for Wordpress Instance
resource "aws_security_group" "wordpress-sg" {
  name = "wordpress-sg"
  description = "allow inbound traffic for ports 80,22"
  vpc_id = aws_vpc.testvpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
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

  tags = {
    Name = "wordpress-sg"
  }
}

# Security group for MySQL instance
resource "aws_security_group" "mysql-sg" {
  name = "mysql-sg"
  description = "allow traffic from wordpress instance to mysql"
  vpc_id = aws_vpc.testvpc.id

  ingress {
    description = "mysql"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.wordpress-sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [ aws_security_group.wordpress-sg ]

  tags = {
    Name = "mysql-sg"
  }
}

