# Skill: Perl Testing (Test2::V0)

## Trigger

Use when:
- Writing or reviewing Perl tests
- Migrating from Test::More to Test2::V0
- Setting up mocks, subtests, or coverage
- Configuring the `prove` runner or Carton-based test environments

## Process

### 1. Test2::V0 vs Test::More

| Feature | Test::More | Test2::V0 |
|---|---|---|
| Import style | `use Test::More tests => N` | `use Test2::V0` |
| Subtest isolation | `subtest` (works, limited) | `subtest` (full event isolation) |
| Exception testing | `eval {}; ok $@` | `dies_ok`, `lives_ok` |
| Mocking | Separate module | `Test2::Mock` built in |
| Output | TAP | TAP (same, compatible) |
| Diagnostics | Basic | Rich, structured |
| Plan | Required or `done_testing` | `done_testing` recommended |

```perl
# Test::More (old)
use Test::More tests => 3;
ok($x == 1, 'x is 1');
is($name, 'alice', 'name matches');
like($msg, qr/hello/, 'message contains hello');
done_testing;

# Test2::V0 (current)
use Test2::V0;

ok($x == 1,       'x is 1');
is($name, 'alice', 'name matches');
like($msg, qr/hello/, 'message contains hello');

done_testing;
```

### 2. Core assertion functions

```perl
use Test2::V0;

# ok — boolean assertion
ok(1,     'true value passes');
ok(0,     'false value fails');  # fail

# is — deep equality (uses Test2's deep comparison)
is($got, $expected, 'values are equal');
is(\@got, [1, 2, 3], 'array ref matches');
is(\%got, {a => 1}, 'hash ref matches');

# like — regex match
like($string, qr/pattern/, 'string matches pattern');

# unlike
unlike($string, qr/bad/, 'string does not match');

# is with deep structures
is(
    get_user(1),
    {
        id    => 1,
        email => 'alice@example.com',
        role  => 'admin',
    },
    'user data matches'
);

# isa_ok — object type
isa_ok($obj, 'My::Class', 'correct class');

# can_ok — method existence
can_ok($obj, 'total', 'item_count');

# cmp_ok — numeric/string comparisons
cmp_ok($count, '>', 0, 'count is positive');
cmp_ok($price, '==', 9.99, 'price matches');

done_testing;
```

### 3. dies_ok and lives_ok (exception testing)

```perl
use Test2::V0;

# Test that an exception is thrown
dies_ok { divide(10, 0) } 'dividing by zero dies';

# Test that no exception is thrown
lives_ok { divide(10, 2) } 'valid division lives';

# Test exception message
like(
    dies { divide(10, 0) },
    qr/division by zero/i,
    'error message mentions division by zero'
);

# Test specific exception class
isa_ok(
    dies { MyApp::InvalidInput->throw("bad data") },
    'MyApp::InvalidInput',
    'throws correct exception class'
);

# Test that exception has correct attributes
my $err = dies { parse_order('{}') };
isa_ok($err, 'MyApp::ValidationError');
is($err->field, 'id', 'error identifies missing field');

done_testing;
```

### 4. subtest

```perl
use Test2::V0;

subtest 'user registration' => sub {
    my $user = register_user('alice@example.com', 'secret');

    ok($user,                     'registration succeeded');
    is($user->{email}, 'alice@example.com', 'email stored');
    ok(length($user->{id}) > 0,  'id assigned');
    ok($user->{active},           'account is active');
};

subtest 'duplicate registration fails' => sub {
    register_user('bob@example.com', 'secret');

    my $err = dies { register_user('bob@example.com', 'other') };
    isa_ok($err, 'MyApp::DuplicateError', 'correct exception class');
    like($err->message, qr/already registered/i, 'message is clear');
};

# Nested subtests
subtest 'cart operations' => sub {
    my $cart = Cart->new;

    subtest 'adding items' => sub {
        $cart->add_item({sku => 'ABC', qty => 2, price => 10.0});
        is($cart->item_count, 1, 'one item in cart');
    };

    subtest 'total calculation' => sub {
        is($cart->total, 20.0, 'total is qty * price');
    };
};

done_testing;
```

