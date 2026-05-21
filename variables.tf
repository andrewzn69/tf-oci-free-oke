# variables.tf

# cloud init

variable "cloud_init_local" {
  type        = string
  description = "Full cloud-init script as a string, replaces the default cloud-init.sh"
  default     = null
}

variable "cloud_init_url" {
  type        = string
  description = "URL to fetch cloud-init script from, replaces the default cloud-init.sh"
  default     = null

  validation {
    condition     = var.cloud_init_url == null || can(regex("^https?://", var.cloud_init_url))
    error_message = "cloud_init_url must be a valid http or https url"
  }
}

# cluster

variable "control_plane_type" {
  type        = string
  description = "Whether to allow public or private access to the control plane endpoint"
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.control_plane_type)
    error_message = "Accepted values are public or private"
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be in format vX.Y.Z (e.g. v1.36.1)"
  }
}

# network

variable "endpoint_subnet_cidr_block" {
  type        = string
  description = "CIDR block for the cluster endpoint and LB subnet"
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.endpoint_subnet_cidr_block, 0))
    error_message = "endpoint_subnet_cidr_block must be a valid CIDR"
  }
}

variable "nodes_subnet_cidr_block" {
  type        = string
  description = "CIDR block for the worker nodes subnet"
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.nodes_subnet_cidr_block, 0))
    error_message = "nodes_subnet_cidr_block must be a valid CIDR"
  }
}

variable "pods_cidr" {
  type        = string
  description = "CIDR for pod networking"
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "pods_cidr must be a valid CIDR"
  }
}

variable "services_cidr" {
  type        = string
  description = "CIDR for service networking"
  default     = "10.96.0.0/16"

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "services_cidr must be a valid CIDR"
  }
}

variable "vcn_cidr_block" {
  type        = string
  description = "CIDR block for the VCN"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr_block, 0))
    error_message = "vcn_cidr_block must be a valid CIDR"
  }
}

# node pool

variable "install_flannel" {
  type        = bool
  description = "Install OKE-managed Flannel CNI. Set to false to bring your own CNI."
  default     = true
}

variable "node_boot_volume_size_gb" {
  type        = number
  description = "Boot volume size in GB per worker node"
  default     = 50

  validation {
    condition     = var.node_boot_volume_size_gb >= 50
    error_message = "node_boot_volume_size_gb must be at least 50 GB (OCI minimum)"
  }
}

variable "node_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 2

  validation {
    condition     = var.node_count > 0
    error_message = "node_count must be at least 1"
  }
}

variable "node_data_volume_size_gb" {
  type        = number
  description = "Size in GB of the data block volume attached to each worker node, for persistent storage. Minimum 50. Set null to skip."
  default     = null

  validation {
    condition     = var.node_data_volume_size_gb == null || var.node_data_volume_size_gb >= 50
    error_message = "node_data_volume_size_gb must be at least 50 GB (OCI minimum)"
  }
}

variable "node_memory_gb" {
  type        = number
  description = "Memory in GB per worker node"
  default     = 12

  validation {
    condition     = var.node_memory_gb >= 1
    error_message = "node_memory_gb must be at least 1"
  }

  validation {
    condition     = var.node_count * var.node_memory_gb <= 24
    error_message = "Total memory (node_count * node_memory_gb) must not exceed 24 GB (OCI free tier limit)"
  }
}

variable "node_ocpus" {
  type        = number
  description = "OCPUs per worker node"
  default     = 2

  validation {
    condition     = var.node_ocpus >= 1
    error_message = "node_ocpus must be at least 1"
  }

  validation {
    condition     = var.node_count * var.node_ocpus <= 4
    error_message = "Total OCPUs (node_count * node_ocpus) must not exceed 4 (OCI free tier limit)"
  }
}

# oci

variable "compartment_id" {
  type        = string
  description = "OCID of the compartment"

  validation {
    condition     = can(regex("^ocid1\\.", var.compartment_id))
    error_message = "compartment_id must be a valid OCI OCID"
  }
}

variable "name" {
  type        = string
  description = "Name used for the cluster and all resource display names"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.name))
    error_message = "name must start with a lowercase letter, contain only lowercase letters and numbers, and be at most 15 characters (OCI dns_label constraint)"
  }
}

# security

variable "bastion_allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to connect to the bastion service"
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

variable "control_plane_allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the control plane endpoint. Only applies when control_plane_type is public"
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

variable "create_bastion" {
  type        = bool
  description = "Create an OCI Bastion Service for accessing the private cluster endpoint."
  default     = true
}

variable "extra_endpoint_ingress_rules" {
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
  description = "Extra ingress rules for the endpoint subnet security list"
  default     = []
}

variable "extra_nodes_ingress_rules" {
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
  description = "Extra ingress rules for the nodes subnet security list"
  default     = []
}

# ssh

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for node access"
  default     = null

  validation {
    condition     = var.ssh_public_key == null || can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid SSH public key (ssh-rsa, ssh-ed25519, or ecdsa-sha2-nistp256/384/521)"
  }
}

# tags

variable "freeform_tags" {
  type        = map(string)
  description = "Freeform tags to apply to all resources"
  default     = {}
}
