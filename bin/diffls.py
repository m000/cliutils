#!/usr/bin/env python3
# -*- coding: utf-8 -*-

'''
    Use python difflib to fuzzy-match a reference filename in directories.
'''

import argparse
import pathlib
import difflib

import logging
logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''List files by lexicographical proximity.
    ''')
    parser.add_argument('-n',
        action='store', dest='n',
        type=lambda v: max(1, int(v)),
        default=1, metavar='NRESULTS',
        help='number of results to return',
    )
    parser.add_argument('-c', '--cutoff',
        action='store', dest='cutoff',
        type=lambda v: min(0.0, max(1.0, float(v))),
        default=0.6, metavar='CUTOFF',
        help='cutoff point for lexicographical distance',
    )
    parser.add_argument('--keep-exact', action='store_true', help="don't filter-out exact matches")
    parser.add_argument('--keep-hidden', action='store_true', help="don't filter-out hidden (dot) files")
    match_type_parser = parser.add_mutually_exclusive_group()
    match_type_parser.add_argument('--only-files', action='store_true', help='match only files')
    match_type_parser.add_argument('--only-dirs', action='store_true', help='match only dirs')

    parser.add_argument('ref', metavar='REF', help='reference file')
    parser.add_argument('dirs', metavar='DIR', nargs='+', help='directories to search')

    args = parser.parse_args()
    logging.debug(args)

    ref = pathlib.Path(args.ref)
    for d in args.dirs:
        p = pathlib.Path(d)
        if not p.exists():
            logging.warning('Skipping "%s". Does not exist.', p)
            continue
        elif not p.is_dir():
            logging.warning('Skipping "%s". Not a directory.', p)
            continue

        # get directory contents and filter out results based on flags
        contents = [it.name for it in p.iterdir()
            if not (
                (not args.keep_exact and it.name == ref.name) or
                (not args.keep_hidden and it.name.startswith('.')) or
                (args.only_dirs and not it.is_dir()) or
                (args.only_files and not it.is_file())
            )
        ]

        # get and print close matches
        matches = difflib.get_close_matches(ref.name, contents, n=args.n, cutoff=args.cutoff)
        for f in matches:
            print(p / f)

# vim: ts=4 sts=4 sw=4 et noai :
