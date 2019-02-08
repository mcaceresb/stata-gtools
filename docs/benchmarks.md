Benchmarks
==========

!!! info "Note"
    The majority of these benchmarks were compiled using `gtools-0.8.0`.
    The current version of gtools should be faster, specially on Linux
    systems, and includes commands not listed here (notably greshape and
    gstats winsor). Updated benchmarks are forthcomming.

Hardware
--------

Stata/IC benchmarks were run on a Linux laptop.

```
Program:   Stata/IC 13.1 (1 core)
OS:        x86_64 GNU/Linux
Processor: Intel(R) Core(TM) i7-6500U CPU @ 2.50GHz
Cores:     2 cores and 2 virtual threads per core.
Memory:    15GiB
Swap:      15GiB
```

Stata/MP benchmarks were run on a Linux setver with 8 cores.

```
Program:   Stata/MP 14.2 (8 cores)
OS:        x86_64 GNU/Linux
Processor: Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.40GHz
Cores:     2 sockets with 6 cores per socket and 2 virtual threads per core.
Memory:    62GiB
Swap:      119GiB
```

Summary
-------

### Versus native equivalents

| Function     | Versus        | Speedup (IC)    | Speedup (MP) |
| ------------ | ------------- | --------------- | ------------ |
| gcollapse    | collapse      |  9 to 300       |  4 to 120    |
| gcontract    | contract      |  5 to 7         |  2.5 to 4    |
| gegen        | egen          |  9 to 26 (+)    |  4 to 9 (+)  |
| gisid        | isid          |  8 to 30        |  4 to 14     |
| glevelsof    | levelsof      |  3 to 13        |  2.5 to 7    |
| gquantiles   | xtile         |  10 to 30 (-)   | 13 to 25     |
|              | pctile        |  13 to 38 (-)   | 2.5 to 5.5   |
|              | \_pctile      |  25 to 40       | 3 to 5       |

<small>(+) Only 'egen group' was benchmarked.</small>

<small>(-) Benchmarks computed 10 quantiles. When computing a large
number of quantiles (e.g. thousands) `pctile` and `xtile` are prohibitively
slow due to the way they are written; in that case gquantiles is hundreds
or thousands of times faster.</small>

In the case of gcollapse, the upper end of the speed improvements are for
quantiles (e.g. median, iqr, p90) and few groups. There `gcollapse` really can
be hundreds of times faster.

