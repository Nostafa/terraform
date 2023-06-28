# provider "aws" {
#   region = "eu-west-3a"
#   # access_key = "AKIAYRZFKQVL2LBWSQZ3"
#   # secret_key = "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"
# }
provider "aws" {
  region  = "eu-west-3"
}

# resource "aws_instance" "backend-server" {
#   ami = "ami-0c55b159cbfafe10"
#   instance_type = "t2.micro"
# }

variable "subnet_cidr_block" {
  description = "cidr block for subnet "
}

variable "vpc_cidr_block" {
  description = "cidr block for vpc"
}

resource "aws_vpc" "development-vpc"{
  cidr_block = var.vpc_cidr_block 
  tags = {
    Name: "development",
    vpc_env: "dev"
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "eu-west-3a"
  tags= {
    Name: "subnet-1-dev"
  }
}

data "aws_vpc" "existing_vpc"{
  default = true

}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-west-3a"
    tags= {
    Name: "subnet-2-default"
  }
} 