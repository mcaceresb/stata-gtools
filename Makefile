SPI = 2.0
SPT = 0.2
CFLAGS = -fPIC -DSYSTEM=OPUNIX -fopenmp -O3
GSLLIB = /usr/local/lib
GSL = -L$(GSLLIB) -l:libgsl.a
GLIB = `pkg-config --cflags --libs glib-2.0`
SPOOKY = -L./lib/spookyhash/build/bin/Release -l:libspookyhash.a
SPT_C = lib/spt-$(SPT)/st_gentools.c lib/spt-$(SPT)/st_gsltools.c
SPT_H = lib/spt-$(SPT)/st_gentools.h lib/spt-$(SPT)/st_gsltools.h
ST_C = lib/spi-$(SPI)/stplugin.c
ST_H = lib/spi-$(SPI)/stplugin.h
OUT = build/gtools.plugin build/stplugin.o build/gtools.o

all: clean links spooky gtools

links: $(SPT_C)
	$(foreach sptc,$(SPT_C), ln -srf $(sptc) src/;)
	$(foreach spth,$(SPT_H), ln -srf $(spth) src/;)
	ln -srf $(ST_C) src/stplugin.c
	ln -srf $(ST_H) src/stplugin.h

spooky:
	ln -srf lib/spookyhash src/spookyhash

gtools: src/gtools.c src/stplugin.c src/gtools.c
	mkdir -p build
	gcc -Wall $(CFLAGS) -shared -c  -o build/stplugin.o src/stplugin.c
	gcc -Wall $(CFLAGS) -shared -c  -o build/gtools.o   src/gtools.c $(GLIB) $(SPOOKY)
	gcc -Wall $(CFLAGS) -shared -lm -o $(OUT) $(GSL) $(GLIB) $(SPOOKY)

.PHONY: clean
clean:
	rm -f $(OUT)
