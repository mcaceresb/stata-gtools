gquantiles
==========

Efficiently compute percentiles, quantiles, categories, and frequency counts.

gquantiles is a by-able replacement for xtile, pctile, and \_pctile
that offers several additional features, like computing arbitrary
quantiles (and an arbitrary number), frequency counts, and more (see the
[examples](#examples) below).

gquantiles is also faster than the user-written fastxtile, so an alias,
fasterxtile, is also provided.

_Note for Windows users:_ It may be necessary to run `gtools, dependencies` at
the start of your Stata session.

Syntax
------

The full syntax is

<p>
<span class="codespan">gquantiles [newvar =] exp [if] [in] [weight], {pctile | xtile | _
pctile}</span>
</br>
<span class="codespan">&emsp;&emsp;&emsp;<a href="#quantiles-method">quantiles_method</a> [ <a href="#gquantiles-options">gquantiles_options</a> ]</span>
</p>

This function accepts `by()` with `xtile` and `pctile`.  However, you
can simply use it as a replacement for native Stata commands.

__*Equivaent to pctile*__ (store the quantiles of `exp` in `newvar`):
```stata
gquantiles newvar = exp [if] [in] [weight], pctile [nquantiles(#) genp(newvarname) altdef]
```

<br>
__*Equivaent to xtile*__ (store the categories of `exp` in `newvar`):
```stata
gquantiles newvar = exp [if] [in] [weight], xtile [nquantiles(#) cutpoints(numlist) altdef]

fasterxtile newvar = exp [if] [in] [weight], [nquantiles(#) cutpoints(numlist) altdef]
```

<br>
__*Equivaent to \_pctile*__ (return the percentiles of `exp`):
```stata
gquantiles exp [if] [in] [weight], _pctile [nquantiles(#) percentiles(numlist) altdef]
```

<br>
The options and behavior of the above largely mimic that of the Stata native
commands. You only need to read the rest of the documentation if you wish to
use some of the additional features that gquantiles provides.

Weights
-------

aweight, fweight, and pweight are allowed and mimic the weights in
`pctile`, `xtile`, or `_pctile` (see `help weight` and the weights
section in `help pctile`). Weights are not allowed with `altdef`.

Options
-------

### Quantiles method

gquantiles offers 4 ways of specifying quantiles and 3 ways of specifying
cutoffs. The behavior of each differs slightly when specifying `pctile`,
`xtile`, and `_pctile` (see [stored results](stored-results) for details).

- `nquantiles(#)` Number of quantiles to copmpute. gquantiles computes
  percentiles (quantiles) corresponding to _100 * k / m_ for
  _k = 1, 2, ..., m - 1_, where _m = #_. For example, `nquantiles(10)`
  requests that the 10th, 20th, ..., 90th percentiles be computed.
  The default is `nquantiles(2)`, the median.
<br><br>

- `cutpoints(varname)` (`xtile` or `pctile` only).
  Requests that the values of `varname` be used instead of the quantiles
  of the source variable. Like the native equivalent, all values of varname
  are used, regardless of any `if` or `in` restriction (the user can pass
  the option `cutifin` to restrict `cutpoints` to the `if in` range or option
  `cutby` to use different cutpoints in each group).
  <br><br>
  Note that without any additional options, in the case of `pctile` all this
  does is sort `varname` and store it in the target variable.  Further, unlike
  the native equivalent, this variable does not need to be sorted or unique.
  Missings are excluded by default and the variable is sorted internally.  The
  user can request duplicates be excluded via the option `dedup`.
<br><br>

- `quantiles(numlist)` or `percentiles(numlist)`. Requests percentiles (quantiles)
  corresponding to those specified by `numlist`. For example,
  `percentiles(10(20)90)` requests that the 10th, 30th, 50th, 70th, and 90th
  percentiles be computed.<br><br>
  Unlike the native equivalent, this can be specified with `pctile` and `xtile`
  as well as `_pctile`.  With `pctile` the results are stored in the target
  variable. With `xtile` the rank is computed using `numlist`.  With `_pctile`
  the return values are stored in r(r1), r(r2), ..., etc. Note that the
  number of return values that can be set is artificially capped at 1001
  because they take a really long time to set. For more than 1001 return
  values consider using `cutquantiles()` with `pctile` or see the
  [computing many quantiles](#computing-many-quantiles) section in the examples
  below.
<br><br>

- `quantmatrix(matrix)`. Requests percentiles (quantiles) corresponding to the
  entries of the matrix. This must be a column vector or a row vector. The
  behavior of gquantiles using this option is otherwise equivalent to its
  behavior when passing `quantiles()`.
<br><br>

- `cutquantiles(varname)` (`xtile` or `pctile` only).
  Requests that the values of `varname` be used as the percentiles (quantiles)
  to compute. `varname` must have all its values between 0 and 100. By default
  all values are read, regardless of `if in` restrictions (use option
  `cutifin` to restrict the range or `cutby` to use different cut quantiles
  per group). Missing values are dropped and duplicates are allowed
  (use option `dedup` to drop duplicate quantiles).<br><br>
  This option is included to allow the user to compute an arbitrary number
  of quantiles in a reasonable amount of time. While the user can force more
  than 1001 return values with the `_pctile` option, this is ill-advised
  since performance will suffer greatly.
<br><br>

- `cutoffs(numlist)` (Only with `xtile`, `pctile`, or `_pctile` with `bincount`).
  This option is similar to `cutpoints`, except that instead of using the values
  of a variable the function uses the values of `numlist` as the cutoffs.<br><br>
  With option `_pctile` this option is only allowed with `bincount`, which
  requests a count of the number of instances of the source variable within
  the bins defined by the cutoffs.
<br><br>

- `cutmatrix(matrix)`. Requests cutoffs corresponding to the entries of the matrix.
  This must be a column vector or a row vector. The behavior of gquantiles using
  this option is otherwise equivalent to its behavior when passing `cutoffs()`.
<br><br>

### gquantiles options

__*Standard Options*__

- `altdef`. Use an alternative definition for quantiles. When you have a finite
  number of values, as is the case with all data with _N_ observations, there are
  at most _N - 1_ exact quantiles (assuming no duplicates). To compute arbitrary
  quantiles we need to make additional assumptions.<br><br>
  Let _x(i)_ denote _i_-th smallest value of the relevant variable such that
  _i > qN / 100_.  If _i - 1 < qN / 100_ then the quantile is _x(i)_. However,
  if _i - 1 = qN / 100_ the convention is to use the average of _x(i)_ and _x(i - 1)_.
  Option `altdef` defines _i <= q(N + 1) / 100_ and _h = q(N + 1) / 100 - i_.
  Then the quantile is _(1 - h) * x(i) + h * x(i + 1)_ instead.
<br><br>

- `genp(newvar)` specifies a new variable to be generated containing the percentages
  corresponding to the percentiles (quantiles) be created.
<br><br>

__*Extras*__

- `by(varlist)` Compute quantiles by group (pctile or xtile only). `pctile[()]` requires option
  `strict`, which has the effect of ignoring groups where the number of quantiles requested is
  larger than the number of non-missing observations within the group. `by()` is most useful
  with option `groupid(varname)`.

- `groupid(varname)` Store group ID in `varname`.

- `_pctile` (Not with by.) does the computation in the style of the native command `_pctile`. It stores
  return values in r(1), r(2), and so on, as wll as a matrix called `r(quantiles_used)`
  or `r(cutoffs_used)` in case quantiles or cutoffs are requested. See [stored results](stored-results)
  for details.
<br><br>

- `pctile` or `pctile(newvar)` Computes the quantiles of the source variable (i.e. calls
  `gquantiles` in the style of the native command `pctile`). The `pctile(newvar)` syntax
  is provided to allow combining `pctile` with other options. See [examples](#multiple-subcommands).
<br><br>

- `xtile` or `xtile(newvar)` Computes the category of the source variable using the categories
  defined by the cutoffs or implied by the quantiles (i.e. calls `gquantiles` in the style of
  the native command `xtile`). The `xtile(newvar)` syntax is provided to allow combining `xtile`
  with other options. See [examples](#multiple-subcommands).
<br><br>

- `binfreq` (Not with by.) or `binfreq(newvar)` Stores the frequency counts of the source variable
  within the bins defined by the quantiles or the cuoffs. When
  weights are specified, this stores the sum of the weights within
  that category. If `newvar` is passed then the frequency counts
  are stored in `newvar`; otherwise they are stored in the matrix
  `r(quantiles_bincount)` or `r(cutoffs_bincount)`.

<br><br>

__*Switches*__

- `method(#)` (Not with by.) If you have many duplicates or are computing many quantiles,
  you should specify `method(1)`. If you have few duplicates or are computing
  few quantiles you should specify `method(2)`. By default, `gquantiles` tries
  to guess which method will run faster. See [computation methods](#computation-methods)
  in the examples section below.
<br><br>

- `dedup` By default all quantiles and cutoffs are used in computations, regardless
  of duplicate values. For instance, if the user asks for quantiles 1, 90, 10,
  10, and 1, then quantiles 1, 1, 10, 10, and 90 are used. With this option
  only 1, 10, and 90 would be used.
<br><br>

- `cutifin` By default all values of the variable requested via `cutpoints`
  or `cutquantiles` are used. The reason Stata behaves in this way is that
  `cutpoints` was written to take in the output of `pctile` (this is how
  `xtile` works internally). Here, both `cutpoints` and `cutquantiles` are
  generic options, so the user can read all values or just values `if in`.
<br><br>

- `cutby` By default all values of the variable requested via `cutpoints`
  or `cutquantiles` are used. With this option, each group uses a different
  set of quantiles or cutoffs (note this automatically sets option `cutifin`).
<br><br>

- `returnlimit(#)` Default is 1001. When the user runs gquantiles in the style of `_pctile`
  return values r(1), r(2), and so on are set. The limit of quantiles that can be computed
  is the number of observations in the data, which can be millions or billions. Setting
  that many return values is computationally infeasible! The user can turn
  off this check via `returnlimit(.)`. **This is ill-advised**. To compute
  that many quantiles it is better to use the `pctile` option.
<br><br>

- `strict` Without `by()`, exit with error if the number of quantiles requested
  is above the number of non-missing values. In the case of xtile, this also
  restricts the number of quantiles to the number of observations in the data.
  With `by()`, skip groups where this happens.  Note that Stata limits
  `nquantiles()` with `xtile` because it creates a temporary variable
  with the quantiles. Hence from the point of view of gquantiles this is
  an artificial limitation.
<br><br>

- `minmax` (Not with by.) Additionally store `r(min)` and `r(max)`. Percentiles
  (quantiles) are required to be strictly between 0 and 100. However,
  the min and max are relatively trivial to compute given the internals
  of the command, so the user can request them here.
<br><br>

- `replace` Replace targets, should they exist.
<br><br>

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

- `hashlib(str)` On earlier versions of gtools Windows users had a problem
            because Stata was unable to find spookyhash.dll, which is bundled
            with gtools and required for the plugin to run correctly. The best
            thing a Windows user can do is run gtools, dependencies at the start
            of their Stata session, but if Stata cannot find the plugin the user
            can specify a path manually here.

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

All calls store the following results

    Scalars

        r(N)                  Number of observations
        r(min)                Min (only if minmax was requested)
        r(max)                Max (only if minmax was requested)
        r(nqused)             Number of quantiles/cutoffs
        r(method_ratio)       Rule used to decide between methods 1 and 2

        r(nquantiles)         Number of quantiles (only w nquantiles())
        r(ncutpoints)         Number of cutpoints (only w cutpoints())
        r(nquantiles_used)    Number of quantiles (only w quantiles())
        r(nquantpoints)       Number of quantiles (only w cutquantiles())
        r(ncutoffs_used)      Number of cutoffs (only w cutoffs())

        r(r#)                 The #th quantile requested (only w _pctile)

    Macros

        r(quantiles)          Quantiles used (only w percentiles() or quantiles())
        r(cutoffs)            Cutoffs used (only w option cutoffs())

    Matrices

        r(quantiles_used)     With _pctile or with quantiles()
        r(quantiles_binfreq)  With option binfreq and any quantiles requested

        r(cutoffs_used)       With _pctile or with cutoffs()
        r(cutoffs_binfreq)    With option binfreq and any cutoffs requested

Methods and Formulas
--------------------

The behavior of `gquantiles` follows the behavior specified in
[Stata's documentation](https://www.stata.com/manuals13/dpctile.pdf)
(in particular see the "Methods and formulas" section). We do not
repeat those formulas here.

One interesting thing to note is that Stata artificially limits the way in
which `xtile` can be categorized. That is, the program defines categories
using the quantiles or the cutoffs as the right-inclusive endpoints. For
instance, `nquantiles(NQ)` gives _q(1), q(2), ..., q(NQ - 1)_ quantiles. (For
`cutpoints(varname)`, _q(i)_ is the _i_-th smallest value of `varname`, and so
on for each way to specify quantiles and cutoffs). Now we have

    | Category | Range                  |
    | -------- | ---------------------- |
    |        1 | (-Inf, q(1)]           |
    |        2 | (q(1), q(2)]           |
    |      ... | ...                    |
    |   NQ - 1 | (q(NQ - 2), q(NQ - 1)] |
    |       NQ | (q(NQ - 1), Inf)       |

In theory there is no reason to limit NQ. For example, the question
"Where do these 4 values fit in these 1000 categories?" is a
well-defined question. Even if there will be at least 996 categories
contain no values, there is no reason to limit the number of categories
to 4 (of course, since the 1000 categories are created from those 4
values, in practice this might not be adviseable).

So why does the limit exist in `xtile`? It is actually a limit in `pctile`,
which is used internally. Since `pctile` stores the percentiles in a variable
in the data, this limit is actually very reasonable in this case (the same
limit is in `gquantiles, pctile`). However, the user can request an arbitrary
number of quantiles via `gquantiles, xtile nq(#)`. If the user does not like
this behavior, they can pass the option `strict`.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gquantiles.do)

### Using by

One major feature that gquantile adds is `by()`. It should be
internally consistent if the user specifies the option `strict`.
For example,

```stata
clear
set obs 1000000
gen group = int(runiform() * 100)
gen x = runiform()

local popts pctile strict by(group) cutby
gquantiles pctile = x, `popts' nq(10) genp(perc) groupid(id)

local xopts xtile strict by(group) cutby
gquantiles xtile  = x, `xopts' nq(10)
gquantiles xtile2 = x, `xopts' cutpoints(pctile)
gquantiles xtile3 = x, `xopts' cutquantiles(perc)

assert xtile == xtile2
assert xtile == xtile3
```

However, there is no requirement for the user to do so:

```stata
sysuse auto, clear
gquantiles xtile = price, xtile by(foreign) nq(50)
```

### Computing many quantiles

Stata's \_pctile caps the number of quantiles to 1001. pctile uses \_pctile
internally, so to compute more than 1001 percentiles it needs to loop over
various runs of \_pctile in a very inefficient way.  This inefficiency carries
over to xtile because that command uses pctile internally. (Presumably this is
the reason for the limit in the user-written fastxtile).

The following executes with no errors in a reasonable amount of time
```stata
clear
set obs 1000000
gen x = runiform()
_pctile x, nq(1001)
pctile p1 = x, nq(1001)
gquantiles p2 = x, pctile nq(1001)
```

However, if you increase `nq` the runtimes become excessive:
```stata
drop p*
timer clear

timer on 90
pctile p1 = x, nq(5001)
timer off 90

timer on 10
gquantiles p2 = x, pctile nq(5001)
timer off 10

assert p1 == p2
timer list
```
```
  10:      0.42 /        1 =       0.4200
  90:     61.14 /        1 =      61.1440
```

61 seconds for only 1,00,000 observations! This is in
Stata/MP with 8 cores. gquantiles scales nicely, by contrast:
```stata
drop p*
timer clear

timer on 10
gquantiles p2 = x, pctile nq(`=_N + 1')
timer off 10

clear
set obs 100000000
gen x = runiform() * 100

timer on 20
gquantiles p2 = x, pctile nq(`=_N + 1')
timer off 20

timer list
```
```
  10:      0.44 /        1 =       0.4430
  20:     36.53 /        1 =      36.5270
  90:     61.14 /        1 =      61.1440
```

That's right, gquantiles computed 100M quantiles for 100M observations in 36
seconds, faster than pctile could compute 5,000 quantiles for 1M observations.
As a side-note, using mata can afford a massive speedup, obviating the need
to call C in case gquantiles does not do something you want. Consider:
```stata
clear all
timer clear

mata:
void function mata_pctile (string scalar newvar,
                           string scalar sourcevar,
                           real scalar nq)
{
    real scalar N
    real colvector X, quantiles, qpositions, qties, qtiesix, Q, Qties

    X = st_data(., sourcevar)
    N = rows(X)
    _sort(X, 1)
    quantiles  = ((1::(nq - 1)) * N / nq)
    qpositions = ceil(quantiles)
    qties      = (qpositions :== quantiles)
    Q          = X[qpositions]

    if ( any(qties) ) {
        qtiesix = selectindex(qties)
        Qties = X[qpositions[qtiesix] :+ 1]
        Q[qtiesix] = (Q[qtiesix] + Qties) / 2
    }

    st_addvar("`:set type'", newvar)
    st_store((1::(nq - 1)), newvar, Q)
}
end

set obs 1000000
gen x = runiform()

timer on 80
mata: mata_pctile("p0", "x", 5001)
timer off 80

timer on 90
pctile p1 = x, nq(5001)
timer off 90

timer on 10
gquantiles p2 = x, pctile nq(5001)
timer off 10

assert p0 == p1
assert p1 == p2
timer list
```
```
  10:      0.48 /        1 =       0.4770
  80:      1.23 /        1 =       1.2300
  90:     56.97 /        1 =      56.9720
```

Just by using mata we speeded up Stata 50 times! The mata solution
does not scale as well as gquantiles, however:
```stata
clear
timer clear
set obs 10000000
gen x = runiform()

timer on 80
mata: mata_pctile("p0", "x", 5001)
timer off 80

timer on 10
gquantiles p2 = x, pctile nq(5001)
timer off 10

timer list
```
```
  10:      2.97 /        1 =       2.9720
  80:     14.40 /        1 =      14.4030
```

With just 10M observations, gquantiles is still a 5x improvement over mata
when computing many quantiles.

### Computation methods

Computing quantiles involves selecting elements from an unordered array
in one of two ways: Using a selection algorithm on the unsorted variable
or sorting and then selecting elements of the sorted varaible.

The internal selection algorithm of gquantiles is very fast and on average will
run in linear O(N) time (see [quickselect](https://en.wikipedia.org/wiki/Quickselect)).
The sorting algorithm runs in O(N log(N)) time (see [quicksort](https://en.wikipedia.org/wiki/Quicksort)).
Clearly, with few quantiles we can see the selection algorithm will be faster.
However, with a large number of quantiles running multiple iterations of the
selection algorithm is clearly slower than doing a single sort.

```stata
clear
timer clear

set obs 10000000
gen x = rnormal() * 100

timer on 10
gquantiles p1 = x, pctile nq(2) method(1)
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(2) method(2)
timer off 20

assert p1 == p2
timer list
```
```
  10:      3.39 /        1 =       3.3870
  20:      1.10 /        1 =       1.1020
```

We can see that method 2 was more than 3 times faster for a single quantile.
```stata
timer clear

timer on 10
gquantiles p1 = x, pctile nq(10) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(10) method(2) replace
timer off 20

timer list
```
```
  10:      3.43 /        1 =       3.4290
  20:      2.28 /        1 =       2.2840
```

While method 2 was still faster, computing 10 quantiles took twice the time it
took to compute 1. By contrast, method 1 took essentially the same time. This
is because after sorting the data, selecting elements is nearly instantaneous.
```stata
timer clear

timer on 10
gquantiles p1 = x, pctile nq(100) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(100) method(2) replace
timer off 20

timer list
```
```
  10:      3.22 /        1 =       3.2210
  20:      7.04 /        1 =       7.0370
```

With 100 quantiles we can see that the performance of method 2 is now much
worse than method 1. Internally, gquantiles will try to switch between the two
methods based on the number of observations and the number of quantiles.
You might be tempted to always specify method 2 for few quantiles, but
there is a second way in which it is slower than sorting:
```stata
timer clear
replace x = int(x)

timer on 10
gquantiles p1 = x, pctile nq(10) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(10) method(2) replace
timer off 20

timer list
```
```
  10:      1.29 /        1 =       1.2940
  20:      1.48 /        1 =       1.4760
```

What happened? While both commands are faster, now method 1 is faster than
method 2, whereas before it was 50% slower. This is because the specific
sorting algorithm I use handles duplicates better than the selection
algorithm.
```stata
timer clear

timer on 10
gquantiles p1 = x, pctile nq(100) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(100) method(2) replace
timer off 20

timer list
```
```
  10:      1.54 /        1 =       1.5390
  20:      4.31 /        1 =       4.3080
```

Again, both are faster with duplicates, but method 1 is much faster.

### Multiple subcommands

gquantiles allows the user to compute several things at once:
```stata
sysuse auto, clear
gquantiles price, _pctile xtile(x1) pctile(p1) binfreq nq(10)
matrix list r(quantiles_binfreq)
l price x1 p1 in 1/10
```
```
r(quantiles_binfreq)[9,1]
    c1
r1   8
r2   7
r3   8
r4   7
r5   7
r6   8
r7   7
r8   8
r9   7

     +----------------------+
     |  price   x1       p1 |
     |----------------------|
  1. |  4,099    2     3895 |
  2. |  4,749    5     4099 |
  3. |  3,799    1     4425 |
  4. |  4,816    5     4647 |
  5. |  7,827    8   5006.5 |
     |----------------------|
  6. |  5,788    7     5705 |
  7. |  4,453    4     6165 |
  8. |  5,189    6     7827 |
  9. | 10,372    9    11385 |
 10. |  4,082    2        . |
     +----------------------+
```

### Specifying quantiles and cutoffs

gquantiles allows for several ways to specify cutoffs
```stata
sysuse auto, clear

gquantiles price, _pctile p(10(10)99)
matrix p0 = r(quantiles_used)

gquantiles p1 = price, pctile nq(10) genp(g1) xtile(x1)
gquantiles x2 = price, xtile cutpoints(p1)
gquantiles x3 = price, xtile cutquantiles(g1)

qui glevelsof p1
gquantiles x4 = price, xtile cutoffs(`r(levels)')

qui glevelsof g1
gquantiles x5 = price, xtile quantiles(`r(levels)')

matrix list p0
l p1 g1 x? in 1/10
```
```
p0[9,1]
        c1
r1    3895
r2    4099
r3    4425
r4    4647
r5  5006.5
r6    5705
r7    6165
r8    7827
r9   11385

. l p1 g1 x? in 1/10

     +--------------------------------------+
     |     p1   g1   x1   x2   x3   x4   x5 |
     |--------------------------------------|
  1. |   3895   10    2    2    2    2    2 |
  2. |   4099   20    5    5    5    5    5 |
  3. |   4425   30    1    1    1    1    1 |
  4. |   4647   40    5    5    5    5    5 |
  5. | 5006.5   50    8    8    8    8    8 |
     |--------------------------------------|
  6. |   5705   60    7    7    7    7    7 |
  7. |   6165   70    4    4    4    4    4 |
  8. |   7827   80    6    6    6    6    6 |
  9. |  11385   90    9    9    9    9    9 |
 10. |      .    .    2    2    2    2    2 |
     +--------------------------------------+
```
