package Net::Works::Types::Internal;
{
  $Net::Works::Types::Internal::VERSION = '0.02';
}
BEGIN {
  $Net::Works::Types::Internal::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Types -declare => [
    qw(
        BigInt
        PackedBinary
        IPInt
        IPVersion
        )
];

use MooseX::Types::Moose qw( Int Value );

class_type BigInt, { class => 'Math::BigInt' };

subtype PackedBinary,
    as Value;

subtype IPInt,
    as Int|BigInt;

subtype IPVersion,
    as Int;

coerce IPVersion,
    from BigInt,
    via { $_->numify() };

1;
