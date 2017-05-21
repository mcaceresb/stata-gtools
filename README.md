Faster Stata for Group Operations
---------------------------------

This is currently a beta release. This package uses a C-plugin
to provide a faster implementation for Stata's `collapse` called
`gcollapse` that is also faster than Sergio Correia's `fcollapse` from
`ftools`. It also provides some support for by-able `egen` functions via
`gegen`.

Currently, memory management is **VERY** bad, so if you are generating
many summary variables from a single source variable, please see the
memory management section below. Support for `egen` is limited, and only
Unix versions of the plugins are available. Future releases will support
the full range of by-able `egen` functions and will be cross-platform.

- [Installation](#installation)
- [Requirements](#requirements)
- [Benchmark](#benchmark)
- [Supported functions](#supported-functions)
- [A word of caution](#a-word-of-caution)
- [FAQs](#faqs)
- [Memory Management](#memory-management)
- [Building](#building)
- [A brief note on hashing](#a-brief-note-on-hashing)
- [License](#license)

Installation
------------

```stata
net install gtools, from(https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/build/)
```

To update, run
```stata
adoupdate, update
```

To uninstall, run
```stata
ado uninstall gtools
```

Requirements
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
My own machine and the servers I have access to run Linux, so I have
only developed this for Stata for Unix so far. Future releases will be
cross-platform. If you want to compile the plugin yourself, atop the C
standard library you will need
- [`centaurean`'s implementation of spookyhash](https://github.com/centaurean/spookyhash)
- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2/) (SPI).

Benchmark
---------

See `src/test/bench_gcollapse.do` for the benchmark code. We have 4 benchmarks:
- `ftools`-style benchmark: This collapses 20M observations to 100
  groups by summing 15 variables.

- `ftools`-style alternative benchmark: This collapses 20M observations
  to 100 groups by taking the mean and median of 3 variables.

- Increasing group size: We fix the sample size at 5M and increase
  the group size from 10 to 1M in geometric succession. We compute
  all available stats (and 2 sample percentiles) for 2 variables.

- Increasing sample size: We fix the group size at 10 and increase the
  sample size from 2,000 to 20M in geometric succession. We compute all
  available stats (and 2 sample percentiles) for 2 variables.

All benchmarks were done on a server with the following specifications:

    Program:   Stata/MP 14.2 (8 cores)
    OS:        x86_64 GNU/Linux
    Processor: Intel(R) Xeon(R) CPU E5-4617 0 @ 2.90GHz
    Cores:     4 sockets with one hexa-core processor (24 cores).
    Memory:    220GiB
    Swap:      298GiB

Alternatively, I made Stata/IC benchmarks available (since I only have
IC on my personal computer). See `./src/test/bench_ic.log`; the speed
gains in IC are, naturally, markedly higher than those below.

### Benchmarks in the style of `ftools`

We vary N for J = 100 and collapse 15 variables:
```
    vars  = y1-y15 ~ 123.456 + U(0, 1)
    stats = sum

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |  2,000,000 |      2.45 |      7.02 |      3.31 |        1.35 |        2.86 |
    | 20,000,000 |     20.23 |     89.45 |     42.75 |        2.11 |        4.42 |
```

In the tables, `g`, `f`, and `c` are code for `gcollapse`, `fcollapse`,
and `collapse`, respectively. We repeat the exercise but with more
complex summary statistics:
```
    vars  = y1-y3 ~ 123.456 + U(0, 1)
    stats = mean median

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/f) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |  2,000,000 |      0.95 |      8.82 |      3.69 |        3.88 |        9.28 |
    | 20,000,000 |     12.35 |    117.78 |     43.34 |        3.51 |        9.54 |
```

We see `gcollapse` is 2-3.5 times faster than `fcollapse` and 4-10 times
faster than `collapse`, with larger speed gains for complex statistics.

### Increasing the sample size

Data was sorted on a random variable before collapsing. We vary N for J = 10:
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |          N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ---------- | --------- | --------- | --------- | ----------- | ----------- |
    |    200,000 |      0.35 |      9.11 |      0.84 |        2.37 |       25.80 |
    |  2,000,000 |      4.70 |    117.18 |     10.13 |        2.15 |       24.93 |
    | 20,000,000 |     40.74 |   1524.70 |    142.14 |        3.49 |       37.43 |
```

We can see that `collapse` takes 25 minutes to handle complicated
functions with 20M observations, whereas `fcollapse` takes about 2.5
minutes and `gcollapse` takes 40 seconds.

### Increasing the number of levels

Data was sorted on a random variable before collapsing. We vary J for N = 5,000,000:
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |         J | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | --------- | --------- | --------- | --------- | ----------- | ----------- |
    |        10 |      4.42 |    338.19 |     28.97 |        6.55 |       76.50 |
    |       100 |      8.10 |    322.82 |     23.57 |        2.91 |       39.85 |
    |     1,000 |     12.94 |    311.75 |     20.90 |        1.61 |       24.09 |
    |    10,000 |     13.13 |    298.15 |     19.26 |        1.47 |       22.71 |
    |   100,000 |      7.99 |    311.57 |     26.96 |        3.37 |       38.98 |
    | 1,000,000 |     14.04 |    327.28 |    107.73 |        7.67 |       23.31 |
```

Interestingly, the performance of collapse is consistent at about
5 minutes, but across the board it was 20-30 times slower than
`gcollapse`. `fcollapse` did better with a modest number of groups,
where `gcollapse` was only 1.5-3.5x faster, similar to prior benchmarks.
However, with 10 groups and 1M groups, `gcollapse` was ~7x faster.

### Stata vs C

We can benchmark the Stata overhead for the two scenarios above. (See
`./src/test/bench_gcollapse.do` for the data simulation program)
```stata
    J = 10
    N = 20,000,000
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    . gcollapse [...], by(group) benchmark
    Program set up executed in 37.54 seconds
            Plugin step 1: stata parsing done; 0.000 seconds.
            Plugin step 2: Hashed by variables; 1.960 seconds.
            Plugin step 3: Sorted on integer-only hash index; 2.890 seconds.
            Plugin step 4: Set up variables for main group loop; 0.410 seconds.
            Plugin step 5.1: Read in source variables; 4.220 seconds.
            Plugin step 5.2: Collapsed source variables; 2.460 seconds.
            Plugin step 6: Copied collapsed variables back to stata; 0.000 seconds.
    The plugin executed in 12.04 seconds
    Program exit executed in 2.72 seconds
    The program executed in 52.3 seconds

    J = 1,000,000
    N = 5,000,000
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    . gcollapse [...], by(group) benchmark
    Program set up executed in 6.144 seconds
            Plugin step 1: stata parsing done; 0.000 seconds.
            Plugin step 2: Hashed by variables; 0.470 seconds.
            Plugin step 3: Sorted on integer-only hash index; 1.270 seconds.
            Plugin step 4: Set up variables for main group loop; 0.090 seconds.
            Plugin step 5.1: Read in source variables; 1.120 seconds.
            Plugin step 5.2: Collapsed source variables; 0.900 seconds.
            Plugin step 6: Copied collapsed variables back to stata; 0.990 seconds.
    The plugin executed in 4.874 seconds
    Program exit executed in 2.036 seconds
    The program executed in 13.05 seconds
```

The crux of the runtime—indeed, 60%-80% of the runtime—is setting
up the data in Stata for C (in particular this is adding empty target
variables and dropping superfluous variables) and dropping non-collapsed
observations after the plugin is done (and with J = 1,000,000, sorting
the collapse also takes some time). It is not possible to add and drop
variables or data from C, so we must do that in Stata before running the
plugin (this is also the problem with memory management).

This also reveals that further speed improvements to the plugin will
come from improving the Stata portion of the code, rather than the C
portion of the code.

Supported Functions
-------------------

The following functions are supported

    | Function | gcollapse | gegen |
    | -------- | --------- | ----- |
    | tag      |           |   X   |
    | group    |           |   X   |
    | total    |           |   X   |
    | sum      |     X     |   X   |
    | mean     |     X     |   X   |
    | sd       |     X     |   X   |
    | max      |     X     |   X   |
    | min      |     X     |   X   |
    | count    |     X     |   X   |
    | median   |     X     |   X   |
    | iqr      |     X     |   X   |
    | percent  |     X     |   X   |
    | first    |     X     |   X   |
    | last     |     X     |   X   |
    | firstnm  |     X     |   X   |
    | lastnm   |     X     |   X   |

Quantiles are supported in both `gcollapse` and `gegen` via

```stata
gcollapse (p#) target = var [target = var ...] , by(varlist)
gegen target = pctile(var), by(varlist) p(#)
```

Where # is a "percentile" (though it can have arbitrary decimal places,
which allows computing quantiles; e.g. 2.5 or 97.5).

A note on `gegen`
-----------------

I do not intend to re-implement all of `egen`, just by-able functions.
Atop the currently supported calls, two generic `egen` functions are
provided that are much faster than their counterparts
```stata
gegen id  = group(varlist)
gegen tag = tag(varlist)
```

Both are much faster than `egen` because they do not sort the data, and
rather rely on hashes to tag the data and generate an id as new groups
appear (_**WARNING**_: this means `group` will ID the first group that
appears as 1 and the last as J; `egen` will sort the data first).

A word of caution
-----------------

At the moment this code is very beta and has not been extensively tested
in the way collapse has. Furthermore, there are some notable problems:
- Memory management is terrible (see below).
- It is only available in Unix.
- Unlike `fcollapse`, the user cannot add functions easily (it uses compiled C code).

Despite this, it has several advantages:
- It's several times faster than `fcollapse` (3-8 times faster in our
  benchmarks, and `fcollapse` in turn is ~3 times faster than plain
  `collapse`).
- Grouping variables can be a mix of numeric and string variables,
  unlike `fcollapse` which limits by variables to be of the same type.
- Quantiles can be quantiles, not just percentiles (e.g. p2.5 and
  p97.5 are be valid stat calls in `gcollapse`).

FAQs
----

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
   (unless you're working with groups in the quintillions, that's
   10^18). Hashing here is also faster than hashing in Sergio Correia's
   `ftools`, which uses a 32-bit hash and will run into collisions just
   with levels in the thousands, so he has to resolve collisions.

2. Efficiency: It is possible that Stata's algorithms are not
   particularly efficient (this is, for example, the explanation given
   for why `ftools` is faster than Stata even though Mata should not be
   faster than compiled C code).

### Why use platform-dependent plugins?

C is fast! When optimizing stata, there are three options:
- Mata (already implemented)
- Java plugins (I don't like Java)
- C and C++ plugins

Sergio Correa's `ftools` tests the limits of mata and achieves excellent
results, but Mata cannot compare to the raw speed a low level language like
C would afford. The only question is whether the overhead reading and writing
data to and from C compensates the speed gain, and in this case it does.

### Why only Unix?

C is platform dependent and I don't have access to Stata on Windows or
OSX. Sorry! I use Linux on my personal computer and on all the servers
where I do my work. If anyone is willing to try compiling the plugins
out on Windows and OSX, I'd be happy to take pull requests!

Memory Management
-----------------

C cannot create or drop variables. This means that we need to create the
target variables in Stata. If creating K targets for a variable, we need
to create K - 1 variables _**before**_ collapsing the data. If you are,
for example, collapsing 1M observations into 10 observations, then even
though a variable in the collapsed data would only take up 80 bytes, they
have to be allocated ~8MiB (8 * 1e6 / 1024 / 1024).

On most systems, this will not be an issue with observations in the low
millions. However, if you have, for example, 100M observations, a singe
variable will take up ~0.8GiB in memory. In that scenario, even a dozen
targets for a single variable may exceed the memory capacity of most
personal computers.

The function tries to be smart about this: Variables are only created
from the _**second**_ target onward. If you have one target per
variable, memory consumption should not exceed that of `collapse` or `fcollapse`.

Building
--------

To compile the plugin, first compile `spookyhash`:
```
cd lib/spookyhash/build
make
cd -
```

If that compiles correctly, run
```
./build.py
```

to compile the plugin and copy the files to `./build`. This tries to run
`make` as one of the steps, so if you are not on Linux you will have to
modify `./Makefile`.

A brief note on hashing
-----------------------

The idea behind using a hash is simple: Sorting a single integer
grouping variable is much faster than sorting on multiple variables
with arbitrary data (in particular, we can use a counting sort, which
asymptotically performs in `O(n)` time compared to `O(n log n)` for the
fastest general-purpose sorting algorithms).

Given `K` by variables, `by_1` to `by_K`, where `by_k` belongs the set
`B_k`, the general problem we face is devising a function `f` such that
`f: B_1 x ... x B_K -> N`, where `N` are the natural (whole) numbers.
Given `B_k` can be integers, floats, and strings, the natural way of doing
this is to use a hash: A function that takes an arbitrary sequence of data
and outputs data of fixed size.

In particular we use the [Spooky Hash](http://burtleburtle.net/bob/hash/spooky.html)
devised by Bob Jenkins, which is a 128-bit hash. Stata caps observations
at 20 billion or so, meaning a 128-bit hash collision is _de facto_
impossible. But if you worry about such things, you can check groups are
consistent with the `checkhash` option.

TODO
----

- [ ] Compile for Windows and OSX.
- [ ] Improve memory management.
- [ ] Implement all by-able `egen` functions.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
