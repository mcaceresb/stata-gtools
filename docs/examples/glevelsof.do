sysuse auto, clear
glevelsof rep78
qui glevelsof rep78, miss local(mylevs)
display "`mylevs'"
glevelsof rep78, sep(,)


************************************
*  De-duplicating a variable list  *
************************************

* `glevelsof` can store the unique levels of a varlist. This is
* specially useful when the user wants to obtain the unique levels but
* runs up against the stata macro variable limit.

set seed 42
clear
set obs 100000
gen x = "a long string appeared" + string(mod(_n, 10000))
gen y = int(10 * runiform())
glevelsof x
glevelsof x, gen(uniq_) nolocal
gisid uniq_* in 1 / `r(J)'

* If the user prefers to work with mata, simply pass the option
* `matasave[(name)]`. With mixed-types, numbers and strings are
* stored in separate matrices as well as a single printed matrix,
* but the latter can be suppressed to save memory.

glevelsof x y, mata(xy) nolocal
glevelsof x,   mata(x)  nolocal silent

mata xy.desc()
mata x.desc()

* The user can also replace the source variables if need be. This is
* faster and saves memory, but it dispenses with the original variables.

glevelsof x y, gen(, replace) nolocal
l in `r(J)'
l in `=_N'


*******************
*  Number format  *
*******************

* `levelsof` by default shows many significant digits for numerical variables.

sysuse auto, clear
replace headroom = headroom + 0.1
levelsof headroom
glevelsof headroom

* This is cumbersome. You can specify a number format to compress this:
glevelsof headroom, numfmt(%.3g)


************************
*  Multiple variables  *
************************

* `glevelsof` can parse multiple variables:
local varlist foreign rep78
glevelsof `varlist', sep("|") colsep(", ")

* If you know a bit of mata, you can parse this string!
mata:
string scalar function unquote_str(string scalar quoted_str)
{
    if ( substr(quoted_str, 1, 1) == `"""' ) {
        quoted_str = substr(quoted_str, 2, strlen(quoted_str) - 2)
    }
    else if (substr(quoted_str, 1, 2) == "`" + `"""') {
        quoted_str = substr(quoted_str, 3, strlen(quoted_str) - 4)
    }
    return (quoted_str);
}

t = tokeninit(`"`r(sep)'"', (""), (`""""', `"`""'"'), 1)
tokenset(t, `"`r(levels)'"')

rows = tokengetall(t)
for (i = 1; i <= cols(rows); i++) {
    rows[i] = unquote_str(rows[i]);
}

levels = J(cols(rows), `:list sizeof varlist', "")

t = tokeninit(`"`r(colsep)'"', (""), (`""""', `"`""'"'), 1)
for (i = 1; i <= cols(rows); i++) {
    tokenset(t, rows[i])
    levels[i, .] = tokengetall(t)
    for (k = 1; k <= `:list sizeof varlist'; k++) {
        levels[i, k] = unquote_str(levels[i, k])
    }
}
end

mata: levels

* While this looks cumbersome, this mechanism is used internally by
* `gtoplevelsof` to display its results.
