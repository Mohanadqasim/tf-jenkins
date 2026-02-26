resource "aws_security_group" "tf_jenkins_sg" {
  name        = "tf-jenkins-sg"
  description = "Allow SSH and TCP 5000"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP 5000 from anywhere"
    from_port   = 5000
    to_port     = 5000
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
    Name = "tf-jenkins-sg"
  }
}

resource "aws_security_group" "tf_jenkins_jksg" {
  name        = "tf-jenkins-jksg"
  description = "Allow SSH and Jenkins UI"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access (restrict to your IP in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-jenkins-jksg"
  }
}

resource "tls_private_key" "tf_jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_jenkins_key" {
  key_name   = "tf-jenkins-key"
  public_key = tls_private_key.tf_jenkins_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.tf_jenkins_key.private_key_pem
  filename        = "${path.module}/tf-jenkins-key.pem"
  file_permission = "0400"
}

resource "tls_private_key" "tf_jenkins_jk_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_jenkins_jk_key" {
  key_name   = "tf-jenkins-jk-key"
  public_key = tls_private_key.tf_jenkins_jk_key.public_key_openssh
}

resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.tf_jenkins_jk_key.private_key_pem
  filename        = "${path.module}/tf-jenkins-jk-key.pem"
  file_permission = "0400"
}

resource "aws_iam_role" "tf_jenkins_ec2_role" {
  name = "tf-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.tf_jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "tf_jenkins_instance_profile" {
  name = "tf-jenkins-instance-profile"
  role = aws_iam_role.tf_jenkins_ec2_role.name
}

resource "aws_iam_role" "tf_jenkins_jk_role" {
  name = "tf-jenkins-jk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_full_access" {
  role       = aws_iam_role.tf_jenkins_jk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "tf_jenkins_jk_instance_profile" {
  name = "tf-jenkins-jk-instance-profile"
  role = aws_iam_role.tf_jenkins_jk_role.name
}

resource "aws_ecr_repository" "tf_jenkins_ecr" {
  name = "tf-jenkins-ecr"
  force_delete = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "tf-jenkins-ecr"
  }
}

resource "aws_instance" "tf_jenkins_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnet.default_subnet.id

  vpc_security_group_ids = [
    aws_security_group.tf_jenkins_sg.id
  ]

  key_name = aws_key_pair.tf_jenkins_key.key_name

  iam_instance_profile = aws_iam_instance_profile.tf_jenkins_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "tf-jenkins-ec2"
  }
}

resource "aws_instance" "tf_jenkins_jk_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"

  subnet_id = data.aws_subnet.default_subnet.id

  vpc_security_group_ids = [
    aws_security_group.tf_jenkins_jksg.id
  ]

  key_name = aws_key_pair.tf_jenkins_jk_key.key_name

  iam_instance_profile = aws_iam_instance_profile.tf_jenkins_jk_instance_profile.name

user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              # Install Java 17 (required for modern Jenkins)
              yum install -y java-17-amazon-corretto

              # Force Java 17 as default
              alternatives --set java /usr/lib/jvm/java-17-amazon-corretto.x86_64/bin/java

              # Install Jenkins
              wget -O /etc/yum.repos.d/jenkins.repo \
                https://pkg.jenkins.io/redhat-stable/jenkins.repo

              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              yum install -y jenkins

              systemctl daemon-reload
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "tf-jenkins-jk-ec2"
  }
}