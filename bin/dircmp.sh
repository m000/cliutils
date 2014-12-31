#!/usr/bin/env zsh

d1="$1"
d2="$2"
deldir="./del"

find "$d1" -type f -depth 1 | while read f; do 
    bf="$(basename "$f")"
    f1="$f"
    f2="$d2/$bf"

    [ -f "$f2" ] || continue
    h1=$(md5sum "$f1" | awk '{print $1}')
    h2=$(md5sum "$f2" | awk '{print $1}')
    if [ "$h1" = "$h2" ]; then
        echo "Match for $f1 and $f2."
        if [ "$f2" -ot "$f1" ]; then
            echo "Updating timestamp of $f1."
            touch -r "$f2" "$f1"
        fi
        echo "Moving $f2 to $deldir."
        mv "$f2" "$deldir"/
    fi
done
