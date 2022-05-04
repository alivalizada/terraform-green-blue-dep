# 

resource "aws_security_group" "green-blue-sg" {
  name = "Dynamic G-B Security Group"

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0               # Means all ports
    to_port     = 0               # Means all ports
    protocol    = "-1"            # Means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic B-G Sec-group"
    Owner = "Ali Valizada"
  }
}
