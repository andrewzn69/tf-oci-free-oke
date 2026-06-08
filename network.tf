# network.tf

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-vcn"
  cidr_blocks    = [var.vcn_cidr_block]
  dns_label      = var.name
  freeform_tags  = var.freeform_tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-igw"
  enabled        = true
  freeform_tags  = var.freeform_tags
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nat"
  freeform_tags  = var.freeform_tags
}

resource "oci_core_route_table" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-igw-rt"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_route_table" "nat" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nat-rt"
  freeform_tags  = var.freeform_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }
}

resource "oci_core_security_list" "endpoint" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-endpoint-sl"
  freeform_tags  = var.freeform_tags

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    source    = var.vcn_cidr_block
    protocol  = "all"
    stateless = false
  }

  dynamic "ingress_security_rules" {
    for_each = var.control_plane_type == "public" ? var.control_plane_allowed_cidrs : []
    content {
      source    = ingress_security_rules.value
      protocol  = "6"
      stateless = false
      tcp_options {
        min = 6443
        max = 6443
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.extra_endpoint_ingress_rules
    content {
      source    = ingress_security_rules.value.source
      protocol  = ingress_security_rules.value.protocol
      stateless = ingress_security_rules.value.stateless

      dynamic "tcp_options" {
        for_each = ingress_security_rules.value.tcp_options != null ? [ingress_security_rules.value.tcp_options] : []
        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "udp_options" {
        for_each = ingress_security_rules.value.udp_options != null ? [ingress_security_rules.value.udp_options] : []
        content {
          min = udp_options.value.min
          max = udp_options.value.max
        }
      }
    }
  }
}

resource "oci_core_security_list" "nodes" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nodes-sl"
  freeform_tags  = var.freeform_tags

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    source    = var.vcn_cidr_block
    protocol  = "all"
    stateless = false
  }

  dynamic "ingress_security_rules" {
    for_each = var.extra_nodes_ingress_rules
    content {
      source    = ingress_security_rules.value.source
      protocol  = ingress_security_rules.value.protocol
      stateless = ingress_security_rules.value.stateless

      dynamic "tcp_options" {
        for_each = ingress_security_rules.value.tcp_options != null ? [ingress_security_rules.value.tcp_options] : []
        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "udp_options" {
        for_each = ingress_security_rules.value.udp_options != null ? [ingress_security_rules.value.udp_options] : []
        content {
          min = udp_options.value.min
          max = udp_options.value.max
        }
      }
    }
  }
}

resource "oci_core_subnet" "endpoint" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.this.id
  display_name      = "${var.name}-endpoint-subnet"
  cidr_block        = var.endpoint_subnet_cidr_block
  route_table_id    = var.control_plane_type == "public" ? oci_core_route_table.igw.id : oci_core_route_table.nat.id
  security_list_ids = [oci_core_security_list.endpoint.id]
  dns_label         = "endpoint"
  freeform_tags     = var.freeform_tags
}

resource "oci_core_subnet" "nodes" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.name}-nodes-subnet"
  cidr_block                 = var.nodes_subnet_cidr_block
  route_table_id             = oci_core_route_table.nat.id
  security_list_ids          = [oci_core_security_list.nodes.id]
  dns_label                  = "nodes"
  prohibit_public_ip_on_vnic = true
  freeform_tags              = var.freeform_tags
}

resource "oci_core_security_list" "lb" {
  count          = var.lb_subnet_cidr_block != null ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-lb-sl"
  freeform_tags  = var.freeform_tags

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "all"
    stateless = false
  }
}

resource "oci_core_subnet" "lb" {
  count             = var.lb_subnet_cidr_block != null ? 1 : 0
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.this.id
  display_name      = "${var.name}-lb-subnet"
  cidr_block        = var.lb_subnet_cidr_block
  route_table_id    = oci_core_route_table.igw.id
  security_list_ids = [oci_core_security_list.lb[0].id]
  dns_label         = "lb"
  freeform_tags     = var.freeform_tags
}
