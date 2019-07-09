#!/bin/bash
#
# flac2mp3.sh 
# 
# A script to convert a single flac file to mp3 while preserving metadata
#
# Copyright 2011-2012 Torben Deumert. All rights reserved.
#
# File		: flac2mp3.sh
# Author	: Torben Deumert (tordeu at googlemail dot com)
# Date		: 2012-06-05
# Version	: 2012-06-05
# License	: FreeBSD License (see "License" section below)
#
#==============================[ Description ]========================================
# 
# flac2mp3.sh will preserve the following metadata:
# 	- TITLE (Track Title)
#	- ARTIST (Track Artist)
#	- ALBUM (Album Title)
#	- YEAR
#	- COMMENT
#	- TRACKNUMBER (Number of the track)
#	- TRACKTTOTAL (Total number of tracks)
#	- GENRE
#
# Note:
#   flac2mp3.sh calls lame for the conversion, which will overwrite existing mp3 files
#   by default without asking.
#
#==============================[ Usage ]========================================
#
# Usage:
#	flac2mp3.sh <VBRQUALITY> <FLACFILE> <MP3FILE> [mtime]
#
# Examples:
#	flac2mp3.sh 6 track.flac track.mp3
#	flac2mp3.sh 6 track.flac track.mp3 mtime
#
# The <QUALITY> parameter corresponds to the -V option of lame, so you can use a value between
# 0 and 9, where 0 gives the highest quality, but biggest filesize and 9 gives the worst quality,
# but the smallest file.
#
# Adding "mtime" is useful for avoiding a lot of unnecessary conversion
# when using this script for entire audio/music libraries. When mtime is
# used, the conversion will only be done if
#	- the mp3 file does not exist yet
#	- the flac file is newer than the mp3 file
# But if the mp3 file is newer than the flac file, it indicates that the
# mp3 file was created after the flac file was last modified, so it is
# up-to-date and does not need to be converted. 
# To force conversion on all or a specific file, run this script without
# "mtime" at the end. 
#
# for f in *.flac; do flac2mp3.sh 0 "$f" "${f%%.flac}".mp3; done
#
#==============================[ License ]========================================
#
# Copyright 2011-2012 Torben Deumert. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.
# 
#    2. Redistributions in binary form must reproduce the above copyright notice, this list
#       of conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of <copyright holder>.
#=================================================================================

# let's make the script a little more robust
set -u			# exit if the script tries to use an unbound variable
set -e			# exit we a command fails 
set -o pipefail # exit if a command in a pipe fails

# check and read the parameters
if [[ !($# -eq 3) ]] && [[ !($# -eq 4) ]]; then 
   	echo "usage: flac2mp3.sh <VBRQUALITY> <FLACFILE> <MP3FILE> [mtime]"
   	echo ""
   	echo "When using 'mtime' at the end the conversion will only take"
   	echo "place, if the mp3 file does not exist yet or the flac file"
   	echo "is newer, which indicates that the mp3 file is out of date."  
	exit 1
fi

V=$1
FLAC=$2
MP3=$3

# Let's check for the 4th parameter
if [[ ($# -eq 4) ]]; then
  COND=$4;
else
  COND=""
fi

# This encodes the FLAC to MP3
function encode() {
	echo "let's encode"
	# extract the tags from the flac file
	for tag in TITLE ARTIST ALBUM DATE COMMENT TRACKNUMBER TRACKTOTAL GENRE; do
		eval "$tag=\"`metaflac --show-tag=$tag "$FLAC" | sed 's/.*=//'`\""
	done

	# start the conversion and include the extracted tags
	flac -cd "$FLAC" | lame -V "$V" --add-id3v2 --tt "$TITLE" --ta "$ARTIST" --tl "$ALBUM" --ty "$DATE" --tc "$COMMENT" --tn "$TRACKNUMBER/$TRACKTOTAL" --tg "$GENRE" - "$MP3"
}

# Check if COND was used
if [ "$COND" == "" ]; then
	# It wasn't, so we will just go ahead and encode the file
	echo "Encoding $FLAC -> $MP3"
	encode
# If COND is "mtime" we will only convert if the mp3 is non-existant or older
# than the flac
elif [ "$COND" == "mtime" ]; then
	# If the mp3 file does not exist yet?
	if [[ ! -e "$MP3" ]]; then
		# we will start encoding
		echo "Encoding $FLAC -> $MP3 (because the mp3 file does not exist yet)"
		encode
	# Is the flac file newer than the mp3 file?
	elif [[ "$FLAC" -nt "$MP3" ]]; then
		# then let's encode as well
		echo "Encoding $FLAC -> $MP3 (because the flac file is newer than the mp3 file)"
		encode
	# Otherwise (the mp3 exists, but the flac is older than the mp3),
	# we do not need to encode
	else
		echo "NOT encoding (the mp3 file is up-to-date)"
	fi
fi	

