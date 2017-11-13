Compiling
=========

Compiling the plugin yourself is advised if you are on Linux or OSX and you
wish to speed up gtools. I ran the Stata/MP benchmarks on a server that used
the plugin I compiled locally. This was because most people will have that
experience (i.e. they will not compile the plugin themselves).

However, if I compile the plugin on the server then gtools can be up to 2
times faster. This is because the optimization flags of the compiler perform
different optimizations in different hardware.

### Requirements

If you want to compile the plugin yourself, you will, at a minimum, need

- The GNU Compiler Collection (`gcc`)
- `git`

The plugin additionally requires:

- v2.0 or above of the [Stata Plugin Interface](https://stata.com/plugins/version2) (SPI).
- [`premake5`](https://premake.github.io)
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)

However, I keep a copy of Stata's Plugin Interface in this repository, and I
have added `centaurean`'s implementation of SpookyHash as a submodule.  Hence
as long as you have `gcc`, `make`, and `git`, you fill be able to compile the
plugin following the instructions below.  

On OSX, you can get `gcc` and `make` from xcode. On windows, you will need

- [Cygwin](https://cygwin.com) with `gcc`, `make`, `x86_64-w64-mingw32-gcc-5.4.0.exe`
  (Cygwin is pretty massive by default; I would install only those packages).

If you also want to compile SpookyHash on Windows yourself, you will also need

- [Microsoft Visual Studio](https://www.visualstudio.com) with the
  Visual Studio Developer Command Prompt (again, this is pretty massive
  so I would recommend you install the least you can to get the
  Developer Prompt).

I keep a copy of `spookyhash.dll` in `./lib/windows` so there is no need to
re-compile SpookyHash. In fact, I would advise **against** trying to recompile
SpookyHash on Windows.

### Compilation

Note that lines 37-40 in `lib/spookyhash/build/premake5.lua` cause the build
to fail on some systems, so we delete them (they are meant to check the git
executable exists).

```bash
bash

git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --init --recursive
make clean
sed -i.bak -e '37,40d' lib/spookyhash/build/premake5.lua
```

If you are on Windows, of if `premake5` is installed and in your system's
`PATH`, run

```bash
make spooky
```

If you are Linux and OSX and you don't know how to install `premake5`, run

```bash
cd lib/spookyhash/build

url=https://github.com/premake/premake-core/releases/download
version=5.0.0.alpha4

# Linux
curl -OL ${url}/v${version}/premake-${version}-linux.tar.gz
tar zxvf premake-${version}-linux.tar.gz

# OSX
curl -OL ${url}/v${version}/premake-${version}-macosx.tar.gz
tar zxvf premake-${version}-macosx.tar.gz

# Make spookyhash
./premake5 gmake
make clean
ALL_CFLAGS+=-fPIC make

cd -
```

To finish, compile the plugin

```bash
make SPOOKYPATH=$(dirname `find ./lib/spookyhash/ -name "*libspookyhash.a"`)
```

### Unit tests

From a stata session, run
```stata
do build/gtools_tests.do
```

If successful, all tests should report to be passing and the exit message
should be "tests finished running" followed by the start and end time.

### Troubleshooting

I test the builds using Travis and Appveyor; if both builds are passing
and you can't get them to compile, it is likely because you have not
installed all the requisite dependencies. For Cygwin in particular, see
`./src/plugin/gtools.h` for all the include statements and check if you have
any missing libraries.

Loading the plugin is a bit trickier. Historically, the plugin has failed on
some windows systems and some legacy Linux systems. The Linux issue is largely
due to versioning. That is, while the functions I use should be available on
most systems, the package versions are too recent for some systems. If this
happens please submit a bug report.

On Windows the issue is largely due to Stata not being able to find the
SpookyHash library, `spookyhash.dll` (Stata does not look in the ado path by
default, just the current directory and the system path). I keep a copy in
`./lib/windows` but the user can also run

```
gtools, dependencies
```

If that does not do the trick, run

```
gtools, dll
```

before calling a gtools command (should only be required once per
script/interactive session). Alternatively, you can keep `spookyhash.dll` in
the working directory or run your commands with `hashlib()`. For example,

```
gcollapse (sum) varlist, by(varlist) hashlib(C:\path\to\spookyhash.dll)
```

Other than that, as best I can tell, all will be fine as long as you use the
MinGW version of gcc and SpookyHash was built using visual studio. That is,

- `x86_64-w64-mingw32-gcc` instead of `gcc` in cygwin for the plugin,
- `premake5 vs2013`, and
- `msbuild SpookyHash.sln` for SpookyHash

Again, you can find the dll pre-built in `./lib/windows/spookyhash.dll`,
but if you are set on re-compiling SpookyHash, you have to force `premake5`
to generate project files for a 64-bit version only (otherwise `gcc` will
complain about compatibility issues). Further, the target folder has not
always been consistent in testing. While this may be due to an error on my
part, I have found the compiled `spookyhash.dll` in

- `./lib/spookyhash/build/bin`
- `./lib/spookyhash/build/bin/x86_64/Release`
- `./lib/spookyhash/build/bin/Release`

Again, I advise against trying to re-compile SpookyHash on Windows. Just use
the dll provided in this repo.

