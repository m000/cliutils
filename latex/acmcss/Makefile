# Disable markdown processing if pandoc is not available.
# PANDOC := $(shell command -v pandoc 2> /dev/null)
ifndef PANDOC
MD_SRC = 
endif

# Set latex files to process.
TEX_SRC ?= $(wildcard ccs-template.tex)

# Set zip file name.
ZIPTARGET = ccs-paper.zip

# Finetune latexpand.
LATEXPAND_SETTINGS = --verbose --explain --empty-comments

# And let the magic happen.
include ../latex.mak

