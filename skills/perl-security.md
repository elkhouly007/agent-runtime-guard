# Skill: Perl Security

## Trigger

Use when:
- Writing Perl code that handles user input, files, or shell commands
- Auditing Perl scripts for injection vulnerabilities
- Enabling taint mode or adding input validation
- Reviewing database queries for parameterization
- Assessing CPAN module security

## Process

### 1. Taint mode (-T flag)

Taint mode marks all external input as "tainted" — untrusted data that cannot flow into dangerous operations without explicit sanitization.

```perl
#!/usr/bin/perl -T
use strict;
use warnings;

# Taint mode is enabled: all input from @ARGV, %ENV, STDIN is tainted
# Any tainted value used in a shell command, file path, or eval will die

my $input = $ARGV[0] // '';  # tainted

# Untaint by matching against a whitelist regex
# The captured group ($1) is untainted
my ($safe_input) = $input =~ /\A([A-Za-z0-9_\-]{1,64})\z/
    or die "Invalid input: only [A-Za-z0-9_-] allowed\n";

# $safe_input is now untainted and safe to use
open my $fh, '<', "/var/data/$safe_input.txt"
    or die "Cannot open file: $!\n";
```

### 2. Safe I/O — 3-argument open

Always use the 3-argument form of `open`. The 1- and 2-argument forms are shell-injection vectors.

```perl
use strict;
use warnings;
use autodie qw(:file);  # turns open/close failures into exceptions

# Bad — 2-arg open: if $path starts with '|', it becomes a pipe command
open my $fh, $path;          # NEVER do this
open my $fh, ">$filename";   # NEVER do this

# Good — 3-arg open: mode and path are separate
open my $in,  '<',  $filename  or die "open read: $!";
open my $out, '>',  $filename  or die "open write: $!";
open my $app, '>>', $filename  or die "open append: $!";

# Binary files — prevent encoding issues
open my $bin, '<:raw', $filename or die "open binary: $!";

# UTF-8 I/O
open my $utf, '<:encoding(UTF-8)', $filename or die "open utf8: $!";

# In-memory file (no disk access)
open my $mem, '<', \$scalar_data or die "open scalar: $!";
```

### 3. Avoiding shell injection — system list form

```perl
use strict;
use warnings;

my $user_input = $ARGV[0];  # untrusted

# Bad — string form of system/exec: shell interprets metacharacters
system("ls -la $user_input");          # shell injection if $user_input = "; rm -rf /"
system("grep $pattern /var/log/app");  # NEVER

# Good — list form: no shell involved, arguments passed directly to execvp
system('ls', '-la', $user_input);      # safe — no shell
exec('grep', $pattern, '/var/log/app') or die "exec failed: $!";

# Backticks — avoid; use IPC::Run or IPC::Open3 for subprocess I/O
use IPC::Run qw(run capture);

my ($stdout, $stderr);
run(['ls', '-la', $safe_dir], '>', \$stdout, '2>', \$stderr)
    or die "command failed: $stderr";

# open with pipe — safe when using list form via open3
use IPC::Open3;
my $pid = open3(\*STDIN, \*STDOUT, \*STDERR, 'ls', '-la', $safe_dir);
```

### 4. Regex security — ReDoS prevention

```perl
# Vulnerable — exponential backtracking
# Input: "aaaaaaaaaaaaaaaa!" causes catastrophic backtracking
my $bad_re = qr/^(a+)+$/;   # NEVER — nested quantifiers on overlapping patterns

# Safe alternatives:
# 1. Possessive quantifiers (requires Perl 5.10+)
my $safe_re = qr/^(a++)+$/;  # possessive — no backtracking

# 2. Atomic groups
my $atomic = qr/^(?>a+)+$/;  # atomic group — no backtracking

# 3. Limit input length before matching
sub safe_match {
    my ($input, $pattern) = @_;
    return 0 if length($input) > 1000;  # deny oversized input
    return $input =~ $pattern;
}

# 4. Use \A and \z (anchors) — avoid $ which allows \n before end
my $email_re = qr/\A[a-zA-Z0-9._%+\-]+\@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}\z/;

# Timeout-based defense (Perl 5.14+)
use Time::HiRes qw(alarm);
eval {
    local $SIG{ALRM} = sub { die "regex timeout\n" };
    alarm(0.1);  # 100ms timeout
    $input =~ $complex_pattern;
    alarm(0);
};
die "regex took too long\n" if $@ eq "regex timeout\n";
```

### 5. DBI parameterized queries

