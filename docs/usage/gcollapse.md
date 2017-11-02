gcollapse
=========

Efficiently make dataset of summary statistics using C.

gcollapse converts the dataset in memory into a dataset of means, sums,
medians, etc., similar to collapse. Unlike collapse, however, weights are
currently not supported. Further, first, last, firstnm, lastnm for string
variables are not supported.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

This is a fast option to Stata's collapse, with several additions.

<p><span style="font-family:monospace">gcollapse clist [if] [in] [, <a href="#options">options</a> ] </p>

where clist is either

```stata
[(stat)] varlist [ [(stat)] ... ]
[(stat)] target_var=varname [target_var=varname ...] [ [(stat)] ...]
```

or any combination of the varlist or target_var forms, and stat is one of

| Stata      | Description
| ---------- | -----------
| mean       | means (default)
| median     | medians
| p1         | 1st percentile
| p2         | 2nd percentile
| ...        | 3rd-49th percentiles
| p50        | 50th percentile (same as median)
| ...        | 51st-97th percentiles
| p98        | 98th percentile
| p99        | 99th percentile
| p1-99.#    | arbitrary quantiles
| sum        | sums
| sd         | standard deviation
| semean     | standard error of the mean (sd/sqrt(n))
| sebinomial | standard error of the mean, binomial (sqrt(p(1-p)/n)) (missing if source not 0, 1)
| sepoisson  | standard error of the mean, Poisson (sqrt(mean / n)) (result rounded to nearest integer)
| count      | number of nonmissing observations
| percent    | percentage of nonmissing observations
| max        | maximums
| min        | minimums
| iqr        | interquartile range
| first      | first value
| last       | last value
| firstnm    | first nonmissing value
| lastnm     | last nonmissing value

Options
-------

- `by(varlist)` specifies the groups over which the means, etc., are to be
                calculated. It can contain any mix of string or numeric variables.

- `cw` specifies casewise deletion.  If cw is not specified, all possible
       observations are used for each calculated statistic.

- `fast` specifies that gcollapse not restore the original dataset should the
         user press Break.

### Extras

- `merge` merges the collapsed data back to the original data set.  Note that
          if you want to replace the source variable(s) then you need to
          specify replace.

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
            Thisis an rclass that must set prettystat as a return value. The
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
            involves some overhead, however, so if J is known to be small forceio
            will be faster.

- `forcemem` The opposite of forceio. The check for whether to use memory or
            disk check involvesforceio some overhead, so if J is known to be
            large forcemem will be faster.

- `double` stores data in double precision.

### Gtools options

(Note: These are common to every gtools command.)

- `verbose` prints some useful debugging info to the console.

- `benchmark` or `bench(level)` prints how long in seconds various parts of the
            program take to execute. Level 1 is the same as `benchmark`. Level 2
            additionally prints benchmarks for internal plugin steps.

- `hashlib(str)` On earlier versions of gtools Windows users had a problem
            because Stata was unable to find spookyhash.dll, which is bundled
            with gtools and required for the plugin to run correctly. The best
            thing a Windows user can do is run gtools, dependencies at the start
            of their Stata session, but if Stata cannot find the plugin the user
            can specify a path manually here.

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

### Basic usage

The syntax for its basic use is the same as collapse:

```stata
sysuse auto, clear
gcollapse (sum) price mpg (mean) m1 = price m2 = mpg, by(foreign)
l

     +------------------------------------------------------+
     |  foreign    price    mpg        m1        m2     p23 |
     |------------------------------------------------------|
  1. | Domestic   315766   1031   6,072.4   19.8269   4,172 |
  2. |  Foreign   140463    545   6,384.7   24.7727   4,499 |
     +------------------------------------------------------+
```

You can call multiple names per statistic in any order,
optionally specifying the target name.

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

The default label for collapsed stats is "(stat) source label"..  I find this
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
