all: autotools_html

autotools_html: autotools.rst
	rst2html.py --stylesheet-path=style.css autotools.rst > autotools.html