The reason is that Stata's algorithm for computing percentiles
sorts the source variables _every time_ a percentile is to
be computed. `gcollapse` (and `gegen`), by contrast, use
[quickselect](https://en.wikipedia.org/wiki/Quickselect), which is very
efficient. While its average complexity is O(N log N), like quicksort, it
can run in up to linear time, O(N).  In practice it is much faster than
quicksort and, since it modifies the data in place, subsequent calls to compute
percentiles run much faster.

### Versus SSC/SJ equivalents

| Function     | Versus             | Speedup (IC)    | Speedup (MP)    |
| ------------ | ------------------ | --------------- | --------------- |
| fasterxtile  | fastxtile (SSC)    |  20 to 30       |  2.5 to 3.5     |
|              | egenmisc (SSC) (-) |  8 to 25        |  2.5 to 6       |
|              | astile (SSC) (-)   |  8 to 12        |  3.5 to 6       |
| gunique      | unique (SSC)       |  4 to 26        |  4 to 12        |
| gdistinct    | distinct (SJ)      |  4 to 26        |  4 to 12        |
| gtoplevelsof | gcontract (Gtools) |  1.5 to 6       |  2 to 6.5       |

<small>(-) `fastxtile` from egenmisc and `astile` were benchmarked against
`gquantiles, xtile` (`fasterxtile`) using `by()`.</small>

`gtoplevelsof` does not quite have an equivalent in SSC/SJ. The command
`groups` with the `select` option is very similar, but it is dozens of
times slower then `gtoplevelsof` when the data is large (millions of
rows). This seems to be mainly because `groups` is not written as a way
to quickly see the top groups of a data set, and it offers relatively
different functionality (and more options).  Hence I felt the comparison
might be unfair.

Note that `fasterxtile` is merely an alias for `gquantiles, xtile`.

### Versus ftools

The commands here are also faster than the commands provided by `ftools`;
further, `gtools` commands take a mix of string and numeric variables,
which is a limitation of `ftools`. (Note I could not get several parts
of `ftools` working on the Linux server where I have access to Stata/MP.)

| Gtools      | Ftools          | Speedup (IC) |
| ----------- | --------------- | ------------ |
| gcollapse   | fcollapse       | 2-9 (+)      |
| gegen       | fegen           | 2.5-4 (.)    |
| gisid       | fisid           | 4-14         |
| glevelsof   | flevelsof       | 1.5-13       |
| hashsort    | fsort           | 2.5-4        |

<small>(+) A older set of benchmarks showed larger speed gains in part due to
mulit-threading, which has been removed as of '0.8.0', and in part because the
old benchmarks were more favorable to gcollapse; in the old benchmarks, the
speed gain is still 3-23, even without multi-threading. See the [old collapse
benchmarks](#old-collapse-benchmarks)</small>

<small>(.) Only 'egen group' was benchmarked rigorously.</small>

### Versus sort

I have implemented a hash-based sorting command, `hashsort`. While at times
this is faster than Stata's `sort`, it can also often be slower:

| Function    | Versis   | Speedup (IC) | Speedup (MP)   |
| ----------- | -------- | ------------ | -------------- |
| hashsort    | sort     | 2.5 to 4     |  0.8 to 1.3    |
|             | gsort    | 2 to 18      |  1 to 6        |

The benchmarks were run with few groups relative to the number of
observations. We can see that, while `hashsort` is clearly faster in this
scenario in Stata/IC, it is only sometimes faster in Stata/MP.  Hence it is
considered an experimental command.

Random data used
----------------

We create a data set with the number of groups we want and expand it to
10M (10,000,000) observations.  Each benchmark indicates how many groups
J there are. (This means that we created a dataset with J observations
and used `extend` with 10M / J as the argument.)

This ensures there are J groups for any given sorting arrangement. Variables
are self-descriptive, so "str_32" is a string with 32 characters. "double2" is
a double. And so on.

String variables were concatenated from a mix of fixed and random strings
using the `ralpha` package. All variables include missing values. `int3` and
`double3` include extended missing values. `int3` is typed as double but all
non-missing entries are integers. The output from desc is:

```stata
. desc

Contains data
  obs:    10,000,000
 vars:            12
 size:   560,000,000
------------------------------------------------------------
              storage   display    value
variable name   type    format     label      variable label
------------------------------------------------------------
str_long        str5    %9s
str_mid         str3    %9s
str_short       str3    %9s
str_32          str32   %32s
str_12          str12   %12s
str_4           str11   %11s
int1            long    %12.0g
int2            long    %12.0g
int3            double  %10.0g
double1         double  %10.0g
double2         double  %10.0g
double3         double  %10.0g
------------------------------------------------------------
Sorted by:
     Note:  dataset has changed since last saved
```

Stata/IC Benchmarks
-------------------

### gcollapse

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

### gcontract

This is 5 to 7 times faster than contract.  Benchmark vs contract, obs =
10,000,000, J = 10,000 (in seconds).

| contract | gcontract | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|     15.9 |      2.36 |        6.75 | str_12
|     16.4 |      3.16 |         5.2 | str_12 str_32
|       18 |      3.29 |        5.46 | str_12 str_32 str_4
|     13.9 |      1.95 |        7.14 | double1
|     14.1 |      2.09 |        6.76 | double1 double2
|     14.1 |      2.28 |        6.19 | double1 double2 double3
|     12.3 |      1.83 |        6.69 | int1
|     13.8 |         2 |        6.88 | int1 int2
|     15.2 |      2.21 |        6.88 | int1 int2 int3
|     15.3 |      2.89 |        5.31 | int1 str_32 double1
|       17 |      3.82 |        4.45 | int1 str_32 double1 int2 str_12 double2
|     19.4 |      4.07 |        4.76 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### Group IDs (gegen)

This is ~9 to 26 times faster than `egen` and ~3 to 4 times faster than `fegen`.
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

### gisid

`gisid` ~8-30 times faster than `isid` and ~4-14 times faster than `fisid`.
Benchmark vs isid, obs = 10,000,000; all calls include an index to ensure
uniqueness.

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

### gduplicates

`gduplicates` is 8-16 times faster than `duplicates`.
Benchmark vs duplicates report, obs = 10,000,000, J = 10,000 (in seconds)

| duplicates | gduplicates | ratio (g/h) | varlist
| ---------- | ----------- | ----------- | -------
|         74 |        7.87 |         9.4 | str_12
|       76.3 |        8.89 |        8.58 | str_12 str_32
|       77.8 |        9.13 |        8.52 | str_12 str_32 str_4
|       55.7 |        5.65 |        9.86 | double1
|       61.6 |        5.95 |        10.4 | double1 double2
|       59.4 |        5.98 |        9.94 | double1 double2 double3
|       67.7 |        4.37 |        15.5 | int1
|       69.9 |        5.25 |        13.3 | int1 int2
|         70 |         6.3 |        11.1 | int1 int2 int3
|       62.1 |        7.86 |         7.9 | int1 str_32 double1
|       70.1 |        9.41 |        7.45 | int1 str_32 double1 int2 str_12 double2
|       78.4 |        11.9 |        6.56 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark vs duplicates drop, obs = 10,000,000, J = 10,000
(in seconds; output compared via cf)

| duplicates | gduplicates | ratio (g/h) | varlist
| ---------- | ----------- | ----------- | -------
|       41.2 |        3.94 |        10.5 | str_12
|       44.9 |        4.79 |        9.39 | str_12 str_32
|       47.8 |        6.27 |        7.63 | str_12 str_32 str_4
|       34.1 |        2.18 |        15.6 | double1
|       36.6 |         2.5 |        14.6 | double1 double2
|       38.1 |        2.45 |        15.6 | double1 double2 double3
|       32.9 |        1.42 |        23.2 | int1
|       36.6 |        1.55 |        23.6 | int1 int2
|       39.8 |        2.63 |        15.2 | int1 int2 int3
|       41.5 |        4.47 |        9.27 | int1 str_32 double1
|       48.4 |        7.77 |        6.23 | int1 str_32 double1 int2 str_12 double2
|       57.7 |         6.7 |        8.61 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### glevelsof

glevelsof` ~3-13 times faster than `levelsof` and ~1.5-13 times `faster than
`flevelsof`.

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
discrepancy.

### gunique

`gunique` ~4-26 times faster than `unique`, and ~3-25 times faster than
`funique`.  Note that `funique` is not an actual `ftools` command, but rather
a prototype that is found in their testing files.  Benchmark vs unique and a
prototype function from ftools to mimic unique. obs = 10,000,000; all calls
include an index to ensure uniqueness.

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

### gtoplevelsof

`gtoplevelsof` is 1.5 to 6 times faster than doing contract to glean the top
levels of a variable.  Benchmark toplevelsof vs contract (unsorted), obs =
10,000,000, J = 10,000 (in seconds)

| gcontract | gtoplevelsof | ratio (c/t) | varlist
| --------- | ------------ | ----------- | -------
|      2.56 |         1.23 |        2.08 | str_12
|       3.5 |         2.27 |        1.54 | str_12 str_32
|      3.88 |         2.21 |        1.76 | str_12 str_32 str_4
|       2.1 |         .746 |        2.81 | double1
|      2.57 |         1.09 |        2.36 | double1 double2
|      3.07 |         1.36 |        2.27 | double1 double2 double3
|      1.97 |         .578 |        3.41 | int1
|      2.27 |         .803 |        2.82 | int1 int2
|      3.52 |         .983 |        3.58 | int1 int2 int3
|      3.24 |         1.75 |        1.85 | int1 str_32 double1
|      4.11 |         2.39 |        1.72 | int1 str_32 double1 int2 str_12 double2
|      4.35 |            3 |        1.45 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark toplevelsof vs contract (plus preserve, sort, keep, restore), obs =
10,000,000, J = 10,000 (in seconds)

| gcontract | gtoplevelsof | ratio (c/t) | varlist
| --------- | ------------ | ----------- | -------
|      3.84 |          1.7 |        2.25 | str_12
|      4.87 |         1.88 |        2.59 | str_12 str_32
|      5.29 |         2.21 |        2.39 | str_12 str_32 str_4
|      3.15 |         .799 |        3.94 | double1
|      3.52 |         1.01 |        3.48 | double1 double2
|      3.19 |         1.02 |        3.14 | double1 double2 double3
|      4.11 |         .678 |        6.06 | int1
|      3.92 |         .788 |        4.97 | int1 int2
|      3.38 |         .948 |        3.57 | int1 int2 int3
|      4.87 |         1.75 |        2.79 | int1 str_32 double1
|      4.52 |         2.33 |        1.94 | int1 str_32 double1 int2 str_12 double2
|      5.82 |         2.96 |        1.97 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### Hash sort

The speed gains here only hold when sorting groups. `hashsort` ~2-18 times
faster than `gsort`, 2.5-4 times faster than `sort`, and ~1.5-2.5 times
faster than `fsort`.

Benchmark vs gsort, obs = 1,000,000, J = 10,000 (in seconds; datasets are
compared via cf)

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

Benchmark vs sort, obs = 10,000,000, J = 10,000 (in seconds; datasets are
compared via cf)

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

### gquantiles

Benchmark with obs = 10,000,000, nquantiles = 10. Note this uses method(2)
in all cases because the way gquantiles determines which method to use is
based off the number of observations and the number of quantiles only. The
user can speed up the benchmarks when there are many duplicates by specifying
method(1).

| \_pctile | gquantiles | ratio (_/g) | varlist
| -------- | ---------- | ----------- | -------
|     31.9 |       1.14 |        27.9 | double1 (~ U(0,  1000), no missings, groups of size 10)
|     27.3 |       .909 |        30.1 | double3 (~ N(10, 5), many missings, groups of size 10)
|     41.1 |        1.3 |        31.5 | ru (~ N(0, 100), few missings, unique)
|     28.5 |       .712 |          40 | int1 (discrete (no missings, many groups))
|     20.8 |       .535 |        38.9 | int3 (discrete (many missings, few groups))
|       33 |       1.19 |        27.7 | ix (discrete (few missings, unique))
|       32 |          1 |          32 | int1^2 + 3 * double1
|     31.8 |       1.03 |        30.8 | 2 * int1 + log(double1)
|     29.4 |       1.14 |        25.8 | int1 * double3 + exp(double3)

| xtile | fastxtile | gquantiles | ratio (x/g) | ratio (f/g) | varlist
| ----- | --------- | ---------- | ----------- | ----------- | -------
|  28.8 |      35.1 |       1.37 |        21.1 |        25.7 | double1 (~ U(0,  1000), no missings, groups of size 10)
|  27.7 |      29.7 |       1.25 |        22.3 |        23.8 | double3 (~ N(10, 5), many missings, groups of size 10)
|    30 |      46.4 |       1.59 |        18.9 |        29.3 | ru (~ N(0, 100), few missings, unique)
|  24.2 |      29.2 |       1.06 |        22.8 |        27.4 | int1 (discrete (no missings, many groups))
|  23.1 |      22.3 |       .753 |        30.7 |        29.6 | int3 (discrete (many missings, few groups))
|  29.7 |        36 |       1.59 |        18.7 |        22.7 | ix (discrete (few missings, unique))
|  30.1 |         . |       2.19 |        13.7 |           . | int1^2 + 3 * double1
|  28.5 |         . |       2.83 |        10.1 |           . | 2 * int1 + log(double1)
|    31 |         . |       2.39 |          13 |           . | int1 * double3 + exp(double3)

| pctile | gquantiles | ratio (p/g) | varlist
| ------ | ---------- | ----------- | -------
|     33 |       .946 |        34.9 | double1 (~ U(0,  1000), no missings, groups of size 10)
|   29.7 |       .919 |        32.3 | double3 (~ N(10, 5), many missings, groups of size 10)
|   42.7 |       1.35 |        31.5 | ru (~ N(0, 100), few missings, unique)
|     30 |       .798 |        37.6 | int1 (discrete (no missings, many groups))
|   20.9 |       .581 |          36 | int3 (discrete (many missings, few groups))
|     36 |       1.17 |        30.7 | ix (discrete (few missings, unique))
|   31.5 |        2.1 |          15 | int1^2 + 3 * double1
|     38 |       2.66 |        14.3 | 2 * int1 + log(double1)
|   33.2 |       2.47 |        13.5 | int1 * double3 + exp(double3)

### gquantiles, by

Benchmark with obs = 10,000,000, nquantiles = 10, and 10,000 groups.

| astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g) | varlist
| ------ | --------- | ---------- | ----------- | ----------- | -------
|   26.5 |      54.6 |       2.78 |        9.56 |        19.6 | str_12
|   34.7 |      70.6 |       3.81 |        9.11 |        18.5 | str_12 str_32
|   26.9 |      60.6 |       2.63 |        10.2 |        23.1 | double1
|     26 |      61.8 |        2.4 |        10.9 |        25.8 | double1 double2
|   26.2 |      53.5 |       2.58 |        10.2 |        20.7 | int1
|     27 |      56.6 |       2.26 |          12 |        25.1 | int1 int2

We additionally benchmark increasing the number of quantiles. The grouping
variable was `int1`:

|     nq | astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g)
| ------ | ------ | --------- | ---------- | ----------- | -----------
|      2 |   23.1 |      44.9 |       2.39 |        9.67 |        18.8
|      4 |     24 |      48.2 |       2.47 |        9.71 |        19.5
|      6 |   24.2 |      45.4 |       2.49 |        9.71 |        18.2
|      8 |   24.3 |      46.1 |       2.49 |        9.75 |        18.5
|     10 |     25 |      48.5 |        2.5 |          10 |        19.4
|     12 |   24.1 |        51 |       2.47 |        9.77 |        20.7
|     14 |   25.9 |      53.8 |       2.58 |          10 |        20.9
|     16 |   24.3 |      50.9 |        2.6 |        9.35 |        19.6
|     18 |   28.3 |      51.9 |        3.1 |        9.14 |        16.7

