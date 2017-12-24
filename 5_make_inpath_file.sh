#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Get the inpath interfaces from Steelhead configs
tac \
    ./configuration_files/Steelheads/*  | 
    ./inpath_interfaces_and_subnets_from_steelhead.pl   \
    > output_5_inpaths.txt
