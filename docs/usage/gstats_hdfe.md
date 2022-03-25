Fixed Effects Absorption (HDFE)
===============================

Efficiently absorb fixed effects (i.e. residualize variables).

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

!!! Warning "Warning"
    `gstats hdfe` is in beta; see [missing features](#missing-features).
    (To enable beta, define `global GTOOLS_BETA = 1`.)

`gstats hdfe` (alias `gstats residualize`) provides a fast way of 
absorbing high-dimensional fixed effects (HDFE). It saves the number of levels
in each absorbed variable, accepts weights, and optionally takes `by()`
as an argument (in this case ancillary information is not saved by
default and must be accessed via `mata()`). Missing values in the
source and absorb variables are skipped row-size (the latter can be
optionally retained via `absorbmissing`).

Syntax
------

<p><span class="codespan"><b>gstats hdfe</b> varlist [if] [in] [, absorb() ///</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp; {gen() | prefix() | replace} <span style="font-style:italic;">options</span>] </span></p>

If none of `gen()`, `prefix()`, or `replace` are specified then `target=source` 
syntax must be supplied instead of `varlist`:

```stata
target_var=varname [target_var=varname ...]
```

(Note: `replace` may be combined by any generate options; `target=source` syntax
may be combined with `prefix()`.)

Options
-------

### Specify targets

- `prefix(str)` Generate all variables with specified prefix. For example,
            `x y, prefix(prefix_)` stores the results in `prefix_x`, `prefix_y`.
            Cannot be combined with `generate()`.

- `generate(newvarlist)` List of targets; must specify one per source.
            Cannot be combined with `prefix()`.

- `replace` Replace variables as applicable; i.e. it replaces targets if
          they already exist and it replaces sources of no target is
          specified. This may be combined with any target specification.

- `wildparse` Allow rename-style syntax if `target=source` is specified;
          for example, `x* = prefix_x*`.

### HDFE Options

- `by(varlist)` Group by variables. In this case the absorption is performed
            separately for each level defined by the `by()` variables.

- `matasave[(str)]` Save `by()` info (and absorb info by group) in mata
            object (default name is `GtoolsByLevels`)

- `absorbmissing` Treat missing absorb levels as a group instead of dropping them.

- `algorithm(str)` Algorithm used to absorb HDFE: SQUAREM (squared extrapolation;
            default), CG (conjugate gradient),  MAP (alternating
            projections), Hybrid (CG with SQUAREM fallback).

- `maxiter(int)` Maximum number of algorithm iterations (default
            100,000). Pass `.` for unlimited iterations.

- `tolerance(real)` Convergence tolerance (default 1e-8). Note the convergence
            criterion is `|X(k + 1) - X(k)| < tol` for the `k`th iteration, with
            `||` the sup norm (i.e. largest element). This is a tighter
            criteria than the squared norm and setting the tolerance too
            low might negatively impact performance or with some algorithms
            run into numerical precision problems.

### Gtools options

(Note: These are common to every gtools command.)

- `compress` Try to compress `by()` strL to str#. The Stata Plugin Interface has
            only limited support for strL variables. In Stata 13 and
            earlier (version 2.0) there is no support, and in Stata 14
            and later (version 3.0) there is read-only support. The user
            can try to compress `by()` strL variables using this option.

- `forcestrl` Skip binary `by()` variable check and force gtools to read strL variables
            (14 and above only). __Gtools gives incorrect results when there is
            binary data in `by()` strL variables__. This option was included because on
            some windows systems Stata detects binary data even when there is none.
            Only use this option if you are sure you do not have binary data in your
            strL variables.

- `verbose` prints some useful debugging info to the console.

- `benchmark` or `bench(level)` prints how long in seconds various parts of the
            program take to execute. Level 1 is the same as `benchmark`. Levels
            2 and 3 additionally prints benchmarks for internal plugin steps.

- `hashmethod(str)` Hash method to use for `by()` variable. `default` automagically
            chooses the algorithm. `biject` tries to biject the inputs into the
            natural numbers. `spooky` hashes the data and then uses the hash.

- `oncollision(str)` How to handle collisions in `by()` levels. A collision should
            never happen but just in case it does `gtools` will try to use native
            commands. The user can specify it throw an error instead by
            passing `oncollision(error)`.

Stored results
--------------

`gstats hdfe` stores the following in r():

    Macros         

      r(algorithm)   algorithm used for HDFE absorption

    Scalars        

      r(N)           number of non-missing observations
      r(J)           number of by() groups
      r(minJ)        largest by() group size
      r(maxJ)        smallest by() group size
      r(iter)        (without by()) iterations of absorption algorithm
      r(feval)       (without by()) function evaluations in absorption algorithm

    Matrices       

      r(nabsorb)     (without by()) vector with number of levels in each absorb variable

When `matasave[(str)]` is passed, the following data is stored in the
mata object (default name `GtoolsByLevels`):

```
    string matrix nj
        non-missing observations in each -by- group

    string matrix njabsorb
        number of absorbed levels in each -by- group by each absorb variable

    real scalar anynum
        1: any numeric by variables; 0: all string by variables

    real scalar anychar
        1: any string by variables; 0: all numeric by variables

    string rowvector byvars
        by variable names

    real scalar kby
        number of by variables

    real scalar rowbytes
        number of bytes in one row of the internal by variable matrix

    real scalar J
        number of levels

    real matrix numx
        numeric by variables

    string matrix charx
        string by variables

    real scalar knum
        number of numeric by variables

    real scalar kchar
        number of string by variables

    real rowvector lens
        > 0: length of string by variables; <= 0: internal code for numeric variables

    real rowvector map
        map from index to numx and charx

    real rowvector charpos
        position of kth character variable

    string matrix printed
        formatted (printf-ed) variable levels (not with option -silent-)
```

Remarks
-------

`gstats hdfe` (alias `gstats residualize`) is designed as a utility to
embed in programs that require absorbing high-dimensional fixed effects,
optionally taking in weights. The number of non-missing observations and
the number of levels in each absorb variable are returned (see
[stored results](#stored-results)).

Mainly as a side-effect of being a gtools program, `by()` is also
allowed. In this case, the fixed effects are absorbed sepparately for
each group defined by `by()`. Note in this case the number of non-missing
observations and the number of absorb levels varies by group.  This is
_**NOT**_ saved by default. The user can optionally specify `matasave[(str)]` to
save information on the by levels, including the number of non-missing
rows per level and the number of levels per absorb variable per level.

`matasave[(str)]` by default is stored in `GtoolsByLevels` but the user may
specify any name desired.  Run `mata GtoolsByLevels.desc()` for details on
the stored objects (also see [stored results](#stored-results) above).

Missing Features
----------------

- Check whether it's mathematically OK to apply SQUAREM. In general it's meant
  for contractions but my understanding is that it can be applied to any 
  monotonically convergent algorithm.

- Improve convergence criterion. Current criterion may not be sensible.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gstats_hdfe.do)

### Showcase

```stata
sysuse auto, clear
gstats hdfe demean_price = price, absorb(foreign)
gstats hdfe hdfe_price   = price, absorb(foreign rep78)
assert mi(hdfe_price) if mi(rep78)
gstats hdfe hdfe_price   = price, absorb(foreign rep78) replace absorbmissing
assert !mi(hdfe_price)

gstats hdfe price mpg [aw = rep78], by(foreign) absorb(rep78 headroom) gen(v1 v2) mata
mata GtoolsByLevels.desc()
mata GtoolsByLevels.nj
mata GtoolsByLevels.njabsorb

gstats hdfe price mpg, absorb(foreign rep78) prefix(res_)
gstats hdfe price mpg, absorb(foreign rep78) replace
assert price == res_price if !mi(rep78)
assert mpg   == res_mpg   if !mi(rep78)

gstats hdfe price mpg, absorb(foreign make) replace
assert abs(price) < 1e-8
assert abs(price) < 1e-8
```

### Sample Benchmarks

```stata
clear
local N 10000000
set obs `N'
gen g1 = int(runiform() * 10000)
gen g2 = int(runiform() * 100)
gen g3 = int(runiform() * 10)
gen x  = rnormal()

timer clear
timer on 1
gstats hdfe x1 = x, absorb(g1 g2 g3) algorithm(squarem) bench(2)
disp r(feval)
timer off 1

timer on 2
gstats hdfe x2 = x, absorb(g1 g2 g3) algorithm(cg) bench(2)
disp r(feval)
timer off 2

timer on 3
gstats hdfe x3 = x, absorb(g1 g2 g3) algorithm(map) bench(2)
disp r(feval)
timer off 3

timer on 4
* equivalent to cg
qui reghdfe x, absorb(g1 g2 g3) resid(x4) acceleration(cg)
timer off 4

timer on 5
* equivalent to map
qui reghdfe x, absorb(g1 g2 g3) resid(x5) acceleration(none)
timer off 5

assert reldif(x1, x2) < 1e-6
assert reldif(x1, x3) < 1e-6
assert reldif(x1, x4) < 1e-6
assert reldif(x1, x5) < 1e-6

timer list

    1:      5.07 /        1 =       5.0740
    2:     11.62 /        1 =      11.6160
    3:      4.81 /        1 =       4.8120
    4:     64.03 /        1 =      64.0290
    5:     44.51 /        1 =      44.5050
```

References
----------

The idea for this function is from Correia (2017). The conjugate
gradient algorithm is from Hernández-Ramos, Escalante, and Raydan
(2011). The SQUAREM algorithm is from Varadhan and Roland (2008) and
Varadhan (2016).

- Correia, Sergio. 2017. "Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/hdfe.pdf](http://scorreia.com/research/hdfe.pdf)

- Hernández-Ramos, Luis M., René Escalante, and Marcos Raydan. 2011. "Unconstrained Optimization Techniques for the Acceleration of Alternating Projection Methods." Numerical Functional Analysis and Optimization, 32(10): 1041–66.

- Varadhan, Ravi and Roland, Christophe. 2008. "Simple and Globally Convergent Methods for Accelerating the Convergence of Any EM Algorithm."" Scandinavian Journal of Statistics, 35(2): 335–353.

- Ravi Varadhan (2016). "SQUAREM: Squared Extrapolation Methods for Accelerating EM-Like Monotone Algorithms." R package version 2016.8-2. https://CRAN.R-project.org/package=SQUAREM
