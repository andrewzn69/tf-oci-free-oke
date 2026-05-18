# bastion.tf

resource "oci_bastion_bastion" "this" {
  count            = var.create_bastion ? 1 : 0
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_id
  target_subnet_id = oci_core_subnet.endpoint.id
  name             = "${var.name}-bastion"

  client_cidr_block_allow_list = var.bastion_allowed_cidrs

  freeform_tags = var.freeform_tags
}
