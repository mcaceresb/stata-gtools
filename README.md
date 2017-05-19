Faster Stata for Group Operations
---------------------------------

This is currently an alpha release. This package uses a C-plugin
to provide a faster implementation for Stata's `collapse` called
`gcollapse` and is also (almost always) faster than Sergio Correia's
`fcollapse` from `ftools`.

Currently, memoy management is **VERY** bad, so if you are generating
many summary variables from a single source variable, please see the
memory management section below. Support for `egen` is limited, and only
`gcollapse` for Unix is available. Future releases will support the full
range of `egen` functions and will be cross-platform.

- [Requirements](#requirements)
- [Installation](#installation)
- [Benchmark](#benchmark)
- [A word of caution](#a-word-of-caution)
- [FAQs](#faqs)
- [Memory Management](#memory-management)
- [Building](#building)
- [A brief note on hashing](#a-brief-note-on-hashing)
- [License](#license)

Requirements
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
My own machine and the servers I have access to run Linux, so I have
only developed this for Stata for Unix so far. Future releases will be
cross-platform.

If you want to compile the plugin yourself, atop the C standard library
- [`centaurean`'s implementation of spookyhash](https://github.com/centaurean/spookyhash)
- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2/) (SPI).

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

Benchmark
---------

A word of caution
-----------------

At the moment this code is very alpha. While it produces identical
results to collapse (up to numerical precision rounding), it has not
been extensively tested in the way collapse has. Furthermore, there are
some glaring problems:
- Computing quantiles is hugely inefficient. Under most scenarios,
  `gcollapse` will be 2-5 times faster than `fcollapse`. In testing,
  however, computing multiple quantiles on data with hundreds of
  thousands or millions of levels resulted in slower speeds. (Short of
  that, evel with several million observations and tens of thousands of
  levels, `gcollapse` will be faster.)
- Memory management is terrible (see below).
- It is only available in Unix
- I sort the resulting data using using Stata.
- The C implementation is very crude (e.g. no multithreading)
- Unlike `fcollapse`, the user cannot add functions easily (it uses compiled C code).

Despite this, it has several advantages:
- It's almost always 2-5 times faster than `fcollapse`, which is in turn
  ~3 times faster than plain `collapse`. See benchmarks above.
- Grouping variables can be a mix of numeric and string variables,
  unlike `fcollapse` which requires the by variables be all numeric or
  all strings.
- Percentiles are computed to match Stata's (`fcollapse` uses a quantile
  function from moremata that does not necessarily match `collapse`'s
  percentile function).
- Can compute arbitrary quantiles, not just percentiles (e.g. p2.5 and
  p.97.5 would be valid stat calls in `gcollapse`).

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
millions, but if you have, for example, 100M observations, then a singe
variable will take up ~0.8GiB in memory. In that scenario, even a dozen
targets for a single variable may exceed the memory capacity of most
personal computers.

The function tries to be smart about this: Variables are only created
from the _**second**_ target onward. If you have one target per
variable, memory consumption should not exceed that of `collapse` of `fcollapse`.

Building
--------

I provide a python-based solution that should be cross-platform,
but I have not had the opportunity to test it outside of Linux.
To place the contents of the package on `./build`, simply run
```
./build.py
```

A brief note on hashing
-----------------------

The idea behind using a hash is simple: Sorting a single integer
grouping variable is much faster than sorting o multiple variables
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
This is perfect for our purposes: We sort on this hash using a counting
sort, and if the integer key is too large then this becomes unfeasible.
We sort the first half 16-bits at a time using a radix sort (multiple
passes of a counting sort). Sorting on the 64-bit key will be enough for
most data (remember it's one hash per _level_, not per observation, and
64 bits is enough until we have levels in the billions). However, we
check all the elements of the second 64-bit portion of the hash are the
same for a given 64-bit entry, and if there is a 64-bit hash collision,
so to speak, we sort by the second half of the hash.

A 128-bit hash collision is _de facto_ impossible, unless someone
is actively trying to corrupt your data. Remember this is not a
general-purpose hash, but merely a way to index the levels implied by a
set of variables in a particular dataset (where observations are capped
at a few dozen billion anyway), and hence only needs to produce numbers
that are unique _for that particular dataset_.

TODO
----

- [ ] Improve memory management.
- [ ] Efficient quantile implementation.
- [ ] Implement `gegen`.
- [ ] Compile for Windows and OSX.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
