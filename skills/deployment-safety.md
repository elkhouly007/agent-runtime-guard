# Skill: deployment-safety

---
name: deployment-safety
description: Run a pre-deployment safety checklist to catch common deployment failures before they reach production
---

# Deployment Safety

Systematic checks before any production deployment.

## When to Use


## Pre-Deployment Checklist

### Code Integrity
- [ ] All tests pass on CI for the exact commit being deployed
- [ ] No failing linter errors (`npm run lint`, `golangci-lint run`, etc.)
- [ ] Security scan passed (Snyk, npm audit, trivy)
- [ ] No uncommitted changes on the deploy branch

### Configuration
- [ ] All required environment variables are set for the target environment
- [ ] Secrets are from the secrets manager, not hardcoded
- [ ] Feature flags for new features are set to off-by-default in production
- [ ] Database connection strings point to the correct environment

### Database
- [ ] All pending migrations have been reviewed
- [ ] Migration is backwards-compatible (old code can run against new schema)
- [ ] Rollback plan exists if migration fails
- [ ] No migration touches a table with active write load without a maintenance window

### Infrastructure
- [ ] Target infrastructure is healthy before deploy starts
- [ ] Auto-scaling limits are appropriate for expected load
- [ ] Load balancer health checks are configured correctly

### Observability
- [ ] New features have logging in place
- [ ] Alerts are configured for the new service/endpoint
- [ ] Dashboards updated to include new metrics

## Deploy Strategy

Choose the right strategy:
- **Blue/Green**: two identical environments, switch traffic atomically — best for zero-downtime
- **Canary**: route 1%–5% traffic to new version, watch metrics, roll forward or back
- **Rolling**: replace instances one at a time — simplest, but briefly runs mixed versions
- **Feature flags**: deploy code with flag off, enable in production separately

## Rollback Trigger Criteria

Define before deploying. Roll back if within 15 minutes:
- Error rate increases by more than X%
- P99 latency exceeds Y ms
- Any critical path returns 5xx
- On-call gets paged

## Post-Deploy Verification

```bash
# Health check
curl -sf https://api.example.com/health | jq .

# Smoke test critical endpoints
curl -sf https://api.example.com/users/me -H "Authorization: Bearer $TEST_TOKEN"

# Check error rate in logs
# (command varies by log platform)
```
