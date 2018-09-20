clear
set more off
graph drop _all

set seed 1 // the seed doesn't matter as far as I can tell
set obs 20
g x = _n
expand 500

// Case 1: - collapsed means and SDs from gcollapse in line 36 are zero
g y = .01*(x)^1.2 + .1*invnorm(uniform())
// Case 2: - Now the collapsed means aren't zero but wrong
// g y = .01*(x)^1.2 + invnorm(uniform())

preserve
collapse (count) obsy=y (sd) sdy=y (mean) meany=y , by(x)
foreach v in obsy sdy meany {
	rename `v' `v'_stata_builtin
	label var `v' ""
}
tempfile 1
save `1'
restore

preserve
collapse (count) obsy=y (sd) sdy=y (mean) meany=y , by(x)
foreach v in obsy sdy meany {
	rename `v' `v'_ftools
	label var `v' ""
}
tempfile 2
save `2'
restore

preserve
gcollapse (count) obsy=y (sd) sdy=y (mean) meany=y , by(x)
foreach v in obsy sdy meany {
	rename `v' `v'_gtools
	label var `v' ""
}
tempfile 3
save `3'
restore


preserve
gcollapse (sd) sdy=y (mean) meany=y , by(x)
foreach v in  sdy meany {
	rename `v' `v'_gtools1
	label var `v' ""
}
tempfile 4
save `4'
restore


use `1', clear
merge 1:1 x using `2'
drop _merge
merge 1:1 x using `3'
drop _merge
merge 1:1 x using `4'
drop _merge
order x  meany* sd* obs*
br
local i 100
twoway (line meany_s x) (line meany_f x) ///
	(line meany_gtools x) (line meany_gtools1 x) , name(g`i++')


foreach var of varlist mean* {
	twoway scatter `var' meany_stata, name(g`i++')
}
