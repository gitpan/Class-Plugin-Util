# $Id: Util.pm,v 1.4 2007/05/24 19:03:26 ask Exp $
# $Source: /opt/CVS/classpluginutil/lib/Class/Plugin/Util.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.4 $
# $Date: 2007/05/24 19:03:26 $
package Class::Plugin::Util;
use strict;
use warnings;
use UNIVERSAL::require;
our $VERSION = 0.004;
{


    # List of subs to export.
    my %EXPORT = (
        supports                => \&supports,
        doesnt_support          => \&doesnt_support,
        factory_new             => \&factory_new,
        first_available_new     => \&first_available_new,
    );

    # Cache of modules already tested.
    my %probe_cache      = ( );

    # Cache of modules that we know doesn't exist.
    my %probe_fail_cache = ( );

    #------------------------------------------------------------------------
    # ::import
    #
    # Our own Exporter functionality.
    # We don't wanna load in all the excess code of Exporter.
    #------------------------------------------------------------------------
    sub import {
        shift; ### delete package name from @_.
        my $caller = caller;
        
        no strict 'refs'; ## no critic
        while (@_) {
            my $export_attr = shift @_;
            my $sub         = $EXPORT{$export_attr};

            if (not $sub) {
                require Carp;
                Carp->import('croak');
                croak("Class::Plugin::Util does not export '$export_attr'");
            }

            *{ $caller . q{::} . $export_attr } = $sub;
        }

        return;
    }

    #------------------------------------------------------------------------
    # ::supports( @modules )
    #
    # Return true if all the modules are available.
    #------------------------------------------------------------------------
    sub supports {
        my (@modules) = @_;
        
        return !doesnt_support(@modules);
    }

    #------------------------------------------------------------------------
    # ::doesnt_support( @modules )
    #
    # Return the first module not available.
    #------------------------------------------------------------------------
    sub doesnt_support {
        my (@modules) = @_;

        PROBE:
        for my $required_module (@modules) {
            if (! exists $probe_cache{$required_module}) {
                if (! $required_module->require) {
                    return $required_module;
                }
            }
            $probe_cache{$required_module}++;
        }

        # if we made it this far, everything was supported.
        return;
    }

    #------------------------------------------------------------------------
    # ::first_available_new( \@classes_to_try, @arguments_to_new )
    #
    # Return a new instance of the first class in the list of classes to try
    # that are available.
    #------------------------------------------------------------------------
    sub first_available_new {
        my $classes_to_try_ref = shift;

        CLASS:
        for my $class (@{ $classes_to_try_ref }) {
            next CLASS if exists $probe_fail_cache{$class};
            next CLASS if ! _CLASS($class);
            next CLASS if ! $class->require;

            my $obj = $class->new( @_ );

            if (! $obj) {
                $probe_fail_cache{$class} = 1;
                next CLASS;
            }

            return $obj;
        }

        return;
    }


    #------------------------------------------------------------------------
    # ->factory_new($class, @arguments_to_new)
    #
    # Return new instance of class in variable.
    # The class will be required.
    #------------------------------------------------------------------------
    sub factory_new {
        my $class = shift;

        $class->require;

        return $class->new(@_);
    }

    #------------------------------------------------------------------------
    # ->_CLASS( $class_name )
    #
    # Copied and pasted from Params::Util.
    # Thanks to Adam Kennedy <adamk@cpan.org>
    #------------------------------------------------------------------------
    sub _CLASS { ## no critic
        (defined $_[0] and ! ref $_[0] and $_[0] =~ m/^[^\W\d]\w*(?:::\w+)*$/s) ? $_[0] : undef; ## no critic;
    } ## no critic

}

1; # keep require happy.

__END__

=pod


=head1 NAME

Class::Plugin::Util - Utility functions for supporting Plug-ins.

=head1 VERSION

This document describes Class::Plugin::Util version 0.004;

=head1 SYNOPSIS

    use Class::Plugin::Util qw( supports doesnt_support factory_new first_available_new)

=head1 DESCRIPTION

This module has utility functions for creating dynamic classes.

=head2 COOKBOOK

=head3 Loading plugins.
    
If you have a class that has a method that returns a list of modules it requires you can
check that everything is OK before you load it.
    
    use Class::Plugin::Util qw(supports);
    use MyPlugin::XMLSupport;

    # The plugin we want to use has a requires class method that
    # returns an array of modules it needs to function properly:
    
    my @required_modules = MyPlugin::XMLSupport->requires;

    # The plugin shouldn't use the required modules itself
    # it should only return the modules it needs to use in
    # in the required method above. The supports method checks
    # if the required modules are available and loads the modules
    # for us.

    if (supports( @required_modules )) {
        print 'We have XML support', "\n";

        my $xml = MyPlugin::XMLSupport->new( );
    
        [ ... ]
    }

    package MyPlugin::XMLSupport;
    {
        sub new {
            return bless { }, shift;
        }

        sub requires {
            return 'XML::Parser';
        }
    }

=head3 Load the best available module.

Say you want to support the ability to export data.
Right now you need support for exporting to a list of formats, let's say YAML, JSON and XML,

