# outputs.tf

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.this.id
}

output "internet_gateway_id" {
  description = "OCID of the VCN's Internet Gateway"
  value       = oci_core_internet_gateway.this.id
}

output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = oci_containerengine_cluster.this.id
}

output "kubeconfig" {
  description = "Raw kubeconfig for the cluster"
  value       = data.oci_containerengine_cluster_kube_config.this.content
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = var.control_plane_type == "public" ? data.oci_containerengine_cluster.refreshed.endpoints[0].public_endpoint : data.oci_containerengine_cluster.refreshed.endpoints[0].private_endpoint
}

output "bastion_id" {
  description = "OCID of the bastion service. Empty string when create_bastion is false."
  value       = var.create_bastion ? oci_bastion_bastion.this[0].id : ""
}

output "node_ids" {
  description = "Compute instance OCIDs of all worker nodes"
  value       = [for node in data.oci_containerengine_node_pool.refreshed.nodes : node.id]
}
