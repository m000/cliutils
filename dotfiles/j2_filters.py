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


### Path filters ####################################################
path_basename = os.path.basename
path_dirname = os.path.dirname
path_expand = lambda p: os.path.expandvars(os.path.expanduser(p)),
path_join = lambda l: None if not all(l) else os.path.join(*l)

### Shell filters ###################################################
#sh_quote = pipes.quote
#sh_which = which
#sh_expand = lambda s: os.path.expandvars(os.path.expanduser(s))
#sh_expanduser = os.path.expanduser
#sh_expandvars = os.path.expandvars

### Debug filters ###################################################
debug_type = lambda x: type(x)

### Misc filters ####################################################
def hr(text=None, width=80, fill='#'):
    ''' Creates an ascii horizontal ruler.
    '''
    if text:
        return ('%s %s ' % (3*fill, text)).ljust(width, fill)
    else:
        return ''.ljust(width, fill)

def bool(var=None, true_=None, false_=None):
    ''' Evaluates var to true or false.
    '''
    if var:
        return ('%s' % (true_ if true_ is not None else str(True).lower()))
    else:
        return ('%s' % (false_ if false_ is not None else str(False).lower()))

# vim:set tabstop=4 softtabstop=4 expandtab:
