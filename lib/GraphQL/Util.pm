package GraphQL::Util;

use 5.014;
use strict;
use warnings;
use Types::Standard -all;
use Function::Parameters;
use Exporter 'import';

our $VERSION = '0.02';

our @EXPORT_OK = qw(
  print_description
);

=head1 NAME

GraphQL::Util - GraphQL utility functions

=head1 SYNOPSIS

  use GraphQL::Util;

=head1 FUNCTIONS

=head2 print_description

Generate

=cut

fun print_description(
  Maybe[Str] $description = undef,
) {
  return () if !$description;
  # TODO This isn't the same logic as the reference implementation. The reference does things like
  # split long lines which would be nice.
  my @lines = split /\n/, $description;
  if (@lines == 1) {
    $lines[0] =~ s!"""!\\"""!g;
    return (qq{"""$lines[0]"""});
  }
  else {
    for my $line (@lines) {
      $line =~ s!"""!\\"""!g;
    }
    return (q{"""}, @lines, q{"""});
  }
}

1;
