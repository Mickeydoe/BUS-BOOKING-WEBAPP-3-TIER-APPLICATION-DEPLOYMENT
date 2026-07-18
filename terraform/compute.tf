resource "random_password" "flask_secret" {
  length  = 32
  special = false
}

locals {
  application_user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    db_host          = aws_db_instance.postgres.address
    db_name          = var.db_name
    db_username      = var.db_username
    db_password      = random_password.database.result
    flask_secret_key = random_password.flask_secret.result

    app_py_b64        = filebase64("${path.module}/../app/app.py")
    requirements_b64  = filebase64("${path.module}/../app/requirements.txt")
    base_html_b64     = filebase64("${path.module}/../app/templates/base.html")
    index_html_b64    = filebase64("${path.module}/../app/templates/index.html")
    success_html_b64  = filebase64("${path.module}/../app/templates/success.html")
    bookings_html_b64 = filebase64("${path.module}/../app/templates/bookings.html")
    style_css_b64     = filebase64("${path.module}/../app/static/style.min.css")
  })
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # EC2 user data is limited to 16 KB before base64 encoding.
  # cloud-init on Amazon Linux can automatically decompress gzip user data.
  user_data = base64gzip(local.application_user_data)

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app.id]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-asg"

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 600

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }

    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_listener.http,
    aws_db_instance.postgres
  ]
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}