#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# uTorrent cleanup script.
# Moves downloads to the proper dir, based on their label.
# Useful after assigning new labels to torrents.
#
# ** SHUT DOWN uTorrent BEFORE RUNNING **
#
# Original on: https://github.com/m000/cliutils
#

from __future__ import print_function
import os
import os.path
import sys
import shutil
import random
import tempfile
from pprint import pprint

MIN_SAVEPATH_LENGTH = 3
SAVEPATH_SAMPLE_SIZE = 10
MOVE_ACROSS_FILESYSTEMS = False
HR_LENGTH = 70
DRY_RUN = False

try:
    import bencode
except ImportError:
    print("Please install the bencode python module. E.g.: sudo pip install bencode", file=sys.stderr)

if __name__ == '__main__':

    if len(sys.argv) < 3:
        print("uTorrent tidy script. Moves completed files to directories matching their label. Writes a new resume data file.", file=sys.stderr)
        print("Usage: %s <datfile> <newdatfile>" % (sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    if not sys.argv[1].lower().endswith('.dat'):
        print("File '%s' does not have a '.dat' extension." % (sys.argv[1]), file=sys.stderr)
        sys.exit(1)

    if not sys.argv[2].lower().endswith('.dat'):
        print("File '%s' does not have a '.dat' extension." % (sys.argv[2]), file=sys.stderr)
        sys.exit(1)

    ################################################
    # Read resume data.
    ################################################
    with open(sys.argv[1]) as dat_in:
        resume_dat = bencode.bdecode(dat_in.read())

    ################################################
    # Calculate the save path for the data.
    ################################################
    allpaths = [ resume_dat[t]['path'] for t in resume_dat
            if t.endswith('.torrent') and os.path.exists(resume_dat[t]['path'])
    ]
    savepath = os.path.commonprefix(allpaths)
    if (len(savepath) < MIN_SAVEPATH_LENGTH):
        # Failed to calculate savepath from all used paths. Try sampling.
        for i in xrange(5):
            savepath = os.path.commonprefix(random.sample(allpaths, SAVEPATH_SAMPLE_SIZE))
            if (len(savepath) < MIN_SAVEPATH_LENGTH):
                break
        if (len(savepath) < MIN_SAVEPATH_LENGTH):
            # TODO: Add support for a hardcoded fallback save path.
            print("Could not calculate a savepath using sampling.", file=sys.stderr)
            print("You may want to retry in a few secs, or reduce the SAVEPATH_SAMPLE_SIZE.", file=sys.stderr)
            sys.exit(1)
    print("Savepath is: %s." % (savepath))

    ################################################
    # Check what has to be done.
    ################################################
    actions = {}
    for torrent, metadata in resume_dat.iteritems():
        # not torrent
        if not torrent.endswith('.torrent'):
            print("Skipping '%s'. Not a torrent." % (torrent))
            continue
        if 'label' not in metadata:
            print("Skipping '%s'. No label." % (torrent))
            continue
        if len(metadata['labels']) > 1:
            # This isn't possible AFAIK. Add a check nevertheless.
            print("Too many labels for '%s'. Don't know how to handle them." % (torrent), file=sys.stderr)
            sys.exit(1)
        if metadata['completed_on'] == 0:
            print("Skipping '%s'. Not completed." % (torrent))
            continue
        if not os.path.exists(metadata['path']):
            print("Skipping '%s'. Path does not exist." % (torrent))
            continue
        on_same_fs = lambda p1, p2: os.stat(p2).st_dev == os.stat(p2).st_dev
        if not MOVE_ACROSS_FILESYSTEMS and not on_same_fs(metadata['path'], savepath):
            print("Skipping '%s'. Not on the same filesystem with savepath." % (torrent))
            continue

        p = metadata['path']
        l = metadata['label']
        d_from = os.path.dirname(p)
        d_to = os.path.join(savepath, l)
        p_to = os.path.join(d_to, os.path.basename(p))

        if d_from == d_to:
            print("Skipping '%s'. Already in the correct directory." % (torrent))
            continue

        # everything ok, add an action
        actions[torrent] = (p, p_to, d_to)

    ################################################
    # Execute actions.
    ################################################
    print(HR_LENGTH*"-")
    try:
        for torrent in actions:
            path_orig, path_dest, dir_dest = actions[torrent]

            # Remove any empty path components of path_dest.
            try:
                os.removedirs(path_dest)
            except OSError:
                pass

            # Create dir_dest.
            try:
                os.makedirs(dir_dest, mode=0o755)
                print("mkdir -p '%s'" % (dir_dest))
            except OSError:
                pass

            # Do the moving.
            if not DRY_RUN:
                shutil.move(path_orig, dir_dest)
            resume_dat[torrent]['path'] = path_dest
            print("mv '%s' '%s'" % (path_orig, dir_dest))
            print(HR_LENGTH*"-")
    finally:
        ################################################
        # Write updated resume data.
        ################################################
        with open(sys.argv[2],'wb+') as dat_out:
            dat_out.write(bencode.bencode(resume_dat))
