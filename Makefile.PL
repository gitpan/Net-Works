
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Sane APIs for IP addresses and networks",
  "AUTHOR" => "Dave Rolsky <autarch\@urth.org>, Olaf Alders <olaf\@wundercounter.com>",
  "BUILD_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Works",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Net::Works",
  "PREREQ_PM" => {
    "Carp" => 0,
    "List::AllUtils" => 0,
    "Moose" => 0,
    "NetAddr::IP" => 0,
    "NetAddr::IP::Util" => 0,
    "Scalar::Util" => 0,
    "bigint" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



