resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.vpc_name })
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => { cidr = cidr, az = var.availability_zones[idx] } }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.vpc_name}-public-${each.key}" })
}

# Private subnets
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets : idx => { cidr = cidr, az = var.availability_zones[idx] } }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = merge(var.tags, { Name = "${var.vpc_name}-private-${each.key}" })
}

# IGW для публічних
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.vpc_name}-igw" })
}

# Elastic IP для NAT
resource "aws_eip" "nat" {
  vpc  = true
  tags = merge(var.tags, { Name = "${var.vpc_name}-nat-eip" })
}

# Один NAT шлюз у першій публічній підмережі
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id # public-0
  tags          = merge(var.tags, { Name = "${var.vpc_name}-nat" })
  depends_on    = [aws_internet_gateway.igw]
}
