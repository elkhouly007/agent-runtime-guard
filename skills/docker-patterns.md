# Skill: Docker Patterns

## Trigger

Use when writing Dockerfiles, docker-compose files, reviewing container configurations, or addressing container security, networking, or secrets management.

## Pre-Container Checklist

- [ ] Multi-stage build used — no build tools in runtime image.
- [ ] Non-root user set in final stage.
- [ ] `.dockerignore` present and excludes dev files, secrets, and `.git`.
- [ ] Base image pinned to a specific digest or minor version, not `latest`.
- [ ] Image scanned with Trivy before push.
- [ ] No secrets or credentials baked into any layer.

## Process

### 1. Multi-Stage Builds

The pattern: **builder** installs toolchain and compiles; **runtime** copies only the artifact.

#### Node.js (TypeScript)

```dockerfile
# Dockerfile
# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependency manifests first — leverages layer cache
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

COPY tsconfig.json ./
COPY src ./src
RUN npm run build          # outputs to /app/dist

# Prune dev dependencies
RUN npm prune --omit=dev

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM node:22-alpine AS runtime

# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only production artifacts
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "dist/index.js"]
```

#### Go

```dockerfile
# Dockerfile
# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM golang:1.23-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
# CGO_ENABLED=0 produces a fully static binary — no libc dependency in runtime
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server ./cmd/server

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM scratch AS runtime
# 'scratch' has no shell, no package manager — minimal attack surface

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/server /server

# Non-root via numeric UID (scratch has no useradd)
USER 65532:65532

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/server", "healthcheck"]

ENTRYPOINT ["/server"]
```

#### Python (FastAPI)

```dockerfile
# Dockerfile
# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock ./
RUN uv pip install --system --no-dev -r pyproject.toml

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder --chown=appuser:appgroup /usr/local/bin /usr/local/bin
COPY --chown=appuser:appgroup src ./src

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### 2. Non-Root User and Read-Only Filesystem

```dockerfile
# Add user
RUN addgroup -S app && adduser -S app -G app
USER app

# Read-only filesystem — mount writable paths explicitly as tmpfs
# In docker run:
docker run --read-only \
  --tmpfs /tmp \
  --tmpfs /run \
  my-image
```

```yaml
# In docker-compose.yml
services:
  api:
    image: my-image
    read_only: true
    tmpfs:
      - /tmp
      - /run
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE   # only if binding to port < 1024
```

### 3. .dockerignore

```
# .dockerignore
.git
.gitignore
.env
.env.*
*.md
node_modules
dist
coverage
.nyc_output
__pycache__
*.pyc
*.pyo
.pytest_cache
.mypy_cache
.ruff_cache
.vscode
.idea
Dockerfile*
docker-compose*
docs
tests
```

### 4. Docker Compose Best Practices

```yaml
# docker-compose.yml — production-ready example
version: "3.9"

services:
  api:
    image: ghcr.io/org/api:${IMAGE_TAG:-latest}
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    environment:
      - APP_VERSION=${IMAGE_TAG}
      # Secrets are injected — not hardcoded
    env_file:
      - .env.production       # never committed; populated by CI or Vault
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy   # waits for DB health check, not just container start
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      start_period: 15s
      retries: 3
    networks:
      - backend
    volumes:
      - uploads:/app/uploads     # named volume — not bind mount

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB:       ${POSTGRES_DB}
      POSTGRES_USER:     ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --save 60 1 --loglevel warning
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - backend

networks:
  backend:
    driver: bridge

volumes:
  pgdata:
  redisdata:
  uploads:
```

### 5. Networking: Bridge vs Host

| Mode | Isolation | Use Case | Avoid When |
|------|-----------|----------|------------|
| `bridge` (default) | Full — containers use virtual NICs | All multi-container apps | Never for production inter-service comms on host |
| `host` | None — shares host network stack | High-throughput, low-latency requirements | Security is a concern |
| `overlay` | Cross-host, encrypted | Docker Swarm / multi-node | Single-host deployments |
| `none` | Completely isolated | Batch jobs, build containers | Service needs network access |

```yaml
# Custom bridge network — explicit subnet
networks:
  backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 6. Named Volumes vs Bind Mounts

