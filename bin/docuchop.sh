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
GREP="grep"
TR="tr"
SED="sed"
PASTE="paste"
CUT="cut"

##################################################################
# Runtime defaults
##################################################################
# Black scene detection filter options.
#    d -> Detect black scenes of at least <d>sec
#    pic_th -> A black frame conists of at least <pic_th>% black pixels.
#    pix_th -> A black pixel may be up to <pix_th>% bright.
# http://ffmpeg.org/ffmpeg-filters.html#blackdetect
BD_OPTS=d=.05:pic_th=0.82:pix_th=0.10

# Extensions of files allowed to be processed. Make sure to include | delimiters on start and end!
VALID_EXTENSIONS="|.avi|.mkv|.mp4|.m4v|"

# Threshold (in sec) for not re-encoding the first part of the trimmed video.
SKIP_PART1_THRESHOLD=1

# For example, produce 8x8 PNG tiles of all keyframes (‘-skip_frame nokey’) in a movie:
# ffmpeg -skip_frame nokey -i file.avi -vf 'scale=128:72,tile=8x8' -an -vsync 0 keyframes%03d.png

##################################################################
# Utility functions
##################################################################
function dt() {
    # Subtracts timestamps and prints result in proper format for ffmpeg.
    # ffmpeg requires having a zero before the floating point for -1<dt<1.
    # E.g. .5 is invalid and should be printed as 0.5.
    local dtr=$($PRINTF '((%f)-(%f))\n' "$1" "$2" | bc -l)
    $PRINTF "%f" "$dtr"
}

function has_valid_extension() {
    # Checks if the given filename's extension is among the global list
    # of valid extensions.
    local ext="${1##*.}"
    echo "$VALID_EXTENSIONS" | $GREP -q "|\.$ext|"
}

function str_common_prefix() {
    # Finds the longest common prefix of two strings.
    # Found on: http://unix.stackexchange.com/a/18240/17259
    local n=0
    while [[ "${1:n:1}" != "" && "${1:n:1}" == "${2:n:1}" ]]; do
       ((n++))
    done
    echo "${1:0:n}"
}

