gdistinct
=========

Efficiently report number(s) of distinct observations or values.

gdistinct is a faster alternative to distinct.  It displays the number of
distinct observations with respect to the variables in varlist.  By
default, each variable is considered separately (excluding missing
values) so that the number of distinct observations for each variable is
reported and in this case the results are stored in a matrix.

The number of distinct observations is the same as the number of distinct
values.  Optionally, variables can be considered jointly so that the
number of distinct groups defined by the values of variables in varlist
is reported.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

This is a fast option to the user command distinct, additionally storing
the results in a matrix.

```stata
gdistinct [varlist] [if] [in] [, ///
    missing abbrev(#) joint minimum(#) maximum(#) ]
```


Options
-------

- `missing` specifies that missing values are to be included in counting
        distinct observations.

- `abbrev(#)` specifies that variable names are to be displayed abbreviated
        to at most # characters.  This option has no effect with joint.

- `joint` specifies that distinctness is to be determined jointly for the
        variables in varlist.

- `minimum(#)` specifies that numbers of distinct values are to be displayed
        only if they are equal to or greater than a specified minimum.

- `maximum(#)` specifies that numbers of distinct values are to be displayed
        only if they are less than or equal to a specified maximum.

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

gdistinct stores the following in r():

    Scalars

        r(ndistinct)    number of groups (last variable or joint)
        r(N)            number of non-missing observations
        r(J)            number of groups
        r(minJ)         largest group size
        r(maxJ)         smallest group size

    Matrices       

        r(ndistinct)    number of non-missing observations; one row
                          per variable (default) or per varlist (with
                          option joint)

Examples
--------

```stata
. sysuse auto
. gdistinct
. gdistinct, max(10)
. gdistinct make-headroom
. gdistinct make-headroom, missing abbrev(6)
. gdistinct foreign rep78, joint
. gdistinct foreign rep78, joint missing
```
