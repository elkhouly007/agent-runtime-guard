---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Perl Design Patterns

Perl-specific patterns for clean, maintainable code.

## Moo/Moose OOP

Prefer Moo for lightweight OOP, Moose for full metaprogramming:

```perl
package MyApp::User;
use Moo;
use Types::Standard qw(Str Int);

has id    => (is => 'ro', isa => Int, required => 1);
has name  => (is => 'ro', isa => Str, required => 1);
has email => (is => 'rw', isa => Str);

sub display_name { "User #" . $_[0]->id . ": " . $_[0]->name }
```

## Role-Based Composition

```perl
package MyApp::Role::Timestamped;
use Moo::Role;

has created_at => (is => 'ro', default => sub { time() });
has updated_at => (is => 'rw');

around save => sub {
    my ($orig, $self, @args) = @_;
    $self->updated_at(time());
    $self->$orig(@args);
};

package MyApp::Post;
use Moo;
with 'MyApp::Role::Timestamped';
```

## Repository Pattern

Isolate data access:

```perl
package MyApp::Repository::User;
use Moo;

has dbh => (is => 'ro', required => 1);

sub find_by_id {
    my ($self, $id) = @_;
    my $sth = $self->dbh->prepare("SELECT * FROM users WHERE id = ?");
    $sth->execute($id);
    return $sth->fetchrow_hashref;
}
```

## Dispatch Tables

Replace long if-elsif chains:

```perl
my %handlers = (
    create => \&_handle_create,
    update => \&_handle_update,
    delete => \&_handle_delete,
);

my $handler = $handlers{$action} or die "Unknown action: $action";
$handler->($self, $params);
```

## Iterator Pattern

```perl
sub each_user {
    my ($self, $cb) = @_;
    my $sth = $self->dbh->prepare("SELECT * FROM users");
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        $cb->($row);
    }
}
```
