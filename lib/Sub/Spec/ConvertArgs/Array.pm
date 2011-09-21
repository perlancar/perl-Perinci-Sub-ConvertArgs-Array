package Sub::Spec::ConvertArgs::Array;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Data::Sah::Util;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(convert_args_to_array);

# VERSION

our %SPEC;

sub _parse_schema {
    Data::Sah::Util::_parse_schema(@_);
}

$SPEC{convert_args_to_array} = {
    summary => 'Convert hash arguments to array',
    description_fmt => 'org',
    description => <<'_',

Using information in sub spec's ~args~ clause (particularly the ~arg_pos~ and
~arg_greedy~ arg type clauses), convert hash arguments to array.

Example:

: my $spec = {
:     summary => 'Multiply 2 numbers (a & b)',
:     args_as => 'array',
      args => {
:         a => ['num*' => {arg_pos=>0}],
:         b => ['num*' => {arg_pos=>1}],
:     }
: }

then ~convert_args_to_array(args=>{a=>2, b=>3}, spec=>$spec)~ will produce:

: [200, "OK", [2, 3]]

_
    args => {
        args => ['hash*' => {
        }],
        spec => ['hash*' => {
        }],
    },
};
sub convert_args_to_array {
    my %input_args = @_;
    my $args       = $input_args{args} or return [400, "Please specify args"];
    my $sub_spec   = $input_args{spec};
    my $args_spec  = $input_args{_args_spec}; # use cache of normalized schema
    if (!$args_spec) {
        $args_spec = $sub_spec->{args} // {};
        $args_spec = { map { $_ => _parse_schema($args_spec->{$_}) }
                           keys %$args_spec };
    }
    my $allow_extra_elems = $input_args{allow_extra_elems} // 0;
    return [400, "Please specify spec"] if !$sub_spec && !$args_spec;
    #$log->tracef("-> get_args_from_array(), array=%s", $array);

    my @array = @{$input_args{array}};
    my $args = {};

    for my $i (reverse 0..$#array) {
        #$log->tracef("i=$i");
        while (my ($name, $schema) = each %$args_spec) {
            my $schema = $args_spec->{$name};
            my $ah0 = $schema->{clause_sets}[0];
            my $o = $ah0->{arg_pos};
            if (defined($o) && $o == $i) {
                if ($ah0->{arg_greedy}) {
                    my $type = $schema->{type};
                    my @elems = splice(@array, $i);
                    if ($type eq 'array') {
                        $args->{$name} = \@elems;
                    } else {
                        $args->{$name} = join " ", @elems;
                    }
                    #$log->tracef("assign %s to arg->{$name}", $args->{$name});
                } else {
                    $args->{$name} = splice(@array, $i, 1);
                    #$log->tracef("assign %s to arg->{$name}", $args->{$name});
                }
            }
        }
    }

    return [400, "There are extra, unassigned elements in array: [".
                join(", ", @array)."]"] if @array && !$allow_extra_elems;

    [200, "OK", $args];
}

1;
#ABSTRACT: Convert hash arguments to array
__END__

=head1 SYNOPSIS

 use Sub::Spec::ConvertArgs::Array;

 my $res = convert_args_to_array(args=>\%args, spec=>$spec, ...);


=head1 DESCRIPTION

This module provides convert_args_to_array() (and
gencode_convert_args_to_array(), upcoming). This module is used by, among
others, L<Sub::Spec::Wrapper>.

This module's functions has L<Sub::Spec> specs.


=head1 FUNCTIONS

None are exported by default, but they are exportable.


=head1 SEE ALSO

L<Sub::Spec>

=cut
