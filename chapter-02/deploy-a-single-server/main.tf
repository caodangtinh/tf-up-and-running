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
  min_size             = 2
  max_size             = 10
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
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