(Note: fastxtile here is from egenmisc)

Last, we benchmark increasing the sample size. For this that for this
data set we dropped the string variables, and we can see that this
speeds up the commands (because the sorts involved run faster due to the
smaller memory requirements):

|            N | astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g)
| ------------ | ------ | --------- | ---------- | ----------- | -----------
|    1,000,000 |   2.05 |       1.9 |       .223 |        9.21 |        8.52
|    2,000,000 |   4.31 |      4.07 |       .434 |        9.92 |        9.38
|    3,000,000 |   6.76 |      6.26 |       .665 |        10.2 |        9.41
|    4,000,000 |   9.63 |      7.51 |       .886 |        10.9 |        8.48
|    5,000,000 |   9.38 |      9.32 |       .883 |        10.6 |        10.6
|    6,000,000 |   11.3 |      11.2 |       1.06 |        10.6 |        10.6
|    7,000,000 |   13.3 |      13.1 |       1.26 |        10.6 |        10.4
|    8,000,000 |   15.3 |      15.6 |       1.46 |        10.4 |        10.7
|    9,000,000 |     17 |      17.3 |       1.64 |        10.4 |        10.6

(Note: fastxtile here is from egenmisc)

Stata/MP Benchmarks
-------------------

Note I could not get serveral parts of `ftools` working in the server where I
have access to MP, so I did not benchmark `gtools` against `ftools` on Stata/MP

