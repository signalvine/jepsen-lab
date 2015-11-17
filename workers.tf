resource "aws_key_pair" "jepsen-ssh" {
  key_name = "jepsen-ssh"
  public_key = "${file("./control.pub")}"
}

resource "aws_security_group" "worker_server" {
  name = "jepsen_worker_server"
  description = "The security group for jepsen worker servers"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["${aws_subnet.main.cidr_block}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "worker" {
  count = 5
  ami = "ami-116d857a"
  instance_type = "c4.large"
  key_name = "${aws_key_pair.jepsen-ssh.key_name}"
  vpc_security_group_ids = ["${aws_security_group.worker_server.id}"]
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.main.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
    delete_on_termination = true
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    script = "./install-sysvinit.sh"

    connection {
      user = "admin"
      timeout = "5m"
      key_file = "control"
      agent = false
      host = "${self.private_ip}"

      bastion_host = "${aws_instance.control.public_ip}"
      bastion_user = "admin"
      bastion_key_file = "${var.private_key_path}"
    }
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    script = "./remove-systemd.sh"

    connection {
      user = "admin"
      timeout = "5m"
      key_file = "control"
      agent = false
      host = "${self.private_ip}"

      bastion_host = "${aws_instance.control.public_ip}"
      bastion_user = "admin"
      bastion_key_file = "${var.private_key_path}"
    }
  }
}

resource "template_file" "hosts" {
  depends_on = ["aws_instance.control"]
  filename = "hosts.tpl"
  count = 5

  vars {
    n1 = "${element(aws_instance.worker.*.private_ip, 0)}"
    n2 = "${element(aws_instance.worker.*.private_ip, 1)}"
    n3 = "${element(aws_instance.worker.*.private_ip, 2)}"
    n4 = "${element(aws_instance.worker.*.private_ip, 3)}"
    n5 = "${element(aws_instance.worker.*.private_ip, 4)}"
  }

  provisioner "remote-exec" {
    inline = ["echo '${self.rendered}' | sudo tee -a /etc/hosts",
              "sudo hostname n${count.index + 1}"]

    connection {
      user = "admin"
      timeout = "5m"
      key_file = "control"
      agent = false
      host = "${element(aws_instance.worker.*.private_ip, count.index)}"

      bastion_host = "${aws_instance.control.public_ip}"
      bastion_user = "admin"
      bastion_key_file = "${var.private_key_path}"
    }
  }
}

resource "null_resource" "control-hosts" {
  depends_on = ["aws_instance.control", "template_file.hosts"]

  provisioner "remote-exec" {
    inline = ["echo '${template_file.hosts.0.rendered}' | sudo tee -a /etc/hosts",
              "ssh-keyscan -t rsa n1 >> ~/.ssh/known_hosts",
              "ssh-keyscan -t rsa n2 >> ~/.ssh/known_hosts",
              "ssh-keyscan -t rsa n3 >> ~/.ssh/known_hosts",
              "ssh-keyscan -t rsa n4 >> ~/.ssh/known_hosts",
              "ssh-keyscan -t rsa n5 >> ~/.ssh/known_hosts"]

    connection {
      user = "admin"
      timeout = "1m"
      agent = false
      key_file = "${var.private_key_path}"
      host = "${aws_instance.control.public_ip}"
    }
  }
}
