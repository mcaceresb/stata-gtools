gunique 
========

Efficiently calculate unique values of a variable or group of variables.

gunique is a faster alternative to unique. It reports the number of unique
values for the varlist. At the moment, its main difference from distinct
is that it always considers the variables jointly. It also has slighly
different options. A future release will include by(varlist) in order to
compute the number of rows of varlist by the groups specified in by. This
feature is not yeat available, however.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

```
gunique varlist [if] [in] [, detail]
```


Options
-------

- `detail` request summary statistics on the number of records which are
            present for unique values of the varlist.

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

Examples
--------

```
. sysuse auto
. gunique *
. gunique *, miss
. gunique make-headroom
. gunique make-headroom, d
```

Stored results
--------------

gunique stores the following in r():

    Scalars

        r(nunique)    number of groups (last variable or joint)
        r(N)          number of non-missing observations
        r(J)          number of groups
        r(minJ)       largest group size
        r(maxJ)       smallest group size
