
# Makefile for the Enve-omics collection
# @update Oct 13 2013
# @author Luis M. Rodriguez-R <lmrodriguez at gmail dot com>

include globals.mk

TEST=Tests
enveomics_r=enveomics.R
enveomics_r_v=enveomics.R_1.1.2
.PHONY: test install install-scripts install-r uninstall install-deps

test: $(enveomics_r_v).tar.gz
	@echo 
	@echo Testing
	cd $(TEST) && $(MAKE)
	@echo 
	@echo Testing $(enveomics_r)
	$(R) CMD check --as-cran $(enveomics_r_v).tar.gz

install: install-r install-scripts

install-scripts:
	[[ -d $(bindir)/lib ]] || mkdir $(bindir)/lib
	ln -s $(foreach file,$(SCRIPTS),$(shell pwd)/$(file)) $(bindir)
	ln -s $(shell pwd)/Scripts/lib/enveomics_rb $(bindir)/lib/
	@echo
	@echo Important note:
	@echo This installation has simply created symbolic links to Scripts.
	@echo If you need to move this folder, use uninstall/install afterwards.
	@echo

install-r:
	$(R) CMD INSTALL $(enveomics_r)/

uninstall:
	-for file in $(foreach f,$(SCRIPTS),$(bindir)/$(notdir $f)) ; do \
	   [[ -h $$file ]] && rm -r $$file ; \
	done
	-[[ -h $(bindir)/lib/enveomics_rb ]] && rm -r $(bindir)/lib/enveomics_rb
	-$(R) CMD REMOVE $(enveomics_r)

$(enveomics_r_v).tar.gz: install-deps
	-rm -r $(enveomics_r).tar.gz
	./build_enveomics_r.bash
	$(R) CMD build $(enveomics_r)/
	$(MAKE) install-r

install-deps: /usr/local/bin/brew /Library/TeX/texbin/pdflatex
	pandoc -v %%>/dev/null || brew install pandoc
	#qpdf -v %%>/dev/null || brew install qpdf
	[[ -d /usr/local/opt/texinfo/bin ]] || brew install texinfo