### 5. Test2::Mock for mocking

```perl
use Test2::V0;
use Test2::Mock;

# Mock an entire class
my $mock = Test2::Mock->new(
    class => 'MyApp::EmailService',
);

my @sent;
$mock->override(
    send_email => sub {
        my ($self, %args) = @_;
        push @sent, \%args;
        return 1;
    },
);

# Run code that uses the mocked class
my $service = MyApp::UserService->new(
    email => MyApp::EmailService->new
);
$service->register('alice@example.com');

is(scalar @sent, 1, 'exactly one email sent');
is($sent[0]{to}, 'alice@example.com', 'email sent to correct address');
like($sent[0]{subject}, qr/welcome/i, 'welcome email sent');

# Override a specific method with die
$mock->override(
    send_email => sub { die "SMTP connection refused\n" },
);

my $err = dies { $service->register('bob@example.com') };
like($err, qr/SMTP/, 'propagates email error');

done_testing;
```

### 6. Test::MockModule — lightweight module mocking

```perl
use Test2::V0;
use Test::MockModule;

# Mock module functions without changing class hierarchy
my $mock = Test::MockModule->new('MyApp::HTTP');
$mock->mock('get', sub {
    my ($url) = @_;
    return { status => 200, body => '{"ok":true}' };
});

my $result = MyApp::API->fetch_status;
is($result->{ok}, 1, 'API returns ok status');

# Restore automatically when $mock goes out of scope

done_testing;
```

### 7. prove runner and Carton

```bash
# Run all tests
prove -lv t/

# Run specific file
prove -lv t/cart.t

# Run recursively
prove -lr t/

# Run with Carton (isolated CPAN deps)
carton exec prove -lr t/

# Parallel test execution
prove -j4 -lr t/

# TAP::Harness options
prove -lr --timer t/          # show timing per test file
prove -lr --failures t/       # show only failed tests
prove -lr --merge t/          # merge stdout/stderr

# From Makefile.PL / cpanfile project
perl Makefile.PL && make test
```

### 8. Devel::Cover for coverage

```bash
# Run tests with coverage collection
cover -test

# Or manually:
PERL5OPT=-MDevel::Cover prove -lr t/
cover                         # generate HTML report in cover_db/

# Summary in terminal
cover -report text

# Exclude files from coverage
cover -ignore_re '^t/' -ignore_re '^inc/'

# Fail if below threshold (CI script)
perl -MDevel::Cover=-silent,1 -e '
    my $db = Devel::Cover::DB->new(db => "cover_db");
    my $total = $db->summary("Total")->{total}{percentage};
    die "Coverage $total% is below 80%\n" if $total < 80;
'
```

```perl
# Mark uncoverable lines
my $x = expensive_debug_only();  ## no critic (Variables::ProhibitUnusedVariables)
# Devel::Cover respects: # uncoverable line / # uncoverable branch
```

## Test Naming Convention

| Bad | Good |
|-----|------|
| `test_order` | `'order total is zero for empty cart'` |
| `check_user` | `'register dies with duplicate email'` |
| `subtest 'user'` | `subtest 'new user gets welcome email'` |

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `ok($x == $y)` | No diagnostic on failure | `is($x, $y)` shows got/expected |
| `eval {} or fail` | Misses syntax errors | Use `dies { }` from Test2::V0 |
| `use Test::More` in new code | Less capable, harder to extend | Migrate to `Test2::V0` |
| Shared mutable state across subtests | Test order dependency | Initialize fresh state in each subtest |
| No `done_testing` | Plan mismatch silent | Always end with `done_testing` |
| Hardcoded file paths in tests | Breaks on other machines | Use `File::Temp` or `tmp_path` equivalent |

## Safe Behavior

- Every `.t` file uses `use Test2::V0` and ends with `done_testing`.
- Mocks are scoped to the test or subtest — never leak globally.
- `prove -lr t/` runs in CI; failure exits non-zero.
- Devel::Cover runs weekly or on branches touching core logic.
- Exception tests use `dies { }` and `like($err, qr/.../)` — not bare `eval`.
- Carton is used to pin and isolate test dependencies.
