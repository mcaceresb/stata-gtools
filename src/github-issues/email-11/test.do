sysuse auto, clear
by foreign:  egen _mean1 = mean(price - price[1])
by foreign: gegen _mean2 = mean(price - price[1])
gen zz = abs((_mean1 - _mean2) / _mean1)
gstats sum zz

capture program drop test
program define test, byable(onecall)
disp _by(), "`_byvars'"
desc
end
test
by foreign: test
bysort mpg: test
by foreign (price), sort: test

clear
set obs 10
gen var = mod(_n, 3)
gen y   = _n
gen u   = runiform()
cap noi by var: gegen x = mean(max(y, y[1]))
by var (u), sort: gegen x = mean(max(y, y[1]))
sort y
bys var (u): gegen z = mean(max(y, y[1]))
bys var (u):  egen w = mean(max(y, y[1]))
assert x == z
assert x == w
