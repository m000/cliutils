HOSTNAME    = $(shell uname -n | cut -d. -f1)
KERNEL      = $(shell uname -s | tr A-Z a-z)
OUTDIR      = output

CONFIG      = config/$(HOSTNAME)-$(KERNEL).json
RCFILES_IN  = $(wildcard *rc.j2)
RCFILES_OUT = $(patsubst %.j2,$(OUTDIR)/.%,$(RCFILES_IN))

RSYNC       = rsync
DIFF        = diff
GREP        = grep
J2          = j2 -C --undefined=normal




.PHONY: all copy-dry copy-real

all: $(OUTDIR) $(RCFILES_OUT)

copy-dry: all
	$(RSYNC) -avPhi -n $(OUTDIR)/ $(HOME)/

copy-real: all
	$(RSYNC) -avPhi $(OUTDIR)/ $(HOME)/

diff: all
	$(DIFF) -wr $(HOME)/ $(OUTDIR)/ | $(GREP) -v "^Only in $(HOME)/:" || true

$(OUTDIR)/.%rc: %rc.j2 $(CONFIG) $(wildcard include/*.inc)
	$(J2) $< $(CONFIG) > $(@)

$(OUTDIR):
	mkdir -p $@

clean:
	rm -rf $(OUTDIR)

