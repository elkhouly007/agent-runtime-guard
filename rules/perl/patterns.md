---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Perl Patterns

## CPAN Module Usage

```perl
# Prefer CPAN modules over reinventing common patterns
use HTTP::Tiny;         # lightweight HTTP client
use JSON::XS;           # fast JSON encode/decode
use DBI;                # database interface
use Moose;              # OOP framework
use Moo;                # lighter Moose alternative
use Try::Tiny;          # safe error handling
use Path::Tiny;         # file/path operations
use List::Util qw(first reduce any all none max min sum);
use Scalar::Util qw(looks_like_number blessed reftype weaken);
```

Use `cpanfile` or `META.json` to declare dependencies — install with `cpanm` or `carton`.

## Object-Oriented Perl (Moo/Moose)

```perl
# Moo — lightweight, modern OOP (preferred for new code)
package User;
use Moo;
use Types::Standard qw(Str Int Bool);

has id    => (is => 'ro',  isa => Int,  required => 1);
has email => (is => 'rw',  isa => Str,  required => 1);
has role  => (is => 'rw',  isa => Str,  default  => sub { 'user' });
has active => (is => 'rw', isa => Bool, default  => sub { 1 });

sub is_admin {
    my ($self) = @_;
    return $self->role eq 'admin';
}

1;

# Usage
my $user = User->new(id => 1, email => 'alice@example.com');
$user->role('admin');
say $user->is_admin ? "Admin" : "User";
```

- `is => 'ro'` — read-only, set at construction
- `is => 'rw'` — read-write, mutable
- `is => 'lazy'` — computed on first access via `_build_<name>` method
- Use `Types::Standard` for type constraints

## File I/O

```perl
use Path::Tiny;

# Read file
my $content = path('data.txt')->slurp_utf8;

# Read lines
my @lines = path('data.txt')->lines_utf8({ chomp => 1 });

# Write file
path('output.txt')->spew_utf8("content here\n");

# Append
path('log.txt')->append_utf8("log line\n");

# Iterate large files without loading all into memory
path('large.csv')->lines_utf8(sub {
    my $line = shift;
    chomp $line;
    process($line);
});
```

## Regular Expressions

```perl
# Named captures — self-documenting
if ($date =~ /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/) {
    say "Year: $+{year}, Month: $+{month}";
}

# Non-destructive substitution (Perl 5.14+)
my $clean = $text =~ s/\s+/ /gr;  # 'r' returns modified copy, doesn't change $text

# Global match into array
my @words = ($text =~ /(\w+)/g);

# Named regex with /x for readability
my $email_re = qr/
    \A                    # start of string
    [\w.+-]+              # local part
    @                     # at sign
    [\w-]+                # domain
    (?:\.[\w-]+)+         # TLD and subdomains
    \z                    # end of string
/x;
```

## Data Processing Patterns

```perl
use List::Util qw(grep map sort);

# Functional-style transforms
my @active_emails =
    map  { $_->{email} }
    grep { $_->{active} }
    @users;

# Sort by multiple criteria
my @sorted = sort {
    $a->{role}  cmp $b->{role} ||
    $a->{email} cmp $b->{email}
} @users;

# Hash slice — extract multiple keys
my @values = @config{qw(host port database)};

# Unique elements (order-preserving)
my %seen;
my @unique = grep { !$seen{$_}++ } @items;
```

## HTTP Client Pattern

```perl
use HTTP::Tiny;
use JSON::XS qw(decode_json encode_json);

my $http = HTTP::Tiny->new(
    timeout => 30,
    default_headers => {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer $ENV{API_TOKEN}",
    },
);

# GET
my $response = $http->get('https://api.example.com/users');
die "Request failed: $response->{status}" unless $response->{success};
my $data = decode_json($response->{content});

# POST
my $body = encode_json({ email => 'alice@example.com' });
my $res  = $http->post('https://api.example.com/users',
    { content => $body }
);
```

## Database Access (DBI)

```perl
use DBI;

my $dbh = DBI->connect(
    "dbi:Pg:dbname=$db;host=$host",
    $user, $password,
    { RaiseError => 1, AutoCommit => 1, pg_enable_utf8 => 1 }
);

# Prepared statement
my $sth = $dbh->prepare("SELECT * FROM users WHERE email = ?");
$sth->execute($email);
my $user = $sth->fetchrow_hashref;
$sth->finish;

# Transaction
$dbh->begin_work;
eval {
    $dbh->do("INSERT INTO orders ...", undef, @values);
    $dbh->do("UPDATE inventory ...", undef, @values);
    $dbh->commit;
};
if ($@) {
    $dbh->rollback;
    die "Transaction failed: $@";
}
```

## Security Patterns

```perl
# Taint mode — enables input validation for security-sensitive scripts
#!/usr/bin/perl -T
use strict;
use warnings;

# Untaint input after validation
my ($safe_id) = ($user_input =~ /\A(\d+)\z/)
    or die "Invalid ID";

# Never interpolate user input into shell commands
# BAD:
system("ls $user_dir");

# GOOD — list form of system (no shell expansion)
system('ls', $user_dir);

# GOOD — use IPC::Run for complex subprocesses
use IPC::Run qw(run);
run ['ls', $user_dir], \my $out, \my $err;
```
