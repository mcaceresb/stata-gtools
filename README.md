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

using the multi-threaded version of `gcollapse` (which I though was
fitting for Stata/MP). Alternatively, I made Stata/IC benchmarks
available (since I only have IC on my personal computer) using the
single-threaded version of `gcollapse`. See `./src/test/bench_ic.log`;
the speed gains in IC are markedly higher than those below.

### Benchmarks in the style of `ftools`

We vary N for J = 100 and collapse 15 variables:
```
    vars  = y1-y15 ~ 123.456 + U(0, 1)
    stats = sum

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      1.18 |      6.18 |      3.49 |        2.96 |        5.25 |
    |  20,000,000 |     11.67 |     66.25 |     41.71 |        3.57 |        5.68 |
    | 200,000,000 |    135.20 |    774.82 |    499.10 |        3.69 |        5.73 |
```

In the tables, `g`, `f`, and `c` are code for `gcollapse`, `fcollapse`,
and `collapse`, respectively. We repeat the exercise but with more
complex summary statistics:
```
    vars  = y1-y3 ~ 123.456 + U(0, 1)
    stats = mean median

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      0.65 |      8.35 |      3.36 |        5.17 |       12.85 |
    |  20,000,000 |      4.72 |     99.25 |     39.30 |        8.33 |       21.03 |
    | 200,000,000 |     57.87 |   1703.96 |    626.00 |       10.82 |       29.44 |
```

We see `gcollapse` is 3-10 times faster than `fcollapse` and 5-30 times
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
impossible. (If you worry about such things, you can check groups are
consistent with the `checkhash` option; fair warning: this feature is
currently very experimental and in testing I have ocassionally found
it to produce false positives---i.e. finding a collision when there is none.)

TODO
----

- [ ] Compile for Windows and OSX.
- [ ] Improve memory management.
- [ ] Implement all by-able `egen` functions.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
