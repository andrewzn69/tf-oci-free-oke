# Examples

Examples covering common use cases of the `oci-free-tier-oke` module.

## Available Examples

| Example   | Description                                                        |
| --------- | ------------------------------------------------------------------ |
| `public`  | Public control plane endpoint with allowed CIDRs, no bastion       |
| `private` | Private control plane endpoint with OCI Bastion Service for access |

## Running an Example

1. Change into the example directory:
```sh
cd examples/<example-name>
```

2. Copy the example tfvars file:
```sh
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars` with your values.

4. Initialize Terraform:
```sh
terraform init
```

5. Review the plan:
```sh
terraform plan
```

6. Apply:
```sh
terraform apply
```

## Required Variables

All examples expect these variables:

```hcl
compartment_id     = "ocid1.compartment.oc1..<...>"
name               = "<cluster-name>"
kubernetes_version = "v1.36.1"
```