### gcollapse

`gcollapse` ~4-120 times faster than `collapse`.

_**Small J:**_

Benchmark vs collapse (all times in seconds)

- obs:     10,000,000
- groups:  100
- options: fast

Simple stats, many variables:

- vars:    x1-x15 ~ N(0, 10)
- stats:   sum

| collapse | gcollapse | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|     37.5 |       4.1 |        9.15 |
|     45.7 |      6.45 |        7.08 | str_12 str_32 str_4
|     47.4 |      5.03 |        9.43 | double1 double2 double3
|     47.5 |      7.15 |        6.65 | int1 int2
|     42.9 |       6.1 |        7.03 | int3 str_32 double1

Modestly complex stats, a few variables:

- vars:    x1-x6 ~ N(0, 10)
- stats:   mean median min max

| collapse | gcollapse | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|      196 |      3.14 |        62.4 |
|      205 |      5.43 |        37.7 | str_12 str_32 str_4
|     92.8 |      4.04 |        22.9 | double1 double2 double3
|     87.7 |      4.29 |        20.4 | int1 int2
|     89.5 |      5.11 |        17.5 | int3 str_32 double1

Very compex stats, one variable:

- vars:    x1 ~ N(0, 10)
- stats:   all available plus percentiles 10, 30, 70, 90

| collapse | gcollapse | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|      183 |      2.17 |        84.2 |
|      292 |      4.76 |        61.3 | str_12 str_32 str_4
|      264 |       2.2 |         120 | double1 double2 double3
|      251 |      1.96 |         128 | int1 int2
|      277 |      4.32 |          64 | int3 str_32 double1

_**Large J:**_

Benchmark vs collapse (all times in seconds)

- obs:     10,000,000
- groups:  1,000,000
- options: fast

Simple stats, many variables:

- vars:    x1-x15 ~ N(0, 10)
- stats:   sum

| collapse | gcollapse | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|       37 |      4.08 |        9.06 |
|     38.8 |        10 |        3.86 | str_12 str_32 str_4
|     41.3 |      7.99 |        5.16 | double1 double2 double3
|     38.8 |      7.63 |        5.09 | int1 int2
|     39.5 |      9.58 |        4.12 | int3 str_32 double1

Modestly complex stats, a few variables:

- vars:    x1-x6 ~ N(0, 10)
- stats:   mean median min max

| collapse | gcollapse | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|      213 |      3.17 |        67.2 |
|      187 |      11.2 |        16.7 | str_12 str_32 str_4
|     90.2 |       8.1 |        11.1 | double1 double2 double3
|      164 |      5.38 |        30.4 | int1 int2
|       89 |      9.68 |         9.2 | int3 str_32 double1

