package Net::Works;
{
  $Net::Works::VERSION = '0.05';
}
BEGIN {
  $Net::Works::AUTHORITY = 'cpan:DROLSKY';
}

# This is a hack to let us test code that requires a specific Net::Works
# version against the Net-Works git repo code, but without actually setting
# the $VERSION variable.
BEGIN {
    $Net::Works::{VERSION} = \99
        unless exists $Net::Works::{VERSION};
}

1;

# ABSTRACT: Sane APIs for IP addresses and networks

__END__

=pod

=head1 NAME

Net::Works - Sane APIs for IP addresses and networks

=head1 VERSION

version 0.05

=head1 DESCRIPTION

The L<NetAddr::IP> module is very complete, correct, and useful. However, its
API design is a bit crufty. This distro provides wrappers around
L<NetAddr::IP> that aim to address the biggest problems with that module's
API, as well as adding some additional features.

This distro contains two modules, L<Net::Works::Address> and
L<Net::Works::Network>.

B<NOTE: This distro's APIs are still in flux. Use at your own risk.>

=head1 BIG INTEGERS

If you're using this module to work with IPv6 addresses, then you'll end up
creating big integers at some point. We strongly recommend that you install
L<Math::BigInt::GMP> or L<Math::BigInt::Pari>. The default pure Perl
implementation of big integers can be very, very slow.

=head1 Net::Works VERSUS NetAddr::IP

Here are some of the key differences between the two distributions:

=over 4

=item * Separation of address from network

C<Net::Works> provides two classes, one for single IP addresses and one for
networks (and subnets). With L<NetAddr::IP> a single address is represented as
a /32 or /128 subnet.

=item * Multiple constructors

L<Net::Works> allows you to construct an IP address from a string ("1.2.3.4")
or an integer (1097) using separate constructors.

=item * Next & previous IP

You can get the next and previous address from L<Net::Works::Address> object,
regardless of whether or not that address is in the same subnet.

=item * Constructors throw exceptions

If you pass bad data to a constructor you'll get an exception.

=item * Sane iterator and first/last

The iterator provided by L<Net::Works::Network> has no confusing special
cases. It always returns all the addresses in a network, including the network
and broadcast addresses. Similarly, the C<< $network->first() >> and C<<
$network->last() >> do not return different results for different sized networks.

=item * Split a range into subnets

The L<Net::Works::Network> class provides a C<<
Net::Works::Network->range_as_subnets >> method that takes a start and end IP
address and splits this into a set of subnets that include all addresses in
the range.

=item * Does less

This distro does not wrap every method provided by L<NetAddr::IP>. Patches to
add more wrappers are welcome, however.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-works@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Olaf Alders <olaf@wundercounter.com>

=item *

Greg Oschwald <oschwald@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
