#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Make sure the directory structure for the config files exists
mkdir -p ./configuration_files/Steelheads
mkdir -p ./configuration_files/VPN
mkdir -p ./configuration_files/Extreme
mkdir -p ./configuration_files/ISG
mkdir -p ./configuration_files/IOS12
mkdir -p ./configuration_files/IOS15
mkdir -p ./configuration_files/GLX
mkdir -p ./configuration_files/F5
mkdir -p ./configuration_files/Nexus
mkdir -p ./configuration_files/ASA
mkdir -p ./configuration_files/FWSM
mkdir -p ./configuration_files/ACE
mkdir -p ./configuration_files/ACME
