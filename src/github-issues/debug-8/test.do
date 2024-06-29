sysuse auto, clear 
gegen fe = group(rep78)
l fe rep78
gegen fe = group(rep78), missing replace hash(1)
l fe rep78

sysuse auto, clear 
replace make = "" if mod(_n, 7) == 0
gegen fe = group(make)
l fe make
gegen fe = group(make), missing replace
l fe make
