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
        if ("`outmiss'" != "") replace rnorm = . if runiform() < 0.1
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") {
            tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
            local target `:di cond("`replace'" == "", "groupstr", "group")'
            replace `target' = "i am a modesly long string" + `target'
        }
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

capture program drop checks_consistency_gegen
program checks_consistency_gegen
    syntax, [tol(real 1e-6) *]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gegen `options'" _n(1) "{hline 80}" _n(1)

    local stats total sum mean sd max min count median iqr
    sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss

    cap drop g*_*
    cap drop c*_*
    di "Checking full range"
    foreach fun of local stats {
        qui gegen g_`fun' = `fun'(rnorm), by(groupstr groupsub) `options'
        qui  egen c_`fun' = `fun'(rnorm), by(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        qui gegen g_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        qui gegen g_`fun' = `fun'(groupstr groupsub), v `options'
        qui  egen c_`fun' = `fun'(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking if range"
    foreach fun of local stats {
        qui gegen gif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub) `options'
        qui  egen cif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        qui gegen g_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        qui gegen gif_`fun' = `fun'(groupstr groupsub) if rsort > 0, v `options'
        qui  egen cif_`fun' = `fun'(groupstr groupsub) if rsort > 0
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking in range"
    foreach fun of local stats {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub) `options'
        qui  egen cin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub)
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen g_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gin_`fun' = `fun'(groupstr groupsub) in `from' / `to', v b `options'
        qui  egen cin_`fun' = `fun'(groupstr groupsub) in `from' / `to'
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking if in range"
    foreach fun of local stats {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) `options'
        qui  egen cifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub)
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen g_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to', v `options'
        qui  egen cifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    di ""
    di as txt "Passed! checks_consistency_gegen `options'"
end

capture program drop checks_options_gegen
program checks_options_gegen
    syntax, [tol(real 1e-6) *]
    di _n(1) "{hline 80}" _n(1) "checks_options_gegen `options'" _n(1) "{hline 80}" _n(1)

    sim, n(20000) nj(100) njsub(2) string outmiss

    gegen id = group(groupstr groupsub)
    gegen double mean    = mean   (rnorm),  by(groupstr groupsub) verbose benchmark `options'
    gegen double sum     = sum    (rnorm),  by(groupstr groupsub) `options'
    gegen double median  = median (rnorm),  by(groupstr groupsub) `options'
    gegen double sd      = sd     (rnorm),  by(groupstr groupsub) `options'
    gegen double iqr     = iqr    (rnorm),  by(groupstr groupsub) `options'
    gegen double first   = first  (rnorm),  by(groupstr groupsub) `options' v b
    gegen double last    = last   (rnorm),  by(groupstr groupsub) `options'
    gegen double firstnm = firstnm(rnorm),  by(groupstr groupsub) `options'
    gegen double lastnm  = lastnm (rnorm),  by(groupstr groupsub) `options'
    gegen double q10     = pctile (rnorm),  by(groupstr groupsub) `options' p(10.5)
    gegen double q30     = pctile (rnorm),  by(groupstr groupsub) `options' p(30)
    gegen double q70     = pctile (rnorm),  by(groupstr groupsub) `options' p(70)
    gegen double q90     = pctile (rnorm),  by(groupstr groupsub) `options' p(90.5)

    gcollapse (mean)    g_mean    = rnorm  ///
              (sum)     g_sum     = rnorm  ///
              (median)  g_median  = rnorm  ///
              (sd)      g_sd      = rnorm  ///
              (iqr)     g_iqr     = rnorm  ///
              (first)   g_first   = rnorm  ///
              (last)    g_last    = rnorm  ///
              (firstnm) g_firstnm = rnorm  ///
              (lastnm)  g_lastnm  = rnorm  ///
              (p10.5)   g_q10     = rnorm  ///
              (p30)     g_q30     = rnorm  ///
              (p70)     g_q70     = rnorm  ///
              (p90.5)   g_q90     = rnorm, by(id) benchmark verbose `options' merge double

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "`fun' vs gcollapse failed! (tol = `tol')"
                exit _rc
            }
        }
        else di as txt "    `fun' vs gcollapse was OK"
    }

    sim, n(20000) nj(100) njsub(2) string outmiss

    local in1 = ceil(runiform() * `=_N')
    local in2 = ceil(runiform() * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')

    gegen id = group(groupstr groupsub) in `from' / `to'
    gegen double mean    = mean   (rnorm) in `from' / `to',  by(groupstr groupsub) verbose benchmark `options'
    gegen double sum     = sum    (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double median  = median (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double sd      = sd     (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double iqr     = iqr    (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double first   = first  (rnorm) in `from' / `to',  by(groupstr groupsub) `options' v b
    gegen double last    = last   (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double firstnm = firstnm(rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double lastnm  = lastnm (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double q10     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(10.5)
    gegen double q30     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(30)
    gegen double q70     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(70)
    gegen double q90     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(90.5)

    gcollapse (mean)    g_mean    = rnorm  ///
              (sum)     g_sum     = rnorm  ///
              (median)  g_median  = rnorm  ///
              (sd)      g_sd      = rnorm  ///
              (iqr)     g_iqr     = rnorm  ///
              (first)   g_first   = rnorm  ///
              (last)    g_last    = rnorm  ///
              (firstnm) g_firstnm = rnorm  ///
              (lastnm)  g_lastnm  = rnorm  ///
              (p10.5)   g_q10     = rnorm  ///
              (p30)     g_q30     = rnorm  ///
              (p70)     g_q70     = rnorm  ///
              (p90.5)   g_q90     = rnorm in `from' / `to', by(id) benchmark verbose `options' merge double

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "`fun' vs gcollapse (in) failed! (tol = `tol')"
                exit _rc
            }
        }
        else di as txt "    `fun' vs gcollapse (in) was OK"
    }

    sim, n(20000) nj(100) njsub(2) string outmiss

    local in1 = ceil(runiform() * `=_N')
    local in2 = ceil(runiform() * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    qui count if rsort < 0 in `from' / `to'
    if !( `r(N)' < `=_N' ) {
        local from = 100
        local to = 19000
    }

    gegen id = group(groupstr groupsub)   if rsort < 0 in `from' / `to'
    gegen double mean    = mean   (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) verbose benchmark `options'
    gegen double sum     = sum    (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double median  = median (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double sd      = sd     (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double iqr     = iqr    (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double first   = first  (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' v b
    gegen double last    = last   (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double firstnm = firstnm(rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double lastnm  = lastnm (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double q10     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(10.5)
    gegen double q30     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(30)
    gegen double q70     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(70)
    gegen double q90     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(90.5)

    keep if rsort < 0 in `from' / `to'
    gcollapse (mean)    g_mean    = rnorm  ///
              (sum)     g_sum     = rnorm  ///
              (median)  g_median  = rnorm  ///
              (sd)      g_sd      = rnorm  ///
              (iqr)     g_iqr     = rnorm  ///
              (first)   g_first   = rnorm  ///
              (last)    g_last    = rnorm  ///
              (firstnm) g_firstnm = rnorm  ///
              (lastnm)  g_lastnm  = rnorm  ///
              (p10.5)   g_q10     = rnorm  ///
              (p30)     g_q30     = rnorm  ///
              (p70)     g_q70     = rnorm  ///
              (p90.5)   g_q90     = rnorm, by(id) benchmark verbose `options' merge double

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "`fun' vs gcollapse (if in) failed! (tol = `tol')"
                exit _rc
            }
        }
        else di as txt "    `fun' vs gcollapse (if in) was OK"
    }

    di ""
    di as txt "Passed! checks_options_gegen `options'"
end
