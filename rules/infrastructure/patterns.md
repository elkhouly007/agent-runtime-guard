---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Infrastructure Patterns

Patterns for reliable, maintainable infrastructure.

## Infrastructure as Code

- All infrastructure defined in code (Terraform, Pulumi, CDK). No manual console changes.
- IaC changes go through the same PR review process as application code.
- State files stored remotely with locking (Terraform Cloud, S3 + DynamoDB).
- Modular structure: reusable modules for common primitives (VPC, ECS service, RDS cluster).

## Environment Parity

- Production, staging, and development environments built from the same IaC modules.
- Environment-specific values in `.tfvars` files or parameter stores, not in module code.
- Staging mirrors production configuration. Feature flags control behavior differences.

## Immutable Infrastructure

- Never SSH into running instances to make changes.
- Changes are applied by replacing instances, not mutating them.
- AMIs and container images are versioned artifacts built in CI.
- Blue/green or canary deployments over in-place updates for stateful services.

## Service Configuration

- Twelve-factor config: all configuration from environment variables.
- Secrets injected at runtime from a secrets manager, not baked into images.
- Health checks on every service: readiness (ready to serve) and liveness (still alive).

## Networking

- Private subnets for application and database tiers. Public subnets only for load balancers.
- Security groups with minimal ingress rules. Default deny.
- VPC endpoints for AWS service communication — no public internet traversal for internal traffic.
- No `0.0.0.0/0` ingress except on load balancers (port 80/443 only).

## Scaling

- Horizontal scaling preferred over vertical.
- Auto-scaling based on CPU, memory, or custom metrics with cooldown periods.
- Load balancers in front of all stateless services.
- Stateful services (databases, queues) scaled through managed service offerings.

## Observability

- Structured logs with correlation IDs forwarded to a central log aggregator.
- Metrics exported in standard formats (Prometheus, CloudWatch).
- Distributed tracing (OpenTelemetry) across service boundaries.
- Alerts on SLOs, not just resource thresholds.
