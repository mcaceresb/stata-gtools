<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

[Overview](#faster-stata-for-group-operations)
| [Installation](#installation)
| [Benchmarks](#collapse-benchmarks)
| [Building](#building)
| [FAQs](#faqs)
| [License](#license)

_Gtools_: Faster Stata for big data. This packages provides a hash-based
implementation of collapse, egen, isid, levelsof, and unique using C plugins
for a massive speed improvement.

`version 0.8.0 25Oct2017`
Builds: Linux [![Travis Build Status](https://travis-ci.org/mcaceresb/stata-gtools.svg?branch=develop)](https://travis-ci.org/mcaceresb/stata-gtools),
Windows (Cygwin) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/2bh1q9bulx3pl81p/branch/develop?svg=true)](https://ci.appveyor.com/project/mcaceresb/stata-gtools)

Faster Stata for Group Operations
---------------------------------

This package's aim is to provide a fast implementation of group commands in
Stata using hashes and C plugins. This includes (benchmarked using Stata/MP):

| Function    | Replaces        | Speedup (MP)      | Unsupported     | Extras                           |
| ----------- | --------------- | ----------------- | --------------- | -------------------------------- |
| `gcollapse` | `collapse`      |  x to    x (+)    | Weights         | Quantiles, `merge`, label output |
| `gegen`     | `egen`          |  x to    x (+, .) | Weights, labels | Quantiles                        |
| `gisid`     | `isid`          |  x to    x        | `using`, `sort` | `if`, `in`                       |
| `glevelsof` | `levelsof`      |  x to    x        |                 | Multiple variables               |
| `gunique`   | `unique`        |  x to    x        | `by`            |                                  |

<small>Commands were benchmarked on a Linux server with Stata/MP; gains in Stata/IC are larger.</small>

<small>(+) The upper end of the speed improvements are for quantiles (e.g. median, iqr, p90) and few groups.</small>

<small>(.) Only `egen group` was benchmarked rigorously.</small>

In addition, all commands take gsort-style input, that is

```
[+|-]varname [[+|-]varname ...]
```

This often does not matter (e.g. gegen summary stats, gisid, gunqiue) but it
saves a second sort in other places (e.g. gcollapse, gegen group, glevelsof).
If you plan to use the plugin extensively, check out the [FAQs](#faqs) for
caveats and details on the plugin.

### Hashing

The key insight is that hashing the data and sorting a hash is a lot faster
than sorting the data to then process it by group. Sorting a hash can be
achieved in linear O(N) time, whereas the best sorts take O(N log(N))
time. Sorting the groups would then be achievable in O(J log(J)) time
(with J groups). Hence the speed improvements are largest when N / J is
largest. Further, compiled C code is much faster than Stata commands.

### Sorting

It should be noted that Stata's sorting mechanism is not inefficient as a
general-purpose sort. It is just inefficient for processing data by group. We
have implemented a hash-based sorting command, `hashsort`. While at times this
is faster than Stata's `sort`, it can also often be slower:

| Function    | Replaces        | Speedup (MP) | Unsupported | Extras               |
| ----------- | --------------- | ------------ | ----------- | -------------------- |
| `hashsort`  | `sort`          | x to x       |             | Group (hash) sorting |
|             | `gsort`         | x to x       | `mfirst`    | Sorts are stable     |

The overhead involves copying the by variables, hashing, sorting the hash,
sorting the groups, copying a sort index back to Stata, and having Stata do
the final swaps. The plugin runs fast, but the copy overhead plus the Stata
swaps often make the function be slower than Stata's native `sort`.

By contrast, Stata's `gsort` is not efficient. To sort data, you need to make
pair-wise comparisons. For real numbers, this is just `a > b`. However, a generic
comparison function can be written as `compare(a, b) > 0`. This is true if a
is greater than b and false otherwise. To invert the sort order, one need only
use `compare(b, a) > 0`, which is what gtools does internally.

However, Stata creates a variable that is the inverse of the sort variable.
This is equivalent, but the overhead makes it slower than `hashsort`.

### Ftools

The commands here are also faster than the commands provided by `ftools`;
further, `gtools` commands take a mix of string and numeric variables,
which is a limitation of `ftools`.

| Gtools      | Ftools          | Speedup     |
| ----------- | --------------- | ----------- |
| `gcollapse` | `fcollapse`     | x-x         |
| `hashsort`  | `fsort`         | x-x         |
| `gegen`     | `fegen`         | x-x (*)     |
| `gisid`     | `fisid`         | x-x         |
| `glevelsof` | `flevelsof`     | x-x         |

Acknowledgements
----------------

* The OSX version of gtools was implemented with invaluable help from @fbelotti
  in [issue 11](https://github.com/mcaceresb/stata-gtools/issues/11).

* Gtools was largely inspired by Sergio Correia's (@sergiocorreia) excellent
  [ftools](https://github.com/sergiocorreia/ftools) package. Further, several
  improvements and bug fixes have come from to @sergiocorreia's helpful comments.

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
gegen group = tag(-price make)
gegen p2_5  = pctile(price), by(foreign) p(2.5)

* gisid varlist [if] [in], [options]
gisid make, missok
gisid price in 1

* glevelsof varlist [if] [in], [options]
glevelsof rep78, local(levels) sep(" | ")
glevelsof foreign mpg if price < 4000, local(levels) sep(" | ") colsep(", ")

* gcollapse (stat) target = source [(stat) target = source ...], by(varlist) [options]
gcollapse (mean) price (median) gear_ratio, by(make) benchmark
gcollapse (p97.5) mpg (iqr) headroom, by(foreign rep78) verbose
```

Support for weights for `gcollapse` and `gegen` planned for a future
release. See the [FAQs](#faqs) for a list of supported functions.

### Extra features

while gtools does not support every native option, it does offer several
additional features. Two of the more interesting extras come via `gcollapse`:

1. `merge`, whichmerges summary stats back to the main data. This is equivalent
   to a sequence of `egen` statements or to `collapse` followed by merge. That
   is, if you want to create bulk summary statistics, you might want to do:

```stata
sysuse auto, clear
preserve
collapse (mean) mean_pr = price (median) median_gr = gear_ratio, by(foreign)
tempfile bulk
save `bulk'
restore
merge m:1 foreign using `bulk', assert(3) nogen
```

But with `gtools` this is simplified to
```stata
sysuse auto, clear
gcollapse (mean) mean_pr = price (median) median_gr = gear_ratio, ///
    by(foreign) merge mergeformats mergelabels
```

2. `labelformat()`, which allows the user to specify the output label format
   using a very simple engine. `collapse` Sets labels to "(stat) source label".
   I find this format ugly, so I have implemented a very basic engine to label
   outputs:

```stata
sysuse auto, clear
gcollapse (mean) price, by(foreign) labelformat(#stat#: #sourcelabel#)
desc
```

The following placeholder options are available in the engine:

- `#stat#`, `#Stat#`, and `#STAT#` are replaced with the lower-, title-, and
  upper-case name of the summary stat.

- `#sourcelabel#`, `#sourcelabel:start:numchars#` are replaced with the source label,
  optionally extracting `numchars` characters from `start` (`numchars` can be `.`
  to denote all characters from `start`).

- `#stat:pretty#` replces each stat name with a nicer version (mean to Mean,
  sd to St Dev., and so on). The user can specify a their own custom pretty
  program via `labelprogram()`. The program MUST be an rclass program
  and return `prettystat`. For example

```
program my_pretty_stat, rclass
         if ( `"`0'"' == "sum"  ) local prettystat "Total"
    else if ( `"`0'"' == "mean" ) local prettystat "Average"
    else {
        GtoolsPrettyStat
    }
    return local prettystat = `"`prettystat'"'
end
sysuse auto, clear
gcollapse (mean) mean = price (sum) sum = price (sd) sd = price, ///
    by(foreign) labelformat(#stat:pretty# of #sourcelabel#) labelp(my_pretty_stat)
desc
```

We can see that `mean` and `sum` were set to the custom labe, while `sd` was
set to the default. You can also specify a different label format for each
variable if you put the stat palceholder in the variable label.

```
sysuse auto, clear
gen mean = price
gen sum  = price

label var mean "Price (#stat#)"
label var sum  "Price #stat:pretty#"

gcollapse (mean) mean (sum) sum (sd) price, ///
    by(foreign) labelformat(#sourcelabel#) labelp(my_pretty_stat)
desc
```

Benchmarks
----------

Benchmarks were performed on a server running Linux:

    Program:   Stata/MP 14.2 (8 cores)
    OS:        x86_64 GNU/Linux
    Processor: Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.40GHz
    Cores:     2 sockets with 6 cores and 2 virtual threads per core.
    Memory:    62GiB
    Swap:      119GiB

### Random data

We create a data observations and expand it to 10M (10,000,000) observations.
Each benchmark indicates how many groups J there are. This means that we
created a dataset with J observations and `extend` with 10M / J as the
argument.

This ensures there are J groups for any given sorting arrangement. Variables
are self-descriptive, so "str_32" is a string with 32 characters. "double2" is
a double. And so on.

String variables were concatenated from a mix of fixed and random strings
using the `ralpha` package. All variables include missing values. `int3` and
`double3` include extended missing values. `int3` is typed as double but all
non-missing entries are integers.

### Collapse

Here I run 2 sets of benchmarks:

- `ftools`-style benchmarks: One version sums 15 variables. The other takes
  the mean, median, min, and max of 6 variables.

- All the summary statistics: Collapse one variable but compute all available
  summary statistics, including 4 percentiles.

I run each style of benchmark under two settings:

- Large number of observations and small number of groups.

- Sma number of observations and large number of groups.

### Group IDs (`egen`)

We benchmark `gegen id = group(varlist)` vs egen and fegen, obs = 10,000,000,
J = 10,000 (in seconds)

    | egen | fegen | gegen | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ---- | ----- | ----- | ----------- | ----------- | ---------------------------------------------------------- |
    | 19.7 |  4.58 |  1.31 |          15 |        3.48 | str_12                                                     |
    | 22.4 |  6.65 |  1.85 |        12.1 |        3.59 | str_12 str_32                                              |
    | 24.1 |  8.23 |  2.22 |        10.9 |        3.71 | str_12 str_32 str_4                                        |
    | 19.8 |  3.35 |  .819 |        24.2 |         4.1 | double1                                                    |
    | 20.3 |  3.65 |  .915 |        22.2 |        3.99 | double1 double2                                            |
    | 19.9 |  3.65 |  1.06 |        18.7 |        3.43 | double1 double2 double3                                    |
    | 17.4 |  1.93 |  .636 |        27.4 |        3.04 | int1                                                       |
    | 18.4 |   2.2 |  .732 |        25.2 |        3.01 | int1 int2                                                  |
    | 20.1 |  2.59 |   1.1 |        18.2 |        2.35 | int1 int2 int3                                             |
    | 19.6 |     . |  1.62 |        12.1 |           . | int1 str_32 double1                                        |
    | 21.4 |     . |  2.29 |        9.36 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 23.5 |     . |  2.84 |        8.27 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

`gegen` 8-27 times faster than `egen` and 2-4 times faster than `fegen`.

### `levelsof`

Benchmark vs levelsof, obs = 10,000,000, J = 100 (in seconds)

    | levelsof | flevelsof | glevelsof | ratio (i/g) | ratio (f/g) | varlist |
    | -------- | --------- | --------- | ----------- | ----------- | ------- |
    |     21.8 |      8.25 |      2.14 |        10.2 |        3.86 | str_12  |
    |     21.7 |      8.67 |      2.49 |        8.72 |        3.48 | str_32  |
    |     21.6 |      7.69 |      1.64 |        13.2 |        4.68 | str_4   |
    |      3.9 |      5.63 |      .807 |        4.83 |        6.98 | double1 |
    |      3.4 |      5.51 |      .895 |         3.8 |        6.16 | double2 |
    |     2.39 |      5.56 |      .729 |        3.27 |        7.63 | double3 |
    |      3.5 |      .564 |      .409 |        8.56 |        1.38 | int1    |
    |     1.32 |      .608 |       .46 |        2.87 |        1.32 | int2    |
    |     1.65 |       6.4 |      .448 |        3.67 |        14.3 | int3    |

`int3` includes extended missing values, which explains the larger discrepancy.

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

    | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ---- | ----- | ----- | ----------- | ----------- | -------                                                    |
    | 38.7 |  25.3 |  2.04 |          19 |        12.4 | str_12                                                     |
    | 43.4 |  30.6 |  2.54 |        17.1 |          12 | str_12 str_32                                              |
    | 46.2 |  34.9 |  2.84 |        16.2 |        12.3 | str_12 str_32 str_4                                        |
    |   31 |  15.6 |     2 |        15.5 |        7.79 | double1                                                    |
    | 33.2 |  15.9 |  1.98 |        16.7 |           8 | double1 double2                                            |
    | 33.5 |  16.6 |  1.94 |        17.3 |        8.56 | double1 double2 double3                                    |
    | 30.6 |    15 |  1.35 |        22.6 |        11.1 | int1                                                       |
    | 32.3 |  15.4 |   1.3 |        24.8 |        11.9 | int1 int2                                                  |
    | 34.3 |  16.3 |   2.2 |        15.6 |        7.42 | int1 int2 int3                                             |
    | 39.3 |     . |   2.6 |        15.1 |           . | int1 str_32 double1                                        |
    |   47 |     . |  3.08 |        15.3 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 51.3 |     . |  3.52 |        14.6 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

Benchmark on Stata/IC vs isid and fisid, obs = 10,000,000, J = 10,000 (in seconds)

    | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ---- | ----- | ----- | ----------- | ----------- | ---------------------------------------------------------- |
    | 16.9 |  9.15 |   1.3 |        12.9 |        7.01 | str_12                                                     |
    | 17.3 |  13.6 |  1.59 |        10.8 |        8.51 | str_12 str_32                                              |
    | 18.6 |  16.2 |  1.87 |        9.92 |        8.67 | str_12 str_32 str_4                                        |
    |   15 |  6.19 |  1.09 |        13.7 |        5.68 | double1                                                    |
    | 15.5 |     7 |  1.24 |        12.5 |        5.66 | double1 double2                                            |
    | 14.3 |  8.43 |  1.28 |        11.1 |        6.58 | double1 double2 double3                                    |
    | 14.7 |  2.49 |  .475 |          31 |        5.24 | int1                                                       |
    | 14.8 |  2.84 |  .847 |        17.5 |        3.35 | int1 int2                                                  |
    | 16.4 |  7.97 |  1.29 |        12.7 |        6.17 | int1 int2 int3                                             |
    | 16.5 |     . |  1.63 |        10.1 |           . | int1 str_32 double1                                        |
    | 17.8 |     . |  2.44 |        7.28 |           . | int1 str_32 double1 int2 str_12 double2                    |
    | 19.6 |     . |  2.55 |        7.67 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

### `unique`

Benchmark vs unique and a prototype function from ftools to mimic unique. obs = 10,000,000;
all calls include an index to ensure uniqueness.

    | unique | funique | gunique | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ------ | ------- | ------- | ----------- | ----------- | ---------------------------------------------------------- |
    |   34.5 |     110 |    4.06 |        8.48 |          27 | str_12                                                     |
    |   38.5 |     176 |    4.94 |         7.8 |        35.7 | str_12 str_32                                              |
    |   46.5 |     139 |    4.97 |        9.34 |          28 | str_12 str_32 str_4                                        |
    |   32.2 |    31.3 |     2.5 |        12.9 |        12.5 | double1                                                    |
    |   34.1 |    31.5 |    2.67 |        12.8 |        11.8 | double1 double2                                            |
    |   35.9 |    32.8 |    2.73 |        13.1 |          12 | double1 double2 double3                                    |
    |   31.8 |    30.3 |    1.17 |        27.1 |        25.8 | int1                                                       |
    |   34.6 |    32.1 |    1.43 |        24.1 |        22.4 | int1 int2                                                  |
    |   35.9 |      34 |     1.7 |        21.2 |        20.1 | int1 int2 int3                                             |
    |   41.1 |       . |    4.76 |        8.63 |           . | int1 str_32 double1                                        |
    |   47.6 |       . |    6.11 |        7.79 |           . | int1 str_32 double1 int2 str_12 double2                    |
    |   52.6 |       . |    8.86 |        5.94 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

Benchmark vs unique, obs = 10,000,000, J = 10,000 (in seconds)

    | unique | funique | gunique | ratio (i/g) | ratio (f/g) | varlist                                                    |
    | ------ | ------- | ------- | ----------- | ----------- | ---------------------------------------------------------- |
    |   19.5 |    9.85 |    3.15 |        6.17 |        3.12 | str_12                                                     |
    |   21.8 |      15 |    3.84 |        5.67 |        3.92 | str_12 str_32                                              |
    |   24.5 |    16.9 |    3.83 |        6.39 |        4.42 | str_12 str_32 str_4                                        |
    |   18.8 |    5.94 |    1.28 |        14.6 |        4.62 | double1                                                    |
    |   19.5 |    7.13 |    1.56 |        12.5 |        4.56 | double1 double2                                            |
    |   20.2 |    7.59 |    1.55 |        13.1 |        4.91 | double1 double2 double3                                    |
    |   17.1 |    2.16 |    .482 |        35.5 |        4.49 | int1                                                       |
    |   19.5 |    2.44 |    .885 |        22.1 |        2.75 | int1 int2                                                  |
    |   20.7 |    7.63 |    1.06 |        19.6 |        7.22 | int1 int2 int3                                             |
    |   21.5 |       . |    3.27 |        6.57 |           . | int1 str_32 double1                                        |
    |     24 |       . |    4.03 |        5.95 |           . | int1 str_32 double1 int2 str_12 double2                    |
    |     27 |       . |    4.75 |        5.69 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

### Hash sort

Benchmark vs gsort, obs = 1,000,000, J = 10,000 (in seconds; datasets are compared via cf)

    | gsort | hashsort | ratio (g/h) | varlist                                                        |
    | ----- | -------- | ----------- | -------------------------------------------------------------- |
    |  1.24 |     .598 |        2.07 | -str_12                                                        |
    |  2.27 |     .796 |        2.86 | str_12 -str_32                                                 |
    |   3.6 |     .741 |        4.86 | str_12 -str_32 str_4                                           |
    |  1.26 |     .487 |        2.58 | -double1                                                       |
    |  2.06 |     .486 |        4.24 | double1 -double2                                               |
    |  3.31 |     .532 |        6.23 | double1 -double2 double3                                       |
    |  .946 |     .402 |        2.35 | -int1                                                          |
    |   1.6 |     .437 |        3.67 | int1 -int2                                                     |
    |  2.43 |     .597 |        4.07 | int1 -int2 int3                                                |
    |  4.43 |     .711 |        6.23 | -int1 -str_32 -double1                                         |
    |     7 |       .8 |        8.75 | int1 -str_32 double1 -int2 str_12 -double2                     |
    |    14 |     .917 |        15.3 | int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3 |

Benchmark vs sort, obs = 10,000,000, J = 10,000 (in seconds; datasets are compared via cf)

    |  sort | fsort | hashsort | ratio (g/h) | ratio (f/h) | varlist                                                    |
    | ----- | ----- | -------- | ----------- | ----------- | ---------------------------------------------------------- |
    |  17.8 |  14.7 |     7.07 |        2.52 |        2.08 | str_12                                                     |
    |    22 |  18.3 |     8.46 |         2.6 |        2.16 | str_12 str_32                                              |
    |  28.1 |  20.6 |     8.97 |        3.13 |         2.3 | str_12 str_32 str_4                                        |
    |    21 |  12.6 |     8.37 |        2.51 |        1.51 | double1                                                    |
    |  23.6 |  14.5 |     8.87 |        2.66 |        1.64 | double1 double2                                            |
    |  24.1 |  16.8 |     8.82 |        2.73 |         1.9 | double1 double2 double3                                    |
    |  20.4 |  11.1 |     7.37 |        2.76 |        1.51 | int1                                                       |
    |  21.9 |  10.5 |      8.1 |        2.71 |        1.29 | int1 int2                                                  |
    |  22.8 |  12.9 |     7.62 |           3 |        1.69 | int1 int2 int3                                             |
    |  22.6 |     . |     8.34 |        2.71 |           . | int1 str_32 double1                                        |
    |  24.2 |     . |     7.71 |        3.13 |           . | int1 str_32 double1 int2 str_12 double2                    |
    |  32.1 |     . |     10.3 |        3.11 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3 |

The above speed gains only hold when sorting groups.

Building
--------

### Requirements

If you want to compile the plugin yourself, you will need

- The GNU Compiler Collection (`gcc`)
- [`premake5`](https://premake.github.io)
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)
- v2.0 or above of the [Stata Plugin Interface](https://stata.com/plugins/version2) (SPI).

I keep a copy of Stata's Plugin Interface in this repository, and I have added
`centaurean`'s implementation of SpookyHash as a submodule.  However, you will
have to make sure you have `gcc` and `premake5` installed and in your system's
`PATH`.

On OSX, yu can get `gcc` and `make` from xcode. On windows, you will need

- [Cygwin](https://cygwin.com) with gcc, make, libgomp, x86_64-w64-mingw32-gcc-5.4.0.exe
  (Cygwin is pretty massive by default; I would install only those packages).

If you also want to compile SpookyHash on windows yourself, you will also need

- [Microsoft Visual Studio](https://www.visualstudio.com) with the
  Visual Studio Developer Command Prompt (again, this is pretty massive
  so I would recommend you install the least you can to get the
  Developer Prompt).

I keep a copy of `spookyhash.dll` in `./lib/windows` so there is no need to
re-compile SpookyHash.

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

Again, I advise against trying to re-compile SpookyHash. Just use the
dll provided in this repo.

FAQs
----

### What functions are available with `gegen` and `gcollapse`?

`gegen` and `gcollapse` should be able to replicate almost all of the
functionality of their Stata counterparts. The following are impemented
internally in C:

    | Function    | gcollapse | gegen   |
    | ----------- | --------- | ------- |
    | tag         |           |   X     |
    | group       |           |   X     |
    | total       |           |   X     |
    | sum         |     X     |   X     |
    | mean        |     X     |   X     |
    | sd          |     X     |   X     |
    | max         |     X     |   X     |
    | min         |     X     |   X     |
    | count       |     X     |   X     |
    | median      |     X     |   X     |
    | iqr         |     X     |   X     |
    | percent     |     X     |   X     |
    | first       |     X     |   X (+) |
    | last        |     X     |   X (+) |
    | firstnm     |     X     |   X (+) |
    | lastnm      |     X     |   X (+) |
    | semean      |     X     |   X     |
    | sebinomial  |     X     |   X     |
    | sepoisson   |     X     |   X     |
    | percentiles |     X     |   X     |

<small>(+) first, last, firstmn, and lastnm are different from their counterparts
in the `egenmore` package and, instead, they are analogous to the `gcollapse`
counterparts.</small>

The percentile syntax mimics that of `collapse` and `egen`, with the addition
that quantiles are also supported. That is,

```stata
gcollapse (p#) target = var [target = var ...] , by(varlist)
gegen target = pctile(var), by(varlist) p(#)
```

where # is a "percentile" with arbitrary decimal places (e.g. 2.5 or 97.5).
Last, when `gegen` calls a function that is not implemented internally by
`gtools`, it will hashe the by variables and call `egen` with `by` set to an
id based on the hash. That is, if `fcn` is not one of the functions above,

```stata
gegen outvar = fcn(varlist) [if] [in], by(byvars)
```

would be the same as
```stata
hashsort byvars, group(id)
egen outvar = fcn(varlist) [if] [in], by(id)
```

but preserving the original sort order.

### Important differences from Stata counterparts

From `collapse`

- `gcollapse, merge` merges the collapsed data set back into memory. This is
  much faster than collapsing a dataset, saving, and merging after. However,
  Stata's `merge ..., update` functionality is not implemented, only replace.
  (If the targets exist the function will throw an error without `replace`).
- `gcollapse, labelformat` allows specifying the output label using placeholders.
- No support for weights.
- `rawsum` is not supported.

From `egen`

- `gegen` upgrades the type of the target variable if it is not specified by
  the user. This means that if the sources are `double` then the output will
  be double. All sums are double. `group` creates a `long` or a `double`. And
  so on. `egen` will default to the system type, which could cause a loss of
  precision on some functions.
- While `gegen` is much faster for `tag`, `group`, and summary stats, most
  egen function are not implemented internally, meaning for arbitrary `gegen`
  calls this is a wrapper for hashsort and egen.
- `group` label options are not supported
- You can specify a varlist as the source, not just a single variable. Observations
  will be pooled by row in that case.

From `levelsof`

- It can take a `varlist` and not just a `varname`; in that case it prints
  all unique combinations of the varlist. The user can specify column and row
  separators.

From `isid`

- It can also check IDs with `if` and `in` conditions.
- No support for `using`. The C plugin API does not allow to load a Stata
  dataset from disk.
- Option `sort` is not available.

### Why can't the functions do weights?

I have never used weights in Stata, so I will have to read up on how weights
are implemented before adding that option to `gcollapse` and `gegen`.

### Warning on using the Stata GUI

When Stata is executing the plugin, the user will not be able to interact
with the Stata GUI. Because of this, Stata may appear unresponsive when it is
merely executing the plugin.

There is at least one known instance where this can cause a confusion for
the user: If the system runs out of RAM, the program will attempt to use the
pagefile/swap space. In doing, so, Stata may appear frozen (it may show a
"(Not Responding)" message on Windows or it may darken on *nix systems).

The program has not crashed; it is merely trying to swap memory.  To
check this is the case, the user can monitor disk activity or monitor the
pagefile/swap space directly.

### Why use platform-dependent plugins?

C is fast! When optimizing stata, there are three options:

- Mata (already implemented)
- Java plugins (I don't like Java)
- C and C++ plugins

Sergio Correa's `ftools` tests the limits of mata and achieves excellent
results, but Mata cannot compare to the raw speed a low level language like
C would afford. The only question is whether the overhead reading and writing
data to and from C compensates the speed gain, and in this case it does.

### Why no multi-threading?

Multi-threading is really difficult to support, specially because I could
not figure out a cross-platform way to implement multi-threading. Perhaps if
I had access to physical Windows and OSX hardware I would be able to do it,
but I only have access to Linux hardware. And even then the multi-threading
implementation that worked on my machine broke the plugin on older systems.

Perhaps I will come back to multi-threading in the future. For now only the
single-threaded version is available, and that is already a massive speedup!

### My computer has a 32-bit CPU

This uses 128-bit hashes split into 2 64-bit parts. As far as I know, it
will not work with a 32-bit processor. If you try to force it to run,
you will almost surely see integer overflows and pretty bad errors.

### How can this be faster?

As I understand it, many of Stata's underpinnings are already compiled C
code. However, there are two explanations why this is faster than Stata's
native commands:

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
sorting algorithms. (Note with a 128-bit algorithm using a counting sort is
prohibitively expensive; `gcollapse` actually does 4 passes of a counting
sort, each sorting 16 bits at a time; if the groups are not unique after
sorting on the first 64 bits we sort on the full 128 bits.)

Given `K` by variables, `by_1` to `by_K`, where `by_k` belongs the set `B_k`,
the general problem is to devise a function `f` such that `f:  B_1 x ... x
B_K -> N`, where `N` are the natural (whole) numbers. Given `B_k` can be
integers, floats, and strings, the natural way of doing this is to use a
hash: A function that takes an arbitrary sequence of data and outputs data of
fixed size.

In particular I use the [Spooky Hash](http://burtleburtle.net/bob/hash/spooky.html)
devised by Bob Jenkins, which is a 128-bit hash. Stata caps observations
at 20 billion or so, meaning a 128-bit hash collision is _de facto_ impossible.
Nevertheless, the function does check for hash collisions and will fall back
on `collapse` and `egen` when it encounters a collision. An internal
mechanism for resolving potential collisions is in the works. See [issue
2](https://github.com/mcaceresb/stata-gtools/issues/2) for a discussion.

### Memory management with gcollapse

C cannot create or drop variables. This creates a problem for `gcollapse` when
N is large and the number of groups J is small. For examplle, N = 100M means
about 800MiB per variable and J = 1,000 means barely 8KiB per variable. Adding
variables after the collapse is trivial and before the collapse it may take
several seconds.

The function tries to be smart about this: Variables are only created if the
source variable cannot be replaced with the target. This conserves memory and
speeds up execution time. (However, the function currently recasts unsuitably
typed source variables, which saves memory but may slow down execution time.)

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

- [ ] Minimize memory use.
- [ ] Improve coverage of debug checks.
- [ ] Option `smart` to check if variables are sorted.
- [ ] Option `freq` to add obs count for each group.
- [ ] Option `greedy` to give user fine-grain control over gcollapse internals.
- [ ] Provide `sumup` and `sum` altetnative, `gsum`.
- [ ] Add `gtab` as a fast version of `tabulate` with a `by` option.
    - [ ] Also add functionality from `tabcustom`.
- [ ] Add support for weights.
- [ ] Add `Var`, `kurtosis`, `skewness`

License
-------

Gtools is [MIT-licensed](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE).
`./lib/spookyhash` and `./src/plugin/tools/quicksort.c` belong to their respective
authors and are BSD-licensed.
