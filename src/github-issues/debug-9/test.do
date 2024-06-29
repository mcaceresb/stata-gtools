exit, clear
./build.py --replace
stata16-mp
global GTOOLS_BETA = 1
global GTOOLS_GREGTABLE = 1
sysuse auto, clear
gen _mpg = mpg

greg price mpg _mpg, absorb(rep78) savecons
reghdfe price mpg _mpg, absorb(rep78)
mata GtoolsRegress.consest

greg price mpg _mpg [aw=rep78], absorb(rep78) savecons
reghdfe price mpg _mpg [aw=rep78], absorb(rep78)
mata GtoolsRegress.consest

greg price mpg _mpg , absorb(rep78 headroom) savecons
reghdfe price mpg _mpg , absorb(rep78 headroom)
mata GtoolsRegress.consest

* Somehow this fails but generally works OK ):
sysuse auto, clear
foreach var in  _a* _b* _c* _d* _e* _h* {
    cap drop `var'
}
reghdfe price mpg, absorb(_aa=rep78 _bb=headroom) resid(_hh)
greg price mpg [aw=weight], absorb(rep78 headroom) savecons alphas(_cc _dd) resid(_ee) replace algorithm(it)
greg price mpg [aw=weight], absorb(rep78 headroom) savecons alphas(_cc _dd) resid(_ee) replace algorithm(squarem)
greg price mpg [aw=weight], absorb(rep78 headroom) savecons alphas(_cc _dd) resid(_ee) replace algorithm(cg)
mata GtoolsRegress.consest
mata reldif(12225.5, GtoolsRegress.consest)
gstats tab _*, s(mean)

    cap drop _*
    reghdfe price [aw=weight], absorb(rep78 headroom) resid(_hdfe_price)
    reghdfe mpg   [aw=weight], absorb(rep78 headroom) resid(_hdfe_mpg)
    gstats hdfe price mpg [aw=weight], absorb(rep78 headroom) gen(_g_price _g_mpg) replace
    reg _hdfe_price _g_price
    reg _hdfe_mpg   _g_mpg
    gstats tab _* [aw=weight], s(mean)
    reg _hdfe_price _hdfe_mpg [aw=weight]
    predict _zz
    reg _g_price _g_mpg [aw=weight]

* for example all these are fine
clear
set obs 100000
gen group = mod(_n, 2)
gen double f1 = round(12.2 * mod(_n, 3),       0.1) if runiform() > 0.05
gen double f2 = round(20 * c(pi) * mod(_n, 5), 0.1) if runiform() > 0.05
gen double f3 = round(9.72 * mod(_n, 41),      0.1) if runiform() > 0.05
gen double x  = round(mod(_n, 100),            0.1) if runiform() > 0.05
gen double y  = 123 * x + f1 + f2 + round(10000 * runiform(), 1)
cap drop _*
reghdfe y x if group == 1, absorb(_aa=f1 _bb=f2 _cc=f3) resid(_hh)
reghdfe y x if group == 0, absorb(    f1     f2     f3)
greg y x, absorb(f1 f2 f3) savecons alphas(_dd _ee _ff) resid(_gg) replace by(group)
mata GtoolsRegress.consest \ GtoolsRegress.r2
gstats tab _*, s(mean)
reg _aa _dd
reg _bb _ee
reg _cc _ff
reg _hh _gg
