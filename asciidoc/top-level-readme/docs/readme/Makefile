# Required software packages for Arch Linux
# asciidoc
# dblatex
# ditaa
# graphviz (dot)
# inkscape
# pandoc
# plantuml
# xmlstarlet

SRC_ADOC      := ../../README.adoc
SRC_IMG       := $(wildcard img/*.jpg) $(wildcard img/*.png)
SRC_DOT       := $(wildcard src/*.dot)
SRC_DITAA     := $(wildcard src/*.ditaa)
SRC_UML       := $(wildcard src/*.uml)

DST_DOT_SVG   := $(SRC_DOT:src/%=img/%.svg)
DST_DITAA_SVG := $(SRC_DITAA:src/%=img/%.svg)
DST_UML_SVG   := $(SRC_UML:src/%=img/%.svg)
DST_IMG_SVG   := $(DST_DOT_SVG) $(DST_DITAA_SVG) $(DST_UML_SVG)

DST_DOT_PDF   := $(SRC_DOT:src/%=build/%.pdf)
DST_DITAA_PDF := $(SRC_DITAA:src/%=build/%.pdf)
DST_UML_PDF   := $(SRC_UML:src/%=build/%.pdf)
DST_IMG_PDF   := $(DST_DOT_PDF) $(DST_DITAA_PDF) $(DST_UML_PDF)

DST_DOT_EMF   := $(SRC_DOT:src/%=build/%.emf)
DST_DITAA_EMF := $(SRC_DITAA:src/%=build/%.emf)
DST_UML_EMF   := $(SRC_UML:src/%=build/%.emf)
DST_IMG_EMF   := $(DST_DOT_EMF) $(DST_DITAA_EMF) $(DST_UML_EMF)

DST_HTML      := $(SRC_ADOC:../../%.adoc=out/%.html)
DST_PDF       := $(SRC_ADOC:../../%.adoc=out/%.pdf)
DST_DOCX      := $(SRC_ADOC:../../%.adoc=out/%.docx)

#.PHONY: all
all: $(DST_HTML) $(DST_PDF) $(DST_DOCX)

#### Directories for artifacts

build:
	mkdir build

out:
	mkdir out

#### Generated documents

# Make the generated html file contain the contents of the svg files so they are self-contained.
# The first for loop appends the contents of the svg file after the img tag. The second for loop removes the img tag itself.
$(DST_HTML): $(SRC_ADOC) $(DST_IMG_SVG) build out
	asciidoc -b html -o $@ $<
	for i in $(SRC_IMG); do \
		title="`grep -Po '(?<=image::docs/readme/'$$i'\[")[^"]*' $(SRC_ADOC)`"; \
		ext="`echo $$i | sed 's,.*[.],,'`"; \
		echo -n '<img src="data:image/'$$ext';base64,' > build/tmp.b64; \
		base64 -w 0 $$i >> build/tmp.b64; \
		echo -n '" alt="'$$title'"/>' >> build/tmp.b64; \
		sed -i '\,<img src="docs/readme/'$$i'"[^/]*/>,r build/tmp.b64' $@; \
		sed -i '\,<img src="docs/readme/'$$i'"[^/]*/>,d' $@; \
	done; \
	for i in $(DST_IMG_SVG); do \
		sed -n '/<svg/,$$p' $$i > build/tmp.svg; \
		sed -i '\,<img src="docs/readme/'$$i'"[^/]*/>,r build/tmp.svg' $@; \
		sed -i '\,<img src="docs/readme/'$$i'"[^/]*/>,d' $@; \
	done

$(DST_PDF): $(SRC_ADOC) $(DST_IMG_PDF) out
	sed -r 's,(image::)docs/readme/,\1,;s,img/(.*).svg,build/\1.pdf,' $< | \
		asciidoc -b docbook -o - - | \
		dblatex -T db2latex -P doc.layout="toc mainmatter" -tpdf -o $@ -

$(DST_DOCX): $(SRC_ADOC) $(DST_IMG_EMF) out
	sed -r 's,(image::)docs/readme/,\1,;s,img/(.*).svg,build/\1.emf,' $< | \
		asciidoc -b docbook -o - - | \
		pandoc -f docbook -t docx -o $@ --toc

#### Generated svg images from text files - the generated files are stored in img and checked in

# The name of the graph in the source file is automatically turned into a title element in the generated svg.
img/%.dot.svg: src/%.dot
	dot -Tsvg $< -o$@

# Sometimes the ditaa image gets generated as a width that is too narrow, even though it's the same width as a png.
# This causes the svg to display with some rightmost words cut off, which causes the pdf image to be cut off, which causes the final pdf to be cut off.
# The title is captured from the adoc file, as ditaa does not generate one.
img/%.ditaa.svg: src/%.ditaa
	title="`grep -Po '(?<=image::docs/readme/$@\[")[^"]*' $(SRC_ADOC)`"; \
		ditaa --svg $< - -T -r | \
		xmlstarlet ed -u "/*/@width" --value "540pt" | \
		xmlstarlet ed -i "/*/*[1]" -t elem -n title -v "$$title" > $@

# The plantuml command does not take a target file.
# The -pipe option generates a file with errors in it.
# The only solution is to rename the file.
# The title is captured from the adoc file, as plantuml does not generate one.
img/%.uml.svg: src/%.uml
	plantuml -tsvg $<
	mv $(<:%.uml=%.svg) $@
	title="`grep -Po '(?<=image::docs/readme/$@\[")([^"]*)' $(SRC_ADOC)`"; \
		xmlstarlet ed --inplace -i "/*/*[1]" -t elem -n title -v "$$title" $@

#### Generated pdf images from svg images - the generated files are stored in build and are git ignored

build/%.dot.pdf: img/%.dot.svg build
	inkscape -o $@ $<
	
build/%.ditaa.pdf: img/%.ditaa.svg build
	inkscape -o $@ $<

build/%.uml.pdf: img/%.uml.svg build
	inkscape -o $@ $<
	
#### Generated emf images from svg images - the generated files are stored in build and are git ignored

build/%.dot.emf: img/%.dot.svg build
	inkscape -o $@ $<

build/%.ditaa.emf: img/%.ditaa.svg build
	inkscape -o $@ $<

build/%.uml.emf: img/%.uml.svg build
	inkscape -o $@ $<

#### Other tasks

.PHONY: vars
.SILENT: vars
vars:
	echo "SRC_ADOC      = $(SRC_ADOC)"
	echo "SRC_IMG       = $(SRC_IMG)"
	echo "SRC_DOT       = $(SRC_DOT)"
	echo "SRC_DITAA     = $(SRC_DITAA)"
	echo "SRC_UML       = $(SRC_UML)"
	echo
	echo "DST_DOT_SVG   = $(DST_DOT_SVG)"
	echo "DST_DITAA_SVG = $(DST_DITAA_SVG)"
	echo "DST_UML_SVG   = $(DST_UML_SVG)"
	echo "DST_IMG_SVG   = $(DST_IMG_SVG)"
	echo
	echo "DST_DOT_PDF   = $(DST_DOT_PDF)"
	echo "DST_DITAA_PDF = $(DST_DITAA_PDF)"
	echo "DST_UML_PDF   = $(DST_UML_PDF)"
	echo "DST_IMG_PDF   = $(DST_IMG_PDF)"
	echo
	echo "DST_DOT_EMF   = $(DST_DOT_EMF)"
	echo "DST_DITAA_EMF = $(DST_DITAA_EMF)"
	echo "DST_UML_EMF   = $(DST_UML_EMF)"
	echo "DST_IMG_EMF   = $(DST_IMG_EMF)"
	echo
	echo "DST_HTML      = $(DST_HTML)"
	echo "DST_PDF       = $(DST_PDF)"
	echo "DST_DOCX      = $(DST_DOCX)"

.PHONY: clean
clean:
	if [ -d build ]; then rm -rf build; fi
	if [ -d out ]; then rm -rf out; fi
