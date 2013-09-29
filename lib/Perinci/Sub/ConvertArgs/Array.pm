package Perinci::Sub::ConvertArgs::Array;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use Data::Sah;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(convert_args_to_array);

# VERSION

our %SPEC;

sub _parse_schema {
    Data::Sah::normalize_schema(@_);
}

$SPEC{convert_args_to_array} = {
    v => 1.1,
    summary => 'Convert hash arguments to array',
    description => <<'_',

Using information in 'args' property (particularly the 'pos' and 'greedy' of
each argument spec), convert hash arguments to array.

Example:

    my $meta = {
        v => 1.1,
        summary => 'Multiply 2 numbers (a & b)',
        args => {
            a => ['num*' => {arg_pos=>0}],
            b => ['num*' => {arg_pos=>1}],
        }
    }

then 'convert_args_to_array(args=>{a=>2, b=>3}, meta=>$meta)' will produce:

    [200, "OK", [2, 3]]

_
    args => {
        args => {req=>1, schema=>'hash*', pos=>0},
        meta => {req=>1, schema=>'hash*', pos=>1},
    },
};
sub convert_args_to_array {
    my %input_args   = @_;
    my $args         = $input_args{args} or return [400, "Please specify args"];
    my $meta         = $input_args{meta} or return [400, "Please specify meta"];
    my $args_prop    = $meta->{args} // {};

    my $v = $meta->{v} // 1.0;
    return [412, "Sorry, only metadata version 1.1 is supported (yours: $v)"]
        unless $v == 1.1;

    #$log->tracef("-> convert_args_to_array(), args=%s", $args);

    my @array;

    while (my ($k, $v) = each %$args) {
        my $as = $args_prop->{$k};
        return [412, "Argument $k: Not specified in args property"] unless $as;
        my $pos = $as->{pos};
        return [412, "Argument $k: No pos specified in arg spec"]
            unless defined $pos;
        if ($as->{greedy}) {
            $v = [$v] if ref($v) ne 'ARRAY';
            # splice can't work if $pos is beyond array's length
            for (@array .. $pos-1) {
                $array[$_] = undef;
            }
            splice @array, $pos, 0, @$v;
        } else {
            $array[$pos] = $v;
        }
    }
    [200, "OK", \@array];
}

1;
#ABSTRACT: Convert hash arguments to array
__END__

=head1 SYNOPSIS

 use Perinci::Sub::ConvertArgs::Array qw(convert_args_to_array);

 my $res = convert_args_to_array(args=>\%args, meta=>$meta, ...);


=head1 DESCRIPTION

This module provides convert_args_to_array() (and
gencode_convert_args_to_array(), upcoming). This module is used by, among
others, L<Perinci::Sub::Wrapper>.


=head1 FUNCTIONS

None are exported by default, but they are exportable.

=cut
