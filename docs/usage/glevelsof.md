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
        r(sep)       Row separator
        r(colsep)    Column sezparator

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
(1978 Automobile Data)

. glevelsof rep78
1 2 3 4 5

. glevelsof rep78, miss local(mylevs) silent

. display "`mylevs'"
1 2 3 4 5 .

. glevelsof rep78, sep(,)
1,2,3,4,5
```

### Number format

`levelsof` by default shows many significant digits for numerical variables.

```stata
. sysuse auto, clear

. replace headroom = headroom + 0.1

. glevelsof headroom
1.600000023841858 2.099999904632568 2.599999904632568 3.099999904632568 3.599999904632568 4.099999904632568 4.599999904632568 5.099999904632568
```

This is cumbersome. You can specify a number format to compress this:
```stata
. glevelsof headroom, numfmt(%.3g)
1.6 2.1 2.6 3.1 3.6 4.1 4.6 5.1
```

### Multiple variables

`glevelsof` can parse multiple variables:

```
. local varlist foreign rep78

. glevelsof `varlist', sep("|") colsep(", ")
`"0, 1"'|`"0, 2"'|`"0, 3"'|`"0, 4"'|`"0, 5"'|`"1, 3"'|`"1, 4"'|`"1, 5"'
```

If you know a bit of mata, you can parse this string!
```stata
mata:
------------------------------------------------------------------------
string scalar function unquote_str(string scalar quoted_str)
{
    if ( substr(quoted_str, 1, 1) == `"""' ) {
        quoted_str = substr(quoted_str, 2, strlen(quoted_str) - 2)
    }
    else if (substr(quoted_str, 1, 2) == "`" + `"""') {
        quoted_str = substr(quoted_str, 3, strlen(quoted_str) - 4)
    }
    return (quoted_str);
}

t = tokeninit(`"`r(sep)'"', (""), (`""""', `"`""'"'), 1)
tokenset(t, `"`r(levels)'"')

rows = tokengetall(t)
for (i = 1; i <= cols(rows); i++) {
    rows[i] = unquote_str(rows[i]);
}

levels = J(cols(rows), `:list sizeof varlist', "")

t = tokeninit(`"`r(colsep)'"', (""), (`""""', `"`""'"'), 1)
for (i = 1; i <= cols(rows); i++) {
    tokenset(t, rows[i])
    levels[i, .] = tokengetall(t)
    for (k = 1; k <= `:list sizeof varlist'; k++) {
        levels[i, k] = unquote_str(levels[i, k])
    }
}
end
------------------------------------------------------------------------

. mata: levels

       1   2
    +---------+
  1 |  0   1  |
  2 |  0   2  |
  3 |  0   3  |
  4 |  0   4  |
  5 |  0   5  |
  6 |  1   3  |
  7 |  1   4  |
  8 |  1   5  |
    +---------+
```

While this looks cumbersome, this mechanism is used internally by
`gtoplevelsof` to display its results.
