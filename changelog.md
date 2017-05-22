Change Log
==========

## gtools-0.3.3 (2017-05-21)

### Features

* Significantly sped up integer-only hash by computing the ranges in C,
  not in Stata.
* Data is now read sequentially from Stata. More extensive testing
  revealed this is usually faster.
* In the multi-threaded version, data is read in parallel. More extensive
  testing revealed this is usually faster.

### Planned

* Decide on a method to read in variables from stata; implement across
  all single and multi-threaded versions.

## gtools-0.3.2 (2017-05-20)

### Features

* Added `checkhash` option to check for hash collisions.

### Bug fixes

* Finished the benchmarks, both locally (IC) and on the server (MP)
* Normalized the execution of `gegen` and `gegen, multi`

### Misc

* Tested reading data from Stata sequentially (it's not faster)
* Improved README
* Various typo fixes in comments

## gtools-0.3.1 (2017-05-19)

### Bug fixes

* Speed up quantiles! (Also, all other functions). Encoded stat string
  to numeric: It's WAY faster to select a function based on a number
  than a string. String comparisons are expensive. I was also parsing
  the quantile string at EVERY function call, which was the bottleneck
  in computing quantiles, not quicksort.
* first and last observations now computed correctly when quantiles are
  also requested.
* Fixed `gtools.pkg`
* Added documentation for `gegen`
* Function names and calls closer to `egen`

## gtools-0.3.0 (2017-05-19)

### Features

* `gegen` implementation with all of `gcollapse`'s functions, as well as
  `total` as an alias for `sum`, `group` to generate an id for a given
  group, and `tag` to tag the first observation in a given group.
* `if` and `in` are correctly supported in `gegen`.
* Both `gegen` and `gcollapse` have multi-threaded versions.
* Note `gegen newvar = group(varlist)` tags the first appearance of a
  group as 1, and so on. `egen` sorts the data, so the group taged as 1
  is the 'first' group, and so on. If you want that behavior you should
  use `egen`; `gegen` is only suitable when you want to index the data
  and you don't mind that it won't be sorted right away.

### Bug fixes

* Fixed bug in hashing strings so it now passes the correct number of
  bytes to the spooky hash (in prior versions, string hashes were not
  consistent).
* Fixed bug in integer bijection so it can now handle missing values.
* Fixed bug in quantile function where the first comparison element was
  selected to be the first entry read from Stata, not the first group entry.

### Problems

* Only available when `c(os)` is Unix.
* Memory management is terrible. See previous notes or `README.md`
  section on memory management.
* Several by-able egen functions are missing
* Not provided
    * semean
    * sebinomial
    * sepoisson
    * rawsum

### Planned

* `checkmem` feature to call `fcollapse` or `collapse` when the plugin
  suspects there will not be enough memory.
* The rest of `gegen`'s by-able functions
* Improve memory management.

------------------------------------------------------------------------

## gtools-0.2.0 (2017-05-19)

### Features

* `gcollapse` `smart` option indexes thye data based on the sorted groups
  so no hashing and sorting is necessary. It no longer calls `collapse`,
  which is slower.
* `gcollapse` provides `merge` to merge the collapsed data back with the
  original data. This is much fastere than collapsing and then merging.
* `gcollapse` provides `multi` to invoke the multi-threaded version of
  the collapse routine.
* Computing percentiles is less inefficient, but it is still inefficient.
  When this is particularly slow, the `multi` option can compensate.
* The code base is cleaner and the C code is (mostly) commented.

### Problems

* Only available when `c(os)` is Unix.
* Memory management is terrible. See previous notes or `README.md`
  section on memory management.
* Not provided
    * semean
    * sebinomial
    * sepoisson
    * rawsum

### Planned

* `checkmem` feature to call `fcollapse` or `collapse` when the plugin
  suspects there will not be enough memory.
* `gegen` as a drop-in replacement for `egen`'s by-able functions that
  should be faster than `fegen`.
* Improve memory management.

------------------------------------------------------------------------

## gtools-0.1.0 (2017-05-16)

### Features

* `gcollapse` provides a C-based near-drop-in replacement for `collapse`
  that is (almost always) several times faster than `fcollapse`.
* Though computing percentiles is currently very inefficient (see below),
  `gcollapse`, unlike `collapse` (of `fcollapse` as best I can tell) can
  compute quantiles, not just percentiles (e.g. p2.5, p15.25)

### Problems

* Only available `c(os)` is Unix.
* Quantile implementation is massively inefficient (via C's `qsort`). In
  fact, it it possible that `fcollapse` will be ~50% faster if there are
  many levels/sgroups (hundreds of thousands or millions) and more than
  a few percentiles (3 or more).
* Memory management is terrible. `fcollapse` does not consume too much
  more memory than collapse because mata can add and drop variables at
  requisite times. C, on the other hand, cannot add or drop variables
  in Stata, and target variables must already exit. This means that for
  every additional summary variable (i.e. 2 or more) based on a single
  source variable, Stata must create them before collapsing the data.
  Thus it is possible that systems that run `collapse` or `fcollapse`
  with ease are not able to run `gcollapse` due to the additional
  memory overhead. See the memory management section in `README.md` to
  estimate whether your system will be able to take advantage of the
  speed improvements of `gcollapse` if you are concerned about memory
  management.
* Not provided
    * semean
    * sebinomial
    * sepoisson
    * rawsum

### Planned

* `gegen` as a drop-in replacement for `egen`'s by-able functions that
  `should be faster than fegen`.
* Improve quantile implementation (perhaps using a better implementation
  of `quickselect`; my attempt at implementing quickselect was slowe
  than `qsort`).
* Improve memory management.
