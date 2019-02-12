* Basic usage
* -----------

* Syntax is largely analogous to `reshape`

webuse reshape1, clear
list
greshape long inc ue, i(id) keys(year)
list, sepby(id)
greshape  inc ue, i(id) keys(year)

* However, the preferred `greshape` parlance is `by` for `i` and `keys`
* for `j`, which I think is clearer.

webuse reshape1, clear
list
greshape long inc ue, by(id) keys(year)
list, sepby(id)
greshape  inc ue, by(id) keys(year)

* `@` syntax is not (yet) supported, but working around it is not too
* difficult.

webuse reshape3, clear
list
cap noi greshape long inc@r ue, by(id) keys(year)
rename inc*r incr*
cap noi greshape long incr ue, by(id) keys(year)
list, sepby(id)
greshape wide incr ue, by(id) keys(year)
rename incr* inc*r

* Allow string values in j; the option `string` is not necessary for
* long to wide:

webuse reshape4, clear
list
greshape long inc, by(id) keys(sex) string
list, sepby(id)
greshape wide inc, by(id) keys(sex)

* Multiple j values:

webuse reshape5, clear
list
greshape wide inc, by(hid) keys(year sex) cols(_)
l

* Gather and Spread
* -----------------

webuse reshape1, clear
greshape gather inc* ue*, values(values) key(varaible)
greshape spread values, key(varaible)

* Fine-grain control over error checks
* ------------------------------------

* By default, greshape throws an error with problematic observations,
* but this can be ignored.

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

* Not all errors are solvable, however. For example, xi variables must
* be unique by i, and j vannot define duplicate values.

cap noi greshape wide inc*, by(id) keys(j) nochecks

drop j
gen j = string(_n) + " "
replace j = "1." in 2
cap noi greshape wide inc*, by(id) keys(j) nochecks

* There is no fix for j defining non-unique names, since variable names
* must be unique. In this case you must manually clean your data before
* reshaping.  However, `greshape` allows the user to specify that xi
* variables can be dropped (i.e. nonly explicitly named variables are kept):

drop j
gen j = _n
cap noi greshape wide inc*, by(id) keys(j) xi(drop) nochecks
