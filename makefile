# This builds the files needed to run Diogenes.
#
# Note that the dictionaries and morphological data are built using
# different makefiles; read the README for details.

DEPDIR = dependencies

#NWJSVERSION = 0.14.7
NWJSVERSION = 0.18.0
ENTSUM = 84cb3710463ea1bd80e6db3cf31efcb19345429a3bafbefc9ecff71d0a64c21c
UNICODEVERSION = 7.0.0
UNICODESUM = bfa3da58ea982199829e1107ac5a9a544b83100470a2d0cc28fb50ec234cb840

all: diogenes-browser/perl/Diogenes/unicode-equivs.pl diogenes-browser/perl/Diogenes/EntityTable.pm

$(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt:
	wget -O $@ http://www.unicode.org/Public/$(UNICODEVERSION)/ucd/UnicodeData.txt
	printf '%s  %s\n' $(UNICODESUM) $@ | sha256sum -c

diogenes-browser/perl/Diogenes/unicode-equivs.pl: utils/make_unicode_compounds.pl $(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt
	./utils/make_unicode_compounds.pl < $(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt > $@

$(DEPDIR)/PersXML.ent:
	wget -O $@ http://www.perseus.tufts.edu/DTD/1.0/PersXML.ent
	printf '%s  %s\n' $(ENTSUM) $@ | sha256sum -c

diogenes-browser/perl/Diogenes/EntityTable.pm: utils/ent_to_array.pl $(DEPDIR)/PersXML.ent
	printf '# Generated by makefile using utils/ent_to_array.pl\n' > $@
	printf 'package Diogenes::EntityTable;\n\n' >> $@
	./utils/ent_to_array.pl < $(DEPDIR)/PersXML.ent >> $@

nw/nwjs-v$(NWJSVERSION)-linux-x64:
	mkdir -p nw
	cd nw && wget https://dl.nwjs.io/v$(NWJSVERSION)/nwjs-v$(NWJSVERSION)-linux-x64.tar.gz
	cd nw && zcat < nwjs-v$(NWJSVERSION)-linux-x64.tar.gz | tar x

linux64: all nw/nwjs-v$(NWJSVERSION)-linux-x64
	mkdir -p linux64
	cp -r nw/nwjs-v$(NWJSVERSION)-linux-x64 linux64
	cp -r diogenes-browser linux64
	cp -r dependencies linux64
	cp -r dist linux64
	printf '#/bin/sh\n./nwjs-v$(NWJSVERSION)-linux-x64/nw dist/nwjs\n' > linux64/diogenes
	chmod +x linux64/diogenes

nw/nwjs-v$(NWJSVERSION)-osx-x64:
	mkdir -p nw
	cd nw && wget https://dl.nwjs.io/v$(NWJSVERSION)/nwjs-v$(NWJSVERSION)-osx-x64.zip
	cd nw && unzip nwjs-v$(NWJSVERSION)-osx-x64.zip

mac: all nw/nwjs-v$(NWJSVERSION)-osx-x64
	mkdir -p mac
	cp -r nw/nwjs-v$(NWJSVERSION)-osx-x64/nwjs.app mac/Diogenes.app
	mkdir -p mac/Diogenes.app/Contents/Resources/app.nw
	cp -r diogenes-browser mac/Diogenes.app/Contents
	cp -r dependencies mac/Diogenes.app/Contents
	cp -r dist/nwjs/* mac/Diogenes.app/Contents/Resources/app.nw
	cp -r dist/app.icns mac/Diogenes.app/Contents/Resources/
	cp -r dist/app.icns mac/Diogenes.app/Contents/Resources/document.icns
	perl -pi -e 's/CFBundleName = "nwjs"/CFBundleName = "Diogenes"/g' mac/Diogenes.app/Contents/Resources/*.lproj/InfoPlist.strings

clean:
	rm -f $(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt
	rm -f diogenes-browser/perl/Diogenes/unicode-equivs.pl
	rm -f $(DEPDIR)/PersXML.ent
	rm -f diogenes-browser/perl/Diogenes/EntityTable.pm
