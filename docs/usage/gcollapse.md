gcollapse
=========

Efficiently make dataset of summary statistics using C.

gcollapse converts the dataset in memory into a dataset of means, sums,
medians, etc., similar to collapse. Unlike collapse, however, first,
last, firstnm, lastnm for string variables are not supported.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

This is a fast option to Stata's collapse, with several additions.

<p><span class="codespan"><b>gcollapse</b> clist [if] [in] [weight] [, <a href="#options">options</a> ] </p>

where clist is either

```stata
[(stat)] varlist [ [(stat)] ... ]
[(stat)] target_var=varname [target_var=varname ...] [ [(stat)] ...]
```

or any combination of the `varlist` or `target_var` forms, and stat is one of

| Stat        | Description
| ----------- | -----------
| mean        | means (default)
| geomean     | geometric means
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

Weights
-------

aweight, fweight, iweight, and pweight are allowed and mimic `collapse`
(see `help weight` and the weights section in `help collapse`).

pweights may not be used with sd, semean, sebinomial, or sepoisson.
iweights may not be used with semean, sebinomial, or sepoisson. aweights
may not be used with sebinomial or sepoisson.

Options
-------

- `by(varlist)` specifies the groups over which the means, etc., are to be
                calculated. It can contain any mix of string or numeric variables.

- `cw` specifies casewise deletion.  If cw is not specified, all possible
       observations are used for each calculated statistic.

- `fast` specifies that gcollapse not restore the original dataset should the
         user press Break.

### Extras

- `rawstat(varlist)` Sequence of target names for which to ignore weights,
        except observations with a weight of zero or missing, which
        are excluded. This is a generalization of rawsum, but it is
        specified for each individual target (if no target is specified,
        the source variable name is what we call target).

- `merge` merges the collapsed data back to the original data set.  Note that
          if you want to replace the source or target variable(s) then you need
          to specify `replace`.

- `wildparse` specifies that the function call should be parsed assuming
              targets are named using rename-stle syntax. For example,
              `gcollapse (sum) s_x* = x*, wildparse`

- `replace` Replace allows replacing existing variables with merge.

- `freq(varname)` stores the group frequency count in freq. It differs from
            count because it merely stores the number of occurrences of the group
            in the data, rather than the non-missing count. Hence it is
            equivalent to summing a dummy variable equal to 1 everywhere.

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

- `unsorted` Do not sort resulting data set. Saves speed.

### Switches

- `forceio` By default, when there are more than 3 additional targets (i.e.
            the number of targets is greater than the number of source variables
            plus 3) the function tries to be smart about whether adding empty
            variables in Stata before the collapse is faster or slower than
            collapsing the data to disk and reading them back after keeping only
            the first J observations (assuming J is the number of groups). For J
            small relative to N, collapsing to disk will be faster. This check
            involves some overhead, however, so if J is known to be small `forceio`
            will be faster.

- `forcemem` The opposite of `forceio`. The check for whether to use memory or
            disk check involves some overhead, so if J is known to be
            large forcemem will be faster.

- `double` stores data in double precision.

- `sumcheck` Check whether byte, int, or long sum will overflow.  By
            default sum targets are double; in this case, sum targets
            check the smallest integer type that will be suitable and
            only assigns a double if the sum would overflow.


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

Out of memory
-------------

(See also Stata's own discussion in `help memory`.)

There are many reasons for why an OS may run out of memory. The best-case
scenario is that your system is running some other memory-intensive
program.  This is specially likely if you are running your program on a
server, where memory is shared across all users. In this case, you should
attempt to re-run gcollapse once other memory-intensive programs finish.

If no memory-intensive programs were running concurrently, the second
best-case scenario is that your user has a memory cap that your programs
can use. Again, this is specially likely on a server, and even more
likely on a computing grid.  If you are on a grid, see if you can
increase the amount of memory your programs can use (there is typically a
setting for this). If your cap was set by a system administrator,
consider contacting them and asking for a higher memory cap.

If you have no memory cap imposed on your user, the likely scenario is
that your system cannot allocate enough memory for gcollapse. At this
point you have two options: One option is to try fcollapse or collapse,
which are slower but using either should require a trivial one-letter
change to the code; another option is to re-write the code to collapse
the data in segments (the easiest way to do this would be to collapse a
portion of all variables at a time and perform a series of 1:1 merges at
the end).

Replacing gcollapse with fcollapse or plain collapse is an option because
gcollapse often uses more memory. This is a consequence of Stata's
inability to create variables via C plugins. This forces gcollapse to
create variables before collapsing, meaning that if there are J groups
and N observations, gcollapse uses N - J more rows than the ideal
collapse program, per variable.

gcollapse was written with this limitation in mind and tries to save
memory in various ways (for example, if J is small relative to N,
gcollapse will use free disk space instead of memory, which not only
saves memory but is also much faster). Nevertheless, it is possible that
your system will allocate enough memory for fcollapse or collapse in
situations where it cannot allocate enough memory for gcollapse.

Stored results
--------------

gcollapse stores the following in r():

    r(N)       number of non-missing observations
    r(J)       number of groups
    r(minJ)    largest group size
    r(maxJ)    smallest group size

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gcollapse.do)

