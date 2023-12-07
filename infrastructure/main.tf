terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.19.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_ACCESS_KEY
  token      = var.AWS_SESSION_TOKEN
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "key_pair_name" {
  key_name   = var.key_pair_name
  public_key = file("my_terraform_key.pub")
}


resource "aws_security_group" "mysql_sg" {
  name        = "mysql_security_group"
  description = "Allow MySQL traffic"
  vpc_id      = data.aws_vpc.default.id


  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "mysql_server" {
  ami             = "ami-0230bd60aa48260c6"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_server_user_data.sh")

  tags = {
    Name = "MySQL Server"
  }
}

resource "aws_instance" "mysql_cluster_manager" {
  ami             = "ami-0230bd60aa48260c6"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_manager_user_data.sh")


  tags = {
    Name = "MySQL Cluster Manager"
  }
}

resource "aws_instance" "mysql_cluster_worker" {
  count           = 3
  ami             = "ami-0230bd60aa48260c6"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_worker_user_data.sh")

  tags = {
    Name = "MySQL Cluster Worker ${count.index}"
  }
}
