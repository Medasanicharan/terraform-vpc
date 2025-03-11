## VPC ##
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = var.instance_tenancy
  enable_dns_hostnames  = var.enable_dns_hostnames

  tags = merge (
    var.common_tags,
    var.vpc_tags,
    {
        Name = local.resource_name
    }
  )
}

## igw ##
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags =  merge (
        var.common_tags,
        var.igw_tags,
        {
            Name = "${local.resource_name}-igw"
        }
    )
}

## public subnet ##

resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone = local.az_names[count.index]

  tags = merge(
    var.common_tags,
    var.public_subnet_cidr_tags,
    {
    Name = "${var.project_name}-public-${local.az_names[count.index]}"
  }
  )
}


## private subnet ##

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
    var.common_tags,
    var.private_subnet_cidr_tags,
    {
    Name = "${var.project_name}-private-${local.az_names[count.index]}"
  }
  )
}


## database subnet ##

resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge (
    var.common_tags,
    var.database_subnet_cidr_tags,
    {
    Name = "${var.project_name}-database-${local.az_names[count.index]}"
  }
  )
}

## public route table ##

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge (
    var.common_tags,
    var.public_route_table_tags,
    {
    Name = "${var.project_name}-public-route-table"
  }
  )
}


## private route table ##

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge (
    var.common_tags,
    var.private_route_table_tags,
    {
    Name = "${var.project_name}-private-route-table"
  }
  )
}


## datbase route table ##

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge (
    var.common_tags,
    var.database_route_table_tags,
    {
    Name = "${var.project_name}-database-route-table"
  }
  )
}

## elastic Ip ##

resource "aws_eip" "nat" {
  domain   = "vpc"

tags = merge (
    var.common_tags,
    var.elastic_ip_tags,
    {
    Name = "${var.project_name}-elastic_ip"
  }
  )
}


## nat gateway ##

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge (
    var.common_tags,
    var.nat_gateway_tags,
    {
    Name = "${local.resource_name}-nat-gateway"
  }
  )
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}


## public route ##

resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}


## private route ##

resource "aws_route" "private_route" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

## database route ##

resource "aws_route" "database_route" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

## public subnet assoiation ##

resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

## private subnet assoiation ##

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

## database subnet assoiation ##

resource "aws_route_table_association" "database" {
    count = length(var.database_subnet_cidrs)
  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = aws_route_table.database.id
}


## database subnet group ##
 
 resource "aws_db_subnet_group" "default" {
  name       = "${local.resource_name}" # expense-dev
  subnet_ids = aws_subnet.database[*].id

  tags = merge (
    var.common_tags,
    var.db_subnet_group_tags,
    {
    Name = "${var.project_name}-db-subnet-group" # expense-dev-db-subnet-group
  }
  )
}


