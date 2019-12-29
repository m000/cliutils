#!/bin/bash

while (( "$#" )); do
    detected=$(chardetect "$1" | awk -F': ' 'NR==1 {print $NF}' | tr A-Z a-z)
    if [ "${detected#*utf-8}" != "$detected" ]; then
        printf "'%s' appears to be encoded in %s. Skipping.\n" "$1" "$detected" >&2
        shift
        continue
    fi

    t=$(mktemp -t greek2utf8XXX)
    iconv -f iso8859-7 -t utf-8 < "$1" > "$t"
    sed -i 's/’/Ά/g' "$t"
    mv "$t" "$1"
    chmod 644 "$1"
    shift
done

