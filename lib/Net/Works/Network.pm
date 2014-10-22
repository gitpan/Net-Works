package Net::Works::Network;
{
  $Net::Works::Network::VERSION = '0.04';
}
BEGIN {
  $Net::Works::Network::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use List::AllUtils qw( any );
use Math::BigInt try => 'GMP,Pari,FastCalc';
use Net::Works::Address;
use Net::Works::Types qw( Int IPInt Str );
use NetAddr::IP::Util qw( bcd2bin bin2bcd );
use Socket qw( inet_ntop inet_pton AF_INET AF_INET6 );

use integer;

use Moose;

with 'Net::Works::Role::IP';

has first => (
    is       => 'ro',
    isa      => 'Net::Works::Address',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_first',
);

has last => (
    is       => 'ro',
    isa      => 'Net::Works::Address',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_last',
);

has mask_length => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has _address_string => (
    is  => 'ro',
    isa => Str,
);

has _address_integer => (
    is       => 'ro',
    isa      => IPInt,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_address_integer'
);

has _subnet_integer => (
    is       => 'ro',
    isa      => IPInt,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_subnet_integer',
);

override BUILDARGS => sub {
    my $self = shift;

    my $p = super();

    my ( $address, $masklen ) = split '/', $p->{subnet};

    my $version = $p->{version} ? $p->{version} : _is_ipv6($address) ? 6 : 4;

    if ( $version == 6 && is_ipv4($address) ) {
        $masklen += 96;
        $address = '::' . $address;
    }

    return {
        _address_string => $address,
        mask_length     => $masklen,
        version         => $version,
    };
};

# Data::Validate::IP does not think '::' is a valid IPv6 address -
# https://rt.cpan.org/Ticket/Display.html?id=81700
sub _is_ipv6 {
    return $_[0] eq '::' || is_ipv6($_[0]);
}

sub _build_address_integer {
    my $self = shift;

    my $packed = inet_pton( $self->address_family(), $self->_address_string() );

    return $self->version() == 4
        ? unpack( N => $packed )
        : Math::BigInt->new( bin2bcd($packed) );
}

sub _build_subnet_integer {
    my $self = shift;

    return $self->_mask_length_to_mask( $self->mask_length() );
}

sub _mask_length_to_mask {
    my $self    = shift;
    my $masklen = shift;

    return $self->_max() & ( $self->_max() << ( $self->bits - $masklen ) );
}

sub max_mask_length {
    my $self = shift;

    my $base = $self->first()->as_integer();

    my $netmask = $self->mask_length();

    my $bits = $self->bits;
    while ($netmask) {
        my $mask = $self->_mask_length_to_mask($netmask);

        last if ( $base & $mask ) != $base;

        $netmask--;
    }

    return $netmask + 1;
}

sub iterator {
    my $self = shift;

    my $version = $self->version();
    my $current = $self->first()->as_integer();
    my $last    = $self->last()->as_integer();

    return sub {
        return if $current > $last;

        Net::Works::Address->new_from_integer(
            integer => $current++,
            version => $version,
        );
    };
}

sub as_string {
    my $self = shift;

    return join '/', lc $self->_address_string(), $self->mask_length();
}

sub _build_first {
    my $self = shift;

    my $id = $self->_address_integer() & $self->_subnet_integer();

    return Net::Works::Address->new_from_integer(
        integer => $id,
        version => $self->version(),
    );
}

sub _build_last {
    my $self = shift;

    my $broadcast
        = $self->_address_integer() | ( $self->_max() & ~$self->_subnet_integer() );

    return Net::Works::Address->new_from_integer(
        integer => $broadcast,
        version => $self->version(),
    );
}

{
    my @reserved_4 = qw(
        10.0.0.0/8
        127.0.0.0/8
        169.254.0.0/16
        172.16.0.0/12
        192.0.2.0/24
        192.88.99.0/24
        192.168.0.0/16
        224.0.0.0/4
    );

    my @reserved_6 = (
        @reserved_4, qw(
            2001::/32
            fc00::/7
            fe80::/10
            ff00::/8
            )
    );

    my %reserved_networks = (
        4 => [
            map { [ $_->first()->as_integer(), $_->last()->as_integer() ] }
                sort { $a->first <=> $b->first }
                map { Net::Works::Network->new( subnet => $_, version => 4 ) }
                @reserved_4,
        ],
        6 => [
            map { [ $_->first()->as_integer(), $_->last()->as_integer() ] }
                sort { $a->first <=> $b->first }
                map { Net::Works::Network->new( subnet => $_, version => 6 ) }
                @reserved_6,
        ],
    );

    sub _remove_reserved_subnets_from_range {
        my $class   = shift;
        my $first   = shift;
        my $last    = shift;
        my $version = shift;

        my @ranges;
        my $add_remaining = 1;

        for my $pn ( @{ $reserved_networks{$version} } ) {
            my $reserved_first = $pn->[0];
            my $reserved_last  = $pn->[1];

            next if ( $reserved_last <= $first );
            last if ( $last < $reserved_first );

            push @ranges, [ $first, $reserved_first - 1 ]
                if $first < $reserved_first;

            if ( $last <= $reserved_last ) {
                $add_remaining = 0;
                last;
            }

            $first = $reserved_last + 1;
        }

        push @ranges, [ $first, $last ] if $add_remaining;

        return @ranges;
    }
}

sub range_as_subnets {
    my $class = shift;
    my $first = shift;
    my $last  = shift;

    my $version = ( any { /:/ } $first, $last ) ? 6 : 4;

    $first = Net::Works::Address->new_from_string(
        string  => $first,
        version => $version,
    ) unless ref $first;

    $last = Net::Works::Address->new_from_string(
        string  => $last,
        version => $version,
    ) unless ref $last;

    my @ranges = $class->_remove_reserved_subnets_from_range(
        $first->as_integer(),
        $last->as_integer(),
        $version
    );

    my @subnets;
    for my $range (@ranges) {
        push @subnets, $class->_split_one_range( @{$range}, $version );
    }

    return @subnets;
}

sub _split_one_range {
    my $class   = shift;
    my $first   = shift;
    my $last    = shift;
    my $version = shift;

    my @subnets;
    while ( $first <= $last ) {
        my $max_network = _max_subnet( $first, $last, $version );

        push @subnets, $max_network;

        $first = $max_network->last()->next_ip()->as_integer();
    }

    return @subnets;
}

sub _max_subnet {
    my $ip      = shift;
    my $maxip   = shift;
    my $version = shift;

    my $masklen = $version == 6 ? 128 : 32;

    my $v = $ip;
    my $reverse_mask = $version == 6 ? Math::BigInt->new(1) : 1;

    while (( $v & 1 ) == 0
        && $masklen > 0
        && ( $ip | $reverse_mask ) <= $maxip ) {

        $masklen--;
        $v = $v >> 1;

        $reverse_mask = ( $reverse_mask << 1 ) | 1;
    }

    my $address = inet_ntop(
        ( $version == 6 ? AF_INET6 : AF_INET ),
        ( $version == 6 ? bcd2bin($ip) : pack( N => $ip ) )
    );

    return Net::Works::Network->new(
        subnet  => $address . '/' . $masklen,
        version => $version,
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An object representing a single IP address (4 or 6) subnet

__END__

=pod

=head1 NAME

Net::Works::Network - An object representing a single IP address (4 or 6) subnet

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  my $network = Net::Works::Network->new( subnet => '1.0.0.0/24' );
  print $network->as_string();          # 1.0.0.0/24
  print $network->mask_length();        # 24
  print $network->bits();               # 32
  print $network->version();            # 4

  my $first = $network->first();
  print $first->as_string();    # 1.0.0.0

  my $last = $network->first();
  print $last->as_string();     # 1.0.0.255

  my $iterator = $network->iterator();
  while ( my $ip = $iterator->() ) { ... }

  my $network = Net::Works::Network->new( subnet => '1.0.0.4/32' );
  print $network->max_mask_length(); # 30

  # All methods work with IPv4 and IPv6 subnets
  my $network = Net::Works::Network->new( subnet => 'a800:f000::/20' );

  my @subnets = Net::Works::Network->range_as_subnets( '1.1.1.1', '1.1.1.32' );
  print $_->as_string, "\n" for @subnets;
  # 1.1.1.1/32
  # 1.1.1.2/31
  # 1.1.1.4/30
  # 1.1.1.8/29
  # 1.1.1.16/28
  # 1.1.1.32/32

=head1 DESCRIPTION

Objects of this class represent an IP address network. It can handle both IPv4
and IPv6 subnets. It provides various methods for getting information about
the subnet.

For IPv6, it uses big integers (via Math::BigInt) to represent the numeric
value of an address as needed.

This module is currently a thin wrapper around NetAddr::IP but that could
change in the future.

=head1 METHODS

This class provides the following methods:

=head2 Net::Works::Network->new( ... )

This method takes a C<subnet> parameter and an optional C<version>
parameter. The C<subnet> parameter should be a string representation of an IP
address subnet.

The C<version> parameter should be either C<4> or C<6>, but you don't really
need this unless you're trying to force a dotted quad to be interpreted as an
IPv6 network or to a force an IPv6 address colon-separated hex number to be
interpreted as an IPv4 network.

=head2 $network->as_string()

Returns a string representation of the network like "1.0.0.0/24" or
"a800:f000::/105".

=head2 $network->version()

Returns a 4 or 6 to indicate whether this is an IPv4 or IPv6 network.

=head2 $network->mask_length()

Returns the numeric network as passed to the constructor.

=head2 $network->bits()

Returns the number of bit of an address in the network, which is either 32
(IPv4) or 128 (IPv6).

=head2 $network->max_mask_length()

This returns the maximum possible numeric subnet that this network could fit
in. In other words, the 1.1.1.0/32 subnet could be part of the 1.1.1.0/24
subnet, so this returns 24.

=head2 $network->first()

Returns the first IP in the network as an L<Net::Works::Address> object.

=head2 $network->last()

Returns the last IP in the network as an L<Net::Works::Address> object.

=head2 $network->iterator()

This returns an anonymous sub that returns one IP address in the range each
time it's called.

For single address subnets (/32 or /128), this returns a single address.

When it has exhausted all the addresses in the network, it returns C<undef>

=head2 Net::Works::Network->range_as_subnets( $first, $last )

Given two IP addresses as strings, this method breaks the range up into the
largest subnets that include all the IP addresses in the range (including the
two passed to this method).

It also excludes any reserved subnets in the range (such as the 10.0.0.0/8 or
169.254.0.0/16 ranges).

This method works with both IPv4 and IPv6 addresses. If either address
contains a colon (:) then it assumes that you want IPv6 subnets.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
