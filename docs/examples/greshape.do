* Basic usage
* -----------

* Syntax is largely analogous to `reshape`

webuse reshape1, clear
list
greshape long inc ue, i(id) keys(year)
list, sepby(id)
greshape wide inc ue, i(id) keys(year)

* However, the preferred `greshape` parlance is `by` for `i` and `keys`
* for `j`, which I think is clearer.

webuse reshape1, clear
list
greshape long inc ue, by(id) keys(year)
list, sepby(id)
greshape wide inc ue, by(id) keys(year)

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

* Complex stub matches
* --------------------

* `@` syntax is supported and can be modified via `match()`

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

* Output variables can be renamed using user-specified patterns.

webuse reshape3, clear
qui greshape long inc@r ue, by(id) keys(year)
qui greshape wide inc[hi]r ue, by(id) keys(year) prefix(year[hi]income #stub#) match([hi])
desc, full

webuse reshape3, clear
qui greshape gather inc*r ue*, values(values) key(variable)
qui greshape spread values, key(variable) prefix(foo@bar_#stub#)
desc, full

* Note that stata variable syntax is only supported for long to wide,
* and cannot be combined with `@` syntax. For complex pattern matching
* from wide to long, use match(regex) or match(ustrregex). With regex,
* the first group is taken to be the group to match (this can be
* modified via /#, e.g. r(e)g(e)x/2 matches the 2nd group). With
* ustrregex, every part of the match outside lookarounds is matched (e.g.
* (?<=(foo|bar)[0-9]{0,2}stub)([0-9]+)(?=alice|bob) matches ([0-9]+)).

webuse reshape3, clear
greshape long inc([0-9]+).+ (ue)(.+)/2, by(id) keys(year) match(regex)
greshape wide inc@r u?, by(id) keys(year)

* Note for `ustrregex` (Stata 14+ only), Stata does not support matches of
* indeterminate length inside lookarounds (this is a limitation that is
* not uncommon across several regex implementations).

* Custom Labels
* -------------

* This was motivated by the labeling convention of `separate`. To mimic
* its labeling, you can do

sysuse auto, clear
local labelformat labelformat(#stubname#, #keyname# == #keyvaluelabel#)
greshape wide mpg, by(make) key(foreign) `labelformat'
desc mpg*

* However, you can use any combination of placeholders. For instance,

sysuse auto, clear
local labelformat labelf(#stublabel#; #keylabel# == #keyvaluelabel#)
greshape wide mpg, by(make) key(foreign) `labelformat'
desc mpg*

* If no label of value labels are available, the program falls back to
* variable name and values

sysuse auto, clear
label drop origin
label var mpg ""
label var foreign ""
local labelformat labelf(#stublabel#; #keylabel# == #keyvaluelabel#)
greshape wide mpg, by(make) key(foreign) `labelformat'
desc mpg*

* Gather and Spread
* -----------------

webuse reshape1, clear
greshape gather inc* ue*, values(values) key(varaible)
greshape spread values, key(varaible)

* Drop missing observations
* -------------------------

* Often it is desireable to drop missing observations when reshaping long.
* For example

clear
set obs 10
gen i = _n
expand i
bys i: gen j = _n
gen x = _n
gen y = -_n
greshape wide x y, by(i) key(j)

* When reshaping this data back into long, we would normally get
* 100 observations, with 45 of them missing. However, we can
* dispense with the additional missing values via `dropmiss`:

greshape long x y, by(i) key(j) dropmiss
assert _N == 55
assert x  == _n
assert y  == -_n

* Fine-grain control over error checks
* ------------------------------------

* By default, greshape throws an error with problematic observations,
* but this can be ignored if so desired.

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
