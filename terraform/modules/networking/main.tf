############################################
# Networking Module: VPC, Subnets, NAT, IGW
############################################

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "starttech_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "starttech-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.starttech_vpc.id

  tags = {
    Name = "starttech-igw"
  }
}

# ---------------- Public Subnets (ALB + NAT) ----------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.starttech_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "starttech-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/starttech-cluster"   = "shared"
  }
}

# ---------------- Private Subnets (EKS Workers + ElastiCache) ----------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.starttech_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "starttech-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/starttech-cluster"   = "shared"
  }
}

# ---------------- NAT Gateway (for private subnet egress) ----------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "starttech-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "starttech-nat" }

  depends_on = [aws_internet_gateway.this]
}

# ---------------- Route Tables ----------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.starttech_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "starttech-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.starttech_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = { Name = "starttech-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
