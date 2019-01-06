EXECUTION=normal
LEGACY=

# ---------------------------------------------------------------------
# Editing/debugging

## Open current meta for working
open:
	konsole -e nvim -S ~/.vim/session/gtools &
	konsole --new-tab --workdir /home/mauricio/todo/now/stata-gtools &
	dolphin --split ~/todo/now/stata-gtools \
					~/todo/now/stata-gtools/src &

# Update!
# -------
#
# ./README.md
# ./docs/index.md
# ./docs/stata/gtools.sthlp
# ./src/ado/gtools.ado
# ./src/ado/_gtools_internal.ado
# ./src/plugin/gtools.c
# ./src/test/gtools_tests.do
# ./src/gtools.pkg
# ./src/stata.toc
# ./.appveyor.yml
# ./.travis.yml
# ./build.py

# ---------------------------------------------------------------------
# Gtools flags

SPI = 2.0
SPIVER = v2
CFLAGS = -Wall -O3 $(OSFLAGS)
OPENMP = -fopenmp -DGMULTI=1
PTHREADS = -lpthread -DGMULTI=1

# ---------------------------------------------------------------------
# OS parsing

ifeq ($(OS),Windows_NT)
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc.exe
	OUT = build/gtools_windows$(LEGACY)_$(SPIVER).plugin
	OUTM = build/gtools_windows_multi$(LEGACY)_$(SPIVER).plugin
	OUTE = build/env_set_windows$(LEGACY)_$(SPIVER).plugin
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
		OUT = build/gtools_unix$(LEGACY)_$(SPIVER).plugin
		OUTM = build/gtools_unix_multi$(LEGACY)_$(SPIVER).plugin
		OUTE = build/env_set_unix$(LEGACY)_$(SPIVER).plugin
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAGS = -bundle -DSYSTEM=APPLEMAC
		OUT = build/gtools_macosx$(LEGACY)_$(SPIVER).plugin
		OUTM = build/gtools_macosx_multi$(LEGACY)_$(SPIVER).plugin
		OUTE = build/env_set_macosx$(LEGACY)_$(SPIVER).plugin
	endif
	GCC = gcc
endif

ifeq ($(EXECUTION),windows)
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc
	OUT = build/gtools_windows$(LEGACY)_$(SPIVER).plugin
	OUTE = build/env_set_windows$(LEGACY)_$(SPIVER).plugin
endif

# ---------------------------------------------------------------------
# Main

## Compile directory
all: clean links gtools gtools_e

## Initialize git and pull sub-modules
git:
	git init
	git submodule add https://github.com/centaurean/spookyhash lib/spookyhash
	git submodule update --init --recursive
	cd lib/spookyhash && git checkout spookyhash-1.0.6 && cd -

## Download latest OSX plugin
osx_plugins:
	wget https://raw.githubusercontent.com/mcaceresb/stata-gtools/osx/build/env_set_macosx_v2.plugin
	wget https://raw.githubusercontent.com/mcaceresb/stata-gtools/osx/build/env_set_macosx_v3.plugin
	wget https://raw.githubusercontent.com/mcaceresb/stata-gtools/osx/build/gtools_macosx_v3.plugin
	wget https://raw.githubusercontent.com/mcaceresb/stata-gtools/osx/build/gtools_macosx_v2.plugin
	cp -f env_set_macosx_v2.plugin build/env_set_macosx_v2.plugin
	cp -f env_set_macosx_v3.plugin build/env_set_macosx_v3.plugin
	cp -f gtools_macosx_v3.plugin  build/gtools_macosx_v3.plugin
	cp -f gtools_macosx_v2.plugin  build/gtools_macosx_v2.plugin
	mv -f env_set_macosx_v2.plugin lib/plugin/env_set_macosx_v2.plugin
	mv -f env_set_macosx_v3.plugin lib/plugin/env_set_macosx_v3.plugin
	mv -f gtools_macosx_v3.plugin  lib/plugin/gtools_macosx_v3.plugin
	mv -f gtools_macosx_v2.plugin  lib/plugin/gtools_macosx_v2.plugin

# ---------------------------------------------------------------------
# Rules

## Build gtools library links
links:
	rm -f  src/plugin/lib
	rm -f  src/plugin/spi
	ln -sf ../../lib 	  src/plugin/lib
	ln -sf lib/spi-$(SPI) src/plugin/spi

GTOOLS_SRC=src/plugin/gtools.c \
	src/plugin/spi/stplugin.c

GTOOLS_E_SRC=src/plugin/spi/stplugin.c \
	src/plugin/env_set.c

SPOOKYHASH_SRC=lib/spookyhash/src/context.c \
	lib/spookyhash/src/globals.c \
	lib/spookyhash/src/spookyhash.c

SPOOKYHASH_INC=-Ilib/spookyhash/src

## Build gtools plugin
gtools: $(GTOOLS_SRC) $(SPOOKYHASH_SRC)
	mkdir -p ./build
	$(GCC) $(CFLAGS) -o $(OUT) $(SPOOKYHASH_INC) $^
	cp build/*plugin lib/plugin/

## Build environment switch
gtools_e: $(GTOOLS_E_SRC)
	mkdir -p ./build
	$(GCC) $(CFLAGS) -o $(OUTE) $^
	cp build/*plugin lib/plugin/


.PHONY: clean
clean:
	rm -f $(OUT) $(OUTE)

#######################################################################
#                                                                     #
#                    Self-Documenting Foo (Ignore)                    #
#                                                                     #
#######################################################################

.DEFAULT_GOAL := show-help

.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
