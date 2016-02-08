OUTDIR      = output
HOSTNAME    = $(shell uname -n | cut -d. -f1)
KERNEL      = $(shell uname -s | tr A-Z a-z)
CONFIG      = config/$(HOSTNAME)-$(KERNEL).json
RCFILES_IN  = $(shell find _* -type f -iname '*.j2')
RCFILES_OUT = $(patsubst _%.j2,$(OUTDIR)/.%,$(RCFILES_IN))

MKDIR       = mkdir -vp
RSYNC       = rsync
DIFF        = diff
GREP        = grep
J2          = j2 -C --undefined=normal

# adjust RCFILES_OUT depending on kernel (i.e. OS)
ifneq ($(KERNEL),linux)
	RCFILES_OUT := $(filter-out $(OUTDIR)/.xinitrc,$(RCFILES_OUT))
endif


.PHONY: all copy-dry copy-real

all: $(RCFILES_OUT)

copy-dry: all
	$(RSYNC) -avPhi -n $(OUTDIR)/ $(HOME)/

copy-real: all
	$(RSYNC) -avPhi $(OUTDIR)/ $(HOME)/

diff: all
	$(DIFF) -wr $(HOME)/ $(OUTDIR)/ | $(GREP) -v "^Only in $(HOME)/:" || true

$(OUTDIR)/.%: _%.j2 $(CONFIG) $(wildcard include/*.inc)
	@test -d $(@D) || $(MKDIR) $(@D)
	$(J2) $< $(CONFIG) > $(@)

clean:
	rm -rf $(OUTDIR)

