Compiling
=========

!!! info "Note"
    Compiling the plugin is only advised for advanced users.

Compiling the plugin yourself might lead to a further speed improvement
because the optimization flags used by different compilers vary on
different hardware and opetaring systems. This is only recommended on
Linux and OSX, where compiling the plugin is relatively easy (specially
if you are able to access a version of `gcc`).

Compiling the plugin locally might also help with troubleshooting if the
plugin failed to load. This should be very rare, however: Most systems
should be able to load the pre-compiled plugin.

### Requirements

If you want to compile the plugin yourself, you will, at a minimum, need

- The GNU Compiler Collection (`gcc`)
- `git`

The plugin additionally requires:

- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2) (Stata 13 and earlier).
- v3.0 of the [Stata Plugin Interface](https://stata.com/plugins) (Stata 14 and later).
- [`premake5`](https://premake.github.io)
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)

However, I keep a copy of Stata's Plugin Interface in this repository, and I
have added `centaurean`'s implementation of SpookyHash as a submodule.  Hence
as long as you have `gcc`, `make`, and `git`, you fill be able to compile the
plugin following the instructions below.

On OSX, you can get `gcc` and `make` from xcode. On windows, you will need

- [Cygwin](https://cygwin.com) with `gcc`, `make`, `x86_64-w64-mingw32-gcc-5.4.0.exe`
  (Cygwin is pretty massive by default; I would install only those packages).

### Compilation

```bash
git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --init --recursive

# Stata 13 and earlier
make clean SPI=2.0 SPIVER=v2
make all   SPI=2.0 SPIVER=v2

# Stata 14 and later
make clean SPI=3.0 SPIVER=v3
make all   SPI=3.0 SPIVER=v3
```

### Unit tests

From a stata session, run
```stata
do build/gtools_tests.do
```

(Note this can take several hours.)  If successful, all tests should report to
be passing and the exit message should be "tests finished running" followed by
the start and end time.

### Troubleshooting

I test the builds using Travis and Appveyor; if both builds are passing
and you can't get them to compile, it is likely because you have not
installed all the requisite dependencies. For Cygwin in particular, see
`./src/plugin/gtools.h` for all the include statements and check if you
have any missing libraries.

Loading the plugin is a bit trickier. Historically, the plugin has
failed on some windows systems and some legacy Linux systems.  If this
happens please submit a bug report. The Linux issue is largely due to
versioning. That is, while the functions I use should be available on
most systems, the package versions are too recent for some systems.

Other than that, as best I can tell, all will be fine as long as you use
the MinGW version of gcc. That is, `x86_64-w64-mingw32-gcc` instead of
`gcc` in cygwin for the plugin.
