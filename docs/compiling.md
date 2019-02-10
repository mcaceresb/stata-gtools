Compiling
=========

Compiling the plugin yourself can lead to further speed improvements
because the optimization flags used by different compilers vary on
different hardware and operating systems.  However, this is only
recommended on Linux and OSX systems, where compiling is relatively
easy.  In the Linux server where I use Stata, a locally compiled plugin
ran 20-50% faster.

While compiling the plugin locally might also help with troubleshooting
if the plugin failed to load, this scenario should be very rare.  Most
systems should load the pre-compiled plugin; if yours doesn't, please
file a bug report.

### Requirements

!!! tip "Pro-tip"
    Install the newest version of `gcc` to get the most out of compiling
    the plugin locally.

You will, at a minimum, need

- `git`
- The GNU Compiler Collection (`gcc`)

The current version of gtools was compiled using `gcc` versions 8
(Linux), 7 (OSX), and 5 (Windows). The plugin additionally requires:

- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2) (Stata 13 and earlier).
- v3.0 of the [Stata Plugin Interface](https://stata.com/plugins) (Stata 14 and later).
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

# Stata 14.0 and earlier
make clean SPI=2.0 SPIVER=v2
make all   SPI=2.0 SPIVER=v2

# Stata 14.1 and later
make clean SPI=3.0 SPIVER=v3
make all   SPI=3.0 SPIVER=v3
```

### Unit tests

From a stata session, run
```stata
do build/gtools_tests.do
```

(Note this can take several hours.)  If successful, all tests should
report to be passing and the exit message should be "tests finished
running" followed by the start and end time.

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
