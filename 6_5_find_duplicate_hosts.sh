#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Find duplicate IPs, ignoring HSRP etc
duplicate_hosts=$(
        grep \
		-i -v                 \
		-P 'hsrp|standby|#'   \
		output_6_hosts.txt             |
		awk '{print $1}'      |
		sort                  |
		uniq -d)


# Now find each of those duplicate IPs in the hosts.txt file
for ip in $duplicate_hosts 
do
    echo "Duplicate: ${ip}"
	grep -P "${ip}\s+" output_6_hosts.txt
	echo "----------------------------------------------"
done
