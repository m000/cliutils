#!/bin/bash

# This simple script patches /etc/bootpd.list to fix DNS resolution
# woes when using Internet Sharing on your Mac. By default your Mac is
# specified as the DNS server to connecting clients. But for some reason
# clients are not able to resolve DNS names using it. This script makes
# the connecting clients to instead use OpenDNS for name resolution,
# which fixes the problem.

# Required utilities
PLUTIL=plutil
JQ=jq
SPONGE=sponge
SUDO=sudo

bootpdcf=/etc/bootpd.plist                      # Location of bootpd config file.
newdns='"208.67.222.222", "208.67.220.220"'     # List of DNS servers to use. Must be comma separated and quoted.

[ -r "$bootpdcf" ] || { echo "Cannot read bootpd config from '$bootpdcf'." 1>&2; exit 1; }

"$PLUTIL" -convert json -o - "$bootpdcf" |
    "$JQ" '.Subnets[].dhcp_domain_name_server = ['"$newdns"']' |
    "$PLUTIL" -convert xml1 -o - - 
    "$SUDO" "$SPONGE" "$bootpdcf"
