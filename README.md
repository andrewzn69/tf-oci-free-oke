# oci-free-tier-oke

Terraform module for provisioning a Kubernetes cluster on OCI using always-free tier resources.

This module can:
- create a VCN with all required subnets, route tables, and security lists
- provision an OKE cluster with an ARM64 (VM.Standard.A1.Flex) node pool
- attach optional data block volumes to each worker node
- create an OCI Bastion Service for private cluster access

## Requirements

- OCI account with always-free tier available
- Terraform ~> 1.15
- oracle/oci ~> 8.14.0
- OCI credentials configured via environment variables

## Usage

```hcl
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
  source = "github.com/andrewzn69/terraform//modules/oci-free-tier-oke"

  compartment_id     = "<compartment-ocid>"
  name               = "<cluster-name>"
  kubernetes_version = "v1.36.1"

  control_plane_type          = "public"
  control_plane_allowed_cidrs = ["0.0.0.0/0"]

  create_bastion = false
}
```

## Examples

See the [examples](./examples/) directory for complete working configurations.

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
