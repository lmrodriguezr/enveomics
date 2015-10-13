
# Makefile for the Enve-omics collection
# @update Oct 13 2013
# @author Luis M. Rodriguez-R <lmrodriguez at gmail dot com>

include globals.mk

TEST=Tests
enveomics_r=enveomics.R

test:
	cd $(TEST) && $(MAKE)

install:
	[[ -d $(bindir)/lib ]] || mkdir $(bindir)/lib
	ln -s $(foreach file,$(SCRIPTS),$(shell pwd)/$(file)) $(bindir)
	ln -s $(shell pwd)/Scripts/lib/enveomics_rb $(bindir)/lib/
	$(R) CMD INSTALL $(enveomics_r)/
	@echo
	@echo Important note:
	@echo This installation has simply created symbolic links to Scripts.
	@echo If you need to move this folder, use uninstall/install afterwards.
	@echo

uninstall:
	for file in $(foreach f,$(SCRIPTS),$(bindir)/$(notdir $f)) ; do \
	   [[ -h $$file ]] && rm $$file ; \
	done
	[[ -h $(bindir)/lib/enveomics_rb ]] && rm $(bindir)/lib/enveomics_rb
	$(R) CMD REMOVE $(enveomics_r)

