* ---------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Tue May 16 07:47:05 EDT 2017
* Purpose: Unit tests for gtools
* Version: 0.2.0
* Manual:  help gcollapse

* Stata start-up options
* ----------------------

version 13
clear all
set more off
set varabbrev off
capture log close _all
set seed 42

* Main program wrapper
* --------------------

program main
    syntax, [CAPture NOIsily]

    * Set up
    * ------

    local  progname tests
    local  start_time "$S_TIME $S_DATE"
    di "Start: `start_time'"

    * Run the things
    * --------------

    `capture' `noisily' {
        * do test_gcollapse.do
        * do bench_gcollapse.do
        checks_simplest_gcollapse
        checks_byvars_gcollapse
        checks_options_gcollapse

        checks_simplest_gcollapse, multi
        checks_byvars_gcollapse,   multi
        checks_options_gcollapse,  multi

        * bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
        * bench_ftools y1 y2 y3, by(x3)    kmin(4) kmax(7) kvars(3) stats(mean median)
        * bench_ftools y1 y2 y3, by(x4 x6) kmin(4) kmax(7) kvars(3) stats(mean median)

        * bench_group_size x1 x2,  by(group) obsexp(6) kmax(6)
        * bench_group_size x1 x2,  by(group) obsexp(6) kmax(6) pct(median iqr p23 p77)
        * bench_sample_size x1 x2, by(group) kmin(4)   kmax(7)
        * bench_sample_size x1 x2, by(group) kmin(4)   kmax(7) pct(median iqr p23 p77)
    }
    local rc = _rc

    exit_message, rc(`rc') progname(`progname') start_time(`start_time') `capture'
    exit `rc'
end

capture program drop exit_message
program exit_message
    syntax, rc(int) progname(str) start_time(str) [CAPture]
    local end_time "$S_TIME $S_DATE"
    local time     "Start: `start_time'" _n(1) "End: `end_time'"
    di ""
    if (`rc' == 0) {
        di "End: $S_TIME $S_DATE"
        local paux	  ran
        local message "`progname' finished running" _n(2) "`time'"
        local subject "`progname' `paux'"
    }
    else if ("`capture'" == "") {
        di "WARNING: $S_TIME $S_DATE"
        local paux ran with non-0 exit status
        local message "`progname' ran but Stata gave error code r(`rc')" _n(2) "`time'"
        local subject "`progname' `paux'"
    }
    else {
        di "ERROR: $S_TIME $S_DATE"
        local paux ran with errors
        local message "`progname' stopped with error code r(`rc')" _n(2) "`time'"
        local subject "`progname' `paux'"
    }
    di "`subject'"
    di ""
    di "`message'"
end

