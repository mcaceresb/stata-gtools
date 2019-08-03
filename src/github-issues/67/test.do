* Create simulated data
clear all
* set obs 10000000
set obs 1000000
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
tempvar t1 t2
gegen `t1' = group(x), counts(`t2')
gen rank2_x = `t1' + `t2' / 2 - 0.5
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
* egen rank_x = rank(x), track
timer off 3

* With gtools 
timer on 4
gegen rank2_x = group(x)
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
* egen rank_x = rank(x), field
timer off 5

* With gtools
timer on 6
tempvar t1 t2
gegen `t1' = group(x), counts(`t2')
gen rank2_x = `r(N)' - `t1' - `t2' + 2
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
