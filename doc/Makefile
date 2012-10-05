# file: Makefile
# author: Andera Vedaldi and Karel Lenc
# brief: Build the documentation and package

NAME := vlbenchmakrs
VER := 1.0-beta
DIST = $(NAME)-$(VER)

html_src = $(wildcard *.html)
demo_src := $(wildcard demo/*.eps)

GIT ?= git
WEBDOC  ?= webdoc/webdoc.py
PYTHON  ?= python2.7
CONVERT ?= convert
MEX ?= mex
MATLAB_PATH ?= $(strip $(shell test "$$(command -v '$(MEX)')" && \
  $(MEX) -v 2>&1 | sed -n 's/.*MATLAB *= *\(.*\)/\1/gp'))
MATLAB_EXE ?= "$(MATLAB_PATH)/bin/matlab"

# 95 DPI makes a letter page 808 pixels large
screen_dpi := 95

pubs=$(wildcard assets/pubs/*.pdf)
pub_thumbs=$(pubs:.pdf=.png)
jpg_tgt := $(demo_src:.eps=.jpg)
img_tgt := $(jpg_tgt)

.PHONY: all assets deep

all: html/index.html assets $(pub_thumbs)

deep: all ../repeatabilityDemo.m
	cd .. ; \
	$(MATLAB_EXE) -$(ARCH) -nodesktop -r "clear mex;repeatabilityDemo(fullfile(pwd,'doc','demo'));exit"
	$(MATLAB_EXE) -$(ARCH) -nodesktop -r "clear mex;retrievalDemo(fullfile(pwd,'doc','demo'));exit"
	cd .. ;

html/index.html: vlbenchmarks.xml \
vlbenchmarks.css pygmentize.css \
html $(img_tgt) $(html_src) $(WEBDOC)
	$(PYTHON) $(WEBDOC) $(<)

assets: html/assets html/images html/demo \
html/vlbenchmarks.css html/pygmentize.css dist-src

html:
	mkdir html

html/assets:
	ln -s ../assets html/assets

html/images:
	ln -s ../images html/images

html/demo:
	ln -s ../demo html/demo

html/vlbenchmarks.css:
	ln -s ../vlbenchmarks.css html/vlbenchmarks.css

html/pygmentize.css:
	ln -s ../pygmentize.css html/pygmentize.css

demo/%.jpg: demo/%.eps
	$(CONVERT) -density 400 -resample $(screen_dpi)  "$<" -colorspace rgb jpg:$@

.PHONY: clean
clean:
	find . -name '*~' -delete

.PHONY: distclean
distclean:
	rm -rf html/

.PHONY: dist-src
dist-src:
	mkdir -p assets/versions/
	COPYFILE_DISABLE=1 \
	COPY_EXTENDED_ATTRIBUTES_DISABLE=1 \
	$(GIT) archive --prefix=$(NAME)-$(VER)/ v$(VER) | gzip > assets/versions/$(DIST).tar.gz

.PHONY: post
post: all
	rsync --delete --exclude=.htaccess \
              --exclude='*.DS_Store' --copy-links \
	      -rvz html/ vlfeat-admin:vlfeat.org/sandbox/benchmarks/
