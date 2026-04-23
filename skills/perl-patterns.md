# Skill: perl-patterns

## Purpose

Apply modern Perl best practices — strict mode, error handling, OOP with Moose/Moo, testing with Test2, and safe system interaction for Perl scripts and modules.

## Trigger

- Writing or reviewing Perl scripts or modules
- Modernizing legacy Perl code
- Asked about Perl patterns, CPAN modules, or system scripting in Perl

## Trigger

`/perl-patterns` or `apply perl patterns to [target]`

## Agents

- `code-reviewer` — general code quality

## Foundations — Always Use

```perl
#!/usr/bin/env perl
use strict;        # enforce variable declaration
use warnings;      # catch common mistakes
use utf8;          # source is UTF-8
use open ':std', ':encoding(UTF-8)';  # handle Unicode I/O correctly
use feature 'say'; # say = print + newline
```

- Never write Perl without `use strict; use warnings;` — it enables critical safety checks.

## Error Handling

```perl
# die with a hashref for structured errors
use Carp qw(croak confess);

sub read_config {
    my ($path) = @_;
    open my $fh, '<', $path or croak "Cannot open $path: $!";
    # ...
}

# eval for exception catching
my $result = eval { risky_operation() };
if (my $err = $@) {
    warn "Operation failed: $err";
}
```

- Use `croak` (caller's perspective) instead of `die` in library code.
- Use `confess` for stack traces during debugging.
- Always check return values of system calls (`open`, `close`, `rename`).

## OOP with Moo

```perl
package Order;
use Moo;
use Types::Standard qw(Str Int);

has product_id => (is => 'ro', isa => Str, required => 1);
has quantity   => (is => 'ro', isa => Int, required => 1);

sub total_price {
    my ($self) = @_;
    return $self->quantity * get_price($self->product_id);
}

1;
```

- Use `Moo` for new code (lighter than `Moose`), `Moose` for complex type systems.
- Use `Types::Standard` for type constraints on attributes.
- Always end modules with `1;`.

## File and System Operations

```perl
# Safe file read
use Path::Tiny;
my $content = path($filename)->slurp_utf8;

# Safe temp files
use File::Temp qw(tempfile);
my ($fh, $tmpfile) = tempfile(UNLINK => 1);

# System commands — use List::Util or IPC::Run, not backticks
use IPC::Run qw(run);
run ['git', 'status'], \my $out, \my $err;
```

- Never use backticks with user input — use `IPC::Run` or `IPC::Open3`.
- Use `Path::Tiny` for file operations — cleaner than manual `open/close`.

## Regular Expressions

```perl
# Use named captures for readability
if ($line =~ /^(?<level>ERROR|WARN)\s+(?<msg>.+)$/) {
    say "$+{level}: $+{msg}";
}

# Use /x for complex patterns
my $date_re = qr/
    (?<year>  \d{4}) -
    (?<month> \d{2}) -
    (?<day>   \d{2})
/x;
```

## Testing with Test2

```perl
use Test2::V0;

subtest 'order creation' => sub {
    my $order = Order->new(product_id => 'p1', quantity => 2);
    is($order->product_id, 'p1', 'product_id set correctly');
    is($order->quantity, 2, 'quantity set correctly');
};

done_testing;
```

- Use `Test2::V0` for new tests — modern, better diagnostics than `Test::More`.
- Always end test files with `done_testing` or a plan.

## CPAN Dependency Management

```bash
# Use cpanfile for declaring dependencies
requires 'Moo', '>= 2.004';
requires 'Path::Tiny', '>= 0.144';
on test => sub { requires 'Test2::V0'; };

# Install with carton for reproducible builds
carton install
```

## Safe Behavior

- Analysis only unless asked to modify code.
- Shell command patterns use list form (`system LIST`) to avoid shell injection.
