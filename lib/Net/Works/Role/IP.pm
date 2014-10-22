package Net::Works::Role::IP;
{
  $Net::Works::Role::IP::VERSION = '0.02';
}
BEGIN {
  $Net::Works::Role::IP::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use Math::BigInt try => 'GMP,Pari,FastCalc';
use Net::Works::Types qw( Int IPVersion );
use Socket qw( AF_INET AF_INET6 );

use Moose::Role;

has version => (
    is       => 'ro',
    isa      => IPVersion,
    required => 1,
    coerce   => 1,
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
        6 => Math::BigInt->from_hex('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'),
    );

    sub _max {
        my $self = shift;
        my $version = shift // $self->version();

        return $max{$version};
    }
}

1;
