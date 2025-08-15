resource "aws_instance" "apptier-1" {
  ami                         = "ami-0144277607031eca2"
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.private-1.id
  vpc_security_group_ids      = [aws_security_group.common_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "apptier-1"
  }
}

resource "aws_instance" "apptier-2" {
  ami                         = "ami-0144277607031eca2"
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.private-2.id
  vpc_security_group_ids      = [aws_security_group.common_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "apptier-2"
  }
}

resource "aws_lb" "apptierlb" {
  name               = "apptier-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.common_sg.id]
  subnets            = [
    aws_subnet.private-1.id,
    aws_subnet.private-2.id
  ]
  enable_deletion_protection = false
  tags = {
    Name = "apptier-lb"
  }
}

resource "aws_lb_target_group" "apptiertg" {
  name        = "apptier-tg"
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
    Name = "apptier-tg"
  }
}

resource "aws_lb_listener" "apptier" {
  load_balancer_arn = aws_lb.apptierlb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apptiertg.arn
  }
}

resource "aws_lb_target_group_attachment" "apptier-1" {
  target_group_arn = aws_lb_target_group.apptiertg.arn
  target_id        = aws_instance.apptier-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "apptier-2" {
  target_group_arn = aws_lb_target_group.apptiertg.arn
  target_id        = aws_instance.apptier-2.id
  port             = 80
}

resource "aws_ami_from_instance" "terraform-ami1" {
  name               = "terraform-ami1"
  source_instance_id = aws_instance.apptier-1.id
}

resource "aws_launch_template" "apptier_lt" {
  name_prefix   = "apptier-launch-template-"
  image_id      = aws_ami_from_instance.terraform-ami1.id
  instance_type = "t3.micro"
  key_name     = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.common_sg.id]
    associate_public_ip_address = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "apptier_asg" {
  launch_template {
    id      = aws_launch_template.apptier_lt.id
    version = "$Latest"
  }

  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = [
    aws_subnet.private-1.id,
    aws_subnet.private-2.id
  ]
  target_group_arns         = [aws_lb_target_group.apptiertg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "apptier-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
