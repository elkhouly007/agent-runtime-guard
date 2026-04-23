# Perl Coding Style

Perl-specific standards for readable, maintainable code.

## Pragmas

Always use strict and warnings:

```perl
use strict;
use warnings;
use utf8;
use feature 'say';
```

## Naming

- Packages/modules: `UpperCamelCase` (`MyApp::UserService`)
- Subroutines and variables: `snake_case`
- Constants: `ALL_CAPS` via `use constant` or `Readonly`
- Private subs/vars: prefix with underscore `_helper()`

## File Structure

```perl
package MyApp::Service;

use strict;
use warnings;

use parent 'MyApp::Base';
use MyApp::Types qw(UserId);

# constants
use constant MAX_RETRIES => 3;

# public interface first, private below
sub new { ... }
sub process { ... }

sub _validate { ... }

1;  # module must return true
```

## Subroutines

- One responsibility per sub. Keep subs under 30 lines.
- Use named parameters via hash refs for subs with >2 args:

```perl
sub create_user {
    my ($self, %args) = @_;
    my $name  = $args{name}  // die "name required";
    my $email = $args{email} // die "email required";
}
```

## Error Handling

- `die` with an object or hashref for structured errors.
- `eval { ... } or do { ... }` for recovery.
- Never use bare `die "string"` in libraries — use objects.

```perl
eval {
    $self->_process($data);
} or do {
    my $err = $@;
    die MyApp::Error->new(message => "process failed: $err");
};
```

## Modern Perl

- Prefer `say` over `print` for line-terminated output.
- Use `//` (defined-or) instead of `||` for default values.
- List::Util, Scalar::Util, POSIX over hand-rolled utilities.
- Moose or Moo for OOP. Avoid manual `bless` in new code.
