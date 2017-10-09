<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

[Overview](#faster-stata-for-group-operations)
| [Installation](#installation)
| [Benchmarks](#collapse-benchmarks)
| [Building](#building)
| [FAQs](#faqs)
| [License](#license)

_Gtools_: Faster Stata for big data. This packages provides a hash-based
implementation of collapse, egen, isid, and levelsof using C plugins for a
massive speed improvement.

`version 0.7.5 08Oct2017`
Builds: Linux [![Travis Build Status](https://travis-ci.org/mcaceresb/stata-gtools.svg?branch=develop)](https://travis-ci.org/mcaceresb/stata-gtools),
Windows (Cygwin) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/2bh1q9bulx3pl81p/branch/develop?svg=true)](https://ci.appveyor.com/project/mcaceresb/stata-gtools)

Faster Stata for Group Operations
---------------------------------

This package's aim is to provide a fast implementation of group commands in
Stata using hashes and C plugins. This includes (benchmarked using Stata/MP):

| Function    | Replaces        | Speedup (MP)   | Extras               | Unsupported       |
| ----------- | --------------- | -------------- | -------------------- | ----------------- |
| `gcollapse` | `collapse`      | 8x to 150x (+) | Quantiles, `merge`   | Weights           |
| `gegen`     | `egen`          | 1.5x to 7x (*) | Quantiles            | See [FAQs](#faqs) |
| `gisid`     | `isid`          | 3.5x to 9x     | `if`, `in`           | `using`, `sort`   |
| `glevelsof` | `levelsof`      | 1.5x to 7x     | Multiple variables   |                   |

<small>Commands were benchmarked on a Linux server with Stata/MP; gains in Stata/IC are larger.</small>

<small>(+) The upper end of the speed improvements are for quantiles (e.g. median, iqr, p90) and few groups.</small>

<small>(*) Only `egen group` was benchmarked.</small>

The key insight is that hashing the data and sorting a hash is a lot faster
than sorting the data to then process it by group. Sorting a hash can be
achieved in linear O(N) time, whereas the best sorts take O(N log(N))
time. Sorting the groups would then be achievable in O(J log(J)) time
(with J groups). Hence the speed improvements are largest when N / J is
largest. Further, compiled C code is much faster than Stata commands.

In addition, an experimental command, `hashsort`, is included as a `sort` and
`gsort` replacement. While `hashsort` is often faster than `sort` in Stata/IC,
it is generally slower in Stata/MP, where Stata sorts at 2-3x the speed. It
is most useful as a `gsort` replacement, where even in Stata/MP there are
often speed gains. (The reason sorting is not faster is that Stata sorts data
in place, with virtually no memory overhead or any additional operations;
`hashsort`, by contrast, must copy the data first and then still rely on Stata
to perform the swaps.)

| Function    | Replaces        | Speedup (MP)   | Extras               | Unsupported     |
| ----------- | --------------- | -------------- | -------------------- | --------------- |
| `hashsort`  | `sort`          | 0.5x to 1.5x   | Group (hash) sorting |                 |
|             | `gsort`         | 1x to 5x       | Sorts are stalbe     | `mfirst`, `gen` |

<small>`hashsort` is only faster then `sort` under limited circumstances. The
benchmarks were conducted on Stata/MP with 8 cores, where sorting was 2-3x
faster than on Stata/IC with one core. Further, even in Stata/IC `hashsort`
could be slower than `sort` if the resulting sort would be unique (i.e. not
sorting groups). By contrast, `hashsort` was often faster than `gsort` even in
Stata/MP and it was always faster than `gsort` in Stata/IC.</small>

This package was largely inspired by Sergio Correia's excellent
[ftools](https://github.com/sergiocorreia/ftools) package. The commands here
are also faster than the commands provided by `ftools`; further, `gtools`
commands take a mix of string and numeric variables.

| Gtools      | Ftools          | Speedup     |
| ----------- | --------------- | ----------- |
| `gcollapse` | `fcollapse`     | 3.5x-20x    |
| `hashsort`  | `fsort`         | 1.5x-2.5x   |
| `gegen`     | `fegen`         | 0.7x-2x (*) |
| `gisid`     | `fisid`         | 2x-8.5x     |
| `glevelsof` | `flevelsof`     | 1.2-2x      |

<small>(*) Only `egen group` was benchmarked. `gegen` was slower when encoding
integers, where the overhead did not offset the speed gains.</small>

The current release only provides Unix (Linux) and Windows versions of the C plugin.
Further, multi-threading is only available on Linux. An OSX version is in the works
(see [issue 11](https://github.com/mcaceresb/stata-gtools/issues/11)). If you plan
to use the plugin extensively, check out the [FAQs](#faqs) for caveats and details
on the plugin.

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
sysuse auto, clear

* hashsort varlist, [options]
hashsort -make
hashsort foreign -rep78, benchmark verbose

* gegen target  = stat(source), by(varlist) [options]
gegen tag   = tag(foreign)
gegen group = tag(make price)
gegen p2_5  = pctile(price), by(foreign) p(2.5)

* gisid varlist [if] [in], [options]
gisid make, missok
gisid price in 1

* glevelsof varlist [if] [in], [options]
glevelsof rep78, local(levels) sep(" | ")
glevelsof foreign mpg if price < 4000, local(levels) sep(" | ") colsep(", ")

* gcollapse (stat) target = source [(stat) target = source ...], by(varlist) [options]
gcollapse (mean) price (median) gear_ratio, by(make) merge benchmark
gcollapse (p97.5) mpg (iqr) headroom, by(foreign) verbose
```

Support for weights for `gcollapse` and `gegen` planned for a future
release. See the [FAQs](#faqs) for a list of supported functions.

Benchmarks
----------

Benchmarks were performed on a server running Linux:

    Program:   Stata/MP 14.2 (8 cores)
    OS:        x86_64 GNU/Linux
    Processor: Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.40GHz
    Cores:     2 sockets with 6 cores and 2 virtual threads per core.
    Memory:    62GiB
    Swap:      119GiB

### Collapse

Here I run 2 sets of benchmarks:

- `ftools`-style benchmarks: Collapse a large number of observations
  to 100 groups. This sums 15 variables, take the mean and median of 3
  variables, and take the mean, sum, count, min, and max of 6 variables.

- Increasing group size: This fixes the sample size at 50M and increase
  the group size from 10 to 10M in geometric succession and computes
  all available stats (and 2 sample percentiles) for 2 variables.

_**In the style of `ftools`**_

Vary N for J = 100 and collapse 15 variables:
```
    vars  = y1-y15 ~ 123.456 + U(0, 1)
    stats = sum
    J     = 100

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |  2,000,000 |      0.59 |      4.71 |      2.06 |        3.46 |        7.92 |
    | 20,000,000 |      5.43 |     60.84 |     21.13 |        3.89 |       11.20 |
```

In the tables, `g`, `f`, and `c` are code for `gcollapse`, `fcollapse`,
and `collapse`, respectively.
```
    vars  = y1-y3 ~ 123.456 + U(0, 1)
    stats = mean median
    J     = 100

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |  2,000,000 |      0.38 |      5.63 |      2.85 |        7.54 |       14.89 |
    | 20,000,000 |      3.12 |     77.58 |     33.77 |       10.82 |       24.86 |
```

The two benchmarks above are run in the `ftools` package. We see `gcollapse`
is ~4-11 times faster than `fcollapse` and ~8-25 times faster than `collapse`,
with larger speed gains for complex statistics and a large number of
observations. I also devised two more benchmark in this style: First, multiple
simple statistics for many variables.
```
    vars  = y1-y6 ~ 123.456 + U(0, 1)
    stats = sum mean count min max
    J     = 100

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |  2,000,000 |      0.38 |     23.13 |      2.17 |        5.68 |       60.55 |
    | 20,000,000 |      3.14 |    297.05 |     21.33 |        6.79 |       94.51 |
```

`gcollapse` was ~5.5-7 times faster than `fcollapse` and 60-95 times faster than
`collapse`. Second, we do all the available statistics.
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77
    J     = 10

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |  2,000,000 |      0.72 |     65.47 |      8.03 |       11.14 |       90.80 |
    | 20,000,000 |      6.62 |    978.61 |     99.40 |       15.01 |      147.78 |
```

`gcollapse` handles multiple complex statistics specially well relative to
`collapse` (91-148 times faster) and `fcollapse` (11 to 15 times faster).

_**Increasing the group size**_

Here we vary J for N = 5,000,000
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |          J | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |     10,000 |      1.79 |    194.50 |     13.97 |        7.79 |      108.54 |
    |    100,000 |      2.25 |    194.31 |     17.19 |        7.64 |       86.36 |
    |  1,000,000 |      4.46 |    197.25 |     63.71 |       14.28 |       44.22 |
```

We can see that while speed gains relative to `collapse` deteriorate as J
increases, `gcollapse` can still be orders of magnitude faster.

### Hash sort

We create a data set of `10,000` observations and extend it to 10M
(10,000,000).  So there are 1,000 groups for any given sorting
arrangement. Variables are self-descriptive, so "str_32" is a string with 32
characters. "double2" is a double. And so on.

String variables were concatenated from a mix of fixed and random strings
using the `ralpha` package.

    | sort | fsort | hashsort | ratio (g/h) | ratio (f/h) | sorted by (stable)                                         |
    | ---- | ----- | -------- | ----------- | ----------- | ---------------------------------------------------------- |
    | 7.14 |  19.7 |     7.05 |        1.01 |         2.8 | str_12                                                     |
    | 9.12 |  22.2 |     11.3 |        .809 |        1.97 | str_12 str_32                                              |
    | 9.39 |  26.1 |       12 |        .785 |        2.18 | str_12 str_32 str_4                                        |
    | 7.56 |    17 |     13.2 |        .574 |        1.29 | double1                                                    |
    | 6.52 |    18 |     8.91 |        .732 |        2.02 | double1 double2                                            |
    | 7.95 |  20.4 |     14.7 |         .54 |        1.38 | double1 double2 double3                                    |
    | 8.02 |  13.6 |     8.02 |        .999 |        1.69 | int1                                                       |
    |  8.6 |  18.3 |     9.87 |        .871 |        1.85 | int1 int2                                                  |
    | 7.95 |  17.2 |     5.33 |        1.49 |        3.22 | int1 int2 int3                                             |
    |   10 |     . |     11.2 |        .897 |           . | int1 str_32 double1                                        |
    | 9.41 |     . |     9.84 |        .957 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 10.7 |     . |     14.3 |        .747 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

    | gsort | hashsort | ratio (g/h) | sorted by                                                      |
    | ----- | -------- | ----------- | -------------------------------------------------------------- |
    |  .636 |     .677 |        .939 | -str_12                                                        |
    |  1.04 |     .817 |        1.28 | str_12 -str_32                                                 |
    |  1.59 |     .875 |        1.82 | str_12 -str_32 str_4                                           |
    |   .77 |     .589 |        1.31 | -double1                                                       |
    |  1.04 |     .669 |        1.56 | double1 -double2                                               |
    |  1.63 |      .69 |        2.36 | double1 -double2 double3                                       |
    |   .68 |     .356 |        1.91 | -int1                                                          |
    |  1.16 |     .437 |        2.66 | int1 -int2                                                     |
    |  1.67 |     .466 |        3.58 | int1 -int2 int3                                                |
    |  2.45 |     .826 |        2.97 | -int1 -str_32 -double1                                         |
    |   3.8 |     .944 |        4.03 | int1 -str_32 double1 -int2 str_12 -double2                     |
    |  6.03 |     1.12 |        5.37 | int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3 |

The above speed gains only hold when sorting groups.

### Group IDs

We use the same data as above to benchmark `gegen id = group(varlist)`.
Again we benchmark vs egen, obs = 10,000,000, J = 10,000 (in seconds)

    | egen | fegen | gegen | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ---- | ----- | ----- | ----------- | ----------- | ---------------------------------------------------------- |
    | 13.6 |  10.7 |  6.96 |        1.95 |        1.53 | str_12                                                     |
    | 13.8 |  15.6 |  10.9 |        1.26 |        1.43 | str_12 str_32                                              |
    | 13.3 |  18.7 |  9.82 |        1.35 |        1.91 | str_12 str_32 str_4                                        |
    | 14.3 |  6.56 |  7.63 |        1.87 |         .86 | double1                                                    |
    | 12.3 |  7.57 |  6.65 |        1.86 |        1.14 | double1 double2                                            |
    | 15.6 |  8.21 |  9.48 |        1.65 |        .866 | double1 double2 double3                                    |
    | 11.1 |  1.09 |  1.64 |        6.79 |        .668 | int1                                                       |
    | 13.1 |  1.43 |  2.04 |         6.4 |        .698 | int1 int2                                                  |
    | 12.8 |  1.89 |  2.25 |         5.7 |        .838 | int1 int2 int3                                             |
    |   16 |     . |  10.5 |        1.53 |           . | int1 str_32 double1                                        |
    | 17.1 |     . |  11.8 |        1.45 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 15.1 |     . |  10.3 |        1.47 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

While `gegen` is a boon over `egen`, it is only a marginal improvement over
`fegen`.  I reckon the crucial advantage relative to `fegen` is its ability to
take a mix of stirng and numeric variables.

### `isid`

Benchmark vs isid, obs = 10,000,000; all calls include an index to ensure
uniqueness (in seconds; fisid benchmarks were run on Stata/IC because
I couldn't get `fisid` to work on the server).

    | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ---- | ----- | ----- | ----------- | ----------- | ---------------------------------------------------------- |
    | 27.6 |     . |  3.67 |        7.51 |           . | str_12                                                     |
    | 28.2 |     . |  4.18 |        6.75 |           . | str_12 str_32                                              |
    | 29.2 |     . |  4.32 |        6.76 |           . | str_12 str_32 str_4                                        |
    | 22.4 |     . |  3.34 |        6.71 |           . | double1                                                    |
    | 22.8 |     . |  3.43 |        6.65 |           . | double1 double2                                            |
    | 23.4 |     . |  3.77 |        6.21 |           . | double1 double2 double3                                    |
    | 22.8 |     . |  2.47 |        9.24 |           . | int1                                                       |
    |   24 |     . |  2.77 |        8.64 |           . | int1 int2                                                  |
    | 24.7 |     . |  3.48 |        7.09 |           . | int1 int2 int3                                             |
    | 27.7 |     . |  4.14 |        6.68 |           . | int1 str_32 double1                                        |
    | 31.4 |     . |  4.81 |        6.54 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 32.4 |     . |  6.11 |        5.31 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

Benchmark vs isid, obs = 10,000,000, J = 10,000 (in seconds)

    | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ---- | ----- | ----- | ----------- | ----------- | ---------------------------------------------------------- |
    | 9.87 |     . |  2.17 |        4.54 |           . | str_12                                                     |
    | 10.2 |     . |  2.81 |        3.63 |           . | str_12 str_32                                              |
    | 10.7 |     . |  2.98 |        3.61 |           . | str_12 str_32 str_4                                        |
    | 8.89 |     . |  2.19 |        4.05 |           . | double1                                                    |
    | 8.84 |     . |  2.32 |        3.81 |           . | double1 double2                                            |
    | 9.36 |     . |  2.46 |         3.8 |           . | double1 double2 double3                                    |
    | 7.59 |     . |   .94 |        8.08 |           . | int1                                                       |
    | 10.5 |     . |  1.28 |        8.23 |           . | int1 int2                                                  |
    |   11 |     . |  1.78 |         6.2 |           . | int1 int2 int3                                             |
    | 12.3 |     . |  2.81 |        4.37 |           . | int1 str_32 double1                                        |
    | 12.6 |     . |  3.33 |        3.79 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 13.8 |     . |  3.98 |        3.46 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

`gisid` is across the board a massive speed improvement. 

Benchmark on Stata/IC vs isid and fisid, obs = 10,000,000, all calls include
an index to ensure uniqueness (in seconds)

     | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist                 |
     | ---- | ----- | ----- | ----------- | ----------- | ----------------------- |
     | 43.3 |  35.5 |   4.2 |        10.3 |        8.46 | str_12                  |
     | 47.2 |  34.6 |  4.37 |        10.8 |        7.92 | str_12 str_32           |
     | 47.1 |  39.7 |  4.65 |        10.1 |        8.53 | str_12 str_32 str_4     |
     | 30.3 |  15.8 |  3.66 |        8.29 |        4.32 | double1                 |
     |   32 |  16.4 |  3.65 |        8.75 |        4.49 | double1 double2         |
     | 33.3 |    17 |  4.01 |        8.31 |        4.25 | double1 double2 double3 |
     | 31.6 |  16.2 |  2.26 |          14 |        7.18 | int1                    |
     | 33.5 |  17.1 |  3.04 |          11 |        5.63 | int1 int2               |
     | 35.7 |  17.6 |  3.25 |          11 |        5.41 | int1 int2 int3          |

Benchmark on Stata/IC vs isid and fisid, obs = 10,000,000, J = 10,000 (in seconds)

     | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist                 |
     | ---- | ----- | ----- | ----------- | ----------- | ----------------------- |
     | 15.5 |  10.3 |  2.57 |        6.02 |        4.01 | str_12                  |
     | 17.3 |    16 |   3.1 |        5.59 |        5.17 | str_12 str_32           |
     | 17.9 |    19 |  3.48 |        5.14 |        5.47 | str_12 str_32 str_4     |
     |   13 |  7.51 |  2.54 |        5.11 |        2.96 | double1                 |
     |   14 |   8.8 |  2.65 |        5.28 |        3.32 | double1 double2         |
     | 14.2 |  9.25 |  2.73 |        5.22 |        3.39 | double1 double2 double3 |
     | 9.49 |  3.08 |  1.15 |        8.23 |        2.67 | int1                    |
     | 14.5 |  3.54 |  1.61 |           9 |        2.19 | int1 int2               |
     | 16.1 |  3.96 |  1.97 |        8.19 |        2.01 | int1 int2 int3          |

### `levelsof`

Benchmark vs levelsof, obs = 10,000,000, J = 100 (in seconds)

   | levelsof | flevelsof | glevelsof | ratio (i/g) | ratio (f/g) | varlist |
   | -------- | --------- | --------- | ----------- | ----------- | ------- |
   |       18 |      7.58 |      3.89 |        4.62 |        1.95 | str_12  |
   |     16.1 |      7.76 |      4.34 |        3.71 |        1.79 | str_32  |
   |     17.3 |      7.23 |      4.65 |        3.71 |        1.55 | str_4   |
   |     3.92 |      5.46 |      2.66 |        1.47 |        2.05 | double1 |
   |     3.96 |      5.62 |      2.77 |        1.43 |        2.03 | double2 |
   |     4.34 |      5.74 |      2.76 |        1.57 |        2.08 | double3 |
   |     1.61 |      .821 |      .561 |        2.87 |        1.46 | int1    |
   |     4.63 |      .815 |      .682 |        6.78 |         1.2 | int2    |
   |     2.21 |      .801 |      .675 |        3.27 |        1.19 | int3    |

In this case, `levelsof` is not a particularly large speed improvement for doubles.

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

Note that lines 37-40 in `lib/spookyhash/build/premake5.lua` cause the build
to fail on some systems, so we delete them (they are meant to check the git
executable exists).
```bash
git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --init --recursive
sed -i.bak -e '37,40d' ./lib/spookyhash/build/premake5.lua 
make spooky
make clean
make
```

### Unit tests

From a stata session, run
```stata
do build/gtools_tests.do
```

If successful, all tests should report to be passinga and the exit message
should be "tests finished running" followed by the start and end time.

### Troubleshooting

If you are on OSX, you will have to compile the plugin yourself.
Some work is being done on this front (see [issue 11](https://github.com/mcaceresb/stata-gtools/issues/11)),
but the plugin is not yet available.

Compiling on Linux or Windows should not give problems. I test the builds
using Travis and Appveyor; if both builds are passing and you can't get them
to compile, it is likely because you have not installed all the requisite
dependencies. For Cygwin in particular, see `./src/plugin/gtools.h` for all
the include statements and check if you have any missing libraries.

Loading the plugin on Windows is a bit trickier. While I eventually got
the plugin to work, it is possible for it to compile but fail to load. One
likely reason for this is that Stata cannot find the SpookyHash library,
`spookyhash.dll` (Stata does not look in the ado path by default, just the
current directory and the system path). I keep a copy in `./lib/windows` but
the user can also run

```
gtools, dependencies
```

If that does not do the trick, run

```
gtools, dll
```

before calling `gcollapse` and `gegen` (should only be required once per
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

Again, I advise against trying to re-compile SpookyHash. Just use the
dll provided in this repo.

FAQs
----

### What functions are available with `gegen` and `gcollapse`?

Most of the `collapse' functions are supported, as well as some
`egen` functions

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

### Important differences from Stata counterparts

From `collapse`

- `gcollapse, merge` merges the collapsed data set back into memory. This is
  much faster than collapsing a dataset, saving, and merging after. Note if the
  source variables are not renamed, they are replaced without warning.
- No support for weights.
- `rawsum` is not supported.
- `semean`, `sebinomial`, `sepoisson` are not supported.

From `egen`

- Most egen function are not yet supported by `gegen`; only the functions
  noted above are currently available.

From `levelsof`

- It can take a `varlist` and not just a `varname`; It then prints all unique
  combinations of the varlist. The user can specify column and row separators.

From `isid`

- It can also check IDs with `if` and `in` conditions.
- No support for `using`. The C plugin API does not allow to load a Stata
  dataset from disk.
- Option `sort` is not available.

### Why can't the functions do weights?

I have never used weights in Stata, so I will have to read up on how
weights are implemented before adding that option to `gcollapse`.

### Stata on Windows

At the moment there are no known problems on on Windows. However, one
important warning is that when Stata is executing the plugin, the user will
not be able to interact with the Stata GUI. Because of this, Stata may appear
unresponsive when it is merely executing the plugin.

There is at least one known instance where this can cause a confusion for
the user: If the system runs out of RAM, the program will attempt to use the
pagefile. In doing, so, Stata may show a "(Not responding)" message. However,
the program has not crashed; it is merely trying to use the pagefile.

To check this is the case, the user can monitor disk activity or monitor the
pagefile directly.

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

Feel free to try and compile this for OSX; see [issue 11](https://github.com/mcaceresb/stata-gtools/issues/11)
for progress we have made on this front. There's likely minimal
tinkering to be done beyond installing the dependencies. I'm happy to
take pull requests! If you try to compile the plugin yourself, make sure
`./build/gtools_tests.do` runs without errors and that you include the
resulting `./build/gtools_tests_macosx.log` in the request.

### My computer has a 32-bit CPU

This uses 128-bit hashes split into 2 64-bit parts. As far as I know, it
will not work with a 32-bit processor. If you try to force it to run,
you will almost surely see integer overflows and pretty bad errors.

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
- [ ] Benchmark parsing if condition when hashing vs post.
- [ ] Provide `sumup` and `sum` altetnative, `gsum`.
    - [ ] Improve the way the program handles no "by" variables.
- [ ] Add `gtab` as a fast version of `tabulate` with a `by` option.
    - [ ] Also add functionality from `tabcustom`.
- [ ] Add support for weights.
- [ ] Add `Var`, `kurtosis`, `skewness`
- [ ] Implement other by-able `egen` functions.

License
-------

Gtools is [MIT-licensed](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE).
`./lib/spookyhash` and `./src/plugin/tools/quicksort.c` belong to their respective
authors and are BSD-licensed.
