output "cluster_name" {
  value = aws_eks_cluster.starttech_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.starttech_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.starttech_cluster.certificate_authority[0].data
}

output "node_group_role_arn" {
  value = aws_iam_role.node_group.arn
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.starttech_cluster.vpc_config[0].cluster_security_group_id
}
