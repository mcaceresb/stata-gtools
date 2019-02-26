gstats sum/tab
==============

Efficiently compute summary statistics by group in the style of
`tabstat` and `summarize, detail`.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p><span class="codespan"><b>gstats <u>sum</u>marize</b> varlist [if] [in] [weight] [, by(varlist) options] </span></p>

<p><span class="codespan"><b>gstats <u>tab</u>stat</b> varlist [if] [in] [weight] [, by(varlist) options] </span></p>

Note the _prefixes_ `by:`, `rolling:`, `statsby:` are _not_ supported.
To compute a table of statistics by a group use the option `by()`. With
`by()`, `gstats tab` is also faster than `gcollapse`.

Statistics
----------

The following are available via `gstats tab`

| Stat        | Description
| ----------- | -----------
| mean        | means (default)
| count       | number of nonmissing observations
| nmissing    | number of missing observations
| nunique     | counts unique elements
| median      | medians
| p#.#        | arbitrary quantiles (#.# must be strictly between 0, 100)
| p1          | 1st percentile
| p2          | 2nd percentile
| ...         | 3rd-49th percentiles
| p50         | 50th percentile (same as median)
| ...         | 51st-97th percentiles
| p98         | 98th percentile
| p99         | 99th percentile
| iqr         | interquartile range
| sum         | sums
| rawsum      | sums, ignoring optionally specified weight except observations with a weight of zero are excluded
| nansum      | sum; returns . instead of 0 if all entries are missing
| rawnansum   | rawsum; returns . instead of 0 if all entries are missing
| sd          | standard deviation
| variance    | variance
| cv          | coefficient of variation (`sd/mean`)
| semean      | standard error of the mean (sd/sqrt(n))
| sebinomial  | standard error of the mean, binomial (sqrt(p(1-p)/n)) (missing if source not 0, 1)
| sepoisson   | standard error of the mean, Poisson (sqrt(mean / n)) (missing if negative; result rounded to nearest integer)
| skewness    | Skewness
| kurtosis    | Kurtosis
| percent     | percentage of nonmissing observations
| max         | maximums
| min         | minimums
| select#     | `#`th smallest non-missing
| select-#    | `#`th largest non-missing
| rawselect#  | `#`th smallest non-missing, ignoring weights
| rawselect-# | `#`th largest non-missing, ignoring weights
| range       | range (`max` - `min`)
| first       | first value
| last        | last value
| firstnm     | first nonmissing value
| lastnm      | last nonmissing value

Options
-------

### Tabstat Options

- `by(varname)`            Group statistics by variable.
- `statistics(stat [...])` Report specified statistics; default for tabstat is count, sum, mean, sd, min, max.
- `columns(stat|var)`      Columns are statistics (default) or variables.
- `prettystats`            Pretty statistic header names
- `labelwidth(int)`        Max by variable label/value width. Default `16`.
- `format[(%fmt)]`         Use format to display summary stats; default `%9.0g`

### Summarize Options

- `nodetail`           Do not display the full set of statistics.
- `meanonly`           Calculate only the count, sum, mean, min, max.
- `by(varname)`        Group by variable; all stats are computed but output is in the style of tabstat.
- `separator(#)`       Draw separator line after every # variables; default is `separator(5)`.
- `tabstat`            Compute and display statistics in the style of tabstat.

### Common Options

- `matasave[(str)]`        Save results in mata object (default name is GstatsOutput).
- `pooled`                 Pool varlist
- `noprint`                Do not print
- `format`                 Use variable's display format.
- `nomissing`              With `by()`, ignore groups with missing entries.

### Gtools options

(Note: These are common to every gtools command.)

- `compress` Try to compress strL to str#. The Stata Plugin Interface has
            only limited support for strL variables. In Stata 13 and
            earlier (version 2.0) there is no support, and in Stata 14
            and later (version 3.0) there is read-only support. The user
            can try to compress strL variables using this option.

- `forcestrl` Skip binary variable check and force gtools to read strL variables
            (14 and above only). __Gtools gives incorrect results when there is
            binary data in strL variables__. This option was included because on
            some windows systems Stata detects binary data even when there is none.
            Only use this option if you are sure you do not have binary data in your
            strL variables.

- `verbose` prints some useful debugging info to the console.

- `benchmark` or `bench(level)` prints how long in seconds various parts of the
            program take to execute. Level 1 is the same as `benchmark`. Levels
            2 and 3 additionally prints benchmarks for internal plugin steps.

- `hashmethod(str)` Hash method to use. `default` automagically chooses the
            algorithm. `biject` tries to biject the inputs into the
            natural numbers. `spooky` hashes the data and then uses the
            hash.

- `oncollision(str)` How to handle collisions. A collision should never happen
            but just in case it does `gtools` will try to use native
            commands. The user can specify it throw an error instead by
            passing `oncollision(error)`.

Remarks
-------

`gstats tab` and `gstats sum` are mainly designed to report
statistics by group. It does not modify the data in memory,
so it is a nice alternative to `gcollapse` when there are few
groups and you want to compute summary stats more quickly.

