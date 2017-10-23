# mstamat's Uber-Makefile boilerplate for LaTeX and Markdown
# Get the latest here: https://raw.githubusercontent.com/m000/cliutils/master/latex/latex.mak
#
# How to use:
# 	a. Copy in your working dir as "Makefile" and edit to match your needs.
# 	   You should only need to edit whatever is marked with "EDIT".
# 	b. Include from your Makefile. Set your own defaults before and add your
# 	   own rules after the include directive.


### Programs ######################################################
LATEX   	?= xelatex
BIBTEX     	?= bibtex
LATEXPAND  	?= latexpand
PANDOC		?= pandoc
ZIP        	?= zip
MKDIR      	?= mkdir -p
CP         	?= cp
RM         	?= rm -f
RSYNC      	?= rsync
SPONGE		?= sponge
GIT			?= git
GNUPLOT		?= gnuplot


### Input/Output files ############################################
# Locations (to be used e.g. in zip name):
MAKEFILE_PATH	= $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
MAKEFILE_DIR	= $(notdir $(realpath $(dir $(MAKEFILE_PATH))))
GIT_DIR			= $(notdir $(shell $(GIT) rev-parse --show-toplevel))

# Markdown:
MD_SRC		?= $(wildcard *.md)						# EDIT: default for markdown files to process
MD_html		= $(patsubst %.md,%.html,$(MD_SRC))
MD_txt		= $(patsubst %.md,%.txt,$(MD_SRC))
MD_pdf		= $(patsubst %.md,%.pdf,$(MD_SRC))

# Plots:
GP_SRC		?= $(wildcard plots/*.gp)
GP_pdf		?= $(patsubst %.gp,%.pdf,$(GP_SRC))

# LaTeX:
TEX_SRC		?= $(wildcard paper*.tex)				# EDIT: default for top-level tex files ti process
ifneq ($(wildcard *-cr.tex),)						# CR files present
TEX_SRC 	= $(wildcard *-cr.tex)
else
TEX_SRC_CR	= $(patsubst %.tex,%-cr.tex,$(TEX_SRC)) # CR files
endif
TEX_SRC_ALL	?= $(wildcard *.tex)
BIB_SRC		?= $(wildcard *.bib)
TEX_AUX		= $(patsubst %.tex,%.aux,$(TEX_SRC))
TEX_BBL		= $(patsubst %.aux,%.bbl,$(TEX_AUX))
TEX_SUP		?= $(wildcard *.cls *.bst *.sty)
TEX_FIG		?= $(wildcard figs/*.pdf figs/*.eps figs/*.png figures/*.pdf figures/*.eps figures/*.png)
TEX_CLEAN	?= $(wildcard *.log *.aux *.blg *.bbl *.out *.nav *.snm *.toc *.vrb)
TEX_pdf		= $(patsubst %.tex,%.pdf,$(TEX_SRC))

# Zip:
ZIPTARGET	?= $(notdir $(CURDIR)).zip				# EDIT: default name for zip file to be created
ZIPTARGET	:= $(strip $(ZIPTARGET))
ZIPDIR		= $(basename $(ZIPTARGET))				# temp directory for holding zipfile contents
ZIPDIR		:= $(strip $(ZIPDIR))
ZIP_CR_SRC	?= Makefile latex.mak $(TEX_pdf) $(TEX_SRC_CR) $(TEX_FIG) $(GP_pdf) $(BIB_SRC) $(TEX_SUP) $(ZIP_CR_SRC_EXTRA)	# EDIT: files in the CR zip
ZIP_CR_CP	= $(addprefix $(ZIPDIR)/,$(ZIP_CR_SRC))


### Settings ######################################################
LATEX_FINAL_SETTINGS	?= -dPDFSETTINGS=/prepress
LATEXPAND_SETTINGS		?= --verbose --explain
ZIPEXCLUDE				?=							# EDIT: e.g. "-x v.pdf trip.pdf"


### Recipes #################################################
%.html: %.md
	$(PANDOC) --standalone --normalize -f markdown-hard_line_breaks -t html5 --self-contained -o $(@) $(<)

%.txt: %.md
	$(PANDOC) --standalone --normalize -f markdown-hard_line_breaks -t plain -o $(@) $(<)

%.tex %.pdf: %.md
	$(PANDOC) --standalone --normalize -f markdown-hard_line_breaks -t latex -o $(@) $(<)

plots/%.pdf: plots/%.gp plots/%.csv
	cd $(dir $(<)) && $(GNUPLOT) $(notdir $(<))

plots/%.pdf: plots/%.gp plots/%.tsv
	cd $(dir $(<)) && $(GNUPLOT) $(notdir $(<))

plots/%.pdf: plots/%.gp plots/%.dat
	cd $(dir $(<)) && $(GNUPLOT) $(notdir $(<))

plots/%.pdf: plots/%.gp
	cd $(dir $(<)) && $(GNUPLOT) $(notdir $(<))

%.pdf: %.tex $(TEX_SRC_ALL) $(BIB_SRC) $(TEX_FIG) $(GP_pdf) $(TEX_SUP)
	$(LATEX) $(patsubst %.tex,%,$<)
	$(MAKE) $(TEX_BBL)
	$(LATEX) $(patsubst %.tex,%,$<)
	$(LATEX) $(LATEX_FINAL_SETTINGS) $(patsubst %.tex,%,$<)

%.bbl: %.aux
	- $(BIBTEX) $(patsubst %.aux,%,$*)

$(ZIPDIR)/%-cr.tex: %.tex
ifneq ($(TEX_SRC_CR),)
	@$(MKDIR) $(dir $(@))
	$(LATEXPAND) $(<) -o $(@) $(LATEXPAND_SETTINGS)
else
	$(error CR files already present)
endif

$(ZIPDIR)/%: %
ifneq ($(TEX_SRC_CR),)
	@$(MKDIR) $(dir $(@))
	$(CP) $(<) $(@)
else
	$(error CR files already present)
endif


### Rules ###################################################
DST			?= $(MD_pdf) $(TEX_pdf) $(GP_pdf)	# EDIT: destination files

.PHONY: all plots zip zip-cr clean distclean

all:: $(DST)
	@echo Done

plots: $(GP_pdf)

zip: $(DST)
	$(ZIP) $(ZIPTARGET) $(ZIPEXCLUDE) -9 $^

zip-cr: $(ZIP_CR_CP)
	$(ZIP) $(ZIPTARGET) $(ZIPEXCLUDE) -9 $^

clean:
	$(RM) $(TEX_CLEAN)
	$(RM) -r $(ZIPDIR) $(ZIPTARGET)

distclean: clean
	$(RM) $(DST)

gitclean:
	$(GIT) clean -fdx