Very compex stats, one variable:

- vars:    x1 ~ N(0, 10)
- stats:   all available plus percentiles 10, 30, 70, 90

| collapse | gcollapse | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|      163 |      2.19 |        74.6 |
|      303 |      8.31 |        36.5 | str_12 str_32 str_4
|      256 |      5.67 |        45.1 | double1 double2 double3
|      249 |      2.46 |         101 | int1 int2
|      316 |      8.03 |        39.3 | int3 str_32 double1

### gcontract

This is 2.5 to 4 times faster than contract.  Benchmark vs contract, obs =
10,000,000, J = 10,000 (in seconds).

| contract | gcontract | ratio (c/g) | varlist
| -------- | --------- | ----------- | -------
|     15.6 |      6.05 |        2.57 | str_12
|       17 |      5.62 |        3.03 | str_12 str_32
|     17.9 |       7.1 |        2.51 | str_12 str_32 str_4
|       15 |      5.71 |        2.63 | double1
|     15.8 |      5.85 |         2.7 | double1 double2
|     15.3 |      5.82 |        2.63 | double1 double2 double3
|     12.8 |      3.89 |        3.28 | int1
|     15.8 |      5.56 |        2.85 | int1 int2
|     17.7 |      4.75 |        3.73 | int1 int2 int3
|     17.9 |      5.67 |        3.15 | int1 str_32 double1
|       19 |      6.87 |        2.76 | int1 str_32 double1 int2 str_12 double2
|     23.2 |      7.04 |        3.29 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### Group IDs (gegen)

`gegen` ~4-9 times faster than `egen`.  We benchmark `gegen id =
group(varlist)` vs egen and fegen, obs = 10,000,000, J = 10,000 (in seconds)

| egen | gegen | ratio (e/g) | varlist
| ---- | ----- | ----------- | -------
| 17.6 |   3.4 |        5.17 | str_12
| 17.9 |  2.49 |        7.17 | str_12 str_32
| 14.9 |  3.32 |        4.47 | str_12 str_32 str_4
| 13.8 |  2.15 |        6.42 | double1
| 13.6 |  1.59 |        8.56 | double1 double2
| 13.7 |  2.13 |        6.45 | double1 double2 double3
| 13.6 |  1.89 |        7.19 | int1
| 14.1 |  1.95 |        7.24 | int1 int2
| 11.5 |  1.57 |        7.34 | int1 int2 int3
| 11.9 |  2.65 |        4.49 | int1 str_32 double1
| 12.2 |  3.14 |        3.88 | int1 str_32 double1 int2 str_12 double2
| 15.6 |   3.9 |           4 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### gisid

`gegen` ~4-14 times faster than `egen`.  Benchmark vs isid, obs = 10,000,000;
all calls include an index to ensure uniqueness.

| isid | gisid | ratio (i/g) | varlist
| ---- | ----- | ----------- | -------
| 27.1 |  3.01 |        9.02 | str_12
| 27.6 |  3.42 |        8.09 | str_12 str_32
| 29.1 |   3.6 |        8.08 | str_12 str_32 str_4
|   22 |  2.59 |        8.48 | double1
| 22.1 |  2.65 |        8.34 | double1 double2
| 22.6 |  2.74 |        8.24 | double1 double2 double3
| 21.8 |  1.56 |          14 | int1
| 22.7 |  1.78 |        12.8 | int1 int2
| 23.2 |  2.79 |        8.34 | int1 int2 int3
|   26 |   3.4 |        7.66 | int1 str_32 double1
| 27.8 |  3.93 |        7.07 | int1 str_32 double1 int2 str_12 double2
|   30 |  4.39 |        6.84 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark vs isid, obs = 10,000,000, J = 10,000 (in seconds)

| isid | gisid | ratio (i/g) | varlist
| ---- | ----- | ----------- | -------
| 9.32 |  1.42 |        6.58 | str_12
| 9.94 |   1.9 |        5.24 | str_12 str_32
| 10.4 |  2.14 |        4.83 | str_12 str_32 str_4
| 8.51 |  1.22 |           7 | double1
| 8.52 |  1.35 |        6.32 | double1 double2
|  9.2 |   1.4 |        6.59 | double1 double2 double3
| 8.51 |  .625 |        13.6 | int1
| 9.07 |  .883 |        10.3 | int1 int2
| 9.58 |  1.44 |        6.64 | int1 int2 int3
| 9.97 |  1.94 |        5.13 | int1 str_32 double1
| 10.6 |  2.41 |        4.41 | int1 str_32 double1 int2 str_12 double2
| 11.9 |  2.86 |        4.18 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### gduplicates

`gduplicates` is 3-10 times faster than `duplicates`.
Benchmark vs duplicates report, obs = 10,000,000, J = 10,000 (in seconds)

| duplicates | gduplicates | ratio (g/h) | varlist
| ---------- | ----------- | ----------- | -------
|       94.4 |        10.7 |        8.84 | str_12
|       96.3 |        12.5 |        7.67 | str_12 str_32
|       97.9 |        13.6 |        7.18 | str_12 str_32 str_4
|       73.7 |        8.85 |        8.33 | double1
|       74.6 |        9.16 |        8.15 | double1 double2
|       74.4 |        9.25 |        8.05 | double1 double2 double3
|       93.5 |        8.41 |        11.1 | int1
|         92 |        9.45 |        9.73 | int1 int2
|       92.6 |        10.7 |        8.66 | int1 int2 int3
|       80.8 |        12.6 |        6.42 | int1 str_32 double1
|       84.7 |        13.7 |         6.2 | int1 str_32 double1 int2 str_12 double2
|       87.7 |        16.8 |        5.22 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark vs duplicates drop, obs = 10,000,000, J = 10,000
(in seconds; output compared via cf)

