#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Add a creation date to the top of the blank hosts file
echo "#This host file was created on $(date)" > output_6_hosts.txt

# Append IOS interfaces
./ipv4_interfaces_by_file.pl ./configuration_files/* >> output_6_hosts.txt

# Append Steelhead interfaces
./ipv4_interfaces_by_file.pl ./configuration_files/Steelheads/* >> output_6_hosts.txt

# #Make a version with windows line-endings
# perl -p -e 's|\n|\r\n|' < output_6_hosts.txt > output_6_hosts_windows.txt
