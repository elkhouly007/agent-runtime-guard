# Perl Testing

Perl-specific testing standards.

## Framework

- `Test::More` for all unit tests.
- `Test::Exception` for testing die/croak behavior.
- `Test::MockObject` or `Test::MockModule` for mocking.
- `Plack::Test` or `Test::WWW::Mechanize` for web app testing.
- `prove` to run test suites; `App::Prove` for CI.

## File Layout

```
t/
  unit/
    user_service.t
    email_validator.t
  integration/
    database.t
  01-basic.t
```

## Test Structure

```perl
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use_ok('MyApp::Service');

my $svc = MyApp::Service->new();

ok($svc, 'service instantiates');

is($svc->process({ name => 'Alice' }), 'ok', 'processes valid input');

throws_ok { $svc->process({}) } qr/name required/, 'rejects missing name';

done_testing;
```

## Naming

- Test files: `snake_case.t`
- Descriptions: plain English — `'returns user when found'`
- Group related tests with `subtest`:

```perl
subtest 'validation' => sub {
    ok(validate('valid@email.com'), 'accepts valid email');
    ok(!validate('not-an-email'), 'rejects invalid email');
};
```

## Mocking

```perl
use Test::MockObject;

my $mock_db = Test::MockObject->new();
$mock_db->mock('find_user', sub { return { id => 1, name => 'Alice' } });

my $svc = MyApp::Service->new(db => $mock_db);
```

## Coverage

- `Devel::Cover` for code coverage. Run with `cover -test`.
- Target 80%+ statement coverage for business logic modules.
