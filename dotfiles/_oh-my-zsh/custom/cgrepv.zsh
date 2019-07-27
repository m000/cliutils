# Function for grepping-out blocks of text.
# Usage:
#    cgrepv <skip_before> <skip_after> <expr> <file>
#
# Modern versions of grep support printing context around matches.
# E.g. to print 2 lines before and 3 lines after a match:
#	grep -B 2 -A 3 foo bar.txt
#
# However *not* printing 2 lines before and 3 lines after a match
# can't be done with grep. I.e., the following won't cut it:
#   grep -v -B 2 -A 3 foo bar.txt
#
# This function provides exactly this functionality. This is useful
# if you want to strip out markup blocks from a file. There may be
# markup-specific tools that allow you to do the same thing more
# reliably. But this function should work without any specialized
# tools installed.
#
function cgrepv() {
	# awk scripts ptints the ranges of lines that need to be deleted as a sed script
	local awkscript="
		/$3/{
			l[NR-$1] = NR+$2;
		}
		END {
			for (i in l) {
				printf(\"%d,%dd;\", i, l[i]);
			}
			print(\"\");
		}
	"
	local sedscript=$(awk "$awkscript" "$4")

	# sed prints the file, sans the lines that need to be deleted
	sed "$sedscript" "$4"
}

# vim:ft=sh
