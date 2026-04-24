---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Perl Security

Perl-specific security rules.

## Taint Mode

Enable taint mode for scripts processing external input:

```perl
#!/usr/bin/perl -T
use strict;
use warnings;
```

Tainted data cannot be used in shell commands or file operations without explicit untainting via validated regex:

```perl
my ($safe_input) = $user_input =~ /^([a-zA-Z0-9_\-]+)$/
    or die "Invalid input";
```

## Shell Injection

- Never pass user input to `system()`, backticks, or `open()` with shell metacharacters.
- Use list form of `system()` to avoid shell interpolation:

```perl
# BAD
system("rm $user_file");

# GOOD
system('rm', '--', $safe_file);
```

- Use `IPC::Open3` or `Capture::Tiny` for subprocess control.

## SQL Injection

Use DBI with placeholders — never interpolate into SQL:

```perl
# BAD
$dbh->do("SELECT * FROM users WHERE id = $user_id");

# GOOD
my $sth = $dbh->prepare("SELECT * FROM users WHERE id = ?");
$sth->execute($user_id);
```

## File Handling

- Use `open(my $fh, '<', $file)` three-argument form always.
- Validate file paths before opening. Reject paths with `..` traversal.
- `File::Temp` for temporary files — do not construct temp names manually.

## Cryptography

- `Crypt::Sodium` or `Crypt::OpenSSL::*` for cryptographic operations.
- `Digest::SHA` for SHA-256/512 hashing. Not MD5 for security purposes.
- Generate random tokens with `/dev/urandom` via `Bytes::Random::Secure`.

## Secrets

- Never hardcode credentials in Perl scripts.
- Read from environment variables or a config file outside the web root.
- `Config::Tiny` or `Config::IniFiles` for structured config files.
