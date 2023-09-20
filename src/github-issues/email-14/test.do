use ./gtools_bug.dta, clear
gegen a=sd(g12) [aw=share], by(time) replace
gegen b=sd(g36) [aw=share], by(time) replace
gegen s=total(share), by(time)
