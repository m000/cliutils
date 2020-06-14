#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Align script for key-value text lines.
Original on: https://github.com/m000/cliutils
"""
import argparse
import string
import sys
import os

# RULER = ''.join(['|' if not i % 10 else ( '+' if not i % 5 else '.' ) for i in range(81)])

def get_spacing(lines, sep, maxsplit=-1):
    # calculate the number of columns
    if maxsplit == -1:
        ncols = max([l.count(sep) for l in lines]) + 1
    else:
        ncols = maxsplit + 1

    # leading indentation and column widths
    indent = 0
    colw = ncols * [0]

    # run through the lines to calculate indent and colw
    for l in lines:
        # current line column widths - single column lines are skipped
        lw = list(map(lambda s: len(s.strip()), l.split(sep, ncols - 1)))
        if len(lw) == 1:
            continue
        lw.extend((ncols - len(lw)) * [0])

        # update indent and colw
        indent = max(indent, len(l) - len(l.lstrip(" ")))
        colw = map(max, zip(colw, lw))

    return (indent, list(colw))

def reformat_lines(lines, sep, colw, indent=0,
        space_before=1, space_after=1, gravity='w', file=sys.stdout):

    ncols = len(colw)
    stripc = string.whitespace + sep
    delim = space_before*' ' + sep + space_after*' '

    for l in lines:
        components_in = l.split(sep, ncols - 1)
        components_out = [indent*" ",]
        if l[0] == sep or len(components_in) == 1:
            # don't process lines starting with sep, or not containing sep
            components_out.append(l.rstrip(stripc))
        else:
            for i, c in enumerate(components_in):
                c = c.strip()
                if gravity == 'e':
                    fmt = "{:<}{:>%d}" % (colw[i]-len(c)+len(delim))
                else:
                    fmt = "{:<}{:<%d}" % (colw[i]-len(c)+len(delim))
                components_out.append(fmt.format(c, delim))
        print("".join(components_out).rstrip(stripc), file=file)

###############################################################################
#### Real action ##############################################################
###############################################################################
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
            description="Align script for key-value text lines.",
            formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-s", "--sep", default=":", help="separator to use")
    parser.add_argument("-B", type=int, default=1, dest='space_before',
            help="extra space before separator")
    parser.add_argument("-A", type=int, default=1,dest='space_after',
            help="extra space after separator")
    parser.add_argument("-g", "--gravity", choices=["e", "w"], default="w",
            help="gravity direction - pulls the separator")
    parser.add_argument("-i", "--indent", type=int, default=-1,
            help="indent space width")
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
    indent, colw = get_spacing(lines, args.sep)

    # fix arguments
    args.output = args.output if not args.in_place else args.input
    args.indent = indent if args.indent < 0 else args.indent

    # reformat and print
    if args.output is None:
        reformat_lines(lines, args.sep, colw, indent=args.indent,
                space_before=args.space_before, space_after=args.space_after,
                gravity=args.gravity)
    else:
        with open(args.output, "w", newline=linesep) as f:
            reformat_lines(lines, args.sep, colw, indent=args.indent,
                    space_before=args.space_before, space_after=args.space_after,
                    gravity=args.gravity, file=f)

# vim: ts=4 sts=4 sw=4 et noai :
