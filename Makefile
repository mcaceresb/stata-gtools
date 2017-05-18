SPI = 2.0
SPT = 0.2
CFLAGS = -fPIC -DSYSTEM=OPUNIX -O3 -fopenmp
# -nostartfiles -lc --entry main
SPOOKY = -L./lib/spookyhash/build/bin/Release -l:libspookyhash.a
OUT = build/gcollapse.plugin build/stplugin.o build/gcollapse.o

all: clean links gcollapse

links:
	ln -srf lib/spt-$(SPT) src/plugin/spt
	ln -srf lib/spi-$(SPI) src/plugin/spi
	ln -srf lib/spookyhash src/plugin/spookyhash

gcollapse: src/plugin/gcollapse.c src/plugin/spi/stplugin.c
	mkdir -p build
	gcc -Wall $(CFLAGS) -shared -c -o build/stplugin.o  src/plugin/spi/stplugin.c
	gcc -Wall $(CFLAGS) -shared -c -o build/gcollapse.o src/plugin/gcollapse.c
	gcc -Wall $(CFLAGS) -shared    -o $(OUT) $(SPOOKY)

.PHONY: clean
clean:
	rm -f $(OUT)
