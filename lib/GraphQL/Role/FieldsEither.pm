package GraphQL::Role::FieldsEither;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use GraphQL::Debug qw(_debug);
use Devel::StrictMode;
use Types::Standard -all;
use Function::Parameters;
use JSON::MaybeXS;
with qw(GraphQL::Role::FieldDeprecation);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};
my $JSON_noutf8 = JSON::MaybeXS->new->utf8(0)->allow_nonref;

=head1 NAME

GraphQL::Role::FieldsEither - GraphQL object role with code common to all fields

=head1 SYNOPSIS

  with qw(GraphQL::Role::FieldsEither);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::FieldsEither));

=head1 DESCRIPTION

Provides code useful to either type of fields.

=cut

method _make_field_def(
  (STRICT ? HashRef : Any) $name2type,
  (STRICT ? Str : Any) $field_name,
  (STRICT ? HashRef : Any) $field_def,
) {
  DEBUG and _debug('FieldsEither._make_field_def', $field_def);
  require GraphQL::Schema;
  my %args;
  %args = (args => +{
    map $self->_make_field_def($name2type, $_, $field_def->{args}{$_}),
      keys %{$field_def->{args}}
  }) if $field_def->{args};
  ($_ => {
    %$field_def,
    type => GraphQL::Schema::lookup_type($field_def, $name2type),
    %args,
  });
}

method _from_ast_fields(
  (STRICT ? HashRef : Any) $name2type,
  (STRICT ? HashRef : Any) $ast_node,
  (STRICT ? Str : Any) $key,
) {
  my $fields = $ast_node->{$key};
  $fields = $self->_from_ast_field_deprecate($_, $fields) for keys %$fields;
  (
    $key => sub { +{
      map {
        my @pair = eval {
          $self->_make_field_def($name2type, $_, $fields->{$_})
        };
        die "Error in field '$_': $@" if $@;
        @pair;
      } keys %$fields
    } },
  );
}

method _description_doc_lines(
  (STRICT ? Maybe[Str] : Any) $description,
) {
  DEBUG and _debug('FieldsEither._description_doc_lines', $description);
  return if !$description;
  my @lines = $description ? split /\n/, $description : ();
  return if !@lines;
  if (@lines == 1) {
    return '"' . ($lines[0] =~ s#"#\\"#gr) . '"';
  } elsif (@lines > 1) {
    return (
      '"""',
      (map s#"""#\\"""#gr, @lines),
      '"""',
    );
  }
}

method _make_fieldtuples(
  (STRICT ? HashRef : Any) $fields,
) {
  DEBUG and _debug('FieldsEither._make_fieldtuples', $fields);
  map {
    my $field = $fields->{$_};
    my @argtuples = map $_->[0],
      $self->_make_fieldtuples($field->{args} || {});
    my $type = $field->{type};
    my $line = $_;
    $line .= '('.join(', ', @argtuples).')' if @argtuples;
    $line .= ': ' . $type->to_string;
    $line .= ' = ' . $JSON_noutf8->encode(
      $type->perl_to_graphql($field->{default_value})
    ) if exists $field->{default_value};
    my @directives = map {
      my $args = $_->{arguments};
      my @argtuples = map { "$_: " . $JSON_noutf8->encode($args->{$_}) } keys %$args;
      '@' . $_->{name} . (@argtuples ? '(' . join(', ', @argtuples) . ')' : '');
    } @{ $field->{directives} || [] };
    $line .= join(' ', ('', @directives)) if @directives;
    [
      $self->_to_doc_field_deprecate($line, $field),
      $self->_description_doc_lines($field->{description}),
    ]
  } sort keys %$fields;
}

__PACKAGE__->meta->make_immutable();

1;
