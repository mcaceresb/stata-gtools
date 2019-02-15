Change Log
==========

## gtools-1.3.2 (2019-02-14)

### Testing

- Hopefully fixes #40; might be related to #53

## gtools-1.3.1 (2019-02-11)

### Enhancements

- `greshape`'s preferred syntax is now `by()` and `keys()` instead
  of `i()` and `j()`; the docs and most of the printouts reflect this.

### Bug fixes

- `gtop`, `glevelsof`, and `gcontract` parse wildcards before
  adding any temporary variables, ensuring the latter don't
  get included in internal function calls.

- `greshape` no longer crashes if there are missing values in
  `keys()`/`j()`; the mata function `strtoname` converted "" into "";
  now I force missing to be converted to `_`.

- `glevelsof` and `gtop` should handle embedded characters better.
  Printing is still a problem but they get copied to the return
  values properly.

## gtools-1.3.0 (2019-02-08)

### Features

- `greshape long` and `greshape wide` are a fast alternative to
  reshape. It additionally implements `greshape spread` and `greshape gather`,
  which are analogous to the `spread` and `gather` commands from R's `tidyr`.

### Enhancements

- Added docs, examples `greshape` and `gstats`

### Bug fixes

- Fixes #49

## gtools-1.2.7 (2019-01-23)

### Enhancements

- Deleted all ancillary files and code related to `spookyhash.dll`

## gtools-1.2.6 (2019-01-19)

### Enhancements

- SpookyHash code compiled directly as part of the plugin. Might fix #35

## gtools-1.2.5 (2019-01-19)

### Enhancements

- Faster hash sort with integer bijection (two-pass radix sorts for
  smaller integers; undocumented option `_ctolerance()` allows the user
  to force the regular counting sort).

- Faster index copy when every observation is read (simply assign the
  index pointer to `st_info->index`)

## gtools-1.2.4 (2019-01-05)

### Bug fixes

- Stata 14.0 no longer tries to load SPI version 3 (loads version 2).
- Fixes #51: `gstats winsor` no longer fails with percentiles not strictly
  between 0 and 100.

## gtools-1.2.3 (2018-12-22)

### Bug fixes

- Fixes #50: `gstats winsor` no longer fills in missing values as the
  high percentile.

## gtools-1.2.2 (2018-12-18)

### Features

- `gstats winsor` now takes weights.

## gtools-1.2.1 (2018-12-16)

### Bug fixes

- `gstats winsor` no longer crashes with multiple variables.
- `gstats winsor, trim` correctly copies the source to the target.

## gtools-1.2.0 (2018-12-16)

### Features

- `gstats` general-purpose wrapper for misc functions.
- `gstats winsor` for Winsorizing and trimming data.

## gtools-1.1.2 (2018-11-16)

### Enhancements

- Improved variable parsing in general.
- Error message when variable not found now explicit.
- If `-` is found, warning message noting the default is to 
  interpret that as negative, not part of a varlist.
- `ds` and `nods` control parsing options for `-`

## gtools-1.1.1 (2018-11-14)

### Features

- `gcollapse, merge` and `gegen` now accept the undocumented option
  `_subtract` to subtract the result from the source variable. This is
  an undocumented option meant for advanced users, so no additional
  checks have been added. If you use it then you know what you're doing.

## gtools-1.1.0 (2018-11-02)

### Features

- `gcollapse (nmissing)` counts the number of missing values (weights
  allowed).

### Enhancements

- `gcollapse (nansum)` and `gcollapse (rawnansum)` preserve missing
  value (NaN) information: If all entries are missing, the output is also
  missing (instead of 0). This is a more flexible version of the previous
  implementation, `gcollapse, missing`.

### Bug fixes

- `gisid` no longer gives wrong results when the data is partially
  ordered. Partially (weakly) sorted data would be incorrectly counted
  as totally sorted.
