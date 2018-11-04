gduplicates
===========

Efficiently report, tag, or drop duplicate observations using C plugins.
This is a faster alternative to duplicates. It can replicate every
sub-command of duplicates; that is, it reports, displays, lists, tags,
or drops duplicate observations, depending on the subcommand. Duplicates
are observations with identical values either on all variables if no
_varlist_ is specified or on a specified _varlist_.

Note that for sub-commands `examples` and `list` the output is _**NOT**_
sorted by default. To mimic duplicates entirely, pass option `sorted`
when using those sub-commands.

_Important:_ Please run `gtools, upgrade` to update `gtools` to the latest
stable version.  _Windows users:_ If the plugin fails to load, please run
`gtools, dependencies` at the start of your Stata session.

Syntax
------

Any observations that do not satisfy specified if and/or in conditions
are ignored when you use report, examples, list, or drop. The variable
created by tag will have missing values for such observations.

Further, option `sorted` is required to fully mimic duplicates examples
and duplicates list; otherwise, gduplicates will not sort the list of
examples or the full list of duplicates. This default behavior improves
performance but may be harder to read.

_**Report**_ duplicates

```stata
gduplicates report [varlist] [if] [in]
```

Print a table showing observations that occur as one or more copies
and indicating how many observations are "surplus" in the sense that
they are the second (third, ...) copy of the first of each group of
duplicates.

_**List one example**_ for each group of duplicates

```stata
gduplicates examples [varlist] [if] [in] [, sorted options]
```

List one example for each group of duplicated observations. Each example
represents the first occurrence of each group in the dataset.

_**List all**_ duplicates

```stata
gduplicates list [varlist] [if] [in] [, sorted options]
```

List all duplicated observations.

_**Tag**_ duplicates

```stata
gduplicates tag [varlist] [if] [in] , generate(newvar)
```

Generate a variable representing the number of duplicates for each
observation. This will be 0 for all unique observations.

_**Drop**_ duplicates

```stata
gduplicates drop [if] [in]

gduplicates drop varlist [if] [in] , force
```

Drop all but the first occurrence of each group of duplicated
observations. The word drop may not be abbreviated.

Options
-------

Unlike other `gtools` commands, `gdistinct` extra arguments are
captured. See `help list` for the full options available with examples
and list (both call the list command internally).
 
To pass `gtools` options use `gtools(str)`.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gduplicates.do);
however, note this merely mimics the examples in `help duplicates`.

```stata
sysuse auto
keep make price mpg rep78 foreign
expand 2 in 1/2
```

Report duplicates
```
gduplicates report

Duplicates in terms of all variables

--------------------------------------
   copies | observations       surplus
----------+---------------------------
        1 |           72             0
        2 |            4             2
--------------------------------------
```
List one example for each group of duplicated observations

```
sort mpg
gduplicates examples

Duplicates in terms of all variables

  +----------------------------------------------------------------------+
  | group:   #   e.g. obs   make          price   mpg   rep78    foreign |
  |----------------------------------------------------------------------|
  |      2   2          2   AMC Pacer     4,749    17       3   Domestic |
  |      1   2          1   AMC Concord   4,099    22       3   Domestic |
  +----------------------------------------------------------------------+
WARNING: examples left unsorted to improve performance; use option sort to mimic duplicates
```

```stata
gduplicates examples, sorted

Duplicates in terms of all variables

  +----------------------------------------------------------------------+
  | group:   #   e.g. obs   make          price   mpg   rep78    foreign |
  |----------------------------------------------------------------------|
  |      1   2          1   AMC Concord   4,099    22       3   Domestic |
  |      2   2          2   AMC Pacer     4,749    17       3   Domestic |
  +----------------------------------------------------------------------+
```

List all duplicated observations

```stata
gduplicates list

Duplicates in terms of all variables

  +--------------------------------------------------------------+
  | group:   obs:   make          price   mpg   rep78    foreign |
  |--------------------------------------------------------------|
  |      2     18   AMC Pacer     4,749    17       3   Domestic |
  |      2     19   AMC Pacer     4,749    17       3   Domestic |
  |      1     45   AMC Concord   4,099    22       3   Domestic |
  |      1     50   AMC Concord   4,099    22       3   Domestic |
  +--------------------------------------------------------------+
WARNING: list left unsorted to improve performance; use option sort to mimic duplicates
```

Create variable dup containing the number of duplicates (0 if
observation is unique)
```stata
gduplicates tag, generate(dup)
```

List the duplicated observations
```stata
list if dup == 1

     +----------------------------------------------------+
     | make          price   mpg   rep78    foreign   dup |
     |----------------------------------------------------|
 18. | AMC Pacer     4,749    17       3   Domestic     1 |
 19. | AMC Pacer     4,749    17       3   Domestic     1 |
 45. | AMC Concord   4,099    22       3   Domestic     1 |
 50. | AMC Concord   4,099    22       3   Domestic     1 |
     +----------------------------------------------------+
```

Drop all but the first occurrence of each group of duplicated
observations
```stata
gduplicates drop

Duplicates in terms of all variables

(2 observations deleted)
```

List all duplicated observations
```stata
gduplicates list

Duplicates in terms of all variables

(0 observations are duplicates)
```
