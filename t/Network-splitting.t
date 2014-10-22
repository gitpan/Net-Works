use strict;
use warnings;

use Test::More 0.88;

use List::AllUtils qw( each_array );
use Math::Int128 qw(uint128);
use Net::Works::Network;

{
    _test_remove_reserved_subnets(
        [ '0.0.0.1', '1.2.3.4' ] => [ [ '0.0.0.1', '1.2.3.4' ] ] );

    _test_remove_reserved_subnets( [ '9.10.11.12', '9.255.255.255' ] =>
            [ [ '9.10.11.12', '9.255.255.255' ] ] );

    _test_remove_reserved_subnets(
        [ '9.0.0.0', '12.0.0.0' ] => [
            [ '9.0.0.0',  '9.255.255.255' ],
            [ '11.0.0.0', '12.0.0.0' ],
        ]
    );

    _test_remove_reserved_subnets(
        [ '9.0.0.0', '10.255.255.255' ] => [
            [ '9.0.0.0', '9.255.255.255' ],
        ]
    );

    _test_remove_reserved_subnets(
        [ '10.2.3.4', '12.255.255.255' ] => [
            [ '11.0.0.0', '12.255.255.255' ],
        ]
    );

    _test_remove_reserved_subnets( [ '10.0.0.0', '10.10.10.10' ] => [] );

    _test_remove_reserved_subnets(
        [ '0.0.0.0', '255.255.255.255' ] => [
            [ '0.0.0.0',      '9.255.255.255' ],
            [ '11.0.0.0',     '126.255.255.255' ],
            [ '128.0.0.0',    '169.253.255.255' ],
            [ '169.255.0.0',  '172.15.255.255' ],
            [ '172.32.0.0',   '192.0.1.255' ],
            [ '192.0.3.0',    '192.88.98.255' ],
            [ '192.88.100.0', '192.167.255.255' ],
            [ '192.169.0.0',  '223.255.255.255' ],
            [ '240.0.0.0',    '255.255.255.255' ],
        ]
    );

    _test_remove_reserved_subnets(
        [ '::', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ] => [
            map {
                [
                    map {
                        Net::Works::Address->new_from_string(
                            string  => $_,
                            version => 6
                            )->as_string()
                    } @{$_}
                ]
                } (
                [ '::',             '::9.255.255.255' ],
                [ '::11.0.0.0',     '::126.255.255.255' ],
                [ '::128.0.0.0',    '::169.253.255.255' ],
                [ '::169.255.0.0',  '::172.15.255.255' ],
                [ '::172.32.0.0',   '::192.0.1.255' ],
                [ '::192.0.3.0',    '::192.88.98.255' ],
                [ '::192.88.100.0', '::192.167.255.255' ],
                [ '::192.169.0.0',  '::223.255.255.255' ],
                [ '::240.0.0.0',
                    '2000:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
                ],
                [
                    '2001:1::',
                    'fbff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
                ],
                [
                    'fe00::',
                    'fe7f:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
                ],
                [
                    'fec0::',
                    'feff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
                ],
                ),
        ],
    );
}

{
    my $start = '0.0.0.1';
    my $end   = '0.0.0.255';

    my @expect = (
        map { Net::Works::Network->new_from_string( string => $_ ) }
            qw(
            0.0.0.1/32
            0.0.0.2/31
            0.0.0.4/30
            0.0.0.8/29
            0.0.0.16/28
            0.0.0.32/27
            0.0.0.64/26
            0.0.0.128/25
            )
    );

    _test_range_as_subnets( $start, $end, \@expect );
}

{
    my $start = '10.0.0.0';
    my $end   = '12.0.0.0';

    my @expect = (
        map { Net::Works::Network->new_from_string( string => $_ ) }
            qw(
            11.0.0.0/8
            12.0.0.0/32
            )
    );

    _test_range_as_subnets( $start, $end, \@expect );
}

