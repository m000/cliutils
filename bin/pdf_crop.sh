#!/bin/bash

if [ "$1" = "${1%.pdf}" ]; then
    echo "Usage: $0 <pdf file>" >&2
    exit 1
fi

pdfcrop "$1"
mv -f "${1%.pdf}-crop.pdf" "$1"
