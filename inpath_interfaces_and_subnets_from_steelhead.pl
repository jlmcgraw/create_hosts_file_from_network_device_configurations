#!/usr/bin/perl
# Copyright (C) 2016  Jesse McGraw (jlmcgraw@gmail.com)
#
# Takes a Riverbed Steelhead running config
# and produces an outfile with information about the INPATH interfaces
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

# Smart_Comments=1 perl my_script.pl to show smart comments
use Smart::Comments -ENV;

my ($hostname);

# An octet
# Longest matches first
my $octetRegex = qr/(?: 25[0-5] | 2[0-4][0-9] | 1[0-9]{2} | [0-9]{1,2})/mx;

# IPv4 address and netmasks are 4 octets
my $ipv4_dotted_quad_regex = qr/(?:$octetRegex)\.
                                (?:$octetRegex)\.
                                (?:$octetRegex)\.
                                (?:$octetRegex)
                                /x;

while (<>) {

    chomp;    # remove newline characters

# find the line with the hostname in it by searching
# for the "hostname " string
# this assumes hostname comes before interface configurations, which it will if
# you use TAC instead of CAT to pipe the input
    if ($_ =~ /^
                \s*
                hostname \s+
                "
                (?<hostname> [\w\-_]+ )
                "
                \s*
                \R
            /ismx
        )
    {

        # split that line on the whitespace character
        #         my @hostnameFields = split /\s+/, $_;
        $hostname = $+{hostname};

        # Only save up to the first .
        ($hostname) = split( /\./, $hostname, 2 );

        # Lowercase it
        #         $hostname = lc $hostname;

        # Align hostname with RFC 952
        $hostname = substr $hostname, 0, 63;
        $hostname =~ s/[^A-Za-z0-9]/-/ixg;
    }

    # identify lines with "interface inpath" at the beginning
    if ($_ =~ /^ \s*
            interface   \s+
            inpath\d_\d \s+
            ip          \s+
            address     \s+
            (?:[0-9]{1,3}\.){3}[0-9]{1,3}
        /ix
        )
    {

        # split the good lines into space-separated fields
        my @fields = split /\s+/, $_;

        # substitute - for / and : in dns names
        # $fields[1]=~s/\/|:/-/g;

        # print in "ipaddr hostname-interface" format
        my $int_name      = $fields[2];
        my $ip_addr       = $fields[5];
        my $netmask       = $fields[6];
        my ($mask_digits) = $netmask =~ / \/ (\d+) /ix;

        # Quick sanity check on the mask
        if ( $mask_digits < 1 || $mask_digits > 31 ) {

            #         say "Bad mask $mask_digits on $_";
            next;
        }

        #         print "$ip_addr$netmask\t$hostname-$int_name\n";
        printf( "%-20s $hostname-$int_name\n", $ip_addr . $netmask );
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

        #Only save up to the first .
        ($hostname_in_file) = split( /\./, $hostname_in_file, 2 );
    }
    else {
        say "#No host name found in file, using file name as device name";

        #Pull out the various filename components of the input file from the
        # command line
        my ( $filename, $dir, $ext ) = fileparse( $file, qr/\.[^.]*/x );

        #Set new name to sanitized version of existing file name
        $hostname_in_file //= $filename;
    }

    # Align hostname with RFC 952
    $hostname_in_file = substr $hostname_in_file, 0, 63;
    $hostname_in_file =~ s/[^A-Za-z0-9]/-/ixg;

    return $hostname_in_file;
}
