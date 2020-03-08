package GraphQL::Role::Abstract;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Function::Parameters;
use Devel::StrictMode;
use Return::Type;
use Types::Standard -all;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::Abstract - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::Abstract);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::Abstract));

=head1 DESCRIPTION

Allows type constraints for abstract objects.

=cut

method _complete_value(
  (STRICT ? HashRef : Any) $context,
  (STRICT ? ArrayRef[HashRef] : Any) $nodes,
  (STRICT ? HashRef : Any) $info,
  (STRICT ? ArrayRef : Any) $path,
  Any $result,
) {
  my $runtime_type = ($self->resolve_type || \&_default_resolve_type)->(
    $result, $context->{context_value}, $info, $self
  );
  # TODO promise stuff
  $self->_ensure_valid_runtime_type(
    $runtime_type,
    $context,
    $nodes,
    $info,
    $result,
  )->_complete_value(@_);
}

method _ensure_valid_runtime_type(
  (STRICT ? (Str | InstanceOf['GraphQL::Type::Object']) : Any) $runtime_type_or_name,
  (STRICT ? HashRef : Any) $context,
  (STRICT ? ArrayRef[HashRef] : Any) $nodes,
  (STRICT ? HashRef : Any) $info,
  Any $result,
) :ReturnType(STRICT ? InstanceOf['GraphQL::Type::Object'] : Any) {
  my $runtime_type = is_InstanceOf($runtime_type_or_name)
    ? $runtime_type_or_name
    : $context->{schema}->name2type->{$runtime_type_or_name};
  die GraphQL::Error->new(
    message => "Abstract type @{[$self->name]} must resolve to an " .
      "Object type at runtime for field @{[$info->{parent_type}->name]}." .
      "@{[$info->{field_name}]} with value $result, received '@{[$runtime_type->name]}'.",
    nodes => [ $nodes ],
  ) if !$runtime_type->isa('GraphQL::Type::Object');
  die GraphQL::Error->new(
    message => "Runtime Object type '@{[$runtime_type->name]}' is not a possible type for " .
      "'@{[$self->name]}'.",
    nodes => [ $nodes ],
  ) if !$context->{schema}->is_possible_type($self, $runtime_type);
  $runtime_type;
}

fun _default_resolve_type(
  Any $value,
  Any $context,
  (STRICT ? HashRef : Any) $info,
  (STRICT ? ConsumerOf['GraphQL::Role::Abstract'] : Any) $abstract_type,
) {
  my @possibles = @{ $info->{schema}->get_possible_types($abstract_type) };
  # TODO promise stuff
  (grep $_->is_type_of->($value, $context, $info), grep $_->is_type_of, @possibles)[0];
}

__PACKAGE__->meta->make_immutable();

1;
