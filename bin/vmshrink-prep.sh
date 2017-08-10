#!/bin/bash
# Script for preparing VM disks for shrinking/compacting.
# After running the script, poweroff and use VBoxManage to compact the image:
#   VBoxManage modifyhd --compact foo.vdi
#
# Short url: http://bit.ly/vmshrink-prep

SCRIPT="$(basename "$0")"
DDBLOCK=8192
let processed=0

if [ "$#" -eq 0 ]; then
    echo "Script for preparing VM disks for shrinking/compacting."
    echo "Usage: $SCRIPT dir1 dir2 ..."
    exit 1
fi

function wipe_swap() {
    if [ "$EUID" -ne 0 ]; then
        echo "skipping swap (not root)"
        return
    fi

    local swp
    local swp_uuid
    # use process substitution rather than a pipe to feed while
    # avoids running in subshell so we can modify processed
    while read swp; do
        swp_uuid=$(blkid -o export "$swp" | grep ^UUID= | cut -d= -f2)
        printf "wiping swap (%s, uuid=%s)\n\t" "$swp" "$swp_uuid"
        printf "off "
        swapoff -U "$swp_uuid"
        printf "wipe "
        dd if=/dev/zero of="$swp" bs=$DDBLOCK 2>/dev/null
        printf "make "
        mkswap -U "$swp_uuid" "$swp" >/dev/null
        printf "on "
        swapon -U "$swp_uuid"
        printf "\n"
        let processed++
    done < <(tail -n +2 < /proc/swaps | awk '{print $1}')
}

function wipe_empty() {
    local wipefile="$1"/wipe"$RANDOM"

    printf "wiping empty ($d)\n\t" "$1"
    printf "make "
    touch "$wipefile"
    printf "wipe "
    dd if=/dev/zero of="$wipefile" bs=$DDBLOCK 2>/dev/null
    printf "rm "
    rm -f "$wipefile"
    printf "\n"
    let processed++
}

for d in "$@"; do
    if [ "$d" = "swap" ]; then
        wipe_swap
    elif [ -d "$d" ]; then
        wipe_empty "$d"
    else
        echo "skipping $d (not a dir)"
    fi
done

if [ "$processed" -gt 0 ]; then
    echo ""
    echo "Processed $processed locations"
else
    echo "No actions performed."
fi