### Basic usage

The syntax for its basic use is the same as collapse:

```stata
sysuse auto, clear
gcollapse (sum) price mpg (mean) m1 = price m2 = mpg if !mi(rep78), by(foreign)
l

     +---------------------------------------------+
     |  foreign    price   mpg        m1        m2 |
     |---------------------------------------------|
  1. | Domestic   296604   938   6,179.3   19.5417 |
  2. |  Foreign   127473   531   6,070.1   25.2857 |
     +---------------------------------------------+
```

You can call multiple names per statistic in any order, optionally
specifying the target name. Further, weights can be selectively applied
to each target.

```stata
sysuse auto, clear
gcollapse (mean) price praw = price [fw = rep78], by(foreign) rawstat(praw)
l

     +------------------------------+
     |  foreign     price      praw |
     |------------------------------|
  1. | Domestic   6,162.5   6,179.3 |
  2. |  Foreign   6,133.8   6,070.1 |
     +------------------------------+
```

Note, however, that rows with missing or 0 values of rep78 are excluded
regardless when selectively applying weights.

### Unique counts

```stata
sysuse auto, clear
gcollapse (nunique) rep78 mpg turn, by(foreign)
l

     +-------------------------------+
     |  foreign   rep78   mpg   turn |
     |-------------------------------|
  1. | Domestic       6    17     17 |
  2. |  Foreign       4    13      7 |
     +-------------------------------+
```

### Wild Parsing

```stata
clear
set obs 10
gen x1 = _n
gen x2 = _n^2
gen x3 = _n^3

gcollapse mean_x* = x*, wildparse
l

     +-----------------------------+
     | mean_x1   mean_x2   mean_x3 |
     |-----------------------------|
  1. |     5.5      38.5     302.5 |
     +-----------------------------+
```

### Quantiles

gcollapse allows the user to specify arbitrary quantiles:
```stata
sysuse auto, clear
gcollapse (p2.5) p2_5 = price (p97.5) p97_5 = price, by(foreign)
l

     +---------------------------+
     |  foreign    p2_5    p97_5 |
     |---------------------------|
  1. | Domestic   3,299   14,500 |
  2. |  Foreign   3,748   12,990 |
     +---------------------------+
```

This is useful if you have a large number of observations per group:

```stata
clear
set obs 1000
gen long id = _n
gcollapse              ///
    (p2)    p2    = id ///
    (p2.5)  p2_5  = id ///
    (p3)    p3    = id ///
    (p96)   p96   = id ///
    (p97.5) p97_5 = id ///
    (p98)   p98   = id
l

     +--------------------------------------------+
     |   p2   p2_5     p3     p96   p97_5     p98 |
     |--------------------------------------------|
  1. | 20.5   25.5   30.5   960.5   975.5   980.5 |
     +--------------------------------------------+
```

### Label outputs

The default label for collapsed stats is "(stat) source label".  I find this
format ugly, so I have implemented a very basic engine to label outputs:

```stata
sysuse auto, clear
gcollapse (mean) price, labelformat(#stat#: #sourcelabel#)
disp _n(1) "`:var label price'"
```
```
mean: Price
```

The following placeholder options are available in the engine:

- `#stat#`, `#Stat#`, and `#STAT#` are replaced with the lower-, title-, and
  upper-case name of the summary stat.

- `#sourcelabel#`, `#sourcelabel:start:numchars#` are replaced with the source label,
  optionally extracting `numchars` characters from `start` (`numchars` can be `.`
  to denote all characters from `start`).

- `#stat:pretty#` replces each stat name with a nicer version (mean to Mean,
  sd to St Dev., and so on). The user can specify a their own custom pretty
  program via `labelprogram()`. The program MUST be an rclass program
  and return `prettystat`. For example

```stata
capture program drop my_pretty_stat
program my_pretty_stat, rclass
         if ( `"`0'"' == "sum"  ) local prettystat "Total"
    else if ( `"`0'"' == "mean" ) local prettystat "Average"
    else {
        local prettystat "#default#"
    }
    return local prettystat = `"`prettystat'"'
end