- `gcollapse (rawsum)` gives 0 if all entries are missing.
- `gcollapse` and `gegen` correctly parse types with weights for counts
  and sums. This includes `gcollapse, sumcheck`
- Closes #45
- Closes #46
- Closes #47

## gtools-1.0.7 (2018-10-27)

### Features

- Added option `sumcheck` to create sum targers from integer source
  as the smallest type that reasonable given the total sum.
- Closes #44

### Enhancements

- Recast upgrade (bug fix from 1.0.5) now done per-variable.
- Added about section to readme, with some plugs (good idea? bad idea?)

## gtools-1.0.6 (2018-09-25)

### Enhancements

- All the help files (and the readme) ask the user to run `gtools, upgrade`

## gtools-1.0.5 (2018-09-20)

### Bug fixes

- `gcollapse` no longer gives wrong results when `count` is the first of
  multiple stats requested for a given source variable. Previous versions
  wrongly recast the source as long.

## gtools-1.0.4 (2018-09-16)

### Enhancements

* Typo fixes and improvements to gtools help file.

## gtools-1.0.3 (2018-08-18)

### Bug fixes

* Gtools exits with error if `_N > 2^31-1` and points the user to the
  pertinent bug report.

## gtools-1.0.2 (2018-08-08)

### Enhancements

* Specify that you can install via `ssc` and upgrade via `gtools, upgrade`
* Can selectively specify tests in `gtools_tests.do`

### Bug fixes

* Fixed minor bug in `gtools.ado` (`else exit {` is now `else {`)

## gtools-1.0.1 (2018-07-23)

### Bug fixes

* `gegen, replace` gave the wrong result if the source was also the target
  (`tag` and `group` worked, but all other stats did not).
* `gunique, by()` was affected by this bug and now works correctly.
* `gcollapse, merge` exits with error if there are no observations matching `if' `in'.

### Enhancements

* `gunique, by()` no longer prints the top unique levels by default unless
  the user asks for them via `detail`.

## gtools-1.0.0 (2018-07-21)

First official release! This will go on SSC once all the tests have
passed. Final TODOs:

[X] Tests from github 0.14.2 tag
    [X] Linux with Stata 13
    [X] Windows with Stata 13
    [X] Windows with Stata 15
    [X] Linux with Stata 15
    [X] OSX with Stata 14
[X] Read the documentation (Stata)
[X] Read the documentation (online)

### Enhancements

* `gtools, license v` prints the licenses of the open source projects
  used in gtools.

### Bug fixes

* Fixed typos in test script
* `gcollapse, merge` no longer replces targets without `replace`
* `glevelsof, gen(, replace)` no longer conflicts with `replace`

------------------------------------------------------------------------

## gtools-0.14.2 (2018-07-21)

Feature freeze!

### Features

* `gtop` (and `gtoplevelsof`) now accept weights.
* `glevelsof` has option `gen()` to store the levels in a variable.
* `glevelsof` has option `nolocal` to skip storing the levels in a local.

### Enhancements

* Added weights to the quick showcase in the README
* Added `gen()` to the quick `glevelsof' showcase
* Added `gen()` to the `glevelsof' usage page and examples.
* Added tests for `gtop [weight]` and `glevelsof, gen()`

### Bug Fixes

* `gegen()` with `replace` sets missing values outside `if in` range.

## gtools-0.14.1 (2018-07-19)

### Features

* `fasterxtile` and `gquantiles` now accept weights (including `by()`)
* Note that stata might not handle weights accurately in pctile
  and xtile (or, at the very least, it does not seem to follow its
  documented formulas in all cases).
* Option `compress` tries to recast strL variables as str#
* Option `forcestrl` ignores binary values check (use with caution).

### Bug Fixes

* `semean` returns missing with fewer than 2 observations.
* If `strL` contains binary data `gtools` functions now throw an error.
* `strL` missing values now read correctly.
* `strL` partial support for OSX (long strings only).
* Added `strL`-specific tests
* All tests passing in Stata 13 in Linux, Windows
* All tests passing in Stata 15 in Linux
* All tests passing in Stata 14 in OSX

