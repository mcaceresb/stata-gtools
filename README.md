Faster Stata for Group Operations
---------------------------------

This is currently a proof-of-concept package that uses a C-plugin
to provide a faster implementation for Stata's `collapse` called
`gcollapse` and is also (almost always) faster than Sergio Correia's
`fcollapse` from `ftools`.

Currently, memoy management is **VERY** bad, so if you are generating
many summary variables from a single source variable, please see the
memory management section below.

Currently only `gcollapse` for Unix is available. Feature releases
will also provide `gegen` and be cross-platform.

Requirements
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
My own machine and the servers I have access to run Linux, so I have
only developed this for Stata for Unix so far. Future releases will be
cross-platform.

If you want to compile the plugin yourself, atop the C standard library
- [`ceanturian`'s implementation of spookyhash](https://github.com/centaurean/spookyhash)
- v2.0 of the [Stata Plugin Interface](https://stata.com/plugins/version2/) (SPI).

FAQs
----

### How can this be faster?

In theory, C shouldn't be faster than Stata native commands because,
as I understand it, many of Stata's underpinnings are compiled C code.
However, there are two explanations why this is faster than Stata's
native commands:

1. Hashing: I hash the data using a 128-bit hash and sort on this hash
   using a radix sort (a counting sort that sorts large integers X-bits
   at a time; I choose X to be 16). This is much faster than sorting
   on arbitrary data. Further, with a 128-bit hash you shouldn't have
   to worry about collisions (unless you're working with groups in the
   quintillions, 10^18 _levels_, not observations). Hashing here is also
   faster than Hashing in Sergio Correia's `ftools`, which uses a 32-bit
   hash and will run into collisions just with levels in the thousands,
   so he has to resolve collisions.

2. Efficiency: It is possible that Stata's algorithms are not particularly
   efficient (this is, for example, the explanation given for why `ftools`
   is faster than Stata even though Mata should not be particularly fast).

### Why use platform-dependent plugins?

C is platform dependent and I don't have access to Stata on Windows or
OSX. Sorry! I use Linux on my personal computer and on all the servers
where I do my work. If anyone is willing to try compiling the plugins
out on Windows and OSX, I'd be happy to take pull requests!

WARNING
-------

This is intented as a proof-of-concept at the moment and is very alpha.
The code has not been optimized at all and several features area missing:
- Computing quantiles is inefficient to the point that if you are
  requesting multiple quantile summaries for a large number of levels
  (hundreds of thousands or millions), `fcollapse` may be faster. In
  testing, this was the only scenario in which `fcollapse` was faster
  or performed at comparable speeds.
- Memory management is terrible (see below).
- It is only available in Unix
- Unless requesting first, firstnm, last, lastnm, min, or max, I ignore
  types and do all operations in double precision. I should try to use
  whatever the user-specified default is. (PS: Since Stata does not implement
  `long long` or unsigned ingeters, just long, even operations like `sum`
  need to be double).
- I sort the resulting data using using Stata.
- The C implementation is very crude (e.g. no multithreading)
- Unlike `fcollapse`, the user cannot add functions easily (it uses compiled C code).

Despite this, it has some advantages:
- It's several times faster than `fcollapse`, which is in turn several times faster than plain `collapse`.
- Grouping variables can be a mix of numeric and string variables,
  unlike `fcollapse` which requires the by variables be all numeric or
  all strings.
- Percentiles are computed to match Stata's (fcollapse uses a quantile
  function from moremata that does not necessarily match collapse's
  percentile function)
- Can have quantiles not just percentiles (e.g. p2.5 and p.97.5 would be
  valid stat calls in gcollapse )

Memory Management
-----------------

_**Pending**_

Installation
------------

```stata
net install gtools, from(https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/)
```

To update, run
```stata
adoupdate, update
```

To uninstall, run
```stata
ado uninstall gtools
```

Building
--------

I provide a python-based solution that should be cross-platform,
but I have not had the opportunity to test it outside of Linux.
To place the contents of the package on `./build`, simply run
```
./build.py
```

TODO
----

- [ ] Improve memory management.
- [ ] Efficient quantile implementation.
- [ ] Implement `gegen`.
- [ ] Compile for Windows and OSX.
- [ ] Clean up C code-base.

License
-------

[MIT](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE)