function make_filename() {
    # Creates a filename from the common prefixes of the supplied arguments.
    local f=""
    local prefix="$1"
    local ext=""

    for f in "$@"; do
        # Initialize and test file extension.
        has_valid_extension "$f" || { echo "Skipping '$f'. Bad extension." 1>&2; continue; }
        [ "$ext" = "" ] && ext="${f##*.}"
        [ "${f##*.}" = "$ext" ] || { echo "Skipping '$f'. Files must have a '.$ext' extension." 1>&2; continue; }

        # Update prefix.
        prefix=$(str_common_prefix "$f" "$prefix")
    done

    # Normalize prefix.
    prefix="${prefix%%[*}"
    prefix="${prefix%"${prefix##*[![:space:]]}"}"   #" # " is a syntax highlight fix
    prefix="${prefix:=video$$}"

    # Print results.
    echo "$prefix"."$ext"
}

##################################################################
# ffmpeg wrapper functions
##################################################################
function video_av_format() {
    # Returns the video/audio format used by the specified video file. E.g. "h264:aac".
    # When input file has multiple video/audio streams, the first from each is used.
    local f="$1"
    local jqfilter='.streams[] |
        {codec_type, codec_name} |
        [select(.codec_type=="video"), select(.codec_type=="audio")] |
        .[0] |
        .codec_name
    '
    $FFPROBE -show_format -show_streams -print_format json -v quiet "$f" |
        $JQ -r "$jqfilter" |
        $PASTE -s -d: -  |
        $TR A-Z a-z
}

function video_analyze() {
    # Analyzes input file and writes results to "$bd_cache", "$fr_cache" and "$st_cache" files.
    #   * The first file contains the black detection analysis results in a custom text format.
    #   * The second file contains the frame analysis results in json format.
    #   * The third file contains stream information for the file.
    # Analysis may take a few minutes. In order to use stdout to display progress of the analysis,
    # the names of the produced cached files are written in the filename specified with the second
    # argument.
    # In order to only read input file once and also exploit multiple cores for the analysis, the
    # black detection and frame analysis run concurrently and read the file from two fifos.
    local f="$1"
    local caches="$2"

    # options used by black detection
    local bdopts_line="# BD_OPTS=$BD_OPTS"

    # fifos for black detection and frame analysis
    local fifo_bd=/tmp/fifo_bd_$$
    local fifo_fr=/tmp/fifo_fr_$$

    # cache files to be created
    local bd_cache="$f".bd.cache
    local fr_cache="$f".fr.cache
    local st_cache="$f".st.cache

    # always create streams files - this is cheap
    $FFPROBE -show_format -show_streams -print_format json -v quiet "$f" > "$st_cache"

    # check if we have cached analysis files
    if [ -f "$fr_cache" ] && [ -f "$bd_cache" ] && $GREP -q "$bdopts_line" "$bd_cache"; then
        echo "Using cached analysis files for $f..."
        echo "$bd_cache" > "$caches"
        echo "$fr_cache" >> "$caches"
        echo "$st_cache" >> "$caches"
        return
    fi

    echo "Analyzing '$f'..."

    # create fifos and feed file into them
    mkfifo "$fifo_bd"
    mkfifo "$fifo_fr"
    $PV -peb "$f" | tee "$fifo_bd" "$fifo_fr" >/dev/null &

    # run commands on fifos
    $FFMPEG -i "$fifo_bd" -vf blackdetect="$BD_OPTS" -an -f null - 2> >(tr -u \\r \\n > "$bd_cache") &
    $FFPROBE -select_streams v -show_frames -print_format json -v quiet "$fifo_fr" > "$fr_cache" &
    wait

    # Append black detection options signature and cleanup fifos.
    echo "$bdopts_line" >> "$bd_cache"
    rm "$fifo_fr" "$fifo_bd"

    # Write cache file names.
    echo "$bd_cache" > "$caches"
    echo "$fr_cache" >> "$caches"
    echo "$st_cache" >> "$caches"
}

function video_make_scenes() {
    local bd_cache="$1"
    local st_cache="$2"

    local bsc=0                                                 # black scene counter
    local black_start=""                                        # current black scene start
    local black_end=""                                          # current black scene end
    local black_start_prev=""                                   # previous black scene start
    local black_end_prev="0"                                    # previous black scene end
    local l=""                                                  # temp variable
    local t_start=""                                            # trim start time
    local t_end=""                                              # trim stop time
    local merge="no"                                            # flags when current scene should be merged with previous

    # Loop on scenes using the detected black scenes.
    # Black scene line format: black_start:66.6667 black_end:66.967 black_duration:0.3003
    # We transform each lines to shell variable assignments: black_start=66.6667; black_end=66.967; black_duration=0.3003 
    $GREP ^black_start "$bd_cache" | $SED 's/:/=/g; s/  */; /g' | while read l; do
        # copy old start/end values & assign new ones
        black_start_prev="$black_start"
        black_end_prev="$black_end"
        eval $l

        if (( bsc++ < $SKIP_FIRST )); then
            echo "Skipping to $black_end..." >&2
            continue;
        elif [ "$merge" = "yes" ]; then
            # merge with previous - only update $t_end
            t_end="$black_start"
            merge="no"
        else
            t_start="$black_end_prev"
            t_end="$black_start"
        fi

        if (( $(bc <<< "$(dt "$t_end" "$t_start")/1") < "$MERGE_THRESHOLD" )); then
            merge="yes"
            continue
        else
            echo "$t_start" "$t_end"
        fi
    done

    # Do the final scene.
    # Start and end have to be recalculated because the previous loop
    # executes in a subshell, so variables are destroyed on exit.
    l=$($GREP ^black_start "$bd_cache" | tail -1 | $SED 's/:/=/g; s/  */; /g')
    eval $l
    t_start="$black_end"
    t_end=$($JQ -r '.format.duration' < "$st_cache")
    if (( $(bc <<< "$(dt "$t_end" "$t_start")/1") >= "$MERGE_THRESHOLD" )); then
        echo "$t_start" "$t_end"
    fi
}

function video_prev_next_iframes() {
    # parses "$fr_cache" and returns the position of the first iframes before and after the specified time
    local fr_cache="$1"
    local t_start="$2"
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
    $JQ -r "$($PRINTF "$jqfilter" "$t_start" "$t_start" "$t_start")" < "$fr_cache"
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
    local fr_cache="$1"
    local t_start="$2"
    local t_end="$3"

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
    local br=$($JQ -r "$($PRINTF "$jqfilter" "$t_start" "$t_end")" < "$fr_cache")

    # round result to an int
    bc <<< "$br/1"
}

function video_encoding_options() {
    # Parse the stream information cache and attempts to produce encoding options
    # that will result in the same quality/format with the original videl.
    # The bitrate to be used is supplied through the second argument.
    local st_cache="$1"
    local brv="$2"
    local jqfilter=""
    local codec=""

    # Check if we have implemented support for this video codec.
    # Each time we add support for a codec, it has to be added to the list
    # of accepted codecs below.
    jqfilter='.streams[] | select(.codec_type == "video") | "\(.codec_name) \(.codec_tag_string)"'
    codec=$($JQ -r "$($PRINTF "$jqfilter" "$brv")" < "$st_cache" | $TR A-Z a-z)
    case "$codec" in
        "h264 avc1"|"mpeg4 xvid")
            # good to go - do nothing
        ;;

        *)
            # Exit executing subshell. This will not terminate the whole script!
            # The caller of the function must check exit code and take appropriate action.
            echo "Detected codec: $codec" 1>&2
            echo "N/A"
            exit 1
        ;;
    esac

    # Always copy audio.
    echo -n "-c:a copy "

    # Create ffmpeg options for encoding video.
    # For each supported codec, stream info must be mapped to encoding options.
    # For XVID mappings, see http://permalink.gmane.org/gmane.comp.video.ffmpeg.user/12241
    jqfilter='.streams[] | select(.codec_type == "video") |
        (
            if .codec_tag_string == "XVID" and .profile == "Advanced Simple Profile" then (
            .opt_codec="-c:v \(.codec_name)" |
            .opt_codec_tag="-tag:v \(.codec_tag_string)" |
            .opt_codec_profile="-profile:v 15" |
            .opt_codec_level="-level:v \(.level)" |
            .opt_codec_preset="-preset slow" |
            .opt_codec_bframes="-bf:v \(.has_b_frames)"
            ) else . end
        ) |
        (
            if .codec_name == "h264" then (
            .opt_codec="-c:v \(.codec_name)" |
            .opt_codec_tag="" |
            .opt_codec_profile="-profile:v \(.profile)" |
            .opt_codec_level="-level:v \(.level)" |
            .opt_codec_preset="-preset slow" |
            .opt_codec_bframes="-bf:v \(.has_b_frames)"
            ) else . end
        ) |
        "\(.opt_codec) \(.opt_codec_tag) \(.opt_codec_profile) \(.opt_codec_level) \(.opt_codec_preset) \(.opt_codec_bframes) -b:v %s"
    '
    $JQ -r "$($PRINTF "$jqfilter" "$brv")" < "$st_cache"
}

