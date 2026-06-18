output "kubernetes_cluster_id" {
  description = "Kubernetes cluster ID"
  value       = yandex_kubernetes_cluster.k8s-cluster.id
}

output "alb_subnet_id" {
  description = "Subnet (no NAT default route) where the GWIN ALB is allocated"
  value       = yandex_vpc_subnet.subnet-alb.id
}
