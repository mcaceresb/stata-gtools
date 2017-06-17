EXECUTION=normal

ifeq ($(OS),Windows_NT)
	SPOOKYLIB = -l:spookyhash.dll
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc-5.4.0.exe
	PREMAKE = premake5.exe
	OUT = build/gtools_windows.plugin  build/gtools.o
	OUTM = build/gtools_windows_multi.plugin build/gtools_multi.o
	OPENMP = -fopenmp -DGMULTI=1
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
		OUT = build/gtools_unix.plugin  build/gtools.o
		OUTM = build/gtools_unix_multi.plugin build/gtools_multi.o
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAGS = -shared -bundle -DSYSTEM=APPLEMAC
		OUT = build/gtools_macosx.plugin  build/gtools.o
		OUTM = build/gtools_macosx_multi.plugin build/gtools_multi.o
	endif
	SPOOKYLIB = -l:libspookyhash.a
	GCC = gcc
	PREMAKE = premake5
	OPENMP = -fopenmp -DGMULTI=1
endif

ifeq ($(EXECUTION),windows)
	SPOOKYLIB = -l:spookyhash.dll
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc
	OUT = build/gtools_windows.plugin  build/gtools.o
	OUTM = build/gtools_windows_multi.plugin build/gtools_multi.o
endif

SPI = 2.0
SPT = 0.2
CFLAGS = -Wall -O2 $(OSFLAGS)
SPOOKY = -L./lib/spookyhash/build/bin/Release -L./lib/spookyhash/build $(SPOOKYLIB)
AUX = build/stplugin.o

all: clean links gtools

ifeq ($(OS),Windows_NT)
spooky:
	cp -f ./lib/windows/spookyhash.dll ./build/
	cp -f ./lib/windows/spookyhash.dll ./lib/spookyhash/build/
	echo -e "\nTo re-compile SpookyHash, run from the Visual Studio Developer Command Prompt:" \
	     "\n    copy /Y lib\\\\windows\\\\spookyhash-premake5.lua lib\\\\spookyhash\\\\build\\\\premake5.lua" \
	     "\n    cd lib\\\\spookyhash\\\\build" \
	     "\n    $(PREMAKE) vs2013" \
	     "\n    msbuild SpookyHash.sln" \
	     "\nSee 'Compiling on Windows' in README.md for details."
else ifeq ($(EXECUTION),windows)
spooky:
	cp -f ./lib/windows/spookyhash.dll ./build/
	cp -f ./lib/windows/spookyhash.dll ./lib/spookyhash/build/
else
spooky:
	cd lib/spookyhash/build && $(PREMAKE) gmake
	cd lib/spookyhash/build && make clean
	cd lib/spookyhash/build && make
endif

spookytest:
	cd lib/spookyhash/build && ./bin/Release/spookyhash-test

links:
	rm -f  src/plugin/lib
	rm -f  src/plugin/spt
	rm -f  src/plugin/spi
	rm -f  src/plugin/spookyhash
	ln -sf ../../lib 	  src/plugin/lib
	ln -sf lib/spt-$(SPT) src/plugin/spt
	ln -sf lib/spi-$(SPI) src/plugin/spi
	ln -sf lib/spookyhash src/plugin/spookyhash

gtools: src/plugin/gtools.c src/plugin/spi/stplugin.c
	mkdir -p build
	$(GCC) $(CFLAGS) -c -o build/stplugin.o      src/plugin/spi/stplugin.c
	$(GCC) $(CFLAGS) -c -o build/gtools.o        src/plugin/gtools.c
	$(GCC) $(CFLAGS) -c -o build/gtools_multi.o  src/plugin/gtools.c $(OPENMP)
	$(GCC) $(CFLAGS)    -o $(OUT)  $(AUX) $(SPOOKY)
	$(GCC) $(CFLAGS)    -o $(OUTM) $(AUX) $(SPOOKY) $(OPENMP)

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTM) $(AUX) ./build/spookyhash.dll ./lib/spookyhash/build/spookyhash.dll
