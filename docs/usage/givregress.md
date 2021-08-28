Instrumental Variables Regression (2SLS)
========================================

2SLS IV regressions by group with weights, clustering, and HDFE

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

!!! Warning "Warning"
    `givregress` is in beta and meant for testing; use in production _**NOT**_ recommended. (To enable beta features, define `global GTOOLS_BETA = 1`.)

`givregress` computes fast IV regression coefficients and standard
errors by group. Its basic functionality is similar to that of the
user-written `rangestat (reg)` or `regressby`, except that it computes
2SLS instead of OLS; in addition, `givregress` allows weights,
clustering, and HDFE by group.  This program is _**not**_ intended as a
substitute for `ivregress`, `ivreghdfe`, or similar commands.  Support
for some estimation operations are planned; however, `givregress` does
not compute any significance tests and no post-estimation commands are
available.

Syntax
------

<p><span class="codespan"><b>givregress</b> depvar (endogenous = instruments) [exogenous]  ///</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp; [if] [in] [weight] [, by() absorb() <span style="font-style:italic;">options</span>] </span></p>

By default, results are saved into a mata class object named
`GtoolsIV`. Run `mata GtoolsIV.desc()` for details; the name
and contents can be modified via `mata()`.  The results can also be
saved into variables via `gen()` or `prefix()` (either can be combined
with `mata()`, but not each other).

Note that extended varlist syntax is _**not**_ supported. Further,
`fweights` behave differently than other weighting schemes; that
is, this assumes that the weight referes to the number of available
_observations_.

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

- `by(varlist)` Group statistics by variable.
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

Results
-------

`givregress` estimates a linear IV model via 2SLS, optionally weighted,
by group, with cluster SE, and/or with multi-way high-dimensional fixed
effects.  The results are by default saved into a mata object (default
`GtoolsIV`).  Run `mata GtoolsIV.desc()` for details; the following data
is stored:

