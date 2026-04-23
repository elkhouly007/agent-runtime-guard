# Skill: Deployment Patterns

## Trigger

Use when planning, reviewing, or executing a deployment — covering CI/CD pipelines, deployment strategy selection, health checks, environment management, rollback procedures, and post-deploy verification.

## Pre-Deployment Checklist

- [ ] All CI stages pass (test, build, scan).
- [ ] Migration rollback plan documented and approved.
- [ ] Feature flags in place for large changes.
- [ ] On-call engineer identified and available.
- [ ] Rollback command documented and tested in staging.
- [ ] Monitoring dashboards open (error rate, p99 latency, saturation).
- [ ] Dependent services notified if contract changes.

## Process

### 1. Choose a Deployment Strategy

| Strategy | How | Risk | When to Use |
|----------|-----|------|-------------|
| Rolling | Replace instances one by one | Medium — mixed versions briefly co-exist | Stateless services, backward-compat changes |
| Blue-Green | Spin up full new env, cut traffic at once | Low — instant rollback | High-stakes releases, DB schema changes with full migration pre-run |
| Canary | Route 1–5% traffic to new version, expand if healthy | Lowest — real traffic validation | Large services, behaviour changes, ML model updates |
| Recreate | Tear down all, bring up new | High — brief downtime | Dev/staging only, or intentional maintenance window |

### 2. Health Check Endpoint Design

Every service must expose three endpoints:

```
GET /health    → 200 if the process is alive (used by load balancer)
GET /ready     → 200 if the service can accept traffic (checks DB, cache, dependencies)
GET /live      → 200 if the process should not be killed (liveness probe in k8s)
```

```typescript
// Express example
import express from 'express';
import { pool } from './db';

const app = express();

// Liveness — is the process running?
app.get('/live', (_req, res) => {
  res.status(200).json({ status: 'alive' });
});

// Readiness — can we serve traffic?
app.get('/ready', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'ready' });
  } catch (err) {
    res.status(503).json({ status: 'not ready', reason: 'db unavailable' });
  }
});

// Health (combined, for simple load balancers)
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', version: process.env.APP_VERSION });
});
```

```python
# FastAPI example
from fastapi import FastAPI, Response
import asyncpg

app = FastAPI()

@app.get('/health')
async def health():
    return {'status': 'ok', 'version': os.getenv('APP_VERSION')}

@app.get('/ready')
async def ready(response: Response):
    try:
        conn = await asyncpg.connect(os.getenv('DATABASE_URL'))
        await conn.execute('SELECT 1')
        await conn.close()
        return {'status': 'ready'}
    except Exception as e:
        response.status_code = 503
        return {'status': 'not ready', 'reason': str(e)}
```

### 3. CI Pipeline Stages

```
test → build → scan → deploy → verify
```

#### Full GitHub Actions Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

env:
  IMAGE: ghcr.io/${{ github.repository }}
  TAG:   ${{ github.sha }}

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4

      - name: Run tests
        env:
          DATABASE_URL: postgres://postgres:test@localhost:5432/testdb
        run: |
          npm ci
          npm run test:coverage
          npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.push.outputs.digest }}
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        id: push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ env.IMAGE }}:${{ env.TAG }},${{ env.IMAGE }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  scan:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE }}:${{ env.TAG }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: '1'   # fail the pipeline on CRITICAL/HIGH

      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

  deploy:
    needs: scan
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Run database migrations
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: npx prisma migrate deploy

      - name: Deploy to production
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG }}
        run: |
          kubectl set image deployment/api \
            api=${{ env.IMAGE }}:${{ env.TAG }} \
            --record
          kubectl rollout status deployment/api --timeout=5m

  verify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Smoke test
        run: |
          BASE=https://api.example.com
          for endpoint in /health /ready; do
            status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$endpoint")
            if [ "$status" != "200" ]; then
              echo "FAIL: $endpoint returned $status"
              exit 1
            fi
            echo "OK: $endpoint"
          done

      - name: Notify on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: '{"text":"Deployment verification failed for ${{ github.sha }}"}'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### 4. Environment Variable Management

**Rules:**
- Never bake secrets into the Docker image.
- Never commit `.env` files with real values.
- Use separate variable sets per environment (dev / staging / prod).

```bash
# Pattern: .env.example committed, .env never committed
# .gitignore
.env
.env.local
.env.production

# .env.example (committed — values are placeholders)
DATABASE_URL=postgres://user:pass@localhost:5432/mydb
REDIS_URL=redis://localhost:6379
APP_SECRET=changeme
APP_VERSION=
```

#### Secrets Injection Patterns

