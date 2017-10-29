<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

[Overview](#faster-stata-for-group-operations)
| [Installation](#installation)
| [Benchmarks](#collapse-benchmarks)
| [Building](#building)
| [FAQs](#faqs)
| [License](#license)

_Gtools_: Faster Stata for big data. This packages provides a hash-based
implementation of collapse, egen, isid, levelsof, and unique/distinct using C
plugins for a massive speed improvement.

`version 0.8.4 29Oct2017`
Builds: Linux [![Travis Build Status](https://travis-ci.org/mcaceresb/stata-gtools.svg?branch=develop)](https://travis-ci.org/mcaceresb/stata-gtools),
Windows (Cygwin) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/2bh1q9bulx3pl81p/branch/develop?svg=true)](https://ci.appveyor.com/project/mcaceresb/stata-gtools)

Faster Stata for Group Operations
---------------------------------

This package's aim is to provide a fast implementation of group commands in
Stata using hashes and C plugins. This includes (benchmarked using Stata/IC):

| Function    | Replaces        | Speedup (IC)      | Unsupported     | Extras                           |
| ----------- | --------------- | ----------------- | --------------- | -------------------------------- |
| `gcollapse` | `collapse`      |  9 to 300 (+)     | Weights         | Quantiles, `merge`, label output |
| `gegen`     | `egen`          |  9 to 26 (+, .)   | Weights, labels | Quantiles                        |
| `gisid`     | `isid`          |  8 to 30          | `using`, `sort` | `if`, `in`                       |
| `glevelsof` | `levelsof`      |  3 to 13          |                 | Multiple variables               |
| `gunique`   | `unique`        |  4 to 26          | `by`            |                                  |
| `gdistinct` | `distinct`      |  4 to 26          |                 |                                  |

<small>Commands were benchmarked on a Linux laptop with Stata/IC; gains in Stata/MP are smaller.</small>

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

| Function    | Replaces        | Speedup (IC) | Unsupported | Extras               |
| ----------- | --------------- | ------------ | ----------- | -------------------- |
| `hashsort`  | `sort`          | 2.5 to 4     |             | Group (hash) sorting |
|             | `gsort`         | 2 to 18      | `mfirst`    | Sorts are stable     |

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
| `gcollapse` | `fcollapse`     | 2-9 (+)     |
| `gegen`     | `fegen`         | 2.5-4 (.)   |
| `gisid`     | `fisid`         | 4-14        |
| `glevelsof` | `flevelsof`     | 1.5-13      |
| `hashsort`  | `fsort`         | 2.5-4       |

<small>(+) Pervious benchmarks of `gcollapse` showed larger speed gains
in part due to mulit-threading, which has been removed as of `0.8.0`, and
in part because the old benchmarks were more favorable to `gcollapse`;
in the old benchmarks, the speed gain is still 3-23, even without
multi-threading. See `./src/test/gtools_benchmarks_old.log`</small>

<small>(.) Only `egen group` was benchmarked rigorously.</small>

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
gcollapse (mean) mean = price (median) median = gear_ratio, by(make) merge v
gcollapse (p97.5) mpg (iqr) headroom, by(foreign rep78) benchmark
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
gcollapse (mean) mean_pr = price (median) median_gr = gear_ratio, by(foreign) merge
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
capture program drop my_pretty_stat
program my_pretty_stat, rclass
         if ( `"`0'"' == "sum"  ) local prettystat "Total"
    else if ( `"`0'"' == "mean" ) local prettystat "Average"
    else {
        local prettystat "#default#"
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

Note in this case `sd` does not appear in the result's label because the
`#stat#` placeholder does not appear.

Benchmarks
----------

Benchmarks were performed on a laptop running Linux:

    Program:   Stata/IC 13.1 (1 core)
    OS:        x86_64 GNU/Linux
    Processor: Intel(R) Core(TM) i7-6500U CPU @ 2.50GHz
    Cores:     2 cores and 2 virtual threads per core.
    Memory:    15GiB
    Swap:      15GiB

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

- Large number of observations and large number of groups.

`gcollapse` ~9-300 times faster than `collapse` and ~2-9 times faster than `fcollapse`.

_**Small J:**_

Benchmark vs collapse (all times in seconds)

- obs:     10,000,000
- groups:  100
- options: fast

Simple stats, many variables:

- vars:    x1-x15 ~ N(0, 10)
- stats:   sum

| collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|     31.9 |      8.55 |      3.45 |        9.24 |        2.48 |
|     93.3 |      16.1 |      4.97 |        18.8 |        3.24 | str_12 str_32 str_4
|     72.2 |      10.6 |      3.36 |        21.5 |        3.14 | double1 double2 double3
|     72.7 |      11.3 |      3.81 |        19.1 |        2.96 | int1 int2 int3
|     89.4 |         . |      4.33 |        20.7 |           . | int1 str_32 double1

Modestly complex stats, a few variables:

- vars:    x1-x6 ~ N(0, 10)
- stats:   mean median min max

| collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|      562 |      45.3 |      2.06 |         273 |          22 |
|      826 |      23.5 |      3.75 |         220 |        6.28 | str_12 str_32 str_4
|     97.6 |      17.7 |      2.58 |        37.9 |        6.88 | double1 double2 double3
|     97.5 |      18.1 |      2.68 |        36.4 |        6.77 | int1 int2 int3
|      107 |         . |      3.33 |        32.1 |           . | int1 str_32 double1

Very compex stats, one variable:

- vars:    x1 ~ N(0, 10)
- stats:   all available plus percentiles 10, 30, 70, 90

| collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|      344 |      42.8 |      1.31 |         262 |        32.7 |
|      897 |      21.2 |      3.08 |         291 |        6.88 | str_12 str_32 str_4
|      626 |      15.5 |      1.95 |         321 |        7.98 | double1 double2 double3
|      579 |      15.6 |      1.95 |         297 |        8.01 | int1 int2 int3
|      699 |         . |      2.67 |         261 |           . | int1 str_32 double1

_**Large J:**_

Benchmark vs collapse (all times in seconds)

- obs:     10,000,000
- groups:  1,000,000
- options: fast

Simple stats, many variables:

- vars:    x1-x15 ~ N(0, 10)
- stats:   sum

| collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|     28.2 |      8.91 |      2.75 |        10.3 |        3.24 |
|      112 |      68.5 |      7.37 |        15.2 |         9.3 | str_12 str_32 str_4
|     87.7 |      13.6 |      6.38 |        13.8 |        2.13 | double1 double2 double3
|     65.8 |      12.2 |       4.2 |        15.6 |         2.9 | int1 int2 int3
|      109 |         . |      6.15 |        17.7 |           . | int1 str_32 double1

Modestly complex stats, a few variables:

- vars:    x1-x6 ~ N(0, 10)
- stats:   mean median min max

| collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|      715 |      52.7 |      1.89 |         378 |        27.8 |
|      756 |      50.1 |      6.15 |         123 |        8.13 | str_12 str_32 str_4
|      151 |      41.2 |      5.32 |        28.4 |        7.74 | double1 double2 double3
|      588 |      20.8 |      3.85 |         153 |        5.41 | int1 int2 int3
|      162 |         . |      5.97 |        27.1 |           . | int1 str_32 double1

Very compex stats, one variable:

- vars:    x1 ~ N(0, 10)
- stats:   all available plus percentiles 10, 30, 70, 90

| collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|      324 |      51.6 |       1.3 |         249 |        39.6 |
|      930 |      43.7 |      5.68 |         164 |         7.7 | str_12 str_32 str_4
|      686 |      35.6 |      3.97 |         173 |        8.97 | double1 double2 double3
|      640 |      18.7 |      2.86 |         224 |        6.55 | int1 int2 int3
|      848 |         . |      5.22 |         163 |           . | int1 str_32 double1

### Group IDs (`egen`)

We benchmark `gegen id = group(varlist)` vs egen and fegen, obs = 10,000,000,
J = 10,000 (in seconds)

 | egen | fegen | gegen | ratio (e/g) | ratio (f/g) | varlist
 | ---- | ----- | ----- | ----------- | ----------- | -------
 | 22.2 |   4.1 |  1.14 |        19.4 |         3.6 | str_12
 | 21.6 |  5.96 |  1.59 |        13.5 |        3.74 | str_12 str_32
 |   23 |  7.31 |  1.95 |        11.8 |        3.74 | str_12 str_32 str_4
 | 18.4 |  2.94 |  .813 |        22.6 |        3.61 | double1
 | 18.4 |  3.24 |  .883 |        20.9 |        3.67 | double1 double2
 | 19.1 |  3.36 |  .945 |        20.2 |        3.56 | double1 double2 double3
 | 16.6 |  1.84 |  .634 |        26.2 |        2.91 | int1
 | 18.3 |  2.05 |  .735 |        24.9 |        2.79 | int1 int2
 | 19.6 |  2.53 |  .895 |        21.9 |        2.83 | int1 int2 int3
 | 20.2 |     . |  1.51 |        13.4 |           . | int1 str_32 double1
 |   22 |     . |  2.07 |        10.6 |           . | int1 str_32 double1 int2 str_12 double2
 | 24.1 |     . |  2.61 |        9.24 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

`gegen` ~9-26 times faster than `egen` and ~2.5-4 times faster than `fegen`.

### `isid`

Benchmark vs isid, obs = 10,000,000; all calls include an index to ensure uniqueness.

 | isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist
 | ---- | ----- | ----- | ----------- | ----------- | -------
 | 37.8 |  24.6 |  2.24 |        16.9 |          11 | str_12
 | 41.5 |  29.9 |   2.4 |        17.3 |        12.5 | str_12 str_32
 | 44.8 |    34 |  2.75 |        16.3 |        12.4 | str_12 str_32 str_4
 | 30.4 |  14.3 |  1.86 |        16.4 |        7.72 | double1
 | 31.6 |  14.9 |  1.95 |        16.2 |        7.63 | double1 double2
 | 32.7 |  15.1 |  2.01 |        16.3 |        7.49 | double1 double2 double3
 | 31.3 |  14.5 |  1.04 |        30.1 |        13.9 | int1
 | 32.6 |  15.1 |  1.25 |        26.1 |        12.1 | int1 int2
 | 34.1 |  15.4 |  2.04 |        16.7 |        7.57 | int1 int2 int3
 | 38.5 |     . |  2.35 |        16.4 |           . | int1 str_32 double1
 |   45 |     . |  2.91 |        15.4 |           . | int1 str_32 double1 int2 str_12 double2
 |   51 |     . |  3.29 |        15.5 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark vs isid, obs = 10,000,000, J = 10,000 (in seconds)

| isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist
| ---- | ----- | ----- | ----------- | ----------- | -------
| 16.2 |  8.35 |  1.15 |        14.1 |        7.25 | str_12
| 17.2 |  12.7 |  1.51 |        11.4 |        8.36 | str_12 str_32
| 18.6 |  14.9 |  1.74 |        10.7 |         8.6 | str_12 str_32 str_4
| 14.2 |  5.77 |  .972 |        14.6 |        5.94 | double1
| 14.5 |  6.88 |  1.16 |        12.5 |        5.95 | double1 double2
| 15.2 |  7.11 |  1.18 |        12.9 |        6.04 | double1 double2 double3
| 13.4 |  2.29 |  .397 |        33.6 |        5.77 | int1
| 14.8 |  2.61 |  .684 |        21.6 |        3.81 | int1 int2
| 15.7 |  7.25 |  1.17 |        13.5 |        6.22 | int1 int2 int3
| 16.1 |     . |  1.52 |        10.6 |           . | int1 str_32 double1
|   18 |     . |  1.98 |        9.09 |           . | int1 str_32 double1 int2 str_12 double2
| 19.8 |     . |  2.37 |        8.35 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

`gisid` ~8-30 times faster than `isid` and ~4-14 times faster than `fisid`.

### `levelsof`

Benchmark vs levelsof, obs = 10,000,000, J = 100 (in seconds)

| levelsof | flevelsof | glevelsof | ratio (l/g) | ratio (f/g) | varlist
| -------- | --------- | --------- | ----------- | ----------- | -------
|     21.7 |      7.86 |      2.04 |        10.7 |        3.86 | str_12
|     21.1 |      8.35 |      2.39 |        8.81 |         3.5 | str_32
|     21.9 |      7.42 |      1.64 |        13.3 |        4.53 | str_4
|     3.65 |      5.46 |      .825 |        4.43 |        6.62 | double1
|     3.19 |      5.52 |      .935 |        3.42 |         5.9 | double2
|     2.28 |       5.5 |      .742 |        3.07 |        7.41 | double3
|     3.43 |      .566 |      .394 |        8.71 |        1.44 | int1
|     1.29 |      .601 |      .435 |        2.97 |        1.38 | int2
|     1.48 |      5.67 |      .448 |        3.29 |        12.7 | int3

`int3` includes extended missing values, which explains the larger
discrepancy. glevelsof` ~3-13 times faster than `levelsof` and ~1.5-13
times `faster than `flevelsof`.

### `unique`

Benchmark vs unique and a prototype function from ftools to mimic unique. obs = 10,000,000;
all calls include an index to ensure uniqueness.

| unique | funique | gunique | ratio (u/g) | ratio (f/g) | varlist
| ------ | ------- | ------- | ----------- | ----------- | -------
|   35.6 |     108 |    4.43 |        8.04 |        24.3 | str_12
|   37.6 |     121 |    4.71 |        7.99 |        25.6 | str_12 str_32
|   39.8 |     133 |    5.37 |        7.42 |        24.8 | str_12 str_32 str_4
|   28.6 |    27.9 |    2.41 |        11.9 |        11.6 | double1
|     30 |    29.4 |    2.52 |        11.9 |        11.7 | double1 double2
|   31.3 |    30.6 |    2.52 |        12.4 |        12.1 | double1 double2 double3
|   29.3 |    27.8 |    1.12 |        26.1 |        24.7 | int1
|   30.8 |      30 |    1.39 |        22.1 |        21.5 | int1 int2
|     32 |    31.3 |    1.63 |        19.6 |        19.2 | int1 int2 int3
|     34 |       . |     4.1 |        8.28 |           . | int1 str_32 double1
|   39.5 |       . |    5.32 |        7.42 |           . | int1 str_32 double1 int2 str_12 double2
|   45.1 |       . |    6.15 |        7.32 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark vs unique, obs = 10,000,000, J = 10,000 (in seconds).

| unique | funique | gunique | ratio (i/g) | ratio (f/g) | varlist
| ------ | ------- | ------- | ----------- | ----------- | -------
|     16 |     8.2 |    2.96 |         5.4 |        2.77 | str_12
|   16.5 |    12.5 |    3.62 |        4.56 |        3.45 | str_12 str_32
|   18.4 |    14.6 |    3.64 |        5.05 |        4.02 | str_12 str_32 str_4
|   13.2 |    5.57 |    1.21 |        10.9 |         4.6 | double1
|   13.6 |    6.61 |    1.58 |        8.65 |        4.19 | double1 double2
|     14 |    6.94 |    1.62 |        8.61 |        4.28 | double1 double2 double3
|   12.3 |     2.1 |    .418 |        29.5 |        5.01 | int1
|   13.3 |     2.4 |    .841 |        15.9 |        2.85 | int1 int2
|   14.6 |    7.11 |    1.06 |        13.8 |        6.71 | int1 int2 int3
|   15.2 |       . |    3.37 |         4.5 |           . | int1 str_32 double1
|   17.5 |       . |    4.35 |        4.02 |           . | int1 str_32 double1 int2 str_12 double2
|   19.6 |       . |    5.05 |        3.88 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

`gunique` ~4-26 times faster than `unique`, and ~3-25 times faster than
`funique`.  Note that `funique` is not an actual `ftools` command, but rather
a prototype that is found in their testing files.

### Hash sort

Benchmark vs gsort, obs = 1,000,000, J = 10,000 (in seconds; datasets are compared via cf)

| gsort | hashsort | ratio (g/h) | varlist
| ----- | -------- | ----------- | -------
|  1.11 |     .501 |        2.21 | -str_12
|  1.89 |     .603 |        3.13 | str_12 -str_32
|  3.05 |     .629 |        4.84 | str_12 -str_32 str_4
|  .895 |     .355 |        2.52 | -double1
|  1.55 |     .372 |        4.17 | double1 -double2
|   2.4 |     .376 |        6.38 | double1 -double2 double3
|  .795 |     .298 |        2.67 | -int1
|  1.28 |     .318 |        4.02 | int1 -int2
|     2 |     .382 |        5.24 | int1 -int2 int3
|  3.46 |      .57 |        6.08 | -int1 -str_32 -double1
|  5.13 |     .621 |        8.26 | int1 -str_32 double1 -int2 str_12 -double2
|  16.3 |     .875 |        18.6 | int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3

Benchmark vs sort, obs = 10,000,000, J = 10,000 (in seconds; datasets are compared via cf)

| sort | fsort | hashsort | ratio (s/h) | ratio (f/h) | varlist
| ---- | ----- | -------- | ----------- | ----------- | -------
| 14.4 |  11.7 |     4.78 |        3.02 |        2.45 | str_12
| 20.3 |  12.7 |     7.05 |        2.87 |        1.81 | str_12 str_32
| 22.4 |  15.5 |     7.45 |           3 |        2.08 | str_12 str_32 str_4
| 15.8 |  9.59 |     6.35 |        2.49 |        1.51 | double1
| 16.8 |  10.2 |     4.41 |        3.82 |        2.31 | double1 double2
|   18 |  10.1 |     5.92 |        3.04 |        1.71 | double1 double2 double3
| 15.7 |  8.84 |     5.52 |        2.85 |         1.6 | int1
| 17.3 |   8.7 |     3.98 |        4.35 |        2.19 | int1 int2
| 18.9 |  10.6 |     5.92 |        3.18 |        1.79 | int1 int2 int3
| 19.4 |     . |     6.44 |        3.02 |           . | int1 str_32 double1
| 22.9 |     . |     6.36 |         3.6 |           . | int1 str_32 double1 int2 str_12 double2
| 29.6 |     . |     8.56 |        3.46 |           . | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

The above speed gains only hold when sorting groups. `hashsort` ~2-18 times
faster than `gsort`, 2.5-4 times faster than `sdort`, and ~1.5-2.5 times
faster than `fsort`.

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

Basically my version of OpenMP, which is what I'd normally use, does not play
nice with Stata's plugin interface or with older Linux versions.  Perhaps
I will come back to multi-threading in the future, but for now only the
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
