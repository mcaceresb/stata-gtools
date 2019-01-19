<img src="https://raw.githubusercontent.com/mcaceresb/mcaceresb.github.io/master/assets/icons/gtools-icon/gtools-icon-text.png" alt="Gtools" width="500px"/>

[Overview](#faster-stata-for-big-data)
| [Installation](#installation)
| [Examples](#examples)
| [Remarks](#remarks)
| [FAQs <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://gtools.readthedocs.io/en/latest/faqs/index.html)
| [Benchmarks <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://gtools.readthedocs.io/en/latest/benchmarks/index.html)
| [Compiling <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://gtools.readthedocs.io/en/latest/compiling/index.html)

Faster Stata for big data. This packages uses C plugins and hashes
to provide a massive speed improvements to common Stata commands,
including: collapse, pctile, xtile, contract, egen, isid, levelsof,
duplicates, and unique/distinct.

![Dev Version](https://img.shields.io/badge/beta-v1.2.5-blue.svg?longCache=true&style=flat-square)
![Supported Platforms](https://img.shields.io/badge/platforms-linux--64%20%7C%20osx--64%20%7C%20win--64-blue.svg?longCache=true&style=flat-square)
[![Travis Build Status](https://img.shields.io/travis/mcaceresb/stata-gtools/master.svg?longCache=true&style=flat-square&label=linux)](https://travis-ci.org/mcaceresb/stata-gtools)
[![Travis Build Status](https://img.shields.io/travis/mcaceresb/stata-gtools/master.svg?longCache=true&style=flat-square&label=osx)](https://travis-ci.org/mcaceresb/stata-gtools)
[![Appveyor Build status](https://img.shields.io/appveyor/ci/mcaceresb/stata-gtools/master.svg?longCache=true&style=flat-square&label=windows-cygwin)](https://ci.appveyor.com/project/mcaceresb/stata-gtools)

Faster Stata for Big Data
-------------------------

This package provides a fast implementation of various Stata commands
using hashes and C plugins. The syntax and purpose is largely
analogous to their Stata counterparts: For example, you can replace
`collapse` with `gcollapse`, `egen` with `gegen`, and so on. For a
comprehensive list of differences (including some extra features!)
see the [remarks](#remarks) below; for details and examples see [the
official project page](https://gtools.readthedocs.io).

__*Quickstart*__

```stata
ssc install gtools
gtools, upgrade
```

__*Gtools commands with a Stata equivalent*__

| Function     | Replaces   | Speedup (IC / MP)        | Unsupported     | Extras                                  |
| ------------ | ---------- | ------------------------ | --------------- | --------------------------------------- |
| gcollapse    | collapse   |  9 to 300 / 4 to 120 (+) |                 | Quantiles, merge, nunique, label output |
| gegen        | egen       |  9 to 26  / 4 to 9 (+,.) | labels          | Weights, quantiles, nunique             |
| gcontract    | contract   |  5 to 7   / 2.5 to 4     |                 |                                         |
| gisid        | isid       |  8 to 30  / 4 to 14      | `using`, `sort` | `if`, `in`                              |
| glevelsof    | levelsof   |  3 to 13  / 2 to 5-7     |                 | Multiple variables, arbitrary levels    |
| gduplicates  | duplicates |  8 to 16 / 3 to 10       |                 |                                         |
| gquantiles   | xtile      |  10 to 30 / 13 to 25 (-) |                 | `by()`, various (see [usage](https://gtools.readthedocs.io/en/latest/usage/gquantiles)) |
|              | pctile     |  13 to 38 / 3 to 5 (-)   |                 | Ibid.                                   |
|              | \_pctile   |  25 to 40 / 3 to 5       |                 | Ibid.                                   |

<small>(+) The upper end of the speed improvements are for quantiles
(e.g. median, iqr, p90) and few groups. Weights have not been
benchmarked.</small>

<small>(.) Only gegen group was benchmarked rigorously.</small>

<small>(-) Benchmarks computed 10 quantiles. When computing a large
number of quantiles (e.g. thousands) `pctile` and `xtile` are prohibitively
slow due to the way they are written; in that case gquantiles is hundreds
or thousands of times faster, but this is an edge case.</small>

__*Extra commands*__

| Function            | Similar (SSC/SJ)   | Speedup (IC / MP)       | Notes                        |
| ------------------- | ------------------ | ----------------------- | ---------------------------- |
| fasterxtile         | fastxtile          |  20 to 30 / 2.5 to 3.5  | Can use `by()`               |
|                     | egenmisc (SSC) (-) |  8 to 25 / 2.5 to 6     |                              |
|                     | astile (SSC) (-)   |  8 to 12 / 3.5 to 6     |                              |
| gstats winsor       | winsor2            |  10 to 40 / 10 to 40    | Can use weights              |
| gunique             | unique             |  4 to 26 / 4 to 12      |                              |
| gdistinct           | distinct           |  4 to 26 / 4 to 12      | Also saves results in matrix |
| gtop (gtoplevelsof) | groups, select()   | (+)                     | See table notes (+)          |

<small>(-) `fastxtile` from egenmisc and `astile` were benchmarked against
`gquantiles, xtile` (`fasterxtile`) using `by()`.</small>

<small>(+) While similar to the user command 'groups' with the 'select'
option, gtoplevelsof does not really have an equivalent. It is several
dozen times faster than 'groups, select', but that command was not written
with the goal of gleaning the most common levels of a varlist. Rather, it
has a plethora of features and that one is somewhat incidental. As such, the
benchmark is not equivalent and `gtoplevelsof` does not attempt to implement
the features of 'groups'</small>

__*Extra features*__

Several commands offer additional features on top of the massive
speedup. See the [remarks](#remarks) section below for an overview; for
details and examples, see each command's help page:

- [gcollapse](https://gtools.readthedocs.io/en/latest/usage/gcollapse/index.html#examples)
- [gquantiles](https://gtools.readthedocs.io/en/latest/usage/gquantiles/index.html#examples)
- [glevelsof](https://gtools.readthedocs.io/en/latest/usage/glevelsof/index.html#examples)
- [gtoplevelsof](https://gtools.readthedocs.io/en/latest/usage/gtoplevelsof/index.html#examples)
- [gegen](https://gtools.readthedocs.io/en/latest/usage/gegen/index.html#examples)
- [gdistinct](https://gtools.readthedocs.io/en/latest/usage/gdistinct/index.html#examples)

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

__*Ftools*__

The commands here are also faster than the commands provided by
`ftools`; further, `gtools` commands take a mix of string and numeric
variables, which is a limitation of `ftools`. (Note I could not get
several parts of `ftools` working on the Linux server where I have
access to Stata/MP; hence the IC benchmarks.)

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
benchmarks <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://gtools.readthedocs.io/en/latest/benchmarks/index.html#old-collapse-benchmarks)</small>

<small>(.) Only egen group was benchmarked rigorously.</small>

__*Limitations*__

- `strL` variables only partially supported on Stata 14 and above;
  `gcollapse` and `gcontract` do not support `strL` variabes.

- Due to a Stata bug, gtools cannot support more
  than `2^31-1` (2.1 billion) observations. See [this
  issue](https://github.com/mcaceresb/stata-gtools/issues/43)

- Due to limitations in the Stata Plugin Interface, gtools
  can only handle as many variables as the largest `matsize`
  in the user's Stata version. For MP this is more than
  10,000 variables but in IC this is only 800. See [this
  issue](https://github.com/mcaceresb/stata-gtools/issues/24).

- Gtools uses compiled C code to achieve it's massive increases in
  speed. This has two side-effects users might notice: First, it is sometimes
  not possible to break the program's execution.  While this is already true
  for at least some parts of most Stata commands, there are fewer opportunities
  to break Gtools commands relative to their Stata counterparts.

  Second, the Stata GUI might appear frozen when running Gtools
  commands.  If the system then runs out of RAM (memory), it could look
  like Stata has crashed (it may show a "(Not Responding)" message on
  Windows or it may darken on \*nix systems). However, the program has
  not crashed; it is merely trying to swap memory.  To check this is the
  case, the user can monitor disk activity or monitor their system's
  pagefile or swap space directly.

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
You can install `gtools` from Stata via SSC:
```stata
ssc install gtools
gtools, upgrade
```

By default this syncs to the master branch, which is stable. To install
the latest version directly, type:
```stata
local github "https://raw.githubusercontent.com"
net install gtools, from(`github'/mcaceresb/stata-gtools/master/build/)
```

### Examples

The syntax is generally analogous to the standard commands (see the corresponding
help files for full syntax and options):
```stata
sysuse auto, clear

* gquantiles [newvarname =] exp [if] [in] [weight], {_pctile|xtile|pctile} [options]
gquantiles 2 * price, _pctile nq(10)
gquantiles p10 = 2 * price, pctile nq(10)
gquantiles x10 = 2 * price, xtile nq(10) by(rep78)
fasterxtile xx = log(price) [w = weight], cutpoints(p10) by(foreign)

* hashsort varlist, [options]
hashsort -make
hashsort foreign -rep78, benchmark verbose mlast

* gegen target  = stat(source) [if] [in] [weight], by(varlist) [options]
gegen tag   = tag(foreign)
gegen group = tag(-price make)
gegen p2_5  = pctile(price) [w = weight], by(foreign) p(2.5)

* gisid varlist [if] [in], [options]
gisid make, missok
gisid price in 1 / 2

* gduplicates varlist [if] [in], [options gtools(gtools_options)]
gduplicates report foreign
gduplicates report rep78 if foreign, gtools(bench(3))

* glevelsof varlist [if] [in], [options]
glevelsof rep78, local(levels) sep(" | ")
glevelsof foreign mpg if price < 4000, loc(lvl) sep(" | ") colsep(", ")
glevelsof foreign mpg in 10 / 70, gen(uniq_) nolocal

* gtop varlist [if] [in] [weight], [options]
* gtoplevelsof varlist [if] [in] [weight], [options]
gtoplevelsof foreign rep78
gtop foreign rep78 [w = weight], ntop(5) missrow groupmiss pctfmt(%6.4g) colmax(3)

* gcollapse (stat) out = src [(stat) out = src ...] [if] [if] [weight], by(varlist) [options]
gen h1 = headroom
gen h2 = headroom
local lbl labelformat(#stat:pretty# #sourcelabel#)

gcollapse (mean) mean = price (median) p50 = gear_ratio, by(make) merge v `lbl'
disp "`:var label mean', `:var label p50'"
gcollapse (iqr) irq? = h? (nunique) turn (p97.5) mpg, by(foreign rep78) bench(2) wild

* gcontract varlist [if] [if] [fweight], [options]
gcontract foreign [fw = turn], freq(f) percent(p)
```

See the [FAQs](faqs) or the respective documentation for a list of supported
`gcollapse` and `gegen` functions.

Remarks
-------

*__Functions available with `gegen` and `gcollapse`__*

`gcollapse` supports every `collapse` function, including their
weighted versions. In addition, weights can be selectively applied via
`rawstat()`, and `nunique` counts the number of unique values.

`gegen` technically does not support all of `egen`, but whenever a
function that is not supported is requested, `gegen` hashes the data and
calls `egen` grouping by the hash, which is often faster (`gegen` only
supports weights for internal functions, since `egen` does not normally
allow weights).

Hence both should be able to replicate all of the functionality of their
Stata counterparts. The following are implemented internally in C:

| Function    | gcollapse | gegen   |
| ----------- | --------- | ------- |
| tag         |           |   X     |
| group       |           |   X     |
| total       |           |   X     |
| nunique     |     X     |   X     |
| sum         |     X     |   X     |
| nansum      |     X     |   X     |
| rawsum      |     X     |         |
| rawnansum   |     X     |         |
| mean        |     X     |   X     |
| sd          |     X     |   X     |
| max         |     X     |   X     |
| min         |     X     |   X     |
| count       |     X     |   X     |
| nmissing    |     X     |   X     |
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
| skewness    |     X     |   X     |
| kurtosis    |     X     |   X     |

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

__*Differences and Extras*__

Differences from `collapse`

- String variables are not allowed for `first`, `last`, `min`, `max`, etc.
  (see [issue 25](https://github.com/mcaceresb/stata-gtools/issues/25))
- `nunique` is supported.
- `nmissing` is supported.
- `rawstat` allows selectively applying weights.
- Option `wild` allows bulk-rename. E.g. `gcollapse mean_x* = x*, wild`
- `gcollapse, merge` merges the collapsed data set back into memory. This is
  much faster than collapsing a dataset, saving, and merging after. However,
  Stata's `merge ..., update` functionality is not implemented, only replace.
  (If the targets exist the function will throw an error without `replace`).
- `gcollapse, labelformat` allows specifying the output label using placeholders.
- `gcollapse (nansum)` and `gcollapse (rawnansum)` outputs a missing
  value for sums if all inputs are missing (instead of 0).
- `gcollapse, sumcheck` keeps integer types with `sum` if the sum will not overflow.

Differences from `xtile`, `pctile`, and `_pctile`

- Adds support for `by()` (including weights)
- Does not ignore `altdef` with `xtile` (see [this Statalist thread](https://www.statalist.org/forums/forum/general-stata-discussion/general/1417198-typo-in-xtile-ado-with-option-altdef))
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
- Fixes numerical precision issues with `pctile, altdef` (e.g. see [this Statalist thread](https://www.statalist.org/forums/forum/general-stata-discussion/general/1418732-numerical-precision-issues-with-stata-s-pctile-and-altdef-in-ic-and-se), which is a very minor thing so Stata and fellow users maintain it's not an issue, but I think it is because Stata/MP gives what I think is the correct answer whereas IC and SE do not).
- Fixes a possible issue with the weights implementation in `_pctile`; see [this thread](https://www.statalist.org/forums/forum/general-stata-discussion/general/1454409-weights-in-pctile).

Differences from `egen`

- `group` label options are not supported
- weights are supported for internally implemented functions.
- `nunique` is supported.
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

- It can take a `varlist` and not just a `varname`; in that case it prints
  all unique combinations of the varlist. The user can specify column and row
  separators.
- It can deduplicate an arbitrary number of levels and store the results in a
  new variable list or replace the old variable list via `gen(prefix)` and
  `gen(replace)`, respectively. If the user runs up against the maximum macro
  variable length, add option `nolocal`.

Differences from `isid`

- No support for `using`. The C plugin API does not allow to load a Stata
  dataset from disk.
- Option `sort` is not available.
- It can also check IDs with `if` and `in` conditions.

Differences from `gsort`

- `hashsort` behaves as if `mfirst` was passed. To recover the default
  behavior of `gsort` pass option `mlast`.

Differences from `duplicates`

- `gduplicates` does not sort `examples` or `list` by default. This massively
  enhances performance but it might be harder to read. Pass option `sort`
  (`sorted`) to mimic `duplicates` behavior and sort the list. 

Hashing and Sorting
-------------------

There are two key insights to the massive speedups of Gtools:

1. Hashing the data and sorting a hash is a lot faster than sorting
  the data to then process it by group. Sorting a hash can be achieved
  in linear O(N) time, whereas the best general-purpose sorts take O(N
  log(N)) time. Sorting the groups would then be achievable in O(J
  log(J)) time (with J groups). Hence the speed improvements are largest
  when N / J is largest.

2. Compiled C code is much faster than Stata commands. While it is true
   that many of Stata's underpinnings are compiled code, several
   operations are written in `ado` files without much thought given
   to optimization. If you're working with tens of thousands of
   observations you might barely notice (and the difference between
   5 seconds and 0.5 seconds might not be particularly important).
   However, with tens of millions or hundreds of millions of rows, the
   difference between half a day and an hour can matter quite a lot.

__*Stata Sorting*__

It should be noted that Stata's sorting mechanism is not inefficient as a
general-purpose sort. It is just inefficient for processing data by group. We
have implemented a hash-based sorting command, `hashsort`. While at times this
is faster than Stata's `sort`, it can also often be slower:

| Function  | Replaces | Speedup (IC / MP)    | Unsupported            | Extras               |
| --------- | -------- | -------------------- | ---------------------- | -------------------- |
| hashsort  | sort     | 2.5 to 4 / .8 to 1.3 |                        | Group (hash) sorting |
|           | gsort    | 2 to 18 / 1 to 6     | `mfirst` (see `mlast`) | Sorts are stable     |

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

TODO
----

These are options/features I would like to support, but I don't have an
ETA for them:

- [ ] `gstats`
    - [ ] `./docs/stata/gstats.sthlp`
    - [ ] `./docs/usage/gstats.md`
    - [ ] `./docs/examples/gstats.do`
    - [ ] `./src/test/test_gstats.do`
    - [ ] 0 and 100 for min/max
    - [ ] README and index for gstats.
    - [ ] Each gstats subcommand will get its own help file.
- [ ] Add support for binary `strL` variables.
- [ ] Minimize memory use.
- [ ] Improve debugging info.
- [ ] Improve code comments when you write the API!
- [ ] Add memory(greedy|lean) to give user fine-grained control over internals.
- [ ] Integration with [ReadStat](https://github.com/WizardMac/ReadStat/tree/master/src)?
- [ ] Create a Stata C hashing API with thin wrappers around core functions.
    - [ ] This will be a C library that other users can import.
    - [ ] Some functionality will be available from Stata via gtooos, api()
- [ ] Have some type of coding standard for the base (coding style)
- [ ] Add option to `gtop` to display top X results in alpha order
- [ ] Clean exit from `gcollapse`, `gegen` on error.
- [ ] Print # of missings for gegen
- [X] Add "Open Source Licenses" section

About
-----

Hi! I'm [Mauricio Caceres](https://mcaceresb.github.io); I made gtools
after some of my Stata jobs were taking literally days to run because of repeat
calls to `egen`, `collapse`, and similar on data with over 100M rows.  Feedback
and comments are welcome! I hope you find this package as useful as I do.

Along those lines, here are some other Stata projects I like:

* [`ftools`](https://github.com/sergiocorreia/ftools): The main inspiration for
  gtools. Not as fast, but it has a rich feature set; its mata API in
  particular is excellent.

* [`reghdfe`](https://github.com/sergiocorreia/reghdfe): The fastest way to run
  a regression with multiple fixed effects (as far as I know).

* [`ivreghdfe`](https://github.com/sergiocorreia/ivreghdfe): A combination of
  [`ivreg2`](https://ideas.repec.org/c/boc/bocode/s425401.html) and `reghdfe`.

* [`stata_kernel`](https://kylebarron.github.io/stata_kernel): A Stata kernel
  for Jupyter; extremely useful for interacting with Stata.

License
-------

Gtools is [MIT-licensed](https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE).
`./lib/spookyhash` and `./src/plugin/common/quicksort.c` belong to their respective
authors and are BSD-licensed. Also see `gtools, licenses`.
