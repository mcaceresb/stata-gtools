greshape
========

`greshape` is a fast alternative to `reshape` that additionally
implements the equivalents to R's `spread` and `gather` from `tidyr`.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

Convert data from wide form to long form

<p>
<span class="codespan">
<b>greshape</b> long stubnames, i(varlist) [<a href="#long-and-wide">options</a>]
</span>
</br>
<span class="codespan">
<b>greshape</b> gather varlist, j(varlist) values(varname) [<a href="#gather-and-spread">options</a>]
</span>
</p>

Convert data from long form to wide form

<p>
<span class="codespan">
<b>greshape</b> wide stubnames, i(varlist) j(varname) [<a href="#long-and-wide">options</a>]
</span>
</br>
<span class="codespan">
<b>greshape</b> spread varlist, j(varname) [<a href="#gather-and-spread">options</a>]
</span>
</p>

Syntax Details
--------------


The stubnames are a list of variable prefixes. The suffixes are either
saved or taken from j(), depending on the shape of the data.  Remember
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
            greshape wide stub, i(i) j(j)

    To go from wide to long:

            greshape long stub, i(i) j(j)
                                       \
                                        j new variable
```

Additionally, the user can `reshape` in the style of R's `tidyr` package.
To go from long to wide:

```
greshape spread varlist, j(j)
```

Note that spread (and gather) both require variable names, not prefixes.
Further, all variables not specified in the `reshape` are assumed to be 
part of `i()` and the new variables are simply named after the values of
`j()`. To go from wide to long:

```
greshape gather varlist, j(j) values(values)
```

This does not check for duplicates or sorts the data. Variables not
named are assumed to be part of `i()`).  The values of the variables in
varlist are saved in `values()`, with their names saved in `j()`.

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

- `i(varlist)`  (Required) Use varlist as the ID variables.
- `j(varname)`  Wide to long: varname, new variable to store stub suffixes (default `_j`).
- `string`      Whether to allow for string matches to each stub

**Wide only**

- `i(varlist)`        (Required) Use varlist as the ID variables.
- `j(varlist)`        (Required) Long to wide: varlist, existing variable with stub suffixes.
- `colsepparate(str)` Column separator when multiple variables are passed to `j()`.

**Wide and long**

- `fast`         Do not wrap the reshape in preserve/restore pairs.
- `unsorted`     Leave the data unsorted (faster). Original sort order is not preserved.
- `nodupcheck`   Wide to long, allow duplicate `i()` values (faster).
- `nomisscheck`  Long to wide, allow missing values and/or leading blanks in `j()` (faster).
- `nochecks`     This is equivalent to all 4 of the above options (fastest).
- `xi(drop)`     Drop variables not in the reshape, `i()`, or `j()`.

### Gather and Spread

**Gather only**

- `values(varname)`   (Required) Store values in varname.
- `j(varname)`        Wide to long: varname, new variable to store variable names (default `_j`).
- `string`            Whether to allow for string matches to each stub

**Spread only**

- `j(varlist)`        (Required) Long to wide: varlist, existing variable with variable names.

**Gather and Spread**

- `i(varlist)`        check varlist are the ID variables. Throws an error otherwise.
- `xi(drop)`          Drop variables not in the reshape or in `i()`. That is,
                      if `i()` is specified then drop variables that have not
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
alternatives that I have encountered to speed up `reshape`, incuding:
`fastreshape`, `sreshape`, and various custom solutions (e.g. here).  In my
benchmarks their performance improvements are either minor or not robust
to complex data configurations (e.g. many unsorted groups, many extra
variables, mixed types, etc.).

The only solution that consistently outperforms `reshape` is `parallel`,
which improves performance by 1.5x to 3x, depending on the data
configuration. `greshape` typically speeds up `reshape` anywhere from
5x to 20x, so it is much faster than even the next-fastest known
improvement to `reshape`.

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

`@` syntax is not (yet) supported, but working around it is not too
difficult.

```stata
webuse reshape3, clear
list
cap noi greshape long inc@r ue, i(id) j(year)
rename inc*r incr*
cap noi greshape long incr ue, i(id) j(year)
list, sepby(id)
greshape wide incr ue, i(id) j(year)
rename incr* inc*r
```

Allow string values in j; the option `string` is not necessary for
long to wide:

```stata
webuse reshape4, clear
list
greshape long inc, i(id) j(sex) string
list, sepby(id)
greshape wide inc, i(id) j(sex)
```

Multiple j values:

```stata
webuse reshape5, clear
list
greshape wide inc, i(hid) j(year sex) cols(_)
l
```

### Gather and Spread

```stata
webuse reshape1, clear
greshape gather inc* ue*, values(values) j(varaible)
greshape spread values, j(varaible)
```

### Fine-grain control over error checks

By default, greshape throws an error with problematic observations,
but this can be ignored.

```stata
webuse reshape2, clear
list
cap noi greshape long inc, i(id) j(year)
preserve
cap noi greshape long inc, i(id) j(year) nodupcheck
restore

gen j = string(_n) + " "
cap noi greshape wide sex inc*, i(id) j(j)
preserve
cap noi greshape wide sex inc*, i(id) j(j) nomisscheck
restore

drop j
gen j = _n
replace j = . in 1
cap noi greshape wide sex inc*, i(id) j(j)
preserve
cap noi greshape wide sex inc*, i(id) j(j) nomisscheck
restore
```

Not all errors are solvable, however. For example, xi variables must
be unique by i, and j vannot define duplicate values.

```stata
cap noi greshape wide inc*, i(id) j(j) nochecks

drop j
gen j = string(_n) + " "
replace j = "1." in 2
cap noi greshape wide inc*, i(id) j(j) nochecks
```

There is no fix for j defining non-unique names, since variable names
must be unique. In this case you must manually clean your data before
reshaping.  However, `greshape` allows the user to specify that xi
variables can be dropped (i.e. nonly explicitly named variables are
kept):

```stata
drop j
gen j = _n
cap noi greshape wide inc*, i(id) j(j) xi(drop) nochecks
```
