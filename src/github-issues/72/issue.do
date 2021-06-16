clear
set obs 9
gen id=strofreal(floor((_n+2)/3))

g cat="none" if id=="1"
replace cat="one" if id!="1"

gegen gtot=total(cat!=cat[_n-1]), by(id)
egen tot=total(cat!=cat[_n-1]), by(id)
