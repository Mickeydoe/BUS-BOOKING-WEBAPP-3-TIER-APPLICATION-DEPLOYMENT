#--------------------------------------------------
# Public ALB Security Group
#--------------------------------------------------
resource "aws_security_group" "public_alb" {
  name        = "${var.project_name}-public-alb-sg"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "${var.project_name}-public-alb-sg"
  }
}

#--------------------------------------------------
# Frontend EC2 Security Group
#--------------------------------------------------
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "Allow traffic only from the Public ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from Public ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}

#--------------------------------------------------
# Internal ALB Security Group
#--------------------------------------------------
resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-internal-alb-sg"
  description = "Allow traffic from Frontend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from Frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-internal-alb-sg"
  }
}

#--------------------------------------------------
# Backend EC2 Security Group
#--------------------------------------------------
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "Allow API traffic only from the Internal ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API traffic"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

#--------------------------------------------------
# Database Security Group
#--------------------------------------------------
resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg"
  description = "Allow PostgreSQL only from Backend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
  tags = {
    Name = "${var.project_name}-database-sg"
  }
}