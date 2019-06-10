* Basic usage
* -----------

* Syntax is largely analogous to `gcollapse`

sysuse auto, clear

gegen norm_price = normalize(price),   by(foreign)
gegen std_price  = standardize(price), by(foreign)
gegen dm_price   = demean(price),      by(foreign)

gstats transform (normalize) norm_mpg = mpg (demean) dm_mpg = mpg, by(foreign) replace
gstats transform (demean) mpg (normalize) price, by(foreign) replace
gstats transform (demean) mpg (normalize) xx = price [w = rep78], by(foreign) auto(#stat#_#source#)

* Moving statistics
* -----------------

* Note the moving window is defined relative to the current observation.

clear
set obs 20
gen g = _n > 10
gen x = _n
gen w = mod(_n, 7)

gegen x1 = moving_mean(x), window(-2 2) by(g)
gstats transform (moving mean -1 3) x2 = x, by(g)
gstats transform (moving sd -4 .) x3 = x (moving p75) x4 = x (moving select3) x5 = x, by(g) window(-3 3)
l

drop x?
gegen x1 = moving_mean(x) [fw = w], window(-2 2) by(g)
gstats transform (moving mean -1 3) x2 = x [aw = w], by(g)
gstats transform (moving sd -4 .) x3 = x (moving p75) x4 = x [pw = w / 7], by(g) window(-3 3)
l
