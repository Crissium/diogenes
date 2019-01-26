# This builds the files needed to run Diogenes.
#
# Note that the dictionaries and morphological data are built using
# different makefiles; read the README for details.

DEPDIR = dependencies

DIOGENESVERSION = $(shell grep "Diogenes::Base::Version" server/Diogenes/Base.pm | sed -n 's/[^"]*"\([^"]*\)"[^"]*/\1/p')

ELECTRONVERSION = 4.0.2
ENTSUM = 84cb3710463ea1bd80e6db3cf31efcb19345429a3bafbefc9ecff71d0a64c21c
UNICODEVERSION = 7.0.0
UNICODESUM = bfa3da58ea982199829e1107ac5a9a544b83100470a2d0cc28fb50ec234cb840
STRAWBERRYPERLVERSION=5.28.0.1

all: server/Diogenes/unicode-equivs.pl server/Diogenes/EntityTable.pm server/fonts/GentiumPlus-I.woff server/fonts/GentiumPlus-R.woff

$(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt:
	curl -o $@ http://www.unicode.org/Public/$(UNICODEVERSION)/ucd/UnicodeData.txt
	printf '%s  %s\n' $(UNICODESUM) $@ | shasum -c -a 256

server/Diogenes/unicode-equivs.pl: utils/make_unicode_compounds.pl $(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt
	./utils/make_unicode_compounds.pl < $(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt > $@

build/GentiumPlus-5.000-web.zip:
	mkdir -p build
	curl -o $@ https://software.sil.org/downloads/r/gentium/GentiumPlus-5.000-web.zip

server/fonts/GentiumPlus-I.woff: build/GentiumPlus-5.000-web.zip
	unzip -n build/GentiumPlus-5.000-web.zip -d build
	mkdir -p server/fonts
	cp build/GentiumPlus-5.000-web/web/GentiumPlus-I.woff $@

server/fonts/GentiumPlus-R.woff: build/GentiumPlus-5.000-web.zip
	unzip -n build/GentiumPlus-5.000-web.zip -d build
	mkdir -p server/fonts
	cp build/GentiumPlus-5.000-web/web/GentiumPlus-R.woff $@

$(DEPDIR)/PersXML.ent:
	curl -o $@ http://www.perseus.tufts.edu/DTD/1.0/PersXML.ent
	printf '%s  %s\n' $(ENTSUM) $@ | shasum -c -a 256

server/Diogenes/EntityTable.pm: utils/ent_to_array.pl $(DEPDIR)/PersXML.ent
	printf '# Generated by makefile using utils/ent_to_array.pl\n' > $@
	printf 'package Diogenes::EntityTable;\n\n' >> $@
	./utils/ent_to_array.pl < $(DEPDIR)/PersXML.ent >> $@

electron/electron-v$(ELECTRONVERSION)-linux-x64:
	mkdir -p electron
	curl -L https://github.com/electron/electron/releases/download/v$(ELECTRONVERSION)/electron-v$(ELECTRONVERSION)-linux-x64.zip > electron/electron-v$(ELECTRONVERSION)-linux-x64.zip
	unzip -d electron/electron-v$(ELECTRONVERSION)-linux-x64 electron/electron-v$(ELECTRONVERSION)-linux-x64.zip
	rm electron/electron-v$(ELECTRONVERSION)-linux-x64.zip

linux64: all electron/electron-v$(ELECTRONVERSION)-linux-x64
	rm -rf linux64
	mkdir linux64
	cp -r electron/electron-v$(ELECTRONVERSION)-linux-x64/* linux64
	cp -r server linux64
	cp -r dependencies linux64
	cp -r dist linux64
	cp -r client linux64/resources/app
	mv linux64/electron linux64/diogenes
	cp COPYING README linux64

electron/electron-v$(ELECTRONVERSION)-win32-ia32:
	mkdir -p electron
	curl -L https://github.com/electron/electron/releases/download/v$(ELECTRONVERSION)/electron-v$(ELECTRONVERSION)-win32-ia32.zip > electron/electron-v$(ELECTRONVERSION)-win32-ia32.zip
	unzip -d electron/electron-v$(ELECTRONVERSION)-win32-ia32 electron/electron-v$(ELECTRONVERSION)-win32-ia32.zip
	rm electron/electron-v$(ELECTRONVERSION)-win32-ia32.zip

electron/electron-v$(ELECTRONVERSION)-win32-x64:
	mkdir -p electron
	curl -L https://github.com/electron/electron/releases/download/v$(ELECTRONVERSION)/electron-v$(ELECTRONVERSION)-win32-x64.zip > electron/electron-v$(ELECTRONVERSION)-win32-x64.zip
	unzip -d electron/electron-v$(ELECTRONVERSION)-win32-x64 electron/electron-v$(ELECTRONVERSION)-win32-x64.zip
	rm electron/electron-v$(ELECTRONVERSION)-win32-x64.zip

w32perl:
	mkdir -p w32perl/strawberry
	curl http://strawberryperl.com/download/$(STRAWBERRYPERLVERSION)/strawberry-perl-$(STRAWBERRYPERLVERSION)-32bit-portable.zip > w32perl/strawberry-perl-$(STRAWBERRYPERLVERSION)-32bit-portable.zip
	unzip -d w32perl/strawberry w32perl/strawberry-perl-$(STRAWBERRYPERLVERSION)-32bit-portable.zip
	rm w32perl/strawberry-perl-$(STRAWBERRYPERLVERSION)-32bit-portable.zip

w64perl:
	mkdir -p w64perl/strawberry
	curl http://strawberryperl.com/download/$(STRAWBERRYPERLVERSION)/strawberry-perl-$(STRAWBERRYPERLVERSION)-64bit-portable.zip > w64perl/strawberry-perl-$(STRAWBERRYPERLVERSION)-64bit-portable.zip
	unzip -d w64perl/strawberry w64perl/strawberry-perl-$(STRAWBERRYPERLVERSION)-64bit-portable.zip
	rm w64perl/strawberry-perl-$(STRAWBERRYPERLVERSION)-64bit-portable.zip

rcedit.exe:
	curl -Lo $@ https://github.com/electron/rcedit/releases/download/v0.1.0/rcedit.exe

icons: dist/icon.svg
	@echo "Rendering icons (needs rsvg-convert and Adobe Garamond Pro font)"
	mkdir -p icons
	rsvg-convert -w 256 -h 256 dist/icon.svg > icons/256.png
	rsvg-convert -w 128 -h 128 dist/icon.svg > icons/128.png
	rsvg-convert -w 64 -h 64 dist/icon.svg > icons/64.png
	rsvg-convert -w 48 -h 48 dist/icon.svg > icons/48.png
	rsvg-convert -w 32 -h 32 dist/icon.svg > icons/32.png
	rsvg-convert -w 16 -h 16 dist/icon.svg > icons/16.png

icons/diogenes.ico: icons
	icotool -c icons/256.png icons/128.png icons/64.png icons/48.png icons/32.png icons/16.png > $@

dist/diogenes.icns: icons
	png2icns $@ icons/256.png icons/128.png icons/48.png icons/32.png icons/16.png

w32: all electron/electron-v$(ELECTRONVERSION)-win32-ia32 w32perl icons/diogenes.ico rcedit.exe
	@echo "Making windows package. Note that this requires wine to be"
	@echo "installed, to edit the .exe resources."
	rm -rf w32
	mkdir -p w32
	cp -r electron/electron-v$(ELECTRONVERSION)-win32-ia32/* w32
	cp -r client w32/resources/app
	mv w32/electron.exe w32/diogenes.exe
	cp -r server w32
	cp -r dependencies w32
	cp -r w32perl/strawberry w32
	cp icons/diogenes.ico w32
	sed 's/$$/\r/g' < COPYING > w32/COPYING.txt
	sed 's/$$/\r/g' < README > w32/README.txt
	wine rcedit.exe w32/diogenes.exe \
	    --set-icon icons/diogenes.ico \
	    --set-product-version $(DIOGENESVERSION) \
	    --set-file-version $(DIOGENESVERSION) \
	    --set-version-string CompanyName "The Diogenes Team" \
	    --set-version-string ProductName Diogenes \
	    --set-version-string FileDescription Diogenes

w64: all electron/electron-v$(ELECTRONVERSION)-win32-x64 w64perl icons/diogenes.ico rcedit.exe
	@echo "Making windows package. Note that this requires wine to be"
	@echo "installed, to edit the .exe resources."
	rm -rf w64
	mkdir -p w64
	cp -r electron/electron-v$(ELECTRONVERSION)-win32-x64/* w64
	cp -r client w64/resources/app
	mv w64/electron.exe w64/diogenes.exe
	cp -r server w64
	cp -r dependencies w64
	cp -r w64perl/strawberry w64
	cp icons/diogenes.ico w64
	sed 's/$$/\r/g' < COPYING > w64/COPYING.txt
	sed 's/$$/\r/g' < README > w64/README.txt
	wine rcedit.exe w64/diogenes.exe \
	    --set-icon icons/diogenes.ico \
	    --set-product-version $(DIOGENESVERSION) \
	    --set-file-version $(DIOGENESVERSION) \
	    --set-version-string CompanyName "The Diogenes Team" \
	    --set-version-string ProductName Diogenes \
	    --set-version-string FileDescription Diogenes

electron/electron-v$(ELECTRONVERSION)-darwin-x64:
	mkdir -p electron
	curl -L https://github.com/electron/electron/releases/download/v$(ELECTRONVERSION)/electron-v$(ELECTRONVERSION)-darwin-x64.zip > electron/electron-v$(ELECTRONVERSION)-darwin-x64.zip
	unzip -d electron/electron-v$(ELECTRONVERSION)-darwin-x64 electron/electron-v$(ELECTRONVERSION)-darwin-x64.zip
	rm electron/electron-v$(ELECTRONVERSION)-darwin-x64.zip

mac: all electron/electron-v$(ELECTRONVERSION)-darwin-x64 dist/diogenes.icns
	rm -rf mac
	mkdir -p mac
	cp -r electron/electron-v$(ELECTRONVERSION)-darwin-x64/* mac
	cp -r client mac/Electron.app/Contents/Resources/app
	cp -r server mac/Electron.app/Contents
	cp -r dependencies mac/Electron.app/Contents
	cp dist/diogenes.icns mac/Electron.app/Contents/Resources/
	perl -pi -e 's/electron.icns/diogenes.icns/g' mac/Electron.app/Contents/Info.plist
	perl -pi -e 's/Electron/Diogenes/g' mac/Electron.app/Contents/Info.plist
	perl -pi -e 's/com.github.electron/uk.ac.durham.diogenes/g' mac/Electron.app/Contents/Info.plist
	perl -pi -e 's/$(ELECTRONVERSION)/$(DIOGENESVERSION)/g' mac/Electron.app/Contents/Info.plist
	perl -pi -e 's#</dict>#<key>NSHumanReadableCopyright</key>\n<string>Copyright © 2019 Peter Heslin\nDistributed under the GNU GPL version 3</string>\n</dict>#' mac/Electron.app/Contents/Info.plist
	mv mac/Electron.app mac/Diogenes.app
	mv mac/Diogenes.app/Contents/MacOS/Electron mac/Diogenes.app/Contents/MacOS/Diogenes
	mv "mac/Diogenes.app/Contents/Frameworks/Electron Helper.app/Contents/MacOS/Electron Helper" "mac/Diogenes.app/Contents/Frameworks/Electron Helper.app/Contents/MacOS/Diogenes Helper"
	mv "mac/Diogenes.app/Contents/Frameworks/Electron Helper.app" "mac/Diogenes.app/Contents/Frameworks/Diogenes Helper.app"
	sed 's/$$/\r/g' < COPYING > mac/COPYING.txt
	sed 's/$$/\r/g' < README > mac/README.txt

zip-linux64: linux64
	rm -rf diogenes-linux-$(DIOGENESVERSION)
	mv linux64 diogenes-linux-$(DIOGENESVERSION)
	tar c diogenes-linux-$(DIOGENESVERSION) | xz > diogenes-linux-$(DIOGENESVERSION).tar.xz
	rm -rf diogenes-linux-$(DIOGENESVERSION)

zip-mac: mac
	rm -rf diogenes-mac-$(DIOGENESVERSION)
	mv mac diogenes-mac-$(DIOGENESVERSION)
	zip -r diogenes-mac-$(DIOGENESVERSION).zip diogenes-mac-$(DIOGENESVERSION)
	rm -rf diogenes-mac-$(DIOGENESVERSION)

zip-w32: w32
	rm -rf diogenes-win32-$(DIOGENESVERSION)
	mv w32 diogenes-win32-$(DIOGENESVERSION)
	zip -r diogenes-win32-$(DIOGENESVERSION).zip diogenes-win32-$(DIOGENESVERSION)
	rm -rf diogenes-win32-$(DIOGENESVERSION)

zip-w64: w64
	rm -rf diogenes-win64-$(DIOGENESVERSION)
	mv w64 diogenes-win64-$(DIOGENESVERSION)
	zip -r diogenes-win64-$(DIOGENESVERSION).zip diogenes-win64-$(DIOGENESVERSION)
	rm -rf diogenes-win64-$(DIOGENESVERSION)

zip-all: zip-linux64 zip-mac zip-w32 zip-w64

inno-setup: 
	mkdir inno-setup
	curl -Lo inno-setup/is.exe http://www.jrsoftware.org/download.php/is.exe
	cd inno-setup; innoextract is.exe

installer-w32: inno-setup w32
	wine inno-setup/app/ISCC.exe dist/diogenes-win32.iss
	mv -f dist/Output/mysetup.exe diogenes-setup-win32-$(DIOGENESVERSION).exe
	rmdir dist/Output

installer-w64: inno-setup w64
	wine inno-setup/app/ISCC.exe dist/diogenes-win64.iss
	mv -f Output/mysetup.exe diogenes-setup-win64-$(DIOGENESVERSION).exe
	rmdir Output

# NB. Installing this Mac package will report success but silently fail if there exists another copy of Diogenes.app with the same version number anywhere whatsoever on the same disk volume, such as in the mac directory here or another random copy on the devel machine.  
installer-macpkg: mac
	rm -f Diogenes-$(DIOGENESVERSION).pkg
	fpm --prefix=/Applications -C mac -t osxpkg -n Diogenes -v $(DIOGENESVERSION) --osxpkg-identifier-prefix uk.ac.durham.diogenes -s dir Diogenes.app

installer-deb64: linux64
	rm -f diogenes-$(DIOGENESVERSION)_amd64.deb
	fpm -s dir -t deb -n diogenes -v $(DIOGENESVERSION) -a x86_64 \
		-p diogenes-$(DIOGENESVERSION)_amd64.deb -d perl \
		-m p.j.heslin@durham.ac.uk --vendor p.j.heslin@durham.ac.uk \
		--url http://diogenes.durham.ac.uk \
		--description "Tool for legacy databases of Latin and Greek texts" \
		--license GPL3 --post-install dist/post-install-deb.sh \
		linux64/=/usr/local/diogenes/ \
		dist/diogenes.desktop=/usr/share/applications/ \
		dist/icon.svg=/usr/share/icons/diogenes.svg

# Completely untested functionality.  I don't know how many of these fpm options are applicable when generating rpms.
installer-rpm64: linux64
	rm -f diogenes-$(DIOGENESVERSION).x86_64.rpm
	fpm -s dir -t rpm -n diogenes -v $(DIOGENESVERSION) -a x86_64 \
		-p diogenes-$(DIOGENESVERSION).x86_64.rpm -d perl \
		-m p.j.heslin@durham.ac.uk --vendor p.j.heslin@durham.ac.uk \
		--url http://diogenes.durham.ac.uk \
		--description "Tool for legacy databases of Latin and Greek texts" \
		--license GPL3 --post-install dist/post-install-rpm.sh \
		linux64/=/usr/local/diogenes/ \
		dist/diogenes.desktop=/usr/share/applications/ \
		dist/icon.svg=/usr/share/icons/diogenes.svg

installer-arch64: linux64
	rm -f diogenes-$(DIOGENESVERSION).pkg.tar.xz
	fpm -s dir -t pacman -n diogenes -v $(DIOGENESVERSION) -a x86_64 \
		-p diogenes-$(DIOGENESVERSION).pkg.tar.xz -d perl \
		-m p.j.heslin@durham.ac.uk --vendor p.j.heslin@durham.ac.uk \
		--url http://diogenes.durham.ac.uk \
		--description "Tool for legacy databases of Latin and Greek texts" \
		--license GPL3 --post-install dist/post-install-rpm.sh \
		linux64/=/usr/local/diogenes/ \
		dist/diogenes.desktop=/usr/share/applications/ \
		dist/icon.svg=/usr/share/icons/diogenes.svg

installer-all: installer-w32 installer-w64 installer-macpkg installer-deb64 installer-rpm64 installer-arch64

clean:
	rm -f $(DEPDIR)/UnicodeData-$(UNICODEVERSION).txt
	rm -f server/Diogenes/unicode-equivs.pl
	rm -f $(DEPDIR)/PersXML.ent
	rm -f server/Diogenes/EntityTable.pm
	rm -rf server/fonts
	rm -rf icons dist/diogenes.icns
	rm -f rcedit.exe
	rm -rf build
	rm -rf electron
	rm -rf mac diogenes-mac-$(DIOGENESVERSION)
	rm -rf linux64 diogenes-linux64-$(DIOGENESVERSION)
	rm -rf w32 w32perl diogenes-w32-$(DIOGENESVERSION)
	rm -rf w64 w64perl diogenes-w64-$(DIOGENESVERSION)
	rm -rf inno-setup
	rm -f diogenes-setup-win32-$(DIOGENESVERSION).exe
	rm -f diogenes-setup-win64-$(DIOGENESVERSION).exe
	rm -f Diogenes-$(DIOGENESVERSION).pkg
	rm -f diogenes-$(DIOGENESVERSION)_amd64.deb
	rm -f diogenes-$(DIOGENESVERSION).x86_64.rpm
	rm -f diogenes-$(DIOGENESVERSION).pkg.tar.xz

