set varabbrev on
set more off
clear
set obs 10
gen aa = 0
gen bb = runiform()
gen cc = runiform()
gen dd = runiform()
gquantiles a b c d, pctile