function video_concat() {
    # Concatenates videos using an appropriate method.
    # The first argument is used as the output file.
    # The rest arguments are used as input files. 
    local f=""
    local outfile="$1"
    local concat_in=""
    local ext="${outfile##*.}"
    local formats=""
    local fifotmp=""

    # Throw away first argument which represents the outfile.
    shift

    # Test if the outfile is suitable for ffmpeg output.
    has_valid_extension "$outfile" || { echo "Aborting. Bad extension for concat outfile '$f'." 1>&2; exit; }

    # Get the A/V formats from the first infile.
    formats=$(video_av_format "$1")

    # Choose appropriate method based on A/V format.
    case "$formats" in
        "h264:aac")
            # Use concat protocol for h264/aac.
            # http://trac.ffmpeg.org/wiki/How%20to%20concatenate%20%28join,%20merge%29%20media%20files#protocol
            concat_in="${outfile%.*}_mpegts_concat.txt"
            $RM -f "$concat_in"
            for f in "$@"; do
                [ -r "$f" ] || { echo "Skipping '$f'. Unreadable." 1>&2; continue; }
                has_valid_extension "$f" || { echo "Skipping '$f'. Bad extension." 1>&2; continue; }
                [ $(video_av_format "$f") = "$formats" ] || { echo "Skipping '$f'. Bad format." 1>&2; continue; }

                # make sure to use -y to convince ffmpeg to "overwrite" fifos
                fifotmp="$(basename "$f" | tr \ . _)_concat_fifo"
                mkfifo "$fifotmp"
                echo "$fifotmp" >> "$concat_in"
                $FFMPEG -i "$f" -c copy -bsf:v h264_mp4toannexb -f mpegts -y "$fifotmp" -loglevel warning </dev/null &
            done
            $FFMPEG -f mpegts -i "concat:$($PASTE -s -d\| "$concat_in")" -c copy -bsf:a aac_adtstoasc "$outfile" -loglevel warning </dev/null
            $RM -f *_concat_fifo "$concat_in"
            ;;
        *)
            # When in doubt, use the concat demuxer.
            # http://trac.ffmpeg.org/wiki/How%20to%20concatenate%20%28join,%20merge%29%20media%20files#demuxer
            concat_in="${outfile%.*}_demuxfilter_concat.txt"
            $RM -f "$concat_in"
            for f in "$@"; do
                [ -r "$f" ] || { echo "Skipping '$f'. Unreadable." 1>&2; continue; }
                has_valid_extension "$f" || { echo "Skipping '$f'. Bad extension." 1>&2; continue; }
                [ $(video_av_format "$f") = "$formats" ] || { echo "Skipping '$f'. Bad format." 1>&2; continue; }

                $PRINTF "file '%s'\n" "$f" >> "$concat_in"
            done
            $FFMPEG -f concat -i "$concat_in" -c copy "$outfile" -loglevel warning </dev/null
            $RM -f "$concat_in"
            ;;
    esac
}

