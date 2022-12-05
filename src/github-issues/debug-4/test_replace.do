***********************************************************************
*                                                                     *
*                              Debugging                              *
*                                                                     *
***********************************************************************

* It seems replace is working correctly?  I _think_ this is replacing
* the entire variable and I initialize the internal object with missing
* values?

clear
set obs 10
gen x = _n
gegen m1 = mean(x)
gegen m2 = mean(x) in 3/6
gegen m3 = mean(x) if _n > 5
l, sep(0)
gegen m3 = mean(x) in 4/7, replace
gegen m2 = mean(x) if _n < 5, replace
l, sep(0)
gcollapse (mean) m1 = x m2 = x if _n == 4, merge replace
l, sep(0)

gstats transform (demean) m1 = x (moving mean -3 .) m2 = x  in 2/9, replace
l, sep(0)

* Check weighted
clear
set obs 10
gen x = _n
gegen m1 = mean(x) [w=1]
gegen m2 = mean(x) in 3/6 [w=1]
gegen m3 = mean(x) if _n > 5 [w=1]
l, sep(0)
gegen m3 = mean(x) in 4/7 [w=1], replace
gegen m2 = mean(x) if _n < 5 [w=1], replace
l, sep(0)
gcollapse (mean) m1 = x m2 = x if _n == 4 [w=1], merge replace
l, sep(0)

* Check weighted
global GTOOLS_BETA = 1
clear
set obs 10
gen x = _n
gen g = mod(_n, 2)
gstats hdfe h1=x, absorb(g)
l, sep(0)
gstats hdfe h1=x if g, absorb(g) replace
l, sep(0)
gegen h1=mean(x) if g, by(g) replace
l, sep(0)
gegen h1=mean(x), by(g) replace
gegen h1=mean(x) if g [w=x], by(g) replace
l, sep(0)
gstats transform (demean) h1 = x if g, by(g) replace
l, sep(0)
gegen h1=mean(x), by(g) replace
gstats winsor x if !g, gen(h1) replace
l, sep(0)
gegen h1=mean(x), by(g) replace
gstats transform (demean) h1 = x in 3/8, by(g) replace
l, sep(0)

***********************************************************************
*                                                                     *
*                             noinit test                             *
*                                                                     *
***********************************************************************

clear
set obs 11
gen x = _n
gen g = _n < 5
l
gegen x = min(x)  if  g, replace noinit
l
gegen x = mean(x) if !g, replace noinit
l

gegen x = mean(x), by(g) replace
    l
gegen x = mean(x) if g, replace
    l

replace x = _n
l
gegen x = min(x)  in 1/5, replace noinit
l
gegen x = mean(x) in 7/9, replace noinit
l

replace x = _n
l
gcollapse (p25) x if g, merge replace noinit
l
gcollapse (select4) x if !g, merge replace noinit
l

replace x = _n
gcollapse (p25) x, merge replace by(g)
l
replace x = _n
gcollapse (select4) x, merge replace by(g)
l

replace x = _n
l
gcollapse (p25) x in 6/10, merge replace noinit
l
gcollapse (select4) x in 1/4, merge replace noinit
l

replace x = _n
l
gstats transform (demean) x if g, noinit replace
gstats transform (moving mean -2 0) x if !g, noinit replace
l

replace x = _n
gstats transform (moving mean -2 0) x, by(g) replace
l
replace x = _n
gstats transform (demean) x, by(g) replace
l

global GTOOLS_BETA = 1
replace x = _n
gstats hdfe x, absorb(g) replace
l
replace x = _n
gstats hdfe x if g, absorb(g) replace
l
replace x = _n
gstats hdfe x if !g, absorb(g) replace noinit
l

replace x = _n
gstats winsor x, replace by(g) trim cuts(40 60)
l
replace x = _n
gstats winsor x if g, replace by(g) trim cuts(40 60) noinit
l
replace x = _n
gstats winsor x if !g, replace by(g) trim cuts(40 60) noinit
l
replace x = _n
gstats winsor x if g, replace by(g) trim cuts(40 60)
gstats winsor x, replace by(g) trim cuts(40 60)
l
