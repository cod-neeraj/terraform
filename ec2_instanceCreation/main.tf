provider "aws" {
    region = var.region
  
}

resource "aws_instance" "terrform" {
    ami = var.ami_id
    instance_type = var.ec2_type
  
}