| Method | Good For | Avoid When |
|--------|----------|------------|
| GitHub Actions secrets → env | CI/CD pipelines | Rotation required frequently |
| Kubernetes Secrets + envFrom | K8s workloads | Plaintext in etcd without encryption |
| AWS Secrets Manager / Parameter Store | Production apps | Adds latency on cold start |
| HashiCorp Vault | Enterprise, dynamic credentials | Simple projects |
| Docker secrets (Swarm) | Docker Swarm only | Non-Swarm environments |

```yaml
# Kubernetes: inject secrets as env vars
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: api
          image: ghcr.io/org/api:abc123
          envFrom:
            - secretRef:
                name: api-secrets          # kubectl create secret generic api-secrets ...
          env:
            - name: APP_VERSION
              value: "abc123"              # non-secret — plain env var
```

```bash
# Create the secret from local env file (one-time or in CI)
kubectl create secret generic api-secrets \
  --from-env-file=.env.production \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 5. Deployment Strategies — Implementation

#### Rolling (Kubernetes default)

```yaml
# deployment.yaml
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1   # at most 1 pod down at a time
      maxSurge: 1         # at most 1 extra pod during update
```

#### Blue-Green (bash + kubectl)

```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/org/api:${GIT_SHA}"
CURRENT=$(kubectl get service api -o jsonpath='{.spec.selector.slot}')
NEW=$([ "$CURRENT" = "blue" ] && echo "green" || echo "blue")

echo "Current slot: $CURRENT → Deploying to: $NEW"

# Deploy to inactive slot
kubectl set image "deployment/api-$NEW" "api=$IMAGE"
kubectl rollout status "deployment/api-$NEW" --timeout=5m

# Health check before cut-over
POD=$(kubectl get pod -l "slot=$NEW" -o jsonpath='{.items[0].metadata.name}' | head -1)
kubectl exec "$POD" -- wget -qO- localhost:8080/ready || {
  echo "Readiness check failed — aborting cutover"
  exit 1
}

# Cut traffic
kubectl patch service api -p "{\"spec\":{\"selector\":{\"slot\":\"$NEW\"}}}"
echo "Traffic switched to $NEW"

# Optionally scale down old slot
kubectl scale "deployment/api-$CURRENT" --replicas=0
```

#### Canary (Argo Rollouts)

```yaml
# rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5        # 5% of traffic
        - pause: {duration: 5m}
        - setWeight: 25
        - pause: {duration: 10m}
        - setWeight: 100      # full rollout if no auto-abort triggered
      analysis:
        templates:
          - templateName: error-rate-check
        args:
          - name: service-name
            value: api
```

### 6. Rollback Triggers and Procedure

**Auto-rollback triggers (alert → pipeline):**
- Error rate > 1% for 5 minutes on new version.
- p99 latency > 2× baseline for 3 minutes.
- Health check returning non-200 for 3 consecutive probes.
- Any CRITICAL log in first 10 minutes post-deploy.

```bash
# Manual rollback — Kubernetes
kubectl rollout undo deployment/api
kubectl rollout status deployment/api --timeout=3m

# Roll back to specific revision
kubectl rollout history deployment/api
kubectl rollout undo deployment/api --to-revision=3

# Manual rollback — database (run BEFORE rolling back the app if migration is not backward-compat)
migrate -path db/migrations -database "$DATABASE_URL" down 1

# Verify health after rollback
curl -f https://api.example.com/ready && echo "OK"
```

### 7. Post-Deploy Smoke Tests

```bash
#!/usr/bin/env bash
# scripts/smoke-test.sh
set -euo pipefail

BASE="${API_BASE_URL:-https://api.example.com}"
TIMEOUT=10

check() {
  local path="$1" expected="$2"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$BASE$path")
  if [ "$status" != "$expected" ]; then
    echo "FAIL  $path — expected $expected, got $status"
    return 1
  fi
  echo "PASS  $path"
}

check /health   200
check /ready    200
check /v1/ping  200

# Auth endpoint — expect 401 without token, not 500
check /v1/users 401

echo "All smoke tests passed."
```

## Anti-Patterns

- **Never deploy directly to production from a local machine** — all deploys must go through CI.
- **Never skip the scan stage** — image scanning catches CVEs before they reach production.
- **Never deploy schema migrations and application code atomically without backward-compat planning** — the migration must be compatible with the current live app version.
- **Never use `latest` tag in production** — pin to immutable digest or git SHA.
- **Never store secrets in environment files committed to git** — use a secrets manager or CI secrets.
- **Never deploy on Friday afternoon without an on-call engineer present.**

## Safe Behavior

- Read-only analysis of pipelines and configs unless Ahmed confirms execution.
- Flags any pipeline that skips the scan stage.
- Flags missing rollback procedure or health checks.
- Does not execute production deploys autonomously.
- CRITICAL findings (no health checks, secrets in image, no rollback plan) require Ahmed's attention before merge.
