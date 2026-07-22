#--------------------------------------------------
# Frontend Launch Template
#--------------------------------------------------

resource "aws_launch_template" "frontend" {

  name_prefix   = "${var.project_name}-frontend-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  key_name = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.frontend.id
  ]

  user_data = base64encode(templatefile("${path.module}/user_data/frontend.sh", {
    repository_url = var.repository_url
    backend_url    = aws_lb.internal.dns_name

  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-frontend"
    }
  }
}

#--------------------------------------------------
# Backend Launch Template
#--------------------------------------------------

resource "aws_launch_template" "backend" {

  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  key_name = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.backend.id
  ]

  user_data = base64encode(templatefile("${path.module}/user_data/backend.sh", {

    repository_url = var.repository_url

    db_host     = aws_db_instance.postgres.address
    db_name     = var.db_name
    db_username = var.db_username
    db_password = random_password.database.result

  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-backend"
    }
  }
}

#--------------------------------------------------
# Frontend Auto Scaling Group
#--------------------------------------------------
resource "aws_autoscaling_group" "frontend" {

  name = "${var.project_name}-frontend-asg"

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  vpc_zone_identifier = aws_subnet.public[*].id

  target_group_arns = [
    aws_lb_target_group.frontend.arn
  ]

  # launch_template {
  #   id      = aws_launch_template.frontend.id
  #   version = "$Latest"
  # }

  //To allow Terraform manage the template version explicitly:
  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }

    triggers = ["launch_template"]
  }

  //Added grace period to avoid premature health check failures during instance initialization
  health_check_grace_period = 300
  health_check_type         = "ELB"


  tag {
    key                 = "Name"
    value               = "${var.project_name}-frontend"
    propagate_at_launch = true
  }
}

#--------------------------------------------------
# Backend Auto Scaling Group
#--------------------------------------------------
resource "aws_autoscaling_group" "backend" {

  name = "${var.project_name}-backend-asg"

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  vpc_zone_identifier = aws_subnet.private_app[*].id

  target_group_arns = [
    aws_lb_target_group.backend.arn
  ]

  launch_template {
    id      = aws_launch_template.backend.id
    version = aws_launch_template.backend.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }

    triggers = ["launch_template"]
  }

  //Added grace period to avoid premature health check failures during instance initialization
  health_check_grace_period = 300
  health_check_type         = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }
}