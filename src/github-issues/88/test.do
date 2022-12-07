clear
set obs 5
g units=1
g weight=5

gegen total  =total(units) [w=weight]
gegen totalf =total(units) [fw=weight]
gegen totalp =total(units) [pw=weight]
sum total*

collapse (sum) units [aw=weight]
disp units

clear
set obs 5
g units=_n
g weight=_n
gegen total =total(units) [w=weight]
gegen totalu=total(units)
sum total*
