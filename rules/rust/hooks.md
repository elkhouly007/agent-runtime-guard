# Rust + ARG Hooks

Rust-specific ARG hook considerations.

## Build Commands

Rust build commands that may trigger ARG:
- `cargo build --release` with custom build scripts: build scripts execute arbitrary code at compile time
- `build.rs` files: read them before running `cargo build` on unfamiliar codebases — they can invoke shell commands
- `cargo install` from crates.io or git URLs: downloads and compiles code from the internet

## Unsafe Code Auditing

When working with unsafe Rust code via the Bash tool:
- `grep -r "unsafe"` to audit unsafe blocks before making changes
- Document why each unsafe block is sound before proceeding
- ARG does not currently parse Rust source — manual unsafe auditing is required

## Cargo.lock and Supply Chain

- `cargo audit` checks for vulnerabilities in dependencies
- Lockfile changes should be reviewed — they indicate dependency version changes
- `cargo-deny` for comprehensive policy enforcement on licenses and advisories

## Secrets in Rust Projects

Rust projects may have secrets in:
- `.cargo/credentials.toml` (registry authentication tokens)
- Environment variables read by `std::env::var()`
- Configuration files parsed by serde

ARG will intercept these if they appear in Bash tool call inputs. Store credentials outside the repository.
