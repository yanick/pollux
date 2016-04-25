package Pollux::Store;

use strict;
use warnings;

use Moose;

use MooseX::MungeHas 'is_ro';

use experimental 'signatures', 'current_sub';

use Type::Tiny;
use Types::Standard qw/ CodeRef ArrayRef HashRef Any /;
use Scalar::Util qw/ refaddr /;
use Const::Fast;

use List::AllUtils qw/ reduce /;

use Pollux;

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

1;



