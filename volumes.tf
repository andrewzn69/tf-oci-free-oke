# volumes.tf

resource "oci_core_volume" "data" {
  count          = var.node_data_volume_size_gb != null ? var.node_count : 0
  compartment_id = var.compartment_id
  # distribute volumes across ADs using the same modulo pattern as placement_configs in cluster.tf
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[count.index % length(data.oci_identity_availability_domains.this.availability_domains)].name
  size_in_gbs         = var.node_data_volume_size_gb
  display_name        = "${var.name}-data-${count.index}"
  freeform_tags       = var.freeform_tags
}

resource "oci_core_volume_attachment" "data" {
  count           = var.node_data_volume_size_gb != null ? var.node_count : 0
  attachment_type = "paravirtualized"
  # nodes[count.index].id is the compute instance OCID - only populated after node pool is fully provisioned
  instance_id = oci_containerengine_node_pool.this.nodes[count.index].id
  volume_id   = oci_core_volume.data[count.index].id
}
