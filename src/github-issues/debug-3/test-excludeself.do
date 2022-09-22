clear
set obs 15
gen x = _n
gen y = mod(_n, 2)
replace y = 2 if _n > 10
replace x = . in 12
gstats transform (range mean . .) z = x, excludeself by(y) replace