| duplicates | gduplicates | ratio (g/h) | varlist
| ---------- | ----------- | ----------- | -------
|       35.1 |        7.96 |        4.41 | str_12
|       37.4 |        8.67 |        4.31 | str_12 str_32
|       40.1 |        10.5 |        3.82 | str_12 str_32 str_4
|       31.4 |        4.75 |        6.61 | double1
|       32.8 |         5.8 |        5.66 | double1 double2
|       32.9 |        5.45 |        6.04 | double1 double2 double3
|       33.2 |        4.18 |        7.95 | int1
|       35.3 |        3.83 |        9.22 | int1 int2
|       36.8 |        6.37 |        5.78 | int1 int2 int3
|       37.9 |        8.06 |         4.7 | int1 str_32 double1
|       41.6 |        10.8 |        3.84 | int1 str_32 double1 int2 str_12 double2
|       45.3 |        12.4 |        3.64 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### glevelsof

`glevelsof` ~2.5-7 times faster than `levelsof`. Benchmark vs levelsof, obs =
10,000,000, J = 100 (in seconds)

| levelsof | glevelsof | ratio (l/g) | varlist
| -------- | --------- | ----------- | -------
|       15 |      2.29 |        6.56 | str_12
|     15.2 |      2.51 |        6.06 | str_32
|     15.5 |      2.15 |        7.21 | str_4
|     4.01 |      1.15 |        3.49 | double1
|     3.54 |      1.18 |        3.01 | double2
|     2.53 |      .937 |         2.7 | double3
|     4.67 |      .634 |        7.37 | int1
|     1.68 |      .555 |        3.02 | int2
|     1.74 |      .534 |        3.26 | int3

### gunique

`gunique` ~4-12 times faster than `unique`.  Benchmark vs unique. obs =
10,000,000; all calls include an index to ensure uniqueness.

| unique | gunique | ratio (d/g) | varlist
| ------ | ------- | ----------- | -------
|     14 |    4.43 |        3.17 | str_12
|   15.6 |    4.93 |        3.17 | str_12 str_32
|   16.2 |    5.26 |        3.07 | str_12 str_32 str_4
|   12.7 |    3.01 |        4.21 | double1
|     13 |       3 |        4.34 | double1 double2
|     13 |     3.1 |        4.19 | double1 double2 double3
|   12.9 |     1.7 |        7.59 | int1
|   13.3 |     1.9 |        7.02 | int1 int2
|   14.1 |    2.21 |        6.36 | int1 int2 int3
|   15.8 |    4.78 |        3.31 | int1 str_32 double1
|   17.3 |    5.57 |        3.11 | int1 str_32 double1 int2 str_12 double2
|   17.1 |    6.45 |        2.65 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark vs unique, obs = 10,000,000, J = 10,000 (in seconds).

| unique | gunique | ratio (u/g) | varlist
| ------ | ------- | ----------- | -------
|   12.7 |     2.6 |        4.88 | str_12
|   13.7 |    3.29 |        4.18 | str_12 str_32
|     14 |    3.69 |         3.8 | str_12 str_32 str_4
|     12 |    1.42 |        8.43 | double1
|   12.5 |    1.67 |        7.47 | double1 double2
|   11.8 |    1.75 |        6.77 | double1 double2 double3
|   11.5 |    .679 |        16.9 | int1
|   12.5 |       1 |        12.4 | int1 int2
|   12.6 |    1.25 |        10.1 | int1 int2 int3
|   13.5 |     3.2 |        4.23 | int1 str_32 double1
|   14.2 |    3.92 |        3.61 | int1 str_32 double1 int2 str_12 double2
|     15 |    4.72 |        3.18 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### gtoplevelsof

`gtoplevelsof` is 2.5 to 6.5 times faster than doing contract to glean the top
levels of a variable.  Benchmark toplevelsof vs contract (unsorted), obs =
10,000,000, J = 10,000 (in seconds)

| gcontract | gtoplevelsof | ratio (c/t) | varlist
| --------- | ------------ | ----------- | -------
|      6.02 |         1.37 |        4.41 | str_12
|      5.56 |         2.33 |        2.39 | str_12 str_32
|      6.98 |         2.34 |        2.98 | str_12 str_32 str_4
|      5.66 |          .93 |        6.08 | double1
|      5.74 |         1.21 |        4.76 | double1 double2
|      4.61 |         1.31 |        3.52 | double1 double2 double3
|      4.68 |         .714 |        6.55 | int1
|      4.41 |         .737 |        5.98 | int1 int2
|      4.46 |         1.05 |        4.25 | int1 int2 int3
|      5.78 |         1.83 |        3.16 | int1 str_32 double1
|      6.49 |          2.5 |        2.59 | int1 str_32 double1 int2 str_12 double2
|      6.54 |         3.19 |        2.05 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

Benchmark toplevelsof vs contract (plus preserve, sort, keep, restore), obs =
10,000,000, J = 10,000 (in seconds)

| gcontract | gtoplevelsof | ratio (c/t) | varlist
| --------- | ------------ | ----------- | -------
|      5.11 |         1.25 |         4.1 | str_12
|      5.81 |         1.91 |        3.05 | str_12 str_32
|      6.12 |         2.35 |         2.6 | str_12 str_32 str_4
|       4.7 |         .848 |        5.54 | double1
|      4.85 |         .975 |        4.97 | double1 double2
|      4.87 |         1.01 |        4.81 | double1 double2 double3
|      4.18 |         .611 |        6.84 | int1
|      4.61 |         .684 |        6.74 | int1 int2
|      4.96 |         1.05 |        4.73 | int1 int2 int3
|       5.8 |         1.83 |        3.17 | int1 str_32 double1
|       6.5 |          2.5 |         2.6 | int1 str_32 double1 int2 str_12 double2
|      6.74 |         3.19 |        2.12 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

