use /home/mauricio/bulk/data/research/census-correctionalss/raw/ICPSR_07852/DS0001/07852-0001-Data.dta, clear
gtop V1 V2

clear
set obs 100
gen x = mod(_n, 2)
label define x 1 hi
label values x x
gtoplevelsof x

use /home/mauricio/bulk/data/ra/doyle/cms-ambulance/cepr_acs_2005.dta, clear
gtop socp05 if inlist(socp05, 292040, 292041, 292042)
desc *soc*

clear
set obs 1000
gen x = ceil(runiform() * 100)
gtop x
gtop x, missrow
gtop x, ntop(1)
gtop x, ntop(-1)
gtop x, ntop(1000)
gtop x, nooth
replace x = . in 20/43
gtop x
gtop x, missrow
gtop x, nomiss
replace x = .a in 50/100
replace x = .b in 200/300
gtop x
gtop x, nomiss
gunique x if !mi(x)
gtop x, missrow
gtop x, missrow ntop(99)

clear
set obs 1000000
gen x = ceil(runiform() * 10000)
gtop x
