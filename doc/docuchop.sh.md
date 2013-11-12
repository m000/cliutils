docuchop.sh
===========

An automated choper for documentary videos. The script automatically
detects intermittent blackening points between scenes and splits video
on them.
Because most modern formats use some form of [keyframes](http://en.wikipedia.org/wiki/I-frame#Intra_coded_frames.2Fslices_.28I.E2.80.91frames.2Fslices_or_Key_frames.29),
the first few seconds of each chunk (from the desired cut-point until
the next keyframe) have to be re-encoded.

Requirements
------------

* [ffmpeg](http://www.ffmpeg.org/ffmpeg.html)/[ffprobe](http://www.ffmpeg.org/ffprobe.html):
  Used for analyzing input video, producing output chunks.
* [pv](http://www.commandlinefu.com/commands/tagged/609/pv):
  For displaying the progress of the input analysis.
* [jq](http://stedolan.github.io/jq/): For extracting information from [json](http://en.wikipedia.org/wiki/JSON) files.
* [printf](http://www.ss64.com/bash/printf.html): For formatting the jq query.


