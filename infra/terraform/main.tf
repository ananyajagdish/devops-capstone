resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "devops-vpc"
  }
}
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.devops_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.devops_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-b"
  }
}

resource "aws_security_group" "ssh_sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH Security Group"
  }
}

resource "aws_security_group" "http_sg" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.devops_vpc.id 

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from all IP addresses
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HTTP Security Group"
  }
}

resource "aws_security_group" "nodeport_sg" {
      name        = "kubernetes-nodeport-sg"
      description = "Security group for Kubernetes NodePort services"
      vpc_id      = aws_vpc.devops_vpc.id

      ingress {
        from_port   = 30000 # Start of the NodePort range
        to_port     = 32767 # End of the NodePort range (default Kubernetes range)
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allow access from anywhere (adjust as needed)
        description = "Allow NodePort traffic"
      }
      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }

      tags = {
        Name = "kubernetes-nodeport-sg"
      }
    }

resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id
  tags = {
    Name = "devops-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.devops_igw.id
}

resource "aws_route_table_association" "subnet_a_assoc" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet_b_assoc" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_instance" "jenkins" {
  ami                    = "ami-00ca32bbc84273381"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_a.id
  vpc_security_group_ids = [
    aws_security_group.http_sg.id,
    aws_security_group.ssh_sg.id
  ]
  key_name = "capstone"

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install java-11-amazon-corretto -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    sudo yum install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
  EOF

  tags = {
    Name = "jenkins-host"
  }
}

resource "aws_instance" "k8s_nodes" {
  count         = 2
  ami           = "ami-00ca32bbc84273381"
  instance_type = "t2.micro"
  subnet_id     = element([aws_subnet.subnet_a.id, aws_subnet.subnet_b.id], count.index)
  vpc_security_group_ids = [aws_security_group.nodeport_sg.id, aws_security_group.ssh_sg.id]
  tags = {
    Name = "k8s-node"
  }
}