```
regression info
---------------

    string scalar caller
        model used; should be "givregress"

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
        grouping variable levels; see GtoolsIV.ByLevels.desc() for details

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

Methods and Formulas
--------------------

IV is computed using via 2SLS in a two-step process. Let

- $Y$ be the dependent variable.

- $X$ be a matrix with endogenous covariates _and_ exogenous covariates.

- $Z$ be a matrix with exogenous covariates _and_ instruments.

Note that the exogenous covariates that appear in $X$ and $Z$ are the
same.  Now we project $X$ onto $Z$ to obtain $\widehat{X}$ and then we
project $Y$ onto $\widehat{X}$ to obtain the coefficients. In particular
$$
\begin{align}
    \widehat{\Gamma} & = (Z^\prime Z)^{-1} Z^\prime X \\\\
    \widehat{X}      & = Z \widehat{\Gamma}
\end{align}
$$

We then essentially run OLS on $Y$ and $\widehat{X}$:
$$
\widehat{\beta} = \left(\widehat{X}^\prime \widehat{X}\right)^{-1} \widehat{X}^\prime Y
$$

A column of ones is automatically appended to the exogenous covariates
(both in $X$ and $Z$) unless the option `noconstant` is passed or
`absorb(varlist)` is requested.

### Identification, Collinearity, and Inverses

`givregress` is not here to judge you. Whether your instrument is good,
bad, or anything in between does not matter for the algorithm so long as
the steps required for 2SLS can be run. As such, the only sanity check
is a basic identification criterion: The number of instruments must be
weakly greater than the number of endogenous (instrumented) covariates.
(This is an important difference from, for example `ivregress 2sls`, which
will also exit with error if the dependent variable is collinear with
any other variable.)

Let $C$ be a matrix with endogenous covariates, exogenous covariates,
_and_ instruments.  $C^\prime C$ is scaled by the inverse of $M =
\max_{ij} C^\prime C$ and subsequently decomposed into $L D L^\prime$,
with $L$ lower triangular and $D$ diagonal (note $C^\prime C$ is a
symmetric positive semi-definite matrix). If $D_{ii}$ is numerically
zero then the $i$th column is flagged as collinear and subsequently
excluded from all computations (specifically if $D_{ii} < k \cdot
2.22\mathrm{e}{-16}$, where $k$ is the number of columns in $C$ and
$2.22\mathrm{e}{-16}$ is the machine epsilon in 64-bit systems).

We then run 2SLS as described in the previous section using _only_
the variables that are determined to be linearly independent using
this method. The identification check is also conducted _after_
the collinearity check. If the model is not identified after
collinear variables have been removed then both the coefficient
and the standard errors are set to missing (`.`).

Note that variables columns that appear earlier in the matrix $C$
are favored to be kept in the collienarity check. For example, if an
instrument is collinear with an exogenous variable, the exogenous
variable will be kept and the instrument will be dropped. As noted,
the order in which variables appear in $C$ is: Endogenous, exogenous,
instruments. Hence instrumented variables are only dropped if they are
collinear with other instrumented variables; instruments, however, are
dropped if they are collinear with any other variable.

The coefficients for collinear columns are coded as $0$ and their
standard errors are coded as missing (`.`). Finally, inverses in
each step are computed directly, since the collinearity check is
conducted at the start and the 2SLS computation is conducted only on
linearly independent columns. (Though note the program will still
print a warning if the determinant is numerically zero, that is, $<
2.22\mathrm{e}{-16}$.)

### Standard Errors

The standard error of the $i$th coefficient is given by
$$
SE_i = \sqrt{\frac{n}{n - k} \widehat{V}_{ii}}
$$

where $n$ is the number of observations, $k$ is the number of covariates
(both endogenous and exogenous), and $\frac{n}{n - k}$ is a small-sample
adjustment and $n \widehat{V}$ is a consistent estimator of the
asymptotic variance of $\widehat{\beta}$. (Note that `givregress` always
computes this small-sample adjustment; Stata's `ivregress 2sls`, for
example, only does so with the option `small`.)  The standard error of
collinear columns is coded as missing (`.`).

By default, homoskedasticity-consistent standard errors are computed:
$$
\begin{align}
  \widehat{V}      & = (\widehat{X}^\prime \widehat{X})^{-1} \widehat{\sigma} \\\\
  \widehat{\sigma} & = \widehat{\varepsilon}^\prime \widehat{\varepsilon} / n
\end{align}
$$

where
$$
\widehat{\varepsilon} = Y - X \widehat{\beta}
$$

is the error of the 2SLS fit (note that $X$ is used here
instead of $\widehat{X}$). If `robust` is passed then White
heteroskedascitity-consistent standard errors are computed instead:
$$
\begin{align}
  \widehat{\Sigma} & = \text{diag}\\{\widehat{\varepsilon}_1^2, \ldots, \widehat{\varepsilon}_n^2\\} \\\\
  \widehat{V}      & =
    (\widehat{X}^\prime \widehat{X})^{-1}
    \widehat{X}^\prime \widehat{\Sigma} \widehat{X}
    (\widehat{X}^\prime \widehat{X})^{-1}
\end{align}
$$

### Clustering

If `cluster(varlist)` is passed then nested cluster standard errors are
computed (i.e. the rows of `varlist` define the groups). Let $j$ denote
the $j$th group defined by `varlist` and $J$ the number of groups. Then
$$
\begin{align}
  \widehat{V} & =
  (\widehat{X}^\prime \widehat{X})^{-1}
  \left(
    \sum_{j = 1}^J \widehat{u}_j \widehat{u}_j^\prime
  \right)
  (\widehat{X}^\prime \widehat{X})^{-1}
  \\\\
    \widehat{u}_j & = \widehat{X}_j^\prime \widehat{\varepsilon}_j
\end{align}
$$

with $\widehat{X}_j^\prime$ the matrix of projected covariates with
observations from the $j$th group and $\widehat{\varepsilon}_j$ the
vector with errors from the $j$th group. (Note another way to write the
sum in $\widehat{V}$ is as $U^\prime U$, with $U^\prime = [u_1 ~~ \cdots
~~ u_J]$.) Finally, the standard error is given by

$$
SE_i = \sqrt{\frac{n - 1}{n - k} \frac{J}{J - 1} \widehat{V}_{ii}}
$$

### Weights

Let $w$ denote the weighting variable and $w_i$ the weight assigned to
the $i$th observation. 
$$
\begin{align}
    \widehat{X} & = Z (Z^\prime W Z)^{-1} Z^\prime W X \\\\
    \widehat{\beta} & = \left(\widehat{X}^\prime W \widehat{X}\right)^{-1} \widehat{X}^\prime W Y
\end{align}
$$

`fweights` runs the regression as if there had been $w_i$ copies of the
$i$th observation. As such, $n_w = \sum_{i = 1}^n w_i$ is used instead
of $n$ to compute the small-sample adjustment for the standard errors,
and
$$
\begin{align}
  W & = \text{diag}\\{w_1, \ldots, w_n\\} \\\\
  \widehat{V} & =
    (\widehat{X}^\prime W \widehat{X})^{-1}
    \widehat{X}^\prime W \widehat{\Sigma} \widehat{X}
    (\widehat{X}^\prime W \widehat{X})^{-1}
\end{align}
$$

is used for robust standard errors. In contrast, for other weights
(`aweights` being the default), $n$ is used to compute the small-sample
adjustment, and $n \widehat{V}$ estimates the asymptotic variance of the
WLS estimator. That is,
$$
\begin{align}
  \widehat{V} & =
    (\widehat{X}^\prime W \widehat{X})^{-1}
    \widehat{X}^\prime W \widehat{\Sigma} W \widehat{X}
    (\widehat{X}^\prime W \widehat{X})^{-1}
\end{align}
$$

With clustering, these two methods of computing $\widehat{V}$ will
actually coincide, and the only difference between `fweights` and other
weights will be the way the small-sample adjustment is computed.

Finally, with weights and HDFE, the iterative de-meaning (see below)
uses the weighted mean.

### HDFE

Multi-way high-dimensional fixed effects can be added to any regression
via `absorb(varlist)`. That is, coefficients are computed as if the
levels of each variable in `varlist` had been added to the regression
as fixed effects. It is well-known that with one fixed effect
$\widehat{\beta}$ can be estimated via the within transformation (i.e.
de-meaning the dependent variable and each covariate by the levels of
the fixed effect; this can also be motivated via the Frisch-Waugh-Lovell
theorem). That is, with one fixed effect we have the following algorithm:

1. Compute $\overline{Y}$ and $\overline{C}$, the mean of $Y$ and
   $C$ by the levels of the fixed effect (recall $C$ is a matrix with
   all the variables: endogenous, exogenous, _and_ instruments).

2. Replace $Y$ and $C$ with $Y - \overline{Y}$ and $C - \overline{C}$,
   respectively.

3. Compute 2SLS normally with $Y$ and $C$ de-meaned, making sure to
   include the number of fixed effects in the small-sample adjustment
   of the standard errors.

With multiple fixed effects, the same can be achieved by continuously
de-meaning by the levels of each of the fixed effects.  Following
[Correia (2017, p. 12)](http://scorreia.com/research/hdfe.pdf), we have
instead:

1. Let $\alpha_m$ denote the $m$th fixed effect, $M$ the number of
   fixed effects (i.e. the number of variables to include as fixed
   effects), and $m = 1$.

2. Compute $\overline{Y}$ and $\overline{C}$ with the mean of $Y$ and
   $C$ by the levels of $\alpha_m$ (again, $C$ is a matrix with
   all the variables: endogenous, exogenous, _and_ instruments).

3. Replace $Y$ and $C$ with $Y - \overline{Y}$ and $C - \overline{C}$,
   respectively.

4. Repeat steps 2 and 3 for $m = 1$ through $M$.

5. Repeat steps 1 through 4 until convergence, that is, until neither
   $Y$ nor $X$ change across iterations.

6. Compute 2SLS normally with the iteratively de-meaned $Y$ and $X$,
   making sure to include the number of fixed effects across
   all fixed effect variables in the small-sample adjustment of the
   standard errors.

This is known as the Method of Alternating Projections (MAP). Let $A_m$
be a matrix with dummy variables corresponding to each of the levels
of $\alpha_m$, the $m$th fixed effect. MAP is so named because at each
step, $Y$ and $C$ are projected into the null space of $A_m$ for $m =
1$ through $M$. (In particular, with $Q_m = I - A_m (A_m^\prime A_m)^{-1}
A_m^\prime$ the orthogonal projection matrix, steps 2 and 3 replace $Y$
and $C$ with $Q_m Y$ and $Q_m C$, respectively.)

[Correia (2017)](http://scorreia.com/research/hdfe.pdf) actually
proposes several ways of accelerating the above algorithm; we have
yet to explore any of his proposed modifications (see Correia's own
`reghdfe` and `ivreghdfe` packages for an implementation of the methods
discussed in his paper).

Finally, we note that in step 5 we detect "convergence" as the
maximum element-wise absolute difference between $Y, C$ and $Q_m
Y, Q_m C$, respectively (i.e. the $l_{\infty}$ norm). This is
a tighter tolerance criterion than the one in [Correia (2017,
p. 12)](http://scorreia.com/research/hdfe.pdf), which uses the $l_2$
norm, but by default we also use a tolerance of $1\mathrm{e}{-8}$. The
trade-off is precision vs speed.  The tolerance criterion is hard-coded
but the level can be modified via `hdfetol()`. A smaller tolerance will
converge faster but the point estimates will be less precise (and the
collinearity detection algorithm will be more susceptible to failure).

### Technical Notes

Ideally I would have been keen to use a standard linear algebra library
available for C. However, I was unable to find one that I could include
as part of the plugin without running into cross-platform compatibility
or installation issues (specifically I was unable to compile them on
Windows or OSX; I do not have access to physical hardware running either
OS, so adding external libraries is challenging). Hence I had to code
all the linear algebra commands that I wished to use.

As far as I can tell, this is only noticeable when it comes to matrix
multiplication. I use a [naive algorithm](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm#Iterative_algorithm)
with no optimizations. This is the main bottleneck in regression models
with multiple covariates. Suggestions on how to improve [this algorithm](https://github.com/mcaceresb/stata-gtools/blob/master/src/plugin/regress/linalg/colmajor.c#L1-L41) are welcome.

Missing Features
----------------

This software will remain in beta at least until the following are added:

- Option to iteratively remove singleton groups with HDFE (see [Correia (2015)
  for notes on this issue](http://scorreia.com/research/singletons.pdf))

- Automatically detect and remove collinear groups with multi-way HDFE.
  (This is specially important for small-sample standard error adjustment.)

In addition, some important features are missing:

- Option to estimate the fixed effects (i.e. the coefficients of each
  HDFE group) included in the regression.

- Option to estimate standard errors under multi-way clustering.

- Faster HDFE algorithm. At the moment the method of alternating
  projections (MAP) is used, which has very poor worst-case performance.
  While `givregress` is fast in our benchmarks, it does not have
  any safeguards against potential corner cases.  ([See Correia
  (2017) for notes on this issue](http://scorreia.com/research/hdfe.pdf).)

- Support for Stata's extended `varlist` syntax.

Examples
--------

Note `gregress` is in beta. To enable enable beta features, define `global GTOOLS_BETA = 1`.

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/givregress.do)

### Showcase

```stata
sysuse auto, clear
gen _mpg  = mpg
qui tab headroom, gen(_h)

