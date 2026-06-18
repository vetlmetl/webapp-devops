variable "folder_id" {
  type    = string
}

variable "subnet_id" {
  type    = string
}

#variable "nat_ip_address" {
#  type    = string
#}

variable "image_id" {
  type    = string
}

variable "platform_id" {
  type    = string
}

variable "zone_id" {
  type    = string
}

variable "vm_name" {
  type    = string
}

variable "disk_size" {
  type        = number
}

variable "node_cores" {
  type        = number
}

variable "node_memory" {
  type        = number
}

variable "nat_enable" {
  type        = bool
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "artifact_front" {
  type    = string
}

variable "artifact_back" {
  type    = string
}

variable "nexus_url" {
  type    = string
}

variable "nexus_repo" {
  type    = string
}

variable "nexus_user" {
  type      = string
  sensitive = true
  default   = "user"
}

variable "nexus_password" {
  type      = string
  sensitive = true
  default   = "password"
}

variable "yc_key" {
  type      = string
  sensitive = true
}

variable "yc_cloud_id" {
  type      = string
  sensitive = true
}

variable "yc_folder_id" {
  type      = string
  sensitive = true
}

variable "container_registry" {
  type      = string
}

variable "release_tag" {
  type      = string
}