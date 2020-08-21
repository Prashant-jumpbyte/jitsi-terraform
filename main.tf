provider "aws" {
    region = "us-east-2"
}

data "aws_route53_zone" "djmorris" {
    name         = "djmorris.net"
}

resource "aws_vpc" "meeting_vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "meeting_test_vpc"
  }
}

resource "aws_subnet" "meeting_test_subnet" {
  vpc_id     = aws_vpc.meeting_vpc.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "meeting test subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.meeting_vpc.id

  tags = {
    Name = "main internet gateway"
  }
}

resource "aws_route_table" "meeting_test_route" {
  vpc_id       = aws_vpc.meeting_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "meeting test route"
  }
}

resource "aws_route_table_association" "meeting_test_route_assoc" {
  subnet_id      = aws_subnet.meeting_test_subnet.id
  route_table_id = aws_route_table.meeting_test_route.id
}

resource "aws_security_group" "meeting_test_sg" {
  name        = "meeting_test_sg"
  vpc_id      = aws_vpc.meeting_vpc.id
  description = "single sg"

  tags = {
    Name = "meeting_test_sg"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["[home IP]/32"]
    description = "ssh to host"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "jitsi to host"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "jitsi redirect to host"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "jitsi https to host"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "jitsi https reg to host"
  }

  ingress {
    from_port   = 4443
    to_port     = 4443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "jitsi RTP to host"
  }

  ingress {
    from_port   = 10000
    to_port     = 10000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "jitsi RTP udp to host"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["[home-IP]/32"]
    description = "ping to host"
  }

  egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
        description = "to anywhere"
    }
}

resource "aws_route53_record" "meeting-test" {
    zone_id = data.aws_route53_zone.djmorris.id
    name    = "meeting-test.djmorris.net"
    type    = "A"
    ttl     = "300"
    records = [aws_instance.meeting-test.public_ip]
}

resource "aws_instance" "meeting-test" {
  ami                         = "ami-02182c548f827ac1d"
  instance_type               = "t3a.small"
  associate_public_ip_address = "true"
  private_ip                  = "10.1.1.7"
  vpc_security_group_ids      = [aws_security_group.meeting_test_sg.id]
  key_name                    = "awdj"
  subnet_id                   = aws_subnet.meeting_test_subnet.id

  tags   = {
    Name = "meeting_test"
  }
}

resource "null_resource" "deploy-hook" {
  depends_on = [aws_route53_record.meeting-test]
  provisioner "file" {
    source      = "scripts/jitsiup.sh"
    destination = "/tmp/jitsiup.sh"

    connection {
      host   = "meeting-test.djmorris.net"
      type   = "ssh"
      user   = "centos"
      agent  = "true"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /tmp/jitsiup.sh |& tee -a /tmp/out.txt",
      "cd /home/centos/docker-jitsi-meet",
      "sudo docker-compose up -d",
    ]

    connection {
      host   = "meeting-test.djmorris.net"
      type   = "ssh"
      user   = "centos"
      agent  = "true"
    }
  }

}

output "public_ip" {
  value = aws_instance.meeting-test.public_ip
}
