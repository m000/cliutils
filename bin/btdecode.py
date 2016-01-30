#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Decodes bencoded bit torrent files and dumps them to stdout.
#
# Original on: https://github.com/m000/cliutils
#

from __future__ import print_function
import sys
from pprint import pprint

HR_LENGTH = 70

try:
    import bencode
except ImportError:
    print("Please install the bencode python module. E.g.: sudo pip install bencode", file=sys.stderr)

if __name__ == '__main__':

    if len(sys.argv) < 1:
        print("Bit Torrent file decode wrapper.", file=sys.stderr)
        print("Usage: %s <datfile>" % (sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    ################################################
    # Read resume data.
    ################################################
    with open(sys.argv[1]) as dat_in:
        resume_dat = bencode.bdecode(dat_in.read())
        pprint(resume_dat)

