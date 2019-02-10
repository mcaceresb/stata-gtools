gcontract
=========

Efficiently make dataset of frequencies and percentages

gcontract replaces the dataset in memory with a new dataset consisting of
all combinations of varlist that exist in the data and a new variable
that contains the frequency of each combination. The user can optionally
request percentages and cumulative counts and percentages.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.


Syntax
------

This is a fast option to Stata's contract.

<p><span class="codespan"><b>gcontract</b> varlist [if] [in] [weight] [, <a href="#options">options</a> ]</span></p>

`fweight`s are allowed; see `help weights`. Further, instead of a
varlist, it is possible to specify

```stata
[+|-] varname [[+|-] varname ...]
```

This will not affect the results, but it will affect the sort order of
the final data.


Options
-------


- `freq(newvar)` specifies a name for the frequency variable.  If not
            specified, `_freq` is used.

- `cfreq(newvar)` specifies a name for the cumulative frequency variable.  If
            not specified, no cumulative frequency variable is created.

- `percent(newvar)` specifies a name for the percentage variable.  If not
            specified, no percent variable is created.

- `cpercent(newvar)` specifies a name for the cumulative percentage variable.
            If not specified, no cumulative percentage variable is created.

- `float` specifies that the percentage variables specified by percent() and
            cpercent() will be stored as variables of type float. This only
            affects the Stata storage type; gtools does all computations
            internally in double precision. If float is not specified, these
            variables will be generated as variables of type double.  All
            generated variables are compressed to the smallest storage type
            possible without loss of precision; see [D] compress.

- `format(format)` specifies a display format for the generated percentage
            variables specified by percent() and cpercent().  If format() is not
            specified, these variables will have the display format %8.2f.

- `zero` specifies that combinations with frequency zero be included.  This
            is VERY slow.

- `nomiss` specifies that observations with missing values on any variable in
            varlist be dropped.  If nomiss is not specified, all observations
            possible are used.

### Extras

- `fast` specifies that gcollapse not restore the original dataset should the
            user press Break.

- `unsorted` Do not sort resulting data set. Saves speed.

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

gcontract stores the following in r():

    r(N)       number of non-missing observations
    r(J)       number of groups
    r(minJ)    largest group size
    r(maxJ)    smallest group size

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gcontract.do)

The options here are essentially the same as Stata's contract,
save for the standard gtools options.

```stata
sysuse auto, clear
gen long id = _n * 1000
expand id
gcontract rep78, verbose
```
```
Bijection OK with all integers (i.e. no extended miss val)? Yes.
Counting sort on hash; min = 1, max = 6
N = 2,775,000; 6 unbalanced groups of sizes 88,000 to 833,000
```
```
l

     +----------------+
     | rep78    _freq |
     |----------------|
  1. |     1    88000 |
  2. |     2   211000 |
  3. |     3   833000 |
  4. |     4   824000 |
  5. |     5   649000 |
     |----------------|
  6. |     .   170000 |
     +----------------+
```

You can add frequencies, percentages, and so on:
```stata
sysuse auto, clear
gen long id = _n * 1000
expand id
gcontract rep78, freq(f) cfreq(cf) percent(p) cpercent(cp) bench
```
```
Added target variables; .161 seconds
Parsed by variables; .004 seconds
Plugin runtime; .28 seconds
Total runtime (internals); .285 seconds
```
```
l

     +-------------------------------------------+
     | rep78        f        cf       p       cp |
     |-------------------------------------------|
  1. |     1    88000     88000    3.17     3.17 |
  2. |     2   211000    299000    7.60    10.77 |
  3. |     3   833000   1132000   30.02    40.79 |
  4. |     4   824000   1956000   29.69    70.49 |
  5. |     5   649000   2605000   23.39    93.87 |
     |-------------------------------------------|
  6. |     .   170000   2775000    6.13   100.00 |
     +-------------------------------------------+
```

Last, with multiple variables you can "fill in" missing groups. This option
has not been implemented internally and as such is very slow:

```stata
sysuse auto, clear
gen long id = _n * 1000
expand id
gcontract foreign rep78, ///
    freq(f) cfreq(cf) percent(p) cpercent(cp) bench(3) zero
```
```
Added target variables; .137 seconds
Parsed by variables; .002 seconds
        Plugin step 1: Read in by variables; 0.116 seconds.
                Plugin step 2.1: Determined hashing strategy; 0.036 seconds.
                Plugin step 2.3: Bijected integers to natural numbers; 0.026 seconds.
                Plugin step 2.4: Sorted integer-only hash; 0.057 seconds.
        Plugin step 2: Hashed by variables; 0.120 seconds.
        Plugin step 3: Set up panel; 0.013 seconds.
                Plugin step 4.2: Keep only one row per group; 0.000 seconds.
        Plugin step 4: Created indexed array with sorted by vars; 0.003 seconds.
        Plugin step 5: Generated output array; 0.000 seconds.
        Plugin step 6: Copied collapsed data to stata; 0.000 seconds.
Plugin runtime; .262 seconds
Total runtime (internals); .265 seconds

l

     +------------------------------------------------------+
     | rep78    foreign        f        cf       p       cp |
     |------------------------------------------------------|
  1. |     1   Domestic    88000     88000    3.17     3.17 |
  2. |     2   Domestic   211000    299000    7.60    10.77 |
  3. |     3   Domestic   654000    953000   23.57    34.34 |
  4. |     4   Domestic   256000   1209000    9.23    43.57 |
  5. |     5   Domestic    63000   1272000    2.27    45.84 |
     |------------------------------------------------------|
  6. |     .   Domestic   106000   1378000    3.82    49.66 |
  7. |     1    Foreign        0   1378000    0.00    49.66 |
  8. |     2    Foreign        0   1378000    0.00    49.66 |
  9. |     3    Foreign   179000   1557000    6.45    56.11 |
 10. |     4    Foreign   568000   2125000   20.47    76.58 |
     |------------------------------------------------------|
 11. |     5    Foreign   586000   2711000   21.12    97.69 |
 12. |     .    Foreign    64000   2775000    2.31   100.00 |
     +------------------------------------------------------+
```

You will note a few levels have 0 frequency, which means they did
not appear in the full data.
