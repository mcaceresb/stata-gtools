ifeq ($(OS),Windows_NT)
	SPOOKYLIB = -l:spookyhash.lib
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc-5.4.0.exe
	PREMAKE = premake5
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAGS = -shared -bundle -DSYSTEM=APPLEMAC
	endif
	SPOOKYLIB = -l:libspookyhash.a
	GCC = gcc
	PREMAKE = premake5
endif

SPI = 2.0
SPT = 0.2
CFLAGS = -Wall -O2 $(OSFLAGS)
SPOOKY = -L./lib/spookyhash/build/bin/Release $(SPOOKYLIB)
AUX = build/stplugin.o
OUT = build/gtools.plugin  build/gtools.o
OUTM = build/gtools_multi.plugin build/gtools_multi.o

all: clean links gtools

spooky:
	cd lib/spookyhash/build && premake5 gmake
	cd lib/spookyhash/build && make clean
	cd lib/spookyhash/build && make
	
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
	ls -la ./lib/
	ls -la ./lib/spookyhash/
	ls -la ./lib/spookyhash/build/
	ls -la ./lib/spookyhash/build/bin/
	ls -la ./lib/spookyhash/build/bin/Release/
	ls -la ./lib/spookyhash/build/bin/Release/libspookyhash.a
	$(GCC) $(CFLAGS) -c -o build/stplugin.o      src/plugin/spi/stplugin.c
	$(GCC) $(CFLAGS) -c -o build/gtools.o        src/plugin/gtools.c
	$(GCC) $(CFLAGS) -c -o build/gtools_multi.o  src/plugin/gtools.c -fopenmp -DGMULTI=1
	$(GCC) $(CFLAGS)    -o $(OUT)  $(AUX) $(SPOOKY)
	$(GCC) $(CFLAGS)    -o $(OUTM) $(AUX) $(SPOOKY) -fopenmp

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTM) $(AUX)

