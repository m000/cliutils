docuchop.sh
===========

This simple script patches ``/etc/bootpd.list`` to fix DNS resolution
woes when using Internet Sharing on your Mac. By default your Mac is
specified as the DNS server to connecting clients. But for some reason
clients are not able to resolve DNS names using it. This script makes
the connecting clients to instead use OpenDNS for name resolution,
which fixes the problem.

Requirements
------------

* [jq](http://stedolan.github.io/jq/): For extracting information from [json](http://en.wikipedia.org/wiki/JSON) files.
* [sponge](http://joeyh.name/code/moreutils/): Enables us to avoid using an intermediate file.

