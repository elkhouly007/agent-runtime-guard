---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Infrastructure Security

Security rules for infrastructure management.

## Identity and Access Management

- IAM roles for services, not long-lived access keys.
- Human access via SSO/IdP with MFA required.
- Least-privilege roles: each service has only the permissions its workload needs.
- Regular access reviews (quarterly). Revoke unused permissions and inactive accounts.
- No wildcard (`*`) actions or resources in production IAM policies.

## Secrets Management

- All secrets in a dedicated secrets manager (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager).
- Secrets are never stored in environment variable definitions in IaC code.
- Secret rotation automated and tested. Applications handle rotation gracefully.
- Secrets never written to logs, metrics, or error reports.

## Network Security

- All inter-service traffic encrypted (mTLS or TLS 1.2+).
- All ingress from the internet terminates at a load balancer or API gateway — never direct to instances.
- WAF in front of web-facing endpoints with OWASP Core Rule Set enabled.
- Network segmentation: no direct database access from internet-facing tiers.
- DDoS protection at the edge (CloudFront, AWS Shield, Cloudflare).

## Container Security

- Base images from trusted, minimal sources (distroless, official slim images).
- Images scanned for CVEs in CI before promotion.
- Containers run as non-root with read-only filesystems where possible.
- No privileged containers in production.
- Image digests pinned, not floating tags.

## Patch Management

- OS and runtime patches applied on a defined schedule (critical: <24h, high: <7d, medium: <30d).
- Immutable infrastructure makes patching a redeploy, not an in-place update.
- Dependency vulnerability scanning in CI with policy gates.

## Audit and Compliance

- CloudTrail / audit logs for all API calls. Retention minimum 1 year.
- Immutable audit log storage (WORM, S3 Object Lock).
- Config drift detection (AWS Config, Terraform sentinel) alerting on unauthorized changes.
- Penetration testing on a defined schedule. Track and remediate findings.
