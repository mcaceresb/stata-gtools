* Basic usage
* -----------

* Syntax is largely analogous to `reshape`

webuse reshape1, clear
list
greshape long inc ue, i(id) j(year)
list, sepby(id)
greshape  inc ue, i(id) j(year)

* `@` syntax is not (yet) supported, but working around it is not too
* difficult.

webuse reshape3, clear
list
cap noi greshape long inc@r ue, i(id) j(year)
rename inc*r incr*
cap noi greshape long incr ue, i(id) j(year)
list, sepby(id)
greshape wide incr ue, i(id) j(year)
rename incr* inc*r

* Allow string values in j; the option `string` is not necessary for
* long to wide:

webuse reshape4, clear
list
greshape long inc, i(id) j(sex) string
list, sepby(id)
greshape wide inc, i(id) j(sex)

* Multiple j values:

webuse reshape5, clear
list
greshape wide inc, i(hid) j(year sex) cols(_)
l

* Gather and Spread
* -----------------

webuse reshape1, clear
greshape gather inc* ue*, values(values) j(varaible)
greshape spread values, j(varaible)

* Fine-grain control over error checks
* ------------------------------------

* By default, greshape throws an error with problematic observations,
* but this can be ignored.

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

* Not all errors are solvable, however. For example, xi variables must
* be unique by i, and j vannot define duplicate values.

cap noi greshape wide inc*, i(id) j(j) nochecks

drop j
gen j = string(_n) + " "
replace j = "1." in 2
cap noi greshape wide inc*, i(id) j(j) nochecks

* There is no fix for j defining non-unique names, since variable names
* must be unique. In this case you must manually clean your data before
* reshaping.  However, `greshape` allows the user to specify that xi
* variables can be dropped (i.e. nonly explicitly named variables are kept):

drop j
gen j = _n
cap noi greshape wide inc*, i(id) j(j) xi(drop) nochecks
