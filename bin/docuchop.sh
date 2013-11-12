#!/bin/bash
# Scene chopper for "documentaries".

##################################################################
# Tool locations
##################################################################
FFMPEG="ffmpeg"
FFPROBE="ffprobe"
JQ="jq"
RM="rm"
PV="pv"
PRINTF="printf"

##################################################################
# Runtime defaults
##################################################################
# Black scene detection filter options.
# 	d -> Detect black scenes of at least <d>sec
#	pic_th -> A black frame conists of at least <pic_th>% black pixels.
#	pix_th -> A black pixel may be up to <pix_th>% bright.
# http://ffmpeg.org/ffmpeg-filters.html#blackdetect
BD_OPTS=d=.2:pic_th=0.8:pix_th=0.10

# Skip the content up to the first black scene. Useful for most documentaries.
SKIP_FIRST=yes

# For example, produce 8x8 PNG tiles of all keyframes (‘-skip_frame nokey’) in a movie:
# ffmpeg -skip_frame nokey -i file.avi -vf 'scale=128:72,tile=8x8' -an -vsync 0 keyframes%03d.png

##################################################################
# Functions
##################################################################
function analyze() {
    # Analyzes input file and writes results to "$BD_CACHE", "$FR_CACHE" and "$ST_CACHE" files.
    # The first file contains the black detection analysis results in a custom text format.
    # The second file contains the frame analysis results in json format.
    # The third file contains stream information for the file.
    #
    # We duplicate the input file in two fifos.
    # This should allow for reading the file only once.
    local f="$1"

    # options used by black detection
    local bdopts_line="# BD_OPTS=$BD_OPTS"

    # fifos for black detection and frame analysis
    local fifo_bd=/tmp/fifo_bd_$$
    local fifo_fr=/tmp/fifo_fr_$$

    # cache files to be created
    BD_CACHE="$f".bd.cache
    FR_CACHE="$f".fr.cache
    ST_CACHE="$f".st.cache

    # always create streams files - this is cheap
    $FFPROBE -show_format -show_streams -print_format json -v 9 "$f" > "$ST_CACHE"

    # check if we have cached analysis files
    if [ -f "$FR_CACHE" ] && [ -f "$BD_CACHE" ] && grep -q "$bdopts_line" "$BD_CACHE"; then
        echo "Using cached analysis files for $f..."
        return
    fi

    echo "Analyzing $f."

    # create fifos and feed file into them
    mkfifo "$fifo_bd"
    mkfifo "$fifo_fr"
    $PV -peb "$f" | tee "$fifo_bd" "$fifo_fr" >/dev/null &

    # run commands on fifos
    $FFMPEG -i "$fifo_bd" -vf blackdetect="$BD_OPTS" -an -f null - 2> >(tr -u \\r \\n > "$BD_CACHE") &
    $FFPROBE -select_streams v -show_frames -print_format json -v quiet "$fifo_fr" > "$FR_CACHE" &
    wait

    # Append black detection options signature and cleanup fifos.
    echo "$bdopts_line" >> "$BD_CACHE"
    rm "$fifo_fr" "$fifo_bd"
}

function find_next_iframe() {
    local t_start="$1"

    # jqfilter which returns the offset of the first iframe after the specified time
    local jqfilter='[.frames[] | select(.key_frame == 1) | .pkt_dts_time | tonumber | select(.>=%f)] | min'
    $JQ -r "$(printf "$jqfilter" "$t_start")" < "$FR_CACHE"

    # # Use jq to get iframes offsets.
    # t_start=0
    # t_end=0
    # $JQ -r '.frames[] | select(.key_frame == 1) | .pkt_dts_time | tonumber ' < "$FR_CACHE" | while read t; do
    #     t_start="$t_end"
    #     t_end="$t"
    #     [[ "$t_start" == 0 ]] && continue
    #     dt=$(echo "($t_end-$t_start)" | bc -l)
    #     outfile="${f%.*}.$((sc++)).${f##*.}"
    #     [ -f "$outfile" ] && $RM "$outfile"
    #     echo "t_start=$t_start" "dt=$dt" "t_end=$t_end"

    #     # Prepend zeros to $t_start, $dt. ffmpeg won't parse floats in .12345 format.
    #     echo $FFMPEG -ss "0$t_start" -i "$f" -t "0$dt" -acodec copy -vcodec copy "$outfile"</dev/null
    #     [ $sc -gt 10 ] && exit
    # done
    # exit
}

