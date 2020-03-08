package GraphQL::Language::Parser;

use 5.014;
use strict;
use warnings;
use base qw(Pegex::Parser);
use Exporter 'import';
use Types::Standard -all;
use Function::Parameters;
use GraphQL::Language::Grammar;
use GraphQL::Language::Receiver;
use GraphQL::Error;

our $VERSION = '0.02';
our @EXPORT_OK = qw(
  parse
);

=head1 NAME

GraphQL::Language::Parser - GraphQL Pegex parser

=head1 SYNOPSIS

  use GraphQL::Language::Parser qw(parse);
  my $parsed = parse(
    $source
  );

=head1 DESCRIPTION

Provides both an outside-accessible point of entry into the GraphQL
parser (see above), and a subclass of L<Pegex::Parser> to parse a document
into an AST usable by GraphQL.

=head1 METHODS

=head2 parse

  parse($source, $noLocation);

B<NB> that unlike in C<Pegex::Parser> this is a function, not an instance
method. This achieves hiding of Pegex implementation details.

=cut

my $GRAMMAR = GraphQL::Language::Grammar->new; # singleton
fun parse(
  $source,
  $noLocation = undef,
) {
  my $parser = __PACKAGE__->SUPER::new(
    grammar => $GRAMMAR,
    receiver => GraphQL::Language::Receiver->new,
  );
  my $input = Pegex::Input->new(string => $source);
  scalar $parser->SUPER::parse($input);
}

=head2 format_error

Override of parent method. Returns a L<GraphQL::Error>.

=cut

sub format_error {
    my ($self, $msg) = @_;
    my $buffer = $self->{buffer};
    my $position = $self->{farthest};
    my $real_pos = $self->{position};
    my ($line, $column) = @{$self->line_column($position)};
    my $pretext = substr(
        $$buffer,
        $position < 50 ? 0 : $position - 50,
        $position < 50 ? $position : 50
    );
    my $context = substr($$buffer, $position, 50);
    $pretext =~ s/.*\n//gs;
    $context =~ s/\n/\\n/g;
    return GraphQL::Error->new(
      locations => [ { line => $line, column => $column } ],
      message => <<EOF);
Error parsing Pegex document:
  msg:      $msg
  context:  $pretext$context
            ${\ (' ' x (length($pretext)) . '^')}
  position: $position ($real_pos pre-lookahead)
EOF
}

1;
