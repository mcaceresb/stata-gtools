gunique 
========

Efficiently calculate unique values of a variable or group of variables.

gunique is a faster alternative to unique. It reports the number of unique
values for the varlist. At the moment, its main difference from distinct is
that it always considers the variables jointly. It also has slighly different
options. For example, this supports the `by(varlist)` option that also appears
in the unique command, but does not support computing the number of unique
values for variables individually.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

```
gunique varlist [if] [in] [, detail]
```


Options
-------

- `by(varlist)` counts unique values within levels of _varlist_ and
            stores them in a new variable named **\_Unique**. The user
            can specify the name of the new variable via the option
            **generate(varname)**.

- `generate(varname)` supplies an alternative name for the new variable
            created by **by**.

- `replace` Replaces **\_Unique** (or the variable specified by **generate()**) 
            if it exists.

- `detail` request summary statistics on the number of records which are
            present for unique values of the varlist.

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

Stored results
--------------

gunique stores the following in r():

    Scalars

        r(nunique)    number of groups (last variable or joint)
        r(N)          number of non-missing observations
        r(J)          number of groups
        r(minJ)       largest group size
        r(maxJ)       smallest group size

Examples
--------

```stata
. sysuse auto, clear
(1978 Automobile Data)

. gunique *
N = 69; 69 balanced groups of size 1

. gunique *, miss
N = 74; 74 balanced groups of size 1

. gunique make-headroom
N = 69; 69 balanced groups of size 1

. gunique rep78, d

                          __000000
-------------------------------------------------------------
      Percentiles      Smallest
 1%            2              2
 5%            2              8
10%            2             11       Obs                   5
25%            8             18       Sum of Wgt.           5

50%           11                      Mean               13.8
                        Largest       Std. Dev.      10.73313
75%           18              8
90%           30             11       Variance          115.2
95%           30             18       Skewness       .5573459
99%           30             30       Kurtosis       2.113785

. gunique rep78, by(foreign)

'rep78' had 5 unique values in 69 observations.
Variable _Unique has the number of unique values of 'rep78' by 'foreign'.
The frequency counts of _Unique for the levels of 'foreign' are

   foreign   _Unique |    N  Cum   Pct (%)   Cum Pct (%) 
 --------------------------------------------------------
  Domestic         5 |   52   52        70            70 
   Foreign         3 |   22   74        30           100 
```
