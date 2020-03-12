package GraphQL::Role::Named;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Devel::StrictMode;
use Types::Standard -all;
use Function::Parameters;
use GraphQL::Type::Library qw(StrNameValid);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Named - GraphQL "named" object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Named);

=head1 DESCRIPTION

Allows type constraints for named objects, providing also C<name> and
C<description> attributes.

=head1 ATTRIBUTES

=head2 name

=cut

has name => (is => 'ro', isa => StrNameValid, required => 1);

=head2 description

Optional description.

=cut

has description => (is => 'ro', isa => Str);

=head1 METHODS

=head2 to_string

Part of serialisation.

=cut

has to_string => (is => 'lazy', isa => Str, init_arg => undef, builder => sub {
  my ($self) = @_;
  $self->name;
});

method _from_ast_named(
  (STRICT ? HashRef : Any) $ast_node,
) {
  (
    name => $ast_node->{name},
    ($ast_node->{description} ? (description => $ast_node->{description}) : ()),
  );
}

__PACKAGE__->meta->make_immutable();

1;
