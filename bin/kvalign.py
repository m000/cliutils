#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Align script for key-value text lines.
Original on: https://github.com/m000/cliutils
"""
import argparse
import sys
import os


def get_spacing(lines, sep, maxsplit=-1):
    if maxsplit == -1:
        maxsplit = max([l.count(sep) for l in lines])

    fw = (maxsplit + 1) * [0]
    indent = 0
    for l in lines:
        lw = list(map(lambda s: len(s.strip()), l.split(sep, maxsplit)))
        lw.extend((maxsplit + 1 - len(lw)) * [0])
        fw = map(max, zip(fw, lw))
        indent = max(indent, len(l) - len(l.lstrip(" ")))

    return (indent, list(fw))


def reformat_lines(lines, sep, fw, indent=0, extra_space=1, file=sys.stdout):
    maxsplit = len(fw) - 1
    fmt = ("{:<%d}" % indent) + "".join(["{:<%d}" % (w + 1 + extra_space) for w in fw])

    for l in lines:
        components_in = l.split(sep, maxsplit)
        components_out = [c.strip() + sep for c in components_in[:-1]]
        components_out.append(components_in[-1].strip())
        components_out.extend((maxsplit + 1 - len(components_out)) * [""])
        print(fmt.format("", *components_out).rstrip(), file=file)


###############################################################################
#### Real action ##############################################################
###############################################################################
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
            description="Align script for key-value text lines.",
            formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-s", "--sep", default=":", help="separator to use")
    parser.add_argument("-i", "--indent", type=int, default=-1,
            help="indent space width")
    parser.add_argument("-e", "--extra-space", type=int, default=1,
            help="extra space after separator")
    output_mode = parser.add_mutually_exclusive_group()
    output_mode.add_argument("-o", "--output", default=None,
            help="output file")
    output_mode.add_argument("--in-place", action="store_true", default=False,
            help="edit input in place")
    parser.add_argument("input", nargs="?", help="input file")
    args = parser.parse_args()

    # read lines
    if args.input is None:
        lines = sys.stdin.readlines()
        linesep = os.linesep
    else:
        with open(args.input, "rU") as f:
            lines = f.readlines()
            linesep = f.newlines

    # get line spacing
    indent, fw = get_spacing(lines, args.sep)

    # fix arguments
    args.output = args.output if not args.in_place else args.input
    args.indent = indent if args.indent < 0 else args.indent

    # reformat and print
    if args.output is None:
        reformat_lines(lines, args.sep, fw, indent=args.indent)
    else:
        with open(args.output, "w", newline=linesep) as f:
            reformat_lines(lines, args.sep, fw, indent=args.indent, file=f)

# vim: ts=4 sts=4 sw=4 et noai :
