use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Plugin::Util',
    AUTHOR              => 'Ask Solem <asksh@cpan.org>',
    VERSION_FROM        => 'lib/Class/Plugin/Util.pm',
    ABSTRACT_FROM       => 'lib/Class/Plugin/Util.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'UNIVERSAL::require'    => 0.10,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Plugin-Util-*' },
);
