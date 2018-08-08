#!/usr/bin/env python3
# -*- coding: utf-8 -*-

'''
    Rename a list of files using another list of files as reference.
'''

import argparse
import pathlib
import difflib

import logging
logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)

def do_confirm(prompt_text=None, default_response=False):
    prompt_text = prompt_text if prompt_text is not None else 'Confirm'
    prompt_fmt = '%s [%s]|%s: ' if default_response else '%s %s|[%s]: '
    prompt = prompt_fmt % (prompt_text, 'y', 'n')

    while True:
        answer = input(prompt).lower()
        if not answer:
            return default_response
        if answer == 'y':
            return True
        elif answer == 'n':
            return False
        else:
            logging.error('Invalid answer: %s', answer)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''Rename a list of files using another list of files as reference.
    ''')
    parser.add_argument('-i', '--interactive', action='store_true', help="prompt for confirmation of actions")
    parser.add_argument('-a', '--append', action='store', dest='stem', metavar='STEM', help="text to append to the stem of reference files")
    parser.add_argument('-s', '--suffix', action='store', dest='suffix', metavar='SUFFIX', help="text to use instead of the suffix of the reference files")
    parser.add_argument('reference', metavar='REFERENCE', help='reference list')
    parser.add_argument('target', metavar='TARGET', help='target list')

    args = parser.parse_args()
    logging.debug(args)

    reference = pathlib.Path(args.reference)
    target = pathlib.Path(args.target)
    with reference.open() as ref:
        with target.open() as tgt:
            # iterate files and rename
            for refl, tgtl in zip(ref, tgt):
                refp = pathlib.Path(refl.rstrip('\n'))
                tgtp = pathlib.Path(tgtl.rstrip('\n'))

                # make sure we're trying to rename something that exists
                if not tgtp.exists():
                    for tgtp_alt in [target.parent / tgtp.name, ]:
                        if tgtp_alt.exists():
                            tgtp = tgtp_alt
                            break
                    else:
                        logging.error('Could not find target file "%s" to rename.', tgtp)
                        continue

                # construct new file name for target file
                basename_new = '%s%s%s' % (
                        refp.stem,
                        args.stem if args.stem is not None else '',
                        refp.suffix if args.suffix is None else args.suffix
                )
                tgtp_new = tgtp.parent / basename_new

                # rename
                print('"%s" ->\n\t"%s"' % (tgtp, tgtp_new))
                if not args.interactive or (args.interactive and do_confirm()):
                    tgtp.rename(tgtp_new)
                if args.interactive:
                    print('')

            # check for length mismatch in reference and target lists
            ref_eof = True if not ref.readline() else False
            tgt_eof = True if not tgt.readline() else False
            if ref_eof and not tgt_eof:
                logging.warning('Reference list shorter than target list.')
            elif not ref_eof and tgt_eof:
                logging.warning('Target list shorter than reference list.')


    #print(list(zip(reference, target)))
    #ref = pathlib.Path(args.ref)
    #for d in args.dirs:
        #p = pathlib.Path(d)
        #if not p.exists():
            #logging.warning('Skipping "%s". Does not exist.', p)
            #continue
        #elif not p.is_dir():
            #logging.warning('Skipping "%s". Not a directory.', p)
            #continue

        # get directory contents and filter out results based on flags
        #contents = [it.name for it in p.iterdir()
            #if not (
                #(not args.keep_exact and it.name == ref.name) or
                #(not args.keep_hidden and it.name.startswith('.')) or
                #(args.only_dirs and not it.is_dir()) or
                #(args.only_files and not it.is_file())
            #)
        #]

        # get and print close matches
        #matches = difflib.get_close_matches(ref.name, contents, n=args.n, cutoff=args.cutoff)
        #for f in matches:
            #print(p / f)

# vim: ts=4 sts=4 sw=4 et noai :
