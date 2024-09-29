# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.project_name}-${var.env}-vpc"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# Subnet
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.project_name}-${var.env}-subnet-public-${var.region}a"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "protected_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name      = "${var.project_name}-${var.env}-subnet-protected-${var.region}a"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "${var.project_name}-${var.env}-public-route-table"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "protected_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name      = "${var.project_name}-${var.env}-protected-a-route-table"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project_name}-${var.env}-internet-gateway"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# EIP
resource "aws_eip" "nat_1a" {
  tags = {
    Name      = "${var.project_name}-${var.env}-eip-natgw-1a"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.nat_1a.id

  tags = {
    Name      = "${var.project_name}-${var.env}-nat-1a"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# ルートテーブルアソシエーション
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "protected_a" {
  subnet_id      = aws_subnet.protected_a.id
  route_table_id = aws_route_table.protected_a.id
}

# Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.env}-ecs-sg"
  description = "${var.project_name}-${var.env}-ecs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-${var.env}-alb-sg"
    Env       = var.env
    ManagedBy = "Terraform"
  }
}
