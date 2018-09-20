!clear
clear
set more off
graph drop _all

set seed 1
set obs 20
g x = _n
expand 500

* Case 1: - collapsed means and SDs from gcollapse in line 36 are zero
* g y = .01*(x)^1.2 + .1*invnorm(uniform())
* Case 2: - Now the collapsed means aren't zero but wrong
g y = .01*(x)^1.2 + invnorm(uniform())

preserve
    gcollapse (count) obsy=y (sd) sdy=y (mean) meany=y, by(x)
    l
restore
    * replace y = int(y)
    gcollapse (sd) sdy=y (mean) meany=y , by(x)
    l
