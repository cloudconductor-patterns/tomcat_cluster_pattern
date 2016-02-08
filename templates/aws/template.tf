resource "aws_eip" "lb_server_eip" {
  count = "${var.lb_server_size}"
  vpc = true
  instance = "${element(aws_instance.lb_server.*.id, count.index)}"
}

resource "aws_security_group" "lb_security_group" {
  name = "LbSecurityGroup"
  description = "Enable SSH access, HTTP access via port 80"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_ap_security_group" {
  name = "WebApSecurityGroup"
  description = "Enable AJP access via / JMX access"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.lb_security_group.id}"]
  }
  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    self = true
  }
  ingress {
    from_port = 9694
    to_port = 9694
    protocol = "tcp"
    self = true
  }
  ingress {
    from_port = 12345
    to_port = 12346
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group_rule" "allow_pgpool" {
    type = "ingress"
    from_port = 9999
    to_port = 9999
    protocol = "tcp"

    security_group_id = "${aws_security_group.web_ap_security_group.id}"
    source_security_group_id = "${aws_security_group.db_security_group.id}"
}

resource "aws_security_group" "db_security_group" {
  name = "DBSecurityGroup"
  description = "Enable DB access via port 5432"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.web_ap_security_group.id}"]
  }
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    self = true
  }
}

resource "aws_instance" "lb_server" {
  count = "${var.lb_server_size}"
  ami = "${var.lb_image}"
  instance_type = "${var.lb_instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.lb_security_group.id}", "${var.shared_security_group}"]
  subnet_id = "${element(split(", ", var.subnet_ids), count.index)}"
  associate_public_ip_address = true
  tags {
    Name = "LbServer"
  }
}

resource "aws_instance" "web_ap_server" {
  count = "${var.web_ap_server_size}"
  depends_on = ["aws_instance.lb_server"]
  ami = "${var.web_ap_image}"
  instance_type = "${var.web_ap_instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.web_ap_security_group.id}", "${var.shared_security_group.id}"]
  subnet_id = "${element(split(", ", var.subnet_ids), count.index)}"
  associate_public_ip_address = true
  tags {
    Name = "WebApServer"
  }
}

resource "aws_instance" "db_server" {
  count = "${var.db_server_size}"
  depends_on = ["aws_instance.lb_server"]
  ami = "${var.db_image}"
  instance_type = "${var.db_instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.db_security_group.id}", "${var.shared_security_group.id}"]
  subnet_id = "${element(split(", ", var.subnet_ids), count.index)}"
  associate_public_ip_address = true
  tags {
    Name = "DBServer"
  }
}

output "cluster_addresses" {
  value = "${join(", ", concat(aws_instance.lb_server.*.private_ip, aws_instance.web_ap_server.*.private_ip, aws_instance.db_server.*.private_ip))}"
}

output "consul_addresses" {
  value = "${join(", ", concat(aws_eip.lb_server_eip.*.public_ip, aws_instance.web_ap_server.*.public_ip, aws_instance.db_server.*.public_ip))}"
}

output "frontend_addresses" {
  value = "${aws_eip.lb_server_eip.0.public_ip}"
}
