output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = module.oke.cluster_id
}

output "kubeconfig" {
  description = "Raw kubeconfig for the cluster"
  value       = module.oke.kubeconfig
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.oke.cluster_endpoint
}

output "node_ids" {
  description = "Compute instance OCIDs of all worker nodes"
  value       = module.oke.node_ids
}
