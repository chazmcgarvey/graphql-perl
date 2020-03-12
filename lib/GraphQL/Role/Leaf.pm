package GraphQL::Role::Leaf;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Function::Parameters;
use Devel::StrictMode;
use Return::Type;
use Types::Standard -all;
use GraphQL::Debug qw(_debug);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::Role::Leaf - GraphQL "leaf" object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Leaf);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Leaf));

=head1 DESCRIPTION

Allows type constraints for leaf objects.

=cut

method _complete_value(
  (STRICT ? HashRef : Any) $context,
  (STRICT ? ArrayRef[HashRef] : Any) $nodes,
  (STRICT ? HashRef : Any) $info,
  (STRICT ? ArrayRef : Any) $path,
  Any $result,
) {
  DEBUG and _debug('Leaf._complete_value', $self->to_string, $result);
  my $serialised = $self->perl_to_graphql($result);
  die GraphQL::Error->new(message => "Expected a value of type '@{[$self->to_string]}' but received: '$result'.\n$@") if $@;
  +{ data => $serialised };
}

__PACKAGE__->meta->make_immutable();

1;
