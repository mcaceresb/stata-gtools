gstats transform
================

Apply statistical functions by group using C for speed.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p><span class="codespan"><b>gstats transform</b> <i>clist</i> [if] [in] [weight] [, by(varlist) options] </span></p>

where clist is either

```stata
[(stat)] varlist [ [(stat)] ... ]
[(stat)] target_var=varname [target_var=varname ...] [ [(stat)] ...]
```

or any combination of the `varlist` or `target_var` forms, and stat is one of

| Stat             | Description
| ---------------- | -----------
| demean           | subtract the mean (default)
| demedian         | subtract the median
| normalize        | (x - mean) / sd
| standardize      | same as normalize
| moving stat # #  | moving statistic _stat_; # specify the relative bounds (e.g. -3 1 means from 3 lag to 1 lead)
| moving stat      | as above; requires input option `window(# #)` with lower and upper window bounds

`moving` may be combined with any one of the folloing stats:

| Stat        | Description
| ----------- | -----------
| mean        | means (default)
| count       | number of nonmissing observations
| nmissing    | number of missing observations
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

Note that `moving` uses a window defined by the _observations_. That
would be equivalent to computing time series rolling window statistics
using the time variable set to `_n`. For example, given some vector `x_i`
with `N` observations, we have

```
Input -> Range
--------------------------------
-3 3  -> x_{i - 3} to x_{i + 3}
-3 .  -> x_{i - 3} to x_N
.  3  -> x_1 to x_{i + 3}
-3 -1 -> x_{i - 3} to x_{i - 1}
-3 0  -> x_{i - 3} to x_i
5  10 -> x_{i + 5} to x_{i + 10}
```

and so on. If the observation is outside of the admisible range (e.g.
`-10 10` but `i = 5`) the output is set to missing.

Options
-------

### Options

- `by(varlist)` specifies the groups over which the means, etc., are to be
                calculated. It can contain any mix of string or numeric variables.

- `replace` Replace allows replacing existing variables with merge.

- `wildparse` specifies that the function call should be parsed assuming
              targets are named using rename-stle syntax. For example,
              `gcollapse (sum) s_x* = x*, wildparse`

- `labelformat(str)` Specifies the label format of the output. #stat# is
            replaced with the statistic: #Stat# for titlecase, #STAT# for
            uppercase, #stat:pretty# for a custom replacement; #sourcelabel# for
            the source label and #sourcelabel:start:nchars# to extract a
            substring from the source label. The default is (#stat#)
            #sourcelabel#. #stat# palceholders in the source label are also
            replaced.

- `labelprogram(str)` Specifies the program to use with #stat:pretty#.
            This is an rclass that must set prettystat as a return value. The
            program must specify a value for each summary stat or return
            #default# to use the default engine. The programm is passed the
            requested stat by gcollapse.

- `autorename[(str)]` Automatically name targets based on requested stats.
            Default is `#source#_#stat#`.

- `nogreedy` Use slower but memory-efficient (non-greedy) algorithm.

- `types(str)` Override variable types for targets (**use with caution**).

- `window(lower upper)` Relative observation range for moving statistics
            (if not specified in call). E.g. `window(-3 1)` means from 3
            lagged observations to 1 leading observation, inclusive. 0
            means up to or from the current observation; window(. #)`
            and `window(# .)` mean from the start and through the end,
            respectively.

### Gtools

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

`gstats transform` applies various statistical transformations to
input data. It is similar to `gcollapse, merge` or `gegen` but for
individual-level transformations. That is, `gcollapse` takes an input
variable and procudes a single statistic; `gstats transform` applies a
function to each element of the input variable. For example, subtracting
the mean.

Every function available to `gstats transform` can be called via `gegen`.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gstats_transform.do)

### Basic usage

Syntax is largely analogous to `gcollapse`

```stata
sysuse auto, clear

gegen norm_price = normalize(price),   by(foreign)
gegen std_price  = standardize(price), by(foreign)
gegen dm_price   = demean(price),      by(foreign)

gstats transform (normalize) norm_mpg = mpg (demean) dm_mpg = mpg, by(foreign) replace
gstats transform (demean) mpg (normalize) price, by(foreign) replace
gstats transform (demean) mpg (normalize) xx = price [w = rep78], by(foreign) auto(#stat#_#source#)
```

### Moving statistics

Note the moving window is defined relative to the current observation.

```stata
clear
set obs 20
gen g = _n > 10
gen x = _n
gen w = mod(_n, 7)

gegen x1 = moving_mean(x), window(-2 2) by(g)
gstats transform (moving mean -1 3) x2 = x, by(g)
gstats transform (moving sd -4 .) x3 = x (moving p75) x4 = x (moving select3) x5 = x, by(g) window(-3 3)
l

drop x?
gegen x1 = moving_mean(x) [fw = w], window(-2 2) by(g)
gstats transform (moving mean -1 3) x2 = x [aw = w], by(g)
gstats transform (moving sd -4 .) x3 = x (moving p75) x4 = x [pw = w / 7], by(g) window(-3 3)
l
```
