<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

[Overview](#faster-stata-for-group-operations)
| [Installation](#installation)
| [Benchmarks](#collapse-benchmarks)
| [Building](#building)
| [FAQs](#faqs)
| [License](#license)

_Gtools_ is a Stata package that provides a fast implementation of common
group commands like collapse, egen, isid, and levelsof using C plugins for a
massive speed improvement.

`version 0.7.4 29Sep2017`
Builds: Linux [![Travis Build Status](https://travis-ci.org/mcaceresb/stata-gtools.svg?branch=develop)](https://travis-ci.org/mcaceresb/stata-gtools),
Windows (Cygwin) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/2bh1q9bulx3pl81p/branch/develop?svg=true)](https://ci.appveyor.com/project/mcaceresb/stata-gtools)

Faster Stata for Group Operations
---------------------------------

This package's aim is to provide a fast implementation of group commands in
Stata using C plugins. This includes:

| Function    | Replaces        | Extras               | Unsupported                               |
| ----------- | --------------- | -------------------- | ----------------------------------------- |
| `gcollapse` | `collapse`      | Quantiles, `merge`   | Weights                                   |
| `gegen`     | `egen`          | Quantiles            | See [FAQs](#faqs) for available functions |
| `hashsort`  | `sort`, `gsort` | Group (hash) sorting | `mfirst`, `gen`                           |
| `gisid`     | `isid`          | `if`, `in`           | `using`, `sort`                           |
| `glevelsof` | `levelsof`      | Multiple variables   |                                           |

The key insight is two-fold: First, hashing the data and sorting the hash is
a lot faster than sorting the data before processing it by group. Second,
compiled C code is much faster than Stata commands. This insight is used
in all `gtools` functions to achieve their speedup.

The package's main feature is a faster implementation of `collapse`, called
`gcollapse`, that is also faster than Sergio Correia's `fcollapse` from
`ftools` (further, group variables can be a mix of string and numeric,
like `collapse`). In our benchmarks, `gcollapse` was 5 to 120 times faster
than `collapse` and 3 to 20 times faster than `fcollapse` (the speed gain
is smaller for simpler statistics, such as sums, and larger for complex
statistics, such as percentiles).

The current release only provides Unix (Linux) and Windows versions of the C
plugin. Further, multi-threading is only available on Linux. OSX versions and
a muilti-threaded Windows version are planned for a future release.
 
If you plan to use the plugin extensively, check out the [FAQs](#faqs) for
caveats and details on the plugin.

Installation
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
```stata
net install gtools, from(https://raw.githubusercontent.com/mcaceresb/stata-gtools/develop/build/)
* adoupdate, update
* ado uninstall gtools
```

The syntax is generally analogous to the standard commands (see the corresponding
help files for full syntax and options):
```stata
gcollapse (stat) target = source [(stat) target = source ...], by(varlist) [options]
gcollapse (mean) mean_x1 = x1 (median) median_x1 = x1, by(groupvar) [options]

gegen target  = stat(source), by(varlist) [options]
gegen mean_x1 = mean(x1), by(groupvar)

hashsort varlist, [options]
hashsort -groupvar, benchmark

gisid varlist [if] [in], [options]
gisid groupvar, missok

glevelsof varlist [if] [in], [options]
glevelsof groupvar, local(levels) sep(" | ")
```

Support for weights for `gcollapse` and `gegen` planned for a future
release. See the [FAQs](#faqs) for a list of supported functions.

Hash sort benchmarks
--------------------

We create a data set of `10,000` observations and extend it to a million
(`1,000,000`). So there are at least 100 groups for any given sorting
arrangement. Variables are self-descriptive, so "str_32" is a string variable
with 32 characters. "double2" is a double. And so on.

String variables were concatenated from a mix of fixed and random strings
using the `ralpha` package. Benchmarks were performed on a personal laptop
running Linux:

    Program:   Stata/IC 13.1 (1 core)
    OS:        x86_64 GNU/Linux
    Processor: Intel(R) Core(TM) i7-6500U CPU @ 2.50GHz
    Cores:     2 cores with 2 virtual threads per core.
    Memory:    15.6GiB
    Swap:      15.6GiB

### Versus `sort`

    | sort | hashsort | ratio (s/q) | sorted by (stable)                                         |
    | ---- | -------- | ----------- | ---------------------------------------------------------- |
    | 1.58 |    .603  | 2.62        | str_12                                                     |
    | 1.72 |    1.00  | 1.72        | str_12 str_32                                              |
    | 1.8  |    .992  | 1.81        | str_12 str_32 str_4                                        |
    | 1.54 |    .785  | 1.96        | double1                                                    |
    | 1.54 |    .779  | 1.98        | double1 double2                                            |
    | 1.84 |    .844  | 2.18        | double1 double2 double3                                    |
    | 1.32 |    .552  | 2.39        | int1                                                       |
    | 1.64 |    .591  | 2.77        | int1 int2                                                  |
    | 1.67 |    .762  | 2.19        | int1 int2 int3                                             |
    | 1.87 |    .898  | 2.08        | int1 str_32 double1                                        |
    | 2.25 |    .977  | 2.3         | int1 str_32 double1 int2 str_12 double2                    |
    | 2.49 |    1.16  | 2.15        | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

### Versus `gsort`

    | gsort | hashsort | ratio (g/h) | sorted by (stable)                                             |
    | ----- | -------- | ----------- | ----------------------------------------------------------     |
    |  6.43 |    .813  | 7.91        | -str_12                                                        |
    |  6.02 |    .75   | 8.03        | str_12 -str_32                                                 |
    |  8.48 |    1.04  | 8.15        | str_12 -str_32 str_4                                           |
    |  6.8  |    .771  | 8.82        | -double1                                                       |
    |  7.29 |    .915  | 7.97        | double1 -double2                                               |
    |  9.73 |    .735  | 13.2        | double1 -double2 double3                                       |
    |  6.53 |    .619  | 10.5        | -int1                                                          |
    |  6.55 |    .654  | 10          | int1 -int2                                                     |
    |  5.96 |    .479  | 12.4        | int1 -int2 int3                                                |
    |  9.79 |    .878  | 11.2        | -int1 -str_32 -double1                                         |
    |  15.5 |    .999  | 15.5        | int1 -str_32 double1 -int2 str_12 -double2                     |
    |  19.5 |    .979  | 19.9        | int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3 |

### Versus `sort` (alt)

We can see hashsort was slowest when sorting by a large number of mixed
variables.  Consider the same data set as above, but expanded from 100, 1,000,
and 500,000 to 1M, sorted by `int1 str_32 double1 int2 str_12 double2 int3 str_4 double3`

    | sort | hashsort | ratio (s/h) | Type           |
    | ---- | -------- | ----------- | -------------- |
    | 3.67 |    .976  | 3.76        | 100 -> 1M      |
    | 2.6  |    1.03  | 2.52        | 1,000 -> 1M    |
    | 1.55 |    1.75  | 0.886       | 500,000 -> 1M  |

We can see that the speed gain is larger for fewer groups, even with many variables, but
that if there are many groups you are better served using `sort`. The same is not true
for gsort, since `hashsort` should perform faster regardless of the setting. Repeating
the above benchmarks gives:

    | gsort | hashsort | ratio (g/h) | Type           |
    | ----- | -------- | ----------- | -------------- |
    |  13.9 |    1.12  | 12.4        | 100 -> 1M      |
    |  15.2 |    1.02  | 14.9        | 1,000 -> 1M    |
    |  20.7 |    1.98  | 10.5        | 500,000 -> 1M  |

Collapse benchmarks
-------------------

See `src/test/bench_gcollapse.do` for the benchmark code. I run 3 sets of benchmarks:
- `ftools`-style benchmarks: Collapse a large number of observations
  to 100 groups. This sums 15 variables, take the mean and median of 3
  variables, and take the mean, sum, count, min, and max of 6 variables.

- Increasing group size: This fixes the sample size at 50M and increase
  the group size from 10 to 10M in geometric succession and computes
  all available stats (and 2 sample percentiles) for 2 variables.

- Increasing sample size: This fixes the group size at 10 and increase
  the sample size from 2M to 200M in geometric succession and computes
  all available stats (and 2 sample percentiles) for 2 variables.

All benchmarks were done on a server with the following specifications:

    Program:   Stata/MP 14.2 (8 cores)
    OS:        x86_64 GNU/Linux
    Processor: Intel(R) Xeon(R) CPU E5-2643 0 @ 3.30GHz
    Cores:     2 quad-core sockets (8 cores).
    Memory:    378GiB
    Swap:      372GiB

Alternatively, I made Stata/IC benchmarks available (since I only have
IC on my personal computer) in `./src/test/bench_ic_fcoll.log`; the
speed gains in IC are markedly higher than those below. Note I have not
yet benchmarked this version of `gcollapse` against `collapse` for 200M
observations. This is because `collapse` takes several hours in that
case, and I have not found occasion to run them.

All commands were run with the `fast` option.

### Benchmark summary plots

We present a graphical comparison of `gcollapse` vs `fcollapse` (full numbers
and comparisons to `collapse` further below). We can see that `gcollapse`
is several times faster than `fcollapse` under all circumstances. The speed
gain is specially sharp when computing multiple complex statistics, such as
percentiles.

<img src="https://raw.githubusercontent.com/mcaceresb/stata-gtools/develop/src/test/plots/barComparisonTag2.png" alt="compare-J" width="700px"/>

<img src="https://raw.githubusercontent.com/mcaceresb/stata-gtools/develop/src/test/plots/barComparisonJ.png" alt="compare-J" width="700px"/>

### Benchmark details: In the style of `ftools`

Vary N for J = 100 and collapse 15 variables:
```
    vars  = y1-y15 ~ 123.456 + U(0, 1)
    stats = sum

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      1.41 |      6.76 |      4.51 |        3.19 |        4.79 |
    |  20,000,000 |     13.04 |     75.53 |     51.68 |        3.96 |        5.79 |
    | 200,000,000 |    112.19 | [not run] |    434.09 |        3.87 |   [not run] |
```

In the tables, `g`, `f`, and `c` are code for `gcollapse`, `fcollapse`,
and `collapse`, respectively.
```
    vars  = y1-y3 ~ 123.456 + U(0, 1)
    stats = mean median

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      0.87 |      9.23 |      3.98 |        4.57 |       10.59 |
    |  20,000,000 |      7.36 |    114.90 |     45.60 |        6.20 |       15.61 |
    | 200,000,000 |     62.37 | [not run] |    641.97 |       10.29 |   [not run] |
```

The two benchmarks above are run in the `ftools` package. We see
`gcollapse` is 3-10 times faster than `fcollapse` and 5-16 times faster
than `collapse`, with larger speed gains for complex statistics and a
large number of observations. I also devised one more benchmark in this
style: Multiple simple statistics for many variables.
```
    vars  = y1-y6 ~ 123.456 + U(0, 1)
    stats = sum mean count min max

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      0.96 |     32.31 |      3.97 |        4.14 |       33.70 |
    |  20,000,000 |      7.52 |    451.24 |     48.06 |        6.39 |       60.02 |
    | 200,000,000 |     58.04 | [not run] |    384.78 |        6.63 |   [not run] |
```

`gcollapse` was 4-6 times faster than `fcollapse` and 30-60 times faster than `collapse`.

### Benchmark details: Increasing the sample size

I thought it fitting to also compare a benchmark that produced one of
each available statistic. Here I vary N for J = 10 (data was sorted on a
random variable before collapsing):
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      1.25 |    119.41 |      9.68 |        7.73 |       95.37 |
    |  20,000,000 |     13.28 |   1649.93 |    159.80 |       12.03 |      124.23 |
    | 200,000,000 |    104.04 | [not run] |   2195.65 |       21.10 |   [not run] |
```

`gcollapse` handles multiple complex statistics specially well relative to
`collapse` (95 to 125 times faster) and `fcollapse` (7 to 21 times faster).

### Benchmark details: Increasing the number of levels

All the benchmarks above have collapsed to a small number of groups;
hence I also benchmark the effect of increasing the group size. Here I
vary J for N = 50,000,000 (data was sorted on a random variable before
collapsing):
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |          J | gcollapse | fcollapse | ratio (f/g) |
    | ---------- | --------- | --------- | ----------- |
    |         10 |     24.94 |    418.04 |       16.76 |
    |        100 |     25.71 |    258.24 |       10.04 |
    |      1,000 |     26.51 |    237.11 |        8.94 |
    |     10,000 |     28.06 |    234.16 |        8.34 |
    |    100,000 |     30.15 |    211.93 |        7.03 |
    |  1,000,000 |     37.51 |    274.60 |        7.32 |
    | 10,000,000 |     91.16 |    986.76 |       10.82 |
```

`fcollapse` did better for a modest numbers of groups, but it performed
poorly for very few groups and for a large number of groups. Overall
`gcollapse` was 7-16 times faster. I have not benchmarked `collapsed`
against version `0.7.0` in this case because each run will take over
an hour and have not found the time. I ran a "smaller" version of this
benchmark: Vary J for N = 5,000,000
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |          J | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |      1,000 |      2.80 |    331.23 |     22.13 |        7.91 |      118.38 |
    |     10,000 |      3.28 |    324.73 |     20.20 |        6.16 |       99.03 |
    |    100,000 |      3.65 |    323.46 |     26.14 |        7.17 |       88.67 |
    |  1,000,000 |      8.91 |    347.01 |     95.51 |       10.71 |       38.92 |
```

Building
--------

### Requirements

If you want to compile the plugin yourself, you will need
- The GNU Compiler Collection (`gcc`)
- [`premake5`](https://premake.github.io)
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)
- v2.0 or above of the [Stata Plugin Interface](https://stata.com/plugins/version2) (SPI).

I keep a copy of Stata's Plugin Interface in this repository, and I
have added `centaurean`'s implementation of SpookyHash as a submodule.
However, you will have to make sure you have `gcc` and `premake5`
installed and in your system's `PATH`. Last, on windows, you will
additionally need
- [Cygwin](https://cygwin.com) with gcc, make, libgomp, x86_64-w64-mingw32-gcc-5.4.0.exe
  (Cygwin is pretty massive by default; I would install only those packages).

If you also want to compile SpookyHash on windows yourself, you will
also need
- [Microsoft Visual Studio](https://www.visualstudio.com) with the
  Visual Studio Developer Command Prompt (again, this is pretty massive
  so I would recommend you install the least you can to get the
  Developer Prompt).

I keep a copy of `spookyhash.dll` in `./lib/windows` so there is no need
to re-compile SpookyHash.

### Compilation

```bash
git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --init --recursive
make spooky
make clean
make
```

If that is successful then run `./build/gtools_tests.do` to test the
program will work as expected. If successful, the exit message should be
"tests finished running" followed by the start and end time.

### Troubleshooting

If you are on OSX, you will have to compile the plugin yourself.
It is possible that after installing the dependencies, all you need
to do is run `make`, but I cannot guarantee that will be the case
since I have not tested it myself.

Compiling on Linux or Windows should not give problems. I test the
builds using Travis and Appveyor; if both builds are passing and
you can't get them to compile, it is likely because you have not
installed all the requisite dependencies. For Cygwin in particular, see
`./src/plugin/gtools.h` for all the include statements and check if you
have any missing libraries.

Loading the plugin on Windows is a bit trickier. While I eventually
got the plugin to work, it is possible for it to compile but fail to
load. One very possible reason for this is that Stata cannot find the
SpookyHash library, `spookyhash.dll` (Stata does not look in the ado
path by default, just the current directory and the system path). I keep
a copy in `./lib/windows` but the user can also run
```
gtools, dependencies
```

If that does not do the trick, run
```
gtools, dll
```

before calling `gcollapse` and `gegen` (should only be required
once per script/interactive session). Alternatively, you can keep
`spookyhash.dll` in the working directory or run your commands with
`hashlib()`. For example,
```
gcollapse (sum) varlist, by(varlist) hashlib(C:\path\to\spookyhash.dll)
```

Other than that, as best I can tell, all will be fine as long
as you use the MinGW version of gcc and SpookyHash was built
using visual studio. (i.e. `x86_64-w64-mingw32-gcc` instead of
`gcc` in cygwin for the plugin; `premake5 vs2013` and `msbuild
SpookyHash.sln` for SpookyHash, though you can find the dll pre-built in
`./lib/windows/spookyhash.dll`, as I mentioned).

If you are set on re-compiling SpookyHash, you have to force `premake5`
to generate project files for a 64-bit version only (otherwise `gcc`
will complain about compatibility issues). Further, the target folder
has not always been consistent in testing. While this may be due to an
error on my part, I have found the compiled `spookyhash.dll` in
- `./lib/spookyhash/build/bin`
- `./lib/spookyhash/build/bin/x86_64/Release`
- `./lib/spookyhash/build/bin/Release`

Again, I advise against trying to re-compile SpookyHash. Just use the
dll provided in this repo.

FAQs
----

### What functions are available?

Most of the `collapse' functions are supported, as well as some `egen`
functions

    | Function    | gcollapse | gegen |
    | ----------- | --------- | ----- |
    | tag         |           |   X   |
    | group       |           |   X   |
    | total       |           |   X   |
    | sum         |     X     |   X   |
    | mean        |     X     |   X   |
    | sd          |     X     |   X   |
    | max         |     X     |   X   |
    | min         |     X     |   X   |
    | count       |     X     |   X   |
    | median      |     X     |   X   |
    | iqr         |     X     |   X   |
    | percent     |     X     |   X   |
    | first       |     X     |   X   |
    | last        |     X     |   X   |
    | firstnm     |     X     |   X   |
    | lastnm      |     X     |   X   |
    | percentiles |     X     |   X   |

The percentile syntax mimics that of `collapse` and `egen`:
```stata
gcollapse (p#) target = var [target = var ...] , by(varlist)
gegen target = pctile(var), by(varlist) p(#)
```

Where # is a "percentile" (though it can have arbitrary decimal places,
which allows computing quantiles; e.g. 2.5 or 97.5).

### Important differences from `collapse`

- No support for weights.
- `rawsum` is not supported.
- `semean`, `sebinomial`, `sepoisson` are not supported.

### Important differences from `egen`

- Most egen function are not yet supported by `gegen`; only the functions
  noted above are currently available.

### Important differences from `flevelsof`

- It can take a `varlist` and not just a `varname`

### Important differences from `isid`

- No support for `using`.
- Option `sort` is not available.
- It can check IDs with `if` and `in`

### Stata on Windows

While the Linux version should be stable, the Windows version is considered
in beta since I do not have access to physical hardware running Windows. The
servers where I do my work, and my personal computer, are running Linux. I
developed the plugin for Windows on a virtual machine, and what works on my
virtual machine has occasionally not worked on some Windows systems.

At the moment there are no known problems on on Windows. However, one important
warning is that when Stata is executing the plugin, the user will not be able
to interact with the Stata GUI. Because of this, Stata may appear unresponsive
when it is merely executing the plugin. There is at least one known instance
where this can cause a confusion for the user: If the system runs out of RAM,
the program will attempt to use the pagefile. In doing, so, Stata may show a
"(Not responding)" message. However, the program has not crashed; it is merely
trying to use the pagefile.

To check this is the case, the user can monitor disk activity or monitor the
pagefile directly.

### How can this be faster?

In theory, C shouldn't be faster than Stata native commands because,
as I understand it, many of Stata's underpinnings are already compiled
C code. However, there are two explanations why this is faster than
Stata's native commands:

1. Hashing: I hash the data using a 128-bit hash and sort on this hash
   using a radix sort (a counting sort that sorts large integers X-bits
   at a time; I choose X to be 16). Sorting on a single integer is much
   faster than sorting on a collection of variables with arbitrary data.
   With a 128-bit hash you shouldn't have to worry about collisions
   (unless you're working with groups in the quintillions—that's
   10^18). Hashing here is also faster than hashing in Sergio Correia's
   `ftools`, which uses a 32-bit hash and will run into collisions just
   with levels in the thousands, so he has to resolve collisions.

2. Efficiency: It is possible that Stata's algorithms are not
   particularly efficient (this is, for example, the explanation given
   for why `ftools` is faster than Stata even though Mata should not be
   faster than compiled C code).

### How does hashing work?

The point of using a hash is straightforward: Sorting a single integer
variable is much faster than sorting multiple variables with arbitrary
data. In particular I use a counting sort, which asymptotically performs
in `O(n)` time compared to `O(n log n)` for the fastest general-purpose
sorting algorithms. (Note with a 128-bit algorithm using a counting
sort is prohibitively expensive; `gcollapse` actually does 4 passes of
a counting sort, each sorting 16 bits at a time; if the groups are not
unique after sorting on the first 64 bits we sort on the full 128 bits.)

Given `K` by variables, `by_1` to `by_K`, where `by_k` belongs the set
`B_k`, the general problem is to devise a function `f` such that `f:
B_1 x ... x B_K -> N`, where `N` are the natural (whole) numbers. Given
`B_k` can be integers, floats, and strings, the natural way of doing
this is to use a hash: A function that takes an arbitrary sequence of
data and outputs data of fixed size.

In particular I use the [Spooky Hash](http://burtleburtle.net/bob/hash/spooky.html)
devised by Bob Jenkins, which is a 128-bit hash. Stata caps observations
at 20 billion or so, meaning a 128-bit hash collision is _de facto_ impossible.
Nevertheless, the function does check for hash collisions and will fall back
on `collapse` and `egen` when it encounters a collision. An internal
mechanism for resolving potential collisions is in the works. See [issue
2](https://github.com/mcaceresb/stata-gtools/issues/2) for a discussion.

### Why use platform-dependent plugins?

C is fast! When optimizing stata, there are three options:
- Mata (already implemented)
- Java plugins (I don't like Java)
- C and C++ plugins

Sergio Correa's `ftools` tests the limits of mata and achieves excellent
results, but Mata cannot compare to the raw speed a low level language like
C would afford. The only question is whether the overhead reading and writing
data to and from C compensates the speed gain, and in this case it does.

### Why no multi-threading on Windows?

I do multi-threading via OpenMP because it has really nice functionality and
is cross platform. However, it doesn't like being used to compile a shared
executable, and Stata requires the plugin to be a shared executable. I can get
the multi-threaded version on Windows to compile and to load but it crashes
Stata. If you have experience with OpenMP on Windows, let me know!

### Why not OSX?

C is platform dependent and I don't have access to a laptop running Windows
or OSX. Windows, however, makes it easy for you to download their ISO, hence
I was able to test this on a virtual machine. OSX does not make their ISO
available, as best I can tell.

Feel free to try and compile this for OSX. There's likely minimal
tinkering to be done beyond installing the dependencies. I'm happy to
take pull requests! If you try to compile the plugin yourself, make sure
`./build/gtools_tests.do` runs without errors and that you include the
resulting `./build/gtools_tests_macosx.log` in the request.

### My computer has a 32-bit CPU

This uses 128-bit hashes split into 2 64-bit parts. As far as I know, it
will not work with a 32-bit processor. If you try to force it to run,
you will almost surely see integer overflows and pretty bad errors.

### Why can't the function do weights?

I have never used weights in Stata, so I will have to read up on how
weights are implemented before adding that option to `gcollapse`.
Support for weight is coming, though!

### Memory management

C cannot create or drop variables. This creates a problem when N is
large and the number of groups J is small. For examplle, N = 100M
means about 800MiB per variable and J = 1,000 means barely 8KiB per
variable. Adding variables after the collapse is trivial and before
the collapse it may take several seconds.

The function tries to be smart about this: Variables are only created if
the source variable cannot be replaced with the target. This conserves
memory and speeds up execution time. (However, the function currently
recasts unsuitably typed source variables, which saves memory but slows
down execution time.)

If there are more targets than sources, however, there are two options:
1. Create the extra target variables in Stata before collapsing.
2. Write the extra targets, collapsed, to disk and read them back later.

Ideally I could create the variables in Stata after collapsing and read
them back from memory, but that is not possible. Hence we must choose
one of the two options above, and it is not always obvious which will be
faster.

Clearly for very large N and very small J, option 2 is faster. However,
as J grows relative to N the trade-off is not obvious. First, variables
still have to be created in Stata. So disk operations have to be faster
than (N - J) / N of the time it takes for Stata to the variables. In our
example, disk operations on 8KiB per variable should be instantaneous
and will almost surely be faster than operations on 720MiB per variable
in memory.

But what if J is 10M? Is operating on ~80MiB on disk faster than ~720MiB
on memory? The answer may well be no. What if J = 50M? Then the answer
is almost surely no. For this reason, the code tries to benchmark how
long it will take to collapse to disk and read back the data from disk
versus creating the variables in memory and simply collapsing to memory.

This has a small overhead, so `gcollapse` will only try the swtich when
there are at least 4 additional targets to create. In testing, the
overhead has been ~10% of the total runtime. If the user expects J to be
large, they can turn off this check via `forcemem`. If the user expects
J to be small, they can force collapsing to disk via `forceio`.

### TODO

In order of priority:

- [ ] Compile for OSX.
- [ ] Multi-threaded version on windows.
- [ ] Fix Windows bug where comma-format is not correctly displayed.
- [ ] Add support for weights.
- [ ] Provide `sumup` and `sum` altetnative, `gsum`.
    - [ ] Improve the way the program handles no "by" variables.
- [ ] Add `gtab` as a fast version of `tabulate` with a `by` option.
    - [ ] Also add functionality from `tabcustom`.
- [ ] Add `Var`, `kurtosis`, `skewness`
- [ ] Implement other by-able `egen` functions.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
