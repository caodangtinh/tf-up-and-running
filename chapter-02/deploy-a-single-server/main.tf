provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "example" {
  ami                         = "ami-0fa377108253bf620"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.instance.id]
  user_data                   = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  user_data_replace_on_change = true
  tags = {
    "Name" = "terraform-example"
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

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

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
