#!/bin/bash
# Locks the screen if the host has been recently rebooted.
# Useful for locking the screen on auto-login, but not on a normal login.

export LC_ALL=C
export LOCK_TIMEOUT=5

# Sed magic from http://stackoverflow.com/a/1665662/277172:
# tx branches to label x if the substitution was successful, d deletes line, :x is a marker for label x
theuptime=$(uptime -p | sed -r 's/^up\s+([0-9]+)\s+minutes.*$/\1/;tx;d;:x')

if [ "$theuptime" = "" ]; then
	exit 0
fi
if [ "$theuptime" -lt "$LOCK_TIMEOUT" ]; then
	gnome-screensaver-command -l
fi
exit 0
