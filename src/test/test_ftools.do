capture program drop run_one
program run_one
	syntax, by(varlist) data(varlist) stats(namelist) method(string)
	assert inlist("`method'", "sumup", "collapse", "fcol", "fcolp", "tab", "gcol")

	foreach s of local stats {
		loc zip `zip' (`s')
		foreach var of varlist `data' {
			loc zip `zip' `s'_`var'=`var'
		}
	}
	di as text "clist=<`zip'>"

	if ("`method'" == "col"   )  collapse `zip', by(`by') fast
	if ("`method'" == "fcol"  ) fcollapse `zip', by(`by') fast verbose
	if ("`method'" == "fcolp" ) fcollapse `zip', by(`by') fast verbose pool(5)
	if ("`method'" == "gcol"  ) gcollapse `zip', by(`by') fast verbose benchmark
	if ("`method'" == "tab"   ) {
		tab `by', missing nofreq nolabel matrow(foobar)
		noi di rowsof(foobar)
	}
end

capture program drop gen_data
program gen_data
	args n k
	clear
	qui set obs `n'
	noi di "(obs set)"
	loc m = ceil(`n' / 10)
	* set seed 234238921
	* gen long x1 = ceil(uniform()*`m')
	gen long x1   = ceil(uniform() * 10000) * 100
	gen int  x2   = ceil(uniform() * 3000)
	gen byte x3   = ceil(uniform() * 100)
	gen str  x4   = "u" + string(ceil(uniform() * 100), "%5.0f")
	gen long x5   = ceil(uniform() * 5000)
	* compress
	noi di "(Xs set)"
	forv i = 1 / `k' {
		gen double y`i' = 123.456 + runiform()
	}
	loc obs_k = ceil(`c(N)' / 1000)
end

* set segmentsize 128m
* set niceness 10, permanently

* gen_data `:di 1 * 1000 * 1000' 15
* gen_data `:di 5 * 1000 * 1000' 15
* gen_data `:di 20 * 1000 * 1000' 15
gen_data `:di 20 * 1000 * 1000' 6
* loc clist (mean) x1 y1-y3 (median) X1=x1 Y1=y1 Y2=y2 Y3=y3 // (median) x5 (max) z=x5
* set processors 3
* sort `all_vars'
tempfile test_data
save `test_data'

* cd /homes/nber/caceres/gtools/build
cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/build
!cd ..; ./build.py
do gcollapse.ado
* preserve
*     gcollapse (sum) x5 (mean) x5 (sd) x5, by(x3) verbose benchmark
* restore

***********************************************************************
*                             Simple run                              *
***********************************************************************

* preserve
	timer clear
	local by x3
	local stats sum
	* local vars y1-y15
	local vars y1-y6

	di as text "{bf:by    = `by'}"
	di as text "{bf:stats = `stats'}"
	di as text "{bf:vars  = `vars'}"

	local i 0
	local msg

	* loc methods collapse gcol fcol fcolp tab
	loc methods fcol gcol

	foreach method of local methods {
        use `test_data', clear
		local ++i
		di as text "{bf:[`i'] `method'}"
		timer on `i'
		run_one, by(`by') data(`vars') stats(`stats') method(`method')
		timer off `i'
		loc msg "`msg' `i'=`method'"
        tempfile t`i'
        save `t`i''
        * restore, preserve
	}
* restore
di as text "`msg'"
timer list
timer clear

* preserve
    local tol = 1e-6
    use `t2', clear
        local bad_any = 0
        local bad x3
        foreach var of varlist mean_y* median_y* {
            rename `var' c_`var'
        }
        merge 1:1 `bad' using `t1', assert(3)
        foreach var of varlist mean_y* median_y* {
            qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
            if ( `r(N)' > 0 ) {
                gen byte bad_`var' = abs(`var' - c_`var') > `tol'
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            l `bad'
        }
        else {
            di "gcollapse produced identical data to fcollapse (tol = `tol')"
        }
* restore

***********************************************************************
*                          Complex summaries                          *
***********************************************************************

* preserve
	timer clear
	local by x3
    * `" x1 "x2 x3" x4 x5 "'
	loc stats mean median
	local vars y1-y3

	di as text "{bf:by    = `by'}"
	di as text "{bf:stats = `stats'}"
	di as text "{bf:vars  = `vars'}"

	local i 0
	local msg

	* loc methods collapse gcol fcol fcolp tab
	loc methods fcol gcol

	foreach method of local methods {
        use `test_data', clear
		local ++i
		di as text "{bf:[`i'] `method'}"
		timer on `i'
		run_one, by(`by') data(`vars') stats(`stats') method(`method')
		timer off `i'
		loc msg "`msg' `i'=`method'"
        tempfile t`i'
        save `t`i''
        * restore, preserve
	}

* restore
di as text "`msg'"
timer list
timer clear

* preserve
    local tol = 1e-6
    use `t2', clear
        local bad_any = 0
        local bad x3
        foreach var of varlist mean_y* median_y* {
            rename `var' c_`var'
        }
        merge 1:1 `bad' using `t1', assert(3)
        foreach var of varlist mean_y* median_y* {
            qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
            if ( `r(N)' > 0 ) {
                gen byte bad_`var' = abs(`var' - c_`var') > `tol'
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            l `bad'
        }
        else {
            di "gcollapse produced identical data to fcollapse (tol = `tol')"
        }
* restore

* set processors 4

***********************************************************************
*                           Complex groups                            *
***********************************************************************

* preserve
	timer clear
	local by x4
    * `" x1 "x2 x3" x4 x5 "'
	loc stats mean median
	local vars y1-y3

	di as text "{bf:by    = `by'}"
	di as text "{bf:stats = `stats'}"
	di as text "{bf:vars  = `vars'}"

	local i 0
	local msg

	* loc methods collapse gcol fcol fcolp tab
	loc methods fcol gcol

	foreach method of local methods {
        use `test_data', clear
		local ++i
		di as text "{bf:[`i'] `method'}"
		timer on `i'
		run_one, by(`by') data(`vars') stats(`stats') method(`method')
		timer off `i'
		loc msg "`msg' `i'=`method'"
        tempfile t`i'
        save `t`i''
        * restore, preserve
	}

* restore
di as text "`msg'"
timer list
timer clear

* preserve
    local tol = 1e-6
    use `t2', clear
        local bad_any = 0
        local bad x3
        foreach var of varlist sum_y* {
            rename `var' c_`var'
        }
        merge 1:1 `bad' using `t1', assert(3)
        foreach var of varlist sum_y* {
            qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
            if ( `r(N)' > 0 ) {
                gen byte bad_`var' = abs(`var' - c_`var') > `tol'
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            l `bad'
        }
        else {
            di "gcollapse produced identical data to fcollapse (tol = `tol')"
        }
* restore
