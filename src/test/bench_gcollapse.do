***********************************************************************
*                           Data simulation                           *
***********************************************************************

capture program drop bench_sim
program bench_sim
    syntax, [n(int 100) nj(int 10) njsub(int 2) nvars(int 2)]
    local offset = -123456

    clear
    set obs `n'
    gen group  = ceil(`nj' *  _n / _N) + `offset'
    gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    bys group: gen groupsub      = ceil(`njsub' *  _n / _N)
    bys group: gen groupsubfloat = ceil(`njsub' *  _n / _N) + 0.5
    tostring group, gen(groupstr)

    forvalues i = 1 / `nvars' {
        gen x`i' = rnormal()
    }
    gen rsort = runiform() - 0.5
    sort rsort

    replace group = . if runiform() < 0.1
    replace rsort = . if runiform() < 0.1
end

capture program drop bench_sim_ftools
program bench_sim_ftools
	args n k
	clear
	qui set obs `n'
	noi di "(obs set)"
	loc m = ceil(`n' / 10)
	gen long x1  = ceil(uniform() * 10000) * 100
	gen int  x2  = ceil(uniform() * 3000)
	gen byte x3  = ceil(uniform() * 100)
	gen str  x4  = "u" + string(ceil(uniform() * 100), "%5.0f")
	gen long x5  = ceil(uniform() * 5000)
	noi di "(Xs set)"
	forv i = 1 / `k' {
		gen double y`i' = 123.456 + runiform()
	}
	loc obs_k = ceil(`c(N)' / 1000)
end

***********************************************************************
*                              fcollapse                              *
***********************************************************************

capture program drop bench_sample_size
program bench_sample_size
    syntax anything, by(str) [nj(int 10) pct(str) stats(str)]
    if ("`stats'" == "") local stats sum mean sd max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local i = 0
    local N ""
    di "Benchmarking N for nj = `nj'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = 4 / 7 {
        di "    `:di %21.0gc `:di 5 * 10^`k'''"
        local N `N' `:di 5 * 10^`k''
        qui bench_sim, n(`:di 5 * 10^`k'') nj(`nj') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore
    }

    local i = 1
    di "Results varying N for nj = `nj'; by(`by')"
    di "                    N | gcollapse | fcollapse |     ratio "
    foreach nn in `N' {
        local ii = `i' + 1
        di "`:di %21.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`ii'' / `r`i'''"
        local ++i
        local ++i
    }
    timer clear
end

capture program drop bench_group_size
program bench_group_size
    syntax anything, by(str) [pct(str) stats(str) obsexp(int 6)]
    if ("`stats'" == "") local stats sum mean sd max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
    local i = 0
    local N ""
    di "Benchmarking nj for N = `nstr'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = 1 / 6 {
        di "    `:di %21.0gc `:di 10^`k'''"
        local N `N' `:di 5 * 10^`k''
        qui bench_sim, n(`:di 5 * 10^`obsexp'') nj(`:di 10^`k'') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore
    }

    local i = 1
    di "Results varying nj for N = `nstr'; by(`by')"
    di "                   nj | gcollapse | fcollapse |     ratio "
    foreach nn in `N' {
        local ii = `i' + 1
        di "`:di %21.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`ii'' / `r`i'''"
        local ++i
        local ++i
    }
    timer clear
end

* bench_group_size x1 x2,  by(group groupsub)
* bench_group_size x1 x2,  by(group groupsub) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(group groupsub)
* bench_sample_size x1 x2, by(group groupsub) pct(median iqr p23 p77)
* bench_group_size x1 x2,  by(groupstr)
* bench_group_size x1 x2,  by(groupstr) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(groupstr)
* bench_sample_size x1 x2, by(groupstr) pct(median iqr p23 p77)

* bench_ftools // todo
* bench_ftools // todo

* cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/build
* !cd ..; ./build.py
* do gcollapse.ado
* do gtools_tests.do

qui bench_sim, n(`:di 10^6') nj(`:di 10') njsub(2) nvars(2)
local i = 0
preserve
    gcollapse `collapse', by(`by') verbose benchmark
    tempfile f`i'
    save `f`i''
    local ++i
restore

preserve
local tol 1e-6
use `f1', clear
    local bad_any = 0
    local bad `by'
    qui ds *x1 *x2
    foreach var in `r(varlist)'  {
        rename `var' c_`var'
    }
    merge 1:1 `by' using `f0', assert(3)
    foreach varc of varlist c_* {
        local var: subinstr local varc "c_" ""
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
        di "gcollapse produced identical data to collapse (tol = `tol')"
    }
restore
