OSFLAGS = -shared
GCC = x86_64-w64-mingw32-gcc.exe

TEST1_SRC=stplugin.c test1.c

TEST2_SRC=stplugin.c test2.c

SPOOKYHASH_SRC=lib/spookyhash/src/context.c \
	lib/spookyhash/src/globals.c \
	lib/spookyhash/src/spookyhash.c

SPOOKYHASH_INC=-Ilib/spookyhash/src

all: clean test1 test2

test1: $(TEST1_SRC)
	$(GCC) $(OSFLAGS) -o test1.plugin $^

test2: $(TEST2_SRC) $(SPOOKYHASH_SRC)
	$(GCC) $(OSFLAGS) -o test2.plugin $(SPOOKYHASH_INC) $^

.PHONY: clean
clean:
	rm -f test1.plugin
	rm -f test2.plugin
