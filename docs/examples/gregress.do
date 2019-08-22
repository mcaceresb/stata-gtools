* Showcase
* --------

sysuse auto, clear
greg price mpg
greg price mpg, by(foreign) robust
greg price mpg [fw = rep78], absorb(headroom)
greg price mpg, cluster(headroom)
greg price mpg [fw = rep78], by(foreign) absorb(rep78 headroom) cluster(headroom)

greg price mpg, mata(coefsOnly, nose)
greg price mpg, mata(seOnly,    nob)
greg price mpg, mata(nothing,   nob nose)

greg price mpg, prefix(b(_b_)) replace
greg price mpg, prefix(se(_se_)) replace
greg price mpg, absorb(rep78 headroom) prefix(b(_b_) se(_se_) hdfe(_hdfe_)) replace
drop _*

greg price mpg, gen(b(_b_mpg _b_cons))
greg price mpg, gen(se(_se_mpg _se_cons))
greg price mpg, absorb(rep78 headroom) gen(hdfe(_hdfe_mpg _hdfe_cons))

* Poisson regression
* ------------------

webuse ships, clear
expand 2
gen by = 1.5 - (_n < _N / 2)
gen w = _n
gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 [fw = w], robust
gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 [pw = w], cluster(ship)
gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79, absorb(ship) cluster(ship)
gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79, by(by) absorb(ship) robust

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
gen x1 = runiform()
gen x2 = runiform()
gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + 20 * rnormal()
gen l  = int(0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + 20 * rnormal())

timer clear
timer on 1
greg y x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.b', greg.se'
timer on 2
reghdfe y x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
greg y x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.b', greg.se'
timer on 4
reghdfe y x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 4

timer on 5
gpoisson l x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 5
mata greg.b', greg.se'
timer on 6
ppmlhdfe l x1 x2, absorb(g1 g2 g3)
timer off 6

timer on 7
gpoisson l x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 7
mata greg.b', greg.se'
timer on 8
ppmlhdfe l x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 8

timer on 9
greg y x1 x2, by(g4) prefix(b(_b_))
timer off 9
drop _*
timer on 10
asreg y x1 x2, by(g4)
timer off 10
drop _*

timer list

*    1:      1.30 /        1 =       1.3050
*    2:     15.34 /        1 =      15.3440
*    3:      1.21 /        1 =       1.2080
*    4:     18.48 /        1 =      18.4850
*    5:      9.46 /        1 =       9.4610
*    6:     46.14 /        1 =      46.1400
*    7:      9.08 /        1 =       9.0760
*    8:     51.27 /        1 =      51.2650
*    9:      0.52 /        1 =       0.5220
*   10:      3.21 /        1 =       3.2050