{
    my $start = '0.0.0.1';
    my $end   = '19.255.255.255';

    my @expect = (
        map { Net::Works::Network->new_from_string( string => $_ ) }
            qw(
            0.0.0.1/32
            0.0.0.2/31
            0.0.0.4/30
            0.0.0.8/29
            0.0.0.16/28
            0.0.0.32/27
            0.0.0.64/26
            0.0.0.128/25
            0.0.1.0/24
            0.0.2.0/23
            0.0.4.0/22
            0.0.8.0/21
            0.0.16.0/20
            0.0.32.0/19
            0.0.64.0/18
            0.0.128.0/17
            0.1.0.0/16
            0.2.0.0/15
            0.4.0.0/14
            0.8.0.0/13
            0.16.0.0/12
            0.32.0.0/11
            0.64.0.0/10
            0.128.0.0/9
            1.0.0.0/8
            2.0.0.0/7
            4.0.0.0/6
            8.0.0.0/7
            11.0.0.0/8
            12.0.0.0/6
            16.0.0.0/6
            )
    );

    _test_range_as_subnets( $start, $end, \@expect );
}

{
    my $start = '::1';
    my $end   = 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff';

    my @subnets = do {
        map {
            Net::Works::Address->new_from_integer(
                integer => uint128(2)**$_,
                version => 6
                )->as_string()
                . '/'
                . ( 128 - $_ )
        } 0 .. 26;
    };

    my @expect = (
        map { Net::Works::Network->new_from_string( string => $_, version => 6 ) } @subnets,
        qw(
            ::8.0.0.0/103
            ::11.0.0.0/104
            ::12.0.0.0/102
            ::16.0.0.0/100
            ::32.0.0.0/99
            ::64.0.0.0/99
            ::96.0.0.0/100
            ::112.0.0.0/101
            ::120.0.0.0/102
            ::124.0.0.0/103
            ::126.0.0.0/104
            ::128.0.0.0/99
            ::160.0.0.0/101
            ::168.0.0.0/104
            ::169.0.0.0/105
            ::169.128.0.0/106
            ::169.192.0.0/107
            ::169.224.0.0/108
            ::169.240.0.0/109
            ::169.248.0.0/110
            ::169.252.0.0/111
            ::169.255.0.0/112
            ::170.0.0.0/103
            ::172.0.0.0/108
            ::172.32.0.0/107
            ::172.64.0.0/106
            ::172.128.0.0/105
            ::173.0.0.0/104
            ::174.0.0.0/103
            ::176.0.0.0/100
            ::192.0.0.0/119
            ::192.0.3.0/120
            ::192.0.4.0/118
            ::192.0.8.0/117
            ::192.0.16.0/116
            ::192.0.32.0/115
            ::192.0.64.0/114
            ::192.0.128.0/113
            ::192.1.0.0/112
            ::192.2.0.0/111
            ::192.4.0.0/110
            ::192.8.0.0/109
            ::192.16.0.0/108
            ::192.32.0.0/107
            ::192.64.0.0/108
            ::192.80.0.0/109
            ::192.88.0.0/114
            ::192.88.64.0/115
            ::192.88.96.0/119
            ::192.88.98.0/120
            ::192.88.100.0/118
            ::192.88.104.0/117
            ::192.88.112.0/116
            ::192.88.128.0/113
            ::192.89.0.0/112
            ::192.90.0.0/111
            ::192.92.0.0/110
            ::192.96.0.0/107
            ::192.128.0.0/107
            ::192.160.0.0/109
            ::192.169.0.0/112
            ::192.170.0.0/111
            ::192.172.0.0/110
            ::192.176.0.0/108
            ::192.192.0.0/106
            ::193.0.0.0/104
            ::194.0.0.0/103
            ::196.0.0.0/102
            ::200.0.0.0/101
            ::208.0.0.0/100
            ::240.0.0.0/100
            ::1:0:0/96
            ::2:0:0/95
            ::4:0:0/94
            ::8:0:0/93
            ::10:0:0/92
            ::20:0:0/91
            ::40:0:0/90
            ::80:0:0/89
            ::100:0:0/88
            ::200:0:0/87
            ::400:0:0/86
            ::800:0:0/85
            ::1000:0:0/84
            ::2000:0:0/83
            ::4000:0:0/82
            ::8000:0:0/81
            ::1:0:0:0/80
            ::2:0:0:0/79
            ::4:0:0:0/78
            ::8:0:0:0/77
            ::10:0:0:0/76
            ::20:0:0:0/75
            ::40:0:0:0/74
            ::80:0:0:0/73
            ::100:0:0:0/72
            ::200:0:0:0/71
            ::400:0:0:0/70
            ::800:0:0:0/69
            ::1000:0:0:0/68
            ::2000:0:0:0/67
            ::4000:0:0:0/66
            ::8000:0:0:0/65
            0:0:0:1::/64
            0:0:0:2::/63
            0:0:0:4::/62
            0:0:0:8::/61
            0:0:0:10::/60
            0:0:0:20::/59
            0:0:0:40::/58
            0:0:0:80::/57
            0:0:0:100::/56
            0:0:0:200::/55
            0:0:0:400::/54
            0:0:0:800::/53
            0:0:0:1000::/52
            0:0:0:2000::/51
            0:0:0:4000::/50
            0:0:0:8000::/49
            0:0:1::/48
            0:0:2::/47
            0:0:4::/46
            0:0:8::/45
            0:0:10::/44
            0:0:20::/43
            0:0:40::/42
            0:0:80::/41
            0:0:100::/40
            0:0:200::/39
            0:0:400::/38
            0:0:800::/37
            0:0:1000::/36
            0:0:2000::/35
            0:0:4000::/34
            0:0:8000::/33
            0:1::/32
            0:2::/31
            0:4::/30
            0:8::/29
            0:10::/28
            0:20::/27
            0:40::/26
            0:80::/25
            0:100::/24
            0:200::/23
            0:400::/22
            0:800::/21
            0:1000::/20
            0:2000::/19
            0:4000::/18
            0:8000::/17
            1::/16
            2::/15
            4::/14
            8::/13
            10::/12
            20::/11
            40::/10
            80::/9
            100::/8
            200::/7
            400::/6
            800::/5
            1000::/4
            2000::/16
            2001:1::/32
            2001:2::/31
            2001:4::/30
            2001:8::/29
            2001:10::/28
            2001:20::/27
            2001:40::/26
            2001:80::/25
            2001:100::/24
            2001:200::/23
            2001:400::/22
            2001:800::/21
            2001:1000::/20
            2001:2000::/19
            2001:4000::/18
            2001:8000::/17
            2002::/15
            2004::/14
            2008::/13
            2010::/12
            2020::/11
            2040::/10
            2080::/9
            2100::/8
            2200::/7
            2400::/6
            2800::/5
            3000::/4
            4000::/2
            8000::/2
            c000::/3
            e000::/4
            f000::/5
            f800::/6
            fe00::/9
            fec0::/10
            )
    );

    _test_range_as_subnets( $start, $end, \@expect );
}