### Hash sort

`hashsort` ~1-6 times faster than `gsort` and 0.8 to 1.3 the speed of `sort`.
Benchmark vs gsort, obs = 1,000,000, J = 10,000 (in seconds; datasets are
compared via cf)

| gsort | hashsort | ratio (g/h) | varlist
| ----- | -------- | ----------- | -------
|  .639 |     .582 |         1.1 | -str_12
|  .995 |     .743 |        1.34 | str_12 -str_32
|  1.61 |     .763 |        2.11 | str_12 -str_32 str_4
|  .562 |     .519 |        1.08 | -double1
|  .824 |     .541 |        1.52 | double1 -double2
|  1.54 |     .697 |        2.21 | double1 -double2 double3
|  .661 |     .567 |        1.17 | -int1
|   .95 |     .561 |        1.69 | int1 -int2
|  1.26 |     .579 |        2.18 | int1 -int2 int3
|  1.98 |     .704 |        2.81 | -int1 -str_32 -double1
|   3.7 |     1.04 |        3.54 | int1 -str_32 double1 -int2 str_12 -double2
|  6.42 |     1.12 |        5.74 | int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3

Benchmark vs sort, obs = 10,000,000, J = 10,000 (in seconds; datasets are compared via cf)

|  sort | hashsort | ratio (s/h) | varlist
|  ---- | -------- | ----------- | -------
|  7.46 |     8.27 |        .901 | str_12
|  8.39 |     8.07 |        1.04 | str_12 str_32
|  9.28 |     7.64 |        1.21 | str_12 str_32 str_4
|  7.05 |     5.33 |        1.32 | double1
|  7.49 |     8.41 |         .89 | double1 double2
|  7.76 |     9.04 |        .859 | double1 double2 double3
|  6.91 |     7.34 |        .942 | int1
|  7.85 |      8.1 |        .969 | int1 int2
|  7.72 |     5.82 |        1.33 | int1 int2 int3
|  8.19 |      7.1 |        1.15 | int1 str_32 double1
|  8.65 |     10.4 |        .835 | int1 str_32 double1 int2 str_12 double2
|  8.81 |     9.27 |         .95 | int1 str_32 double1 int2 str_12 double2 int3 str_4 double3

The above speed gains only hold when sorting groups. `hashsort` ~2-18 times
faster than `gsort`, 2.5-4 times faster than `sdort`, and ~1.5-2.5 times
faster than `fsort`.

### gquantiles

Benchmark with obs = 10,000,000, nquantiles = 10. Note this uses method(2)
in all cases because the way gquantiles determines which method to use is
based off the number of observations and the number of quantiles only. The
user can speed up the benchmarks when there are many duplicates by specifying
method(1).

| \_pctile | gquantiles | ratio (_/g) | varlist
| -------- | ---------- | ----------- | -------
|     5.62 |       1.77 |        3.17 | double1 (~ U(0,  1000), no missings, groups of size 10)
|     5.16 |       1.69 |        3.05 | double3 (~ N(10, 5), many missings, groups of size 10)
|      5.8 |       1.99 |        2.92 | ru (~ N(0, 100), few missings, unique)
|     5.48 |       1.22 |         4.5 | int1 (discrete (no missings, many groups))
|      4.5 |       .841 |        5.35 | int3 (discrete (many missings, few groups))
|     6.43 |       2.08 |         3.1 | ix (discrete (few missings, unique))
|     5.85 |       1.79 |        3.26 | int1^2 + 3 * double1
|     5.77 |       1.69 |        3.41 | 2 * int1 + log(double1)
|      5.1 |        1.7 |        3.01 | int1 * double3 + exp(double3)

| xtile | fastxtile | gquantiles | ratio (x/g) | ratio (f/g) | varlist
| ----- | --------- | ---------- | ----------- | ----------- | -------
|  48.3 |      7.33 |       2.44 |        19.7 |           3 | double1 (~ U(0,  1000), no missings, groups of size 10)
|  47.8 |      6.53 |       2.26 |        21.1 |        2.89 | double3 (~ N(10, 5), many missings, groups of size 10)
|  48.4 |      7.69 |       3.02 |          16 |        2.55 | ru (~ N(0, 100), few missings, unique)
|  43.4 |      6.75 |       2.04 |        21.2 |         3.3 | int1 (discrete (no missings, many groups))
|  39.6 |      5.77 |       1.58 |          25 |        3.64 | int3 (discrete (many missings, few groups))
|  49.7 |      7.64 |       2.68 |        18.6 |        2.85 | ix (discrete (few missings, unique))
|  48.1 |         . |       3.51 |        13.7 |           . | int1^2 + 3 * double1
|    49 |         . |       3.58 |        13.7 |           . | 2 * int1 + log(double1)
|  47.1 |         . |       3.36 |          14 |           . | int1 * double3 + exp(double3)

| pctile | gquantiles | ratio (p/g) | varlist
| ------ | ---------- | ----------- | -------
|   8.02 |       2.02 |        3.97 | double1 (~ U(0,  1000), no missings, groups of size 10)
|   7.29 |       1.82 |           4 | double3 (~ N(10, 5), many missings, groups of size 10)
|   8.65 |       2.29 |        3.78 | ru (~ N(0, 100), few missings, unique)
|   7.16 |       1.54 |        4.65 | int1 (discrete (no missings, many groups))
|   6.08 |       1.11 |        5.48 | int3 (discrete (many missings, few groups))
|   7.75 |       2.25 |        3.45 | ix (discrete (few missings, unique))
|   8.62 |       3.07 |         2.8 | int1^2 + 3 * double1
|    8.1 |       3.15 |        2.57 | 2 * int1 + log(double1)
|   7.75 |       3.07 |        2.52 | int1 * double3 + exp(double3)

