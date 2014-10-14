#!/bin/bash

# Simple script that concats files from /etc/hosts.d into /etc/hosts.
# Only files starting with digits followed by a dash are considered from
# /etc/hosts.d. Command line arguments can be used to exclude specific
# files. Matching for exclusions is made on the part of the filename
# following the dash.
# The script was created for automating blocking of timesink websites
# during work hours :-P.

SPONGE=/opt/homebrew/bin/sponge
HOSTSD=/etc/hosts.d
HOSTS=/etc/hosts

# check for sponge
if [ ! -x "$SPONGE" ]; then
    echo "Script $0 uses 'sponge' utility, which was not found." 1>&2
    exit 1
fi

# process files
for f in "$HOSTSD"/[0-9]*-*; do
    [ -f "$f" ] || continue

    b="$(basename "$f")"
    b=${b/*-/}

    for a in "$@"; do
        [ "$b" = "$a" ] && break
    done
    [ "$b" = "$a" ] && continue

    cat "$f"
done | "$SPONGE" > "$HOSTS"

