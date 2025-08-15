# Web tier EC2 Instances
resource "aws_instance" "webtier-1" {
  ami                         = "ami-0144277607031eca2"
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public-1.id
  vpc_security_group_ids      = [aws_security_group.common_sg.id]
  associate_public_ip_address = true
  user_data                   = file("userdata.sh")

  tags = {
    Name = "webtier-1"
  }
}

resource "aws_instance" "webtier-2" {
  ami                         = "ami-0144277607031eca2"
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public-2.id
  vpc_security_group_ids      = [aws_security_group.common_sg.id]
  associate_public_ip_address = true
  user_data                   = file("userdata1.sh")

  tags = {
    Name = "webtier-2"
  }
}


# Load Balancer
resource "aws_lb" "webtierlb" {
  name               = "webtier-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.common_sg.id]
  subnets = [
    aws_subnet.public-1.id,
    aws_subnet.public-2.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "webtier-lb"
  }
}

# Target Group
resource "aws_lb_target_group" "webtiertg" {
  name        = "webtier-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.mahi.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "webtier-tg"
  }
}

# Listener - attach Target Group to ALB
resource "aws_lb_listener" "webtier" {
  load_balancer_arn = aws_lb.webtierlb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtiertg.arn
  }
}

# Target Group Attachments - register instances with TG
resource "aws_lb_target_group_attachment" "webtier-1" {
  target_group_arn = aws_lb_target_group.webtiertg.arn
  target_id        = aws_instance.webtier-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webtier-2" {
  target_group_arn = aws_lb_target_group.webtiertg.arn
  target_id        = aws_instance.webtier-2.id
  port             = 80
}

#creating AMI
resource "aws_ami_from_instance" "terraform-ami" {
  name               = "terraform-ami"
  source_instance_id = aws_instance.webtier-1.id
}

resource "aws_launch_template" "webtier_lt" {
  name_prefix   = "webtier-launch-template-"
  image_id      = aws_ami_from_instance.terraform-ami.id
  instance_type = "t3.micro"
  key_name     = var.key_name

  network_interfaces {
    security_groups             = [aws_security_group.common_sg.id]
    associate_public_ip_address = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "webtier_asg" {
  launch_template {
    id      = aws_launch_template.webtier_lt.id
    version = "$Latest"
  }

  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [
    aws_subnet.public-1.id,
    aws_subnet.public-2.id
  ]
  target_group_arns = [aws_lb_target_group.webtiertg.arn]

  tag {
    key                 = "Name"
    value               = "webtier-asg-instance"
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
}

output "application_load_balancer_dns_name" {
  value = aws_lb.webtierlb.dns_name
}
