<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

[Overview](#faster-stata-for-group-operations)
| [Installation](#installation)
| [Benchmarks](#benchmarks)
| [Building](#building)
| [FAQs](#faqs)
| [License](#license)

`version 0.5.2 15Jun2017`
[![Travis Build Status](https://travis-ci.org/mcaceresb/stata-gtools.svg?branch=develop)](https://travis-ci.org/mcaceresb/stata-gtools)

_Gtools_ is a Stata package that provides a fast implementation of
common group commands like collapse and egen using C-plugins for a
massive speed improvement.

Faster Stata for Group Operations
---------------------------------

This is currently a beta release. This package's aim is to provide a
fast implementation of group commands in Stata using C-plugins. At
the moment, the package's main feature is a faster implementation
of `collapse`, called `gcollapse`, that is also faster than Sergio
Correia's `fcollapse` from `ftools` (further, group variables can be
a mix of string and numeric, like `collapse`). It also provides some
(limited) support for by-able `egen` functions via `gegen`.

In our benchmarks, `gcollapse` was 5 to 120 times faster than `collapse`
and 3 to 20 times faster than `fcollapse` (the speed gain is smaller for
simpler statistics, such as sums, and larger for complex statistics,
such as percentiles). The key insight is two-fold: First, hashing the
data and sorting the hash is a lot faster than sorting the data before
processing it by group. Second, compiled C code is much faster than
Stata commands.

The current beta release only provides Unix versions of the C plugin.
Windows and OSX versions are planned for a future release.

Installation
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
Further, since my own machine and the servers I have access to run
Linux, I have only developed this for Stata for Unix so far. Future
releases will be cross-platform.
```stata
net install gtools, from(https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/build/)
* adoupdate, update
* ado uninstall gtools
```

The syntax is identical to `collapse`, except the current release does
not support weights
```stata
gcollapse (stat) target = source [(stat) target = source ...], by(varlist)
gcollapse (mean) mean_x1 = x1 (median) median_x1 = x1, by(groupvar)
```

Support for weights is planned for a future release.

Benchmarks
----------

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

### Benchmarks in the style of `ftools`

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

### Increasing the sample size

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

### Increasing the number of levels

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
against version `0.5.1` in this case because each run will take over
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

If you want to compile the plugin yourself, atop the C standard library
you will need
- The GNU Compiler Collection (`gcc`)
- [`premake5`](https://premake.github.io)
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)
- v2.0 or above of the [Stata Plugin Interface](https://stata.com/plugins/version2) (SPI).

I keep a copy of Stata's Plugin Interface in this repository, and I
have added `centaurean`'s implementation of SpookyHash as a submodule.
However, you will have to make sure you have `gcc` and `premake5`
installed and in your system's `PATH`.

### Compilation

```bash
git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --recursive
make spooky
./build.py --test
```

`./build.py` runs `make` to compile the plugins and places all
the requisite `.ado` files, `.sthlp` files, and test scripts in
`./build`. A log with the output of the test script will be printed
to `./build/gtools_tests.log`; if successful, the exit message should
be "tests finished running" followed by the start and end time.

### Troubleshooting

If you are not on Linux, you will have to comment out lines 34, 1167,
and 1170 in `./src/ado/gcollapse.ado` and lines 15, 517, and 520 in
`./src/ado/gegen.ado`. These lines prevent the function from running
outside Stata for Unix.

On OSX this will likely be enough. On Windows, however, it is possible
you will have to modify the Makefile (while this should compile from
Cygwin, it is possible the plugins will not load into Stata correctly)
or throw the Makefile away altogether and try to compile the plugin
using Visual Studio.

If the build fails, test that SpookyHash was compiled correctly:
```
make spookytest
```

These take a long time to run, so it is faster to try to test the plugin
first and only test SpookyHash if the plugin does not work.

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

### Why can't the function do weights?

I have never used weights in Stata, so I will have to read up on how
weights are implemented before adding that option to `gcollapse`.
Support for weight is coming, though!

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

The percentile syntax mimics that of `collapse` and `egen`:
```stata
gcollapse (p#) target = var [target = var ...] , by(varlist)
gegen target = pctile(var), by(varlist) p(#)
```

Where # is a "percentile" (though it can have arbitrary decimal places,
which allows computing quantiles; e.g. 2.5 or 97.5).

### Generating group IDs is different than `egen`

There are two generic `egen` functions provided that are much faster
than their counterparts
```stata
gegen id  = group(varlist)
gegen tag = tag(varlist)
```

Part of the reason they much faster than `egen` is that they do not sort
the data, and instead rely on hashes to tag the data and generate an id
as new groups appear. This means `group` will ID the first group that
appears as 1 and the last as J; `egen` will sort the data first.

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

- [ ] Add support for weights.
- [ ] Compile for Windows and OSX.
- [ ] Implement all by-able `egen` functions.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
