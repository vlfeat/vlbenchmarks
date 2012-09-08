html_src = $(wildcard *.html)

WEBDOC ?= webdoc/webdoc.py
PYTHON ?= /opt/local/bin/python2.6

pubs=$(wildcard assets/pubs/*.pdf)
pub_thumbs=$(pubs:.pdf=.png)

.PHONY: all, assets

all: html/index.html assets $(pub_thumbs)

html/index.html: vlbenchmarks.xml vlbenchmarks.css pygmentize.css html $(html_src) $(WEBDOC)
	$(PYTHON) $(WEBDOC) $(<)

html:
	mkdir html

assets: html/assets html/images html/vlbenchmarks.css html/pygmentize.css

html/assets:
	ln -s ../assets html/assets

html/images:
	ln -s ../images html/images

html/vlbenchmarks.css:
	ln -s ../vlbenchmarks.css html/vlbenchmarks.css

html/pygmentize.css:
	ln -s ../pygmentize.css html/pygmentize.css

.PHONY: clean
clean:
	find . -name '*~' -delete

.PHONY: distclean
distclean:
	rm -rf html/

.PHONY: post
post: all
	rsync --delete --exclude=.htaccess \
              --exclude='*.DS_Store' --copy-links \
	      -rvz html/ vlfeat-admin:vlfeat.org/benchmarks/
