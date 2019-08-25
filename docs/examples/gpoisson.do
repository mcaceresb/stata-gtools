* Showcase
* --------

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
gen x3 = runiform()
gen x4 = runiform()
gen x1 = x3 + runiform()
gen x2 = x4 + runiform()
gen l  = int(0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + g4 + 20 * rnormal())

timer clear
timer on 1
gpoisson l x1 x2, absorb(g1 g2 g3) mata(greg)
timer off 1
mata greg.b', greg.se'
timer on 2
ppmlhdfe l x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
gpoisson l x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
timer off 3
mata greg.b', greg.se'
timer on 4
ppmlhdfe l x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 4

timer list

*    1:      8.66 /        1 =       8.6560
*    2:     46.38 /        1 =      46.3820
*    3:      8.75 /        1 =       8.7470
*    4:     41.51 /        1 =      41.5120
