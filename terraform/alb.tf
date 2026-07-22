#--------------------------------------------------
#Public ALB
#--------------------------------------------------
resource "aws_lb" "public" {
  name               = "${var.project_name}-public-alb"
  load_balancer_type = "application"
  internal           = false

  subnets = aws_subnet.public[*].id

  security_groups = [
    aws_security_group.public_alb.id
  ]

  tags = {
    Name = "${var.project_name}-public-alb"
  }
}

#--------------------------------------------------
# Internal ALB
#--------------------------------------------------
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  load_balancer_type = "application"
  internal           = true

  subnets = aws_subnet.private_app[*].id

  security_groups = [
    aws_security_group.internal_alb.id
  ]

  tags = {
    Name = "${var.project_name}-internal-alb"
  }
}
#--------------------------------------------------
# Frontend Target Group
#--------------------------------------------------
resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-frontend"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled  = true
    path     = "/"
    matcher  = "200"
    protocol = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-frontend"
  }
}
#--------------------------------------------------
# Backend Target Group
#--------------------------------------------------
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-backend"
  port        = 5000
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled  = true
    path     = "/health"
    matcher  = "200"
    protocol = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-backend"
  }
}
#--------------------------------------------------
# Public Listener
#--------------------------------------------------
resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
#--------------------------------------------------
# Internal Listener
#--------------------------------------------------
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.backend.arn
  }
}
