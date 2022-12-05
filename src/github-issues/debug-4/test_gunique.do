clear
set more off
set obs 40
gen g = mod(_n, 5)
gen x = ceil(runiform() * 10)
gunique x, by(g) gen(y)
l
gunique x if inlist(g, 2, 3, 4), by(g) gen(z)
l
gunique x if inlist(g, 2, 3, 4), by(g) gen(z)
gunique x if inlist(g, 1, 2, 3), by(g) gen(z) replace
l

clear
set obs 10
gen x = 1
gegen y = group(x) if x > 1
gegen z = tag(x)   if x > 1
egen _y = group(x) if x > 1
egen _z = tag(x)   if x > 1
l
