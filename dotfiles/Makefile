# Tools used by the Makefile.
CP          = cp -f
MKDIR       = mkdir -vp
RSYNC       = rsync
DIFF        = diff
GREP        = grep
J2          = j2 -U --filters j2_filters.py --tests j2_tests.py --

# Configuration variables, affecting the processing of templates.
OUTDIR          = output
HOSTNAME        = $(shell uname -n)
HOSTNAME_SHORT  = $(shell uname -n | cut -d. -f1)
KERNEL          = $(shell uname -s | tr A-Z a-z)

# Set base config - optional.
CONFIG_BASE     = config/_base.json
ifeq ($(realpath $(CONFIG_BASE)),)
CONFIG_BASE     =
endif

# Set os config - optional.
CONFIG_OS       = config/_base_$(KERNEL).json
ifeq ($(realpath $(CONFIG_OS)),)
CONFIG_OS       =
endif

# Set host config - mandatory.
CONFIG_HOST     = config/$(HOSTNAME)-$(KERNEL).json
ifeq ($(realpath $(CONFIG)),)
CONFIG_HOST     = config/$(HOSTNAME_SHORT)-$(KERNEL).json
endif
ifeq ($(realpath $(CONFIG_HOST)),)
$(error No configuration file for this host)
endif

CONFIG          = $(CONFIG_BASE) $(CONFIG_OS) $(CONFIG_HOST)

# Make a list of *.j2 files that should be compiled with j2cli.
RCFILES_IN      = $(shell find _* \( -type f -or -type l \) -iname '*.j2')
RCFILES_OUT     = $(patsubst _%.j2,$(OUTDIR)/.%,$(RCFILES_IN))

# Anything inside a directory that is not a template is copied without processing.
RCFILES_CP_FROM	= $(shell find _* \( -type f -or -type l \) -not -iname '*.j2')
RCFILES_CP_TO   = $(patsubst _%,$(OUTDIR)/.%,$(RCFILES_CP_FROM))

# Exclude unwanted files from being copied.
RCFILES_CP_TO	:= $(filter-out %.swp,$(RCFILES_CP_TO))
RCFILES_CP_TO	:= $(filter-out %.swo,$(RCFILES_CP_TO))
RCFILES_CP_TO	:= $(filter-out %.pyc,$(RCFILES_CP_TO))

# adjust RCFILES_OUT depending on kernel (i.e. OS)
ifneq ($(KERNEL),linux)
	RCFILES_OUT := $(filter-out $(OUTDIR)/.x%,$(RCFILES_OUT))
	RCFILES_OUT := $(filter-out $(OUTDIR)/.i3/%,$(RCFILES_OUT))
	RCFILES_OUT := $(filter-out $(OUTDIR)/.local/share/applications/%,$(RCFILES_OUT))
endif
ifneq ($(KERNEL),darwin)
	RCFILES_OUT := $(filter-out $(OUTDIR)/.slate%,$(RCFILES_OUT))
endif


.PHONY: all copy-dry copy-real

all: $(RCFILES_OUT) $(RCFILES_CP_TO)

copy-dry: all
	$(RSYNC) --exclude-from=config/exclude.txt -avPhi -n $(OUTDIR)/ $(HOME)/

copy-real: all
	$(RSYNC) --exclude-from=config/exclude.txt -avPhi $(OUTDIR)/ $(HOME)/

diff: all
	$(DIFF) --exclude-from=config/exclude.txt -wr $(HOME)/ $(OUTDIR)/ | $(GREP) -v "^Only in $(HOME)/[^:]*:" || true

$(OUTDIR)/.%: _% $(CONFIG)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(CP) $(<) $(@)

$(OUTDIR)/.%: _%.j2 $(CONFIG) $(wildcard include/*.inc)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(J2) $(<) $(CONFIG) > $(@)

clean:
	rm -rf $(OUTDIR)

