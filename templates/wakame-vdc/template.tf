resource "wakamevdc_security_group" "lb_security_group" {
  display_name = "LbSecurityGroup"
  description = "Enable SSH access, HTTP access via port 80"
  rules = "tcp:80,80,ip4:0.0.0.0\ntcp:443,443,ip4:0.0.0.0"
}

resource "wakamevdc_security_group" "web_ap_security_group" {
  display_name = "WebApSecurityGroup"
  description = "Enable AJP access / JMX access"
  rules = "tcp:80,80,${wakamevdc_security_group.lb_security_group.id}\ntcp:12345,12345,ip4:10.0.0.0/16\ntcp:12346,12346,ip4:10.0.0.0/16\ntcp:9999,9999,${var.shared_security_group}"
}

resource "wakamevdc_security_group" "web_ap_self_security_group" {
  display_name = "WebApSelfSecurityGroup"
  description = "Enable AJP access"
  rules = "tcp:9000,9000,${wakamevdc_security_group.web_ap_security_group.id}\ntcp:9694,9694,${wakamevdc_security_group.web_ap_security_group.id}"
}

resource "wakamevdc_security_group" "db_security_group" {
  display_name = "DbSecurityGroup"
  description = "Enable DB access via port 5432"
  rules = "tcp:5432,5432,${wakamevdc_security_group.web_ap_security_group.id}"
}

resource "wakamevdc_security_group" "db_self_security_group" {
  display_name = "DbSelfSecurityGroup"
  description = "Enable DB access via port 5432"
  rules = "tcp:5432,5432,${wakamevdc_security_group.db_security_group.id}"
}

resource "wakamevdc_instance" "lb_server" {
  count = "${var.lb_server_size}"
  display_name = "LbServer"
  cpu_cores = "${var.lb_cpu_cores}"
  memory_size = "${var.lb_memory_size}"
  image_id = "${var.lb_image}"
  hypervisor = "kvm"
  ssh_key_id = "${var.wakame_key_id}"

  vif {
    network_id = "${var.global_network}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.lb_security_group.id}"
    ]
  }
  vif {
    network_id = "${element(split(", ", var.subnet_ids), count.index)}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.lb_security_group.id}"
    ]
  }
}

resource "wakamevdc_instance" "web_ap_server" {
  count = "${var.web_ap_server_size}"
  depends_on = ["wakamevdc_instance.lb_server"]
  display_name = "WebApServer"
  cpu_cores = "${var.web_ap_cpu_cores}"
  memory_size = "${var.web_ap_memory_size}"
  image_id = "${var.web_ap_image}"
  hypervisor = "kvm"
  ssh_key_id = "${var.wakame_key_id}"

  vif {
    network_id = "${var.global_network}"
    security_groups = [
      "${var.shared_security_group}"
    ]
  }
  vif {
    network_id = "${element(split(", ", var.subnet_ids), count.index)}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.web_ap_security_group.id}",
      "${wakamevdc_security_group.web_ap_self_security_group.id}"
    ]
  }
}

resource "wakamevdc_instance" "db_server" {
  count = "${var.db_server_size}"
  depends_on = ["wakamevdc_instance.lb_server"]
  display_name = "DbServer"
  cpu_cores = "${var.db_cpu_cores}"
  memory_size = "${var.db_memory_size}"
  image_id = "${var.db_image}"
  hypervisor = "kvm"
  ssh_key_id = "${var.wakame_key_id}"

  vif {
    network_id = "${var.global_network}"
    security_groups = [
      "${var.shared_security_group}"
    ]
  }
  vif {
    network_id = "${element(split(", ", var.subnet_ids), count.index)}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.db_security_group.id}",
      "${wakamevdc_security_group.db_self_security_group.id}"
    ]
  }
}

output "frontend_address" {
  value = "${wakamevdc_instance.lb_server.vif.0.ip_address}"
}

output "consul_addresses" {
  value = "${join(", ", concat(wakamevdc_instance.lb_server.*.vif.0.ip_address, wakamevdc_instance.web_ap_server.*.vif.0.ip_address, wakamevdc_instance.db_server.*.vif.0.ip_address))}"
}

output "cluster_addresses" {
  value = "${join(", ", concat(wakamevdc_instance.lb_server.*.vif.1.ip_address, wakamevdc_instance.web_ap_server.*.vif.1.ip_address, wakamevdc_instance.db_server.*.vif.1.ip_address))}"
}