`gstats sum` by default computes the staistics that are reported by
`sum, detail` and without `by()` it is anywhere from 5 to 40
times faster. The lower end of the speed gains are for Stata/MP, but
`sum, detail` is very slow in versions of Stata that are not multi-threaded.
The behavior of plain `summarize` and `summarize, meanonly`
can be recovered via options `nodetail` and `meanonly`, but Stata
is not specially slow in this case. Hence they are mainly included for
use with `by()`, where `gstats sum` is again faster.

`gstats tab` should be faster than `tabstat` even without
groups, but the speed gains are largest with even a modest number of
levels in `by()`. Furthermore, an arbitrary number of grouping
variables are allowed. Note that with a very large numer of groups,
`tabstat`'s runtime seems to scale non-linearly, while `gstats tab`
will execute in a reasonable time.

`gstata tab` does not store results in `r()`. Rather, the option
`matasave` is provided to store the full set of summary statistics and
the by variable levels in a mata class object called `GstatsOutput`
(the name of the object can be changed via `opt matasave(name)`) . Run
`mata GstatsOutput.desc()` after `gstats tab, matasave` for details. The
following helper functions are provided:

```
    string scalar getf(j, l, maxlbl)
        get formatted (j, l) entry from by variables up to maxlbl characters

    real matrix getnum(j, l)
        get (j, l) numeric entry from by variables

    string matrix getchar(j, l,| raw)
        get (j, l) numeric entry from by variables; raw controls whether to null-pad entries

    real rowvector getOutputRow(j)
        get jth output row

    real colvector getOutputCol(j)
        get jth output column by position

    real matrix getOutputVar(var)
        get jth output var by name

    real matrix getOutputGroup(j)
        get jth output group
```

The following data is stored in `GstatsOutput`:

```
summary statistics
------------------

    real matrix output
        matrix with output statistics; J x kstats x kvars

    real scalar colvar
        1: columns are variables, rows are statistics; 0: the converse

    real scalar ksources
        number of variable sources (0 if pool is true)

    real scalar kstats
        number of statistics

    real matrix tabstat
        1: used tabstat; 0: used summarize

    string rowvector statvars
        variables summarized

    string rowvector statnames
        statistics computed

    real rowvector scodes
        internal code for summary statistics

    real scalar pool
        pooled source variables

variable levels (empty if without -by()-)
-----------------------------------------

    real scalar anyvars
        1: any by variables; 0: no by variables

    real scalar anychar
        1: any string by variables; 0: all numeric by variables

    string rowvector byvars
        by variable names

    real scalar kby
        number of by variables

    real scalar rowbytes
        number of bytes in one row of the internal by variable matrix

    real scalar J
        number of levels

    real matrix numx
        numeric by variables

    string matrix charx
        string by variables

    real scalar knum
        number of numeric by variables

    real scalar kchar
        number of string by variables

    real rowvector lens
        > 0: length of string by variables; <= 0: internal code for numeric variables

    real rowvector map
        map from index to numx and charx

printing options
----------------

    void printOutput()
        print summary table

    real scalar maxlbl
        max by variable label/value width

    real scalar pretty
        print pretty statistic names

    real scalar usevfmt
        use variable format for printing

    string scalar dfmt
        fallback printing format

    real scalar maxl
        maximum column length

    void readDefaults()
        reset printing defaults
```

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gstats_summarize.do)

### Tabstat

Basic usage

```stata
gstats tab price
gstats tab price, s(mean sd min max) by(foreign)
gstats tab price, by(foreign rep78)
```

Custom printing

```stata
gstats tab price mpg, s(p5 q p95 select7 select-3) pretty
gstats tab price mpg, s(p5 q p95 select7 select-3) col(var)
gstats tab price mpg, s(p5 q p95 select7 select-3) col(stat)
```

Mata API

```stata
gen strvar = "string" + string(rep78)
gstats tab price mpg, by(foreign strvar) matasave

mata
GstatsOutput.getf(1, 1, .)
GstatsOutput.getnum(., 1)
GstatsOutput.getchar((2, 5, 6), .)

GstatsOutput.getOutputRow(1)
GstatsOutput.getOutputCol(1)
GstatsOutput.getOutputVar("price")
GstatsOutput.getOutputVar("mpg")
GstatsOutput.getOutputGroup(1)
end

mata: st_matrix("output", GstatsOutput.output)
matrix list output
```

The mata API allows the user to computing several runs of summary
statistics and keeping them in memory:

```stata
gstats tab price mpg, by(foreign) noprint matasave(StatsByForeign)
gstats tab price mpg, by(rep78)   noprint matasave(StatsByRep)

mata StatsByRep.desc()
mata StatsByForeign.desc()
mata StatsByForeign.printOutput()
```

It is also specially useful for a large number of groups

```stata
clear
set obs 100000
gen g = mod(_n, 10000)
gen x = runiform()
gstats tab x, by(g) noprint matasave
mata GstatsOutput.J
mata GstatsOutput.getOutputGroup(13)
```

### Summarize

Basic usage

```stata
sysuse auto, clear
gstats sum price
gstats sum price [pw = gear_ratio / 5]
gstats sum price mpg, f
```

In the style of tabstat

```stata
gstats sum price mpg, tab nod
gstats sum price mpg, tab meanonly
gstats sum price mpg, by(foreign) tab
gstats sum price mpg, by(foreign) nod
gstats sum price mpg, by(foreign) meanonly
```

Pool inputs

```stata
gstats sum price *, nod
gstats sum price *, nod pool
```