function get_encoding_params() {
    $JQ '.streams[] | select(.codec_type == "audio")' < "$ST_CACHE"
    $JQ '.streams[] | select(.codec_type == "video")' < "$ST_CACHE"

    # codec_name
    # level
    # tag
}

for f in "$@"; do
    [ -r "$f" ] || { echo "Skipping $f." 1>&2; continue; }
    analyze "$f"

    # Reset scene counter.
    sc=1

    # Use jq to get iframes offsets.
    # t_start=0
    # t_end=0
    # $JQ -r '.frames[] | select(.key_frame == 1) | .pkt_dts_time | tonumber ' < "$FR_CACHE" | while read t; do
    #     t_start="$t_end"
    #     t_end="$t"
    #     [[ "$t_start" == 0 ]] && continue
    #     dt=$(echo "($t_end-$t_start)" | bc -l)
    #     outfile="${f%.*}.$((sc++)).${f##*.}"
    #     [ -f "$outfile" ] && $RM "$outfile"
    #     echo "t_start=$t_start" "dt=$dt" "t_end=$t_end"

    #     # Prepend zeros to $t_start, $dt. ffmpeg won't parse floats in .12345 format.
    #     echo $FFMPEG -ss "0$t_start" -i "$f" -t "0$dt" -acodec copy -vcodec copy "$outfile"</dev/null
    #     [ $sc -gt 10 ] && exit
    # done
    # exit

    # Loop on scenes using the detected black scenes.
    # Black scene line format:
    # 	black_start:66.6667 black_end:66.967 black_duration:0.3003
    # We transform each lines to shell variable assignments:
    #   black_start=66.6667; black_end=66.967; black_duration=0.3003
    grep ^black_start "$BD_CACHE" | sed 's/:/=/g; s/  */; /g' | while read l; do
    	# copy old start/end values & assign new ones
    	black_start_prev="$black_start"
    	black_end_prev="$black_end"
    	eval $l

    	if [ "$black_start_prev" = "" ]; then
	    	# first iteration processing
    		[ "$SKIP_FIRST" = "yes" ] && continue
    		t_start=0
    		t_end="$black_start"
    	else
    		# normal processing
    		t_start="$black_start_prev"
    		t_end="$black_start"
    	fi

    	# Construct outfile & remove old outfile.
		outfile="${f%.*}.$((sc++)).${f##*.}"
		[ -f "$outfile" ] && $RM "$outfile"

		echo "--------------------------------"
        t_middle=$(find_next_iframe "$t_start")
        dt1=$(echo "($t_middle-$t_start)" | bc -l)
        dt2=$(echo "($t_end-$t_middle)" | bc -l)


        get_encoding_params 

		# Process. Put the -ss argument after the -i argument. Slower but supposedly more accurate.
		# Apparently ffmpeg also reads chars from stdin. Use /dev/null as stdin or suffer! 
		# http://ubuntuforums.org/showthread.php?t=1582957
        echo "t_start=$t_start" "t_middle=$t_middle" "t_end=$t_end"
        echo $FFMPEG -ss "$t_start"  -i "$f" -t "$dt1" -c:a copy -c:v mpeg4 -tag:v XVID -profile:v 15 -level:v 5 -preset slow "$outfile"</dev/null
    	echo $FFMPEG -ss "$t_middle" -i "$f" -t "$dt2" -c:a copy -c:v copy "$outfile"</dev/null
        echo $FFMPEG -i concat:'z1.m.1.avi|z2.m.1.avi' -c copy foo.avi
    	# mencoder -ss "$t_start"  -endpos "$t_end" -oac copy -ovc copy "$f" -o "$outfile"</dev/null
        # iframe_probe "$f"
        exit 
    done
done