sysuse auto, clear
gcollapse               ///
    (mean) mean = price ///
    (sum)  sum = price  ///
    (sd)   sd = price,  ///
    freq(obs)           ///
    labelformat(#stat:pretty# #sourcelabel#) labelp(my_pretty_stat)

disp _n(1) "`:var label mean'" ///
     _n(1) "`:var label sum'"  ///
     _n(1) "`:var label sd'"   ///
     _n(1) "`:var label obs'"
```
```
Average Price
Total Price
St Dev. Price
Group size
```

We can see that `mean` and `sum` were set to the custom label, while `sd` was
set to the default. You can also specify a different label format for each
variable if you put the stat palceholder in the variable label.

```stata
sysuse auto, clear
gen mean = price
gen sum  = price

label var mean  "Price (#stat#)"
label var sum   "Price #stat:pretty#"
label var price "`:var label price' #stat:pretty#"

gcollapse               ///
    (mean) mean         ///
    (sum)  sum          ///
    (sd)   sd = price,  ///
    labelformat(#sourcelabel#) labelp(my_pretty_stat)

disp _n(1) "`:var label mean'" ///
     _n(1) "`:var label sum'"  ///
     _n(1) "`:var label sd'"
```
```
Price (mean)
Price Sum
Price St Dev.
```

### Merge

You can merge summary stats back to the main data with gcollapse. This is
equivalent to a sequence of `egen` statements or to `collapse` followed by
merge. That is, if you want to create bulk summary statistics, you might want
to do:

```stata
sysuse auto, clear
qui {
    preserve
    collapse (mean) m_pr = price (sum) s_gr = gear_ratio, by(rep78)
    tempfile bulk
    save `bulk'
    restore
    merge m:1 rep78 using `bulk', assert(3) nogen
}
```

But with gcollapse this is simplified to
```stata
sysuse auto, clear
gcollapse (mean) m_pr = price (sum) s_gr = gear_ratio, by(rep78) merge
```

If you wish to replace the source variables, you can do
```stata
sysuse auto, clear
gcollapse (mean) price (sum) gear_ratio, by(rep78) merge replace
```

### Using I/O vs memory

gcollapse tries to determine whether using memory or using
your disk's temporary drive is better. For example:
```stata
sysuse auto, clear
gen long id = _n * 1000
expand id
replace id = _n
tempfile io
save `io'

local call (sum)  s1 = id ///
           (mean) s2 = id ///
           (max)  s3 = id ///
           (min)  s4 = id ///
           (sd)   s5 = id

gcollapse `call', by(foreign) v
```
```
Bijection OK with all integers (i.e. no extended miss val)? Yes.
Counting sort on hash; min = 1, max = 2
N = 2,775,000; 2 unbalanced groups of sizes 1,378,000 to 1,397,000
Will write 4 extra targets to disk (full data = 84.7 MiB; collapsed data = 6.1e-05 MiB).
        Adding targets before collapse estimated to take 0.00027 seconds.
        Adding targets after collapse estimated to take 1.9e-10 seconds.
        Writing/reading targets to/from disk estimated to take 1.4e-07 seconds.
Will write to disk and read back later to save time.
```

Foreign has 2 levels, and we can see that `gcollapse`
determines that collapsing to disk would save time.
However, we can skip this check if we know a variable
has few levels:
```stata
use `io', clear
gcollapse `call', by(foreign) verbose forceio bench
```
```
Parsed by variables, sources, and targets; .013 seconds
Recast source variables to save memory; .06 seconds
Parsed by variables; .001 seconds
Bijection OK with all integers (i.e. no extended miss val)? Yes.
Counting sort on hash; min = 1, max = 2
N = 2,775,000; 2 unbalanced groups of sizes 1,378,000 to 1,397,000
Plugin runtime; .21 seconds
Total runtime (internals); .213 seconds
Added extra targets after collapse; 0 seconds
Read extra targets from disk; .004 seconds
Program exit executed; 0 seconds
```

We can see that `gcollapse` skipped the check but that it read the collapsed
targets from disk after the collapse. We can also force `gcollapse` to use memory:
```stata
use `io', clear
gcollapse `call', by(foreign) verbose forcemem bench
```
```
Parsed by variables, sources, and targets; .006 seconds
Recast source variables to save memory; .044 seconds
Dropped superfluous variables; .061 seconds
Generated additional targets; 0 seconds
Parsed by variables; .002 seconds
Bijection OK with all integers (i.e. no extended miss val)? Yes.
Counting sort on hash; min = 1, max = 2
N = 2,775,000; 2 unbalanced groups of sizes 1,378,000 to 1,397,000
Plugin runtime; .222 seconds
Total runtime (internals); .224 seconds
Program exit executed; .001 seconds
```

Again, it skipped the check but this time but we can see it generated the
targets before the collapse.
