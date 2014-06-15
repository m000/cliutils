#!/usr/bin/env zsh

pdf_reformat() {
	infile="$7"
	jobname="${infile%.pdf}-new"

	if (( $2 == 0 )); then
		pdflatex -jobname="$jobname" <<-EOF
			\documentclass[a4paper]{article}
			\usepackage{pdfpages}
			\begin{document}
			\includepdf[pagecommand={\thispagestyle{empty}}, pages=-, scale=$1]{$infile}
			\end{document}
		EOF
	else
		pdflatex -jobname="$jobname" <<-EOF
			\documentclass[a4paper]{article}
			\usepackage{pdfpages}
			\usepackage{fancyhdr}

			\pagestyle{plain}
			\fancypagestyle{plain}{
				\fancyhf{} % clear all header and footer fields
				\fancyfoot[C]{\large[\thepage]}
				\renewcommand{\headrulewidth}{0pt}
				\renewcommand{\footrulewidth}{0pt}
				\setlength{\footskip}{$3}
			}

			\begin{document}
			\includepdf[pagecommand={\thispagestyle{plain}}, pages=-, scale=$1]{$infile}
			\end{document}
		EOF
    fi

    # touch output to have the same timestamp as input
    if (( $4 == 1 )); then
	touch -r "$infile" "$jobname".pdf
    fi

    # replace input with produced output
    if (( $5 == 1 )); then
	mv -f "$jobname".pdf "$infile"
    fi

    # remove latex log files
    if (( $6 == 0 )); then
	rm -f "$jobname".aux "$jobname".log
    fi
}



### parse options ##############################
o_zoom=(-z 1.0)
o_footerskip=(-s 0pt)

zparseopts -K -D -- z:=o_zoom n=o_addnumbers s:=o_footerskip t=o_touch w=o_overwrite d=o_dirty h=o_help
if [[ $? != 0 || "$o_help" != "" ]]; then
    echo "Usage: $(basename "$0") [OPTIONS] FILE1 FILE2 ..."
    echo ""
    echo "Available options:"
    echo "	-z ZOOM		Zoom factor. Allows manipulating margins."
    echo "	-n		Add page numbers to the output file."
    echo "	-s FOOTER_SKIP	Verical space to skip before page numbers. E.g. 1cm."
    echo "	-t		Touch output files to match timestamps of input files."
    echo "	-w		Overwrite input files with the produced output files."
    echo "	-d		Be dirty, don't cleanup LaTeX generated files."
    exit 1
fi

# parse flags
zoom=$o_zoom[2]
if [[ "$o_addnumbers" != "" ]]; then addnumbers=1; else addnumbers=0; fi
footerskip=$o_footerskip[2]
if [[ "$o_touch" != "" ]]; then touch=1; else touch=0; fi
if [[ "$o_overwrite" != "" ]]; then overwrite=1; else overwrite=0; fi
if [[ "$o_dirty" != "" ]]; then dirty=1; else dirty=0; fi

### do the formatting ##########################
for f in $*; do
	pdf_reformat $zoom $addnumbers $footerskip $touch $overwrite $dirty "$f"
done
