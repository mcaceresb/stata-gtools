clear
set obs 1000
gen double xx = int(100 * runiform()) / 100
gegen yy1 = median(xx)
gegen yy2 = pctile(xx), p(50)
gcollapse (median) zz1 = xx, merge
gcollapse (p50) zz2 = xx, merge
tab yy1 yy2
tab zz1 zz2
gquantiles xx, _pctile
disp r(r1)
