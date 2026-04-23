---
last_reviewed: 2026-04-20
version_target: "Perl 5.36+, Test2::Suite, prove"
upstream_ref: "source-README.md"
---

# Perl Testing

## Test Pyramid

Follow the **70/20/10** split: 70% unit, 20% integration, 10% end-to-end.

## Test2 Suite (Modern Standard)

```perl
use Test2::V0;   # replaces Test::More, Test::Exception, Test::Deep

# Assertions
is($got, $expected,     'scalar equality');
like($string, qr/pattern/, 'regex match');
ok($condition,          'boolean check');
is($ref, {key => 'val'},'deep structure');

# Exception testing
like(
    dies { dangerous_operation() },
    qr/expected error/,
    'throws expected error'
);

ok(lives { safe_operation() }, 'does not throw');

# Numeric comparisons
is($count, 5,    'exact count');
ok($count > 0,   'positive count');

done_testing;
```

## Test::More (Legacy — still common)

```perl
use strict;
use warnings;
use Test::More tests => 5;    # or: use Test::More; ... done_testing;
use Test::Exception;
use Test::Deep;

ok(defined $obj,          'object created');
is($obj->name, 'Alice',   'name accessor');
isa_ok($obj, 'My::Class', 'correct class');

# Deep structure
cmp_deeply(
    $result,
    { status => 'ok', count => 42 },
    'response structure matches'
);

# Exceptions
throws_ok { $obj->risky_method } qr/invalid input/, 'throws on bad input';
lives_ok  { $obj->safe_method  }                    'no exception on valid input';

done_testing;
```

## Test Organization

```
t/
  unit/
    01-user.t
    02-order.t
  integration/
    10-database.t
    11-api.t
  fixtures/
    test_data.json
lib/
  My/Module.pm
```

```perl
# t/unit/01-user.t
use strict;
use warnings;
use Test2::V0;
use My::User;

subtest 'creation' => sub {
    my $user = My::User->new(name => 'Alice', email => 'alice@example.com');
    ok(defined $user, 'user created');
    is($user->name,  'Alice',              'name set');
    is($user->email, 'alice@example.com',  'email set');
};

subtest 'validation' => sub {
    like(
        dies { My::User->new(name => '', email => 'x@y.com') },
        qr/name is required/,
        'rejects empty name'
    );
};

done_testing;
```

## Mocking with Test::MockObject / Test::MockModule

```perl
use Test::MockModule;

# Mock a module method
my $mock = Test::MockModule->new('External::API');
$mock->mock('fetch', sub { return { status => 'ok', data => [1,2,3] } });

# Test code that calls External::API->fetch
my $result = My::Service->process();
is($result->{count}, 3, 'processes 3 items');

# Mock is scoped — restored when $mock goes out of scope
```

## Database Testing

```perl
# Use a test database / in-memory SQLite for unit tests
use DBI;
my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
$dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO users VALUES (1, "Alice")');

my $sth = $dbh->prepare('SELECT name FROM users WHERE id = ?');
$sth->execute(1);
my ($name) = $sth->fetchrow_array;
is($name, 'Alice', 'database round-trip');
```

## Coverage

```perl
# Run with Devel::Cover
cover -delete
PERL5OPT="-MDevel::Cover" prove -r t/
cover
# Generates cover_db/coverage.html — open in browser

# Or via test harness
perl Makefile.PL
make test TEST_VERBOSE=1

# Quick coverage summary
cover -report text
```

Target coverage: **≥ 80%** for new code, **100%** for security-critical modules.

## Tooling Commands

```bash
# Run all tests
prove -r t/

# Run with verbose output
prove -rv t/

# Run single test file
perl -Ilib t/unit/01-user.t

# Run with coverage
PERL5OPT="-MDevel::Cover" prove -r t/ && cover

# Check test count
find t/ -name '*.t' | wc -l

# Static analysis alongside tests
perlcritic --severity 3 lib/
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `use Test::More tests => N` (hardcoded) | Plan drift as tests change | Use `done_testing` |
| No `dies`/`lives` checks | Exceptions silently caught | `Test2::V0` `dies {}` |
| Hitting production DB in unit tests | Slow, flaky, destructive | SQLite in-memory or fixtures |
| Global state between test files | Test order dependency | Reset state in `setup`/`teardown` |
| Testing implementation not behavior | Brittle tests | Test public interface only |
| No coverage gate in CI | Uncovered regressions | `cover -report text` + threshold |
