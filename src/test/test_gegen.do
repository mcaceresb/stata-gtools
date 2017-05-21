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
    syntax, [tol(real 1e-6) multi]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gegen `multi'" _n(1) "{hline 80}" _n(1)

    local stats total sum mean sd max min count median iqr
    sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss

    cap drop g*_*
    cap drop c*_*
    di "Checking full range"
    foreach fun of local stats {
        qui gegen g_`fun' = `fun'(rnorm), by(groupstr groupsub)
        qui  egen c_`fun' = `fun'(rnorm), by(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        qui gegen g_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p')
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
        qui gegen g_`fun' = `fun'(groupstr groupsub)
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
        qui gegen gif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        qui  egen cif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        qui gegen g_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p')
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
        qui gegen gif_`fun' = `fun'(groupstr groupsub) if rsort > 0
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
        qui gegen gin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub)
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
        qui gegen g_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p')
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
        qui gegen gin_`fun' = `fun'(groupstr groupsub) in `from' / `to', v b
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
        qui gegen gifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub)
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
        qui gegen g_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p')
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
        qui gegen gifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        qui  egen cifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    di ""
    di as txt "Passed! checks_consistency_gegen `multi'"
end

capture program drop checks_options_gegen
program checks_options_gegen
    syntax, [tol(real 1e-6) multi]
    di _n(1) "{hline 80}" _n(1) "checks_options_gegen `multi'" _n(1) "{hline 80}" _n(1)

    sim, n(20000) nj(100) njsub(2) string outmiss

    gegen id      = group(groupstr groupsub)
    gegen mean    = mean   (rnorm),  by(groupstr groupsub) verbose benchmark `multi'
    gegen sum     = sum    (rnorm),  by(groupstr groupsub) `multi'
    gegen median  = median (rnorm),  by(groupstr groupsub) `multi'
    gegen sd      = sd     (rnorm),  by(groupstr groupsub) `multi'
    gegen iqr     = iqr    (rnorm),  by(groupstr groupsub) `multi'
    gegen first   = first  (rnorm),  by(groupstr groupsub) v b
    gegen last    = last   (rnorm),  by(groupstr groupsub)
    gegen firstnm = firstnm(rnorm),  by(groupstr groupsub)
    gegen lastnm  = lastnm (rnorm),  by(groupstr groupsub)
    gegen q10     = pctile (rnorm),  by(groupstr groupsub) p(10.5)
    gegen q30     = pctile (rnorm),  by(groupstr groupsub) p(30)
    gegen q70     = pctile (rnorm),  by(groupstr groupsub) p(70)
    gegen q90     = pctile (rnorm),  by(groupstr groupsub) p(90.5)

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
              (p90.5)   g_q90     = rnorm, by(id) benchmark verbose `multi' merge

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            di as err "`fun' vs gcollapse failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' vs gcollapse was OK"
    }

    * clear
    * set obs 20000000
    * gen long x = ceil(uniform() * 5000)
    * gen double xdbl = x  + 0.5
    * tostring x, gen(xstr)
    * replace xstr = "str" + xstr
    * set rmsg on
    *     gegen id  = group(x)
    *     drop id*
    *     gegen id  = group(xdbl)
    *     drop id*
    *     gegen id  = group(xstr)
    *     drop id*
    *     gegen tag = tag(x)
    *     drop tag*
    *     gegen tag = tag(xdbl)
    *     drop tag*
    *     gegen tag = tag(xstr)
    *     drop tag*
    *     fegen id  = group(x)
    *     drop id*
    *     fegen id  = group(xdbl)
    *     drop id*
    *     fegen id  = group(xstr)
    *     drop id*
    *     egen id   = group(x)
    *     drop id*
    *     egen id   = group(xdbl)
    *     drop id*
    *     egen id   = group(xstr)
    *     drop id*
    *     egen tag  = tag(x)
    *     drop tag* 
    *     egen tag  = tag(xdbl)
    *     drop tag* 
    *     egen tag  = tag(xstr)
    *     drop tag*
    * set rmsg off

    * | variable | gegen | fegen |  egen | 
    * | -------- | ----- | ----- | ----- | 
    * |        x |  6.32 |  2.52 | 35.32 | 
    * |     xstr |  8.13 | 35.39 | 41.16 | 
    * |     xdbl |  8.09 | 21.36 | 38.33 | 

    * | variable | gegen |  egen | 
    * | -------- | ----- | ----- | 
    * |        x |  4.58 | 47.61 | 
    * |     xstr |  6.86 | 57.39 | 
    * |     xdbl |  6.37 | 49.56 | 

    di ""
    di as txt "Passed! checks_options_gegen `multi'"
end
