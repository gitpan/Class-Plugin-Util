#!/usr/local/bin/perl
use strict;
use warnings;
use English qw( -no_match_vars );

our $THIS_TEST_HAS_TESTS = 10;

use Test::More;
eval 'require Module::Mask';
if ($EVAL_ERROR) {
    plan( skip_all => 'These tests requires Module::Mask' );
}


plan( tests => $THIS_TEST_HAS_TESTS );

use_ok('Class::Plugin::Util');
my @methods = qw(factory_new supports doesnt_support first_available_new);
use Class::Plugin::Util @methods;

for my $method (@methods) {
    eval 'Class::Plugin::Util::import("main", $method)';
    ok(!$EVAL_ERROR, "exports $method" );
}

ok( supports( ), 'supports( )' );
ok( Class::Plugin::Util::supports( ), 'Class::Plugin::Util::supports( )' );

MASK: {
    my $mask  = Module::Mask->new('Badabing');
    my $mask2 = Module::Mask->new('Badabom');

    ok( !supports('Badabing', 'Badabom' ), 'supports( ) bail on nonexistant module');
}

ok( supports('Module::Mask', 'Carp', 'English' ), 'supports( ) success on existing modules');
ok( supports('Module::Mask', 'Carp', 'English' ), 'supports( ) success on existing modules (with cache)');
