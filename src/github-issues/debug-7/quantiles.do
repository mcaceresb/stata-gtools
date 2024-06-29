clear
set obs 1000
gen x  = rnormal()
gen e  = rnormal()
gen fe = mod(_n, 10)
gen y  = 3 * x^2 - x + fe + e
gquantiles xbins = x, nq(252) xtile replace
count if mi(xbins)
* I'm not sure what happened but this seems fine?
