#!/bin/bash

while (( "$#" )); do
    t=$(mktemp -t greek2utf8XXX)
    iconv -f iso8859-7 -t utf-8 < "$1" > "$t"
    mv "$t" "$1"
    shift
done

