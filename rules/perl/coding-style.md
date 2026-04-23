---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Perl Coding Style

## Strict and Warnings

Every Perl file must start with:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
```

- `use strict` — prevents use of undeclared variables, symbolic references, and bareword strings.
- `use warnings` — surfaces potential bugs (uninitialized values, deprecated features).
- Never disable strict or warnings to silence errors — fix the underlying issue.
- For Perl 5.10+: add `use feature ':5.10';` or `use v5.10;` for modern features.

## Variable Naming

```perl
# Scalars — $lowercase or $camelCase
my $user_name = 'Alice';
my $maxRetries = 3;

# Arrays — @plural_nouns
my @order_ids = (1, 2, 3);
my @users     = ();

# Hashes — %noun_phrase
my %config = (host => 'localhost', port => 5432);
my %user_by_id = ();

# Constants — use Readonly or constant pragma
use constant MAX_SIZE => 1024;
use Readonly;
Readonly my $API_ENDPOINT => 'https://api.example.com';

# Subroutines — snake_case
sub get_user_by_id { ... }
sub send_welcome_email { ... }
```

## Subroutines

```perl
# Declare all subs before use, or at the top of the file
sub process_order {
    my ($order_id, $options) = @_;   # explicit parameter extraction — not using @_ directly

    # Validate inputs
    die "order_id required" unless defined $order_id;

    # Default options
    $options //= {};
    my $dry_run = $options->{dry_run} // 0;

    # ... logic

    return $result;  # always explicit return
}

# Named parameters via hash ref (for 3+ params)
sub create_user {
    my ($args) = @_;
    my $email  = $args->{email}  // die "email required";
    my $role   = $args->{role}   // 'user';
    my $active = $args->{active} // 1;
    # ...
}
```

- Always extract `@_` explicitly at the start of subroutines — never use `$_[0]` directly in logic.
- Use `//` (defined-or) not `||` for defaults — `||` is false-based and fails for `0` or `""`.
- Always `return` explicitly — do not rely on implicit last-expression return for non-trivial subs.

## References and Data Structures

```perl
# Array ref
my $colors = ['red', 'green', 'blue'];
push @$colors, 'yellow';
my $first = $colors->[0];

# Hash ref
my $user = { id => 1, email => 'alice@example.com' };
$user->{role} = 'admin';
my $email = $user->{email};

# Nested structures
my $config = {
    database => {
        host => 'localhost',
        port => 5432,
    },
    redis => {
        url => 'redis://localhost:6379',
    },
};
my $db_host = $config->{database}{host};
```

## Modern Perl Features (5.10+)

```perl
# say — like print but adds newline
use feature 'say';
say "Hello, $name";

# given/when (switch) — 5.10+, but use if/elsif in new code (given/when deprecated)
# Use if chains instead

# Defined-or
my $value = $input // 'default';

# State variables (for sub-level persistence)
use feature 'state';
sub counter {
    state $count = 0;
    return ++$count;
}
```

## Error Handling

```perl
# die/eval pattern
eval {
    process_order($id);
};
if (my $error = $@) {
    warn "Failed to process order $id: $error";
    # handle or rethrow
}

# Modern: use Try::Tiny (CPAN)
use Try::Tiny;
try {
    process_order($id);
} catch {
    warn "Error: $_";
};
```

## File Organization

```perl
package MyApp::Services::UserService;

use strict;
use warnings;
use parent 'MyApp::BaseService';

# Constructor
sub new {
    my ($class, %args) = @_;
    return bless {
        _repository => $args{repository} // die "repository required",
    }, $class;
}

# Public methods first
sub find_active { ... }
sub create      { ... }

# Private methods at bottom (convention: _prefix)
sub _validate_email { ... }

1;  # Module must return true
```

- One package per file.
- File path must match package name: `MyApp::Services::UserService` → `lib/MyApp/Services/UserService.pm`.
- Always end module files with `1;`.

## Formatting

- 4-space indentation.
- Align hash arrows (`=>`) and assignment operators in blocks for readability.
- Closing brace on its own line for multi-line blocks.
- Use `perltidy` with a project-level `.perltidyrc` for consistent auto-formatting.
