package Pollux;

use strict;
use warnings;

use Hash::Merge    qw/ merge/;
use Clone          qw/ clone /;
use List::AllUtils qw/ pairmap reduce /;

use experimental 'signatures';

use parent 'Exporter';

our @EXPORT = qw/ clone merge combine_reducers /;

Hash::Merge::specify_behavior({
        SCALAR => {
            map { $_ => sub { $_[1] } } qw/ SCALAR ARRAY HASH /
        },
        ARRAY => {
            map { $_ => sub { $_[1] } } qw/ SCALAR ARRAY HASH /
        },
        HASH => {
            HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
            map { $_ => sub { $_[1] } } qw/ SCALAR ARRAY /,
        },
}, 'Pollux');

sub combine_reducers {
    my @reducers = @_;

    return sub($action=undef,$store={}) {
        reduce {
            merge( $a, $b ) }  $store,
            pairmap { +{ $a => $b->($action, exists $store->{$a} ? $store->{$a} : () ) } }
            @reducers;
    }

}

1;


