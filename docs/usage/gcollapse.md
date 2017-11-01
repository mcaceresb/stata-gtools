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

- `freq(varname)` Specifies that the row count of each group be stored in
            freq after the collapse.

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

- `benchmark` prints how long in seconds various parts of the program take to
            execute.

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

Pending XX