function video_chop() {
    # Chops the specified file on its black scenes.
    local f="$1"
    local sc=1                                                  # scene counter

    # Analyze file and get cached analysis files.
    video_analyze "$f" "$f.meta.cache"
    local bd_cache=$($GREP "\.bd\.cache$" "$f.meta.cache")      # black detect cache
    local fr_cache=$($GREP "\.fr\.cache$" "$f.meta.cache")      # frames cache
    local st_cache=$($GREP "\.st\.cache$" "$f.meta.cache")      # streams cache

    # Variables used while looping scenes.
    local t_start=""                                            # trim start time
    local t_end=""                                              # trim end time
    local outfile=""                                            # final scene video file
    local outfile_1=""                                          # intermediate file 1 (reencoded)
    local outfile_2=""                                          # intermediate file 2 (stream copy)
    local dt1=""                                                # length in sec of intermediate file 1
    local dt2=""                                                # length in sec of intermediate file 2
    local reencode_bitrate=""                                   # identified bitrate for the part to be reencoded
    local reencode_options=""                                   # determined encoding options for the same part

    # Create scenes based on black scenes and to the trimming.
    video_make_scenes "$bd_cache" "$st_cache" | while read t_start t_end; do
        # Construct outfiles & remove old outfiles.
        outfile_1="${f%.*}.$((sc)).1.${f##*.}"
        outfile_2="${f%.*}.$((sc)).2.${f##*.}"
        outfile="${f%.*} scene$((sc)).${f##*.}"
        [ -f "$outfile" ] && $RM "$outfile"
        [ -f "$outfile_1" ] && $RM "$outfile_1"
        [ -f "$outfile_2" ] && $RM "$outfile_2"

        echo "Processing scene $((sc++))..."

        # Scene debug.
        # echo $t_start $t_end
        # continue

        # Find the iframes before and after the starting time.
        read prev_iframe next_iframe <<< $(video_prev_next_iframes "$fr_cache" "$t_start")

        # Calculate bitrate for the part that has to be reencoded.
        reencode_bitrate=$(video_bitrate "$fr_cache" "$prev_iframe" "$next_iframe")

        # Calculate ffmpeg options for the part that has to be reencoded.
        reencode_options=$(video_encoding_options "$st_cache" "$reencode_bitrate"k)
        [ "$reencode_options" = "N/A" ] && { echo "Aborting. Don't know how to get reencode options for '$f'." 1>&2; } && return

        ##############################################################################################
        # We want to trim video between the detected $t_start and $t_end and avoid reencoding as much
        # as possible.
        # In most modern video format this is not possible by simple stream copying, because of
        # the use of iframes (also called keyframes). The video stream can only be seeked/trimmed on
        # iframes.
        #
        # For this we create two separate trim files and then concatenate them:
        #   1. The first video part is from $t_start until $next_iframe.
        #      This part will usually be very short (O(sec)) and has to be reencoded.
        #   2. The second video part is from $next_iframe until $t_end.
        #      This is the bulk of the video and can be copied using simple stream copy.
        #
        # This is pictured in the following ascii art. We want to trim the part marked with #.
        #
        # ------------------------------------------------------------------------------------------
        # |          |          |###########|######################|                               |
        # ------------------------------------------------------------------------------------------
        # |          |          |           |                      |                               |
        # 0     prev_iframe  t_start   next_iframe               t_end                         video end
        #
        # Creating the first video still has a few catches. In order for the final result to be
        # seamless, we need to employ the fast and accurate seek method described in the ffmpeg wiki:
        # https://trac.ffmpeg.org/wiki/Seeking%20with%20FFmpeg
        # This method does the seek to $t_start in two steps:
        #   1. A fast seek to $prev_iframe applied on the input file (i.e. before -i argument).
        #   2. A slow seek from that point until "$t_start" applied on the decoded stream (i.e. after -i argument).
        #
        # Note: On non-interactive invocations of ffmpeg stdin should be read from /dev/null!!!
        #       Otherwise ffmpeg reads chars generated in the script, gets confused and fails.
        ##############################################################################################
        dt1=$(dt "$next_iframe" "$t_start") 
        dt2=$(dt "$t_end" "$next_iframe")
        if (( $(bc <<< "$dt1/1") < "$SKIP_PART1_THRESHOLD" )); then
            # First part too small. Just copy the second to the output.
            $FFMPEG -ss "$next_iframe" -i "$f" -t "$dt2" -c:a copy -c:v copy "$outfile" -loglevel warning </dev/null        
        else
            $FFMPEG -ss "$prev_iframe" -i "$f" -ss $(dt "$t_start" "$prev_iframe") -t "$dt1" $reencode_options "$outfile_1" -loglevel warning </dev/null
            $FFMPEG -ss "$next_iframe" -i "$f" -t "$dt2" -c:a copy -c:v copy "$outfile_2" -loglevel warning </dev/null
            # Concat files. First argument is the final output.
            video_concat "$outfile" "$outfile_1" "$outfile_2"
            $RM -f "$outfile_1" "$outfile_2"
        fi
        # (( $sc > 2 )) && break
    done
}

