# Disable markdown processing if pandoc is not available.
# PANDOC := $(shell command -v pandoc 2> /dev/null)
ifndef PANDOC
MD_SRC = 
endif

# Set latex files to process.
TEX_SRC ?= $(wildcard dissertation.tex)

# Set latex files that trigger a rebuild.
TEX_SRC_ALL ?= $(wildcard *.tex frontmatter/*.tex endmatter/*.tex chapters/*.tex)

# Set zip file name.
ZIPTARGET = dissertation.zip

# Finetune latexpand.
LATEXPAND_SETTINGS = --verbose --explain --empty-comments

# And let the magic happen.
include ../latex.mak

