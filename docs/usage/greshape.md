greshape
========

`greshape` is a fast alternative to `reshape` that additionally
implements the equivalents to R's `spread` and `gather` from `tidyr`.
It also allows an arbitrary number of grouping by variables (`i()`) and
keys (`j()`).

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

In R parlance, `j()` is called `keys()`, which is frankly much clearer
to understand than `i` and `j`. While regular Stata syntax is also
supported, `greshape` provides the aliases `by()` and `keys()` for `i()`
and `j()` respectively (note _spread_ and _wide_ accept multiple `j` keys).

<p>
<span class="codespan">
wide -> long
</br>
------------
</br>
</br>
<b>greshape</b> long stubnames, by(varlist) [<a href="#long-and-wide">options</a>]
</span>
</br>
<span class="codespan">
<b>greshape</b> gather varlist, keys(varlist) values(varname) [<a href="#gather-and-spread">options</a>]
</span>
</p>

<p>
<span class="codespan">
long -> wide
</br>
------------
</br>
</br>
<b>greshape</b> wide stubnames, by(varlist) keys(varname) [<a href="#long-and-wide">options</a>]
</span>
</br>
<span class="codespan">
<b>greshape</b> spread varlist, keys(varname) [<a href="#gather-and-spread">options</a>]
</span>
</p>

I think the above syntax is clearer (happy to receive feedback otherwise)
but `greshape` also accepts the traditional Stata `i, j` syntax:
<p>
<span class="codespan">
greshape long stubnames, i(varlist) [options]
</span>
</br>
<span class="codespan">
greshape wide stubnames, i(varlist) j(varname) [options]
</span>
</p>

Syntax Details
--------------


The stubnames are a list of variable prefixes. The suffixes are either
saved or taken from `keys()`, depending on the shape of the data.  Remember
this picture:

```
       long
    +------------+                   wide
    | i  j  stub |                  +----------------+
    |------------|                  | i  stub1 stub2 |
    | 1  1   4.1 |     greshape     |----------------|
    | 1  2   4.5 |   <---------->   | 1    4.1   4.5 |
    | 2  1   3.3 |                  | 2    3.3   3.0 |
    | 2  2   3.0 |                  +----------------+
    +------------+

    To go from long to wide:

                                            j existing variable
                                           /
            greshape wide stub, by(i) keys(j)

    To go from wide to long:

            greshape long stub, by(i) keys(j)
                                           \
                                            j new variable(s)
```

Additionally, the user can `reshape` in the style of R's `tidyr` package.
To go from long to wide:

```
    greshape spread varlist, keys(j)
```

Note that spread (and gather) both require variable names, not prefixes.
Further, all variables not specified in the `reshape` are assumed to be
part of `by()` and the new variables are simply named after the values of
`keys()`. From wide to long:

```
    greshape gather varlist, keys(j) values(values)
```

This does not check for duplicates or sorts the data. Variables not
named are assumed to be part of `by()`).  The values of the variables in
varlist are saved in `values()`, with their names saved in `keys()`.

`reshape`'s extended syntax is not supported; that is, `greshape` does
not implement "reshape mode" where a user can type `reshape long` or
`reshape wide` after the first reshape. This syntax is cumbersome to
support and prone to errors given the degree to which `greshape` had to
rewrite the base code. This also means the "advanced" commands are not
supported, including: `clear`, `error`, `query`, `i`, `j`, `xij`, and `xi`.

Options
-------

### Long and Wide

**Long only**
**Wide only**
**Wide and long**

