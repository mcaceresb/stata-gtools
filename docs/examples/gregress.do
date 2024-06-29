* NOTE: gregress is in beta. To enable enable beta features, define
*
*     global GTOOLS_BETA = 1
*     global GTOOLS_GREGTABLE = 1

* Showcase
* --------

sysuse auto, clear
gen _mpg  = mpg
qui tab headroom, gen(_h)

greg price mpg
greg price mpg, by(foreign) robust
mata GtoolsRegress.print()

greg price mpg _h* [fw = rep78]
mata GtoolsRegress.print()

greg price mpg _h* [fw = rep78], absorb(headroom)
mata GtoolsRegress.print()

greg price mpg _mpg, cluster(headroom)
greg price mpg _mpg [aw = rep78], by(foreign) absorb(rep78 headroom) cluster(headroom)
mata GtoolsRegress.print()

greg price mpg, mata(coefsOnly, nose)
greg price mpg, mata(seOnly,    nob)
greg price mpg, mata(nothing,   nob nose)

mata coefsOnly.print()
mata seOnly.print()
mata nothing.print()

greg price mpg, prefix(b(_b_)) replace
greg price mpg, prefix(se(_se_)) replace
greg price mpg _mpg, absorb(rep78 headroom) prefix(b(_b_) se(_se_) hdfe(_hdfe_)) replace
drop _*

greg price mpg, gen(b(_b_mpg _b_cons))
greg price mpg, gen(se(_se_mpg _se_cons))
greg price mpg, absorb(rep78 headroom) gen(hdfe(_hdfe_price _hdfe_mpg))

* Basic Benchmark
* ---------------

clear
local N 1000000
local G 10000
set obs `N'
gen g1 = int(runiform() * `G')
gen g2 = int(runiform() * `G')
gen g3 = int(runiform() * `G')
gen g4 = int(runiform() * `G')
gen x3 = runiform()
gen x4 = runiform()
gen x1 = x3 + runiform()
gen x2 = x4 + runiform()
gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + g4 + 20 * rnormal()

timer clear
timer on 1
greg y x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.print()
timer on 2
reghdfe y x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
greg y x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.print()
timer on 4
reghdfe y x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 4

timer on 5
greg y x1 x2, by(g4) prefix(b(_b_))
timer off 5
drop _*
timer on 6
asreg y x1 x2, by(g4)
timer off 6
drop _*

timer list

*    1:      0.64 /        1 =       0.6380
*    2:     11.77 /        1 =      11.7730
*    3:      0.91 /        1 =       0.9140
*    4:     15.74 /        1 =      15.7370
*    5:      0.46 /        1 =       0.4570
*    6:      2.09 /        1 =       2.0890
