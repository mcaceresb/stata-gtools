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

Software and hardware specifications:
- Program: Stata/SE 13.1
- OS: Linux (4.10.13-1-ARCH x86\_64 GNU/Linux)
- Processor: Intel(R) Core(TM) i7-6500U CPU @ 2.50GHz
- Cores: 2 cores with 2 virtual threads per core.
- Memory: 15.6GiB
- Swap: 7.8GiB

### Compared to `fcollapse`

We vary N for J = 100 and collapse 15 variables:
```
    vars  = y1-y15 ~ 123.456 + U(0, 1)
    stats = sum

    |          N | gcollapse | gcollapse (multi) | fcollapse | ratio | ratio (multi) |
    | ---------- | --------- | ----------------- | --------- | ----- | ------------- |
    |    200,000 |      0.16 |              0.15 |      0.28 |  1.75 |          1.87 |
    |  2,000,000 |      1.49 |              1.65 |      3.01 |  2.02 |          1.83 |
    | 20,000,000 |     14.24 |             13.37 |     55.24 |  3.88 |          4.13 |
```

We vary N for J = 100 and collapse 3 variables:
```
    vars  = y1-y3 ~ 123.456 + U(0, 1)
    stats = mean median

    |          N | gcollapse | gcollapse (multi) | fcollapse | ratio | ratio (multi) |
    | ---------- | --------- | ----------------- | --------- | ----- | ------------- |
    |    200,000 |      0.09 |              0.10 |      0.32 |  3.38 |          3.18 |
    |  2,000,000 |      0.98 |              0.87 |      3.87 |  3.94 |          4.45 |
    | 20,000,000 |      9.45 |              7.44 |     66.88 |  7.08 |          8.99 |
```

### Increasing the sample size

We vary N for J = 10:
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean sd max min count percent first last firstnm lastnm

    |          N | gcollapse | gcollapse (multi) | fcollapse | ratio | ratio (multi) |
    | ---------- | --------- | ----------------- | --------- | ----- | ------------- |
    |    200,000 |      0.11 |              0.11 |      0.34 |  2.94 |          3.07 |
    |  2,000,000 |      1.49 |              1.45 |      3.28 |  2.20 |          2.27 |
    | 20,000,000 |     14.57 |             14.06 |     35.36 |  2.43 |          2.52 |

    vars  = x1 x2
    stats = sum mean sd max min count percent first last firstnm lastnm median iqr p23 p77

    |          N | gcollapse | gcollapse (multi) | fcollapse | ratio | ratio (multi) |
    | ---------- | --------- | ----------------- | --------- | ----- | ------------- |
    |    200,000 |      0.15 |              0.12 |      1.00 |  6.79 |          8.04 |
    |  2,000,000 |      1.86 |              1.79 |     15.53 |  8.33 |          8.69 |
    | 20,000,000 |     20.83 |             19.04 |    256.49 | 12.32 |         13.47 |
```

The `gcollapse` and `fcollapse` columns show the execution time in
seconds. We can see `gcollapse` is several times faster than `fcollapse`
in our benchmarks, and that `fcollapse` is specially slow relative to
`gcollapse` at computing quantiles for large groups.

### Increasing the number of levels

We vary J for N = 5,000,000:
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean sd max min count percent first last firstnm lastnm

    |         J | gcollapse | gcollapse (multi) | fcollapse | ratio | ratio (multi) |
    | --------- | --------- | ----------------- | --------- | ----- | ------------- |
    |        10 |      3.31 |              3.33 |      7.51 |  2.26 |          2.25 |
    |       100 |      4.07 |              3.95 |      7.59 |  1.86 |          1.92 |
    |     1,000 |      4.54 |              4.29 |      8.64 |  1.90 |          2.02 |
    |    10,000 |      5.17 |              5.26 |     10.49 |  2.03 |          1.99 |
    |   100,000 |      6.09 |              5.78 |     14.15 |  2.32 |          2.45 |
    | 1,000,000 |      8.89 |              7.87 |     32.71 |  3.68 |          4.15 |

    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean sd max min count percent first last firstnm lastnm median iqr p23 p77

    |         J | gcollapse | gcollapse (multi) | fcollapse | ratio | ratio (multi) |
    | --------- | --------- | ----------------- | --------- | ----- | ------------- |
    |        10 |      5.16 |              4.88 |     50.86 |  9.86 |         10.43 |
    |       100 |      5.48 |              5.23 |     30.55 |  5.57 |          5.84 |
    |     1,000 |      6.26 |              5.79 |     24.02 |  3.84 |          4.14 |
    |    10,000 |      7.74 |              6.30 |     22.60 |  2.92 |          3.59 |
    |   100,000 |     19.83 |             13.16 |     28.75 |  1.45 |          2.19 |
    | 1,000,000 |    146.76 |             59.05 |     86.43 |  0.59 |          1.46 |
```

