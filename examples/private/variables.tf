variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

variable "name" {
  description = "Name used for the cluster and all resource display names"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "bastion_allowed_cidrs" {
  description = "CIDRs allowed to connect to the bastion service"
  type        = list(string)
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "node_ocpus" {
  description = "OCPUs per worker node"
  type        = number
  default     = 2
}

variable "node_memory_gb" {
  description = "Memory in GB per worker node"
  type        = number
  default     = 12
}

variable "node_boot_volume_size_gb" {
  description = "Boot volume size in GB per worker node"
  type        = number
  default     = 50
}

variable "node_data_volume_size_gb" {
  description = "Size in GB of the data block volume per node. Set null to skip."
  type        = number
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
