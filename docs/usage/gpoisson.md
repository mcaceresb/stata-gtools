Poisson Regression (IRLS)
=========================

IRLS Poisson regressions by group with weights, clustering, and HDFE

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

!!! Warning "Warning"
    `gpoisson` is in beta; use with caution. (To enable beta features, define `global GTOOLS_BETA = 1`.)

`gpoisson` computes fast Poisson regression coefficients and standard
errors by group. Its basic functionality is similar to that of the
user-written `rangestat (reg)` or `regressby`, except that it computes
IRLS for a Poisson regression instead of OLS; in addition, `gpoisson`
allows weights, clustering, and HDFE by group.  This program is
_**not**_ intended as a substitute for `poisson`, `ppmlhdfe`, or
similar commands.  Support for some estimation operations are planned;
however, `gpoisson` does not compute any significance tests and no
post-estimation commands are available.

Syntax
------

<p><span class="codespan"><b>gpoisson</b> depvar indepvars [if] [in]  [weight] [, ///</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp; by() absorb() <span style="font-style:italic;">options</span>] </span></p>

By default, results are saved into a mata class object named
`GtoolsPoisson`. Run `mata GtoolsPoisson.desc()` for details; the name
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
- `poistol(real)` Tolerance level for Poisson IRLS algoritm (default 1e-8).
- `poisiter(int)` Maximum number of iterations for Poisson IRLS (default 1000).

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

`gpoisson` estimates a Poisson regression model via IRLS, optionally
weighted, by group, with cluster SE, and/or with multi-way
high-dimensional fixed effects.  The results are by default saved into a
mata object (default `GtoolsPoisson`).  Run `mata GtoolsPoisson.desc()`
for details; the following data is stored:

```
regression info
---------------

    string scalar caller
        model used; should be "gpoisson"

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
        grouping variable levels; see GtoolsPoisson.ByLevels.desc() for details

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

### MLE via IRLS

Poisson regression is computed via IRLS in an iterative process. Recall
the exponential family of distributions, where
$$
\begin{align}
  f(y; \theta, \varphi)
  =
  \exp \left[
      \dfrac{y \theta - b(\theta)}{a(\varphi)}
      +
      c(y, \varphi)
  \right]
\end{align}
$$

and consider $y_i | x_i \sim f(y_i; x_i^\prime \beta, \varphi)$, so that
$$
\begin{align}
    E[y_i | x_i]
    &
    =
    \mu_i
    =
    b^\prime(x_i^\prime \beta)
    % \\\\
    % V(y_i | x_i)
    % &
    % =
    % b^{\prime\prime}(\theta) a(\varphi)
    % =
    % b^{\prime\prime}(x_i^\prime \beta) a(\varphi)
\end{align}
$$

We can estimate this model via MLE, where we maximize the log-likelihood
$$
\begin{align}
  \log L
  &
  = \sum_i \log f(y_i; x_i^\prime \beta, \varphi)
  = \sum_i \left[
      \dfrac{y_i \cdot (x_i^\prime \beta) - b(x_i^\prime \beta)}{a(\varphi)}
      +
      c(y_i, \varphi)
  \right]
\end{align}
$$

with $y_i$ the dependent variable, $x_i$ covariates, and $\beta$
the vector of parameters to be estimated. The MLE estimator
$\widehat{\beta}$ is then given by the solving the FOC with respect
to $\beta$
$$
\begin{align}
  0
  &
  =
  \sum_i \dfrac{y_i - b^{\prime}(x_i^\prime \beta)}{a(\varphi)} x_i
  =
  \sum_i \dfrac{y_i - \mu_i}{a(\varphi)} x_i
\end{align}
$$

with $x_i$ the vector of covariates. One way to solve the above
equaiton is to apply Newton's method (Newton-Raphson) as shown by Nelder
and Wedderburn (1972). To find the zeros of a vector-valued function
$g(t)$, given an initial guess $t_0$, we can iterate
$$
\begin{align}
  t_{n + 1}
  &
  =
  t_n - [J_g(t_n)]^{-1} g(t_n)
\end{align}
$$

with $J_g(\cdot)$ the Jacobian matrix with the derivatives of each of
the elements of $g$ with respect to each of its arguments. Let $g(\beta)$
denote the gradient of the log-likelihood and $H(\beta)$ the Hessian,
so that $H(\beta)$ is the Jacobian matrix of $g(\beta)$. That is,
$$
\begin{align}
  g(\beta)
  &
  =
  \sum_i \dfrac{y_i - b^{\prime}(x_i^\prime \beta)}{a(\varphi)} x_i
  =
  a(\varphi)^{-1}
  X^\prime \left(Y - \mu\right)
  \\\\
  H(\beta)
  &
  =
  - \sum_i \dfrac{b^{\prime\prime}(x_i^\prime \beta)}{a(\varphi)} x_i x_i^\prime
  =
  -
  a(\varphi)^{-1}
  X^\prime W X
\end{align}
$$

where $W$ is a diagonal matrix with $w_{ii} = b^{\prime\prime}(x_i^\prime \beta)$
and $\mu$ is a vector of stacked $\mu_i = b^\prime(x_i^\prime \beta)$. Now given
an initial guess $\widehat{\beta}^{(0)}$, noting the $a(\varphi)$ cancel,
$$
\begin{align}
  \widehat{\beta}^{(r + 1)}
  &
  =
  \widehat{\beta}^{(r)}
  -
  H\big(\widehat{\beta}^{(r)}\big)^{-1}
  g\big(\widehat{\beta}^{(r)}\big)
  \\\\
  &
  =
  \widehat{\beta}^{(r)}
  +
  \big(X^\prime W^{(r)} X\big)^{-1}
  X^\prime \left(Y - \mu^{(r)}\right)
  \\\\
  &
  =
  \big(X^\prime W^{(r)} X\big)^{-1} \left(
    \big(X^\prime W^{(r)} X\big) \widehat{\beta}^{(r)}
    +
    X^\prime \left(Y - \mu^{(r)}\right)
  \right)
  \\\\
  &
  =
  \big(X^\prime W^{(r)} X\big)^{-1}
  X^\prime W^{(r)}
  \left(
    X \widehat{\beta}^{(r)}
    +
    \big(W^{(r)}\big)^{-1}
    \left(Y - \mu^{(r)}\right)
  \right)
  \\\\
  &
  =
  (X^\prime W^{(r)} X)^{-1} X^\prime W^{(r)} z^{(r)}
  \\\\
  z^{(r)}
  &
  \equiv
  \eta^{(r)}
  +
  \big(W^{(r)}\big)^{-1}
  \left(Y - \mu^{(r)}\right)
  \\\\
  \eta^{(r)}
  &
  \equiv
  X \widehat{\beta}^{(r)}
\end{align}
$$

That is, $\widehat{\beta}^{(r + 1)}$ is the result of WLS with $z^{(r)}$
as the left-hand variable, $X$ as covariates, and $W^{(r)}$ as the
weighting matrix. This procedure can estimate MLE whenever the pdf
is a member of the exponential family of distributions. In the specific
case of the Poisson,
$$
\begin{align}
  a(\varphi) = 1
  \quad\quad
  b(\theta) = e^\theta
  \quad\quad
  c(y, \varphi) = - \log(y!)
\end{align}
$$

Hence $b^{\prime}(\theta) = e^\theta, b^{\prime\prime}(\theta) = e^\theta$ and
$$
\begin{align}
  \eta^{(r)} & = X \beta^{(r)} \\\\
  \mu^{(r)}  & = \exp(\eta^{(r)}) \\\\
  W^{(r)}    & = \text{diag}\\{\mu^{(r)}_1, \ldots, \mu^{(r)}_n\\} \\\\
  z^{(r)}    & = \eta^{(r)} + (Y - \mu^{(r)}) / \mu^{(r)}
\end{align}
$$

In our specific implementation, we follow Guimarães (2014) and implement
an initial guess $\mu^{(0)} = (Y + \overline{Y}) / 2$ then define
$\eta^{(0)}, z^{(0)}$, and $W^{(0)}$. In all subsequent iterations, however, the
variables are defined as in the equations above using $\beta^{(r)}$.
Note a column of ones is automatically appended to $X$ unless the option
`noconstant` is passed or `absorb(varlist)` is requested.

We iterate until convergence. At each step, we compute the deviance,
$$
\delta^{(r + 1)} = 2 \cdot (\log(Y / \mu^{(r + 1)}) - (Y - \mu^{(r + 1)}))
$$

(if $Y_i = 0$ then $\delta^{(r + 1)}_i$ is also set to $0$). We stop
if the largest relative absolute difference between $\delta^{(r)}$ and
$\delta^{(r + 1)}$, denoted $\Delta^{(r + 1)}$, is within `poistol()`
$$
\Delta^{(r + 1)} \equiv \max_i
\frac{
  |\delta^{(r + 1)}_i - \delta^{(r)}_i|
}{
  |\delta^{(r)}_i + 1|
}
$$

$\delta^{(0)}$ is set to $1$ and the default tolerance is
$1\mathrm{e}{-8}$.  If the tolerance criteria is met then each variable
is set to their value after the $r$th iteration (i.e. $\widehat{\beta}$
to $\widehat{\beta}^{(r + 1)}$, $W$ to $W^{(r + 1)}$, and so on).
If convergence is not achieved, however, and the maximum number of
iterations is reached instead (see `poisiter()`) then the program exits
with error.

### Collinearity and Inverse

$X^\prime W^{(r)} X$ is is scaled by the inverse of $M = \max_{ij}
X^\prime W^{(r)} X$ and subsequently decomposed into $L D L^\prime$,
with $L$ lower triangular and $D$ diagonal (note $X^\prime X$ is a
symmetric positive semi-definite matrix). If $D_{ii}$ is numerically
zero then the $i$th column is flagged as collinear and subsequently
excluded from all computations (specifically if $D_{ii} < k \cdot
2.22\mathrm{e}{-16}$, where $k$ is the number of columns in $X$ and
$2.22\mathrm{e}{-16}$ is the machine epsilon in 64-bit systems).

The inverse is then computed as $(L^{-1})^\prime D^{-1} L^{-1} M^{-1}$,
excluding the columns flagged as collinear. If the determinant of
$X^\prime W^{(r)} X$ is numerically zero ($< 2.22\mathrm{e}{-16}$)
despite excluding collinear columns, a singularity warning is printed.
The coefficients for collinear columns are coded as $0$ and their
standard errors are coded as missing (`.`).

### Standard Errors

The standard error of the $i$th coefficient is given by
$$
SE_i = \sqrt{\frac{n}{n - 1} \widehat{V}_{ii}}
$$

where $\frac{n}{n - 1}$ is a small-sample adjustment and $n
\widehat{V}$ is a consistent estimator of the asymptotic variance of
$\widehat{\beta}$.  Note we compute the small-sample adjustment to match
the standard errors returned by Stata's `poisson` program.  The standard
error of collinear columns is coded as missing (`.`).

By default, homoskedasticity-consistent standard errors are computed:
$$
\begin{align}
  \widehat{V}      & = (X^\prime W X)^{-1} \widehat{\sigma} \\\\
  \widehat{\sigma} & = \widehat{\varepsilon}^\prime \widehat{\varepsilon} / n
\end{align}
$$

where
$$
\widehat{\varepsilon} = z - X \widehat{\beta}
$$

is the error of the WLS fit for the $r$th iteration. If `robust` is
passed then White heteroskedascitity-consistent standard errors are
computed instead:
$$
\begin{align}
  \widehat{\Sigma} & = \text{diag}\\{\widehat{\varepsilon}_1^2, \ldots, \widehat{\varepsilon}_n^2\\} \\\\
  \widehat{V}      & = (X^\prime W X)^{-1} X^\prime W \widehat{\Sigma} W X (X^\prime W X)^{-1}
\end{align}
$$

### Clustering

If `cluster(varlist)` is passed then nested cluster standard errors are
computed (i.e. the rows of `varlist` define the groups). Let $j$ denote
the $j$th group defined by `varlist` and $J$ the number of groups. Then
$$
\begin{align}
  \widehat{V} & =
  (X^\prime W X)^{-1}
  \left(
    \sum_{j = 1}^J \widehat{u}_j \widehat{u}_j^\prime
  \right)
  (X^\prime W X)^{-1}
  \\\\
  \widehat{u}_j & = X_j^\prime W_j \widehat{\varepsilon}_j
\end{align}
$$

with $X_j^\prime$ the matrix of covariates with observations from the
$j$th group, $\widehat{\varepsilon}_j$ the vector with errors from the
$j$th group, and $W_j$ the diagonal matrix with entries corresponding to
the weights for the $j$th group (i.e. $\mu_j$).  (Note another way to
write the sum in $\widehat{V}$ is as $U^\prime U$, with $U^\prime = [u_1
~~ \cdots ~~ u_J]$.) Finally, the standard error is given by

$$
SE_i = \sqrt{\frac{J}{J - 1} \widehat{V}_{ii}}
$$

Note we compute the small-sample adjustment to match the standard errors
returned by Stata's `poisson` program.

### Weights

Let $w$ denote the weighting variable and $w_i$ the weight assigned to
the $i$th observation. $\widehat{\beta}$ is obtained in the same way
except that at each iteration step, we use
$$
\widetilde{W}^{(r)} = \text{diag}\\{\mu^{(r)}_1 w_1, \ldots, \mu^{(r)}_n w_n\\}
$$

as the weighting matrix instead of $W^{(r)}$. `fweights` runs the regression as if
there had been $w_i$ copies of the $i$th observation. As such, $n_w =
\sum_{i = 1}^n w_i$ is used instead of $n$ to compute the small-sample
adjustment, and
$$
\begin{align}
  \widehat{\Sigma} & = \text{diag}\\{\widehat{\varepsilon}_1^2 w_1, \ldots, \widehat{\varepsilon}_n^2 w_n\\} \\\\
  \widehat{V} & =
    (X^\prime \widetilde{W} X)^{-1}
    X^\prime W \widetilde{\Sigma} W X
    (X^\prime \widetilde{W} X)^{-1}
\end{align}
$$

is used for robust standard errors. There are a few ways to write this,
but the idea is that this is not the variance of the WLS estimate, but
the variance if there had been $w_i$ copies of the $i$th observation.
The IRLS algorithm computes WLS already, so the $i$th weight (after
convergence) is $\mu_i w_i$. However, we want $w_i$ _copies_ of the $i$th
observation instead.  Hence the correct _weight_ is $W$ but we
multiply $\widehat{\varepsilon}_i^2$ with $w_i$ to mimic the scenario
when we have $w_i$ copies of the $i$th row.

In contrast, for other weights (`aweights` being the default), $n$
is used to compute the small-sample adjustment, and $n \widehat{V}$
estimates the asymptotic variance of the WLS estimator. That is,
$$
\begin{align}
  \widehat{V} & =
    (X^\prime \widetilde{W} X)^{-1}
    X^\prime \widetilde{W} \widehat{\Sigma} \widetilde{W} X
    (X^\prime \widetilde{W}  X)^{-1}
\end{align}
$$

In other words, we can replace $W$ with $\widetilde{W}$ entirely.  With
clustering, these two methods of computing $\widehat{V}$ will actually
coincide, and the only difference between `fweights` and other weights
will be the way the small-sample adjustment is computed.

Finally, with weights and HDFE, the iterative de-meaning (see below)
uses the weighted mean.

### HDFE

Multi-way high-dimensional fixed effects can be added to any regression
via `absorb(varlist)`. That is, coefficients at each iteration are
computed as if the levels of each variable in `varlist` had been
added to the regression as fixed effects. It is well-known that with
one fixed effect $\widehat{\beta}^{(r)}$ can be estimated via the
within transformation (i.e. de-meaning the dependent variable and each
covariate by the levels of the fixed effect; this can also be motivated
via the Frisch-Waugh-Lovell theorem). That is, with one fixed effect we
have the following algorithm at each iteration:

1. Compute $\overline{z}^{(r)}$ and $\overline{X}$ with the _weighted_
   mean of $z^{(r)}$ and $X$ by the levels of the fixed effect. The
   weighting vector is $\mu^{(r)}$.

2. Replace $z^{(r)}$ and $X$ with $z^{(r)} - \overline{z}^{(r)}$ and
   $X - \overline{X}$, respectively.

3. Compute WLS normally with $z^{(r)}$ and $X$ de-meaned, making sure
   to include the number of fixed effects in the small-sample adjustment
   of the standard errors.

With multiple fixed effects, the same can be achieved by continuously
de-meaning by the levels of each of the fixed effects.  Following
[Correia (2017, p. 12)](http://scorreia.com/research/hdfe.pdf), we have
instead:

1. Let $\alpha_m$ denote the $m$th fixed effect, $M$ the number of
   fixed effects (i.e. the number of variables to include as fixed
   effects), and $m = 1$.

2. Compute $\overline{z}^{(r)}$ and $\overline{X}$ with the _weighted_
   mean of $z^{(r)}$ and $X$ by the levels of $\alpha_m$. The weighting
   vector is $\mu^{(r)}$.

3. Replace $z^{(r)}$ and $X$ with $z^{(r)} - \overline{z}^{(r)}$ and
   $X - \overline{X}$, respectively.

4. Repeat steps 2 and 3 for $m = 1$ through $M$.

5. Repeat steps 1 through 4 until convergence, that is, until neither
   $Y$ nor $X$ change across iterations.

6. Compute WLS normally with the iteratively de-meaned $z^{(r)}$ and
   $X$, making sure to include the number of fixed effects across all
   fixed effect variables in the small-sample adjustment of the standard
   errors.

This is known as the Method of Alternating Projections (MAP). Let $A_m$
be a matrix with dummy variables corresponding to each of the levels
of $\alpha_m$, the $m$th fixed effect. MAP is so named because at each
step, $z^{(r)}$ and $X$ are projected into the null space of $A_m$ for $m =
1$ through $M$. (In particular, with $Q_m = I - A_m (A_m^\prime A_m)^{-1}
A_m^\prime$ the orthogonal projection matrix, steps 2 and 3 replace $z^{(r)}$
and $X$ with $Q_m z^{(r)}$ and $Q_m X$, respectively.)

[Correia (2017)](http://scorreia.com/research/hdfe.pdf) actually
proposes several ways of accelerating the above algorithm; we have
yet to explore any of his proposed modifications (see Correia's own
`reghdfe` and `ppmlhdfe` packages for an implementation of the methods
discussed in his paper).

Finally, we note that in step 5 we detect "convergence" as the
maximum element-wise absolute difference between $z^{(r)}, X$ and
$Q_m z^{(r)}, Q_m X$, respectively (i.e. the $l_{\infty}$ norm). This
is a tighter tolerance criterion than the one in [Correia (2017,
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
with multiple covariates (and the main reason `regress` is faster without
groups or clustering). Suggestions on how to improve [this algorithm](https://github.com/mcaceresb/stata-gtools/blob/master/src/plugin/regress/linalg/colmajor.c#L1-L41) are welcome.

Missing Features
----------------

This software will remain in beta at least until the following are added:

- Option to iteratively remove singleton groups with HDFE (see [Correia (2015)
  for notes on this issue](http://scorreia.com/research/singletons.pdf))

- Automatically detect and remove collinear groups with multi-way HDFE.
  (This is specially important for small-sample standard error adjustment.)

- Automatically detect and option to flag separated observations (see [Correia,
  Guimarães, and Zylkin, 2019](https://arxiv.org/abs/1903.01633v5) and the
  primer [here](https://github.com/sergiocorreia/ppmlhdfe/blob/master/guides/separation_primer.md)).

In addition, some important features are missing:

- Option to estimate the fixed effects (i.e. the coefficients of each
  HDFE group) included in the regression.

- Option to estimate standard errors under multi-way clustering.

- Faster HDFE algorithm. At the moment the method of alternating
  projections (MAP) is used, which has very poor worst-case performance.
  While `gregress` is fast in our benchmarks, it does not have
  any safeguards against potential corner cases.  ([See Correia
  (2017) for notes on this issue](http://scorreia.com/research/hdfe.pdf).)

- Support for Stata's extended `varlist` syntax.

Examples
--------

Note `gregress` is in beta. To enable enable beta features, define `global GTOOLS_BETA = 1`.

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gpoisson.do)

### Showcase

```stata
webuse ships, clear
expand 2
gen by = 1.5 - (_n < _N / 2)
gen w = _n
gen _co_75_79  = co_75_79
qui tab ship, gen(_s)

gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 [fw = w], robust
mata GtoolsPoisson.print()

gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 _co_75_79 [pw = w], cluster(ship)
mata GtoolsPoisson.print()

gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 _s*, absorb(ship) cluster(ship)
mata GtoolsPoisson.print()

gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79, by(by) absorb(ship) robust
mata GtoolsPoisson.print()
```

### Basic benchmark

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
gen l  = int(0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + g4 + 20 * rnormal())

timer clear
timer on 1
gpoisson l x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.print()
timer on 2
ppmlhdfe l x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
gpoisson l x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.print()
timer on 4
ppmlhdfe l x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 4

timer list

   1:      9.10 /        1 =       9.0950
   2:     37.58 /        1 =      37.5760
   3:      8.68 /        1 =       8.6810
   4:     37.16 /        1 =      37.1600
```

References
----------

Correia, Sergio. 2015. "Singletons, Cluster-Robust Standard Errors and Fixed Effects: A Bad Mix" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/singletons.pdf](http://scorreia.com/research/singletons.pdf)

Correia, Sergio. 2017. "Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator" Working Paper. Accessed January 16th, 2020. Available at [http://scorreia.com/research/hdfe.pdf](http://scorreia.com/research/hdfe.pdf)

Correia, Sergio, Paulo  Guimarães, and Thomas Zylkin. 2019. "Verifying the existence of maximum likelihood estimates for generalized linear models." arXiv:1903.01633v5 [econ.EM]. Accessed January 16th, 2020. Available at [https://arxiv.org/abs/1903.01633v5](https://arxiv.org/abs/1903.01633v5)

Guimarães, Paulo. 2014. "POI2HDFE: Stata module to estimate a Poisson regression with two high-dimensional fixed effects." Statistical Software Components S457777, Boston College Department of Economics, revised 16 Sep 2016. Accessed January 16th, 2020. Available at [https://ideas.repec.org/c/boc/bocode/s457777.html](https://ideas.repec.org/c/boc/bocode/s457777.html)

Nelder, John A. and Wedderburn, Robert W. 1972. "Generalized Linear Models." Journal of the Royal Statistical Society. Series A (General), 135 (3): 370-384. Accessed September 12th, 2020.
