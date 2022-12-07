* NOTE: gglm is in beta. To enable enable beta features, define
*
*     global GTOOLS_BETA = 1

* Showcase
* --------

webuse lbw, clear
gglm low age lwt smoke ptl ht ui, absorb(race) family(binomial)
mata GtoolsLogit.print()

gen w = _n
gglm low age lwt smoke ptl ht ui [fw = w], absorb(race) family(binomial)
mata GtoolsLogit.print()

webuse ships, clear
expand 2
gen by = 1.5 - (_n < _N / 2)
gen w = _n
gen _co_75_79  = co_75_79
qui tab ship, gen(_s)

gglm accident op_75_79 co_65_69 co_70_74 co_75_79 [fw = w], robust family(poisson)
mata GtoolsPoisson.print()

gglm accident op_75_79 co_65_69 co_70_74 co_75_79 _co_75_79 [pw = w], cluster(ship) family(poisson)
mata GtoolsPoisson.print()

gglm accident op_75_79 co_65_69 co_70_74 co_75_79 _s*, absorb(ship) cluster(ship) family(poisson)
mata GtoolsPoisson.print()

gglm accident op_75_79 co_65_69 co_70_74 co_75_79, by(by) absorb(ship) robust family(poisson)
mata GtoolsPoisson.print()

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
gglm l x1 x2, absorb(g1 g2 g3) mata(greg) family(poisson)
timer off 1
mata greg.print()
timer on 2
ppmlhdfe l x1 x2, absorb(g1 g2 g3)
timer off 2

timer on 3
gglm l x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg) family(poisson)
timer off 3
mata greg.print()
timer on 4
ppmlhdfe l x1 x2, absorb(g1 g2 g3) vce(cluster g4)
timer off 4

timer list

*    1:      3.22 /        1 =       3.2160
*    2:     29.64 /        1 =      29.6380
*    3:      3.31 /        1 =       3.3140
*    4:     31.32 /        1 =      31.3190
