all: autotools.html

autotools.html: autotools.rst
	rst2html.py --stylesheet-path=style.css autotools.rst > autotools.html

install: all
	cp -f autotools.html $(HOME)/public_html/
