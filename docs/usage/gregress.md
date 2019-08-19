gregress
========

Regressions by group with clustering and HDFE

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p><span class="codespan"><b><u>greg</u>ress</b> depvar indepvars [if] [in] [weight] [, by(varlist) options] </span></p>

By default, results are saved into a mata class object named
`GtoolsRegress`. Run `mata GtoolsRegress.desc()` for details; the name
and contents can be modified via `mata()`.  The results can also be
saved into variables via `gen()` or `prefix()` (either can be combined
with `mata()`, but not each other).

Note that extended varlist syntax is _**not**_ supported.

Options
-------

### Save Results

- `mata(name, [nob nose])` Specify name of output mata object and
            whether to save `b` and `se`

- `gen(...)` Specify any of `b(varlist)`, `se(varlist)`, and
            `hdfe(varlist)`. One per covariate is required (`hdfe()`
            also requires one for the dependent variable).

- `prefix(...)` Specify any of `b(str)`, `se(str)`, and `hdfe(str)`. A
            single prefix is allowed.

- `replace` Allow replacing existing variables.

### Options

- `by(varname)` Group statistics by variable.
- `robust` Robust SE.
- `cluster(varlist)` One-way or nested cluster SE.
- `absorb(varlist)` Multi-way high-dimensional fixed effects.
- `hdfetol(real)` Tolerance level for HDFE algoritm (default 1e-8).
- `noconstant` Whether to add a constant (cannot be combined with `absorb()`).

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

Remarks
-------

`gregress` runs a simple OLS regression, optionally by group, with
cluster SE, and/or with multi-way high-dimensional fixed effects. The
results are by default saved into a mata object (default `GtoolsRegress`).
Run `mata GtoolsRegress.desc()` for details; the following data is stored:

```
regression info
---------------

    real scalar kx
        number of (non-absorbed) covariates

    real scalar cons
        whether a constant was added automagically

    real scalar saveb
        whether b was stored

    real matrix b
        J by kx matrix with regression coefficients

    real scalar savese
        whether se was stored

    real matrix se
        J by kx matrix with corresponding standard errors

    string scalar setype
        type of SE computed (homoskedastic, robust, or cluster)

    real scalar absorb
        whether any FE were absorbed

    string colvector absorbvars
        variables absorbed as fixed effects

    string colvector clustervars
        cluster variables

    real scalar by
        whether there were any grouping variables

    string rowvector byvars
        grouping variable names

    real scalar J
        number of levels defined by grouping variables

    class GtoolsByLevels ByLevels
        grouping variable levels; see GtoolsRegress.ByLevels.desc() for details

variable levels (empty if without -by()-)
-----------------------------------------

    real scalar ByLevels.anyvars
        1: any by variables; 0: no by variables

    real scalar ByLevels.anychar
        1: any string by variables; 0: all numeric by variables

    string rowvector ByLevels.byvars
        by variable names

    real scalar ByLevels.kby
        number of by variables

    real scalar ByLevels.rowbytes
        number of bytes in one row of the internal by variable matrix

    real scalar ByLevels.J
        number of levels

    real matrix ByLevels.numx
        numeric by variables

    string matrix ByLevels.charx
        string by variables

    real scalar ByLevels.knum
        number of numeric by variables

    real scalar ByLevels.kchar
        number of string by variables

    real rowvector ByLevels.lens
        > 0: length of string by variables; <= 0: internal code for numeric variables

    real rowvector ByLevels.map
        map from index to numx and charx
```

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gregress.do)

### Showcase

``stata
sysuse auto, clear
gregress price mpg
gregress price mpg, by(foreign) robust
gregress price mpg, absorb(headroom) 
gregress price mpg, cluster(headroom) 
greg price mpg, by(foreign) absorb(rep78 headroom) cluster(headroom) 

greg price mpg, mata(coefsOnly, nose)
greg price mpg, mata(seOnly,    nob)
greg price mpg, mata(nothing,   nob nose)

greg price mpg, prefix(b(_b_)) replace
greg price mpg, prefix(se(_se_)) replace
greg price mpg, absorb(rep78 headroom) prefix(b(_b_) se(_se_) hdfe(_hdfe_))
drop _*

greg price mpg, gen(b(_b_mpg _b_cons))
greg price mpg, gen(se(_se_mpg _se_cons))
greg price mpg, absorb(rep78 headroom) gen(hdfe(_hdfe_mpg _hdfe_cons))
```

### Basic benchmark

``stata
clear
timer clear
local N 1000000
local G 10000
set obs `N'
gen g1 = int(runiform() * `G')
gen g2 = int(runiform() * `G')
gen g3 = int(runiform() * `G')
gen g4 = int(runiform() * `G')
gen x1 = runiform()
gen x2 = runiform()
gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + 20 * rnormal()

timer on 1
greg y x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.b', greg.se'
timer on 2
reghdfe y x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
greg y x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.b', greg.se'
timer on 4
reghdfe y x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 4

timer on 5
greg y x1 x2, by(g4) prefix(b(_b_))
timer off 5
drop _*
timer on 6
asreg y x1 x2, by(g4)
timer off 6
drop _*

timer list

   1:      1.14 /        1 =       1.1370
   2:     13.33 /        1 =      13.3340
   3:      1.27 /        1 =       1.2730
   4:     14.56 /        1 =      14.5630
   5:      0.26 /        1 =       0.2610
   6:      1.92 /        1 =       1.9160
```
