
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Works.pm',
    'lib/Net/Works/Address.pm',
    'lib/Net/Works/Network.pm',
    'lib/Net/Works/Role/IP.pm',
    'lib/Net/Works/Types.pm',
    'lib/Net/Works/Util.pm'
);

notabs_ok($_) foreach @files;
done_testing;