While `fcollapse` is inefficient at computing quantiles for large of
groups relative to `gcollapse`, the converse is true for a large number
of small groups: With 1M groups and 5M observations, `fcollapse` is
faster at computing quantiles than the single-threaded version of
`gcollapse`, and the multi-threaded version is only 33% faster.

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
gegen target = quantile(var), by(varlist) p#
```

Where # is a "percentile" (though it can have arbitrary decimal places,
which allows computing quantiles; e.g. 2.5 or 97.5).


A word of caution
-----------------

At the moment this code is very beta and has not been extensively tested
in the way collapse has. Furthermore, there are some glaring problems:
- Memory management is terrible (see below).
- It is only available in Unix.
- Computing quantiles is inefficient.
- Unlike `fcollapse`, the user cannot add functions easily (it uses compiled C code).

Despite this, it has several advantages:
- It's several times faster than `fcollapse`. On smaller data (thousands
  or low millions) it is 2-10 times faster than `fcollapse`, which is in
  turn ~3 times faster than plain `collapse`. See benchmarks above. (for
  data in the tens of millions the speed gains compound because the main
  bottleneck in `gcollapse` is the overhead involved in setting up the
  data before calling the C plugin)
- Grouping variables can be a mix of numeric and string variables,
  unlike `fcollapse` which limits by variables to be of the same type.
- Quantiles are computed to match Stata's `collapse`, unlike `fcollapse`.
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
   (unless you're working with groups in the quintillions, 10^18
   _levels_, not observations). Hashing here is also faster than hashing
   in Sergio Correia's `ftools`, which uses a 32-bit hash and will run
   into collisions just with levels in the thousands, so he has to
   resolve collisions.

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

To compile the plugin, simply run
```
make
```

This is NOT cross-platform. You have to edit `./Makefile` to have
it compile elsewhere. To copy the files to `./build`, run
```
./build.py
```

This script also compiles the plugin, so you can just run `./build.py`.

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
devised by Bob Jenkins, which is a 128-bit hash in two 64-bit parts.
This is perfect for our purposes: We want to use a counting sort, but if
the integer key is too large then this becomes unfeasible. We sort the
first half 16-bits at a time using a radix sort (multiple passes of a
counting sort). Sorting on the 64-bit key will be enough for most data
(remember it's one hash per _level_, not per observation, and 64 bits
is enough until we have levels in the billions). However, we check all
the elements of the second 64-bit portion of the hash are the same for
a given 64-bit entry, and if there is a 64-bit hash collision, so to
speak, we sort by the second half of the hash as well.

A 128-bit hash collision is _de facto_ impossible, unless someone
is actively trying to corrupt your data. Remember this is not a
general-purpose hash, but merely a way to index the levels implied by a
set of variables in a particular dataset (where observations are capped
at just over 20 billion anyway), and hence only needs to produce numbers
that are unique _for that particular dataset_.

TODO
----

- [ ] Implement all of `gegen`.
- [ ] Improve memory management.
- [ ] Compile for Windows and OSX.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
