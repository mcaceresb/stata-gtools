gstats winsor
=============

Efficiently winsorize a list of varaibles, optionally specifying
weights.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p><span class="codespan"><b>gstats winsor</b> varlist [if] [in] [weight] [, by(varlist) options] </span></p>
 
Options
-------

- `prefix(str)`         Generate targets as prefixsource (default empty).

- `suffix(str)`         Generate targets as sourcesuffix (default _w with cut and _tr with trim).

- `generate(namelist)`  Named targets to generate; one per source.

- `cuts(#.# #.#)`       Cut points (detault 1.0 and 99.0 for 1st and 99th percentiles).

- `trim`                Trim instead of Winsorize (i.e. replace outliers with missing values).

- `label`               Add Winsorized/trimming note to target labels.

- `replace`             Replace targets if they exist.

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

gstats winsor winsorizes or trims (if the trim option is specified)
the variables in varlist at particular percentiles specified by option
`cuts(#1 #2)`. By defult, new variables will be generated with a
suffix "_w" or "_tr", respectively. The user can control this via the
`suffix()` option.  The replace option replaces the variables with their
winsorized or trimmed ones.

### Winsorizing vs trimming

!!! info "Note"
    This section is nearly verbatim from the equivalent help section from winsor2.

Winsorizing is not equivalent to simply excluding data, which is
a simpler procedure, called trimming or truncation.  In a trimmed
estimator, the extreme values are discarded; in a Winsorized estimator,
the extreme values are instead replaced by certain percentiles,
specified by option cuts(# #). For details, see `help winsor` (if
installed), `help trimmean` (if installed).

For example, you type the following commands to get the 1th and 99th
percentiles of variable wage, `1.930993` and `38.70926`, respectively.

```stata
sysuse nlsw88, clear
sum wage, detail
```

By default, gstats winsor winsorize wage at 1th and 99th percentiles,

```stata
gstats winsor wage, replace cuts(1 99)
```

which can be done by hand:

```stata
replace wage = 1.930993 if wage < 1.930993
replace wage = 38.70926 if wage > 38.70926
```

Note that, values smaller than the 1th percentile is repalce by the 1th
percentile, and the similar thing is done with the 99th percentile.
Things change when `trim` option is specified:

```stata
gstats winsor wage, replace cuts(1 99) trim
```

which can also be done by hand:

```stata
replace wage = . if wage < 1.930993
replace wage = . if wage > 38.70926
```

In this case, we discard values smaller than 1th percentile or greater
than 99th percentile.  This is trimming.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gstats_winsor.do)

_Note_: These examples are taken verbatim from `help winsor2`.

Winsor at `(p1 p99)`, get new variable `wage_w`

```stata
sysuse nlsw88, clear
gstats winsor wage
```

Winsor 3 variables at 0.5th and 99.5th percentiles, and overwrite the
old variables

```stata
gstats winsor wage age hours, cuts(0.5 99.5) replace
```

Winsor 3 variables at (p1 p99), gen new variables with suffix `_win`,
and add variable labels

```stata
gstats winsor wage age hours, suffix(_win) label
```

Left-winsorizing only, at 1th percentile

```stata
cap noi gstats winsor wage, cuts(1 100)
gstats winsor wage, cuts(1 100) s(_w2)
```

Right-trimming only, at 99th percentile

```stata
gstats winsor wage, cuts(0 99) trim
```

Winsor variables at (p1 p99) by (industry), overwrite the old variables

```stata
gstats winsor wage hours, replace by(industry)
```
