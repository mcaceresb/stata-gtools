SPI = 2.0
SPT = 0.2
CFLAGS = -fPIC -DSYSTEM=OPUNIX -O2
# -nostartfiles -lc --entry main
SPOOKY = -L./lib/spookyhash/build/bin/Release -l:libspookyhash.a
AUX = build/stplugin.o
OUT = build/gtools.plugin  build/gtools.o
OUTM = build/gtools_multi.plugin build/gtools_multi.o

all: clean links gtools

links:
	ln -sf ../../lib 	  src/plugin/lib
	ln -sf lib/spt-$(SPT) src/plugin/spt
	ln -sf lib/spi-$(SPI) src/plugin/spi
	ln -sf lib/spookyhash src/plugin/spookyhash

gtools: src/plugin/gtools.c src/plugin/spi/stplugin.c
	mkdir -p build
	gcc -Wall $(CFLAGS) -shared -c -o build/stplugin.o      src/plugin/spi/stplugin.c
	gcc -Wall $(CFLAGS) -shared -c -o build/gtools.o        src/plugin/gtools.c
	gcc -Wall $(CFLAGS) -shared -c -o build/gtools_multi.o  src/plugin/gtools.c -fopenmp -DGMULTI=1
	gcc -Wall $(CFLAGS) -shared    -o $(OUT)  $(AUX) $(SPOOKY)
	gcc -Wall $(CFLAGS) -shared    -o $(OUTM) $(AUX) $(SPOOKY) -fopenmp

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTM) $(AUX)
