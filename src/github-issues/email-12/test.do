clear all
set obs 100000

gen x = rnormal()
gen n = round(_n/10)

* pause on
* pause
*
* forvalues x = 1/100000{
*     di "`x'"
*     gcollapse (max) maxx = x, by(n) merge
*     drop maxx
* }

* forvalues x = 1 / 100{
*     di "`x'"
*     gcollapse (max) maxx = x, by(n) merge
*     drop maxx
* }
