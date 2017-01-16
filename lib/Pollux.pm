package Pollux;

use strict;
use warnings;

use Hash::Merge    qw/ merge/;
use Clone          qw/ clone /;
use List::AllUtils qw/ pairmap reduce /;

use Moose;

use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    as_is => [qw/ clone merge combine_reducers /],
);

use MooseX::MungeHas 'is_ro';

use experimental 'signatures', 'current_sub';

use Type::Tiny;
use Types::Standard qw/ CodeRef ArrayRef HashRef Any /;
use Scalar::Util qw/ refaddr /;
use Const::Fast;

use List::AllUtils qw/ reduce /;

has state => (
    is        => 'rwp',
    predicate => 1,
    coerce    =>  1,
    isa       =>Type::Tiny->new->plus_coercions(
                  Any ,=> sub { const my $immu = $_; return $immu }
              ),
    trigger   => sub($self,$new,$old=undef) {
        no warnings 'uninitialized';

        return if $new eq $old;

        $self->unprocessed_subscribers([ $self->all_subscribers ]); 

        $self->notify;
    },
);

has reducer => (
    required => 1,
    coerce   => 1,
    isa      => Type::Tiny->new(
                    parent => CodeRef,
                )->plus_coercions(
                    HashRef ,=> sub { combine_reducers( %$_ ) }
                ),
);

has middlewares => (
    is => 'ro',
    traits => [ qw/ Array / ],
    default => sub { [] },
    handles => {
        all_middlewares => 'elements',
    },
);


has subscribers => (
    traits => [ 'Array' ],
    is => 'rw',
    default => sub { [] },
    handles => {
        all_subscribers  => 'elements',
        add_subscriber   => 'push',
        grep_subscribers => 'grep',
    },
);

has unprocessed_subscribers => (
    traits     => [ 'Array' ],
    is         => 'rw',
    default    => sub { [] },
    handles    => {
        shift_unprocessed_subscribers => 'shift',
    },
);


sub subscribe($self,$code) { 
    $self->add_subscriber($code);

    my $addr = refaddr $code;

    return sub { $self->subscribers([ 
        $self->grep_subscribers(sub{ $addr != refaddr $_ })
    ]) } 
}

sub notify($self) {
    my $sub = $self->shift_unprocessed_subscribers or return;
    $sub->($self);
    goto __SUB__;  # tail recursion!
}

sub _dispatch_list {
    my $self = shift;
    return $self->all_middlewares, sub { $self->_dispatch(shift) };
}

sub dispatch($self,$action) { 
    ( reduce {
        # inner scope to thwart reduce scoping issue
        { 
            my ( $inner, $outer ) = ($a,$b);
            sub { $outer->( $self, $inner, shift ) };
        }
    } reverse $self->_dispatch_list )->($action);
}

sub _dispatch($self,$action) { 
    $self->_set_state( $self->reducer->(
        $action, $self->has_state ? $self->state : () 
    ));
}

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


