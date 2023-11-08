local nobs 10000000

clear
set obs `nobs'
gen groups = int(runiform() * 1000)
gen rsort  = rnormal()
gen rvar   = rnormal()
gen ix     = _n
sort rsort
local nprocessors = c(processors)
gen e = rnormal()
gen x = rnormal()
gen y = x + e + groups/100
gen g = mod(groups, 10)

set rmsg on
global GTOOLS_BETA=1
global GTOOLS_TABLE=1
greg y x, by(g)
mata GtoolsRegress.b
mata GtoolsRegress.se
