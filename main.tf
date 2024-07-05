#Create VPC

resource "aws_vpc" "prod-vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
}

#Create IGW

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id
}

#Create public subnet for EC2
resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "192.168.0.0/18"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"
}

#Create private subnet for RDS

resource "aws_subnet" "prod-subnet-private-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "192.168.64.0/18"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "false"
}

#Create a second private subnet for RDS

resource "aws_subnet" "prod-subnet-private-2" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "192.168.128.0/18"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = "false"
}

#Create a route table 

resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }

}

# Associating route tabe to public subnet
resource "aws_route_table_association" "name" {
  subnet_id = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

#create a security group for the EC2 instance 

resource "aws_security_group" "ec2-allow-rules" {
  name        = "ec2-sg"
  description = "allow ssh,http,https"
  vpc_id      = aws_vpc.prod-vpc.id


  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  ingress {
    description = "http"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  ingress {
    description = "https"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  ingress {
    description = "MYSQL"
    from_port = 3306
    to_port = 3306
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow ssh, http,https"
  }
}

#Create a security group for RDS

resource "aws_security_group" "RDS-allow-rules" {
  name        = "RDS-sg"
  description = "allow MYSQL"
  vpc_id      = aws_vpc.prod-vpc.id


  ingress {
    description = "MYSQL"
    from_port = 3306
    to_port = 3306
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow MYSQL"
  }
}

#Create AWS subnet group

resource "aws_db_subnet_group" "RDS_subnet_grp" {
  subnet_ids = [aws_subnet.prod-subnet-private-1.id, aws_subnet.prod-subnet-private-2.id]
}

# Create the RDS instance

resource "aws_db_instance" "wordpressdb" {
  allocated_storage    = 10
  db_name              = "wordpress"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  vpc_security_group_ids = aws_db_subnet_group.RDS_subnet_grp.id
  username             = "wordpress"
  password             = "wordpress"
  skip_final_snapshot  = true
    
    lifecycle {
     ignore_changes = [password]
   }
}

# change USERDATA varible value after grabbing RDS endpoint info
data "template_file" "user_data" {
  template = file("${path.module}/userdata.tpl")
  vars = {
    db_username      = "wordpress"
    db_user_password = "wordpress"
    db_name          = "wordpress"
    db_RDS           = aws_db_instance.wordpressdb.endpoint
  }
}

resource "aws_instance" "wordpressec2" {
  ami = "ami-0195204d5dce06d99"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-allow-rules.id]
  key_name = aws_key_pair.ec2_key.name
  subnet_id = aws_subnet.prod-subnet-public-1.public
  user_data = data.template_file.user_data.rendered
    tags = {
    Name = "Wordpress.web"
  }
  root_block_device {
    volume_size = 10 # in GB 
  }

# this will stop creating EC2 before RDS is provisioned
  depends_on = [aws_db_instance.wordpressdb]

}