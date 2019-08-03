* Create simulated data
clear all
set obs 10000000
gen x = ceil(runiform()*10000)
tempfile data
save `data'

*---------------------------------------------
* egen rank
*---------------------------------------------

* Load simulated data
use `data', clear 

* With egen
timer on 1
egen rank_x = rank(x)
timer off 1

* With gtools
timer on 2
tempvar t1 t2 t3
gen `t1' = x
gdistinct x
fasterxtile `t2' = x, nq(`r(N)') 
gegen `t3' = count(x), by(`t1')
gen rank2_x = `t2' + `t3'/2 - 0.5
timer off 2

* Validate
gen same = rank_x==rank2_x
sum

*---------------------------------------------
* egen rank, track
*---------------------------------------------

* Load simulated data
use `data', clear 

* With egen
timer on 3
egen rank_x = rank(x), track
timer off 3

* With gtools 
timer on 4
tempvar t1 t2 t3
gen `t1' = x
gdistinct x
local Nd = r(ndistinct)
fasterxtile `t2' = x, nq(`r(N)')
gen rank2_x = `t2' 
timer off 4

* Validate
gen same = rank_x==rank2_x
sum 

*---------------------------------------------
* egen rank, field
*---------------------------------------------

* Load simulated data
use `data', clear 

* With egen
timer on 5
egen rank_x = rank(x), field
timer off 5

* With gtools
timer on 6
tempvar t1 t2 t3
gen `t1' = x
gdistinct x
local N = r(N)
fasterxtile `t2' = x, nq(`N') 
gegen `t3' = count(x), by(`t1')
gen rank2_x = `N' - `t2' - `t3' + 2
timer off 6

* Validate they produce same results
gen same = rank_x==rank2_x
sum 

*---------------------------------------------
* Display relative speeds
*---------------------------------------------

* Display benchmark speeds
timer list
timer clear
