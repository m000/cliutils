#!/usr/bin/env zsh

pdf_reformat() {
	jobname="${5%.pdf}-new"

	if (( $1 == 0 )); then
		pdflatex -jobname="$jobname" <<-EOF
			\documentclass[a4paper]{article}
			\usepackage{pdfpages}
			\begin{document}
			\includepdf[pagecommand={\thispagestyle{empty}}, pages=-, scale=$2]{$5}
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
				\renewcommand{\footskip}{$3}
			}

			\begin{document}
			\includepdf[pagecommand={\thispagestyle{plain}}, pages=-, scale=$2]{$5}
			\end{document}
		EOF
    fi

    if (( $4 == 1 )); then
        rm -f "$jobname".aux "$jobname".log
    fi
}



### parse options ##############################
o_addnumbers=(-n 1)
o_zoom=(-z 1.0)
o_footskip=(--fs 0pt)
o_cleanup=(-c 1)

zparseopts -K -D -- n:=o_addnumbers z:=o_zoom -fs:=o_footskip h=o_help
if [[ $? != 0 || "$o_help" != "" ]]; then
    echo Usage: $(basename "$0") "[-n 0|1] [-z PAGE_ZOOM] [--fs FOOTER_SKIP] [-c 0|1]"
    exit 1
fi

addnumbers=$o_addnumbers[2]
zoom=$o_zoom[2]
footskip=$o_footskip[2]
cleanup=$o_cleanup[2]



### do the formatting ##########################
for f in $*; do
	pdf_reformat $addnumbers $zoom $footskip $cleanup "$f"
done
