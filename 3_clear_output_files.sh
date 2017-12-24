#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

rm -f \
        ./output_5_inpaths.txt                       \
        ./output_6_hosts.txt                         \
        ./output_7_hostsWithInpath.txt               \
        ./output_8_hosts.txt                         \
        ./output_8_hosts_windows.txt
