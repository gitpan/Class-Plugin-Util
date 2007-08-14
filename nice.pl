#!/usr/local/bin/perl
use strict;
use warnings;
use Time::HiRes qw(usleep);
$|++;

sub sl{
    usleep((rand 100 * rand 6000));
    q{};
}

sub p {
    my @c = qw(// _ || \\\\);
    my $i = 0;
    return sub {
        print $c[$i], sl();
        $i >= $#c ? $i = 0 : $i++;
    }
}

sub e {
    my @v = qw(a       e       i           o           u           );
    my @c = qw(  b c d   f g h   j k   m n   p   r s t             );
    my @R = qw(                      l         q         v w x y z );
    my @l = ('a'..'z');
    my @p = (q{ }, q{,}, qw(! . ?));
    my $i = 0;
    return sub {
        if ($i >= rand(15)) { 
            print $p[rand $#p], sl(), q{ },
                  uc($i % 3 ? $c[rand $#c] : $v[rand $#v]), sl();
            $i = 0;
        }
        elsif( $i >= rand(64)) {
            print $p[rand $#p], sl(), q{ };
            $i = 0;
        }
        if ($i > 32)  {
            my $c = $c[rand $#c];
            print $c, $c, sl();
        }
        elsif ($i > 48)  {
            print $R[rand $#R], sl();
        } else {
            print ($i % 4 ? $c[rand $#c] : $v[rand $#v]), sl();
        }
        $i > 64 ? $i = 0 : $i++;
    }
}
         
my $X = e();
while('Infinity') {
    $X->();
}
