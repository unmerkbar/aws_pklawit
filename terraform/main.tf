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