* Wrapper for easy timer use
cap program drop mytimer
program mytimer, rclass
    * args number what step
    syntax anything, [minutes ts]

    tokenize `anything'
    local number `1'
    local what   `2'
    local step   `3'

    if ("`what'" == "end") {
        qui {
            timer clear `number'
            timer off   `number'
        }
        if ("`ts'" == "ts") mytimer_ts `step'
    }
    else if ("`what'" == "info") {
        qui {
            timer off `number'
            timer list `number'
        }
        local seconds = r(t`number')
        local prints  `:di trim("`:di %21.2gc `seconds''")' seconds
        if ("`minutes'" != "") {
            local minutes = `seconds' / 60
            local prints  `:di trim("`:di %21.3gc `minutes''")' minutes
        }
        mytimer_ts Step `step' took `prints'
        qui {
            timer clear `number'
            timer on    `number'
        }
    }
    else {
        qui {
            timer clear `number'
            timer on    `number'
            timer off   `number'
            timer list  `number'
            timer on    `number'
        }
        if ("`ts'" == "ts") mytimer_ts `step'
    }
end

capture program drop mytimer_ts
program mytimer_ts
    display _n(1) "{hline 79}"
    if ("`0'" != "") display `"`0'"'
    display `"        Base: $S_FN"'
    display  "        In memory: `:di trim("`:di %21.0gc _N'")' observations"
    display  "        Timestamp: $S_TIME $S_DATE"
    display  "{hline 79}" _n(1)
end

capture program drop sim
program sim, rclass
    syntax, [offset(str) n(int 100) nj(int 10) njsub(int 2) string float sortg replace groupmiss outmiss]
    qui {
        if ("`offset'" == "") local offset 0
        clear
        set obs `n'
        gen group  = ceil(`nj' *  _n / _N) + `offset'
        bys group: gen groupsub   = ceil(`njsub' *  _n / _N)
        bys group: gen groupfloat = ceil(`njsub' *  _n / _N) + 0.5
        gen rsort = runiform() - 0.5
        gen rnorm = rnormal()
        if ("`sortg'" == "")  sort rsort
        if ("`groupmiss'" != "") replace group = . if runiform() < 0.1
        if ("`outmiss'" != "") replace rsort = . if runiform() < 0.1
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
        gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    }
    sum rsort
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    compress
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

capture program drop checks_simplest_gcollapse
program checks_simplest_gcollapse
    syntax, [tol(real 1e-6) multi]
    di _n(1) "{hline 80}" _n(1) "checks_simplest_gcollapse" _n(1) "{hline 80}" _n(1)

    * sim, n(500000) nj(8) njsub(4) string groupmiss outmiss
    sim, n(50000) nj(8) njsub(4) string groupmiss outmiss

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm
    }
    local collapse_str `collapse_str' (p23) p23 = rnorm
    local collapse_str `collapse_str' (p77) p77 = rnorm

    local i = 0
    mytimer 9
    preserve
        mytimer 9 info
        gcollapse `collapse_str' (p2.5) p2_5 = rnorm, by(groupsub groupstr) verbose benchmark `multi'
        mytimer 9 info "gcollapse 2 groups"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        fcollapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupsub group) verbose
        mytimer 9 info "fcollapse 2 groups"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        collapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupsub groupstr)
        mytimer 9 info "collapse 2 groups"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore

    preserve
        mytimer 9 info
        gcollapse `collapse_str' (p2.5) p2_5 = rnorm, by(groupstr) verbose benchmark `multi'
        mytimer 9 info "gcollapse 1 group"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        fcollapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupstr) verbose
        mytimer 9 info "fcollapse 1 group"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        collapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupstr)
        mytimer 9 info "collapse 1 group"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore
    mytimer 9 off

    preserve
    use `f2', clear
        local bad_any = 0
        local bad groupsub groupstr
        foreach var in `stats' p23 p77 {
            rename `var' c_`var'
        }
        merge 1:1 groupsub groupstr using `f0', assert(3)
        foreach var in `stats' p23 p77 {
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
            l *count* `bad'
        }
        else {
            di "gcollapse produced identical data to collapse (tol = `tol')"
        }

    restore, preserve

    use `f5', clear
        local bad_any = 0
        local bad groupstr
        foreach var in `stats' p23 p77 {
            rename `var' c_`var'
        }
        merge 1:1 groupstr using `f3', assert(3)
        foreach var in `stats' p23 p77 {
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
            l *count* `bad'
        }
        else {
            di "gcollapse produced identical data to collapse (tol = `tol')"
        }
    restore

    di ""
    di as txt "Passed! checks_simplest_gcollapse"
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    syntax, [multi]
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string
    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr groupsub) verbose `multi'
    restore
    set rmsg off


    di ""
    di as txt "Passed! checks_byvars_gcollapse"
end

capture program drop checks_options_gcollapse
program checks_options_gcollapse
    syntax, [multi]
    di _n(1) "{hline 80}" _n(1) "checks_options_gcollapse" _n(1) "{hline 80}" _n(1)

    local stats mean count median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm `stat'2 = rnorm
    }

    sim, n(200) nj(10) string outmiss
    preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `multi'
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose unsorted `multi'
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw `multi'
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) double `multi'
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) merge `multi'
        l
    restore

    sort groupstr groupsub
    preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark `multi'
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark smart `multi'
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_str', by(groupsub groupstr) verbose benchmark smart `multi'
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `multi'
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark smart `multi'
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark smart `multi'
        l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark `multi'
        l
    restore

    di ""
    di as txt "Passed! checks_options_gcollapse"
end

* TODO: Edge cases (nothing in anything, no -by-, should mimic collapse // 2017-05-16 08:03 EDT

* ---------------------------------------------------------------------
* Run the things

main, cap noi
