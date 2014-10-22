package Net::Works::Role::IP;
{
  $Net::Works::Role::IP::VERSION = '0.12';
}
BEGIN {
  $Net::Works::Role::IP::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use Math::Int128 qw( uint128 );
use Net::Works::Types qw( Int IPInt IPVersion );
use Socket qw( AF_INET AF_INET6 );

use Moo::Role;

use integer;

has version => (
    is       => 'ro',
    isa      => IPVersion,
    required => 1,
);

has _integer => (
    is       => 'rw',
    writer   => '_set_integer',
    isa      => IPInt,
    required => 1,
);

has address_family => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub { $_[0]->version() == 6 ? AF_INET6 : AF_INET },
);

{
    my %max = (
        4 => 0xFFFFFFFF,
        6 => uint128(0) - 1,
    );

    sub _max {
        my $self = shift;
        my $version = shift // $self->version();

        return $max{$version};
    }
}

sub bits { $_[0]->version() == 6 ? 128 : 32 }

sub _validate_ip_integer {
    my $self = shift;

    my $int = $self->_integer();

    # We don't need to check if it's too big with v6 because uint128 does not
    # allow a number larger than 2**128-1.
    if ( $self->version() == 6 ) {
        $self->_set_integer( uint128($int) )
            unless ref $int;
    }
    else {
        die "$int is not a valid integer for an IP address"
            if $int >= 2**32;
    }

    return;
}

1;
