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
import argparse

MIN_SAVEPATH_LENGTH = 3
SAVEPATH_SAMPLE_SIZE = 10
SAVEPATH_SAMPLE_RETRIES = 5
HR_LENGTH = 70

try:
    import bencode
except ImportError:
    print("Please install the bencode python module. E.g.: sudo pip install bencode", file=sys.stderr)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='uTorrent tidy script. Moves completed files to directories matching their label. Writes a new resume data file.')
    parser.add_argument("-n", "--dry-run",
        action="store_true", dest="dryrun", default=False,
        help="only print the actions to be performed"
    )
    parser.add_argument("-p", "--save-path",
        action="store", dest="savepath", default=None,
        help="manually set the torrent save path"
    )
    parser.add_argument("--xfs",
        action="store_true", dest="xfs", default=False,
        help="allow moving files across filesystems"
    )
    parser.add_argument('resumedat_in', help='input utorrent resume.dat file')
    parser.add_argument('resumedat_out', help='output utorrent resume.dat file')
    args = parser.parse_args()

    ################################################
    # Read resume data.
    ################################################
    with open(args.resumedat_in, 'rb') as dat_in:
        resume_dat = bencode.bdecode(dat_in.read())

    print(HR_LENGTH*"*")
    print("Dry Run: %s, Move Across FS: %s, Manual Savepath: %s" % (args.dryrun, args.xfs, args.savepath))
    print(HR_LENGTH*"*")

    ################################################
    # Calculate the save path for the data.
    ################################################
    if args.savepath:
        savepath = args.savepath
    else:
        allpaths = [ resume_dat[t]['path'] for t in resume_dat
            if t.endswith('.torrent') and os.path.exists(resume_dat[t]['path'])
        ]
        savepath = os.path.commonprefix(allpaths)
        if (len(savepath) < MIN_SAVEPATH_LENGTH):
            # Failed to calculate savepath from all used paths. Try sampling.
            for i in xrange(SAVEPATH_SAMPLE_RETRIES):
                savepath = os.path.commonprefix( random.sample(allpaths, min(SAVEPATH_SAMPLE_SIZE, len(allpaths))) )
                if (len(savepath) < MIN_SAVEPATH_LENGTH):
                    break
            if (len(savepath) < MIN_SAVEPATH_LENGTH):
                print("Could not calculate a savepath using sampling.", file=sys.stderr)
                print("You may want to retry in a few secs, or manually set the savepath.", file=sys.stderr)
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
        if not args.xfs and not on_same_fs(metadata['path'], savepath):
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
            if not args.dryrun:
                shutil.move(path_orig, dir_dest)
            resume_dat[torrent]['path'] = path_dest
            print("mv '%s' '%s'" % (path_orig, dir_dest))
            print(HR_LENGTH*"-")
    finally:
        ################################################
        # Write updated resume data.
        ################################################
        with open(args.resumedat_out,'wb+') as dat_out:
            dat_out.write(bencode.bencode(resume_dat))
