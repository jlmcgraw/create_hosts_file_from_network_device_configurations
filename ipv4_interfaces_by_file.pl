#!/usr/bin/perl
# Copyright (C) 2016  Jesse McGraw (jlmcgraw@gmail.com)
#
# Create hosts file entries from IOS and Steelhead configuration files
#
#-------------------------------------------------------------------------------
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [http://www.gnu.org/licenses/].
#-------------------------------------------------------------------------------

#Standard modules
use strict;
use warnings;
use autodie;

# use Socket;
# use Config;
# use Data::Dumper;
# use Storable;
# use threads;
# use Thread::Queue;
# use threads::shared;
# use Getopt::Std;
use FindBin '$Bin';
use vars qw/ %opt /;
use File::Copy;
use Config;
use File::Basename;

#Use a local lib directory so users don't need to install modules
use lib "$FindBin::Bin/local/lib/perl5";

#Additional modules
use Modern::Perl '2014';
use Params::Validate qw(:all);

#Smart_Comments=1 perl my_script.pl to show smart comments
use Smart::Comments -ENV;

if ( !@ARGV ) {
    say "$0 <configuration file(s)>";
}

#Save original ARGV
my @ARGV_unmodified;

#Expand wildcards on command line since windows doesn't do it for us
if ( $Config{archname} =~ m/win/ix ) {
    use File::Glob ':bsd_glob';

    #Expand wildcards on command line
    ### "Expanding wildcards for Windows";
    @ARGV_unmodified = @ARGV;
    @ARGV = map { bsd_glob $_ } @ARGV;
}

#Valid characters in interface names
my $interfaceNameRegex = qr/[\w\/:\_\-\.]+/mx;

#An octet
#Longest matches first
my $octetRegex = qr/(?: 25[0-5] | 2[0-4][0-9] | 1[0-9]{2} | [0-9]{1,2})/mx;

#IPv4 address and netmasks are 4 octets
my $ipv4_dotted_quad_regex = qr/(?:$octetRegex)\.
                                (?:$octetRegex)\.
                                (?:$octetRegex)\.
                                (?:$octetRegex)
                                /x;

# For each file from the command line...
foreach my $file ( sort @ARGV ) {

    # Skip if this isn't actually a file
    next unless -f $file;

    my ($file_text,    $int_name,  $ip_addr,
        $group_number, $ipv6_addr, $protocol
    );

    # Read in the whole file
    {
        local $/;
        open my $fh, '<', $file or die "can't open $file: $!";
        $file_text = <$fh>;
        close $fh;
    }

    # Try to find a hostname
    my $hostname = determine_hostname( $file_text, $file );
    die unless $hostname;

    say "#$hostname";

    # Process each line in the config file sequentially...
    foreach my $line ( split /^/, $file_text ) {

        given ($line) {

            # IOS interfaces
            # identify lines with "interface " at the beginning
            when (
                /^ \s*                                  #BOL and zero+ whitespace
                    interface \s+
                    (?<interface> $interfaceNameRegex )
                    \s* $                               #Zero+ whitespace and EOL
                    /ix
                )
            {
                # Clean variables between interfaces
                $int_name = $ip_addr = $group_number = $ipv6_addr = $protocol
                    = undef;

                $int_name = $+{interface};

                # substitute - for / and : in dns names
                $int_name =~ s/[\/:]/-/g;

            }

            # ACE interface
            # identify lines with "interface vlan " at the beginning
            when (
                /^ \s*                                  #BOL and zero+ whitespace
                    (?: ft \s+)?                        #May include "ft"
                    interface   \s+
                    vlan        \s+
                    (?<interface> \d+ )
                    \s* $                               #Zero+ whitespace and EOL
                    /ix
                )
            {
                # Clean variables between interfaces
                $int_name = $ip_addr = $group_number = $ipv6_addr = $protocol
                    = undef;

                $int_name = 'vlan' . $+{interface};

                # substitute - for / and : in dns names
                $int_name =~ s/[\/:]/-/g;
            }

            # STEELHEAD interfaces and ip addresses
            # interface inpath0_0 ip address 10.90.243.55 /28
            when (
                /^ \s*                                          #BOL and zero+ whitespace
                    interface   \s+ 
                    (?<interface> $interfaceNameRegex )     \s+
                    ip          \s+
                    address     \s+
                    (?<ip_addr> $ipv4_dotted_quad_regex )   \s+
                    \/
                    (?<mask> \d+ )  
                    \s* $                                       #Zero+ whitespace and EOL
                /ix
                )
            {
                # Clean variables between interfaces
                $int_name = $ip_addr = $group_number = $ipv6_addr = $protocol
                    = undef;

                $int_name = $+{interface};
                $ip_addr  = $+{ip_addr};

                if ( all_defined( $ip_addr, $hostname, $int_name ) ) {
                    printf( "%-20s $hostname-$int_name\n", $ip_addr );
                }
                else {
                    warn $line;
                    die "Problem with $file";
                }
            }

            # identify lines with "ip address #.#.#.#" in them
            # eg
            #   ip address #.#.#.# /##
            #   ip address #.#.#.# #.#.#.#
            #   ip address #.#.#.#/##
            when (
                /^ \s*                                          #BOL and zero+ whitespace
                    ip      \s+
                    address \s+
                    (?<ip_addr> $ipv4_dotted_quad_regex )
                /ix
                )
            {

                $ip_addr = $+{ip_addr};

                if ( all_defined( $ip_addr, $hostname, $int_name ) ) {
                    printf( "%-20s $hostname-$int_name\n", $ip_addr );
                }
                else {
                    warn $line;
                    die "Problem with $file";
                }
            }

            # This section handles IOS HSRP and GLBP configurations
            when (
                /^ \s*                                      #BOL and zero+ whitespace
                    (?<protocol> standby|glbp ) \s+
                    (?<group_number> \d+)       \s+
                    ip \s+
                    (?<ip_addr> $ipv4_dotted_quad_regex )
                /ix
                )
            {

                $group_number = $+{group_number};
                $ip_addr      = $+{ip_addr};
                $protocol     = $+{protocol};

                if (all_defined(
                        $ip_addr,  $hostname, $int_name,
                        $protocol, $group_number
                    )
                    )
                {
                    printf(
                        "%-20s $hostname-$int_name-$protocol-$group_number\n",
                        $ip_addr );
                }
                else {
                    say
                        "$ip_addr && $hostname && $int_name && $protocol && $group_number";
                    warn $line;

                    die "Problem with $file";
                }

            }

            # This section handles NEXUS HSRP and GLBP configurations
            when (
                /^ \s*                                      #BOL and zero+ whitespace
                   (?<protocol> hsrp|glbp ) \s+
                   (?<group_number> \d+) 
                   \s*
                 $                
                /ix
                )
            {

                $group_number = $+{group_number};
                $protocol     = $+{protocol};
            }

            # This section handles NEXUS HSRP and GLBP configurations
            when (
                /^ \s*                                      #BOL and zero+ whitespace
                    ip \s+
                    (?<ip_addr> $ipv4_dotted_quad_regex )
                    \s*
                 $
                /ix
                )
            {

                $ip_addr = $+{ip_addr};

                if (all_defined(
                        $ip_addr,  $hostname, $int_name,
                        $protocol, $group_number
                    )
                    )
                {
                    printf(
                        "%-20s $hostname-$int_name-$protocol-$group_number\n",
                        $ip_addr );
                }
                else {
                    warn $line;
                    die "Problem with $file";
                }

            }

            # This section handles IPv6 configurations
            # identify lines that start with "ipv6 address"
            when (
                /^ \s*
                    ipv6    \s+
                    address \s+
                    (?<ipv6_addr> )
                /ix
                )
            {

                #
                $ipv6_addr = $+{ipv6_addr};

                #                 say "$ipv6_addr\t\t$hostname-$int_name";

                if ( all_defined( $ip_addr, $hostname, $int_name ) ) {
                    printf( "%-20s $hostname-$int_name\n", $ip_addr );
                }
                else {
                    say $line;
                    die "Problem with $file";
                }
            }
        }

    }
}

sub determine_hostname {

    my ( $file_text, $file )
        = validate_pos( @_, { type => SCALAR }, { type => SCALAR }, );

    # STEELHEAD: hostname "STEELHEAD"
    # IOS: hostname ROUTER

    # Regex for finding the hostname in this config file
    my $hostname_regex = qr/^
                                \s*
                                (?: hostname | switchname ) \s+
                                "?
                                ( [\w\-_]+ )
                                "?
                                \s*
                                \R
                            /ismx;

    # Search the whole file for hostname
    my ($hostname_in_file) = $file_text =~ m/$hostname_regex/ixsm;

    # Did we find a hostname?
    if ($hostname_in_file) {

        # Only save up to the first .
        ($hostname_in_file) = split( /\./, $hostname_in_file, 2 );
    }
    else {
        say "#No host name found in file, using file name as device name";

        # Pull out the various filename components of the input file from the
        # command line
        my ( $filename, $dir, $ext ) = fileparse( $file, qr/\.[^.]*/x );

        # Set new name to sanitized version of existing file name
        $hostname_in_file //= $filename;
    }

    # Align hostname with RFC 952
    $hostname_in_file = substr $hostname_in_file, 0, 63;
    $hostname_in_file =~ s/[^A-Za-z0-9]/-/ixg;

    return $hostname_in_file;
}

sub all_defined {

    # Test whether all provided variables are defined
    for my $i (@_) {
        return if !defined $i;
    }
    return 1;
}
