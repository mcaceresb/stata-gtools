gcontract
=========

Efficiently make dataset of frequencies and percentages

gcontract replaces the dataset in memory with a new dataset consisting of
all combinations of varlist that exist in the data and a new variable
that contains the frequency of each combination. The user can optionally
request percentages and cumulative counts and percentages.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

This is a fast option to Stata's contract.

<p><span style="font-family:monospace">gcontract varlist [if] [in] [, <a href="#options">options</a> ] </p>

Instead of varlist, it is possible to specify

```stata
[+|-] varname [[+|-] varname ...]
```

This will not affect the results, but it will affect the sort order of
the final data.


Options
-------


- `freq(newvar)` specifies a name for the frequency variable.  If not
            specified, `_freq` is used.

- `cfreq(newvar)` specifies a name for the cumulative frequency variable.  If
            not specified, no cumulative frequency variable is created.

- `percent(newvar)` specifies a name for the percentage variable.  If not
            specified, no percent variable is created.

- `cpercent(newvar)` specifies a name for the cumulative percentage variable.
            If not specified, no cumulative percentage variable is created.

- `float` specifies that the percentage variables specified by percent() and
            cpercent() will be stored as variables of type float. This only
            affects the Stata storage type; gtools does all computations
            internally in double precision. If float is not specified, these
            variables will be generated as variables of type double.  All
            generated variables are compressed to the smallest storage type
            possible without loss of precision; see [D] compress.

- `format(format)` specifies a display format for the generated percentage
            variables specified by percent() and cpercent().  If format() is not
            specified, these variables will have the display format %8.2f.

- `zero` specifies that combinations with frequency zero be included.  This
            is VERY slow.

- `nomiss` specifies that observations with missing values on any variable in
            varlist be dropped.  If nomiss is not specified, all observations
            possible are used.

### Extras

- `fast` specifies that gcollapse not restore the original dataset should the
            user press Break.

- `unsorted` Do not sort resulting data set. Saves speed.

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

Stored results
--------------

gcontract stores the following in r():

    r(N)       number of non-missing observations
    r(J)       number of groups
    r(minJ)    largest group size
    r(maxJ)    smallest group size

Examples
--------

Pending XX
