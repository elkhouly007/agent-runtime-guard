---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Infrastructure Patterns (Docker, Terraform, Kubernetes)

## Docker

### Image Hygiene

```dockerfile
# BAD — uses root, large image, no pinned versions
FROM ubuntu
RUN apt-get install nodejs npm
COPY . /app
CMD ["node", "server.js"]

# GOOD — pinned, minimal, non-root
FROM node:20.11-alpine3.19 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20.11-alpine3.19
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=app:app . .
USER app
EXPOSE 3000
CMD ["node", "server.js"]
```

- Pin base image versions (tag + digest) — `FROM node:20.11-alpine3.19` not `FROM node:latest`.
- Use multi-stage builds to keep final images small.
- Run as a non-root user in the final stage.
- Never `COPY . .` before `RUN npm install` — it breaks layer caching. Copy lockfiles first.
- Use `.dockerignore` to exclude `node_modules`, `.git`, secrets, local `.env` files.
- Scan images for vulnerabilities in CI: `docker scout cves` or `trivy image`.

### Secrets

- Never `ENV SECRET_KEY=...` in a Dockerfile — it ends up in the image layer history.
- Pass secrets at runtime via environment variables (injected by orchestrator or secret manager).
- Use Docker BuildKit secrets (`--mount=type=secret`) for build-time secrets (e.g., private npm registry tokens).

## Terraform

### State Management

- Store Terraform state in a remote backend (S3 + DynamoDB lock, GCS, Terraform Cloud) — never commit `terraform.tfstate` to git.
- Use state locking — prevents concurrent `apply` runs from corrupting state.
- Use workspaces or separate state files per environment (`dev`, `staging`, `prod`).

### Variable and Secret Handling

```hcl
# BAD — hardcoded secret in variable default
variable "db_password" {
  default = "supersecret123"
}

# GOOD — no default, injected from environment or secret manager
variable "db_password" {
  description = "Database password — injected from secret manager"
  type        = string
  sensitive   = true
}
```

- Mark sensitive variables with `sensitive = true` — Terraform will redact them from logs.
- Use `terraform.tfvars` only for non-sensitive values. Pass secrets via `TF_VAR_` environment variables or a secret manager data source.
- Never commit `*.tfvars` files that contain secrets.

### Resource Safety

```hcl
# Protect critical resources from accidental deletion
resource "aws_rds_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

- Add `lifecycle { prevent_destroy = true }` to production databases, S3 buckets, and KMS keys.
- Always run `terraform plan` and review the diff before `terraform apply` — especially check for `destroy` and `replace` actions.
- Use `required_providers` with version constraints — pin minor versions, allow patch: `~> 5.0`.

## Kubernetes

### Resource Limits

```yaml
# Always set requests AND limits
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

- Never deploy without resource requests and limits — unbounded pods cause noisy-neighbor problems.
- Set `requests` to what the pod normally uses; set `limits` to the maximum before it should be killed.
- Use `LimitRange` objects to enforce defaults at the namespace level.

### Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

- Run containers as non-root (`runAsNonRoot: true`).
- Use `readOnlyRootFilesystem: true` where possible — mount writable volumes explicitly.
- Drop all capabilities by default; add only what is required.
- Never use `privileged: true` in production.

### Secrets Management

- Never store secrets in ConfigMaps — use Secrets (with encryption at rest enabled in etcd).
- Prefer external secret managers (AWS Secrets Manager, Vault) with `ExternalSecret` CRD over native k8s Secrets for long-lived credentials.
- Rotate secrets without pod restarts using projected volume mounts or the CSI Secrets Store driver.

### Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 20
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

- Every pod must have both `livenessProbe` and `readinessProbe`.
- Liveness: "is the process running?" — failing restarts the pod.
- Readiness: "can this pod serve traffic?" — failing removes it from the load balancer.
- Do not reuse the same endpoint for both — readiness may fail during warm-up without needing a restart.

### CI/CD Safety

- Use `kubectl diff` before `kubectl apply` to preview changes in CI.
- Use `--dry-run=server` for validation before applying to production.
- Never `kubectl apply -f .` across a directory without reviewing each manifest.
- Gate production deploys on passing smoke tests against staging.
