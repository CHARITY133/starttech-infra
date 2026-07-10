#!/usr/bin/env bash
# deploy-infrastructure.sh
# Two-pass apply helper for starttech-infra.
#
# Pass 1: stands up VPC, EKS, S3, ECR, Redis (everything CloudFront depends on).
# Pass 2: run AFTER you've deployed the app + Ingress (which creates the ALB),
#         with alb_dns_name set in terraform.tfvars, to create CloudFront.
set -euo pipefail

cd "$(dirname "$0")/../terraform"

echo "==> terraform init"
terraform init -input=false

echo "==> terraform fmt -check"
terraform fmt -recursive

echo "==> terraform validate"
terraform validate

echo "==> terraform plan"
terraform plan -out=tfplan

echo "==> terraform apply"
terraform apply -auto-approve tfplan

echo ""
echo "Pass 1 complete. Next steps:"
echo "  1. aws eks update-kubeconfig --name starttech-cluster --region \$(terraform output -raw aws_region 2>/dev/null || echo us-east-1)"
echo "  2. Install the AWS Load Balancer Controller (helm) in the cluster."
echo "  3. kubectl apply -f ../../starttech-application/k8s/"
echo "  4. kubectl get ingress backend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo "  5. Put that hostname into terraform.tfvars as alb_dns_name, then re-run this script."
