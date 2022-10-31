EXECUTION=normal
LEGACY=
STATA = ${HOME}/.local/stata13/stata -b

# ---------------------------------------------------------------------
# Editing/debugging

## Open current meta for working
open:
	konsole -e nvim -S ~/.vim/session/gtools &
	konsole --new-tab --workdir /home/mauricio/todo/now/stata-gtools &
	dolphin --split ~/todo/now/stata-gtools \
					~/todo/now/stata-gtools/src &

# bug  xx replace does not empty out variables; problem with ifin
# doc  xx add resid[(str)] option to docs
# doc  xx what was absorb(, save(str)) meant to do?
# test xx src/test/test_gregress.do
# doc  xx docs/usage/gpoisson.md    (consolidate)
# doc  xx docs/stata/gpoisson.sthlp (consolidate)
# ex   xx docs/examples/glogit.do
# bug  xx detect collinearity with dep var in glm

# Update!
# -------
#
# ./lib/bumpver.py
# ./README.md
# ./docs/index.md
# ./docs/stata/gtools.sthlp
# ./src/ado/gtools.ado
# ./src/ado/_gtools_internal.ado
# ./src/plugin/gtools.h
# x ./src/plugin/gtools.c
# x ./src/test/gtools_tests.do
# ./src/gtools.pkg
# ./src/stata.toc
# ./.appveyor.yml
# x ./build.py
# x ./changelog.md

# Add a group stat
# ----------------
#
# ./README.md L318
# ./docs/index.md L308
# ./changelog.md note in new version which stats
#     gcollapse
#     gegen
#     gstats tab
#
# ./docs/usage/gcollapse.md L29
# ./docs/usage/gegen.md L194
# ./docs/usage/gstats_summarize.md L26
# ./docs/usage/gstats_transform.md L34
# ./docs/stata/gcollapse.sthlp L50
# ./docs/stata/gegen.sthlp L223
# ./docs/stata/gstats_summarize.sthlp L278
# ./docs/stata/gstats_transform.sthlp L55
#
# ./src/ado/_gtools_internal.ado L2496, L3395, L3545, L3660, L3915, L4200, L5060, L5420, L5690, L5800, L5900
# ./src/ado/_gtools_internal.mata L1252, L1311
# ./src/ado/gcollapse.ado L1106, L1743, L1845, L1932
# ./src/ado/gegen.ado L63, L81, L820
#
# ./src/plugin/collapse/gtools_math.c
# ./src/plugin/collapse/gtools_math.h
# ./src/plugin/collapse/gtools_math_unw.c
# ./src/plugin/collapse/gtools_math_unw.h
# ./src/plugin/collapse/gtools_math_w.c
# ./src/plugin/collapse/gtools_math_w.h

# ./src/ado/_gtools_internal.ado gstats_hdfe fun
	# ./src/plugin/gtools.c
	# ./src/plugin/gtools.h
    # gstats_scalars   init
    # if ( inlist("`gfunction'",  "stats") ) {
# ./src/ado/gstats.ado gstats_hdfe fun
# ./docs/stata/gstats_hdfe.sthlp
# ./docs/usage/gstats_hdfe.md

# Add to gstats
# -------------
#
# ./src/ado/gstats.ado L27
# ./src/ado/_gtools_internal.ado L2470, L3685
# ./src/ado/_gtools_internal.ado L3795 add program gstats_<newfunc>

# ---------------------------------------------------------------------
# Gtools flags

SPIVER = v2
SPI = 2.0
GTOOLSOMP? = 0
ifeq ($(GTOOLSOMP),1)
	CFLAGS = -Wall -O3 $(OSFLAGS) -DGTOOLSOMP=1 -fopenmp
else
	CFLAGS = -Wall -O3 $(OSFLAGS)
endif

# ---------------------------------------------------------------------
# OS parsing

ifeq ($(OS),Windows_NT)
	OSFLAGS = -shared -fPIC
	GCC = x86_64-w64-mingw32-gcc.exe
	OUT = build/gtools_windows$(LEGACY)_$(SPIVER).plugin
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		GCC = gcc
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
		OUT = build/gtools_unix$(LEGACY)_$(SPIVER).plugin
	endif
	ifeq ($(UNAME_S),Darwin)
		GCC = clang
		OSFLAGS = -bundle -DSYSTEM=APPLEMAC
		OUT = build/gtools_macosx$(LEGACY)_$(SPIVER).plugin
	endif
endif

ifeq ($(EXECUTION),windows)
	OSFLAGS = -shared
	GCC = x86_64-w64-mingw32-gcc
	OUT = build/gtools_windows$(LEGACY)_$(SPIVER).plugin
endif

# ---------------------------------------------------------------------
# Main

## Compile directory
all: clean links gtools
osx: clean links osx_combine

## Initialize git and pull sub-modules
git:
	git init
	git submodule add https://github.com/centaurean/spookyhash lib/spookyhash
	git submodule update --init --recursive
	cd lib/spookyhash && git checkout spookyhash-1.0.6 && cd -

## Download latest OSX plugin
osx_plugins:
	wget https://raw.githubusercontent.com/mcaceresb/stata-gtools/osx/build/gtools_macosx_v3.plugin
	wget https://raw.githubusercontent.com/mcaceresb/stata-gtools/osx/build/gtools_macosx_v2.plugin
	cp -f gtools_macosx_v3.plugin  build/gtools_macosx_v3.plugin
	cp -f gtools_macosx_v2.plugin  build/gtools_macosx_v2.plugin
	mv -f gtools_macosx_v3.plugin  lib/plugin/gtools_macosx_v3.plugin
	mv -f gtools_macosx_v2.plugin  lib/plugin/gtools_macosx_v2.plugin

## Install the Stata package (replace if necessary)
replace:
	cd build/ && $(STATA) "cap noi net uninstall gtools"
	cd build/ && $(STATA) "net install gtools, from(\`\"${PWD}/build\"')"

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

SPOOKYHASH_SRC=lib/spookyhash/src/context.c \
	lib/spookyhash/src/globals.c \
	lib/spookyhash/src/spookyhash.c

SPOOKYHASH_INC=-Ilib/spookyhash/src

## Build gtools plugin
gtools: $(GTOOLS_SRC) $(SPOOKYHASH_SRC)
	mkdir -p ./build
	$(GCC) $(CFLAGS) -o $(OUT) $(SPOOKYHASH_INC) $^
	cp build/*plugin lib/plugin/

## Build OSX-specific plugins
osx_combine: $(GTOOLS_SRC) $(SPOOKYHASH_SRC)
	mkdir -p ./build
	$(GCC) $(CFLAGS) -arch arm64  -o $(OUT).arm64  $(SPOOKYHASH_INC) $^
	$(GCC) $(CFLAGS) -arch x86_64 -o $(OUT).x86_64 $(SPOOKYHASH_INC) $^
	lipo -create -output $(OUT) $(OUT).x86_64 $(OUT).arm64
	cp build/*plugin lib/plugin/

.PHONY: clean
clean:
	rm -f $(OUT)*

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
