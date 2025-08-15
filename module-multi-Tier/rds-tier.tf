resource "aws_db_subnet_group" "DBsubnet" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private-3.id, aws_subnet.private-4.id]

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_security_group" "mysql" {
  name        = "rds-mysql"
  description = "Allow MySQL access"
  vpc_id      = aws_vpc.mahi.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["13.0.0.0/16"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysqlDB" {
  allocated_storage      = 100
  db_name                = "DBtier"
  engine                 = "mysql"
  engine_version         = "8.0.42"
  multi_az               = true
  instance_class         = "db.t3.micro"
  username               = "mahesh"
  password               = var.password
  port                   = 3306
  db_subnet_group_name   = aws_db_subnet_group.DBsubnet.name
  vpc_security_group_ids = [aws_security_group.mysql.id]
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
}

