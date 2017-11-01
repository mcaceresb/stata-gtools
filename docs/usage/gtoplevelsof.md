gtoplevelsof 
============

Quickly tabulate most common levels of variable list.

gtoplevelsof displays a table with the frequency counts, percentages, and
cummulative counts and %s of the most common levels of varlist that occur in
the data.  It is similar to the user-written group with the select otpion or
to contract after keeping only the largest frequency counts.

Unlike contract, it does not modify the original data and instead prints the
resulting table to the console. It also stores a matrix with the frequency
counts and stores the levels in the macro r(levels).


Syntax
------

<p><span style="font-family:monospace">gtoplevelsof varlist [if] [in] [, <a href="#options">options</a> ] </p>

Instead of varlist, it is possible to specify

```stata
[+|-] varname [[+|-] varname ...]
```

Note sort order is used to break ties, so this might affect the
levels displayed.

Options
-------

### Summary Options

- `ntop(int)` Number of levels to display. This can be negative.  In that
            case, the smallest frequencies are displayed. Note cummulative
            percentages and counts are computed within each generated table, so
            for the smallest groups the table would display the cummulative count
            for those frequencies, in descending order.

- `freqabove(int)` Skip frequencies below this level then determining the
            largest levels. So if this is 10, only frequencies above 10 will be
            displayed as part of the top frequencies.  If every frequency that
            would be displayed is above this level then this option has no
            effect.

- `pctabove(real)` Skip frequencies that are a smaller percentage of the data
            than pctabove. If this is 10, then only frequencies that represent at
            least 10% of all observations are displayed as part of the top
            frequencies.  If every frequency that would be displayed is at least
            this percentage of the data then this option has no effect.

### Toggles

- `missrow` Add row with count of missing values. By default, missing rows
            are treated as another group and will be displayed as part of the top
            levels. With multiple variables, only rows with all values missing
            are counted here unless groupmissing is also passed. If this option
            is specified then a row is printed after the top levels with the
            frequency count of missing rows.

- `groupmissing` This option specifies that a missing row is a row where any
            of the variables have a missing value. See missrow.

- `nomissing` Case-wise exclude rows with missing values from frequency
            count.  By default missing values are treated as another level.

- `noother` By default a row is printed after the top levels with the
            frequency count from groups not in the top levels and not counted as
            missing. This option toggles display of that row.

### Display Options

- `pctfmt(format)` Print format for percentage columns.

- `otherlabel(str)` Specify label for row with the count of the rest of the
            levels.

- `missrowlabel(str)` Specify the label for the row the count of the
            "missing" levels.

- `varabbrev(int)` Variables names are displayed above their groups. This
            option specifies that variables should be abbreviated to at most
            varabbrev characters. This is ignored if it is smaller than 5.

- `colmax(numlist)` Specify width limit for levels (can be single number of
            variable-specific).

- `colstrmax(numlist)` Specify width limit for string variables (can be
            single number of variable-specific). Ths overrides colmax for strings
            and allows the user to specify string and number widths sepparately.
            (Also see numfmt(format))

- `numfmt(format)` Format for numeric variables. Default is %.8g.  Note
            number levels are formatted in C, so this must be a valid format for
            the C internal printf. The syntas is very similar to mata's printf.
            Some examples are: %.2f, %10.6g, %5.0f, and so on.

- `colseparate(separator)` Column separator; default is double blank " ".

- `novaluelabels` Do not replace numeric variables with their value labels.
            Value label widths are governed by colmax and NOT colstrmax.

- `hidecontlevels` If a level is repeated in the subsequent row, display a
            blank. This is only done if both observations are within the same
            outer level.

### levelsof Options

- `local(macname)` inserts the list of levels in local macro macname within
            the calling program's space. Hence, that macro will be accessible
            after gtoplevelsof has finished.  This is helpful for subsequent use.
            Note this uses colseparate to sepparate columns. The default is " "
            so be careful when parsing! Rows are enclosed in double quotes (`""')
            so parsing is possible, just not trivial.

- `separate(separator)` specifies a separator to serve as punctuation for the
            values of the returned list.  The default is a space.  A useful
            alternative is a comma.

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

gtoplevelsof stores the following in r():

    Macros

        r(levels)       list of top (most common) levels (rows)
                        
    Scalars             
                        
        r(N)            number of non-missing observations
        r(J)            number of groups
        r(minJ)         largest group size
        r(maxJ)         smallest group size
                        
    Matrices            
        r(toplevels)    Table with frequency counts and percentages.

The missing and other rows are stored in the matrix with IDs 2 and 3,
respectively.

Remarks
-------

gtoplevelsof has the main function of displaying the most common levels
of varlist. While tab is great, it cannot handle a large number of
levels, and it prints ALL the levels in alphabetical order.

Very often when exploring data I just want to have a quick look at the
largest levels of a variable that may have thousands of levels in a data
set with millions of rows. gcontract and gcollapse are great but they
modify the original data and doing a lot of subsequent preserve, sort,
restore gets very slow very fast.

I have found this command extremely helpful when exploring big data.
Specially if a string is not clean, then having a look at the largest
values or the largest values that match a pattern is very helpful.

Examples
--------

```stata
. sysuse auto
. gtoplevelsof rep78
. gtoplevelsof rep78, missrow local(toplevels)
. gtoplevelsof rep78, colsep(", ")
. gtoplevelsof foreign rep78, ntop(3) missrow
```
