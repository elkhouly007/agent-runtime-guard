---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Perl + ARG Hooks

Perl-specific ARG hook considerations.

## CPAN and Package Operations

Commands that may trigger ARG:
- `cpan install Module::Name` or `cpanm Module::Name`: installs third-party code
- `cpanm --installdeps .`: resolves and installs all dependencies
- Makefile.PL or Build.PL execution during install can run arbitrary Perl

## File and Process Operations

Perl one-liners with system effects:
- `perl -i -pe 's/old/new/g' file`: in-place file editing
- `perl -e 'unlink glob "*.tmp"'`: file deletion
- Scripts using `system()`, `exec()`, or backtick operators

## DBI and Database Connections

- Scripts executing schema migrations via DBI
- `perl script.pl` that drops or truncates tables
- Bulk updates or deletes via DBI

## Secrets in Perl Projects

Common locations:
- Hardcoded credentials in `DBI->connect()` calls
- `.env` files loaded via `Dotenv` modules
- Config files (`.conf`, `.ini`, `.yaml`) with database passwords

## CGI and Web Scripts

Legacy CGI scripts may:
- Execute shell commands based on form input (high injection risk)
- Write to filesystem paths derived from URL parameters
- Use `eval` on user-supplied data

ARG will flag `system()`, `exec()`, and backtick usage in scripts that appear to process external input.
