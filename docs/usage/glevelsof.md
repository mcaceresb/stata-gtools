glevelsof
=========

Efficiently get levels of variable using C plugins

glevelsof displays a sorted list of the distinct values of varlist.  It is
meant to be a fast replacement of levelsof. Unlike levelsof, it can take a
single variable or multiple variables.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

<p><span style="font-family:monospace">glevelsof varlist [if] [in] [, <a href="#options">options</a> ] </p>

Instead of varlist, it is possible to specify

```stata
[+|-] varname [[+|-] varname ...]
```

This will not affect the levels recovered but it will affect the sort order in
which they are stored and printed.

Options
-------

- `clean` displays string values without compound double quotes.  By default,
            each distinct string value is displayed within compound double
            quotes, as these are the most general delimiters.  If you know that
            the string values in varlist do not include embedded spaces or
            embedded quotes, this is an appropriate option.  clean does not
            affect the display of values from numeric variables.

- `local(macname)` inserts the list of values in local macro macname within
            the calling program's space.  Hence, that macro will be accessible
            after glevelsof has finished.  This is helpful for subsequent use,
            especially with foreach.

- `missing` specifies that missing values of varlist should be included in
            the calculation.  The default is to exclude them.

- `separate(separator)` specifies a separator to serve as punctuation for the
            values of the returned list.  The default is a space.  A useful
            alternative is a comma.

- `colseparate(separator)` specifies a separator to serve as punctuation for
            the columns of the returned list.  The default is a pipe.  Specifying
            a varlist instead of a varname is only useful for double loops or for
            use with gettoken.

- `numfmt(format)` Number format for printing. By default numbers are printed
            to 16 digits of precision, but the user can specify the number format
            here. Only "%.#g|f" and "%#.#g|f" are accepted since this is formated
            internally in C.

- `silent` Do not print levels. If there are many levels and the user still
            wishes to see debugging or benchmark information, this option is
            useful.

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

glevelsof stores the following in r():

    Macros

        r(levels)    list of distinct values

    Scalars

        r(N)         number of non-missing observations
        r(J)         number of groups
        r(minJ)      largest group size
        r(maxJ)      smallest group size

Remarks
-------

glevelsof serves two different functions.  First, it gives a compact
display of the distinct values of varlist.  More commonly, it is useful
when you desire to cycle through the distinct values of varlist with
(say) foreach; see [P] foreach.  glevelsof leaves behind a list in
r(levels) that may be used in a subsequent command.

glevelsof may hit the limits imposed by your Stata.  However, it is
typically used when the number of distinct values of varlist is modest.
If you have many levels in varlist then an alternative may be
gtoplevelsof, which shows the largest or smallest levels of a varlist by
their frequency count.

Examples
--------

```stata
. sysuse auto

. glevelsof rep78
. display `"`r(levels)'"'

. glevelsof rep78, miss local(mylevs)
. display `"`mylevs'"'

. glevelsof rep78, sep(,)
. display `"`r(levels)'"'

. glevelsof foreign rep78, sep(,)
. display `"`r(levels)'"'
```
