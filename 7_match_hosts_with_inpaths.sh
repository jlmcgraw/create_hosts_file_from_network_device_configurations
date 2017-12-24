#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Match up entries in the hosts.txt file with inpath subnets from Steelhead configs
./add_inpath_to_hosts.pl -houtput_6_hosts.txt -ioutput_5_inpaths.txt > output_7_hostsWithInpath.txt

# perl -p -e 's|\n|\r\n|' < output_7_hostsWithInpath.txt > output_7_hostsWithInpath.txt_windows.txt
