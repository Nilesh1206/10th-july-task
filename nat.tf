provider "aws" {
     region = "ap-south-1"
     
 }

resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "aws-vpc"
  }
} 

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone= "ap-south-1a"
  map_public_ip_on_launch ="true"

  tags = {
    Name = "aws-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone= "ap-south-1b"

  tags = {
    Name = "aws-subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
   
   tags = {
      Name = "aws-internet-gw"
   }
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

resource "aws_route_table_association" "ng" {
    subnet_id      = aws_subnet.subnet1.id
    route_table_id = aws_route_table.route-table.id
 }

resource "aws_eip" "my_eip1" {
   vpc= true

depends_on        =[aws_internet_gateway.gw]
}


resource "aws_nat_gateway" "natgw"{
    depends_on=[aws_internet_gateway.gw]
    allocation_id =aws_eip.my_eip1.id
    subnet_id     =aws_subnet.subnet1.id

    tags ={
         Name ="natgw"
   }
 }

resource "aws_route_table" "nat_routing" {
    vpc_id =aws_vpc.myvpc.id

    route{
    cidr_block= "0.0.0.0/0"
    nat_gateway_id=aws_nat_gateway.natgw.id
    }
    tags={
  name="natroute"
}
    
}
   
resource "aws_route_table_association" "nat_sub2" {
    subnet_id      = aws_subnet.subnet2.id
    route_table_id = aws_route_table.nat_routing.id
 }









resource "aws_security_group" "public_sec"{
   name            = "public_sec"
   description     = " Allows SSH , HTTP "
   vpc_id          = aws_vpc.myvpc.id
 
   ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }
    
    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks =["0.0.0.0/0"]
        }
    
      tags ={
        Name = "public_sec"
   }
}

resource "aws_instance" "Wp-os" {
   ami          = "ami-7e257211"
   instance_type= "t2.micro"
   key_name     = "mykey1122"
  security_groups = [aws_security_group.public_sec.id]
   subnet_id    = aws_subnet.subnet1.id
   
      tags ={
          Name = "Wp-os"
     }
}
resource "aws_security_group" "private_sec"{
   name            = "private_sec"
   description     = " Allows sql"
   vpc_id          = aws_vpc.myvpc.id
 
   ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }
   ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }
     
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks =["0.0.0.0/0"]
        }
    
      tags ={
        Name = "private_sec"
   }
}


resource "aws_instance" "mysql-os" {
   ami          = "ami-08706cb5f68222d09"
   instance_type= "t2.micro"
   key_name     = "mykey1122"
   security_groups = ["${aws_security_group.private_sec.id}"]
   subnet_id    = aws_subnet.subnet2.id
   
      tags ={
          Name = "mysql-os"
     }
}

resource "aws_security_group" "bastionhost_sec"{
   name            = "bastionhost_sec"
   depends_on      = [aws_vpc.myvpc]
   vpc_id          = aws_vpc.myvpc.id
 
   ingress {
        description = "ssh"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks =["0.0.0.0/0"]
        }
     
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks =["0.0.0.0/0"]
        }
    
      tags ={
        Name = "bastion_sec"
   }
}

resource "aws_instance" "bastionhost" {
   ami          = "ami-0732b62d310b80e97"
   instance_type= "t2.micro"
   key_name     = "mykey1122"
   security_groups = ["${aws_security_group.bastionhost_sec.id}"]
   subnet_id    = aws_subnet.subnet1.id
   associate_public_ip_address="true"
   
      tags ={
          Name = "bastionhost"
     }
}


