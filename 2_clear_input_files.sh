#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

find \
        ./configuration_files/  \
        -iname "*"              \
        -type f                 \
        -delete
