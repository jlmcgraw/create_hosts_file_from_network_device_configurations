#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Combine into the final hosts file
# Inpath info comes first so it will resolve first

# Convert to all lowercase
# cat hostsWithInpath.txt hosts.txt | tr '[:upper:]' '[:lower:]' > hosts

# Combine the output files
cat output_7_hostsWithInpath.txt output_6_hosts.txt > output_8_hosts.txt

# Create a windows line-ending version of the file
perl -p -e 's|\n|\r\n|' < output_8_hosts.txt > output_8_hosts_windows.txt