done_testing();

sub _test_remove_reserved_subnets {
    my $range  = shift;
    my $expect = shift;

    my $version = $range->[0] =~ /:/ ? 6 : 4;

    # All these conversions are gross but normally this is handled by the
    # range_as_subnets method.
    my $first = Net::Works::Address->new_from_string(
        string  => $range->[0],
        version => $version,
    )->as_integer();

    my $last = Net::Works::Address->new_from_string(
        string  => $range->[1],
        version => $version
    )->as_integer();

    my @got = map {
        [
            map {
                Net::Works::Address->new_from_integer(
                    integer => $_,
                    version => $version
                    )
            } @{$_}
        ]
        } Net::Works::Network->_remove_reserved_subnets_from_range(
        $first,
        $last,
        $version,
        );

    is_deeply(
        \@got,
        $expect,
        "_remove_reserved_subnets_from_range returned expected result for $range->[0] - $range->[1]"
    );
}

sub _test_range_as_subnets {
    my $start          = shift;
    my $end            = shift;
    my $expect_subnets = shift;

    my @subnets = Net::Works::Network->range_as_subnets( $start, $end );

    is(
        scalar @subnets,
        scalar @{$expect_subnets},
        'got the same number of subnets as we expect'
    );

    my $iter = each_array( @subnets, @{$expect_subnets} );

    while ( my ( $got, $expect ) = $iter->() ) {
        last unless $got && $expect;

        my $first = eval { $expect->first()->as_ipv4_string() }
            // $expect->first()->as_string();

        is(
            $got->first()->as_string(),
            $expect->first()->as_string(),
            "subnet first matches expected first - split $start - $end ($first)"
        );

        my $last = eval { $expect->last()->as_ipv4_string() }
            // $expect->last()->as_string();

        is(
            $got->last()->as_string(),
            $expect->last()->as_string(),
            "subnet last matches expected last - split $start - $end ($last)"
        );

        my $netmask = $expect->mask_length();
        is(
            $got->mask_length(),
            $netmask,
            "netmask matches expected netmask - split $start - $end ($netmask)"
        );
    }
}
