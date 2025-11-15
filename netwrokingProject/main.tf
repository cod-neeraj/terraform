provider "aws" {
  region = "us-east-1"
}

# -----------------------
# VPC
# -----------------------
resource "aws_vpc" "myVpc" {
  cidr_block = var.cidr_block
}

# -----------------------
# Public Subnet
# -----------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.myVpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# -----------------------
# Private Subnet
# -----------------------
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.myVpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# -----------------------
# Internet Gateway
# -----------------------
resource "aws_internet_gateway" "awsIG" {
  vpc_id = aws_vpc.myVpc.id
}

# -----------------------
# Public Route Table
# -----------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.myVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.awsIG.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# -----------------------
# NAT Gateway
# -----------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
}

# -----------------------
# Private Route Table
# -----------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.myVpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------------
# Security Group
# -----------------------
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myVpc.id

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
}

# -----------------------
# EC2 in Public Subnet
# -----------------------
resource "aws_instance" "webserver1" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.public.id
}

# -----------------------
# EC2 in Private Subnet
# -----------------------
resource "aws_instance" "webserver2" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.private.id
}