As there are several implementations of YAML on CPAN you want to load the best module that
the user has available on his system.

Exporting data should be as easy as:

    my $exporter = MyApp::Export->new({
        format => 'YAML',
    });

    $exporter->export($data);

You could implement this with Class::Plugin::Util like this:

C<MyApp/Export.pm> - This is the main class.

    package MyApp::Export;
    use strict;
    use warnings;
    use Class::Plugin::Util qw( first_available_new );
    {

        my @LIST_OF_YAML_HANDLERS = qw(
            MyApp::Export::YAML::LibYAML
            MyApp::Export::YAML::Syck
            MyApp::Export::YAML
        );

        my @LIST_OF_JSON_HANDLERS = qw(
            MyApp::Export::JSON::Syck
            MyApp::Export::JSON::PC
            MyApp::Export::JSON
        );

        my %FORMAT_TO_HANDLER = (
            'JSON'  => [ @LIST_OF_JSON_HANDLERS ],
            'YAML'  => [ @LIST_OF_YAML_HANDLERS ],
        ); 
        
        sub new {
            my ($class, $arg_ref) = @_;
           
            # The format argument decides which format we choose. 
            my $format = uc( $arg_ref->{format} );
            # Default format is YAML.
            $format  ||= 'YAML',
    
            my $select_ref = $FORMAT_TO_HANDLER{$format};

            my $object = Class::Plugin::Util::first_available_new($select_ref, $arg_ref);

            return $object;
        } 
    }

    1;

C<MyApp/Export/Base.pm> - This is base class export handlers should inherit from.

    package MyApp::Export::Base;
    use strict;
    use warnings;
    use Carp;
    use Class::Plugin::Util;
    {
        sub new {
            my ($class, $arg_ref) = @_;
           
            # All MyApp::Export:: classes should have a requires method which returns
            # a list of all modules it requires to do it's work. 
            my @this_handler_requires = $class->requires;

            # check if we're missing any modules.
            my $missing_module = Class::Plugin::Util::doesnt_support(@this_handler_requires);
            
            if ($missing_module) {
                carp    "$class requires $missing_module, " .
                        "please install from CPAN."         ;
            }

            my $self = { };
            bless $self, $class;

            return $self; 
        }

        # transform is the function exporters should use to transform the data to it's format.
        sub transform {
            croak 'You cannot use MyApp::Export::Base directly. Subclass it!';
        }

        # the list of modules we require.
        sub requires {
            croak 'You cannot use MyApp::Export::Base directly. Subclass it!';
        }

        sub export {
            my ($self, $data) = @_;
            return if not $data;

            return $self->transform($data);
        }
    }

    1;

C<MyApp/Export/YAML/LibYAML.pm> - Example implementation of YAML::LibYAML support for MyApp::Export

    package MyApp::Export::YAML::LibYAML;
    use strict;
    use warnings;
    use base 'MyApp::Export::Base';
    {
        
        my @MODULES_REQUIRED = qw( YAML::LibYAML );

        sub transform {
            my ($self, $data_ref) = @_;

            return YAML::LibYAML::Dump($data_ref);
        }

        sub requires {
            return @MODULES_REQUIRED;
        }
    }

    1;

C<MyApp/Export/JSON/Syck.pm> - Example implementation of JSON::Syck support for MyApp::Export.

    package MyApp::Export::JSON::Syck;
    use strict;
    use warnings;
    use base 'MyApp::Export::Base';
    {
    
        my @MODULES_REQUIRED = qw( JSON::Syck );

        sub transform {
            my ($self, $data_ref) = @_;

            return JSON::Syck::Dump($data_ref);
        }

        sub requires {
            return @MODULES_REQUIRED;
        }
    }

    1;



=head3 Abstract Factory

You want the user to be able to select which database type to use in a configuration file,
have support for different database systems without listing all database modules (i.e DBD::mysql, DBD::pg etc)
in your distributions prerequirements list, and you want to be able to add new database types with 


=head1 SUBROUTINES/METHODS

=head2 CLASS METHODS 

=head3 C<Class::Plugin::Util::supports( @required_modules )>

Require all the given modules, but return false if any one of them fails
to load.

=head3 C<Class::Plugin::Util::doesnt_support( @required_modules )>

In a list of modules, return the first module that is not installed.
If every module is installed, it returns nothing.

=head3 C<Class::Plugin::Util::factory_new($class, @arguments_to_new)>

Given a class name, load the module (via UNIVERSAL::require) and return a new instance of it.

=head3 C<Class::Plugin::Util::first_available_new(\@list_of_class_to_try, @arguments_to_new)>

Given a list of modules, pick the first module installed and return a new instance of it.
If no modules are installed, it returns nothing.

=head1 DIAGNOSTICS

No information available.

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 DEPENDENCIES


=over 4

=item * L<UNIVERSAL::require>

=back

=head1 ALTERNATIVES

For the 'Choosing the first available module' problem you might want to look at L<Best> by Gaal Yahas,
if all the modules has the same interface.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-modwheel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local variables:
# vim: ts=4
