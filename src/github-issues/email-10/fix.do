clear
set more off
set seed 1
set obs 2
g y = 1.23
g o = 9
l

* clear
* set obs 10000000
* gen x = abs(runiform())
* gen y = abs(rnormal())
* set rmsg on
* sum x y, meanonly
* global GTOOLS_CALLER ghash
* _gtools_internal, sumcheck(x y)
* matrix list r(sumcheck)
* sum x y

preserve
    gcollapse (count) cy = y (first) fy = y (mean) o, freq(z)
    l
restore, preserve
    gcollapse (count) y (first) fy = y (nunique) o, freq(z)
    l
restore, preserve
    gcollapse (first) fy = y (count) y  (mean) o, freq(z)
    l
restore, preserve
    gcollapse (first) fy = y (count) cy = y (count) o, freq(z)
    l
restore
