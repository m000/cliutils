# OpenVPN Config Files

This is a simple collection of OpenVPN files to help with quick bootstrapping
of an OpenVPN server.
Similar with the [dotfiles collection](../dotfiles), the files are generated
using [Jinja2](http://jinja.pocoo.org/) templates, through the
[j2cli](https://github.com/kolypto/j2cli) command line wrapper.
The generated dot files are first written in a local directory
(default: `output`) and then copied to `/etc` using
[rsync](https://rsync.samba.org/).

## Prerequisites

### OpenVPN and EasyRSA

On the machine that you want to use as OpenVPN server, run as root:

```
apt-get install openvpn easy-rsa
```

### Python Environment

To setup a working python environment to generate the OpenVPN
configurations, first you neet to install `virtualenv` and `pip`.
As root, run:

```
apt-get install python-virtualenv python-pip
pip install -U pip
```

Then create a new virtual environment and install the required
python packages:

```
virtualenv openvpn_pyenv
. ./openvpn_pyenv/bin/activate
pip install -r requirements.txt
```


echo 1 > /proc/sys/net/ipv4/ip_forward
You will need to edit /etc/sysctl.conf and change the line that says net.ipv4.ip_forward = 0 to net.ipv4.ip_forward = 1


## How to use the dotfiles

### Python environment
Install the required Python packages in a local environment:
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

## Resources
* [Jinja2 Template Designer Documentation](http://jinja.pocoo.org/docs/dev/templates/)
