hashsort
--------

sort and gsort using hashes and C-plugins


!!! Warning "Caveats"
    While hashsort should always be faster than gsort, it might not
    always be faster than regular sort. In testing, hashsort was always
    faster in Stata/IC but not always in Stata/MP. If there are lots of
    duplicates then hashsort might be faster; if the sort variables are
    unique then hashsort will probably be slower.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p><span class="codespan"><b>hashsort</b> [+|-] varname [[+|-] varname ...] [, <a href="#options">options</a> ] </p>

Description
-----------

hashsort uses C-plugins to implement a hash-based sort that is always
faster than sort for sorting groups and faster than gsort in general.
hashsort hashes the data and sorts the hash, and then it sorts one
observation per group. The fewer the number of gorups relative to the
number of observations, the larger the speed gain.

If the sort is expected to be unique or if the number of groups is large,
then this comes at a potentially large memory penalty and it may not be
faster than sort (the exception is when the sorting variables are all
integers).

Each varname can be numeric or a string. The observations are placed in
ascending order of varname if + or nothing is typed in front of the name
and are placed in descending order if - is typed. hashsort always
produces a stable sort.

Options
-------

- `generate(varname)` or `gen(varname)`  Store group ID in generate.

- `sortgen` Set data sortby variable to `generate`.

- `replace` If `generate` exits, it is replaced.

- `skipcheck` Skip internal is sorted check.

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

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/hashsort.do)

```stata
. sysuse auto, clear
. hashsort price
. hashsort +price
. hashsort rep78 -price
. hashsort make
. hashsort foreign -make
```

One thing that is useful is that hashsort can encode a set of variables and
set the encoded variable as the sorting variable:

```stata
. sysuse auto, clear
(1978 Automobile Data)

. hashsort foreign -rep78, gen(id) sortgen
(note: missing values will be sorted last)

. disp "`: sortedby'"
id

. tab id

         id |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |          4        5.41        5.41
          2 |          2        2.70        8.11
          3 |          9       12.16       20.27
          4 |         27       36.49       56.76
          5 |          8       10.81       67.57
          6 |          2        2.70       70.27
          7 |          1        1.35       71.62
          8 |          9       12.16       83.78
          9 |          9       12.16       95.95
         10 |          3        4.05      100.00
------------+-----------------------------------
      Total |         74      100.00
```
