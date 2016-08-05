# mstamat's Uber-Makefile for LaTeX
# Get the latest here: https://github.com/m000/cliutils/latex

### Definitions ###################################################
# Programs:
PDFLATEX = pdflatex
BIBTEX   = bibtex
ZIP      = zip
RM       = rm -f

# Settings:
PDFLATEX_FINAL_SETTINGS = -dPDFSETTINGS=/prepress
#ZIPEXCLUDE = -x v.pdf trip.pdf

# Source/target files:
TEXTARGET = $(wildcard *-boilerplate.tex)
PDFTARGET = $(patsubst %.tex,%.pdf,$(TEXTARGET))
TEXFILES = $(wildcard *.tex)
BIBFILES = $(wildcard *.bib)
AUXFILES = $(wildcard *.aux)
BBLFILES = $(patsubst %.aux,%.bbl,$(AUXFILES))
FIGFILES = $(wildcard figs/*.pdf figs/*.eps figs/*.png)
ZIPFILE  = $(basename $(firstword $(TEXTARGET))).zip


### Rules ###################################################
.PHONY: all bib clean distclean zip zip-src

all: $(PDFTARGET)

%.pdf: %.tex $(TEXFILES) $(BIBFILES) $(FIGFILES)
	$(PDFLATEX) $(patsubst %.tex,%,$<)
	$(MAKE) bib
	$(PDFLATEX) $(patsubst %.tex,%,$<)
	$(PDFLATEX) $(PDFLATEX_FINAL_SETTINGS) $(patsubst %.tex,%,$<)

%.bbl: %.aux
	- $(BIBTEX) $(patsubst %.aux,%,$*)

bib: $(BBLFILES)

clean:
	$(RM) *.log *.aux *.blg *.bbl *.out *.nav *.snm *.toc *.vrb $(ZIPFILE)

distclean:
	$(RM) *.log *.aux *.blg *.bbl *.out *.nav *.snm *.toc *.vrb $(ZIPFILE) $(PDFTARGET)

zip: $(PDFTARGET)
	$(ZIP) $(ZIPFILE) $(ZIPEXCLUDE) -9 $^

zip-src: $(PDFTARGET) $(TEXFILES) $(BIBFILES) $(FIGFILES) Makefile
	$(ZIP) $(ZIPFILE) $(ZIPEXCLUDE) -9 $^

