provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fa377108253bf620"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default_subnets.ids
  target_group_arns    = [aws_lb_target_group.asg_target_group.arn]
  health_check_type    = "ELB"
  min_size             = 2
  max_size             = 10
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default_subnets.ids
  security_groups    = [aws_security_group.alb_security_group.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code  = "400"
    }
  }
}

resource "aws_security_group" "alb_security_group" {
  name = "terraform-example-alb"
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
}
resource "aws_lb_target_group" "asg_target_group" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "lb_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["/"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_target_group.arn
  }
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The DNS name of the load balancer"
}

# output "public_ip" {
#   value       = aws_instance.example.public_ip
#   description = "The public IP address of the web server"
# }

# variable "number_example" {
#   description = "An example of a number variable in Terraform"
#   type        = number
#   default     = 42
# }

# variable "list_example" {
#   description = "An example of a list variable in Terraform"
#   type        = list(any)
#   default     = ["a", "b", "c"]
# }

# variable "list_numeric_example" {
#   description = "An example of a numeric list variable in Terraform"
#   type        = list(number)
#   default     = [0, 1, 2]
# }

# variable "map_example" {
#   description = "An example of a map variable in Terraform"
#   type        = map(string)
#   default = {
#     "key1" = "value1"
#     "key2" = "value2"
#   }

# }
# variable "object_example" {
#   description = "An example of a structural variable in Terraform"
#   type = object({
#     name    = string
#     age     = number
#     tags    = list(string)
#     enabled = bool
#   })
#   default = {
#     name    = "John Doe"
#     age     = 42
#     tags    = ["a", "b", "c"]
#     enabled = "true"
#   }

# }