| | Named Volume | Bind Mount |
|---|---|---|
| Managed by Docker | Yes | No |
| Portable | Yes | No (path is host-specific) |
| Use for | Persistent data (DB, uploads) | Dev hot-reload, config injection |
| Production safe | Yes | Avoid for data |

```bash
# Create a named volume
docker volume create pgdata

# Inspect
docker volume inspect pgdata

# Backup a named volume
docker run --rm \
  -v pgdata:/source:ro \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/pgdata-$(date +%Y%m%d).tar.gz -C /source .
```

### 7. Secrets Management

| Method | When to Use |
|--------|-------------|
| `.env` file (never committed) | Local dev only |
| `docker secret` (Swarm) | Docker Swarm production |
| Kubernetes Secrets + secretRef | Kubernetes production |
| AWS Secrets Manager / Vault | Multi-service, rotation required |

```bash
# Docker Swarm secrets
echo "supersecretpassword" | docker secret create db_password -

# Use in Swarm service
docker service create \
  --secret db_password \
  --env POSTGRES_PASSWORD_FILE=/run/secrets/db_password \
  myapp
```

```yaml
# docker-compose.yml — using Docker secrets (Swarm mode)
secrets:
  db_password:
    external: true

services:
  api:
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
```

```bash
# Application reads secret from file (not env var) — prevents accidental logging
DB_PASSWORD=$(cat /run/secrets/db_password)
```

### 8. Image Scanning with Trivy

```bash
# Install
brew install trivy        # macOS
apt install trivy         # Debian/Ubuntu

# Scan a local image
trivy image my-image:latest

# Fail on CRITICAL/HIGH only
trivy image --severity CRITICAL,HIGH --exit-code 1 my-image:latest

# Scan filesystem (in CI before build)
trivy fs --security-checks vuln,secret --exit-code 1 .

# Scan a remote image from registry
trivy image ghcr.io/org/api:abc123

# Output as JSON for further processing
trivy image -f json -o results.json my-image:latest
```

```yaml
# GitHub Actions integration
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE }}:${{ env.TAG }}
    format: table
    severity: CRITICAL,HIGH
    exit-code: '1'
```

### 9. Base Image Selection

| Type | Image | Size | Security |
|------|-------|------|----------|
| Node | `node:22-alpine` | ~180 MB | Good — musl libc |
| Python | `python:3.12-slim` | ~130 MB | Good — minimal Debian |
| Go | `scratch` | ~0 MB | Best — no OS |
| Java | `eclipse-temurin:21-jre-alpine` | ~200 MB | Good |
| Generic | `cgr.dev/chainguard/static` | ~3 MB | Best — sigstore signed |

Always pin to a specific minor version + digest:

```dockerfile
# Bad
FROM node:latest
FROM python:3

# Good
FROM node:22.4-alpine
FROM python:3.12-slim

# Best (immutable — digest never changes)
FROM node:22.4-alpine@sha256:abc123...
```

## Anti-Patterns

- **Never run as root in production containers** — any process exploit gives host root access.
- **Never use `ADD` with remote URLs** — use `COPY` for local files, `curl` explicitly for remote.
- **Never copy `.env` or credentials into the image** — they are visible in `docker history`.
- **Never use `docker-compose up` in production without explicit `--no-deps` awareness** — use orchestration (k8s, Swarm) for production.
- **Never use `depends_on` without `condition: service_healthy`** — the default only waits for container start, not readiness.
- **Never store database data in a bind mount in production** — named volumes only.
- **Never use `network_mode: host` unless you have a measurable performance requirement and accept the security trade-off.**

## Safe Behavior

- Read-only analysis of Dockerfiles and compose files.
- Flags root user, missing health checks, missing .dockerignore, secrets in ENV layers.
- Flags `latest` tag usage in production compose files.
- CRITICAL findings (root user, secrets in image, no health check) require Ahmed's attention.
- Does not push images or modify running containers autonomously.
