terraform {
  required_version = ">= 1.10"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.206.0"
    }
  }
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket   = "momo-store-bucket"
    key      = "vm-docker/terraform.tfstate"
    region   = "ru-central1"

    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

}

provider "yandex" {
  service_account_key_file = "${path.module}/sa-key.json"
  zone      = var.zone_id
}

resource "yandex_compute_instance" "vm-cloud1" {
  name        = var.vm_name
  folder_id   = var.folder_id
  zone        = var.zone_id
  platform_id = var.platform_id
  allow_stopping_for_update = true

  resources {
    cores  = var.node_cores
    memory = var.node_memory
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.disk_size
    }
  }

  network_interface {
    subnet_id       = var.subnet_id
    nat             = var.nat_enable
  #  nat_ip_address  = var.nat_ip_address
  }

  metadata = {
    docker-container-declaration = file("${path.module}/declaration.yaml")
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      nexus_url          = var.nexus_url
      nexus_repo         = var.nexus_repo
      nexus_user         = var.nexus_user
      nexus_password     = var.nexus_password
      artifact_back      = var.artifact_back
      artifact_front     = var.artifact_front
      ssh_public_key     = var.ssh_public_key
      yc_key             = var.yc_key
      yc_cloud_id        = var.yc_cloud_id
      yc_folder_id       = var.yc_folder_id
      container_registry = var.container_registry
      release_tag        = var.release_tag

    })
  }

}
