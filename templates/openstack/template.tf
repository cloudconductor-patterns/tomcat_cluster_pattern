resource "openstack_compute_floatingip_v2" "main" {
  count = "${var.lb_server_size}"
  pool = "public"
}

resource "openstack_compute_secgroup_v2" "lb_security_group" {
  name = "LbSecurityGroup"
  description = "Enable SSH access, HTTP access via port 80"
  rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 443
    to_port = 443
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "web_ap_security_group" {
  name = "WebApSecurityGroup"
  description = "Enable AJP access via / JMX access"
  rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    from_group_id = "${openstack_compute_secgroup_v2.lb_security_group.id}"
  }
  rule {
    from_port = 9000
    to_port = 9000
    ip_protocol = "tcp"
    self = true
  }
  rule {
    from_port = 9694
    to_port = 9694
    ip_protocol = "tcp"
    self = true
  }
  rule {
    from_port = 12345
    to_port = 12346
    ip_protocol = "tcp"
    cidr = "10.0.0.0/16"
  }
  rule {
    from_port = 9999
    to_port = 9999
    ip_protocol = "tcp"
    from_group_id = "${var.shared_security_group}"
  }
}

resource "openstack_compute_secgroup_v2" "db_security_group" {
  name = "DbSecurityGroup"
  description = "Enable DB access via port 5432"
  rule {
    from_port = 5432
    to_port = 5432
    ip_protocol = "tcp"
    from_group_id = "${openstack_compute_secgroup_v2.web_ap_security_group.id}"
  }
  rule {
    from_port = 5432
    to_port = 5432
    ip_protocol = "tcp"
    self = true
  }
}

resource "openstack_compute_instance_v2" "lb_server" {
  count = "${var.lb_server_size}"
  name = "LbServer"
  image_id = "${var.lb_image}"
  flavor_name = "${var.lb_instance_type}"
  metadata {
    Role = "lb"
    Name = "LbServer"
  }
  key_pair = "${var.key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.lb_security_group.name}", "${var.shared_security_group}"]
  floating_ip = "${element(openstack_compute_floatingip_v2.main.*.address, count.index)}"
  network {
    uuid = "${element(split(", ", var.subnet_ids), count.index)}"
  }
}

resource "openstack_compute_instance_v2" "web_ap_server" {
  count = "${var.web_ap_server_size}"
  depends_on = ["openstack_compute_instance_v2.lb_server"]
  name = "ApServer"
  image_id = "${var.web_ap_image}"
  flavor_name = "${var.web_ap_instance_type}"
  metadata {
    Role = "web,ap"
    Name = "ApServer"
  }
  key_pair = "${var.key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.web_ap_security_group.name}", "${var.shared_security_group}"]
  network {
    uuid = "${element(split(", ", var.subnet_ids), count.index)}"
  }
}

resource "openstack_compute_instance_v2" "db_server" {
  count = "${var.db_server_size}"
  depends_on = ["openstack_compute_instance_v2.lb_server"]
  name = "DbServer"
  image_id = "${var.db_image}"
  flavor_name = "${var.db_instance_type}"
  metadata {
    Role = "db"
    Name = "DbServer"
  }
  key_pair = "${var.key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.db_security_group.name}", "${var.shared_security_group}"]
  network {
    uuid = "${element(split(", ", var.subnet_ids), count.index)}"
  }
}

output "cluster_addresses" {
  value = "${join(", ", concat(openstack_compute_instance_v2.lb_server.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.web_ap_server.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.db_server.*.network.0.fixed_ip_v4))}"
}

output "frontend_addresses" {
  value = "${join(", ", openstack_compute_floatingip_v2.main.*.address)}"
}