### gquantiles, by

Benchmark with obs = 10,000,000, nquantiles = 10, and 10,000 groups.

| astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g) | varlist
| ------ | --------- | ---------- | ----------- | ----------- | -------
|   19.5 |      19.8 |       5.46 |        3.56 |        3.63 | str_12
|     20 |      21.8 |        6.2 |        3.23 |        3.52 | str_12 str_32
|     19 |      20.3 |       4.89 |        3.88 |        4.16 | double1
|   18.6 |      20.9 |       5.62 |         3.3 |        3.71 | double1 double2
|     19 |      19.4 |       5.01 |         3.8 |        3.87 | int1
|   19.6 |      20.1 |       5.34 |        3.68 |        3.77 | int1 int2

We additionally benchmark increasing the number of quantiles. The grouping
variable was `int1`:

|     nq | astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g)
| ------ | ------ | --------- | ---------- | ----------- | -----------
|      2 |   17.6 |      17.3 |       5.09 |        3.46 |        3.41
|      4 |   18.8 |      17.9 |       4.85 |        3.88 |        3.69
|      6 |   17.7 |      17.7 |       4.92 |        3.59 |         3.6
|      8 |   18.2 |      17.7 |       4.89 |        3.72 |        3.62
|     10 |   17.6 |      18.2 |       4.91 |        3.58 |         3.7
|     12 |   18.6 |      18.5 |       4.91 |        3.78 |        3.77
|     14 |   17.9 |      18.2 |       4.93 |        3.63 |        3.68
|     16 |   17.9 |      18.3 |       4.91 |        3.63 |        3.74
|     18 |   17.8 |      18.7 |       4.92 |        3.61 |         3.8

(Note: fastxtile here is from egenmisc)

Last, we benchmark increasing the sample size. For this that for this
data set we dropped the string variables, and we can see that this
speeds up the commands (because the sorts involved run faster due to the
smaller memory requirements):

|            N | astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g)
| ------------ | ------ | --------- | ---------- | ----------- | -----------
|    1,000,000 |    1.2 |      1.14 |       .299 |           4 |        3.81
|    2,000,000 |   2.42 |      2.38 |       .695 |        3.48 |        3.42
|    3,000,000 |   3.91 |      3.81 |       1.06 |         3.7 |         3.6
|    4,000,000 |   6.41 |      5.37 |       1.55 |        4.13 |        3.46
|    5,000,000 |   6.73 |      7.37 |        1.8 |        3.75 |         4.1
|    6,000,000 |   8.24 |      7.79 |       2.15 |        3.82 |        3.61
|    7,000,000 |   8.54 |      8.76 |       1.53 |        5.59 |        5.73
|    8,000,000 |     10 |      9.33 |       1.72 |        5.84 |        5.43
|    9,000,000 |   11.3 |      11.4 |       2.02 |        5.59 |        5.67

(Note: fastxtile here is from egenmisc)

Old Collapse Benchmarks
-----------------------

The data used here is different.  The grouping variable is an integer with
missing values and no extended missing values. The source variables are random
uniform variables with an offset. We can see that `gcollapse` (`0.9.0`) can be
3-23 times faster than `fcollapse` undere some conditions.

Benchmarking N for J = 100; by(x3)

- vars  = y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15
- stats = sum

|              N | gcollapse | fcollapse | ratio (f/g) |
| -------------- | --------- | --------- | ----------- |
|      2,000,000 |      0.62 |      2.06 |        3.29 |
|     20,000,000 |      7.89 |     24.51 |        3.10 |

Benchmarking N for J = 100; by(x3)

- vars  = y1 y2 y3
- stats = mean median

|              N | gcollapse | fcollapse | ratio (f/g) |
| -------------- | --------- | --------- | ----------- |
|      2,000,000 |      0.40 |      2.76 |        6.93 |
|     20,000,000 |      3.89 |     35.74 |        9.18 |

Benchmarking N for J = 100; by(x3)

- vars  = y1 y2 y3 y4 y5 y6
- stats = sum mean count min max

|              N | gcollapse | fcollapse | ratio (f/g) |
| -------------- | --------- | --------- | ----------- |
|      2,000,000 |      0.41 |      1.80 |        4.39 |
|     20,000,000 |      4.10 |     20.20 |        4.92 |

Benchmarking N for J = 10; by(group)

- vars  = x1 x2
- stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

|              N | gcollapse | fcollapse | ratio (f/g) |
| -------------- | --------- | --------- | ----------- |
|      2,000,000 |      0.57 |      8.32 |       14.53 |
|     20,000,000 |      6.49 |    151.95 |       23.42 |

Benchmarking J for N = 5,000,000; by(group)

- vars  = x1 x2
- stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

|              J | gcollapse | fcollapse | ratio (f/g) |
| -------------- | --------- | --------- | ----------- |
|             10 |      2.11 |     23.76 |       11.28 |
|            100 |      1.39 |     17.50 |       12.60 |
|          1,000 |      1.50 |     15.10 |       10.07 |
|         10,000 |      2.88 |     14.00 |        4.86 |
|        100,000 |      3.01 |     13.78 |        4.57 |
|      1,000,000 |      3.91 |     43.36 |       11.09 |

