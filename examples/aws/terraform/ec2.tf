data "aws_ami" "go" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["${var.aws_ami}"]
  }

}

resource "aws_key_pair" "go" {
  key_name   = "${var.aws_env}"
  public_key = "${tls_private_key.go.public_key_openssh}"
}

resource "aws_security_group" "allow_all" {
  name        = "go_allow_all"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "go-iam" {
  count = 1
  ami           = "${data.aws_ami.go.id}"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.go.name}"
  associate_public_ip_address = true
  key_name = "${aws_key_pair.go.key_name}"
  security_groups = ["${aws_security_group.allow_all.name}"]
  tags {
    env = "${var.aws_env}"
  }

  user_data = <<SCRIPT
#!/bin/bash
cat << EOF > /app/config.toml
[database]
host="${var.postgres_host}"
port="${var.postgres_port}"
name="${var.postgres_database}"
mount="database"
role="order"
[vault]
host="${var.vault_host}"
mount="aws-iam"
port="${var.vault_port}"
scheme="${var.vault_scheme}"
authentication="aws-iam"
role="order"
EOF
systemctl enable go.service
service go restart
SCRIPT

}

resource "aws_instance" "go-ec2" {
  count = 1
  ami           = "${data.aws_ami.go.id}"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.go.name}"
  associate_public_ip_address = true
  key_name = "${aws_key_pair.go.key_name}"
  security_groups = ["${aws_security_group.allow_all.name}"]

  tags {
    env = "${var.aws_env}"
  }

  user_data = <<SCRIPT
#!/bin/bash
cat << EOF > /app/config.toml
[database]
host="${var.postgres_host}"
port="${var.postgres_port}"
name="${var.postgres_database}"
mount="database"
role="order"
[vault]
host="${var.vault_host}"
mount="aws-ec2"
port="${var.vault_port}"
scheme="${var.vault_scheme}"
authentication="aws-ec2"
role="order"
EOF
systemctl enable go.service
service go restart
SCRIPT

}