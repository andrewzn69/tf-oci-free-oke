# volumes.tf

resource "oci_core_volume" "data" {
  count          = var.node_data_volume_size_gb != null ? var.node_count : 0
  compartment_id = var.compartment_id
  # use the node's actual AD so the volume is attachable (cross-AD attachment is not allowed)
  availability_domain = data.oci_containerengine_node_pool.refreshed.nodes[count.index].availability_domain
  size_in_gbs         = var.node_data_volume_size_gb
  display_name        = "${var.name}-data-${count.index}"
  freeform_tags       = var.freeform_tags
}

resource "oci_core_volume_attachment" "data" {
  count           = var.node_data_volume_size_gb != null ? var.node_count : 0
  attachment_type = "paravirtualized"
  instance_id     = data.oci_containerengine_node_pool.refreshed.nodes[count.index].id
  volume_id       = oci_core_volume.data[count.index].id
}
