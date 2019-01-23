glevelsof
=========

Efficiently get levels of variable using C plugins

glevelsof displays a sorted list of the distinct values of varlist.  It is
meant to be a fast replacement of levelsof. Unlike levelsof, it can take a
single variable or multiple variables.

_Important:_ Please run `gtools, upgrade` to update `gtools` to the
latest stable version.

Syntax
------

<p><span class="codespan">glevelsof varlist [if] [in] [, <a href="#options">options</a> ] </p>

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

### Extras

- `nolocal` Do not store `varlist` levels in a local macro. This is
            specially useful with `gen()`

- `gen([prefix], [replace])` Store the unique levels of `varlist`
            in a new varlist prefixed by `prefix` **or** `replace` the
            `varlist` with its unique levels. The two optoins are
            mutually exclusive.

- `colseparate(separator)` specifies a separator to serve as punctuation for
            the columns of the returned list.  The default is a pipe.  Specifying
            a varlist instead of a varname is only useful for double loops or for
            use with gettoken.

- `numfmt(format)` Number format for printing. By default numbers are printed
            to 16 digits of precision, but the user can specify the number format
            here. Only "%.#g|f" and "%#.#g|f" are accepted since this is formated
            internally in C.

- `unsorted` Do not sort levels. This option is experimental and only affects the
            output when the input is not an integer (for integers, the levels are
            sorted internally regardless). While not sorting the levels is faster,
            `glevelsof` is typically used when the number of levels is small (10s,
            100s, 1000s) and thus speed
            savings will be minimal.

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

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/glevelsof.do)

```stata
. sysuse auto
(1978 Automobile Data)

. glevelsof rep78
1 2 3 4 5

. qui glevelsof rep78, miss local(mylevs)

. display "`mylevs'"
1 2 3 4 5 .

. glevelsof rep78, sep(,)
1,2,3,4,5
```
###  De-duplicating a variable list

`glevelsof` can store the unique levels of a varlist. This is specially
useful when the user wants to obtain the unique levels but runs up
against the stata macro variable limit.

```stata
. set seed 42

. clear

. set obs 100000
obs was 0, now 100000

. gen x = "a long string appeared" + string(mod(_n, 10000))

. gen y = int(10 * runiform())

. glevelsof x
macro substitution results in line that is too long
    The line resulting from substituting macros would be longer than allowed.  The maximum allowed length is 165,216 characters, which is calculated on the
    basis of set maxvar.

    You can change that in Stata/SE and Stata/MP.  What follows is relevant only if you are using Stata/SE or Stata/MP.

    The maximum line length is defined as 16 more than the maximum macro length, which is currently 165,200 characters.  Each unit increase in set maxvar
    increases the length maximums by 33.  The maximum value of set maxvar is 32,767.  Thus, the maximum line length may be set up to 1,081,527 characters
    if you set maxvar to its largest value.

try gen(prefix) nolocal; see help glevelsof for details
r(920);

. glevelsof x, gen(uniq_) nolocal
. gisid uniq_* in 1 / `r(J)'
```

The user can also replace the source variables if need be. This is
faster and saves memory, but it dispenses with the original variables.

```stata
. glevelsof x, gen(uniq_) nolocal

. glevelsof x y, gen(, replace) nolocal

. l in `r(J)'

       +-----------------------------------------+
       |                          x   y   uniq_x |
       |-----------------------------------------|
64958. | a long string appeared9999   8          |
       +-----------------------------------------+

. l in `=_N'

        +----------------+
        | x   y   uniq_x |
        |----------------|
100000. |     .          |
        +----------------+
```

### Number format

`levelsof` by default shows many significant digits for numerical variables.

```stata
. sysuse auto, clear

. replace headroom = headroom + 0.1

. glevelsof headroom
1.600000023841858 2.099999904632568 2.599999904632568 3.099999904632568 3.599999904632568 4.099999904632568 4.599999904632568 5.099999904632568

. levelsof headroom
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

levels
end
```

And now we have the leves in a mata matrix:
```
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
