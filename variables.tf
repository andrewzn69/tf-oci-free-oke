# variables.tf

# oci

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.", var.compartment_id))
    error_message = "compartment_id must be a valid OCI OCID"
  }
}

variable "name" {
  description = "Name used for the cluster and all resource display names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.name))
    error_message = "name must start with a lowercase letter, contain only lowercase letters and numbers, and be at most 15 characters (OCI dns_label constraint)"
  }
}

# cluster

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be in format vX.Y.Z (e.g. v1.36.1)"
  }
}

variable "control_plane_type" {
  description = "Whether to allow public or private access to the control plane endpoint"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.control_plane_type)
    error_message = "Accepted values are public or private"
  }
}

# node pool

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_count > 0
    error_message = "node_count must be at least 1"
  }
}

variable "node_ocpus" {
  description = "OCPUs per worker node"
  type        = number
  default     = 2

  validation {
    condition     = var.node_ocpus >= 1
    error_message = "node_ocpus must be at least 1"
  }
}

variable "node_memory_gb" {
  description = "Memory in GB per worker node"
  type        = number
  default     = 12

  validation {
    condition     = var.node_memory_gb >= 1
    error_message = "node_memory_gb must be at least 1"
  }
}

variable "node_boot_volume_size_gb" {
  description = "Boot volume size in GB per worker node"
  type        = number
  default     = 50

  validation {
    condition     = var.node_boot_volume_size_gb >= 50
    error_message = "node_boot_volume_size_gb must be at least 50 GB (OCI minimum)"
  }
}

variable "node_data_volume_size_gb" {
  description = "Size in GB of the data block volume attached to each worker node, for persistent storage. Minimum 50. Set null to skip."
  type        = number
  default     = null

  validation {
    condition     = var.node_data_volume_size_gb == null || var.node_data_volume_size_gb >= 50
    error_message = "node_data_volume_size_gb must be at least 50 GB (OCI minimum)"
  }
}

# network

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr_block, 0))
    error_message = "vcn_cidr_block must be a valid CIDR"
  }
}

variable "endpoint_subnet_cidr_block" {
  description = "CIDR block for the cluster endpoint and LB subnet"
  type        = string
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.endpoint_subnet_cidr_block, 0))
    error_message = "endpoint_subnet_cidr_block must be a valid CIDR"
  }
}

variable "nodes_subnet_cidr_block" {
  description = "CIDR block for the worker nodes subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.nodes_subnet_cidr_block, 0))
    error_message = "nodes_subnet_cidr_block must be a valid CIDR"
  }
}

variable "pods_cidr" {
  description = "CIDR for pod networking"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "pods_cidr must be a valid CIDR"
  }
}

variable "services_cidr" {
  description = "CIDR for service networking"
  type        = string
  default     = "10.96.0.0/16"

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "services_cidr must be a valid CIDR"
  }
}

# security

variable "control_plane_allowed_cidrs" {
  description = "CIDRs allowed to reach the control plane endpoint. Only applies when control_plane_type is public"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.control_plane_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All entries in control_plane_allowed_cidrs must be valid CIDRs"
  }

  validation {
    condition     = var.control_plane_type != "public" || length(var.control_plane_allowed_cidrs) > 0
    error_message = "control_plane_allowed_cidrs must be set when control_plane_type is public"
  }
}

variable "extra_endpoint_ingress_rules" {
  description = "Extra ingress rules for the endpoint subnet security list"
  type = list(object({
    source    = string
    protocol  = string
    stateless = optional(bool, false)
    tcp_options = optional(object({
      min = number
      max = number
    }))
    udp_options = optional(object({
      min = number
      max = number
    }))
  }))
  default = []
}

variable "extra_nodes_ingress_rules" {
  description = "Extra ingress rules for the nodes subnet security list"
  type = list(object({
    source    = string
    protocol  = string
    stateless = optional(bool, false)
    tcp_options = optional(object({
      min = number
      max = number
    }))
    udp_options = optional(object({
      min = number
      max = number
    }))
  }))
  default = []
}

variable "create_bastion" {
  description = "Create an OCI Bastion Service for accessing the private cluster endpoint."
  type        = bool
  default     = true
}

variable "bastion_allowed_cidrs" {
  description = "CIDRs allowed to connect to the bastion service"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.bastion_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All entries in bastion_allowed_cidrs must be valid CIDRs"
  }

  validation {
    condition     = !var.create_bastion || length(var.bastion_allowed_cidrs) > 0
    error_message = "bastion_allowed_cidrs must be set when create_bastion is true"
  }
}

# ssh

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = null

  validation {
    condition     = var.ssh_public_key == null || can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid SSH public key (ssh-rsa, ssh-ed25519, or ecdsa-sha2-nistp256/384/521)"
  }
}

# tags

variable "freeform_tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# cloud init

variable "cloud_init_local" {
  description = "Full cloud-init script as a string, replaces the default cloud-init.sh"
  type        = string
  default     = null
}

variable "cloud_init_url" {
  description = "URL to fetch cloud-init script from, replaces the default cloud-init.sh"
  type        = string
  default     = null

  validation {
    condition     = var.cloud_init_url == null || can(regex("^https?://", var.cloud_init_url))
    error_message = "cloud_init_url must be a valid http or https url"
  }
}
