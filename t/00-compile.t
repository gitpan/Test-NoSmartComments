#!perl
#
# This file is part of Test-NoSmartComments
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More;



use File::Find;
use File::Temp qw{ tempdir };

my @modules;
find(
  sub {
    return if $File::Find::name !~ /\.pm\z/;
    my $found = $File::Find::name;
    $found =~ s{^lib/}{};
    $found =~ s{[/\\]}{::}g;
    $found =~ s/\.pm$//;
    return if $found =~ /MooseX::AutoDestruct::Trait.*/;
    push @modules, $found;
  },
  'lib',
);

my @scripts = glob "bin/*";

my $plan = scalar(@modules) + scalar(@scripts);
$plan ? (plan tests => $plan) : (plan skip_all => "no tests to run");

{
    # fake home for cpan-testers
    # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );

    like( qx{ $^X -Ilib -e "require $_; print '$_ ok'" }, qr/^\s*$_ ok/s, "$_ loaded ok" )
        for sort @modules;

    SKIP: {
        eval "use Test::Script 1.05; 1;";
        skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
        foreach my $file ( @scripts ) {
            my $script = $file;
            $script =~ s!.*/!!;
            script_compiles( $file, "$script script compiles" );
        }
    }
}
