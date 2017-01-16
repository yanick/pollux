package Pollux::Action;
# ABSTRACT: action objects for Pollux stores

=head1 SYNOPSIS

    use Pollux::Action;

    my $AddTodo = Pollux::Action->new( 'ADD_TODO', 'text' );

    # later on...
    $store->dispatch( $AddTodo->( 'do stuff' ) );

=head1 DESCRIPTION

Creates an action object generator  out of an
action name and a list of fields. 

The objects overload a few operators to ease combiner
comparisons: 

    # create the action generator
    my $AddTodo = Pollux::Action->new( 'ADD_TODO', 'text' );

    my $do_stuff = $AddTodo->( 'do stuff' );

    # stringification resolves to the action type
    print "$do_stuff";  # prints 'ADD_TODO'

    # turned into a hashref if deferenced
    my %x = %$do_stuff; # => { type => 'ADD_TODO', text => 'do stuff ' }

    # smart-matching compare the type between two actions
    print "matching" if $do_stuff ~~ $AddTodo->(); # prints 'matching'

=cut

use strict;
use warnings;

use List::MoreUtils qw/ zip /;
use Const::Fast;

use Moo;

use MooseX::MungeHas 'is_ro';

use experimental 'postderef';

use overload 
    '""' => sub { $_[0]->type },
    '&{}' => sub {
        my $self = shift;
        return sub {
            const my $r, { type => $self->type,
                $self->has_fields ? zip $self->fields->@*, @_ : ()
            };
            $r;
        }
    },
    '~~' => sub {
        my( $self, $other ) = @_;

        no warnings 'uninitialized';
        return $self->type eq ( ref $other ? $other->{type} : $other );
    },
    fallback => 1;


has type => (
    required => 1,
);

has fields => (
    predicate => 1,
);

sub BUILDARGS {
    my $class = shift;

    my %args;
    $args{type} = uc shift;

    $args{fields} = [ @_ ] if @_;

    return \%args;
}

1;
