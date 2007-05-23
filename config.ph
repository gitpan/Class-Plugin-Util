# $Id: config.ph,v 1.3 2007/05/21 21:18:33 ask Exp $
# $Source: /opt/CVS/Modwheel/config.ph,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/05/21 21:18:33 $
module_name          => 'Class::Plugin::Util',
license              => 'perl',
dist_author          => 'Ask Solem <ASKSH@cpan.org>',
all_from             => 'lib/Class/Plugin/Util.pm',
dynamic_config       => NO,
sign                 => NO, # asksh: have to find out why my signature fails.
recursive_test_files => YES,
requires             => {
    'Params::Util'          => 0.22,    # bugfix for _CODELIKE
    'UNIVERSAL::require'    => 0.10,    # 0.10 fixes a security issue.
},
recommends           => {
    'Test::Pod'             => 1.22,    # Last significant bug-change.
    'Pod::Coverage'         => 0.18,       
    'Test::Pod::Coverage'   => 1.08,    # Last significant bug-change.
    'Test::Exception'       => 0.25,
    'Perl::Critic'          => 1.051,
    'Test::Perl::Critic'    => 1.0,
    'Test::YAML::Meta'      => 0.04,
    'Test::Kwalitee'        => 0.30,
},
build_requires       => {
    'Test::Simple'            => 0.42,    # 
},
add_to_cleanup       => [ qw(
    a.out
    test.pl
    test.c
    test.cpp
    test.m
    *.swp
    .gdb_history
    install.cache
    t/cache
    cache/
) ],
meta_merge => {
    distribution_type   => 'Module',
},
