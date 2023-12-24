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

resource "aws_security_group" "gatekeeper_sg" {
  name        = "gatekeeper_security_group"
  description = "Allow web traffic to Gatekeeper"
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
    security_groups  = [aws_security_group.trusted_host_sg.id]
  }
}

resource "aws_security_group" "trusted_host_sg" {
  name        = "trusted_host_security_group"
  description = "Security group for Trusted Host"
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
    security_groups  = [aws_security_group.mysql_sg.id]

  }
}


resource "aws_instance" "mysql_server" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_server_user_data.sh")

  tags = {
    Name = "MySQL Server"
  }
}

resource "aws_instance" "mysql_cluster_manager" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_manager_user_data.sh")

  provisioner "file" {
    source      = "../scripts/ip_addresses.sh"
    destination = "/tmp/ip_addresses.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./my_terraform_key")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "MySQL Cluster Manager"
  }
}

resource "aws_instance" "mysql_cluster_worker" {
  count           = 3
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_worker_user_data.sh")

  provisioner "file" {
    source      = "../scripts/ip_addresses.sh"
    destination = "/tmp/ip_addresses.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./my_terraform_key")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "MySQL Cluster Worker ${count.index}"
  }
}

variable "private_key_path" {
  description = "Path to the SSH private key"
  type        = string
  default     = "./my_terraform_key"
}

resource "aws_instance" "mysql_proxy" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_proxy_user_data.sh")

  provisioner "file" {
    source      = "../scripts/ip_addresses.sh"
    destination = "/tmp/ip_addresses.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./my_terraform_key")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/ubuntu/my_terraform_key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "MySQL Proxy Server"
  }
}

resource "aws_instance" "gatekeeper" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.gatekeeper_sg.name]
  user_data       = file("./mysql_gatekeeper_user_data.sh")

  provisioner "file" {
    source      = "../scripts/ip_addresses.sh"
    destination = "/tmp/ip_addresses.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./my_terraform_key")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/ubuntu/my_terraform_key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "Gatekeeper Server"
  }
}

resource "aws_instance" "trusted_host" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.trusted_host_sg.name]
  user_data       = file("./mysql_trusted_host_user_data.sh")

  provisioner "file" {
    source      = "../scripts/ip_addresses.sh"
    destination = "/tmp/ip_addresses.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./my_terraform_key")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/ubuntu/my_terraform_key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "Trusted Host Server"
  }
}

# Output Public IP of MySQL Cluster Manager
output "mysql_cluster_manager_ip" {
  value = aws_instance.mysql_cluster_manager.public_ip
}

# Output Public IPs of MySQL Cluster Workers
output "mysql_cluster_worker_ips" {
  value = [for instance in aws_instance.mysql_cluster_worker : instance.public_ip]
}

# Output Public IP of MySQL Proxy Server
output "mysql_proxy_server_ip" {
  value = aws_instance.mysql_proxy.public_ip
}

# Output Public IP of Gatekeeper Server
output "gatekeeper_server_ip" {
  value = aws_instance.gatekeeper.public_ip
}

# Output Public IP of Trusted Host Server
output "trusted_host_server_ip" {
  value = aws_instance.trusted_host.public_ip
}

