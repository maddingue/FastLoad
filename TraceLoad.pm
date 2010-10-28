package TraceLoad;
use strict;
#use Data::Dumper;

my @loads;

unshift @INC, sub {
    my ($coderef, $filename) = @_;

    my (undef, $caller_file) = caller();

    my $level = 1;
    while (index($caller_file, "(eval") >= 0) {
        (undef, $caller_file) = caller($level++);
    }
        print STDERR "* $caller_file --($level)--> $filename\n";

    push @loads, [$caller_file, $filename];
};


CHECK {
    my %shortname = reverse %INC;
    my @load_graph;
    my @stack = ( \@load_graph );
    my @callers_stack;
    my $prev_caller = "";
    my $prev_callee = "";

    for my $load (@loads) {
        my $caller = $shortname{$load->[0]} || $load->[0];
        my $callee = $load->[1];

        if ($caller eq $prev_caller) {
            push @{ $stack[-1] }, [ $callee ];
        }
        elsif ($caller eq $prev_callee) {
            push @{ $stack[-1][-1] }, [ [ $callee ] ];
            push @stack, $stack[-1][-1][-1];
            push @callers_stack, $caller;
        }
        else {
            while (@callers_stack and $callers_stack[-1] ne $caller) {
                pop @callers_stack;
                pop @stack;
            }

            if ($callers_stack[-1] eq $caller) {
                push @{ $stack[-1] }, [ $callee ];
            }
            else {
                push @callers_stack, $caller;
                push @stack, [ [ $callee ] ];
                push @load_graph, [ $caller => $stack[-1] ];
            }
        }

        $prev_caller = $caller;
        $prev_callee = $callee;
    }

#    print Dumper(\@load_graph);
    walk_graph(\@load_graph, \my @load_order);
    print join $/, @load_order, "";
}

sub walk_graph {
    my ($list, $order) = @_;

    return unless ref $list eq "ARRAY";

    for my $node (@$list) {
        walk_graph($node->[1], $order) if ref $node->[1];
        push @$order, $node->[0];
    }
}

1