```perl
use DBI;
use strict;
use warnings;

my $dbh = DBI->connect(
    "dbi:Pg:dbname=mydb;host=localhost",
    $user, $pass,
    {
        RaiseError     => 1,
        AutoCommit     => 1,
        pg_enable_utf8 => 1,
    }
) or die DBI->errstr;

# Bad — string interpolation = SQL injection
my $id = $ARGV[0];
my $sth = $dbh->prepare("SELECT * FROM users WHERE id = $id");   # NEVER

# Good — placeholders; values bound separately
my $sth = $dbh->prepare("SELECT id, email FROM users WHERE id = ?");
$sth->execute($id);
my $row = $sth->fetchrow_hashref;

# Named placeholders (DBD::Pg supports $1, $2 style)
my $sth = $dbh->prepare(
    "INSERT INTO orders (user_id, amount) VALUES (?, ?) RETURNING id"
);
$sth->execute($user_id, $amount);
my ($order_id) = $sth->fetchrow_array;

# Batch operations with execute_array
my $sth = $dbh->prepare("INSERT INTO tags (name) VALUES (?)");
$sth->execute_array({}, \@tag_names);

# Transactions
$dbh->begin_work;
eval {
    $dbh->do("UPDATE accounts SET balance = balance - ? WHERE id = ?",
             undef, $amount, $from_id);
    $dbh->do("UPDATE accounts SET balance = balance + ? WHERE id = ?",
             undef, $amount, $to_id);
    $dbh->commit;
};
if ($@) {
    $dbh->rollback;
    die "Transaction failed: $@";
}
```

### 6. Input validation patterns

```perl
use Scalar::Util qw(looks_like_number);

# Whitelist validation — accept only known-good
sub validate_username {
    my ($name) = @_;
    die "username too long\n"   if length($name) > 64;
    die "invalid username\n"    unless $name =~ /\A[A-Za-z0-9_\-]{3,64}\z/;
    return $name;
}

# Numeric validation
sub validate_amount {
    my ($val) = @_;
    die "not a number\n"       unless looks_like_number($val);
    die "amount out of range\n" unless $val > 0 && $val <= 1_000_000;
    return $val + 0;  # numify
}

# Email validation (basic — use Email::Valid for production)
use Email::Valid;
sub validate_email {
    my ($email) = @_;
    my $valid = Email::Valid->address($email)
        or die "invalid email address\n";
    return lc $valid;
}

# Path traversal prevention
sub safe_path {
    my ($base, $filename) = @_;
    # Strip any path components
    ($filename) = $filename =~ /\A([A-Za-z0-9_\-\.]{1,128})\z/
        or die "invalid filename\n";
    die "invalid extension\n" unless $filename =~ /\.(txt|csv|json)\z/;
    return "$base/$filename";
}
```

### 7. use strict / use warnings enforcement

```perl
#!/usr/bin/perl
use strict;       # requires variable declaration; prevents typos becoming globals
use warnings;     # enables all runtime warnings
use 5.036;        # Perl 5.36+ — also enables strict and warnings by default

# Perl 5.36+ modern preamble (replaces strict + warnings)
use v5.36;
use utf8;                   # source is UTF-8
use open ':std', ':utf8';   # I/O defaults to UTF-8

# Recommended for production scripts
use Carp qw(croak confess carp cluck);  # stack-trace-aware errors
use Scalar::Util qw(blessed looks_like_number weaken);
use List::Util qw(any all none first reduce sum0 max min);
```

### 8. Module security — CPAN audit

```bash
# Audit installed CPAN modules for known CVEs
cpan-audit   # install: cpanm CPAN::Audit

# Scan current project deps
cpan-audit --installed

# Check specific distribution
cpan-audit Dist::Name

# Lock deps with Carton
carton install       # installs from cpanfile.snapshot
carton exec perl app.pl

# cpanfile — explicit version constraints
requires 'DBI',           '>= 1.643';
requires 'DBD::Pg',       '>= 3.16.0';
requires 'Crypt::Bcrypt', '>= 0.011';
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| 2-arg `open` with user input | Shell injection via pipe prefix | Always 3-arg open |
| String form `system("cmd $input")` | Shell injection | List form `system('cmd', $input)` |
| String interpolation in SQL | SQL injection | Placeholders + `execute($val)` |
| No taint mode on CGI/CLI scripts | User input flows unchecked | `-T` flag or explicit untainting |
| Nested quantifiers in regex | ReDoS | Possessive quantifiers or atomic groups |
| `eval "string"` with user data | Code injection | Never eval user strings |
| `die $msg` without newline | Appends file/line to message | `die "message\n"` |
| CPAN modules with no version pin | Silent upgrades with breaking changes | Pin versions in `cpanfile` |

## Safe Behavior

- All scripts handling input run under `-T` (taint mode).
- All `open` calls use 3-argument form; `autodie` is loaded for implicit error handling.
- All subprocess invocations use list form of `system`/`exec` or `IPC::Run`.
- All DB queries use DBI placeholders — no string interpolation in SQL.
- Input validation uses whitelist regex anchored with `\A` and `\z`.
- `use strict` + `use warnings` (or `use v5.36`) is mandatory in every file.
- CPAN deps are audited in CI with `cpan-audit` and locked with `Carton`.
