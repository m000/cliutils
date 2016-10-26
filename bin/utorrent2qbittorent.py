#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Original on: https://github.com/m000/cliutils

'''
uTorrent to qBittorrent migration script.

The purpose of the script is to:
    a. Remove the matching torrents from uTorrent's resume.dat.
    b. Move the download files from uTorrent download dir to
       qBittorrent download dir.
    c. Export the .torrent file in a directory so you can import
       it to qBittorrent.

Importing to qBittorrent is a three-step manual process:
    a. Add the .torrent file in paused state.
    b. Force a recheck on the torrent data.
    c. Start the torrent.

** SHUT DOWN uTorrent BEFORE RUNNING **

A more complete ruby script with similar goals can be found here:
    https://gist.github.com/danzig666/5468d7dc2f7421c887e7
The ruby script also converts metadata to qBittorrent format and
imports them.
'''

from __future__ import print_function
import os, sys, subprocess, shutil, datetime
import re, hashlib, argparse
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
    import bendcode
except ImportError:
    print_banner(["Please install the bencode/bendcode python modules. E.g.: sudo pip install bencode bendcode",], fill='!', file=sys.stderr)
    raise
try:
    import emoji
except ImportError:
    print_hr("Consider installing the emoji python module for nicer output. E.g.: sudo pip install emoji", fill='!', file=sys.stderr)


###############################################################################
#### Functionality helpers ####################################################
###############################################################################
def check_torrent(torrent, metadata, args):
    ''' Checks the torrent and its metadata to determine whether it
        should be moved. For torrents that should be moved, a tuple
        is returned. Otherwise a message is printed and None is returned.
    '''
    use_emojis = True if 'emoji' in sys.modules else False
    if use_emojis:
        emj = lambda s: emoji.emojize(s, use_aliases=True).encode('utf-8')

    try: width = int(subprocess.check_output(['stty', 'size']).split()[1])
    except: width = 80

    def _torrent_hash(torrent):
        torrent_f = os.path.join(args.ut_path, torrent)
        print(torrent_f)
        with open(torrent_f, 'rb') as torrent_f_in:
            d = torrent_f_in.read()
            try: # try default bencode module - faster
                metainfo = bencode.bdecode(d)
            except bencode.BTL.BTFailure:
                pass
            try: # fallback to bendcode - more robust
                metainfo = bendcode.decode(d)
            except:
                return None
            return hashlib.sha1(bencode.bencode(metainfo['info'])).hexdigest()  

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

    if not torrent.endswith('.torrent'): # unresolved magnet links
        print(_make_message(torrent, 'skip', 'not a torrent'))
        return None
    if metadata['completed_on'] == 0 and not args.incomplete:
        print(_make_message(torrent, 'skip', 'incomplete'))
        return None
    if not os.path.exists(metadata['path']) and not args.incomplete:
        print(_make_message(torrent, 'skip', 'invalid path'))
        return None
    if len(metadata['labels']) > 1:
        print(_make_message(torrent, 'wtf', 'multiple labels'))
        return None
    if not args.all:
        if args.tag_re is not None:
            m = re.match(args.tag_re, metadata['label'], flags=re.I|re.U)
            if m is None:
                print(_make_message(torrent, 'skip', 'not matching tag RE'))
                return None
        elif args.name_re is not None:
            m = re.match(args.name_re, metadata['caption'], flags=re.I|re.U)
            if m is None:
                print(_make_message(torrent, 'skip', 'not matching name RE'))
                return None
        else:
            print(_make_message(torrent, 'wtf', 'weird match config'))
            return None

    # This is just an integrity check for now.
    # Eventually, it can be used to directly import torrents into qBittorrent.
    # Torrents are saved as thash.torrent along with a thash.fastresume file.
    thash = _torrent_hash(torrent)
    if thash is None:
        print(_make_message(torrent, 'skip', 'bad torrent'))
        return None

    # Get path, label, tag.
    p = metadata['path']
    l = metadata['label']

    # Make from/to directories. A number of dashes from the label will be
    # converted to subdirectories, according to args.ndash.
    d_from = os.path.dirname(p)
    d_to = os.path.join(args.qt_dlpath, *l.split('-', args.ndash))
    p_to = os.path.join(d_to, os.path.basename(p))
    
    # Check directories.
    on_same_fs = lambda p1, p2: os.stat(p1).st_dev == os.stat(p2).st_dev
    if d_from == d_to:
        print(_make_message(torrent, 'wtf', 'no action required'))
        return None
    elif not args.xfs:
        # Check for same fs.
        if os.path.exists(d_to) and not on_same_fs(os.path.dirname(d_from), os.path.dirname(d_to)):
            print(_make_message(torrent, 'xfs', 'xfs disabled'))
            return None
        elif not on_same_fs(os.path.dirname(d_from), os.path.dirname(args.qt_dlpath)):
            print(_make_message(torrent, 'xfs', 'xfs disabled'))
            return None

    # # everything ok - return an action tuple
    print(_make_message(torrent, 'move', 'moving'))
    return (p, p_to, d_to)    


