#!/bin/bash

SCRIPT="$(basename "$0")"

if [ "$#" -eq 0 ]; then
    echo "Script for preparing VM disks for shrinking/compacting."
    echo "Usage: $SCRIPT dir1 dir2 ..."
    exit 1
fi


let processed=0

for d in "$@"; do
    if [ ! -d "$d" ]; then
        echo "skipping $d (not a dir)"
        continune
    fi
    echo "processing $d"
    wipefile="$d"/wipe"$RANDOM"
    dd if=/dev/zero of="$wipefile" bs=8192
    rm -rf "$wipefile"
    let processed++
done

if [ "$processed" -gt 0 ]; then
    echo ""
    echo "Processed $processed directories."
else
    echo "No actions performed."
fi

