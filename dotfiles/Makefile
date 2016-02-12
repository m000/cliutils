# Tools used by the Makefile.
CP          = cp -f
MKDIR       = mkdir -vp
RSYNC       = rsync
DIFF        = diff
GREP        = grep
J2          = j2 -C --undefined=normal

# Configuration variables, affecting the processing of templates.
OUTDIR          = output
HOSTNAME        = $(shell uname -n | cut -d. -f1)
KERNEL          = $(shell uname -s | tr A-Z a-z)
CONFIG          = config/$(HOSTNAME)-$(KERNEL).json

# Make a list of *.j2 files that should be compiled with j2cli.
RCFILES_IN      = $(shell find _* -type f -iname '*.j2')
RCFILES_OUT     = $(patsubst _%.j2,$(OUTDIR)/.%,$(RCFILES_IN))

# Anything inside a directory that is not a template is copied without processing.
RCFILES_CP_FROM	= $(shell find _* -type f -not -iname '*.j2')
RCFILES_CP_TO   = $(patsubst _%,$(OUTDIR)/.%,$(RCFILES_CP_FROM))

# adjust RCFILES_OUT depending on kernel (i.e. OS)
ifneq ($(KERNEL),linux)
	RCFILES_OUT := $(filter-out $(OUTDIR)/.x%,$(RCFILES_OUT))
	RCFILES_OUT := $(filter-out $(OUTDIR)/.i3/%,$(RCFILES_OUT))
	RCFILES_OUT := $(filter-out $(OUTDIR)/.local/share/applications/%,$(RCFILES_OUT))
endif


.PHONY: all copy-dry copy-real

all: $(RCFILES_OUT) $(RCFILES_CP_TO)

copy-dry: all
	$(RSYNC) -avPhi -n $(OUTDIR)/ $(HOME)/

copy-real: all
	$(RSYNC) -avPhi $(OUTDIR)/ $(HOME)/

diff: all
	$(DIFF) -wr $(HOME)/ $(OUTDIR)/ | $(GREP) -v "^Only in $(HOME)/[^:]*:" || true

$(OUTDIR)/.%: _% $(CONFIG)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(CP) $(<) $(@)

$(OUTDIR)/.%: _%.j2 $(CONFIG) $(wildcard include/*.inc)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(J2) $(<) $(CONFIG) > $(@)

clean:
	rm -rf $(OUTDIR)

