gisid 
=====

Efficiently check for unique identifiers using C plugins.  This is a fast
option to Stata's isid. It checks whether a set of variables uniquely
identifies observations in a dataset. It can additionally take `if` and
`in` but it cannot check an external data set or sort the data.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.

Syntax
------

```
gisid varlist [if] [in] [, missok]
```

Options
-------

        missok indicates that missing values are permitted in varlist.

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

Examples
--------

```stata
. sysuse auto, clear
(1978 Automobile Data)

. gisid mpg
variable mpg does not uniquely identify the observations
r(459);

. gisid make

. replace make = "" in 1
(1 real change made)

. gisid make
variable make should never be missing
r(459);

. gisid make, missok
```

gisid can also take a range, that is
```
. gisid mpg in 1
. gisid mpg if _n == 1
```
