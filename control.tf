variable "aws_ssh_key" {}
variable "private_key_path" {
  default = "~/.ssh/tower"
}

resource "aws_security_group" "control_server" {
  name = "jepsen_control_server"
  description = "The security group for the jepsen control server"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "control" {
  ami = "ami-116d857a"
  instance_type = "c4.xlarge"
  key_name = "${var.aws_ssh_key}"
  vpc_security_group_ids = ["${aws_security_group.control_server.id}"]
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.main.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
    delete_on_termination = true
  }

  # Hopefully getting around the connection refused as the instance is starting up
  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p ~/.ssh"]

    connection {
      user = "admin"
      timeout = "1m"
      agent = false
      key_file = "${var.private_key_path}"
    }
  }

  provisioner "file" {
    source = "./control"
    destination = "~/.ssh/id_rsa"

    connection {
      user = "admin"
      timeout = "5m"
      agent = false
      key_file = "${var.private_key_path}"
    }
  }

  provisioner "remote-exec" {
    script = "./control-setup.sh"

    connection {
      user = "admin"
      timeout = "1m"
      agent = false
      key_file = "${var.private_key_path}"
    }
  }
}

output "control-ip" {
  value = "${aws_instance.control.public_ip}"
}