givregress price (mpg = gear_ratio) weight turn
givregress price (mpg = gear_ratio) _mpg, cluster(headroom)
mata GtoolsIV.print()

givregress price (mpg weight = gear_ratio turn displacement) _h*, absorb(rep78 headroom)
mata GtoolsIV.print()

givregress price (mpg = gear_ratio) weight [fw = rep78], absorb(headroom)
mata GtoolsIV.print()

givregress price (mpg = gear_ratio turn displacement) weight [aw = rep78], by(foreign)
mata GtoolsIV.print()

givregress price (mpg = gear_ratio turn) weight, by(foreign) mata(coefsOnly, nose) prefix(b(_b_) se(_se_))
givregress price (mpg weight = gear_ratio turn), mata(seOnly, nob) prefix(hdfe(_hdfe_))
givregress price (mpg weight = gear_ratio turn) displacement, mata(nothing, nob nose)

mata coefsOnly.print()
mata seOnly.print()
mata nothing.print()
```

```stata
clear
local N 1000000
local G 10000
set obs `N'
gen g1 = int(runiform() * `G')
gen g2 = int(runiform() * `G')
gen g3 = int(runiform() * `G')
gen g4 = int(runiform() * `G')
gen x3 = runiform()
gen x4 = runiform()
gen x1 = x3 + runiform()
gen x2 = x4 + runiform()
gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + g4 + 20 * rnormal()

timer on 1
givregress y (x1 x2 = x3 x4), absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.b', greg.se'
timer on 2
ivreghdfe y (x1 x2 = x3 x4), absorb(g1 g2 g3)
timer off 2

timer on 3
givregress y (x1 x2 = x3 x4), absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.b', greg.se'
timer on 4
ivreghdfe y (x1 x2 = x3 x4), absorb(g1 g2 g3) cluster(g4)
timer off 4

timer list

   1:      2.44 /        1 =       2.4430
   2:     18.39 /        1 =      18.3870
   3:      2.44 /        1 =       2.4370
   4:     25.51 /        1 =      25.5070
```

References
----------

Correia, Sergio. 2015. "Singletons, Cluster-Robust Standard Errors and Fixed Effects: A Bad Mix" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/singletons.pdf](http://scorreia.com/research/singletons.pdf)

Correia, Sergio. 2017. "Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/hdfe.pdf](http://scorreia.com/research/hdfe.pdf)
