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

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

This is a fast option to the user command distinct, additionally storing
the results in a matrix.

<p>
<span class="codespan"><b>gdistinct</b> [varlist] [if] [in] [, ///</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp; missing abbrev(#) joint minimum(#) maximum(#) ]</span>
</p>

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

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gdistinct.do)

gdistinct can function as a drop-in replacement for distinct.

```stata
. sysuse auto, clear
. gdistinct

              |        Observations
              |      total   distinct
--------------+----------------------
         make |        74        74
        price |        74        74
          mpg |        74        21
        rep78 |        69         5
     headroom |        74         8
        trunk |        74        18
       weight |        74        64
       length |        74        47
         turn |        74        18
 displacement |        74        31
   gear_ratio |        74        36
      foreign |        74         2

. matrix list r(distinct)

r(distinct)[12,2]
                     N  Distinct
        make        74        74
       price        74        74
         mpg        74        21
       rep78        69         5
    headroom        74         8
       trunk        74        18
      weight        74        64
      length        74        47
        turn        74        18
displacement        74        31
  gear_ratio        74        36
     foreign        74         2
   
. gdistinct, max(10)

              |        Observations
              |      total   distinct
--------------+----------------------
        rep78 |        69         5
     headroom |        74         8
      foreign |        74         2

. gdistinct make-headroom

          |        Observations
          |      total   distinct
----------+----------------------
     make |        74        74
    price |        74        74
      mpg |        74        21
    rep78 |        69         5
 headroom |        74         8

. gdistinct make-headroom, missing abbrev(6)

        |        Observations
        |      total   distinct
--------+----------------------
   make |        74        74
  price |        74        74
    mpg |        74        21
  rep78 |        74         6
 head~m |        74         8

. gdistinct foreign rep78, joint

        Observations
      total   distinct
         69          8

. gdistinct foreign rep78, joint missing

        Observations
      total   distinct
         74         10
```

Acknowledgements
----------------

`gdistinct` was written to mimic the community-contributed command `distinct`, the latter written by

- Gary Longton, Fred Hutchinson Cancer Research Center, USA. [glongton@fhcrc.org](mailto:glongton@fhcrc.org)

- Nicholas J. Cox, Durham University, UK. [n.j.cox@durham.ac.uk](mailto:n.j.cox@durham.ac.uk)
