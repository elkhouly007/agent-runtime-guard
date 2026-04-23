---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Go + ARG Hooks

Go-specific ARG hook considerations.

## Build Commands

Go build commands that may trigger ARG dangerous-command-gate:
- `go generate` runs arbitrary commands defined in `//go:generate` directives — ensure these are reviewed
- `cgo` compilation that invokes C compilers is safe but note that ARG may flag unusual compiler flags
- `go install` from unverified module paths downloads and installs code

## Module Security

- `go mod download` from unknown sources: ARG's network-aware policy may flag this in high-security contexts
- `replace` directives in go.mod that point to local paths should be reviewed — they bypass module authentication
- `GONOSUMCHECK` and `GONOSUMDB` bypass checksum verification. Document any use.

## Secrets in Go Projects

Go projects often have secrets in:
- `.env` files loaded by `godotenv`
- `config.yaml` files with database connection strings
- `*.pem` files with private keys

ARG `secret-warning.js` will intercept these if they appear in Bash tool calls. Store them outside the repository and reference by environment variable.

## Go-Specific Shell Safety

When Go code generates shell commands (for CI, tooling, etc.):
- Use `os/exec` with explicit argument lists, not shell strings
- When writing Makefile targets or shell scripts in a Go project, apply the same ARG hook considerations as any bash script
- `go run ./scripts/myscript.go` is safer than shell scripts for complex project tooling
