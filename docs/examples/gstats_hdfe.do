sysuse auto, clear
gstats hdfe demean_price = price, absorb(foreign)
gstats hdfe hdfe_price   = price, absorb(foreign rep78)
assert mi(hdfe_price) if mi(rep78)
gstats hdfe hdfe_price   = price, absorb(foreign rep78) replace absorbmissing
assert !mi(hdfe_price)

gstats hdfe price mpg [aw = rep78], by(foreign) absorb(rep78 headroom) gen(v1 v2) mata
mata GtoolsByLevels.desc()
mata GtoolsByLevels.nj
mata GtoolsByLevels.njabsorb

gstats hdfe price mpg, absorb(foreign rep78) prefix(res_)
gstats hdfe price mpg, absorb(foreign rep78) replace
assert price == res_price if !mi(rep78)
assert mpg   == res_mpg   if !mi(rep78)

gstats hdfe price mpg, absorb(foreign make) replace
assert abs(price) < 1e-8 if !mi(rep78)
assert abs(price) < 1e-8 if !mi(rep78)

* Basic Benchmark
* ---------------

clear
local N 10000000
set obs `N'
gen g1 = int(runiform() * 10000)
gen g2 = int(runiform() * 100)
gen g3 = int(runiform() * 10)
gen x  = rnormal()

timer clear
timer on 1
gstats hdfe x1 = x, absorb(g1 g2 g3) algorithm(squarem) bench(2)
disp r(feval)
timer off 1

timer on 2
gstats hdfe x2 = x, absorb(g1 g2 g3) algorithm(cg) bench(2)
disp r(feval)
timer off 2

timer on 3
gstats hdfe x3 = x, absorb(g1 g2 g3) algorithm(map) bench(2)
disp r(feval)
timer off 3

timer on 4
gstats hdfe x4 = x, absorb(g1 g2 g3) algorithm(it) bench(2)
disp r(feval)
timer off 4

timer on 5
* equivalent to cg
qui reghdfe x, absorb(g1 g2 g3) resid(x5) acceleration(cg)
timer off 5

timer on 6
* equivalent to map
qui reghdfe x, absorb(g1 g2 g3) resid(x6) acceleration(none)
timer off 6

assert reldif(x1, x2) < 1e-6
assert reldif(x1, x3) < 1e-6
assert reldif(x1, x4) < 1e-6
assert reldif(x1, x5) < 1e-6
assert reldif(x1, x6) < 1e-6

timer list

*    1:      2.73 /        1 =       2.7260
*    2:      2.94 /        1 =       2.9430
*    3:      2.46 /        1 =       2.4620
*    4:      2.90 /        1 =       2.8980
*    5:     41.24 /        1 =      41.2390
*    6:     44.05 /        1 =      44.0450
