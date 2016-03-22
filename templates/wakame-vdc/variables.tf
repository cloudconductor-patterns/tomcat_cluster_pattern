variable "global_network" {
  description = "Global Network ID to reach internet on Wakame-vdc"
  default = "nw-global"
}
variable "subnet_ids" {
  description = "Network ID which is created by common network pattern."
}
variable "shared_security_group" {
  description = "SecurityGroup ID which is created by common network pattern."
}
variable "key_name" {
  description = "Name of an existing KeyPair to enable SSH access to the instances."
}
variable "lb_image" {
  description = "[computed] LbServer Image Id. This parameter is automatically filled by CloudConductor."
}
variable "web_ap_image" {
  description = "[computed] WebApServer Image Id. This parameter is automatically filled by CloudConductor."
}
variable "db_image" {
  description = "[computed] DbServer Image Id. This parameter is automatically filled by CloudConductor."
}
variable "lb_cpu_cores" {
  description = "LbServer Cpu Cores"
  default = "1"
}
variable "lb_memory_size" {
  description = "LbServer Memory Size"
  default = "512"
}
variable "web_ap_cpu_cores" {
  description = "WebApServer Cpu Cores"
  default = "1"
}
variable "web_ap_memory_size" {
  description = "WebApServer Memory Size"
  default = "512"
}
variable "db_cpu_cores" {
  description = "DbServer Cpu Cores"
  default = "1"
}
variable "db_memory_size" {
  description = "DbServer Memory Size"
  default = "512"
}
variable "lb_server_size" {
  description = "LbServer instance size"
  default = "1"
}
variable "web_ap_server_size" {
  description = "WebApServer instance size"
  default = "1"
}
variable "db_server_size" {
  description = "DbServer instance size"
  default = "2"
}
