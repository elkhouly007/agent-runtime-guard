---
last_reviewed: 2026-04-20
version_target: "Terraform 1.7, Docker 25, Kubernetes 1.29"
upstream_ref: "source-README.md"
---

# Infrastructure Security

## Secrets in IaC State

**Never store secrets in Terraform state, tfvars, or IaC templates.**

```hcl
# BAD — hardcoded secret in Terraform resource
resource "aws_db_instance" "main" {
  username = "admin"
  password = "s3cr3tpassword"   # stored in .tfstate in plaintext
}

# GOOD — read from SSM / Secrets Manager at apply time
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/myapp/db_password"
}

resource "aws_db_instance" "main" {
  username = "admin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}

# GOOD — sensitive variable (excluded from plan output)
variable "db_password" {
  type      = string
  sensitive = true
}
```

- Mark all secret variables with `sensitive = true` — Terraform redacts them from plan output.
- Add `terraform.tfstate*` and `*.tfvars` (if they contain secrets) to `.gitignore`.
- Use remote state with encryption: S3 + server-side encryption, not local state files.
- Rotate secrets via Secrets Manager / Vault — never by editing IaC.

## Overpermissive IAM

```hcl
# BAD — wildcard permissions on all resources
resource "aws_iam_policy" "app_policy" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["*"]
      Resource = ["*"]
    }]
  })
}

# GOOD — minimal permissions on specific resources
resource "aws_iam_policy" "app_policy" {
  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["arn:aws:s3:::my-app-bucket/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = ["arn:aws:secretsmanager:us-east-1:123456789:secret:prod/myapp/*"]
      }
    ]
  })
}
```

- Apply principle of least privilege: grant only the actions the service actually calls.
- Use IAM conditions to restrict by IP, VPC, or time window when possible.
- Regularly audit with `aws iam get-account-authorization-details` or IAM Access Analyzer.
- Never use root account credentials for application deployments.

## Exposed Storage Buckets

```hcl
# BAD — public S3 bucket
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# GOOD — all public access blocked (default for new accounts, explicit here)
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# GOOD — enforce TLS-only access policy
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    Statement = [{
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = ["${aws_s3_bucket.main.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}
```

## Container Image Security

```dockerfile
# BAD — unpinned, runs as root, no multi-stage
FROM node:latest
COPY . /app
RUN npm install
CMD ["node", "server.js"]

# GOOD — pinned digest, non-root, multi-stage, minimal image
FROM node:20.11-alpine3.19@sha256:<digest> AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts

FROM node:20.11-alpine3.19@sha256:<digest>
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder --chown=app:app /app/node_modules ./node_modules
COPY --chown=app:app . .
USER app
EXPOSE 3000
CMD ["node", "--disable-proto=throw", "server.js"]
```

```yaml
# Kubernetes: security context for pods
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

- Pin base images to digest (`@sha256:...`), not just a tag — tags are mutable.
- Never run containers as root; use `USER nonroot` in Dockerfile.
- Set `readOnlyRootFilesystem: true` in Kubernetes and mount writable volumes only where needed.
- Scan images with `trivy image <name>` or `docker scout cves <name>` before pushing.

## Network Exposure

```yaml
# BAD — Kubernetes service exposed as LoadBalancer with no restriction
apiVersion: v1
kind: Service
spec:
  type: LoadBalancer
  ports:
  - port: 5432       # database port directly exposed to internet

# GOOD — database service is ClusterIP only (internal)
spec:
  type: ClusterIP
  ports:
  - port: 5432
```

- Database and internal services must be `ClusterIP` — never `LoadBalancer` or `NodePort`.
- Use Network Policies to restrict pod-to-pod communication.
- Restrict SSH and admin ports (22, 3389) to known IP ranges using security groups.

## Tooling Commands

```bash
# Terraform: scan for misconfigurations
tfsec .
checkov -d .

# Check for secrets in IaC files
git-secrets --scan
trufflehog filesystem .

# Docker: scan image for CVEs
trivy image myapp:latest
docker scout cves myapp:latest

# Kubernetes: audit security posture
kubectl auth can-i --list --as=system:serviceaccount:default:myapp
kube-bench run --targets node,master

# AWS: find public S3 buckets
aws s3api list-buckets --query 'Buckets[].Name' | \
  xargs -I{} aws s3api get-bucket-acl --bucket {}
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Secrets in tfstate / tfvars | Credential exposure | Secrets Manager + `sensitive = true` |
| Wildcard IAM (`Action: *`) | Full account compromise | Least privilege per service |
| Public S3 bucket | Data breach | Block all public access |
| Unpinned base images | Supply chain attack | Pin to digest |
| Container running as root | Container escape → host | `USER nonroot` + `runAsNonRoot: true` |
| Database port as LoadBalancer | DB exposed to internet | ClusterIP only |
| No network policies | Lateral movement | Restrict pod-to-pod traffic |
| Local unencrypted tfstate | State file theft | Remote state + encryption |
