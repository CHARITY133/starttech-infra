variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster/nodes, used to restrict Redis ingress"
  type        = string
}
