variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group. Assessment brief calls for t3.medium; temporarily set to a free-tier-eligible type if your AWS account has Free Tier instance restrictions."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}