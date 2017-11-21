<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

Faster Stata for big data. This packages provides a hash-based
implementation of collapse, pctile, xtile, contract, egen, isid,
levelsof, and unique/distinct using C plugins for a massive speed
improvement.

`version 0.11.2 21Nov2017`
Builds: Linux, OSX [![Travis Build Status](https://travis-ci.org/mcaceresb/stata-gtools.svg?branch=master)](https://travis-ci.org/mcaceresb/stata-gtools),
Windows (Cygwin) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/2bh1q9bulx3pl81p/branch/master?svg=true)](https://ci.appveyor.com/project/mcaceresb/stata-gtools)

Overview
--------

This package's aim is to provide a fast implementation of various Stata
commands using hashes and C plugins.  If you plan to use the plugin
extensively, check out the [remarks](#remarks) below and the [FAQs](faqs) for
caveats and details on the plugin.

__*Gtools commands with a Stata equivalent*__

| Function     | Replaces | Speedup (IC / MP)        | Unsupported     | Extras                            |
| ------------ | -------- | ------------------------ | --------------- | --------------------------------- |
| gcollapse    | collapse |  9 to 300 / 4 to 120 (+) | Weights         | Quantiles, `merge`, label output  |
| gcontract    | contract |  5 to 7   / 2.5 to 4     | Weights         |                                   |
| gegen        | egen     |  9 to 26  / 4 to 9 (+,.) | Weights, labels | Quantiles                         |
| gisid        | isid     |  8 to 30  / 4 to 14      | `using`, `sort` | `if`, `in`                        |
| glevelsof    | levelsof |  3 to 13  / 2 to 5-7     |                 | Multiple variables                |
| gquantiles   | xtile    |  10 to 30 / 13 to 25 (-) | Weights         | `by()`, various (see [usage](usage/gquantiles)) |
|              | pctile   |  13 to 38 / 3 to 5 (-)   | Ibid.           | Ibid.                             |
|              | \_pctile |  25 to 40 / 3 to 5       | Ibid.           | Ibid.                             |

<small>(+) The upper end of the speed improvements for gcollapse are for
quantiles (e.g. median, iqr, p90) and few groups.</small>

<small>(.) Only gegen group was benchmarked rigorously.</small>

<small>(-) Benchmarks computed 10 quantiles. When computing a large
number of quantiles (e.g. thousands) `pctile` and `xtile` are prohibitively
slow due to the way they are written; in that case gquantiles is hundreds
or thousands of times faster.</small>

__*Gtools extras*__

| Function            | Similar (SSC)      | Speedup (IC / MP)       | Notes                                 |
| ------------------- | ------------------ | ----------------------- | ------------------------------------- |
| fasterxtile         | fastxtile          |  20 to 30 / 2.5 to 3.5  | Can use `by()`; weights not supported |
|                     | egenmisc (SSC) (-) |  8 to 25 / 2.5 to 6     |                                       |
|                     | astile (SSC) (-)   |  8 to 12 / 3.5 to 6     |                                       |
| gunique             | unique             |  4 to 26 / 4 to 12      |                                       |
| gdistinct           | distinct           |  4 to 26 / 4 to 12      | Also saves results in matrix          |
| gtop (gtoplevelsof) | groups, select()   | (+)                     | See table notes (+)                   |

<small>(-) `fastxtile` from egenmisc and `astile` were benchmarked against
`gquantiles, xtile` (`fasterxtile`) using `by()`.</small>

<small>(+) While similar to the user command 'groups' with the 'select'
option, gtoplevelsof does not really have an equivalent. It is several
dozen times faster than 'groups, select', but that command was not written
with the goal of gleaning the most common levels of a varlist. Rather, it
has a plethora of features and that one is somewhat incidental. As such, the
benchmark is not equivalent and `gtoplevelsof` does not attempt to implement
the features of 'groups'</small>

In addition, several commands take gsort-style input, that is

```stata
[+|-]varname [[+|-]varname ...]
```

This does not affect the results in most cases, just the sort order.
Commands that take this type of input include:

- gcollapse
- gcontract
- gegen
- glevelsof
- gtop (gtoplevelsof)

__*Hashing*__

The key insight is that hashing the data and sorting a hash is a lot faster
than sorting the data to then process it by group. Sorting a hash can be
achieved in linear O(N) time, whereas the best sorts take O(N log(N))
time. Sorting the groups would then be achievable in O(J log(J)) time
(with J groups). Hence the speed improvements are largest when N / J is
largest. Further, compiled C code is much faster than Stata commands.

__*Sorting*__

It should be noted that Stata's sorting mechanism is not inefficient as a
general-purpose sort. It is just inefficient for processing data by group. We
have implemented a hash-based sorting command, `hashsort`. While at times this
is faster than Stata's `sort`, it can also often be slower:

| Function  | Replaces | Speedup (IC / MP)    | Unsupported | Extras               |
| --------- | -------- | -------------------- | ----------- | -------------------- |
| hashsort  | sort     | 2.5 to 4 / .8 to 1.3 |             | Group (hash) sorting |
|           | gsort    | 2 to 18 / 1 to 6     | `mfirst`    | Sorts are stable     |

The overhead involves copying the by variables, hashing, sorting the hash,
sorting the groups, copying a sort index back to Stata, and having Stata do
the final swaps. The plugin runs fast, but the copy overhead plus the Stata
swaps often make the function be slower than Stata's native `sort`.

The reason that the other functions are faster is because they don't deal with
all that overhead.  By contrast, Stata's `gsort` is not efficient. To sort
data, you need to make pair-wise comparisons. For real numbers, this is just
`a > b`. However, a generic comparison function can be written as `compare(a, b) > 0`.
This is true if a is greater than b and false otherwise. To invert
the sort order, one need only use `compare(b, a) > 0`, which is what gtools
does internally.

However, Stata creates a variable that is the inverse of the sort variable.
This is equivalent, but the overhead makes it slower than `hashsort`.

__*Ftools*__

The commands here are also faster than the commands provided by `ftools`;
further, `gtools` commands take a mix of string and numeric variables,
which is a limitation of `ftools`. (Note I could not get several parts
of `ftools` working on the Linux server where I have access to Stata/MP.)

| Gtools    | Ftools        | Speedup (IC) |
| --------- | ------------- | ------------ |
| gcollapse | fcollapse     | 2-9 (+)      |
| gegen     | fegen         | 2.5-4 (.)    |
| gisid     | fisid         | 4-14         |
| glevelsof | flevelsof     | 1.5-13       |
| hashsort  | fsort         | 2.5-4        |

<small>(+) A older set of benchmarks showed larger speed gains in part due to
mulit-threading, which has been removed as of 0.8.0, and in part because the
old benchmarks were more favorable to gcollapse; in the old benchmarks, the
speed gain is still 3-23, even without multi-threading. See the [old collapse
benchmarks](benchmarks#old-collapse-benchmarks)</small>

<small>(.) Only egen group was benchmarked rigorously.</small>

Acknowledgements
----------------

* The OSX version of gtools was implemented with invaluable help from @fbelotti
  in [issue 11](https://github.com/mcaceresb/stata-gtools/issues/11).

* Gtools was largely inspired by Sergio Correia's (@sergiocorreia) excellent
  [ftools](https://github.com/sergiocorreia/ftools) package. Further, several
  improvements and bug fixes have come from to @sergiocorreia's helpful comments.

Installation
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
```stata
local github "https://raw.githubusercontent.com"
net install gtools, from(`github'/mcaceresb/stata-gtools/master/build/)
* adoupdate, update
* ado uninstall gtools
```

The syntax is generally analogous to the standard commands (see the corresponding
help files for full syntax and options):
```stata
sysuse auto, clear

* gquantiles [newvarname =] exp, {_pctile|xtile|pctile} [options]
gquantiles 2 * price, _pctile nq(10)
gquantiles p10 = 2 * price, pctile nq(10)
gquantiles x10 = 2 * price, xtile nq(10) by(rep78)
fasterxtile xx = log(price), cutpoints(p10) by(foreign)

* hashsort varlist, [options]
hashsort -make
hashsort foreign -rep78, benchmark verbose

* gegen target  = stat(source), by(varlist) [options]
gegen tag   = tag(foreign)
gegen group = tag(-price make)
gegen p2_5  = pctile(price), by(foreign) p(2.5)

* gisid varlist [if] [in], [options]
gisid make, missok
gisid price in 1

* glevelsof varlist [if] [in], [options]
glevelsof rep78, local(levels) sep(" | ")
glevelsof foreign mpg if price < 4000, loc(lvl) sep(" | ") colsep(", ")

* gtoplevelsof varlist [if] [in], [options]
gtop foreign rep78
gtoplevelsof foreign rep78, ntop(2) missrow groupmiss pctfmt(%6.4g) colmax(3)

* gcollapse (stat) out = src [(stat) out = src ...], by(varlist) [options]
gcollapse (mean) mean = price (median) p50 = gear_ratio, by(make) merge v
gcollapse (p97.5) mpg (iqr) headroom, by(foreign rep78) benchmark
```

See the [FAQs](faqs) or the respective documentation for a list of supported
`gcollapse` and `gegen` functions.

Extra features
--------------

gtools commands support most of the options of their native counterparts, but
not all. To compensate, they also offer several features on top the massive
speedup. In particulat, see:

- [gcollapse](usage/gcollapse#examples)
- [gquantiles](usage/gquantiles#examples)
- [gtoplevelsof](usage/gtoplevelsof#examples)
- [gegen](usage/gegen#examples)
- [glevelsof](usage/glevelsof#examples)
- [gdistinct](usage/gdistinct#examples)

Remarks
-------

*__Functions available with `gegen` and `gcollapse`__*

Other than `rawsum`, `gcollapse` supports every `collapse` function. `gegen`
technically does not support all of `egen`, but whenever a function that is
not supported is requested, `gegen` hashes the data and calls `egen` grouping
by the hash, which is often faster.

Hence both should be able to replicate almost all of the functionality of their
Stata counterparts. The following are implemented internally in C:

| Function    | gcollapse | gegen   |
| ----------- | --------- | ------- |
| tag         |           |   X     |
| group       |           |   X     |
| total       |           |   X     |
| sum         |     X     |   X     |
| mean        |     X     |   X     |
| sd          |     X     |   X     |
| max         |     X     |   X     |
| min         |     X     |   X     |
| count       |     X     |   X     |
| median      |     X     |   X     |
| iqr         |     X     |   X     |
| percent     |     X     |   X     |
| first       |     X     |   X (+) |
| last        |     X     |   X (+) |
| firstnm     |     X     |   X (+) |
| lastnm      |     X     |   X (+) |
| semean      |     X     |   X     |
| sebinomial  |     X     |   X     |
| sepoisson   |     X     |   X     |
| percentiles |     X     |   X     |

<small>(+) first, last, firstmn, and lastnm are different from their counterparts
in the egenmore package and, instead, they are analogous to the gcollapse
counterparts.</small>

The percentile syntax mimics that of `collapse` and `egen`, with the addition
that quantiles are also supported. That is,

```stata
gcollapse (p#) target = var [target = var ...] , by(varlist)
gegen target = pctile(var), by(varlist) p(#)
```

where # is a "percentile" with arbitrary decimal places (e.g. 2.5 or 97.5).
Last, when `gegen` calls a function that is not implemented internally by
`gtools`, it will hash the by variables and call `egen` with `by` set to an
id based on the hash. That is, if `fcn` is not one of the functions above,

```stata
gegen outvar = fcn(varlist) [if] [in], by(byvars)
```

would be the same as
```stata
hashsort byvars, group(id) sortgroup
egen outvar = fcn(varlist) [if] [in], by(id)
```

but preserving the original sort order. In case an `egen` option might
conflict with a gtools option, the user can pass `gtools_capture(fcn_options)`
to `gegen`.

__*Differences from Stata counterparts*__

Differences from `collapse`

- No support for weights.
- String variables are nor allowed for `first`, `last`, `min`, `max`, etc.
  (see [issue 25](https://github.com/mcaceresb/stata-gtools/issues/25))
- `rawsum` is not supported.
- `gcollapse, merge` merges the collapsed data set back into memory. This is
  much faster than collapsing a dataset, saving, and merging after. However,
  Stata's `merge ..., update` functionality is not implemented, only replace.
  (If the targets exist the function will throw an error without `replace`).
- `gcollapse, labelformat` allows specifying the output label using placeholders.

Differences from `xtile`, `pctile`, and `_pctile`

- No support for weights.
- Adds support for `by()`
- Does not ignore `altdef` with `xtile` (see [this Statalist thread](https://www.statalist.org/forums/forum/general-stata-discussion/general/1417198-typo-in-xtile-ado-with-option-altdef))
- Fixes numerical precision issues with `pctile, altdef` (see [this Statalist thread](https://www.statalist.org/forums/forum/general-stata-discussion/general/1418732-numerical-precision-issues-with-stata-s-pctile-and-altdef-in-ic-and-se))
- Category frequencies can also be requested via `binfreq[()]`.
- `xtile`, `pctile`, and `_pctile` can be combined via `xtile(newvar)` and
  `pctile(newvar)`
- There is no limit to `nquantiles()` for `xtile`
- Quantiles can be requested via `percentiles()` (or `quantiles()`),
  `cutquantiles()`, or `quantmatrix()` for `xtile` as well as `pctile`.
- Cutoffs can be requested via `cutquantiles()`, `cutoffs()`,
  or `cutmatrix()` for `xtile` as well as `pctile`.
- The user has control over the behavior of `cutpoints()` and `cutquantiles()`.
  They obey `if` `in` with option `cutifin`, they can be group-specific with
  option `cutby`, and they can be de-duplicated via `dedup`.

Differences from `egen`

- `group` label options are not supported
- `gegen` upgrades the type of the target variable if it is not specified by
  the user. This means that if the sources are `double` then the output will
  be double. All sums are double. `group` creates a `long` or a `double`. And
  so on. `egen` will default to the system type, which could cause a loss of
  precision on some functions.
- For internally supported functions, you can specify a varlist as the source,
  not just a single variable. Observations will be pooled by row in that case.
- While `gegen` is much faster for `tag`, `group`, and summary stats, most
  egen function are not implemented internally, meaning for arbitrary `gegen`
  calls this is a wrapper for hashsort and egen.

Differences from `levelsof`

- The user can specify a number format.
- It can take a `varlist` and not just a `varname`; in that case it prints
  all unique combinations of the varlist. The user can specify column and row
  separators.

Differences from `isid`

- No support for `using`. The C plugin API does not allow to load a Stata
  dataset from disk.
- Option `sort` is not available.
- It can also check IDs with `if` and `in` conditions.

__*The Stata GUI freezes when running Gtools commands*__

When Stata is executing the plugin, the user will not be able to interact
with the Stata GUI. Because of this, Stata may appear unresponsive when it is
merely executing the plugin.

There is at least one known instance where this can cause a confusion for
the user: If the system runs out of RAM, the program will attempt to use the
pagefile/swap space. In doing, so, Stata may appear unresponsive (it may show
a "(Not Responding)" message on Windows or it may darken on \*nix systems).

The program has not crashed; it is merely trying to swap memory.  To
check this is the case, the user can monitor disk activity or monitor the
pagefile/swap space directly.

TODO
----

Features that might make it to 1.0 (but I make no promises)

- Add option to save glevelsof in a variable/matrix (incl freq).
- Add option to control how to treat missing values in gcollapse
    - anymissing()
    - allmissing()
- Minimize memory use.

These are options/features I would like to support, but I don't have an
ETA for them (and they almost surely won't make it to the 1.0 release):

- Add support for weights.
- Add memory(greedy|lean) to give user fine-grained control over internals.
- Integration with [ReadStat](https://github.com/WizardMac/ReadStat/tree/master/src)?
- Create a Stata C hashing API with thin wrappers around core functions.
    - This will be a C library that other users can import.
    - Some functionality will be available from Stata via gtooos, api()
- `gcollapse (mean) pre_* (count) count_* = pre_*, by(byvars)`
- Have some type of coding standard for the base (coding style)
- Add `Var`, `kurtosis`, `skewness`

License
-------

Gtools is [MIT-licensed](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE).
`./lib/spookyhash` and `./src/plugin/common/quicksort.c` belong to their respective
authors and are BSD-licensed.
