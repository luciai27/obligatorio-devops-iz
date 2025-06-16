output "cluster_name" {
  value = aws_eks_cluster.eks_dev.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_dev.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.eks_dev.certificate_authority[0].data
}
