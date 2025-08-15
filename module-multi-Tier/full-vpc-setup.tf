#Vpc Creation
resource "aws_vpc" "mahi" {
  cidr_block = "13.0.0.0/16"

  tags = {
    Name = "my-custom"
  }
}

#subnets creation
resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.mahi.id
  cidr_block        = "13.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.mahi.id
  cidr_block        = "13.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "public-2"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.mahi.id
  cidr_block        = "13.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-1"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.mahi.id
  cidr_block        = "13.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-2"
  }
}

resource "aws_subnet" "private-3" {
  vpc_id            = aws_vpc.mahi.id
  cidr_block        = "13.0.5.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-3"
  }
}

resource "aws_subnet" "private-4" {
  vpc_id            = aws_vpc.mahi.id
  cidr_block        = "13.0.6.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-4"
  }
}

#create IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mahi.id

  tags = {
    Name = "IGW-custom"
  }
}

#creating public route table
resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.mahi.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-RT"
  }
}

#subnet association
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public_RT.id
}

#create EIP
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP"
  }
}

# Nat gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-1.id

  tags = {
    Name = "gw NAT"
  }
}

#creating private RT and alllow NAT GW
resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.mahi.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-RT"
  }
}

#Associate private subnets to Private-RT
resource "aws_route_table_association" "b1" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "b2" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "b3" {
  subnet_id      = aws_subnet.private-3.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "b4" {
  subnet_id      = aws_subnet.private-4.id
  route_table_id = aws_route_table.private_RT.id
}

#Creating security group for common access
resource "aws_security_group" "common_sg" {
  vpc_id = aws_vpc.mahi.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "common-sg"
  }
}



