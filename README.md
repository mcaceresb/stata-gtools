Faster Stata for Group Operations
---------------------------------

`version 0.4.0 23May2017`

---

This is currently a beta release. This package uses a C-plugin
to provide a faster implementation for Stata's `collapse` called
`gcollapse` that is also faster than Sergio Correia's `fcollapse` from
`ftools`. Futher, group variables can be a mix of string and numeric,
like `collapse`. It also provides some support for by-able `egen`
functions via `gegen`.

Currently, memory management is **VERY** bad. If you are generating many
simple summary statistics from a single variable, the overhead may not
be worth it. I plan a massive improvement to this for version 0.5.0.

At the moment, only Unix versions of the plugins are available. Windows
and OSX versions are planned for a future release.

- [Installation](#installation)
- [Benchmark](#benchmark)
- [Building](#building)
- [FAQs](#faqs)
- [Miscellaneous Notes](#miscellaneous-notes)
- [License](#license)

Installation
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
Further, since my own machine and the servers I have access to run
Linux, I have only developed this for Stata for Unix so far. Future
releases will be cross-platform.
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

Benchmark
---------

See `src/test/bench_gcollapse.do` for the benchmark code. We have 3 benchmarks:
- `ftools`-style benchmarks: Collapse a large number of observations
  to 100 groups. We sum 15 variables, take the mean and median of 3
  variables, and take the mean, sum, count, min, and max of 6 variables.

- Increasing group size: We fix the sample size at 50M and increase
  the group size from 10 to 10M in geometric succession. We compute
  all available stats (and 2 sample percentiles) for 2 variables.

- Increasing sample size: We fix the group size at 10 and increase the
  sample size from 20,000 to 200M in geometric succession. We compute all
  available stats (and 2 sample percentiles) for 2 variables.

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
case, and I have not yet had time to run them. (Benchmarks for the old
version are still available in `./src/test/bench_mp-0.3.log`.)

All commands were run with the `fast` option.

### Benchmarks in the style of `ftools`

We vary N for J = 100 and collapse 15 variables:
```
    vars  = y1-y15 ~ 123.456 + U(0, 1)
    stats = sum

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      0.81 |      6.26 |      3.48 |        4.32 |        7.77 |
    |  20,000,000 |      8.66 |     76.73 |     34.64 |        4.00 |        8.86 |
    | 200,000,000 |     83.11 | [not run] |    368.81 |        4.44 |   [not run] |
```

In the tables, `g`, `f`, and `c` are code for `gcollapse`, `fcollapse`,
and `collapse`, respectively. We repeat the exercise but with more
complex summary statistics:
```
    vars  = y1-y3 ~ 123.456 + U(0, 1)
    stats = mean median

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      0.69 |      8.33 |      3.54 |        5.15 |       12.11 |
    |  20,000,000 |      4.93 |    109.10 |     43.09 |        8.73 |       22.12 |
    | 200,000,000 |     52.96 | [not run] |    613.47 |       11.58 |   [not run] |
```

We see `gcollapse` is 4-11 times faster than `fcollapse` and 8-22 times
faster than `collapse`, with larger speed gains for complex statistics
and a large number of observations. We devised one more benchmark:
Multiple simple statistics for many variables.
```
    vars  = y1-y6 ~ 123.456 + U(0, 1)
    stats = sum mean count min max

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |   2,000,000 |      3.90 |     36.44 |      3.37 |        0.86 |        9.35 |
    |  20,000,000 |     37.88 |    459.67 |     34.20 |        0.90 |       12.13 |
    | 200,000,000 |    389.19 | [not run] |    338.76 |        0.87 |   [not run] |
```

`gcollapse` performs really poorly in this scenario. We detail the
reason why further down in this section, but the short story is that
C cannot create variables in Stata. My initial solution for this was
to create the target variables first, populate them with the collapsed
data, and then keep the first J observations after the collapse.

This is glaringly inefficient in situations like these: 30 targets for 6
variables means creating at least 24 variables, each occupying 8 bytes *
200M observations, or 1.5GiB. In other words, Stata allocates 32GiB of
memory _before_ calling the C plugin. This makes no sense in this case,
because the collapsed data would only occupy 23KiB.

For the 0.5.0 release, I plan to have `gcollapse` be smart about writing
the collapsed data to disk and reading that back into Stata if the
trade-off indicates it will be efficient to do so.

### Increasing the sample size

Data was sorted on a random variable before collapsing. We vary N for J = 10:
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |           N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |
    | ----------- | --------- | --------- | --------- | ----------- | ----------- |
    |     200,000 |      0.14 |      7.62 |      0.81 |        5.95 |       56.04 |
    |   2,000,000 |      2.21 |    110.26 |      9.65 |        4.37 |       49.98 |
    |  20,000,000 |     26.48 |   1520.18 |    142.84 |        5.39 |       57.41 |
    | 200,000,000 |    263.46 | [not run] |   2670.32 |       10.14 |   [not run] |
```

We can see that `collapse` does not handle multiple complex statistics
particularly well as N grows. `gcollapse` was more than 50 times faster.
`fcollapse` performed better, but`gcollapse` was still 4-10 times faster

### Increasing the number of levels

Data was sorted on a random variable before collapsing. We vary J for N = 5,000,000:
```
    vars  = x1 x2 ~ N(0, 1)
    stats = sum mean max min count percent first last firstnm lastnm median iqr p23 p77

    |          J | gcollapse | fcollapse | ratio (f/g) |
    | ---------- | --------- | --------- | ----------- |
    |         10 |     62.29 |    508.00 |        8.16 |
    |        100 |     65.88 |    284.83 |        4.32 |
    |      1,000 |     58.34 |    253.01 |        4.34 |
    |     10,000 |     60.31 |    231.36 |        3.84 |
    |    100,000 |     69.40 |    221.33 |        3.19 |
    |  1,000,000 |     67.21 |    299.31 |        4.45 |
    | 10,000,000 |     82.47 |   1075.93 |       13.05 |
```

We have not benchmarked `collapsed` against version `0.4.0` because when
we benchmarked it against version `0.3.0` it took almost an hour for
each run of this benchmark and we have not found the time. `fcollapse`
did better for a modest numbers of groups, but it performed poorly for
very few groups and for a large number of groups. Overall `gcollapse`
was 3-13 times faster.

### Comparing `gcollapse` and `fcollapse` at their worst

`gcollapse` performed worst when computing many simple statistics for
200M observations. `fcollapse` performed worst when computing many
complex statistics for 10M groups. We benchmark a run for N = 200M and
J = 40M for many simpe statistics:
```
    vars  = x1 x2 x3 x4 x5 x6
    stats = sum mean count min max
    N = 200,000,000
    J =  40,000,000

    | gcollapse | fcollapse | ratio (f/g) |
    | --------- | --------- | ----------- |
    |    281.30 |   2015.36 |        7.16 |
```

### The Stata overhead

In the last benchmark above, we ran
```
. local stats mean count min max sum
. local vars x1 x2 x3 x4 x5 x6

. local collapse ""
. foreach stat of local stats {
.     local collapse `collapse' (`stat')
.     foreach var of local vars {
.         local collapse `collapse' `stat'_`var' = `var'
.     }
. }

. bench_sim, n(200000000) nj(40000000) nvars(6)
. gcollapse `collapse', by(group) benchmark fast

Parsed by variables, sources, and targets; .014 seconds
Generated targets; 104.1 seconds
        Plugin step 1: stata parsing done; 0.000 seconds.
        Plugin step 2: Hashed by variables; 15.290 seconds.
        Plugin step 3: Sorted on integer-only hash index; 63.110 seconds.
        Plugin step 4: Set up variables for main group loop; 5.950 seconds.
        Plugin step 5.1: Read source variables in parallel; 11.654 seconds.
        Plugin step 5.2: Collapsed variables in parallel; 1.712 seconds.
        Plugin step 6: Copied collapsed variables back to stata; 17.940 seconds.
The plugin executed in 119.2 seconds
Program exit executed in 58 seconds
The program executed in 281.3 seconds
```

We can clearly see the bottleneck is the Stata overhead: Indeed, nearly
40% of the execution time is spent adding the target variables, and
another 20% in sorting the data at the end. We are working on a solution
that sorts the data in C, and that is smart about writing the collapse
to disk for it to be read by Stata later.

In this case the data would not be written to disk, as the I/O involved
in writing 40M observations should not be faster than creating the
variables in memory.

Building
--------

If you want to compile the plugin yourself, atop the C standard library
you will need
- [`centaurean`'s implementation of spookyhash](https://github.com/centaurean/spookyhash)
- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2/) (SPI).

From the root folder of this repo, first compile `spookyhash`:
```
cd lib/spookyhash/build
make
cd -
```

If that compiles correctly, you can run
```
./build.py
```

to compile the plugin and copy the files to `./build`. This tries to run
`make` as one of the steps, so if you are not on Linux you will have to
modify `./Makefile`.

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

### What functions are available?

Most of the `collapse' functions are supported:

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

The percentile syntas mimics that of `collapse` and `egen`:
```stata
gcollapse (p#) target = var [target = var ...] , by(varlist)
gegen target = pctile(var), by(varlist) p(#)
```

Where # is a "percentile" (though it can have arbitrary decimal places,
which allows computing quantiles; e.g. 2.5 or 97.5).

Miscellaneous Notes
-------------------

### Generating group IDs in `gegen`

I do not intend to re-implement all of `egen`, just by-able functions.
Atop the currently supported calls, two generic `egen` functions are
provided that are much faster than their counterparts
```stata
gegen id  = group(varlist)
gegen tag = tag(varlist)
```

Both are much faster than `egen` because they do not sort the data, and
rather rely on hashes to tag the data and generate an id as new groups
appear. This means `group` will ID the first group that appears as 1 and
the last as J; `egen` will sort the data first.

### Memory management

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
variable, memory consumption should not exceed that of `collapse` or
`fcollapse`.

### Hashing

The idea behind using a hash is simple: Sorting a single integer
grouping variable is much faster than sorting on multiple variables
with arbitrary data (in particular, we can use a counting sort, which
asymptotically performs in `O(n)` time compared to `O(n log n)` for the
fastest general-purpose sorting algorithms).

Given `K` by variables, `by_1` to `by_K`, where `by_k` belongs the set
`B_k`, the general problem we face is devising a function `f` such that
`f: B_1 x ... x B_K -> N`, where `N` are the natural (whole) numbers.
Given `B_k` can be integers, floats, and strings, the natural way of
doing this is to use a hash: A function that takes an arbitrary sequence
of data and outputs data of fixed size.

In particular we use the [Spooky Hash](http://burtleburtle.net/bob/hash/spooky.html)
devised by Bob Jenkins, which is a 128-bit hash. Stata caps observations
at 20 billion or so, meaning a 128-bit hash collision is _de facto_ impossible.

### TODO

- [ ] Compile for Windows and OSX.
- [ ] Improve memory management.
- [ ] Implement all by-able `egen` functions.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
