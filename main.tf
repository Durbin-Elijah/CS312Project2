terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "minecraft_server" {
   ami           = "ami-05f9478b4deb8d173"
   instance_type = "t3.small"
   subnet_id                   = aws_subnet.minecraft_subnet.id
   vpc_security_group_ids      = [aws_security_group.minecraft_sec.id]
   key_name                    = aws_key_pair.minecraft_key.key_name
   associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}

resource "null_resource" "configure_minecraft_with_ansible" {
  depends_on = [aws_instance.minecraft_server]

  triggers = {
    instance_id = aws_instance.minecraft_server.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i C:/Users/sirti/.ssh/minecraft_server \
      ec2-user@${aws_instance.minecraft_server.public_ip} exit; \
      do sleep 10; done
    EOT
    interpreter=["C:/Program Files/Git/bin/bash.exe", "-c"]
  }

  provisioner "local-exec" {
    command = <<-EOT
      ansible-playbook -i '${aws_instance.minecraft_server.public_ip},' \
      --user ec2-user \
      --private-key C:/Users/sirti/.ssh/minecraft_server \
      minecraft_playbook.yml
    EOT
    interpreter=["C:/Program Files/Git/bin/bash.exe", "-c"]
  }
}

resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft_server" # This is the name AWS will use for your key pair
  public_key = file("C:/Users/sirti/.ssh/minecraft_server.pub")
}

resource "aws_vpc" "minecraft_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "minecraft-vpc"
  }
}

resource "aws_subnet" "minecraft_subnet" {
  vpc_id     = aws_vpc.minecraft_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "minecraft-subnet"
  }
}

resource "aws_security_group" "minecraft_sec" {
  name        = "minecraft-security-group"
  description = "Allows minecraft traffic and SSH from my house"
  vpc_id      = aws_vpc.minecraft_vpc.id

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Minecraft Server"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["76.144.4.12/32"]
    description = "SSH Access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id
  tags = {
    Name = "minecraft-igw"
  }
}

resource "aws_route_table" "minecraft_route_table" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }
  tags = {
    Name = "minecraft-route-table"
  }
}

resource "aws_route_table_association" "minecraft_rt_association" {
  subnet_id      = aws_subnet.minecraft_subnet.id
  route_table_id = aws_route_table.minecraft_route_table.id
}