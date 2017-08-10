#!/usr/bin/env python3.6

# python3.5 or later required -- supplies subprocess.run()

import argparse
import subprocess
import os
import shlex
import logging

FFMPEG_BIN = 'ffmpeg'
AUDIO_CODEC = 'libfdk_aac'
VIDEO_CODEC = 'libx265'
VIDEO_CODEC_PARAMS = '-x265-params'
OUTPUT_EXT = '.mkv'

X265_PRESETS = ['ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow', 'placebo',]
UNSHARP_PRESETS = [
    None,                   # no unsharp
    "5:5:1.0:5:5:0.0",      # smaller output
    "3:3:2:3:3:2",          # sharper output
]
VSCALE_PRESETS = [0, 480, 720, 1080,]

# Video filters
#DEINT="yadif=0:-1:0"

### Do the encoding based on processed arguments #####################
def x265enc(ffmpeg_args, outdir):
    if not os.path.isdir(outdir):
        logging.info("Creating output directory '%s'" % outdir)
        os.makedirs(outdir)

    for i, (fin, fout) in enumerate(zip(ffmpeg_args['input'], ffmpeg_args['output']), 1):
        cmd = [ffmpeg_args['ffmpeg'], '-i', fin]
        cmd.extend(ffmpeg_args['vfilter'])
        cmd.extend(ffmpeg_args['audio'])
        cmd.extend(ffmpeg_args['video'])
        cmd.append(os.path.join(outdir,fout))
        cmd_shell = ' '.join(map(shlex.quote, cmd))

        logging.info("encoding job %d/%d:%s" % (i, len(ffmpeg_args['input']), cmd_shell))
        subprocess.run(cmd, shell=False, check=True)

### Make ffmpeg arguments from wrapper arguments #####################
def make_ffmpeg_args(args):
    ffmpeg_args = {'input': [], 'vfilter': [], 'audio': [], 'video': [], 'output': [],}
    output_file = {'ext': OUTPUT_EXT}
    
    # straight copy
    ffmpeg_args['ffmpeg'] = args.ffmpeg

    # parse video filters
    vf = []
    if args.unsharp > 0:
        vf.append("unsharp=%s" % UNSHARP_PRESETS[args.unsharp])
    if args.vscale > 0:
        vf.append("scale=-1:%d" % args.vscale)
        output_file['size'] = '%dp' % args.vscale
    else:
        output_file['size'] = 'noscale'
    if vf:
        ffmpeg_args['vfilter'].extend(('-vf', ','.join(vf)))

    # parse audio options
    if args.abr > 0:
        ffmpeg_args['audio'].extend(('-c:a', AUDIO_CODEC))
        ffmpeg_args['audio'].extend(('-b:a', '%dk' % args.abr))
        ffmpeg_args['audio'].extend(('afterburner', '1'))
        output_file['audio'] = 'aac%d' % args.abr
    else:
        ffmpeg_args['audio'].extend(('-c:a', 'copy'))
        output_file['audio'] = 'acp'

    # parse video options
    ffmpeg_args['video'].extend(('-c:v', VIDEO_CODEC))
    ffmpeg_args['video'].extend(('-preset', args.preset))
    if args.crf > 0:
        ffmpeg_args['video'].extend((VIDEO_CODEC_PARAMS, 'crf=%d' % args.crf))
    else:
        ffmpeg_args['video'].extend((VIDEO_CODEC_PARAMS, 'lossless=1'))
    output_file['crf'] = 'crf%d' % args.crf

    # process input/output filenames
    for f in args.input:
        if not os.path.isfile(f):
            logging.warning("Input file '%s' does not exist" % f)
            continue
        ffmpeg_args['input'].append(f)
        output_file['filename'], filext = os.path.splitext(os.path.basename(f))
        ffmpeg_args['output'].append('{filename}[{size}-{crf}-{audio}]{ext}'.format(**output_file))

    return ffmpeg_args


### Argument parsing #################################################
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="""ffmpeg wrapper for x265 encoding.
    """)
    parser.add_argument("--ffmpeg",
        dest="ffmpeg", default=FFMPEG_BIN,
        help="ffmpeg binary to use (default: ffmpeg)",
    )
    parser.add_argument("-a", "--audio",
        action="store", type=int, dest="abr", default=0,
        help="bitrate for audio in kbps (copy: 0, default: 0)",
    )
    parser.add_argument("-c", "--crf",
        action="store", type=int, dest="crf", default=28,
        help="CRF to use for video (default: 28, lossless: 0)",
    )
    parser.add_argument("-p", "--preset",
        dest="preset", default="slower",
        choices=X265_PRESETS[4:9],
        help="specify preset to use (default: slower)",
    )
    parser.add_argument("-u", "--unsharp",
        action="store", type=int, dest="unsharp", default=0,
        choices = range(len(UNSHARP_PRESETS)),
        help="unsharp preset (default: 0, disabled: 0)",
    )
    parser.add_argument("--vscale",
        action="store", type=int, dest="vscale", default=0,
        choices=VSCALE_PRESETS,
        help="scale video to the specified height (default: 0, no-scale: 0)",
    )
    parser.add_argument("-o", "--outdir",
        dest="outdir", required=True, metavar="DIR",
        help="output dir",
    )
    parser.add_argument(
        dest="input", nargs="+", metavar="FILE",
        help="input files",
    )
    args = parser.parse_args()
    logging.basicConfig(format='%(levelname)s:%(message)s', level='INFO')

    ffmpeg_args = make_ffmpeg_args(args)
    x265enc(ffmpeg_args, args.outdir)


#OUTDIR="$HOME/Desktop"
#OUTDIR="./out"


# vim: ts=4 sts=4 sw=4 et noai :
