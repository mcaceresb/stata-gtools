Change Log
==========

## gtools-0.6.1 (2017-06-17)

### Bug fixes

- Program now installs correctly from build folder on Windows. I had to
  create a `gtools.ado` file and tell the user to run `gtools, dependencies`
  to install spookyhash.dll so Stata can find it...

### Misc

- Tried and failed to compile on OSX using Travis, but cleaned it up
  enough that it will be easier to compile once I get access to OSX, if
  ever. Windows version still OK.

## gtools-0.6.0 (2017-06-16)

### Features

- Windows version passing all tests; benchmarked on virtualbox.

### Bug fixes

- `gegen tag()` now gives the correct result when there are no obs that
  match the tag (e.g. all missing). Previous versions returned all
  missing values. The new version returns all 0s, matching `egen`.

### Known problems

* The multi-threaded version does not load on Windows. Getting this to
  work on Windows was painful enough that I have 0 plans to debug it at
  this time. The single-threaded version works fine, however, and is
  already plenty fast.

* The marginal time to add a variable to memory is non-linear. If there
  are 100 variables in memory, adding the 101th varaible will take
  longer than if there are 0 variables in memory and we are adding the
  first one. This is problematic because we try to estimate the time
  by benchmarking adding two variables. The non-linear relation is not
  obvious as it would depend on the user's system's RAM and CPU. Hence
  we simply scale the benchmark by K / 2.

* Stata's timer feature is only accurate up to miliseconds. Since adding
  the two variables for benchmarking is faster than adding marginal
  variables thereafter, occasionally Stata incorrectly estimates the
  time to add a variable to be 0 seconds. Empirically it does not bear
  out that adding variables after the benchmark variables takes more
  than 0 seconds. Hence we assume that Stata would actually take 0.001
  seconds to add 2 variables to memory.

### Planned

* Sort variables in C, not in Stata (high priority; performance)
* Allow merge with an if statement (low priority; feature).
* If you sort the data in C, then assert the sort is unique and
  print "(hashed correctly grouped observations: resulting sort is unique)"
* Allow `greedy` option to skip drops and recasting? (Depending on
  the implementation this may be slower because adding variables takes
  longer with more variables in memory.)

---

## gtools-0.5.2 (2017-06-15)

### Misc

* Added Travis CI integration.
* Improved README (logo, cleaner flow, better compilation instructions).

### Bug fixes

- Properly added spookyhash as submodule.
- Compiles with Travis CI

## gtools-0.5.1 (2017-06-14)

### Bug fixes

* In prior versions, if `gcollapse` was called with no observations or
  when the result of `if in` gave no observations, the function throwed
  an error. Now the program exits and prints "no observations" to the
  console (`gcollapse` returns an empty data set; `gegen` returns a
  variable with all missing values).
* In prior versions, in some cases, when multiple statistics are
  generated from a single source and the summary statistics are
  collapsed to disk, the first statistic may be swapped for another.
  This happened because the function tries to use source variables and
  targets, and it also tries to be smart about which target statistic
  to use the source variable for. So if you request mean and min for
  a byte, the function will want outputs to be at least float and
  byte, and will use the source variable for the min and generate
  an additional variable for the mean. This had been implemented
  incorrectly when collapsing to disk.
* Added additional unit tests for collapsing to disk.

## gtools-0.5.0 (2017-06-14)

### Features

* The function tries to be smarter Be smart about memory management.
  When `merge` is not specified, N is larger than 1M, and there are
  more than 3 additional targets to create in memory, the function
  tries to figure out whether collapsing the data and writing the
  collapsed data for the extra targets to disk is faster than creating
  the targets in memory and collapsing to memory.

  While collapsing to memory is faster than collapsing to disk,
  generating variables in memory with N observations, before collapsing,
  is slower than for J observations, after collapsing. For J small enough
  (e.g. 10 groups vs 1M observations) it is more efficient to collapse
  to disk and read the data back in after. The rules
    * `merge` merges back to the original data, so we do not collapse to disk.
    * `forceio` forces the function to collapse to disk.
    * `forcemem` forces the function to collapse to memory.
    * Otherwise, if N > 1M and the number of variables to add is K > 3,
      the function benchmarks how long it would take C to write and
      read `K * 8 * J / 1024^2` MiB and then creating K variables
      in memory for J observations vs creating K variables for N
      observations.
    * Creating observations is memory is given the "benefit of the doubt"
      by a factor of 10. So we have to estimate writing to disk
      and creating variables after the collapse will be at least
      10 times faster for the swtich to take place.
* String by variables are now read into C and written back into Stata
  directly. Prior versions generated temporary variables to read string
  by variables into the temporary variables and then copied them back.
  This was inefficient.
* Moved away from using regexes in C code. Now the function just passes
  the quantile as a string directly from Stata and uses `atof`. This is
  marginally faster and eliminates a dependency.

### Backwards-incompatible

* All undocumented `mf_` options have been changed to `debug_`

### Bug fixes

* Option `debug_checkhash` seems to work properly now. This was fixed by
  zero-ing the string that was used as the temporary buffer for reading
  in Stata variables.

### Known problems

* The marginal time to add a variable to memory is non-linear. If there
  are 100 variables in memory, adding the 101th varaible will take
  longer than if there are 0 variables in memory and we are adding the
  first one.
* This is problematic because we try to estimate the time by
  benchmarking adding two variables. The non-linear relation is not
  obvious as it would depend on the user's system's RAM and CPU.
  Hence we simply scale the benchmark by K / 2.
* Stata's timer feature is only accurate up to miliseconds. Since adding
  the two variables for benchmarking is faster than adding marginal
  variables thereafter, occasionally Stata incorrectly estimates the
  time to add a variable to be 0 seconds. Empirically it does not bear
  out that adding variables after the benchmark variables takes more
  than 0 seconds. Hence we assume that Stata would actually take 0.001
  seconds to add 2 variables to memory.

### Planned

* Allow `greedy` option to skip drops and recasting? (Depending on
  the implementation this may be slower because adding variables takes
  longer with more variables in memory.)
* Sort variables in C, not in Stata (high priority; performance)
* Allow merge with an if statement (low priority; feature).
* If you sort the data in C, then assert the sort is unique and
  print "(hashed correctly grouped observations: resulting sort is unique)"

---

## gtools-0.4.1 (2017-05-29)

### Bug fixes

* `gegen` now generates the expression passed to its functions if the
  argument is not a varlist.

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

* Allow merge with an if statement (low priority; feature).
* Sort variables in C, not in Stata (high priority; performance)
* If you sort the data in C, then assert the sort is unique and
  print "(hashed correctly grouped observations: resulting sort is unique)"
* Be smart about memory management when J is small relative to N.

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