###############################################################################
#### Real action ##############################################################
###############################################################################
def main():
    parser = argparse.ArgumentParser(description="""uTorrent to qBittorrent migration script.
        Reads uTorrent's resume.dat file and moves files to qBittorrent downloads directory.
        Writes a new resume.dat file that excludes the torrents that were moved.
    """)
    parser.add_argument("-n", "--dry-run",
        action="store_true", dest="dryrun", default=False,
        help="only print the actions to be performed"
    )
    parser.add_argument("--incomplete",
        action="store_true", dest="incomplete", default=False,
        help="process incomplete torrents"
    )
    parser.add_argument("--xfs",
        action="store_true", dest="xfs", default=False,
        help="allow moving files across filesystems"
    )
    parser.add_argument("--dash-to-slash",
        action="store", type=int, dest="ndash", default=1,
        help="converts the specified number of dashes from the torrent tag/label to slashes (default: 1)"
    )
    parser.add_argument("--ut-path", default=None,
        action="store", dest="ut_path", help="set the uTorrent config path, in case it is not the one containing resume.dat"
    )
    parser.add_argument("-e", "--export-path", default=None,
            action="store", dest="export_path", help="where to export the torrent files (default: home dir)"
    )
    match = parser.add_mutually_exclusive_group(required=True)
    match.add_argument('--name', action="store", dest="name_re", help="only process torrents with caption matching this re")
    match.add_argument('--tag', action="store", dest="tag_re", help="only process torrents with labels matching this re")
    match.add_argument('--all', action="store_true", dest="all", default=False, help="process all torrents")
    parser.add_argument("--qt-dlpath", required=True,
        action="store", dest="qt_dlpath", help="set the qBittorrent download path"
    )
    parser.add_argument('resume_dat', metavar='resume.dat', help='input utorrent resume.dat file')
    args = parser.parse_args()

    ################################################
    # Read resume.dat.
    ################################################
    resume_dat_f = args.resume_dat
    with open(resume_dat_f, 'rb') as resume_dat_in:
        resume_dat = bencode.bdecode(resume_dat_in.read())

    ################################################
    # Set uTorrent config path and torrent export path.
    ################################################
    if args.ut_path is None:
        args.ut_path = os.path.dirname(os.path.abspath(resume_dat_f))
    if args.export_path is None:
        args.export_path = os.path.expanduser("~")

    ################################################
    # Print active configuration.
    ################################################
    cfg_banner = [ 
            'Dry Run: %s' % (args.dryrun),
            'Move Across FS: %s' % (args.xfs),
            'uTorrent config path: %s' % (args.ut_path),
            'qBittorrent download path: %s' % (args.qt_dlpath),
    ]
    print_banner(cfg_banner)
    print('')

    ################################################
    # Check what has to be done.
    ################################################
    print_banner(['Analyzing actions'])
    actions = {}
    for torrent, metadata in resume_dat.iteritems():
        action = check_torrent(torrent, metadata, args)
        if action is not None:
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
            torrent_from = os.path.join(args.ut_path, torrent)
            if not args.dryrun:
                shutil.move(path_orig, dir_dest)
                shutil.move(torrent_from, args.export_path)
            del resume_dat[torrent]
            print("mv '%s' '%s'" % (path_orig, dir_dest))
            print("mv '%s' '%s'" % (torrent_from, args.export_path))
            print_hr(fill='-')
    finally:
        ################################################
        # Make a backup for resume.dat and write updated file.
        ################################################
        resume_dat_bak_f = '%s.%s.bak' % (resume_dat_f, datetime.datetime.now().strftime("%Y%m%d_%H%M%S"))
        print("Making a backup of resume.dat to %s." % (resume_dat_bak_f))
        if not args.dryrun:
            shutil.copyfile(resume_dat_f, resume_dat_bak_f)
        print("Writing new resume.dat to %s." % (resume_dat_f))
        if not args.dryrun:
            with open(resume_dat_f,'wb+') as resume_dat_out:
                resume_dat_out.write(bencode.bencode(resume_dat))
        print_hr(fill='-')
    print('Finished!')

if __name__ == '__main__':
    main()


