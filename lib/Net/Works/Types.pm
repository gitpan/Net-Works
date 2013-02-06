package Net::Works::Types;
{
  $Net::Works::Types::VERSION = '0.09';
}
BEGIN {
  $Net::Works::Types::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;

use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Moose
        Net::Works::Types::Internal
        )
);

1;
