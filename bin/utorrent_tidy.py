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
import os, sys, subprocess, shutil
import re, argparse
import random
from pprint import pprint


###############################################################################
#### Format helpers ###########################################################
###############################################################################
def make_hr(text=None, width=None, fill='#'):
    ''' Creates an ascii horizontal ruler.'''
    if width is None:
        try: width = int(subprocess.check_output(['stty', 'size']).split()[1])
        except: width = 80
    return ''.ljust(width, fill) if not text else ('%s %s ' % (3*fill, text)).ljust(width, fill)

def print_hr(text=None, width=None, fill='#', file=sys.stdout):
    ''' Print an ascii horizontal ruler.'''
    print(make_hr(text, width, fill), file=file)

def print_banner(lines=[], width=None, fill='#', file=sys.stdout):
    ''' Prints the specified lines in a banner-like format.'''
    ljust_len = max([len(s) for s in lines])+1
    print_hr(width=width, fill=fill, file=file)
    for l in lines:
        print_hr(l.ljust(ljust_len), width=width, fill=fill, file=file)
    print_hr(width=width, fill=fill, file=file)

def fit_string(s, width, just='l', fill=' '):
    ''' Fits string s to the specified width.'''
    if len(s) > width:
        scont = '...'
        ltail = (width-len(scont))/2
        lhead = width-len(scont)-ltail
        s = '%s%s%s' % (s[:lhead], scont, s[-ltail:])
    if just == 'r':
        return s.rjust(width, fill)
    elif just == 'c':
        return s.center(width, fill)
    else:
        return s.ljust(width, fill)


###############################################################################
#### Influential imports ######################################################
###############################################################################
try:
    import bencode
except ImportError:
    print_banner(["Please install the bencode python module. E.g.: sudo pip install bencode",], fill='!', file=sys.stderr)
    raise
try:
    import emoji
except ImportError:
    print_hr("Consider installing the emoji python module for nicer output. E.g.: sudo pip install emoji", fill='!', file=sys.stderr)


###############################################################################
#### Functionality helpers ####################################################
###############################################################################
def guess_savepath(resume_dat):
    ''' Attempt to guess the save path for uTorrent data.
        This works as following:
            - First the common prefix of all save locations is calculated.
              If this is longer than MIN_SAVEPATH_LENGTH, it is returned.
            - If not, this means that multiple save locations are in use.
              Then, it is attempted to use sampling to guess the most popular
              one. If sampling succeeds, the savepath is returned.
            - Else, an exception is raised.
    '''
    MIN_SAVEPATH_LENGTH = 3
    SAVEPATH_SAMPLE_SIZE = 10
    SAVEPATH_SAMPLE_RETRIES = 5

    allpaths = [ resume_dat[t]['path'] for t in resume_dat
        if t.endswith('.torrent') and os.path.exists(resume_dat[t]['path'])
    ]
    savepath = os.path.commonprefix(allpaths)
    if (len(savepath) < MIN_SAVEPATH_LENGTH):
        # Failed to calculate savepath from all used paths. Try sampling.
        for i in xrange(SAVEPATH_SAMPLE_RETRIES):
            savepath = os.path.commonprefix( random.sample(allpaths, min(SAVEPATH_SAMPLE_SIZE, len(allpaths))) )
            if (len(savepath) >= MIN_SAVEPATH_LENGTH):
                break
        if (len(savepath) < MIN_SAVEPATH_LENGTH):
            raise Exception("Guessing of the uTorrent save path failed. You may want to retry in a few secs, or manually set the savepath.")
    return savepath

def check_torrent(torrent, metadata, args, tagpath):
    ''' Checks the torrent and its metadata to determine whether it
        should be moved. For torrents that should be moved, a tuple
        is returned. Otherwise a message is printed and None is returned.
    '''
    use_emojis = True if 'emoji' in sys.modules else False
    if use_emojis:
        emj = lambda s: emoji.emojize(s, use_aliases=True).encode('utf-8')

    try: width = int(subprocess.check_output(['stty', 'size']).split()[1])
    except: width = 80

    def _make_message(torrent, action, reason):
        values = {
            'torrent': fit_string(torrent, width-20-5-6, 'l'),
            'action': fit_string(action, 5, 'l'),
            'reason': fit_string(reason, 20, 'c'),
        }
        if use_emojis:
            if action == 'skip':
                values['action'] = fit_string(emj(':no_entry:'), 4, 'l')
            elif action == 'ok':
                values['action'] = fit_string(emj(':checkered_flag:'), 5, 'l')
            elif action == 'move':
                values['action'] = fit_string(emj(':arrow_right:'), 4, 'l')
            elif action == 'xfs':
                values['action'] = fit_string(emj(':warning:'), 4, 'l')
            elif action == 'wtf':
                values['action'] = fit_string(emj(':interrobang:'), 4, 'l')
            else:
                values['action'] = fit_string(emj(':question:'), 4, 'l')
        return '{action} | {torrent} | {reason}'.format(**values)             

    if not torrent.endswith('.torrent'):
        print(_make_message(torrent, 'skip', 'not a torrent'))
        return None
    if 'label' not in metadata:
        print(_make_message(torrent, 'skip', 'no label'))
        return None
    if len(metadata['labels']) > 1:
        print(_make_message(torrent, 'wtf', 'multiple labels'))
        return None
    if metadata['completed_on'] == 0:
        print(_make_message(torrent, 'skip', 'incomplete'))
        return None
    if not os.path.exists(metadata['path']):
        print(_make_message(torrent, 'skip', 'invalid path'))
        return None

    # Get path, label, tag.
    p = metadata['path']
    l = metadata['label']
    t = None
    if len(tagpath) > 1:
        tagre = re.compile('\[([^]]*)\]\s*(.*)', re.UNICODE)
        match = tagre.match(l)
        if match:
            t, l = match.groups()

    # Make from/to directories.
    d_from = os.path.dirname(p)
    if t and t in tagpath:
        d_to = os.path.join(tagpath[t], l)
    else:
        d_to = os.path.join(tagpath['default'], l)
    p_to = os.path.join(d_to, os.path.basename(p))

    # Check directories.
    on_same_fs = lambda p1, p2: os.stat(p1).st_dev == os.stat(p2).st_dev
    if d_from == d_to:
        print(_make_message(torrent, 'ok', 'no action required'))
        return None
    elif not args.xfs and not on_same_fs(os.path.dirname(d_from), os.path.dirname(d_to)):
        print(_make_message(torrent, 'xfs', 'xfs disabled'))
        return None

    # everything ok - return an action tuple
    print(_make_message(torrent, 'move', 'move to %s' % (t if t else 'default')))
    return (p, p_to, d_to)    


###############################################################################
#### Real action ##############################################################
###############################################################################
def main():
    parser = argparse.ArgumentParser(description="""uTorrent tidy script.
        Moves completed files to directories matching their label.
        Writes a new resume data file.
        By default, a single torrent save path is assumed. Multiple save paths
        can be used though the --tag-path option which associates label tags to
        specific save paths. The format for tagged labels is "[tag] label".
    """)
    parser.add_argument("-n", "--dry-run",
        action="store_true", dest="dryrun", default=False,
        help="only print the actions to be performed"
    )
    parser.add_argument("-p", "--save-path",
        action="store", dest="savepath", default=None,
        help="manually set the default torrent save path"
    )
    parser.add_argument("-t", "--tag-path",
        action="append", dest="tagpath", metavar='TAG:SAVEPATH',
        help="use SAVEPATH for labels tagged with TAG"
    )
    # todo
    # parser.add_argument("--rewrite-path",
    #     action="append", dest="rewritepath", metaver='FROM:TO',
    #     help="rewrite the save path without actually moving"
    # )
    parser.add_argument("--xfs",
        action="store_true", dest="xfs", default=False,
        help="allow moving files across filesystems"
    )
    parser.add_argument('resumedat_in', help='input utorrent resume.dat file')
    parser.add_argument('resumedat_out', help='output utorrent resume.dat file')
    args = parser.parse_args()

    ################################################
    # Read resume data and calculate save paths.
    ################################################
    with open(args.resumedat_in, 'rb') as dat_in:
        resume_dat = bencode.bdecode(dat_in.read())

    savepath = args.savepath if args.savepath else guess_savepath(resume_dat)
    tagpath = dict([tp.split(':', 1) for tp in args.tagpath]) if args.tagpath else {}
    tagpath['default'] = savepath

    ################################################
    # Print active configuration.
    ################################################
    cfg_banner = [ 
            'Dry Run: %s' % (args.dryrun),
            'Move Across FS: %s' % (args.xfs),
            'Savepath[default]: %s (%s)' % (savepath, 'guessed' if not args.savepath else 'user-set'),
    ]
    for tp in tagpath.iteritems():
        cfg_banner.append('Savepath[%s]: %s' % (tp))
    print_banner(cfg_banner)
    print('')
    
    ################################################
    # Check what has to be done.
    ################################################
    print_banner(['Analyzing actions'])
    actions = {}
    for torrent, metadata in resume_dat.iteritems():
        action = check_torrent(torrent, metadata, args, tagpath)
        # everything ok, add an action.
        if action:
            actions[torrent] = action
    print('')

    ################################################
    # Execute actions.
    ################################################
    print_banner(['Hammer time!%s' % (' (dry run)' if args.dryrun else '')])
    try:
        if not actions:
            print('Nothing to do!')
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
            print_hr(fill='-')
    finally:
        ################################################
        # Write updated resume data.
        ################################################
        with open(args.resumedat_out,'wb+') as dat_out:
            dat_out.write(bencode.bencode(resume_dat))
    print('Finished!')
if __name__ == '__main__':
    main()


