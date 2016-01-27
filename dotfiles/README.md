# mstamat's dotfiles

This is a simple solution to keep track of my (and perhaps also your) dot files.
The dot files are compiled from [Jinja2](http://jinja.pocoo.org/) templates, and
a host-specific configuration file. 
Jinja2 usually operates in the context of some web framework. To run it as a 
command line tool we use the [j2cli](https://github.com/kolypto/j2cli) wrapper.

To avoid screw-ups, the generated dot files are first written in a local
directory (default: `output`) and then copied to your home directory using
[rsync](https://rsync.samba.org/).

## How to use the dotfiles

### Python environment
Install the required Python packages in a local environment:
```
virtualenv .dotfiles_pyenv
. ./.dotfiles_pyenv/bin/activate
pip install -r requirements.txt
```

Then each time you want to update your dot files, you only
need to activate the environment:
```
. ./.dotfiles_pyenv/bin/activate
```

### Common Makefile targets
* **all**: Compile all dot files in the output dir.
* **clean**: Remove the output dir and all its contents.
* **copy-dry**: See what files will be copied to your home directory.
* **copy-real**: Copy the generated files to your home directory.
* **diff**: See the differences between generated and installed dot files.
