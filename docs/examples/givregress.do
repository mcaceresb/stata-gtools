* Showcase
* --------

sysuse auto, clear

givregress price (mpg = gear_ratio) weight turn
givregress price (mpg = gear_ratio), cluster(headroom)
givregress price (mpg weight = gear_ratio turn displacement), absorb(rep78 headroom)

givregress price (mpg = gear_ratio) weight [fw = rep78], absorb(headroom)
givregress price (mpg = gear_ratio turn displacement) weight [aw = rep78], by(foreign)

givregress price (mpg = gear_ratio turn) weight, by(foreign) mata(coefsOnly, nose) prefix(b(_b_) se(_se_))
givregress price (mpg weight = gear_ratio turn), mata(seOnly, nob) prefix(hdfe(_hdfe_))
givregress price (mpg weight = gear_ratio turn) displacement, mata(nothing, nob nose)

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
givregress y (x1 x2 = x3 x4), absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.b', greg.se'
timer on 2
ivreghdfe y (x1 x2 = x3 x4), absorb(g1 g2 g3)
timer off 2

timer on 3
givregress y (x1 x2 = x3 x4), absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.b', greg.se'
timer on 4
ivreghdfe y (x1 x2 = x3 x4), absorb(g1 g2 g3) cluster(g4)
timer off 4

timer list

*    1:      3.49 /        1 =       3.4890
*    2:     20.84 /        1 =      20.8410
*    3:      2.02 /        1 =       2.0250
*    4:     30.15 /        1 =      30.1500