- `by(varlist)`   (Required) Use varlist as the ID variables (alias `i()`).
- `keys(varname)` Wide to long: varname, new variable to store stub suffixes (default `_j`; alias `j()`).
- `string`        Whether to allow for string matches to each stub
- `match(str)`    Where to match levels of `keys()` in stub (default `@`). Use `match(regex)`
                  for complex matches (see [examples below](#complex-stub-matches) for details).

**Wide only**

- `by(varlist)`       (Required) Use varlist as the ID variables (alias `i()`).
- `keys(varlist)`     (Required) Long to wide: varlist, existing variable with stub suffixes (alias `j()`).
- `colsepparate(str)` Column separator when multiple variables are passed to `j()`.
- `match(str)`        Where to replace the levels of `keys()` in stub (default `@`).

**Wide and long**

- `fast`         Do not wrap the reshape in preserve/restore pairs.
- `unsorted`     Leave the data unsorted (faster). Original sort order is not preserved.
- `nodupcheck`   Wide to long, allow duplicate `by()` values (faster).
- `nomisscheck`  Long to wide, allow missing values and/or leading blanks in `keys()` (faster).
- `nochecks`     This is equivalent to all 4 of the above options (fastest).
- `xi(drop)`     Drop variables not in the reshape, `by()`, or `keys()`.

### Gather and Spread

**Gather only**

- `values(varname)`   (Required) Store values in varname.
- `keys(varname)`     Wide to long: varname, new variable to store variable names (default `_key`).
- `uselabels[(str)]`  Store variable labels instead of their names. Optionally specify a varlist
                      with the variables to do this for (or `uselabels(varlist, exclude)`
                      to specify the variables _not_ to do this for).

**Spread only**

- `keys(varlist)`     (Required) Long to wide: varlist, existing variable with variable names.

**Gather and Spread**

- `by(varlist)`       check varlist are the ID variables. Throws an error otherwise.
- `xi(drop)`          Drop variables not in the reshape or in `by()`. That is,
                      if `by()` is specified then drop variables that have not
                      been explicitly named.
- `fast`              Do not wrap the reshape in preserve/restore pairs.

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

`greshape` converts data from wide to long form and vice versa.  It is a
fast alternative to `reshape`, and it additionally implements `greshape spread`
and `greshape gather`, both of which are marginally faster and in
the style of the equivalent R commands from `tidyr`.

It is well-known that `reshape` is a slow command, and there are several
alternatives that I have encountered to speed up `reshape`, including:
`fastreshape`, `parallel`, `sreshape`, and various custom solutions
(e.g. [here](http://www.nber.org/stata/efficient/reshape.html)). While
these alternatives are slower than `greshape`, the speed gains are not
uniform.

If `j()` is numeric, the data is already sorted by `i()`, and there are
not too may variables to reshape, then `fastreshape` comes closest to
achieving comparable speeds to `greshape`. Under most circumstances,
however, `greshape` is typically 20-60% faster than `fastreshape` on
sorted data, and up to 90% faster if `j()` has string values _or_ if the
data is unsorted (by default `greshape` will output the data in the
correct sort order). In other words, `greshape`'s speed gains are very
robust, while other solutions' are not.

!!! note "Note"
    `greshape` relies on temporary files written to your disk storage to
    reshape the data in memory. While this might deteriorate performance
    for particularly large reshapes, the speed gains are large enough
    that `greshape` should still be faster than its Stata counterpart.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/greshape.do)

### Basic usage

Syntax is largely analogous to `reshape`

```stata
webuse reshape1, clear
list
greshape long inc ue, i(id) j(year)
list, sepby(id)
greshape  inc ue, i(id) j(year)
```

However, the preferred `greshape` parlance is `by` for `i` and `keys`
for `j`, which I think is clearer.

```stata
webuse reshape1, clear
list
greshape long inc ue, by(id) keys(year)
list, sepby(id)
greshape  inc ue, by(id) keys(year)
```

Allow string values in j; the option `string` is not necessary for
long to wide:

```stata
webuse reshape4, clear
list
greshape long inc, by(id) keys(sex) string
list, sepby(id)
greshape wide inc, by(id) keys(sex)
```

Multiple j values:

```stata
webuse reshape5, clear
list
greshape wide inc, by(hid) keys(year sex) cols(_)
l
```

### Complex stub matches

`@` syntax is supported and can be modified via `match()`

```stata
webuse reshape3, clear
list
greshape long inc@r ue, by(id) keys(year)
list, sepby(id)
greshape wide inc@r ue, by(id) keys(year)
list

webuse reshape3, clear
list
greshape long inc[year]r ue, by(id) keys(year) match([year])
list, sepby(id)
greshape wide inc[year]r ue, by(id) keys(year) match([year])
list
```

Note that stata variable syntax is only supported for long to wide,
and cannot be combined with `@` syntax. For complex pattern matching
from wide to long, use `match(regex)` or `match(ustrregex)`. With
regex, the first group is taken to be the group to match (this can be
modified via `/#`, e.g. `r(e)g(e)x/2` matches the 2nd group). With
ustrregex, every part of the match outside lookarounds is matched (e.g.
`(?<=(foo|bar)[0-9]{0,2}stub)([0-9]+)(?=alice|bob)` matches `([0-9]+)`).

```stata
webuse reshape3, clear
greshape long inc([0-9]+).+ (ue)(.+)/2, by(id) keys(year) match(regex)
greshape wide inc@r u?, by(id) keys(year)
```

Note for `ustrregex` (Stata 14+ only), Stata does not support matches of
indeterminate length inside lookarounds (this is a limitation that is
not uncommon across several regex implementations).

### Gather and Spread

```stata
webuse reshape1, clear
greshape gather inc* ue*, values(values) keys(varaible)
greshape spread values, keys(varaible)
```

### Fine-grain control over error checks

By default, greshape throws an error with problematic observations,
but this can be ignored.

```stata
webuse reshape2, clear
list
cap noi greshape long inc, by(id) keys(year)
preserve
cap noi greshape long inc, by(id) keys(year) nodupcheck
restore

gen j = string(_n) + " "
cap noi greshape wide sex inc*, by(id) keys(j)
preserve
cap noi greshape wide sex inc*, by(id) keys(j) nomisscheck
restore

drop j
gen j = _n
replace j = . in 1
cap noi greshape wide sex inc*, by(id) keys(j)
preserve
cap noi greshape wide sex inc*, by(id) keys(j) nomisscheck
restore
```

Not all errors are solvable, however. For example, xi variables must
be unique by i, and j vannot define duplicate values.

```stata
cap noi greshape wide inc*, by(id) keys(j) nochecks

drop j
gen j = string(_n) + " "
replace j = "1." in 2
cap noi greshape wide inc*, by(id) keys(j) nochecks
```

There is no fix for j defining non-unique names, since variable names
must be unique. In this case you must manually clean your data before
reshaping.  However, `greshape` allows the user to specify that xi
variables can be dropped (i.e. nonly explicitly named variables are
kept):

```stata
drop j
gen j = _n
cap noi greshape wide inc*, by(id) keys(j) xi(drop) nochecks
```
