# cluster.tf

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

data "oci_containerengine_node_pool_option" "this" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_id
}

data "http" "cloud_init" {
  count = var.cloud_init_url != null ? 1 : 0
  url   = var.cloud_init_url
}

locals {
  node_image_id = [
    for source in data.oci_containerengine_node_pool_option.this.sources :
    source.image_id
    if source.source_type == "IMAGE" &&
    can(regex("Oracle-Linux.*aarch64.*OKE-${trimprefix(var.kubernetes_version, "v")}", source.source_name))
  ][0]

  cloud_init_script = (
    var.cloud_init_local != null ? var.cloud_init_local :
    var.cloud_init_url != null ? data.http.cloud_init[0].response_body :
    file("${path.module}/cloud-init.sh")
  )
}

data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = oci_containerengine_cluster.this.id
}

# re-read after create completes - endpoints[0].kubernetes on the resource itself
# can still be "" right after creation while OCI finishes provisioning the endpoint
data "oci_containerengine_cluster" "refreshed" {
  cluster_id = oci_containerengine_cluster.this.id
  depends_on = [oci_containerengine_cluster.this]
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.name
  vcn_id             = oci_core_vcn.this.id

  dynamic "cluster_pod_network_options" {
    for_each = var.install_flannel ? [1] : []
    content {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  endpoint_config {
    is_public_ip_enabled = var.control_plane_type == "public"
    subnet_id            = oci_core_subnet.endpoint.id
  }

  options {
    service_lb_subnet_ids = []
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
  }

  freeform_tags = var.freeform_tags
}

resource "oci_containerengine_node_pool" "this" {
  compartment_id     = var.compartment_id
  cluster_id         = oci_containerengine_cluster.this.id
  kubernetes_version = var.kubernetes_version
  name               = "${var.name}-pool"

  node_config_details {
    size = var.node_count

    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.this.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = oci_core_subnet.nodes.id
      }
    }

    freeform_tags = var.freeform_tags
  }

  node_shape = "VM.Standard.A1.Flex"

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gb
  }

  node_source_details {
    image_id                = local.node_image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.node_boot_volume_size_gb
  }

  node_metadata = {
    user_data = base64encode(local.cloud_init_script)
  }

  ssh_public_key = var.ssh_public_key

  freeform_tags = var.freeform_tags
}

# re-read after create completes - nodes[].id on the resource itself can still
# be empty right after creation while OCI finishes provisioning the instances
data "oci_containerengine_node_pool" "refreshed" {
  node_pool_id = oci_containerengine_node_pool.this.id
  depends_on   = [oci_containerengine_node_pool.this]
}
