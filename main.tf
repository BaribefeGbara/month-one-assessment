# ========================================
# TERRAFORM CONFIGURATION
# Terraform AWS Infrastructure for TechCorp
# ========================================

# Tell Terraform which cloud provider to use
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# ========================================
# DATA SOURCES
# ========================================

# Find the latest Amazon Linux 2 AMI (the operating system image)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ========================================
# VPC - Virtual Private Cloud
# ========================================

# Create the main VPC (your private network in AWS)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # IP range: 10.0.0.0 to 10.0.255.255
  enable_dns_hostnames = true          # Allows servers to have DNS names
  enable_dns_support   = true          # Allows DNS resolution

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ========================================
# INTERNET GATEWAY
# ========================================

# Create Internet Gateway (allows VPC to connect to internet)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ========================================
# SUBNETS
# ========================================

# Public Subnet 1 (can access internet directly)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]  # 10.0.1.0/24
  availability_zone       = var.availability_zones[0]   # us-east-1a
  map_public_ip_on_launch = true                        # Auto-assign public IPs

  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

# Public Subnet 2 (in different availability zone for redundancy)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[1]  # 10.0.2.0/24
  availability_zone       = var.availability_zones[1]   # us-east-1b
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

# Private Subnet 1 (cannot access internet directly, more secure)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[0]  # 10.0.3.0/24
  availability_zone = var.availability_zones[0]    # us-east-1a

  tags = {
    Name = "${var.project_name}-private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[1]  # 10.0.4.0/24
  availability_zone = var.availability_zones[1]    # us-east-1b

  tags = {
    Name = "${var.project_name}-private-subnet-2"
  }
}

# ========================================
# ELASTIC IPs FOR NAT GATEWAYS
# ========================================

# Elastic IP for NAT Gateway 1 (static public IP)
resource "aws_eip" "nat_1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip-1"
  }
}

# Elastic IP for NAT Gateway 2
resource "aws_eip" "nat_2" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip-2"
  }
}

# ========================================
# NAT GATEWAYS
# ========================================

# NAT Gateway 1 (allows private subnet to access internet for updates)
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.project_name}-nat-gateway-1"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway 2
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id

  tags = {
    Name = "${var.project_name}-nat-gateway-2"
  }

  depends_on = [aws_internet_gateway.main]
}

# ========================================
# ROUTE TABLES
# ========================================

# Public Route Table (routes traffic to internet gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # All internet traffic
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Private Route Table 1 (routes traffic to NAT gateway)
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"  # All internet traffic
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-1"
  }
}

# Private Route Table 2
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-2"
  }
}

# ========================================
# ROUTE TABLE ASSOCIATIONS
# ========================================

# Connect public subnets to public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Connect private subnets to private route tables
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

# ========================================
# SECURITY GROUPS (Firewalls)
# ========================================

# Bastion Security Group (only you can SSH in)
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# Web Security Group
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from bastion only
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL from web servers only
  ingress {
    description     = "PostgreSQL from web servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Allow SSH from bastion only
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}

# ========================================
# EC2 INSTANCES
# ========================================

# Bastion Host (jump server for SSH access)
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public_1.id

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Enable password authentication
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              systemctl restart sshd
              
              # Create admin user
              useradd -m admin
              echo "admin:BastionPass123!" | chpasswd
              usermod -aG wheel admin
              
              # Install useful tools
              yum install -y telnet nc htop
              
              echo "Bastion setup complete" > /tmp/setup_complete.txt
              EOF

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# Elastic IP for Bastion (static public IP)
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-bastion-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Web Server 1
resource "aws_instance" "web_1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.private_1.id

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = file("${path.module}/user_data/web_server_setup.sh")

  tags = {
    Name = "${var.project_name}-web-1"
  }
}

# Web Server 2
resource "aws_instance" "web_2" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.private_2.id

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = file("${path.module}/user_data/web_server_setup.sh")

  tags = {
    Name = "${var.project_name}-web-2"
  }
}

# Database Server
resource "aws_instance" "database" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.db_instance_type
  subnet_id     = aws_subnet.private_1.id

  vpc_security_group_ids = [aws_security_group.database.id]

  user_data = file("${path.module}/user_data/db_server_setup.sh")

  tags = {
    Name = "${var.project_name}-database"
  }
}

# ========================================
# APPLICATION LOAD BALANCER
# ========================================

# Target Group (defines where to send traffic)
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-web-tg"
  }
}

# Register web servers with target group
resource "aws_lb_target_group_attachment" "web_1" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

# Classic Load Balancer
resource "aws_elb" "web" {
  name               = "${var.project_name}-clb"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_groups    = [aws_security_group.web.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = {
    Name = "${var.project_name}-clb"
  }
}


