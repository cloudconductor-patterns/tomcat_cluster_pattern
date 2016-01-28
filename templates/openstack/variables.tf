variable "subnet_ids" {
  description = "Subnet ID which is created by common network pattern."
}
variable "shared_security_group" {
  description = "SecurityGroup ID which is created by common network pattern."
}
variable "key_name" {
  description = "Name of an existing EC2/OpenStack KeyPair to enable SSH access to the instances."
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
variable "lb_instance_type" {
  description = "LbServer instance type"
  default = "t2.small"
}
variable "web_ap_instance_type" {
  description = "WebApServer instance type"
  default = "t2.small"
}
variable "db_instance_type" {
  description = "DbServer instance type"
  default = "t2.small"
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
