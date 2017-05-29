Change Log
==========

## gtools-0.5.0 (2017-05-28)

### Misc
* Moved away from using regexes in C code. Now just pass the quantile as a
  string directly from Stata and use `atof`

## gtools-0.4.0 (2017-05-23)

### Features

* Somewhat faster: The function tries to choose the multi-threaded
  version of the plugin when available, and non-multi otherwise. It is
  also smarter about recasting variables.
* Various undocumented options to test and benchmark different
  algorithms for reading and collapsing the data.

### Bug fixes

* `gegen` now computes the first and last non-missing observations
  correctly when there is an if statement involved in the call.
* `gcollapse|gegen` now correctly finds first and last when there are
  missing values.
* `gcollapse|gegen` now correctly populates firstnm and lastnm with
   missing values when all observations are missing.
* `gcollapse|gegen` now output the sum as 0 of all missing values
  to mimic `collapse`.
* `benchmark` now correctly times parallel execution.

### Known problems

* `gcollapse` does not work correctly with `merge` when the user asks
  for an if statement, so when it is tried the function exits with
  error.
* Checkhash may give false positives when checking strings. It will
  occasionally read more data than necessary to make the comparison,
  resulting in a false positive. Working on a fix, but for now I moved
  the function to be undocumented, `mf_checkhash`

### Misc

* Updated benchmarks
* Cleaned up method for reading data in from Stata. Kept the sequential
  and the out-of-order methods (parallel out of order for the
  multi-threaded version).
* Normalized method of reading data from Stata in gegen.
* Added some undocumented options to control what is executed in
  parallel and what isn't when running with `multi`.

### Planned

* If you optimize the adding variables thing, then you can fix checkhash
  and have that be the default behavior. Print a message with option
  `verbose` that says "(found no hash collisions in N = %'lu, J = $'lu)".
  Further, if you sort the data in C, then assert the sort is unique and
  print "(hashed correctly grouped observations: resulting sort is unique)"
* Allow merge with an if statement (low priority; feature).
* Sort variables in C, not in Stata (high priority; performance)
* Be smart about memory management (high  priority; performance).
  This should be allowed to be negated via option -greedy- or similar,
  and would, of course, be ignored with -merge-):

For k1 sources and k2 targets, when k2 - k1 > 0 and `_N` is above some
threshold, say 10M, then kick off this hassle to figure out if adding
variables is worth it. We start by adding an "index" option to the
plugin which generates two variables, `index` and `info`, and saves to
`__gtools_J` the number of groups (it should also save the benchmark
below, and if possible the space in the /tmp folder that it found so it
can figure out whether the disk may get full by us doing this; it will
take J * k2 * sizeof(double) bytes, so worry about the amount of space
in /tmp). Use this to benchmark how much time it takes for Stata to add
two numeric variables (which will be long or double). If it added them
in `bench_stata` seconds, then define

    rate_stata = 8 * 2 * _N / bench_stata

Then we benchmark how much time it takes for C to read/write data from
disk. We write some number, say 1MiB, of random data to disk. We then
read it back. Call the time it took `bench_c`. Then define

    rate_c = 1024 * 1024 / bench_c

(Note: define `bench_c` as, e.g., MAX(1, bench)?) We now have the
approximate rate in seconds at which Stata can create data in memory and
at which C can write and read back data from disk. The times it would
take to add variables in Stata is

    time_stata = (k2 - k1) * _N * 8 / rate_stata

And in C it is

    time_c = k2 * __gtools_J * 8 / rate_c

If `time_c` * threshold < `time_stata` then we should write
to disk from C and then read the data. I think threshold should be
a large number, e.g. 10 or 100, to be safe. Then we can do:

      tempfile __gtools_collapsed_file
      cap `noi' `plugin_call' `plugvars', collapse write `__gtools_collapsed_file'

      keep in 1 / `:di scalar(__gtools_J)'
      mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
      order `by' `gtools_targets'
      set obs `:di scalar(__gtools_J)'
      cap `noi' `plugin_call' `by' `gtools_targets', read `__gtools_collapsed_file'

The collapse to disk code would use the info and index variables created
earlier, rather than re-hashing and re-sorting the data, to collapse the
sources to the targets and write to `__gtools_collapsed_file`.

---

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
