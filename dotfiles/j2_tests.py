# -*- coding: utf-8 -*-
import os

assert sys.version_info >= (2,5), "Need at least Python 2.5."
if sys.version_info < (3,0):
    from shutilwhich import which
else:
    from shutil import which

### Tests ###########################################################
def exists(p):
    ''' Returns true if path p exists.
        Tilde and shell variables in d are expanded before testing.
    '''
    if not p:
        return False
    else:
        p = os.path.expandvars(os.path.expanduser(p))
        return os.path.exists(p)

def dir(d):
    ''' Returns true if d is a directory.
        Tilde and shell variables in d are expanded before testing.
    '''
    if not d:
        return False
    else:
        d = os.path.expandvars(os.path.expanduser(d))
        return os.path.isdir(d)

def file(f):
    ''' Returns true if f is a file.
        Tilde and shell variables in f are expanded before testing.
    '''
    if not f:
        return False
    else:
        f = os.path.expandvars(os.path.expanduser(f))
        return os.path.isfile(f)

def installed(b):
    ''' Returns true if an executable named b exists in the current path.
        b may also be a list of binaries.
    '''
    blist = b if isinstance(b, list) else [b,]
    return all([which(b) for b in blist])

# vim:set tabstop=4 softtabstop=4 expandtab:
