Compiling
=========

`gtools` uses compiled C code internally to achieve its speed
improvements.  While the package comes with pre-compiled binaries,
compiling the plugin yourself may be necessary on some platforms.
Further, some support for parallel processing can be implemented at
compile time if the OpenMP library is available in your system. See
[below](parallel-support) for a list of functions with OpenMP support at
compile time. (Parallel execution has not been optimized; YMMV.)

Compiling the plugin yourself can lead to further speed improvements
because the optimization flags used by different compilers vary on
different hardware and operating systems.  In the Linux server where I
use Stata, a locally compiled plugin ran 20-50% faster (again, YMMV).

### Requirements

!!! tip "Pro-tip"
    Install the newest version of `gcc` to get the most out of compiling
    the plugin locally.

The requirements are slightly different from system to system:

- Linux: `git`, `make`, `gcc` (available from your distribution's repository).
- OSX: `git`, `make`, `clang` (available via brew or xcode).
- Windows: `git` and [Cygwin](https://cygwin.com) with `make`, `binutils`, `gcc-core`, `mingw64-x86_64-gcc-core` (you will have the option to select these packages during the Cygwin installation).

The following are also required, but copies are provided in the repository:

- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2) (Stata 13 and earlier).
- v3.0 of the [Stata Plugin Interface](https://stata.com/plugins) (Stata 14 and later).
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)

### Compiling

On Linux and OSX, open any terminal; on Windows, open specifically the
Cygwin terminal. Then run

```bash
git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --init --recursive

# Stata 14.1 and later
make clean SPI=3.0 SPIVER=v3
make all   SPI=3.0 SPIVER=v3

# Parallel support
make clean SPI=3.0 SPIVER=v3
make all   SPI=3.0 SPIVER=v3 GTOOLSOMP=1

# Stata 14.0 and earlier
make clean SPI=2.0 SPIVER=v2
make all   SPI=2.0 SPIVER=v2
```

### Parallel Support

Portions of these functions internals are executed in parallel if you
compile `gtools` with OpenMP support (GTOOLSOMP flag):

- `gstats hdfe`
- `gregress`
- `givregress`
- `gglm`

### Unit tests

From a stata session, run
```stata
do build/gtools_tests.do
```

(Note this can take several hours.)  If successful, all tests should
report to be passing and the exit message should be "tests finished
running" followed by the start and end time.

### Troubleshooting

I test the builds using Github Workflows and Appveyor; if both builds
are passing and you can't get them to compile, it is likely because
you have not installed all the requisite dependencies. For Cygwin in
particular, see `./src/plugin/gtools.h` for all the include statements
and check if you have any missing libraries.

Loading the plugin is a bit trickier. Historically, the plugin has
failed on some windows systems and some legacy Linux systems.  If this
happens please submit a bug report. The Linux issue is largely due to
versioning. That is, while the functions I use should be available on
most systems, the package versions are too recent for some systems.

Other than that, as best I can tell, all will be fine as long as you use
the MinGW version of gcc. That is, `x86_64-w64-mingw32-gcc` instead of
`gcc` in cygwin for the plugin.
