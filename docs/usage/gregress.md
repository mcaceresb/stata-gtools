Linear Regression (OLS)
=======================

OLS linear regressions by group with weights, clustering, and HDFE

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

!!! Warning "Warning"
    `gregress` is in beta and meant for testing; use in production _**NOT**_ recommended. (To enable beta features, define `global GTOOLS_BETA = 1`.)

`gregress` computes fast OLS regression coefficients and standard errors
by group. Its basic functionality is similar to that of the user-written
`rangestat (reg)` or `regressby`; in addition, `gregress` allows weights,
clustering, and HDFE by group.

This program is _**not**_ intended as a substitute for `regress`,
`reghdfe`, or similar commands.  Support for some estimation operations
are planned; however, `gregress` does not compute any significance tests
and no post-estimation commands are available.  For non-grouped OLS, in
fact, Stata's `regress` is faster (unless clustering). For non-grouped
OLS with HDFE, `ftools`' `reghdfe` is more stable and offers more
features.

Syntax
------

<p><span class="codespan"><b><u>greg</u>ress</b> depvar indepvars [if] [in]  [weight] [, ///</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp; by() absorb() <span style="font-style:italic;">options</span>] </span></p>

By default, results are saved into a mata class object named
`GtoolsRegress`. Run `mata GtoolsRegress.desc()` for details; the name
and contents can be modified via `mata()`.  The results can also be
saved into variables via `gen()` or `prefix()` (either can be combined
with `mata()`, but not each other).

Extended varlist syntax is _**not**_ supported. Further, `fweights`
behave differently than other weighting schemes; specifically,
this assumes that the weight refers to the number of available
_observations_. Other weights run WLS; default weights are `aweights`.

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
- `alphas(varlist)` One per absorb variable; save FE (normalized to be mean zero).
- `savecons` Save implied constant in mata (with `absorb()`).
- `predict(varname)` Save linear fit.
- `resid(varname)` Save residuals.
- `hdfetol(real)` Tolerance level for HDFE algoritm (default 1e-8).
- `algorithm(str)` Algorithm used to absorb HDFE: CG (conjugate gradient; default)
            MAP (alternating projections), SQUAREM (squared extrapolation),
            IT (Irons and Tuck).
- `maxiter(int)` Maximum number of algorithm iterations (default
            100,000). Pass `.` for unlimited iterations.
- `tolerance(real)` Convergence tolerance (default 1e-8). Note the convergence
            criterion is `|X(k + 1) - X(k)| < tol` for the `k`th iteration, with
            `||` the sup norm (i.e. largest element). This is a tighter
            criteria than the squared norm and setting the tolerance too
            low might negatively impact performance or with some algorithms
            run into numerical precision problems.
- `traceiter` Trace algorithm iterations.
- `standardize` Standardize variables before algorithm (may be faster but
            is slighty less precise).
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

`gregress` estimates a linear regression model via OLS, optionally
weighted, by group, with cluster SE, and/or with multi-way
high-dimensional fixed effects.  The results are by default saved into a
mata object (default `GtoolsRegress`).  Run `mata GtoolsRegress.desc()`
for details; the following data is stored:

```
regression info
---------------

    string scalar caller
        model used; should be "gregress"

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

Methods and Formulas
--------------------

OLS is computed using the standard formla
$$
\widehat{\beta} = (X^\prime X)^{-1} X^\prime Y
$$

where $Y$ is the dependent variable and $X$ is a matrix with $n$
rows, one for each set of observations, and $k$ columns, one for each
covariate. A column of ones is automatically appended to $X$ unless the
option `noconstant` is passed or `absorb(varlist)` is requested.

### Collinearity and Inverse

$X^\prime X$ is scaled by the inverse of $M = \max_{ij} X^\prime
X$ and subsequently decomposed into $L D L^\prime$, with $L$ lower
triangular and $D$ diagonal (note $X^\prime X$ is a symmetric positive
semi-definite matrix). If $D_{ii}$ is numerically zero then the $i$th
column is flagged as collinear and subsequently excluded from all
computations (specifically if $D_{ii} < k \cdot 2.22\mathrm{e}{-16}$,
where $k$ is the number of columns in $X$ and $2.22\mathrm{e}{-16}$ is
the machine epsilon in 64-bit systems).

The inverse is then computed as $(L^{-1})^\prime D^{-1} L^{-1} M^{-1}$,
excluding the columns flagged as collinear. If the determinant of
$X^\prime X$ is numerically zero ($< 2.22\mathrm{e}{-16}$) despite
excluding collinear columns, a singularity warning is printed.
The coefficients for collinear columns are coded as $0$ and their
standard errors are coded as missing (`.`).

### Standard Errors

The standard error of the $i$th coefficient is given by
$$
SE_i = \sqrt{\frac{n}{n - k} \widehat{V}_{ii}}
$$

where $\frac{n}{n - k}$ is a small-sample adjustment and $n \widehat{V}$
is a consistent estimator of the asymptotic variance of $\widehat{\beta}$.
The standard error of collinear columns is coded as missing (`.`).

By default, homoskedasticity-consistent standard errors are computed:
$$
\begin{align}
  \widehat{V}      & = (X^\prime X)^{-1} \widehat{\sigma} \\\\
  \widehat{\sigma} & = \widehat{\varepsilon}^\prime \widehat{\varepsilon} / n
\end{align}
$$

where
$$
\widehat{\varepsilon} = Y - X \widehat{\beta}
$$

is the error of the OLS fit. If `robust` is passed then White
heteroskedascitity-consistent standard errors are computed instead:
$$
\begin{align}
  \widehat{\Sigma} & = \text{diag}\\{\widehat{\varepsilon}_1^2, \ldots, \widehat{\varepsilon}_n^2\\} \\\\
  \widehat{V}      & = (X^\prime X)^{-1} X^\prime \widehat{\Sigma} X (X^\prime X)^{-1}
\end{align}
$$

### Clustering

If `cluster(varlist)` is passed then nested cluster standard errors are
computed (i.e. the rows of `varlist` define the groups). Let $j$ denote
the $j$th group defined by `varlist` and $J$ the number of groups. Then
$$
\begin{align}
  \widehat{V} & =
  (X^\prime X)^{-1}
  \left(
    \sum_{j = 1}^J \widehat{u}_j \widehat{u}_j^\prime
  \right)
  (X^\prime X)^{-1}
  \\\\
    \widehat{u}_j & = X_j^\prime \widehat{\varepsilon}_j
\end{align}
$$

with $X_j^\prime$ the matrix of covariates with observations from the
$j$th group and $\widehat{\varepsilon}_j$ the vector with errors from
the $j$th group. (Note another way to write the sum in $\widehat{V}$ is
as $U^\prime U$, with $U^\prime = [u_1 ~~ \cdots ~~ u_J]$.) Finally, the
standard error is given by

$$
SE_i = \sqrt{\frac{n - 1}{n - k} \frac{J}{J - 1} \widehat{V}_{ii}}
$$

### Weights

Let $w$ denote the weighting variable and $w_i$ the weight assigned to
the $i$th observation. The weighted OLS estimator is
$$
\widehat{\beta} = (X^\prime W X)^{-1} X^\prime W Y
$$

`fweights` runs the regression as if there had been $w_i$ copies of the
$i$th observation. As such, $n_w = \sum_{i = 1}^n w_i$ is used instead
of $n$ to compute the small-sample adjustment, for the standard errors,
and
$$
\begin{align}
  W & = \text{diag}\\{w_1, \ldots, w_n\\} \\\\
  \widehat{V} & =
    (X^\prime W X)^{-1}
    X^\prime W \widehat{\Sigma} X
    (X^\prime W X)^{-1}
\end{align}
$$

is used for robust standard errors. In contrast, for other weights
(`aweights` being the default), $n$ is used to compute the small-sample
adjustment, and $n \widehat{V}$ estimates the asymptotic variance of the
WLS estimator. That is,
$$
\begin{align}
  \widehat{V} & =
    (X^\prime W X)^{-1}
    X^\prime W \widehat{\Sigma} W X
    (X^\prime W X)^{-1}
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

1. Compute $\overline{Y}$ and $\overline{X}$, the mean of $Y$ and
   $X$ by the levels of the fixed effect.

2. Replace $Y$ and $X$ with $Y - \overline{Y}$ and $X - \overline{X}$,
   respectively.

3. Compute OLS normally with $Y$ and $X$ de-meaned, making sure to
   include the number of fixed effects in the small-sample adjustment
   of the standard errors.

With multiple fixed effects, the same can be achieved by continuously
de-meaning by the levels of each of the fixed effects.  Following
[Correia (2017a, p. 12)](http://scorreia.com/research/hdfe.pdf), we have
instead:

1. Let $\alpha_m$ denote the $m$th fixed effect, $M$ the number of
   fixed effects (i.e. the number of variables to include as fixed
   effects), and $m = 1$.

2. Compute $\overline{Y}$ and $\overline{X}$ with the mean of $Y$ and
   $X$ by the levels of $\alpha_m$.

3. Replace $Y$ and $X$ with $Y - \overline{Y}$ and $X - \overline{X}$,
   respectively.

4. Repeat steps 2 and 3 for $m = 1$ through $M$.

5. Repeat steps 1 through 4 until convergence, that is, until neither
   $Y$ nor $X$ change across iterations.

6. Compute OLS normally with the iteratively de-meaned $Y$ and $X$,
   making sure to include the number of fixed effects across
   all fixed effect variables in the small-sample adjustment of the
   standard errors.

This is known as the Method of Alternating Projections (MAP). Let $A_m$
be a matrix with dummy variables corresponding to each of the levels
of $\alpha_m$, the $m$th fixed effect. MAP is so named because at each
step, $Y$ and $X$ are projected into the null space of $A_m$ for $m =
1$ through $M$. (In particular, with $Q_m = I - A_m (A_m^\prime A_m)^{-1}
A_m^\prime$ the orthogonal projection matrix, steps 2 and 3 replace $Y$
and $X$ with $Q_m Y$ and $Q_m X$, respectively.)

[Correia (2017a)](http://scorreia.com/research/hdfe.pdf) actually
proposes several ways of accelerating the above algorithm; we have
yet to explore any of his proposed modifications (see Correia's own
`reghdfe` package for an implementation of the methods discussed in his
paper).

Finally, we note that in step 5 we detect "convergence" as the
maximum element-wise absolute difference between $Y, X$ and $Q_m
Y, Q_m X$, respectively (i.e. the $l_{\infty}$ norm). This is
a tighter tolerance criterion than the one in
[Correia (2017a, p. 12)](http://scorreia.com/research/hdfe.pdf), which uses the $l_2$
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
with multiple covariates (and the main reason `regress` is faster without
groups or clustering). Suggestions on how to improve [this algorithm](https://github.com/mcaceresb/stata-gtools/blob/master/src/plugin/regress/linalg/colmajor.c#L1-L41) are welcome.

Missing Features
----------------

This software will remain in beta at least until the following are added:

- Option to iteratively remove singleton groups with HDFE (see 
  [Correia (2015) for notes on this issue](http://scorreia.com/research/singletons.pdf))

- Automatically detect and remove collinear groups with multi-way HDFE.
  (This is specially important for small-sample standard error adjustment.)

In addition, some important features are missing:

- Option to estimate the fixed effects (i.e. the coefficients of each
  HDFE group) included in the regression.

- Option to estimate standard errors under multi-way clustering.

- Faster HDFE algorithm. At the moment the method of alternating
  projections (MAP) is used, which has very poor worst-case performance.
  While `gregress` is fast in our benchmarks, it does not have
  any safeguards against potential corner cases. 
  ([See Correia (2017a) for notes on this issue](http://scorreia.com/research/hdfe.pdf).)

- Support for Stata's extended `varlist` syntax.

Examples
--------

Note `gregress` is in beta. To enable enable beta features, define `global GTOOLS_BETA = 1`.

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gregress.do)

### Showcase

```stata
sysuse auto, clear
gen _mpg  = mpg
qui tab headroom, gen(_h)

greg price mpg
greg price mpg, by(foreign) robust

greg price mpg _h* [fw = rep78]
mata GtoolsRegress.print()

greg price mpg _h* [fw = rep78], absorb(headroom)
mata GtoolsRegress.print()

greg price mpg _mpg, cluster(headroom)
greg price mpg _mpg [aw = rep78], by(foreign) absorb(rep78 headroom) cluster(headroom)
mata GtoolsRegress.print()

greg price mpg, mata(coefsOnly, nose)
greg price mpg, mata(seOnly,    nob)
greg price mpg, mata(nothing,   nob nose)
mata coefsOnly.print()
mata seOnly.print()
mata nothing.print()

greg price mpg, prefix(b(_b_)) replace
greg price mpg, prefix(se(_se_)) replace
greg price mpg _mpg, absorb(rep78 headroom) prefix(b(_b_) se(_se_) hdfe(_hdfe_)) replace
drop _*

greg price mpg, gen(b(_b_mpg _b_cons))
greg price mpg, gen(se(_se_mpg _se_cons))
greg price mpg, absorb(rep78 headroom) gen(hdfe(_hdfe_price _hdfe_mpg))
```

### Basic Benchmark

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

timer clear
timer on 1
greg y x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.print()
timer on 2
reghdfe y x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
greg y x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.print()
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

   1:      0.64 /        1 =       0.6380
   2:     11.77 /        1 =      11.7730
   3:      0.91 /        1 =       0.9140
   4:     15.74 /        1 =      15.7370
   5:      0.46 /        1 =       0.4570
   6:      2.09 /        1 =       2.0890
```

References
----------

The idea for this function is from Correia (2017a). The conjugate
gradient algorithm is from Hernández-Ramos, Escalante, and Raydan
(2011) and implemented following Correia (2017b).  The SQUAREM algorithm
is from Varadhan and Roland (2008) and Varadhan (2016). Irons and Tuck
(1969) method implemented following Ramière and Helfer (2015).

- Correia, Sergio (2015). "Singletons, Cluster-Robust Standard Errors and Fixed Effects: A Bad Mix" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/singletons.pdf](http://scorreia.com/research/singletons.pdf)

- Correia, Sergio (2017a). "Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/hdfe.pdf](http://scorreia.com/research/hdfe.pdf)

- Correia Sergio (2017b). "reghdfe: Stata module for linear and instrumental-variable/GMM regression absorbing multiple levels of fixed effects." Statistical Software Components S457874, Boston College Department of Economics. Accessed March 6th, 2022. Available at [https://ideas.repec.org/c/boc/bocode/s457874.html](https://ideas.repec.org/c/boc/bocode/s457874.html)

- Hernández-Ramos, Luis M., René Escalante, and Marcos Raydan. 2011. "Unconstrained Optimization Techniques for the Acceleration of Alternating Projection Methods." Numerical Functional Analysis and Optimization, 32(10): 1041–66.

- Varadhan, Ravi and Roland, Christophe. 2008. "Simple and Globally Convergent Methods for Accelerating the Convergence of Any EM Algorithm."" Scandinavian Journal of Statistics, 35(2): 335–353.

- Varadhan, Ravi (2016). "SQUAREM: Squared Extrapolation Methods for Accelerating EM-Like Monotone Algorithms." R package version 2016.8-2. https://CRAN.R-project.org/package=SQUAREM

- Bergé, Laurent (2016). "Efficient estimation of maximum likelihood models with multiple fixed-effects: the R package FENmlm." CREA Discussion Paper 2018-13. https://wwwen.uni.lu/content/download/110162/1299525/file/2018_13.

- Irons, B. M., Tuck, R. C. (1969). "A version of the Aitken accelerator for computer iteration." International Journal for Numerical Methods in Engineering 1(3): 275–277.

- Ramière, I., Helfer, T. (2015). "Iterative residual-based vector methods to accelerate fixed point iterations." Computers & Mathematics with Applications 70(9): 2210–2226