##################################################################
# Argument processing & action.
##################################################################



# Concat all videos in one before processing.
# Uses more space but you won't have to care about videos not stopping on a black scene.
CONCAT_ALL="no"

# How many scenes should be skipped from start. Useful for documentary credits etc.
SKIP_FIRST=0

# Threshold for merging smaller scenes.
MERGE_THRESHOLD=150

while getopts ":cs:t:" opt; do
  case $opt in
    s) ((SKIP_FIRST+=OPTARG)) ;;
    c) CONCAT_ALL="yes";;
    t)
        if (( $OPTARG > 0 )); then
            MERGE_THRESHOLD="$OPTARG"
        else
            echo "Invalid merge threshold specified. Using default." >&2
        fi
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done
shift $((OPTIND-1))

if [[ "$CONCAT_ALL" = "yes" && $# -gt 1 ]]; then
    concat_file="$(make_filename "$@")"
    if [ -f "$concat_file" ]; then
        echo "Continuing with existing concat file '$concat_file'..." 1>&2;
    else
        echo "Concatenating to '$concat_file'..." 1>&2;
        video_concat "$concat_file" "$@"
    fi
    video_chop "$concat_file"
else
    for f in "$@"; do
        [ -r "$f" ] || { echo "Skipping '$f'. Unreadable." 1>&2; continue; }
        has_valid_extension "$f" || { echo "Skipping '$f'. Bad extension." 1>&2; continue; }
        video_chop "$f"
    done
fi
