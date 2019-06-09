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

| Stat        | Description
| ----------- | -----------
| demean      | subtract the mean (default)
| demedian    | subtract the median
| normalize   | (x - mean) / sd
| standardize | same as normalize

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

- `nogreedy` Use slower but memory-efficient (non-greedy) algorithm.

- `types(str)` Override variable types for targets (**use with caution**).

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

```stata
sysuse auto, clear

gegen norm_price = normalize(price),   by(foreign)
gegen std_price  = standardize(price), by(foreign)
gegen dm_price   = demean(price),      by(foreign)

gstats transform (normalize) norm_mpg = mpg (demean) dm_mpg = mpg, by(foreign) replace
gstats transform (demean) mpg (normalize) price, by(foreign) replace
```
