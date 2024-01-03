provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0fa377108253bf620"
  instance_type = "t2.micro"
}
