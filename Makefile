BUILDDIR := build
DESIGN_DOCS = $(wildcard design_docs/*.rst)

.PHONY: clean html pdf bps all

all: bps html pdf

clean:
	rm -rf $(BUILDDIR)/*

bps: $(DESIGN_DOCS) | $(BUILDDIR)
	mkdir -p $(BUILDDIR)/design_docs
	$(foreach f,$(DESIGN_DOCS),rst2html.py $(f) $(BUILDDIR)/$(f:.rst=.html);)

bps: $(DESIGN_DOCS) | $(BUILDDIR)
	mkdir -p $(BUILDDIR)/design_docs
	$(foreach f,$(DESIGN_DOCS),rst2html.py $(f) $(BUILDDIR)/$(f:.rst=.pdf);)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)
