terraform {
  required_version = "~> 1.15"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.14.0"
    }
  }
}

provider "oci" {}

module "oke" {
  source = "../../"

  compartment_id = var.compartment_id
  name           = var.name

  kubernetes_version = var.kubernetes_version

  control_plane_type          = "public"
  control_plane_allowed_cidrs = var.control_plane_allowed_cidrs

  create_bastion = false

  node_data_volume_size_gb = var.node_data_volume_size_gb

  ssh_public_key = var.ssh_public_key
}
