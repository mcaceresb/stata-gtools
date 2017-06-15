ifeq ($(OS),Windows_NT)
	SPOOKYLIB = -l:spookyhash.lib
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc-5.4.0.exe
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
endif

SPI = 2.0
SPT = 0.2
CFLAGS = -Wall -O2 $(OSFLAGS)
SPOOKY = -L./lib/spookyhash/build/bin/Release $(SPOOKYLIB)
AUX = build/stplugin.o
OUT = build/gtools.plugin  build/gtools.o
OUTM = build/gtools_multi.plugin build/gtools_multi.o

all: clean links gtools

links:
	rm -f  src/plugin/lib
	rm -f  src/plugin/spt
	rm -f  src/plugin/spi
	rm -f  src/plugin/spookyhash
	cd src/plugin && ln -sf ../../lib 	 lib
	cd src/plugin && ln -sf lib/spt-$(SPT) spt
	cd src/plugin && ln -sf lib/spi-$(SPI) spi
	cd src/plugin && ln -sf lib/spookyhash spookyhash

gtools: src/plugin/gtools.c src/plugin/spi/stplugin.c
	mkdir -p build
	cd src/plugin && $(GCC) $(CFLAGS) -c -o ../../build/stplugin.o     spi/stplugin.c
	cd src/plugin && $(GCC) $(CFLAGS) -c -o ../../build/gtools.o       gtools.c
	cd src/plugin && $(GCC) $(CFLAGS) -c -o ../../build/gtools_multi.o gtools.c -fopenmp -DGMULTI=1
	$(GCC) $(CFLAGS) -o $(OUT)  $(AUX) $(SPOOKY)
	$(GCC) $(CFLAGS) -o $(OUTM) $(AUX) $(SPOOKY) -fopenmp

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTM) $(AUX)
