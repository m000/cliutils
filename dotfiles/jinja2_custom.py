# -*- coding: utf-8 -*-
import os
import sys
import pipes
from functools import partial

assert sys.version_info >= (2,5), "Need at least Python 2.5."
if sys.version_info < (3,0):
    from shutilwhich import which
else:
    from shutil import which

# Check ansible's extra filters for inspiration:
#   https://github.com/ansible/ansible/tree/devel/lib/ansible/plugins/filter

def hr(text=None, width=80, fill='#'):
    ''' Creates an ascii horizontal ruler.
    '''
    if text:
        return ('%s %s ' % (3*fill, text)).ljust(width, fill)
    else:
        return ''.ljust(width, fill)


FILTERS = {
    'hr':               hr,
    'sh_expand':        lambda s: os.path.expandvars(os.path.expanduser(s)),
    'sh_expanduser':    os.path.expanduser,
    'sh_expandvars':    os.path.expandvars,
    'sh_quote':         pipes.quote,
    'sh_which':         which,
    'path_exists':      os.path.exists,
    'basename':         os.path.basename,
    'is_file':          os.path.isfile,
    'is_dir':           os.path.isdir,
}