## gtools-0.14.0 (2018-07-17)

### Bug Fixes

* Closes https://github.com/mcaceresb/stata-gtools/issues/39 `strL`
  partial support (OSX pending).
* Closes https://github.com/mcaceresb/stata-gtools/issues/41 `wild` with
  existing variables gets a warning.
* Fixes https://github.com/mcaceresb/stata-gtools/issues/42 `gunique` typo.

------------------------------------------------------------------------

## gtools-0.13.3 (2018-05-06)

### Features

* Adds `gduplicates` as a replacement of `duplicates`. This is
  basically a wrapper for `gegen tag` and `gegen count`.

### Enhancements

* `_gtools_internals.ado` exits when `GTOOLS_CALLER` is empty.

## gtools-0.13.2 (2018-05-03)

### Features

* Fixes https://github.com/mcaceresb/stata-gtools/issues/31
  (added option `mlast` to `hashsort` to imitate `gsort` when sorting
  numbers in inverse order and they contain missing values).

## gtools-0.13.1 (2018-05-02)

### Pending

- For now, throws error for strL variable: https://github.com/mcaceresb/stata-gtools/issues/39

Plugin version 2.0 makes no mention of strL variables; however, plugin
version 3.0 notes that they are actually not supported by the macros
that I use to access strings. I think I'll have to compile a sepparate
version of the plugin for Stata 13 and Stata 14 and above. The Stata
13 version will throw an error for strL variables. This is currently
the only version until I figure out where to test Stata 14 and how to
implement this switch.

### Bug fixes

- Fixes https://github.com/mcaceresb/stata-gtools/issues/38

When the quantile requested was N - 1 out of an array of length N, I
makde an exception so the function picked up the largest value, instead
of passing N - 1 to the selection algorithm. However, I made a mistake
and quantiles between 100 - 150 / N and 100 - 100 / N, left-inclusive
right-exclusive, would give the wrong quantile.

## gtools-0.13.0 (2018-04-24)

### Enhancements

- Added some basic debugging code and comments to the code base.

### Bug fixes

- `sd`, `semean` give the correct answer when the group is a singleton
   or when all observations are the same.
- `skew`, `kurt` give the correct answer when the group is a singleton
   or when all observations are the same.

------------------------------------------------------------------------

## gtools-0.12.8 (2018-04-23)

### Features

* Added `rawsum`
* Added option `rawstat()`; you can pass a list of targets for which
  weights will be ignored. `percent` cannot be called with `rawstat`.
  All targets must be named _**explicitly**_ (i.e. will not expand
  varlist notation). Fixes https://github.com/mcaceresb/stata-gtools/issues/37

Neither rawsum nor rawstat are very smart. If the user requests them
without weights, they will be ignored without warning. If the user
requests them with weights, the weighted version will still be called
(weighted internals are slower than unweighted internals).

### Bug fixes

- When not weighted, `skew` and `kurt` return missing when all
  observations are the same. When weighted, they may return -1 or 1
  due to numerical (im)precission problems. This issue is also present
  in Stata's implementation and should only come up when working with
  doubles rounded to arbitrary decimal places.

## gtools-0.12.7 (2018-04-05)

### Bug fixes

* Added OSX plugin in build.
* Enclosed various macros in `""' in case they contain quotations.

## gtools-0.12.6 (2018-03-31)

### Features

* Added skewness and kurtosis to `gcollapse` and `gegen`

### Bug fixes

* Fixed install issues in https://github.com/mcaceresb/stata-gtools/issues/36

## gtools-0.12.5 (2018-03-06)

### Bug fixes

* Fixed install issues in https://github.com/matthieugomez/benchmark-stata-r/issues/6
* Fixed `gegen` type issue in https://github.com/mcaceresb/stata-gtools/issues/34

## gtools-0.12.4 (2018-02-06)

### Enhancements

- `gegen` always created a temporary variable in an attempt
  to fix https://github.com/mcaceresb/stata-gtools/issues/33,
  which was unnecessary and it slowed it down.
- Updated typos in documentation.

## gtools-0.12.3 (2018-02-01)

### Enhancements

- Linux and Windows tests passing with updated weights and nunique
- Updated documentation.

### Bug fixes

- Weights used the incorrect rules for outputting missing values
  when computing `sd` or `se*`; this was fixed.
- Fixes https://github.com/mcaceresb/stata-gtools/issues/33 and now
  tries to parse and expression first and a varlist second.

## gtools-0.12.2 (2018-02-01)

### Enhancements

- OSX version of gcollapse, gegen with weights and nunique
- Travis-compiled; I won't commit to master w/o passing tests

## gtools-0.12.1 (2018-01-22)

### Features

- gcontract supports fweights (Unix only; tests pending)
- gcollapse and gegen support nunique (Unix only; tests pending)
- gcollapse and gegen now support weights in Windows and Unix
  (OSX pending). gegen does not support weights with multiple
  sources (e.g. `sum(x y z)`).

------------------------------------------------------------------------

## gtools-0.11.5 (2018-01-16)

### Features

- gcollapse now allows wild-parsing via option `wild`
  (`wildparse`). E.g. `(sum) x* (mean) mean_x* = x*` would
  be valid syntax.

## gtools-0.11.4 (2018-01-08)

### Features

- `gcollapse, missing` output missing for sums if all inputs are missing.
- `glevelsof` adds option `unsorted` which is faster and does not sort results
- The resulting data from `gcollapse` and `gcontract` are now sorted

### Bug fixes

- `gegen` now imitates `egen` when there are no observations selected
  and leaves the new variable in memory with all missing values.
- `gegen, missing` for total and sum now correctly output missing if all
  inputs are missing
- Fixes https://github.com/mcaceresb/stata-gtools/issues/32 (gcontract
  should allow abbreviations)

## gtools-0.11.3 (2017-11-21)

### Bug fixes

- `gtop` now reads a global from `gtoplevelsof` so if there was an error
  but the exit code should be 0 (in this case, no observations throws an
  error internally but exits with 0 status externally) `gtop` no longer
  throws a syntax error.
- Fixed bug in gdistinct where all missing observations without the
  missing option caused an error.

## gtools-0.11.2 (2017-11-20)

### Bug fixes

- Fixed bug in glevelsof where if string data is already sorted the
  system does not compute the length of the de-duplicated string
  data. This caused malloc to attempt to assign the length of an
  unassigned but declared variable. This treated an object's address as a
  length and caused malloc to request dozens or hundreds of GiB and crash
  on some systems.

## gtools-0.11.1 (2017-11-20)

### Bug fixes

- Fixed bug with naming conflicts between internals and gcollapse.

## gtools-0.11.0 (2017-11-17)

### Backwards Incompatible

- `gquantiles` no longer supports option "binpct[()]"
- `glevelsof` no longer supports option "silent"

### Features

- `gquantiles` supports `by()`

- Option `hash()` gives user control over hashing mechanics.  0 is
  default (internals choose what it thinks will be fastest), 1 tries to
  biject, 2 always calls spookyhash.

### Enhancements

- Improved internal handling of numerical precision issues when
  computing quantiles (gquantiles, gcollapse, and gegen).

- When the data is sorted, groups are indexed directly instead of using
  the hash. This was 2x faster in testing for an overall ~33% or so speedup.

- `gtop` is a shortcut for `gtoplevelsof`

- `bench(2)` and `bench(3)` offer the user more control over what
  benchmark steps are displayed.

### Bug fixes

- Fixes possible bug with levelsof where the plugin tries to read
  more characters than contained in the numfmt local macro. This
  could cause problems on some systems.

------------------------------------------------------------------------

## gtools-0.10.3 (2017-11-12)

### Bug fixes

- Fixes https://github.com/mcaceresb/stata-gtools/issues/29; if the
  sources appear out of order relative to the targets (e.g. sources are
  'a b' but targets use sources 'a a b b' instead of 'a b a b') then
  gcollapse produced the wrong results with option `forceio` or with the
  swtich code. The code now reorders the sources, targets, and statistics
  so the source variables always appear first and the extra targets last.
- Fixes bug in `gtop` where requesting negative levels caused an overflow.
- Fixes bug in `hashsort` where there may be a loss in numerical
  precision when clearing the sort var. It now adds one observation to the
  source data, changes the dummy observation, and drops it. This should
  have the same effect without modifying the original dataset.

### Enhancements

- Counting sort now uses pointers, which is hopefully faster.
- Added special cases for `gquantiles` to hopefully accelerate reading
  source variables from Stata.
- Added special case for `gegen, group` so the code orders the groups
  back to Stata order before copying. It runs faster because it writes
  to Stata sequentially, but it uses more memory.
- The code no longer keeps a copy of the by variables when it is not
  needed (gcollapse, glevelsof, gtop, and gcontract need a copy;
  gegen, hashsort, gquantiles, etc. do not).

## gtools-0.10.2 (2017-11-08)

### Bug fixes

- Fixes bug where integer overflows if `gtoplevelsof, ntop(-#)`
  is requested.

## gtools-0.10.1 (2017-11-08)

### Features

- `gquantiles` is a fast alternative to `_pctile`, `pctile`, and
  `xtile` with several additional features.
- `fasterxtile` is an alias for `gquantiles, xtile`

### Bug fixes

- Fixes https://github.com/mcaceresb/stata-gtools/issues/27
- Fixed numerical precision issue with quantiles.
  Now ((ST_double) N / 100) is computed first.

------------------------------------------------------------------------

## gtools-0.9.4 (2017-11-03)

### Bug fixes

- Fixes https://github.com/mcaceresb/stata-gtools/issues/26
  so that hashsort sets `sortedby` to the outermost levels that
  are positive (e.g. `foreign -rep78` sets `sortedby` to `foreign`).

### Backwards Incompatible

- Apparentlly `gen` in `gsort` was intuitively specified, so I have
  now made `gen` mirror that in `hashsort`. Previous versions offered
  this functionality via `group`.

## gtools-0.9.3 (2017-11-02)

### Bug fixes

- Major bug in gisid: False positive when there was a duplicate row with
  multiple variable levels but data was otherwise sorted.

## gtools-0.9.2 (2017-11-02)

### Bug fixes

- Previous commit had a corrupted binary for the OSX plugin.

### Backwards Incompatible

- Option `benchmark` is no longer abbreviated with `b` and MUST be abbreviated
  as `bench`.  This is to ensure consistency with options `bench(0)`,
  `bench(1)` and `bench(2)`. `bench(1)` is the same as `benchmark`. `bench(2)`
  additionally shows benchmarks for various internal plugin steps. `bench(0)`
  is the same as not including `benchmark`.

### Enhancements

- Improved online docs: Now each example is available as raw code
  (each example page points to it) and inline monospaced code should
  be slightly bigger, improving readability.

## gtools-0.9.1 (2017-11-01)

- Stability improvements.
- Commands should be faster when data is sorted (skips
  hash sorting if data is already sorted).
- Misc bug fixes.

## gtools-0.9.0 (2017-11-01)

### Features

- The plugin now works on OSX
- `gcontract` is a fast alternative to `contrast`
- `gtoplevelsof` is a new command that allows the user to glean the most
  common levels of a set of variables.  Similar to `gcontract` with a `gsort`
  of frequency by descending order thereafter, but `gtoplevelsof` does not
  modify the source data and saves a matrix with the results after its run.
- `gdistinct` now saves its results to a matrix when there are multiple
  variables.
- Improved and normalized documentation

### Bug fixes

- OSX version; fixes https://github.com/mcaceresb/stata-gtools/issues/11
- `gisid` now sient w/o benchmark or verbose; fixes https://github.com/mcaceresb/stata-gtools/issues/20
- Added quotes to `cd cwd` in `gtools`; fixes https://github.com/mcaceresb/stata-gtools/issues/22
- `gcontract` available; fixes https://github.com/mcaceresb/stata-gtools/issues/23 

------------------------------------------------------------------------

## gtools-0.8.5 (2017-10-30)

### Features

- `gcollapse, freq()` stores frequency count in variable.
  Same as `gen long freq = 1` and then `(sum) freq`.
- Hashsort is marginally faster (sortindex inversion now
  done internally in C).

## gtools-0.8.4 (2017-10-29)

### Enhancements

- Normalized types in the C base to ensure I have 64-bit integers
  (signed and unsigned) as well as `ST_doubles` all around.
- Bijection limit is now limit on signed 64-bit integers.

## gtools-0.8.3 (2017-10-28)

### Features

- `gisid` includes an internal check to see if the data is sorted.
  This means that if there are two duplicate rows in unsorted data
  or if the data is already sorted, `gisid` will give a result much
  faster. However, if the data is not sorted it will be marginally
  slower as it will execute the rest of the code normally.

### Backwards Incompatible

- `gisid` and `hashsort` are no longer rclass. Both will exit early if
  the data is already sorted, and `gisid` will also exit if it finds a
  duplicate row during the sorted check. Hence they will not always
  store results, making them inconsistent. It would be bad practice
  to continue to have them store `rclass` results.

### Enhancements

- Cleaned up the C base somewhat. Improved modularity.
- All `int` were changed to `size_t` or `int64_t` as applicable, since
  `int` is not necessarily aliased to a 64-bit integer on all platforms.

## gtools-0.8.2 (2017-10-26)

### Features

* `gdistinct` is a replacement for `distinct`.  It is functionally identical
  to `gunique` except it mimics the output format of `distinct`.

## gtools-0.8.1 (2017-10-26)

### Backwards Incompatible

* `merge` now merges labels and formats by default

### Bug fixes

* Fxied examples in README; fixed minor typos in README
* `gegen` now handles the type of `pctile` correctly.

## gtools-0.8.0 (2017-10-19)

### Features

* Refactored code base for somewhat faster runtime, but mainly for bug fixes
  and ease of maintenance.
* gcollapse, gegen, glevelsof, gisid, gunique, hashsort all call the function
  `_gtools_internal`, which then calls the plugin.
* gcollapse includes a target labeling engine.
* gcollapse now supports semean, sebinomial, and sepoisson.
* gegen will take (almost) any egen function. If it is not implemented
  by gtools it will simply use hashsort and then call egen.
* Windows and Linux versions passing tests, OSX version should be feasible.

### Bug fixes

* Fixes https://github.com/mcaceresb/stata-gtools/issues/19
* Fixes https://github.com/mcaceresb/stata-gtools/issues/18
* Fixes https://github.com/mcaceresb/stata-gtools/issues/11

------------------------------------------------------------------------

## gtools-0.7.5 (2017-10-08)

### Features

* Updated benchmarks for new commands, all in Stata/MP.
* Added `counts` option (with `fill`) to `gegen group`.
  `fill` can be a number, `group` to fill in the counts
  normally, or `data` to fill in the first J_th_ observations.
* The number of groups is now stored in `r(J)`, along with
  other useful meta stats.

## gtools-0.7.4 (2017-09-29)

### Features

* `hashsort` is added as a working replacement for `sort` and `gsort`.
  The sort is always stable. `mfirst` is not allowed.

## gtools-0.7.2 (2017-09-28)

### Features

* `gisid` is added as a working replacement for `isid` and `isid, missok`.
  `gisid` taks `if` and `in` statements; however, it does not implement
  `isid, sort` or `isid using`.
* `glevelsof` is added as a working replacement for `levelsof`.
  All `levelsof` features are available.

### Enhancements

* Fixes https://github.com/mcaceresb/stata-gtools/issues/13 so
  `gcollapse` maintains source formats on targets.
* Improved internal handling of if conditions for `egen`.

### Bug fixes

* Prior versions de-facto used a 64-bit hash instead of a 128-bit hash.
  The new version should use the 128-bit hash correctly.
* Prior versions would fail if there was only 1 observation.

## gtools-0.7.1 (2017-09-27)

### Enhancements

* `egen` now only processes observations in range for `id, group`
* `egen, group` now marginally faster when all vars are integers

## gtools-0.7.0 (2017-09-26)

### Enhancements

* Temporary variable no longer created for `egen, tag` or `egen, group`
* Fixes https://github.com/mcaceresb/stata-gtools/issues/6
    * Variables are sorted internally for `egen, group`, which matches `egen`.
    * Variables are sorted internally for `gcollapse`, which is faster.
* Various internal enhancements:
    * The hash is validated faster
    * Hash validation is also used to read in group variables
    * Integer bijection now sorts by the integers correctly,
      obviating the need for a second sort.
    * No need to validate the hash with integer bijection.
    * The memory usage is marginally leaner.
    * Reorganized all the files, making the code-base easier to maintain.
* Various commented internal code deleted.

### Backwards-incompatible

* `gcollapse, unsorted` no longer supported (due to internal sorting)

------------------------------------------------------------------------

## gtools-0.6.17 (2017-09-17); fixes #15

### Bug fixes

* Fixes https://github.com/mcaceresb/stata-gtools/issues/15
  which was introduced trying to fix
  https://github.com/mcaceresb/stata-gtools/issues/15

## gtools-0.6.16 (2017-09-13); addresses #7

### Bug fixes

* Improves the issues raised by https://github.com/mcaceresb/stata-gtools/issues/7
  Now the commands only fail if Stata hits the `matsize` limit (internally, the plugin
  no longer uses the `subinstr` hack to go from locals to mata string matrices and uses
  `tokens` instead, which is more appropriate; further, the plugin tries to set matsize
  to at least the number of variables and gives a verbose error if it fails.)

## gtools-0.6.15 (2017-09-12); fixes #14, #9

### Bug fixes

* Fixes https://github.com/mcaceresb/stata-gtools/issues/14
* Fixes https://github.com/mcaceresb/stata-gtools/issues/9
  (prior fixes were erratic; this should work)

## gtools-0.6.14 (2017-09-12)

### Bug fixes

* No longer crashes on Linux systems with older glibc versions.

## gtools-0.6.13 (2017-09-12)

### Bug fixes

* Should fix https://github.com/mcaceresb/stata-gtools/issues/9
  Added legacy plugin using older `libgomp.so` library.

## gtools-0.6.12 (2017-09-11)

### Bug fixes

* Should fix https://github.com/mcaceresb/stata-gtools/issues/12

## gtools-0.6.11 (2017-08-17)

### Bug fixes

* Fixed https://github.com/mcaceresb/stata-gtools/issues/8 so
  `gegen` is callable via `by:`; it also gives the stat for the
  overall group if called without a `by`.

## gtools-0.6.10 (2017-06-27)

### Bug fixes

* When fixing issue https://github.com/mcaceresb/stata-gtools/issues/5
  I introduced a bug. This is fixed.

## gtools-0.6.9 (2017-06-27)

### Enhancements

* Addressed the possible issue noted in issue
  https://github.com/mcaceresb/stata-gtools/issues/3 and the functions now
  use mata and extended macro functions as applicable.
* `gegen varname = group(varlist)` no longer has holes, as noted in issue
  https://github.com/mcaceresb/stata-gtools/issues/4
* `gegen` and `gcollapse` fall back on `collapse` and `egen` in case there
  is a collision. Future releases will implement an internal way to resolve
  collisions. This is not a huge concern, as SpookyHash has no known
  vulnerabilities (I believe the concern raied in issue https://github.com/mcaceresb/stata-gtools/issues/2
  was base on a typo; see [here](https://github.com/rurban/smhasher/issues/34))
  and the probability of a collision is very low.
* `gegen varname = group(varlist)` now has a consistency test (though
  the group IDs are not the same as `egen`'s, they should map to the `egen`
  group IDs 1 to 1, which is what the tests now check for).

### Bug fixes

* `gegen` no longer ignores unavailable options, as noted in issue
  https://github.com/mcaceresb/stata-gtools/issues/4, and now it throws an error.
* `gegen varname = tag(varlist)` no longer tags missing values, as noted
  in issue https://github.com/mcaceresb/stata-gtools/issues/5
* Additional fixes for issue https://github.com/mcaceresb/stata-gtools/issues/1
* Apparentlly the argument Stata passes to plugins have a maximum length. The
  code now makes sure chuncks are passed when the PATH length will exceed the
  maximum. The plugin later concatenates the chuncks to set the PATH correctly.

## gtools-0.6.8 (2017-06-25)

### Bug fixes

* Fixed issue https://github.com/mcaceresb/stata-gtools/issues/1
* The problem was that the wrapper I wrote to print to the Stata
  console has a maximum buffer size; when it tries to print the
  new PATH it encounters an error when the string is longer than
  the allocated size. Since printing this is unnecessary and
  will only ever be used for debugging, I no longer print the PATH.

## gtools-0.6.7 (2017-06-18)

### Debugging

* Debugging issue https://github.com/mcaceresb/stata-gtools/issues/1
  on github (in particular, `env_set` on Windows).

## gtools-0.6.6 (2017-06-18)

### Bug fixes

* Removed old debugging code that had been left uncommented
* Improved out-of-memory message (now links to relevant help section).

## gtools-0.6.5 (2017-06-18)

### Features

* The function now checks numerical variabes to see if they are integers.
  Working with integers is faster than hashing.
* The function is now smarter about generating targets. In prior versions,
  when the target statistic was a sum the function would force the target
  type to be `double`. Now if the source already exists and is a float, the
  function now checks if the resultimg sum would overflow. It will only
  recast the source as double for collapsing if the sum might overflow, that
  is, if `_N * min < -10^38` or `10^38 < _N * max` (note +/- 10^38 are the
  largest/smallest floats stata can represent; see `help data_types`).

### Bug fixes

* Fixed bug where Stata crashes when it can no longer allocate memory. It now
  exists with error.
* In Windows, `gcollapse` and `gegen` now check whether `spookyhash.dll` can be
  found before trying to modify the `PATH` environment variable.

## gtools-0.6.4 (2017-06-18)

### Bug fixes

- On windows, when all variables are numeric and the second variable
  is constant, there used to be a division by 0 crash. This was fixed.

## gtools-0.6.3 (2017-06-18)

### Bug fixes

- Forgot to provide OS-specific versions of `env_set` as well...
- Linux and Windows versions passing from github.

## gtools-0.6.2 (2017-06-18)

### Bug fixes

- Forgot to commit new files in `./build`

## gtools-0.6.1 (2017-06-17)

### Bug fixes

- Program now installs correctly from build folder on Windows. I had
  to add the assumed `spookyhash.dll` path to the system `PATH` at
  eacah run. I also provide a `gtools.ado` file that allows the user to
  troubleshoot some possible issues that may arise.

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

------------------------------------------------------------------------

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

------------------------------------------------------------------------

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

------------------------------------------------------------------------


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

* `gcollapse` `smart` option indexes the data based on the sorted groups
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
  `gcollapse`, unlike `collapse` (or `fcollapse` as best I can tell) can
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
