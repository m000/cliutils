# -*- coding: utf-8 -*-
import os
from functools import partial

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
    'path_exists':      os.path.exists,
    'basename':         os.path.basename,
    'is_file':          os.path.isfile,
    'is_dir':           os.path.isdir,
}
