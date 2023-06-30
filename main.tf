# provider "aws" {
#   region = "eu-west-3a"
#   access_key = "AKIAYRZFKQVL2ZDKB6T4"
#   secret_key = "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"
# }
provider "aws" {
  region  = "eu-west-3"
}

# resource "aws_instance" "backend-server" {
#   ami = "ami-0c55b159cbfafe10"
#   instance_type = "t2.micro"
# }

variable vpc_cidr_block {
  description = "cidr block for vpc"
}
variable subnet_cidr_block {
  description = "cidr block for subnet "
}
variable avail_zone{}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable my_public_key {}
variable my_public_key_location {}

resource "aws_vpc" "myapp-vpc"{
  cidr_block = var.vpc_cidr_block 
  tags = {
    Name: "${var.env_prefix}-vpc"  
    }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags= {
    Name: "${var.env_prefix}-subnet"
  }
}


resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-internet-gateway.id
  }
  tags = {
    Name = "${var.env_prefix}-route-table", 
  }
}


resource "aws_internet_gateway" "myapp-internet-gateway" {
  vpc_id = aws_vpc.myapp-vpc.id
tags = {
    Name = "${var.env_prefix}-internet-gateway", 
  }
}

resource "aws_route_table_association" "a-art-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-security-group" {
  name = "myapp-security-group"
  vpc_id = aws_vpc.myapp-vpc.id
  # we use ingress here to set roles for incoming requests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ var.my_ip ]
  }

    ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # we use agress here to set roles for outcoming requests
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    prefix_list_ids = [  ]
  }

  tags = {
    Name: "${var.env_prefix}-sg"
  }
}

# hte * is for anything after this word 
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  # owners = ["amazon"]
  owners = ["137112412989"]
  filter {
    name = "name"
    values = [ "al2023-ami-2023.*-kernel-6.1-x86_64" ]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}
# output "aws_ami_id_output" {
#   value = data.aws_ami.latest-amazon-linux-image.id
# }

resource "aws_key_pair" "ssh-key-pair" {
  key_name = "backend-key-pair"
  # public_key = var.my_public_key
public_key = file(var.my_public_key_location)
}

resource "aws_instance" "backend-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type =var.instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [ aws_security_group.myapp-security-group.id ]
  availability_zone = var.avail_zone

  user_data = file("start-server.sh")

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key-pair.key_name
  tags = {
    Name = "${var.env_prefix}-server"
    type = "backend server"
  }
} 