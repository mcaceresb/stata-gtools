GCC = gcc
FLAGS = -Wall -shared -fPIC -DSYSTEM=OPUNIX
SPOOKY = -L./ -l:libspookyhash.a

all: clean test1 test2

test1: test1.c stplugin.c
	$(GCC) $(FLAGS) -o test1.plugin stplugin.c test1.c

test2: test2.c stplugin.c
	$(GCC) $(FLAGS) -o test2.plugin stplugin.c test2.c $(SPOOKY)

.PHONY: clean
clean:
	rm -f test1.plugin
	rm -f test2.plugin
