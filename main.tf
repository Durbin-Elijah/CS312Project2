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

  provisioner "file" {
    source      = "setup_minecraft.sh"          # Path to your local script file
    destination = "/tmp/setup_minecraft.sh"     # Path where the script will be copied on the EC2 instance

    # Connection details for SSH. Terraform handles this natively.
    connection {
      type        = "ssh"
      user        = "ec2-user" # Default user for Amazon Linux AMIs
      private_key = file("C:/Users/sirti/.ssh/minecraft_server") # Path to your LOCAL private key
      host        = self.public_ip # The public IP of the newly created instance
      timeout     = "5m" # Increase timeout if provisioning takes a while
   }
  }
  
  provisioner "remote-exec" {
    # Commands to execute on the remote EC2 instance.
    # Make the script executable, then run it with sudo.
    inline = [
      "chmod +x /tmp/setup_minecraft.sh", # Make the copied script executable
      "sudo /tmp/setup_minecraft.sh",     # Execute the script as root
    ]

    # Connection details for SSH (same as above).
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/sirti/.ssh/minecraft_server")
      host        = self.public_ip
      timeout     = "10m" # Allow more time for script execution
    }
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