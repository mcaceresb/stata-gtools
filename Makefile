SPI = 2.0
SPT = 0.2
CFLAGS = -fPIC -DSYSTEM=OPUNIX -O3 -fopenmp
# -nostartfiles -lc --entry main
SPOOKY = -L./lib/spookyhash/build/bin/Release -l:libspookyhash.a
OUT = build/gtools.plugin build/stplugin.o build/gtools.o

all: clean links gtools

links:
	ln -srf lib/spt-$(SPT) src/plugin/spt
	ln -srf lib/spi-$(SPI) src/plugin/spi
	ln -srf lib/spookyhash src/plugin/spookyhash

gtools: src/plugin/gtools.c src/plugin/spi/stplugin.c
	mkdir -p build
	gcc -Wall $(CFLAGS) -shared -c -o build/stplugin.o  src/plugin/spi/stplugin.c
	gcc -Wall $(CFLAGS) -shared -c -o build/gtools.o    src/plugin/gtools.c
	gcc -Wall $(CFLAGS) -shared    -o $(OUT) $(SPOOKY)

.PHONY: clean
clean:
	rm -f $(OUT)
