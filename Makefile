EXECUTION=normal
LEGACY=

ifeq ($(OS),Windows_NT)
	SPOOKYLIB = spookyhash.dll
	SPOOKY = -L./lib/spookyhash/build/bin/Release -L./lib/spookyhash/build -l:$(SPOOKYLIB)
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc-5.4.0.exe
	PREMAKE = premake5.exe
	OUT = build/gtools_windows$(LEGACY).plugin
	OUTM = build/gtools_windows_multi$(LEGACY).plugin build/gtools_multi$(LEGACY).o 
	OUTE = build/env_set_windows$(LEGACY).plugin
	OPENMP = -fopenmp -DGMULTI=1
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
		OUT = build/gtools_unix$(LEGACY).plugin  build/gtools$(LEGACY).o
		OUTM = build/gtools_unix_multi$(LEGACY).plugin build/gtools_multi$(LEGACY).o
		OUTE = build/env_set_unix$(LEGACY).plugin
		SPOOKYLIB = libspookyhash.a
		SPOOKY = -L./lib/spookyhash/build/bin/Release -L./lib/spookyhash/build -l:$(SPOOKYLIB)
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAGS = -bundle -DSYSTEM=APPLEMAC
		OUT = build/gtools_macosx$(LEGACY).plugin
		OUTM = build/gtools_macosx_multi$(LEGACY).plugin build/gtools_multi$(LEGACY).o
		OUTE = build/env_set_macosx$(LEGACY).plugin
		SPOOKYLIB = libspookyhash.a
		SPOOKY = lib/spookyhash/build/bin/Release/$(SPOOKYLIB)
	endif
	GCC = gcc
	PREMAKE = premake5
	OPENMP = -fopenmp -DGMULTI=1
endif

ifeq ($(EXECUTION),windows)
	SPOOKYLIB = spookyhash.dll
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc
	OUT = build/gtools_windows$(LEGACY).plugin
	OUTM = build/gtools_windows_multi$(LEGACY).plugin build/gtools_multi$(LEGACY).o 
	OUTE = build/env_set_windows$(LEGACY).plugin
endif

SPI = 2.0
SPT = 0.2
CFLAGS = -Wall -O3 $(OSFLAGS)
AUX = build/stplugin.o

# OpenMP only tested on Linux
ifeq ($(OS),Windows_NT)
all: clean links gtools_other
else ifeq ($(EXECUTION),windows)
all: clean links gtools_other
else ifeq ($(UNAME_S),Darwin)
all: clean links gtools_other
else ifeq ($(UNAME_S),Linux)
all: clean links gtools_nix
endif

ifeq ($(OS),Windows_NT)
spooky:
	cp -f ./lib/windows/spookyhash.dll ./build/spookyhash.dll
	cp -f ./lib/windows/spookyhash.dll ./lib/spookyhash/build/spookyhash.dll
	echo -e "\nTo re-compile SpookyHash, run from the Visual Studio Developer Command Prompt:" \
	     "\n    copy /Y lib\\\\windows\\\\spookyhash-premake5.lua lib\\\\spookyhash\\\\build\\\\premake5.lua" \
	     "\n    cd lib\\\\spookyhash\\\\build" \
	     "\n    $(PREMAKE) vs2013" \
	     "\n    msbuild SpookyHash.sln" \
	     "\nSee 'Building#Troubleshooting' in README.md for details."
else ifeq ($(EXECUTION),windows)
spooky:
	cp -f ./lib/windows/spookyhash.dll ./build/spookyhash.dll
	cp -f ./lib/windows/spookyhash.dll ./lib/spookyhash/build/spookyhash.dll
else ifeq ($(UNAME_S),Darwin)
spooky:
	cd lib/spookyhash/build && $(PREMAKE) gmake
	cd lib/spookyhash/build && make clean
	cd lib/spookyhash/build && make
	mkdir -p ./build
else ifeq ($(UNAME_S),Linux)
ifeq ($(LEGACY),_legacy)
spooky:
	# cd lib/spookyhash/build && $(PREMAKE) gmake
	cd lib/spookyhash/build && make clean
	cd lib/spookyhash/build && make CFLAGS+=-fPIC
else
spooky:
	cd lib/spookyhash/build && $(PREMAKE) gmake
	cd lib/spookyhash/build && make clean
	cd lib/spookyhash/build && make
endif
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

gtools_other: src/plugin/gtools.c src/plugin/spi/stplugin.c
	# $(GCC) $(CFLAGS) -c -o build/stplugin.o src/plugin/spi/stplugin.c
	# $(GCC) $(CFLAGS) -c -o build/gtools_multi$(LEGACY).o src/plugin/gtools.c $(OPENMP)
	# $(GCC) $(CFLAGS)    -o $(OUTM) $(AUX) $(SPOOKY) $(OPENMP) # Does not load
	# $(GCC) -Wall -O3    -o $(OUTM) $(AUX) $(SPOOKY) $(OPENMP) # Crashes
	mkdir -p ./build
	mkdir -p ./lib/spookyhash/build/bin/Release
	$(GCC) $(CFLAGS) -o $(OUT)  src/plugin/spi/stplugin.c src/plugin/gtools.c $(SPOOKY)
	$(GCC) $(CFLAGS) -o $(OUTE) src/plugin/spi/stplugin.c src/plugin/env_set.c
	cp build/*plugin lib/plugin/

gtools_nix: src/plugin/gtools.c src/plugin/spi/stplugin.c
	mkdir -p ./build
	mkdir -p ./lib/spookyhash/build/bin/Release
	$(GCC) $(CFLAGS) -c -o build/stplugin.o src/plugin/spi/stplugin.c
	$(GCC) $(CFLAGS) -c -o build/gtools$(LEGACY).o src/plugin/gtools.c
	$(GCC) $(CFLAGS)    -o $(OUT)  $(AUX) $(SPOOKY)
	$(GCC) $(CFLAGS) -c -o build/gtools_multi$(LEGACY).o src/plugin/gtools.c $(OPENMP)
	$(GCC) $(CFLAGS)    -o $(OUTM) $(AUX) $(SPOOKY) $(OPENMP)
	$(GCC) $(CFLAGS) -o $(OUTE) src/plugin/spi/stplugin.c src/plugin/env_set.c

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTM) $(OUTE) $(AUX)
