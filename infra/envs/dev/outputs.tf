output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}