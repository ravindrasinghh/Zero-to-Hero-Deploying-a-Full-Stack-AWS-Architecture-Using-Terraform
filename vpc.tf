#VPC and Subnet Configuration

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_conf.cidr
  instance_tenancy     = var.vpc_conf.instance_tenancy
  enable_dns_support   = var.vpc_conf.enable_dns_support
  enable_dns_hostnames = var.vpc_conf.enable_dns_hostnames
  tags = {
    Name = "${var.env}-vpc"
  }
}
resource "aws_eip" "nat" {
  for_each = var.public_subnets

  vpc = tobool(true)
}

resource "aws_nat_gateway" "nat" {
  for_each = aws_eip.nat

  allocation_id = each.value.id
  subnet_id     = values(local.target_subnet_id)[0]

  tags = {
    Name = "${var.env}-nat-gateway-${each.key}"
  }
}
resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = "${var.env}-private-route-table-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}



resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = each.key

  tags = {
    Name = "${var.env}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = each.key

  tags = {
    Name = "${var.env}-private-${each.key}"
  }
}
#Internet Gateway and Routing


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id


  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.env}-public-rtb"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
