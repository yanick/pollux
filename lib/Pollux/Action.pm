package Pollux::Action;

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
