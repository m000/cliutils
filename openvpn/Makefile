# Tools used by the Makefile.
CP          = cp -f
MKDIR       = mkdir -vp
RSYNC       = rsync
DIFF        = diff
GREP        = grep
J2          = j2 -C --undefined=normal

# Configuration variables, affecting the processing of templates.
INDIR			= input
OUTDIR          = output
DESTDIR			?= /etc
HOSTNAME        = $(shell uname -n)
HOSTNAME_SHORT  = $(shell uname -n | cut -d. -f1)
KERNEL          = $(shell uname -s | tr A-Z a-z)

# Choose config file.
CONFIG          ?= config/$(HOSTNAME)-$(KERNEL).json
ifeq ($(realpath $(CONFIG)),)
CONFIG          = config/$(HOSTNAME_SHORT)-$(KERNEL).json
endif
ifeq ($(realpath $(CONFIG)),)
$(error No configuration file for this host)
endif

# Make a list of *.j2 files that should be compiled with j2cli.
RCFILES_IN      = $(shell find $(INDIR) -type f -iname '*.j2')
RCFILES_OUT     = $(patsubst $(INDIR)/%.j2,$(OUTDIR)/%,$(RCFILES_IN))

# Anything inside a directory that is not a template is copied without processing.
RCFILES_CP_FROM	= $(shell find $(INDIR) -type f -not -iname '*.j2' -not -iname '.git*')
RCFILES_CP_TO   = $(patsubst $(INDIR)/%,$(OUTDIR)/%,$(RCFILES_CP_FROM))

# Exclude unwanted files from being copied.
RCFILES_CP_TO	:= $(filter-out %.swp,$(RCFILES_CP_TO))
RCFILES_CP_TO	:= $(filter-out %.swo,$(RCFILES_CP_TO))

# adjust RCFILES_OUT depending on kernel (i.e. OS)
ifneq ($(KERNEL),linux)
	RCFILES_OUT := $(filter-out $(OUTDIR)/.x%,$(RCFILES_OUT))
	RCFILES_OUT := $(filter-out $(OUTDIR)/.i3/%,$(RCFILES_OUT))
	RCFILES_OUT := $(filter-out $(OUTDIR)/.local/share/applications/%,$(RCFILES_OUT))
endif


.PHONY: all copy-dry copy-real

all: $(RCFILES_OUT) $(RCFILES_CP_TO)

copy-dry: all
	$(RSYNC) --exclude-from=config/exclude.txt -avPhi -n $(OUTDIR)/ $(DESTDIR)/

copy-real: all
	$(RSYNC) --exclude-from=config/exclude.txt -avPhi $(OUTDIR)/ $(DESTDIR)/

diff: all
	$(DIFF) --exclude-from=config/exclude.txt -wr $(DESTDIR)/ $(OUTDIR)/ | $(GREP) -v "^Only in $(DESTDIR)/[^:]*:" || true

$(OUTDIR)/%: $(INDIR)/% $(CONFIG)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(CP) $(<) $(@)

$(OUTDIR)/%: $(INDIR)/%.j2 $(CONFIG) $(wildcard include/*.inc)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(J2) $(<) $(CONFIG) > $(@)

clean:
	rm -rf $(OUTDIR)

