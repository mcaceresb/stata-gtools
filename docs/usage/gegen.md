gegen
=====

Efficient implementation of by-able egen functions using C.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p>
<span class="codespan"><b>gegen</b> [type] newvar = fcn(arguments) [if] [in] [weight] [, ///</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp; replace <a href="#compiled-functions">fcn_options</a> <a href="#gtools-options">gtools_options</a> ]
</p>

### Gtools options

- `compress` Try to compress strL to `str#`.

- `forcestrl` Skip binary variable check and force gtools to read strL variables.

- `verbose` prints some useful debugging info to the console.

- `benchmark` prints how long in seconds various parts of the program take to execute.

- `benchmarklevel(int)` depth of benchmark.

- `hashmethod(str)` For debugging: default, biject, or spooky.

- `oncollision(str)` For debugging: fallback or error.

- `gtools_capture(str)`  The above options are captured and not passed to
                                 egen in case the requested function is not
                                 internally supported by gtools. You can pass
                                 extra arguments here if their names conflict
                                 with captured gtools options.

Weights
-------

Weights are only allowed for internally-implemented functions. In
particular they only affect: total, sum, mean, sd, count, median,
iqr, percent, semean, sebinomial, sepoisson, percentiles, skewness,
kurtosis. They are ignored by: tag, group, nunique, max, min, first,
last, firstnm, lastnm. All other functions do not allow weights.

aweight, fweight, iweight, and pweight are allowed for the functions
listed below and mimic `collapse` (see `help weight` and the weights
section in `help collapse`).

pweights may not be used with sd, semean, sebinomial, or sepoisson.
iweights may not be used with semean, sebinomial, or sepoisson. aweights
may not be used with sebinomial or sepoisson.

Compiled functions
------------------

The following are simply wrappers for other _gtools_ functions.  Consult
each command's corresponding help files for details. (Note that `gstats
transform` in particular allows embedding options in the statistic call
rather than program arguments; while this is technically also possible
to do through `gegen`, I do not recommend it. Instead, use `window()` with
`moving_stat`, `interval()` with `range_stat`, `cumby()` with `cumsum`, and
so on.) In the table, `stat` can be replaced with any stat available to
`gcollapse` except percent, `nunique`:

    function              -> calls
    -----------------------------------------
    xtile(exp)            -> fasterxtile
    standardize(varname)  -> gstats transform
    normalize(varname)    -> gstats transform
    demean(varname)       -> gstats transform
    demedian(varname)     -> gstats transform
    moving_stat(varname)  -> gstats transform
    range_stat(varname)   -> gstats transform
    cumsum(varname)       -> gstats transform
    shift(varname)        -> gstats transform
    rank(varname)         -> gstats transform
    winsor(varname)       -> gstats winsor
    winsorize(varname)    -> gstats winsor

The functions listed here have been compiled and hence will run very quickly.
Functions not listed here hash the data and then call egen with by(varlist)
set to the hash, which is often faster than calling egen directly, but not
always. The functions here _should_ always be faster, however.

### Generate IDs

    group(varlist) [, missing counts(newvarname) fill(real)]
        may not be combined with by.  It creates one variable taking on
        values 1, 2, ... for the groups formed by varlist.  varlist may
        contain numeric variables, string variables, or a combination of
        the two.  The default order of the groups is the sort order of the
        varlist. However, the user can specify:

            [+|-] varname [[+|-] varname ...]

        And the order will be inverted for variables that have -
        prepended.  missing indicates that missing values in varlist
        (either . or "") are to be treated like any other value when
        assigning groups, instead of as missing values being assigned to
        the group missing.

        You can also specify counts() to generate a new variable with the
        number of observations per group; by default all observations
        within a group are filled with the count, but via fill() the user
        can specify the value the variable will take after the first
        observation that appears within a group. The user can also
        specify fill(data) to fill the first Jth observations with the
        count per group (in the sorted group order) or fill(group) to
        keep the default behavior.

### Tag groups

    tag(varlist) [, missing]
        may not be combined with by.  It tags just 1 observation in each
        distinct group defined by varlist.  When all observations in a
        group have the same value for a summary variable calculated for
        the group, it will be sufficient to use just one value for many
        purposes.  The result will be 1 if the observation is tagged and
        never missing, and 0 otherwise.

        Note values for any observations excluded by either if or in are
        set to 0 (not missing).  Hence, if tag is the variable produced
        by egen tag = tag(varlist), the idiom if tag is always safe.
        missing specifies that missing values of varlist may be included.

### Summary stats

All the functions listed here allow `by(varlist)`. If this is not specified,
then operations are performed by row. `exp` must be a valid Stata espression
or a list of variables.

    first|last|firstnm|lastnm(exp)
        creates a constant (within varlist) containing the first, last,
        first non-missing, and last non-missing observation. The
        functions are analogous to those in collapse and not to those in
        egenmore.

    count(exp)
        creates a constant (within varlist) containing the number of
        nonmissing observations of exp.

    nunique(exp)
        creates a constant (within varlist) containing the number of
        unique observations of exp.

    iqr(exp)
        creates a constant (within varlist) containing the interquartile
        range of exp.  Also see pctile().

    max(exp)
        creates a constant (within varlist) containing the maximum value
        of exp.

    mean(exp)
        creates a constant (within varlist) containing the mean of exp.

    geomean(exp)
        creates a constant (within varlist) containing the geometric mean of exp.
        If exp has any negative values, the function returns missing (`.`). If it
        has any zeros, the function returns zero.

    median(exp)
        creates a constant (within varlist) containing the median of exp.
        Also see pctile().

    min(exp)
        creates a constant (within varlist) containing the minimum value
        of exp.

    range(exp)
        creates a constant (within varlist) containing the range of exp.

    pctile(exp) [, p(#)]
        creates a constant (within varlist) containing the #th percentile
        of exp.  If p(#) is not specified, 50 is assumed, meaning
        medians.  Also see median().

    select(exp) , n(#|-#)
        creates a constant (within varlist) containing the `#`th smallest
        non-missing value of exp.  If `-#` is specified, the `#`th _largest_
        non-missing value is output instead. Note if there are any non-missing
        values then `n(1)` and `n(-1)` will output the same value as `min` and
        `max`, respectively.

    sd(exp)
        creates a constant (within varlist) containing the standard
        deviation of exp.  Also see mean().

    variance(exp)
        creates a constant (within varlist) containing the variance
        of exp.  Also see sd().

    cv(exp)
        creates a constant (within varlist) containing the coefficient
        of variation of exp.  Also see sd() adn mean().

    percent(exp)
        creates a constant (within varlist) containing the percent of
        non-missing observations in the group relative to the sample.

    semean(exp)
        creates a constant (within varlist) containing the standard
        error of the mean (sd/sqrt(n))

    sebinomial(exp)
        creates a constant (within varlist) containing the standard
        error of the mean, binomial (sqrt(p(1-p)/n)) (missing if not 0, 1)

    sepoisson(exp)
        creates a constant (within varlist) containing the standard
        error of the mean, Poisson (sqrt(mean / n)) (missing if
        negative; result rounded to nearest integer)

    skewness(exp)
        creates a constant (within varlist) containing the skewness

    kurtosis(exp)
        creates a constant (within varlist) containing the kurtosis

    total(exp) [, missing]
    sum(exp) [, missing]
        creates a constant (within varlist) containing the sum of exp
        treating missing as 0.  If missing is specified and all values in
        exp are missing, newvar is set to missing.  Also see mean().

    gini(exp)
    gini|dropneg(exp)
    gini|keepneg(exp)
        creates a constant (within varlist) containing the Gini
        coefficient of exp, truncating negative values to 0. `gini|dropneg`
        drops negative values, and `gini|keepneg` keeps negative values
        as is (the user is responsible for the interpretation of the
        Gini coefficient in this case).

Description
-----------

gegen creates newvar of the optionally specified storage type equal to
fcn(arguments). Here fcn() is either one of the internally supported
commands above or a by-able function written for egen, as documented
above. Only egen functions or internally supported functions may be used
with egen.  If you want to generate multiple summary statistics from a
single variable it may be faster to use gcollapse with the merge option.

Depending on fcn(), arguments, if present, refers to an expression,
varlist, or a numlist, and the options are similarly fcn dependent.

Out of memory
-------------

(See also Stata's own discussion: help memory.)

There are many reasons for why an OS may run out of memory. The best-case
scenario is that your system is running some other memory-intensive
program.  This is specially likely if you are running your program on a
server, where memory is shared across all users. In this case, you should
attempt to re-run gegen once other memory-intensive programs finish.

If no memory-intensive programs were running concurrently, the second
best-case scenario is that your user has a memory cap that your programs
can use. Again, this is specially likely on a server, and even more
likely on a computing grid.  If you are on a grid, see if you can
increase the amount of memory your programs can use (there is typically a
setting for this). If your cap was set by a system administrator,
consider contacting them and asking for a higher memory cap.

If you have no memory cap imposed on your user, the likely scenario is
that your system cannot allocate enough memory for gegen. At this point
you can try fegen or egen, which are slower but using either should
require a trivial one-letter change to the code.  Note, however, that
replacing gegen with fegen or plain egen is not guaranteed to use less
memory. I have not benchmarked memory use very extensively, so gegen
might use less memory (I doubt that is the case in most scenarios, but
it is possible).

You can also try to process the data by segments. However, if you are
doing group operations you would need to first sort the data and make
sure you are not splitting groups apart.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gegen.do)

```stata
. sysuse auto, clear
. gegen id    = group(foreign)
. gegen tag   = group(foreign)
. gegen sum   = sum(mpg), by(foreign)
. gegen sum2  = sum(mpg rep78), by(foreign)
. gegen p5    = pctile(mpg rep78), p(5) by(foreign)
. gegen nuniq = nunique(mpg rep78), by(foreign)
```

The function can be any of the supported functions above.
It can also be any function supported by egen:

```stata
. webuse egenxmpl4, clear

. gegen hsum = rowtotal(a b c)
rowtotal() is not a gtools function and no by(); falling back on egen

. sysuse auto, clear
(1978 Automobile Data)

. gegen seq = seq(), by(foreign)
seq() is not a gtools function; will hash and use egen
```
