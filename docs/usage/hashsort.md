hashsort
--------

sort and gsort using hashes and C-plugins

_**Important:**_ Hashsort does not afford speed improvements over sort
for Stata/MP users. Hence it is considered an experimental command, even
though it is typically faster than gsort even in Stata/MP.

_Note for Windows users:_ It may be necessary to run gtools, dependencies at
the start of your Stata session.


Syntax
------

<p><span style="font-family:monospace">gcontract [+|-] varname [[+|-] varname ...] [, <a href="#options">options</a> ] </p>

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

- `gen(varname)` Store sort oder in gen.

- `group(varname)` Store group ID in group.

- `sortgroup` Set data sortby variable to group.

- `replace` If group exits, it is replaced.

- `skipcheck` Skip internal is sorted check.

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

. hashsort foreign -make, group(id) sortgroup
(note: missing values will be sorted last)

. disp "`: sortedby'"
id
```
