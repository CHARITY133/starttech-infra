# starttech-infra

Terraform infrastructure for StartTech's enterprise CI/CD platform on Amazon EKS.

## What this provisions

| Module | Resources |
|---|---|
| `networking` | VPC (`starttech-vpc`, `10.0.0.0/16`), 2 public + 2 private subnets, IGW, NAT Gateway, route tables, ELB/internal-ELB subnet tags |
| `eks` | EKS cluster `starttech-cluster` (v1.34), managed node group `starttech-node-group` (2x `t3.medium`), least-privilege IAM roles |
| `storage` | Private S3 bucket `starttech-frontend-bucket-*`, ECR repo `starttech-backend-api` |
| `cdn` | Single CloudFront distribution: `S3-Frontend` origin (OAC) + `ALB-Backend` origin (HTTP), SPA 403/404→`/index.html` rewrite, `/api/*` uncached passthrough |
| `database` | ElastiCache Redis `starttech-redis` (`cache.t3.micro`), locked to EKS node security group |

## Why this needs TWO applies

CloudFront's `ALB-Backend` origin needs the ALB's DNS name. That ALB is
created by the **AWS Load Balancer Controller running inside EKS**, in
response to `k8s/ingress.yaml` in the `starttech-application` repo. So the
ALB doesn't exist until *after* you've deployed the cluster and the app.

**Pass 1** (`alb_dns_name = ""` in tfvars): creates VPC, EKS, S3, ECR, Redis.
The `cdn` module is skipped (`count = 0`).

Then:
```bash
aws eks update-kubeconfig --name starttech-cluster --region us-east-1

# Install the AWS Load Balancer Controller via Helm (one-time):
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=starttech-cluster \
  --set serviceAccount.create=true

kubectl apply -f ../starttech-application/k8s/
kubectl get ingress backend-ingress \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Pass 2**: put that hostname into `terraform.tfvars` as `alb_dns_name`,
run `terraform apply` again. This creates the CloudFront distribution.
Optionally grab the distribution ARN afterward and set
`cloudfront_distribution_arn` in tfvars, then apply once more to lock the S3
bucket policy down to that specific distribution.

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Or use `scripts/deploy-infrastructure.sh`, which runs the same steps.

## CI/CD

`.github/workflows/infrastructure-deploy.yml` runs `terraform fmt -check`,
`terraform validate`, and `terraform apply -auto-approve` on every push to
`main` that touches `terraform/**`. It authenticates via OIDC
(`secrets.AWS_DEPLOY_ROLE_ARN` — create an IAM role trusting GitHub's OIDC
provider, do not use long-lived access keys in CI).

## Remote state (recommended)

Uncomment the `backend "s3"` block in `terraform/main.tf` and create the
bucket + DynamoDB lock table first, so `terraform apply` in CI doesn't clobber
local state.

## Grader access

Attach the least-privilege JSON policy from the assessment brief to an IAM
user named `start-tech-grader`, and hand its access key / console password to
the grader via the submission Google Doc — never commit credentials to this
repo.
