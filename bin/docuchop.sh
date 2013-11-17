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

function prev_next_iframes() {
    # parses "$FR_CACHE" and returns the position of the first iframes before and after the specified time
    local t_start="$1"
    local jqfilter='reduce (
        .frames[] |
        select(.key_frame == 1) |
        .pkt_dts_time |
        tonumber
    ) as $i (
        {"before":0, "after":0};
        {
            "before": (if $i <= %f then $i else .before end),
            "after": (if .after < %f and $i >= %f then $i else .after end)
        }
    ) | [.[]] | sort | .[]'
    # "$t_start" is used 3 times in the filter!
    $JQ -r "$(printf "$jqfilter" "$t_start" "$t_start" "$t_start")" < "$FR_CACHE"
}

function video_bitrate() {
    # jqfilter that calculates the average video bitrate (kbit/sec) between the defined times.
    # To do so, it uses reduce to calculate the sum of pkt_size and pkt_duration_time
    # of individual frames and then divides the two values.
    #
    # Notes:
    #   In order to avoid warnings, we have to filter out frames without a pkt_dts_time.
    #   In our experience this is only the last frame. 
    #   The defined times should correspond to iframes, otherwise the calculation will be
    #   inaccurate if dt=O(sec).
    local t_start="$1"
    local t_end="$2"

    local jqfilter='reduce (
        .frames[] |
        select(.pkt_dts_time != null) |
        {pkt_size, pkt_duration_time, pkt_dts_time} |
        with_entries(.value |= tonumber) |
        select(.pkt_dts_time>=%f and .pkt_dts_time<%f) |
        {pkt_size, pkt_duration_time}
    ) as $i (
        {"time":0, "size":0};
        {
            "time": (.time+$i["pkt_duration_time"]),
            "size": (.size+$i["pkt_size"])
        }
    ) | .time as $t | .size | (8*(./$t))/1024'
    local br=$($JQ -r "$(printf "$jqfilter" "$t_start" "$t_end")" < "$FR_CACHE")

    # round result to an int
    echo "$br/1" | bc
}

function encoding_options() {
    local brv="$1"

    # Dump info for debugging.
    # $JQ '.streams[] | select(.codec_type == "audio")' < "$ST_CACHE"
    # $JQ '.streams[] | select(.codec_type == "video")' < "$ST_CACHE"

    # echo -n "-c:a copy "
    local jqfilter='.streams[] | select(.codec_type == "audio") |
        "-c:a \(.codec_name) -b:a 64000"
    '
    # Create ffmpeg options for encoding video.
    # Automatic mapping from stream info to encoding options is not always possible*.
    # For this, we first set any custom options and then append them to the options that
    # can be set automatically (i.e. without manual processing).
    #
    # * The problem is also described here: https://trac.ffmpeg.org/ticket/2901
    #   XVID mappings: http://permalink.gmane.org/gmane.comp.video.ffmpeg.user/12241
    local jqfilter='.streams[] | select(.codec_type == "video") |
        (if .codec_tag_string == "XVID" then
            (if .profile == "Advanced Simple Profile" then
                "-profile:v 15 -preset slow"
            else
                ""
            end)
        else
            ""
        end) as $custom |
        "-c:v \(.codec_name) -tag:v \(.codec_tag_string) -bf:v \(.has_b_frames) -level:v \(.level) \($custom) -b:v %s"
    '
    $JQ -r "$(printf "$jqfilter" "$brv")" < "$ST_CACHE"

    # -c:v mpeg4 -tag:v XVID -profile:v 15  -preset slow "$outfile"</dev/null
    # level
}

for f in "$@"; do
    [ -r "$f" ] || { echo "Skipping $f." 1>&2; continue; }
    analyze "$f"

    # Reset scene counter.
    sc=1

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

        # Construct outfiles & remove old outfiles.
        outfile_1="${f%.*}_1.$((sc)).${f##*.}"
        outfile_2="${f%.*}_2.$((sc)).${f##*.}"
        outfile="${f%.*}.$((sc)).${f##*.}"
		[ -f "$outfile" ] && $RM "$outfile"
        [ -f "$outfile_1" ] && $RM "$outfile_1"
        [ -f "$outfile_2" ] && $RM "$outfile_2"

		echo "--------------------------------"
        echo "Processing scene $((sc++))..."
        # Find the iframes before and after the starting time.
        read prev_iframe next_iframe <<< $(prev_next_iframes "$t_start")

        # Calculate times. Fix values<1 to start with 0 or ffmpeg will not be able to parse them.
        t_middle="$next_iframe"
        dt1=$(echo "dt=($t_middle-$t_start); if (dt>=0 && dt<1) {print 0}; print dt;" | bc -l)
        dt2=$(echo "dt=($t_end-$t_middle); if (dt>=0 && dt<1) {print 0}; print dt;" | bc -l)

        # Calculate bitrate for the part that has to be reencoded.
        reencode_bitrate=$(video_bitrate "$prev_iframe" "$next_iframe")

        # Calculate ffmpeg options for the part that has to be reencoded.
        reencode_options=$(encoding_options "$reencode_bitrate"k)
        # -c:a copy -c:v mpeg4 -tag:v XVID -profile:v 15 -level:v 5 -preset slow

		# Process.
        # Notes:
        #   Use -ss as an input argument (before -i). Otherwise a few seconds may be lost from the begining of the video.
        #   Always use /dev/null as the stdin of ffmpeg! Otherwise ffmpeg reads chars from stdin and gets confused.
        echo "t_start=$t_start" "t_middle=$t_middle" "t_end=$t_end"
        $FFMPEG -ss "$t_start"  -i "$f" -t "$dt1" $reencode_options "$outfile_1"</dev/null
        $FFMPEG -ss "$t_middle" -i "$f" -t "$dt2" -c:a copy -c:v copy "$outfile_2"</dev/null

        # Use concat demuxer to join files.
        # http://stackoverflow.com/a/15186625/277172
        # http://ffmpeg.org/trac/ffmpeg/wiki/How%20to%20concatenate%20%28join,%20merge%29%20media%20files#demuxer
        printf "file '%s'\nfile '%s'\n" "$outfile_1" "$outfile_2" > cc$$.txt
        $FFMPEG -f concat -i cc$$.txt -c copy "$outfile"</dev/null
        $RM cc$$.txt
        exit
    done
done
