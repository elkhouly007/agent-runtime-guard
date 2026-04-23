---
last_reviewed: 2026-04-20
version_target: "Perl 5.36+"
upstream_ref: "source-README.md"
---

# Perl Security

## Input Validation and Taint Mode

**Enable taint mode (`-T`) for any script that processes external input.**

```perl
#!/usr/bin/env perl -T
use strict;
use warnings;

# Taint mode marks all external data as tainted.
# Tainted data cannot be used in system calls, file ops, or evals without untainting.

# BAD — using external input directly in system call
my $file = $ENV{FILENAME};
system("cat $file");        # shell injection if FILENAME = "; rm -rf /"

# GOOD — validate and untaint first
my $file = $ENV{FILENAME} // '';
if ($file =~ /\A([\w.\/-]+)\z/) {   # allowlist: only safe characters
    my $safe_file = $1;             # $1 is untainted
    system('cat', $safe_file);      # list form — no shell interpolation
} else {
    die "Invalid filename\n";
}
```

## Shell Injection Prevention

```perl
# BAD — string form of system/exec: shell interprets metacharacters
system("ls $user_dir");
`rm -rf $path`;
open(my $fh, "| mail $address");

# GOOD — list form of system/exec: arguments passed directly to execvp
system('ls', $user_dir);
open(my $fh, '-|', 'mail', $address) or die "Cannot open: $!";

# BAD — open() with shell metacharacters
open(my $fh, "<$filename") or die;  # $filename = "| malicious_cmd"

# GOOD — three-argument open (safe, no shell)
open(my $fh, '<', $filename) or die "Cannot open $filename: $!";
open(my $fh, '>', $output)   or die "Cannot write $output: $!";
```

- Always use the **list form** of `system()`, `exec()`, and `open()` with shell commands.
- Never interpolate user input into shell strings or backtick operators.
- Use `IPC::Open3` or `Capture::Tiny` for complex subprocess interaction.

## SQL Injection

```perl
# BAD — string interpolation into SQL
my $sql = "SELECT * FROM users WHERE name = '$name'";
$dbh->do($sql);

# GOOD — DBI placeholders
my $sth = $dbh->prepare("SELECT * FROM users WHERE name = ?");
$sth->execute($name);

# GOOD — named placeholders (DBIx::Class / SQL::Abstract)
my @users = $schema->resultset('User')->search({ name => $name });
```

- Always use DBI placeholders (`?`) — never string interpolation.
- Use `RaiseError => 1` and `AutoCommit => 0` in DBI connection for proper error handling.
- Enable `taint` and DBI's `Taint => 1` option together for double protection.

## Cryptography

```perl
# BAD — MD5 or SHA1 for passwords
use Digest::MD5 qw(md5_hex);
my $hash = md5_hex($password);      # fast hash — trivially crackable

# GOOD — bcrypt via Crypt::Bcrypt or Crypt::Eksblowfish::Bcrypt
use Crypt::Bcrypt qw(bcrypt bcrypt_check);
my $hash = bcrypt($password, 12);   # cost factor 12
bcrypt_check($password, $hash) or die "Invalid password";

# BAD — rand() for security tokens (seeded, predictable)
my $token = join '', map { chr(65 + rand(26)) } 1..32;

# GOOD — cryptographically secure random via /dev/urandom
use Bytes::Random::Secure qw(random_bytes_hex);
my $token = random_bytes_hex(32);   # 256 bits of entropy
```

- Never use `MD5`, `SHA1`, or `crypt()` for password storage.
- Use `Crypt::Bcrypt` or `Argon2` (via `Crypt::Argon2`) with cost factor ≥ 12.
- Use `Bytes::Random::Secure` or `/dev/urandom` directly for tokens and nonces.

## Path Traversal

```perl
# BAD — user controls path: traversal via ../
my $file = "/var/app/uploads/" . $user_path;
open(my $fh, '<', $file) or die;   # $user_path = "../../etc/passwd"

# GOOD — canonicalize and validate stays within allowed root
use Cwd qw(realpath);
my $base  = realpath('/var/app/uploads') or die;
my $full  = realpath("$base/$user_path");
die "Path traversal detected\n" unless defined $full && index($full, $base) == 0;
open(my $fh, '<', $full) or die "Cannot open: $!";
```

## Session and Cookie Security

```perl
# BAD — CGI::Session with default settings
use CGI::Session;
my $session = CGI::Session->new();
print CGI::header(-cookie => $session->cookie("CGISESSID"));

# GOOD — secure cookie attributes
my $cookie = CGI::Cookie->new(
    -name     => 'session_id',
    -value    => $session->id,
    -httponly => 1,        # no JavaScript access
    -secure   => 1,        # HTTPS only
    -samesite => 'Strict', # CSRF protection
);
```

## Tooling Commands

```bash
# Static analysis for Perl security issues
perlcritic --severity 1 lib/
perl -MO=Deparse script.pl 2>&1 | grep -i 'system\|exec\|open'

# Check for taint mode usage
grep -rn '#!.*-T' bin/ scripts/

# Scan for SQL injection patterns
grep -rn 'do.*\$\|execute.*\$\|prepare.*\$' lib/ | grep -v '?'

# Dependency audit
cpan-outdated
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `system("cmd $var")` | Shell injection | List form: `system('cmd', $var)` |
| `open(FH, "<$file")` | Shell metachar injection | Three-arg open |
| SQL string interpolation | SQL injection | DBI placeholders (`?`) |
| `md5_hex($password)` | Trivial cracking | bcrypt cost ≥ 12 |
| `rand()` for tokens | Predictable tokens | `Bytes::Random::Secure` |
| No taint mode on CGI | Unvalidated external input | `#!/usr/bin/perl -T` |
| Path without `realpath` | Path traversal | `realpath` + prefix check |
