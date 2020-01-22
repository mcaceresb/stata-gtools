capture program drop checks_gregress
program checks_gregress
    basic_gregress
    coll_gregress
end

capture program drop basic_gregress
program basic_gregress
    local tol 1e-8

disp ""
disp "----------------------"
disp "Comparison Test 1: OLS"
disp "----------------------"
disp ""

    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)

    foreach v in v1 v2 v5 v7 {
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [aw = w]
        if ( "`v'" == "v6" ) local w [aw = w]

        if ( "`v'" == "v7" ) local w [pw = w]
        if ( "`v'" == "v8" ) local w [pw = w]

        disp "greg checks `v': `w'"

        qui greg price mpg `w', by(foreign) `r'
            qui reg price mpg if foreign == 0 `w'
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[1, .]) :< `tol'))
            qui reg price mpg if foreign == 1 `w'
            mata: assert(all((abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[2, .])) :< `tol'))
            mata: assert(all((abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[2, .])) :< `tol'))
        qui greg price mpg `w', by(foreign) robust `r'
            qui reg price mpg if foreign == 0 `w', robust
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[1, .]) :< `tol'))
            qui reg price mpg if foreign == 1 `w', robust
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[2, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[2, .]) :< `tol'))
        qui greg price mpg `w', by(foreign) cluster(headroom) `r'
            qui reg price mpg if foreign == 0 `w', cluster(headcode)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[1, .]) :< `tol'))
            qui reg price mpg if foreign == 1 `w', cluster(headcode)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[2, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[2, .]) :< `tol'))

        qui greg price mpg `w', absorb(rep78)
            qui areg price mpg `w', absorb(rep78)
            mata: assert(all(abs(st_matrix("r(table)")[1, 1] :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1] :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78) robust
            qui areg price mpg `w', absorb(rep78) robust
            mata: assert(all(abs(st_matrix("r(table)")[1, 1] :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1] :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78) cluster(headroom)
            qui areg price mpg `w', absorb(rep78) cluster(headroom)
            mata: assert(all(abs(st_matrix("r(table)")[1, 1] :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1] :- GtoolsRegress.se[1, 1]) :< `tol'))

        qui greg price mpg `w', by(foreign) absorb(rep78)
            qui areg price mpg if foreign == 0 `w', absorb(rep78)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
            qui areg price mpg if foreign == 1 `w', absorb(rep78)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78) robust
            qui areg price mpg if foreign == 0 `w', absorb(rep78) robust
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
            qui areg price mpg if foreign == 1 `w', absorb(rep78) robust
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78) cluster(headroom)
            qui areg price mpg if foreign == 0 `w', absorb(rep78) cluster(headroom)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
            qui areg price mpg if foreign == 1 `w', absorb(rep78) cluster(headroom)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[2, 1]) :< `tol'))

        qui greg price mpg `w', absorb(rep78 headroom)
            qui reg price mpg i.rep78 i.headcode `w'
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78 headroom) robust
            qui reg price mpg i.rep78 i.headcode `w', robust
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg i.rep78 i.headcode `w', vce(cluster headcode)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))

        qui greg price mpg `w', by(foreign) absorb(rep78 headroom)
            qui reg price mpg i.rep78 i.headcode if foreign == 0 `w'
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[1, 1]) :< `tol'))
            qui reg price mpg i.rep78 i.headcode if foreign == 1 `w'
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78 headroom) robust
            qui reg price mpg i.rep78 i.headcode if foreign == 0 `w', robust
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[1, 1]) :< `tol'))
            qui reg price mpg i.rep78 i.headcode if foreign == 1 `w', robust
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg i.rep78 i.headcode if foreign == 0 `w', cluster(headroom)
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[1, 1]) :< `tol'))
            qui reg price mpg i.rep78 i.headcode if foreign == 1 `w', cluster(headroom)
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[2, 1]) :< `tol'))
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "---------------------"
disp "Comparison Test 2: IV"
disp "---------------------"
disp ""

    local tol 1e-6
    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)

    local v
    local w
    foreach v in v1 v2 v3 v4 {
        local w
        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v3" ) local w [aw = w]
        if ( "`v'" == "v4" ) local w [pw = w]
        disp "iv checks `v': `w'"

        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars i.rep78
            if ( `"`av'"' == "v3" ) local avars i.rep78 i.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "basic checks: `vce' `small' `absorb'"
                qui givregress price (mpg = gear_ratio) weight turn                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight turn `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 1"
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 2"
                qui givregress price (mpg = gear_ratio)                                        `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio)             `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 3"
                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars'      `w' , `vce' noc `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 4"
                }
                qui givregress price (mpg = gear_ratio turn displacement) weight               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn displacement) weight `avars' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 5"
                qui givregress price (mpg = gear_ratio turn) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn) weight `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 6"
                qui givregress price (mpg weight = gear_ratio turn)                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 7"
                qui givregress price (mpg weight = gear_ratio turn) displacement               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) displacement `avars' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 8"
                qui givregress price (mpg weight = gear_ratio turn displacement)               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn displacement) `avars' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 9"
            }
        }

        * expand 10
        * gen _by = mod(_n, 2)
        * local by by(_by)
        local by by(foreign)
        local if1 if foreign == 0
        local if2 if foreign == 1
        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars i.rep78
            if ( `"`av'"' == "v3" ) local avars i.rep78 i.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "`by' checks: `vce' `small' `absorb'"
                qui givregress price (mpg = gear_ratio) weight turn                            `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio) weight turn `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio) weight turn `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 1"
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 2"
                qui givregress price (mpg = gear_ratio)                                        `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio)             `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio)             `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 3"
                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb' noc `by'
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if1' `w' , `vce' noc `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if2' `w' , `vce' noc `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 4"
                }
                qui givregress price (mpg = gear_ratio turn displacement) weight               `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio turn displacement) weight `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio turn displacement) weight `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 5"
                qui givregress price (mpg = gear_ratio turn) weight                            `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio turn) weight `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio turn) weight `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 6"
                qui givregress price (mpg weight = gear_ratio turn)                            `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 7"
                qui givregress price (mpg weight = gear_ratio turn) displacement               `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) displacement `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) displacement `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 8"
                qui givregress price (mpg weight = gear_ratio turn displacement)               `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn displacement) `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg weight = gear_ratio turn displacement) `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 9"
            }
        }
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "--------------------------"
disp "Comparison Test 3: Poisson"
disp "--------------------------"
disp ""

    local tol 1e-4
    * webuse ships, clear
    use /tmp/ships, clear
    qui expand 2
    qui gen by = 1.5 - (_n < _N / 2)
    qui gen w = _n
    foreach v in v1 v2 v5 {
        disp "poisson checks `v'"
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [pw = w]
        if ( "`v'" == "v6" ) local w [pw = w]

        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', robust `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 1"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship) `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 2"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) robust `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 0.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 1.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 3"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) cluster(ship) `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 0.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 1.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 4"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) r
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 5"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) cluster(ship)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 6"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) absorb(ship) robust
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 0.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 1.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 7"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) absorb(ship) cluster(ship)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 0.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 1.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 8"
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "--------------------------"
disp "Stress Test 1: Consistency"
disp "--------------------------"
disp ""
    qui {
        clear
        set obs 10000
        gen e = rnormal() * 50
        gen g = ceil(runiform()*100)
        forvalues i = 1 / 4 {
            gen x`i' = rnormal() * `i' + `i'
        }
        gen byte ones = 1
        gen y = 5 - 4 * x1 + 3 * x2 - 2 * x3 + x4 + g + e
        gen w = int(50 * runiform())
        areg y x1 x2 x3 x4, absorb(g)
        greg y x1 x2 x3 x4, absorb(g) mata(coefs)
        greg y x1 x2 x3 x4, absorb(g) prefix(hdfe(_hdfe_)) mata(coefs)
        greg y x1 x2 x3 x4, absorb(g) prefix(hdfe(_hdfe_)) replace
        greg y x1 x2 x3 x4, absorb(g) prefix(b(_b_))
        greg y x1 x2 x3 x4, absorb(g) prefix(se(_se_))
        greg y x1 x2 x3 x4, absorb(g) gen(b(_bx1 _bx2 _bx3 _bx4))
        greg y x1 x2 x3 x4, absorb(g) gen(hdfe(_hy _hx1 _hx2 _hx3 _hx4)) mata(levels, nob nose)
        greg y x1 x2 x3 x4, absorb(g) gen(se(_sex1 _sex2 _sex3 _sex4))
        assert (_hdfe_y == _hy)
        foreach var in x1 x2 x3 x4 {
            assert (_hdfe_`var' == _h`var')
            assert (_b_`var' == _b`var')
            assert (_se_`var' == _se`var')
        }

        drop _*
        areg y x1 x2 x3 x4 [fw = w], absorb(g)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) mata(coefs)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(hdfe(_hdfe_)) mata(coefs)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(hdfe(_hdfe_)) replace
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(b(_b_))
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(se(_se_))
        greg y x1 x2 x3 x4 [fw = w], absorb(g) gen(b(_bx1 _bx2 _bx3 _bx4))
        greg y x1 x2 x3 x4 [fw = w], absorb(g) gen(hdfe(_hy _hx1 _hx2 _hx3 _hx4)) mata(levels, nob nose)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) gen(se(_sex1 _sex2 _sex3 _sex4))
        assert (_hdfe_y == _hy)
        foreach var in x1 x2 x3 x4 {
            assert (_hdfe_`var' == _h`var')
            assert (_b_`var' == _b`var')
            assert (_se_`var' == _se`var')
        }
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "-----------------------------------"
disp "Stress Test 2: 'Large' observations"
disp "-----------------------------------"
disp ""
    qui {
        clear
        set obs 10000000
        gen e = rnormal() * 20
        gen g = ceil(runiform()*100)
        forvalues i = 1 / 4 {
            gen x`i' = rnormal() * `i' + `i'
        }
        gen byte ones = 1
        gen y = 5 - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e
        gen w = int(50 * runiform())

        greg y x1 x2 x3 x4, mata(r1)
        reg  y x1 x2 x3 x4
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- r1.se[1, .]) :< `tol'))
        greg y x1 x2 x3 x4, r mata(r1)
        reg  y x1 x2 x3 x4, r
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- r1.se[1, .]) :< `tol'))
        greg y x1 x2 x3 x4, cluster(g) mata(r1)
        reg  y x1 x2 x3 x4, vce(cluster g)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- r1.se[1, .]) :< `tol'))
        greg y x1 x2 x3 x4, absorb(g) mata(r1)
        areg y x1 x2 x3 x4, absorb(g)
            mata: assert(all(abs(st_matrix("r(table)")[1, 1::4] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1::4] :- r1.se[1, .]) :< `tol'))

        greg y x1 x2 x3 x4 [fw = w], mata(r1)
        reg  y x1 x2 x3 x4 [fw = w], mata(r1)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- r1.se[1, .]) :< `tol'))
        greg y x1 x2 x3 x4 [fw = w], mata(r1) r
        reg  y x1 x2 x3 x4 [fw = w], r
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- r1.se[1, .]) :< `tol'))
        greg y x1 x2 x3 x4 [fw = w], mata(r1) cluster(g)
        reg  y x1 x2 x3 x4 [fw = w], vce(cluster g)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- r1.se[1, .]) :< `tol'))
        greg y x1 x2 x3 x4 [fw = w], mata(r1) absorb(g)
        areg y x1 x2 x3 x4 [fw = w], absorb(g)
            mata: assert(all(abs(st_matrix("r(table)")[1, 1::4] :- r1.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1::4] :- r1.se[1, .]) :< `tol'))
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    if ( `c(MP)' ) {
disp ""
disp "---------------------------"
disp "Stress Test 3: 'Wide' model"
disp "---------------------------"
disp ""
        qui {
            clear
            set matsize 10000
            set maxvar 50000
            set obs 50000
            gen g = ceil(runiform()*10)
            gen e = rnormal() * 5
            forvalues i = 1 / 500 {
                gen x`i' = rnormal() * `i' + `i'
            }
            gen y = - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e

            * Slower with all the vars, but no longer unreasonably so
            greg y x*, mata(r1) v bench(3)
            reg  y x*
                mata: assert(all(abs(st_matrix("r(table)")[1, .] :- r1.b[1, .]) :< `tol'))
                mata: assert(all(abs(st_matrix("r(table)")[2, .] :- r1.se[1, .]) :< `tol'))
            greg y x*, mata(r1) v bench(3) cluster(g)
            reg  y x*, vce(cluster g)
                mata: assert(all(abs(st_matrix("r(table)")[1, .] :- r1.b[1, .]) :< `tol'))
                mata: assert(all(abs(st_matrix("r(table)")[2, .] :- r1.se[1, .]) :< `tol'))
        }
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    * clear
    * local N 1000000
    * local G 10000
    * set rmsg on
    * set obs `N'
    * gen g1 = int(runiform() * `G')
    * gen g2 = int(runiform() * `G')
    * gen g3 = int(runiform() * `G')
    * gen g4 = int(runiform() * `G')
    * gen x1 = runiform()
    * gen x2 = runiform()
    * gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + 20 * rnormal()
    * gen w  = int(50 * runiform())
    *
    * reghdfe y x1 x2, absorb(g1 g2 g3)
    * greg y x1 x2, absorb(g1 g2 g3) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2, absorb(g1 g2 g3) vce(robust)
    * greg y x1 x2, absorb(g1 g2 g3) mata(greg) r
    * mata greg.print()
    *
    * reghdfe y x1 x2, absorb(g1 g2 g3) vce(cluster g4)
    * greg y x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [fw = w], absorb(g1 g2 g3)
    * greg y x1 x2 [fw = w], absorb(g1 g2 g3) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [fw = w], absorb(g1 g2 g3) vce(robust)
    * greg y x1 x2 [fw = w], absorb(g1 g2 g3) mata(greg) r
    * mata greg.print()
    *
    * reghdfe y x1 x2 [fw = w], absorb(g1 g2 g3) vce(cluster g4)
    * greg y x1 x2 [fw = w], absorb(g1 g2 g3) cluster(g4) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [aw = w], absorb(g1 g2 g3)
    * greg y x1 x2 [aw = w], absorb(g1 g2 g3) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [aw = w], absorb(g1 g2 g3) vce(robust)
    * greg y x1 x2 [aw = w], absorb(g1 g2 g3) mata(greg) r
    * mata greg.print()
    *
    * reghdfe y x1 x2 [aw = w], absorb(g1 g2 g3) vce(cluster g4)
    * greg y x1 x2 [aw = w], absorb(g1 g2 g3) cluster(g4) mata(greg)
    * mata greg.print()

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    * Well, there is an issue when the number of absorbed effects are
    * close to the number of observations ):
end

capture program drop coll_gregress
program coll_gregress
    local tol 1e-8

disp ""
disp "------------------------"
disp "Collinearity Test 1: OLS"
disp "------------------------"
disp ""

    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)

    foreach v in v1 v2 v5 v7 {
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [aw = w]
        if ( "`v'" == "v6" ) local w [aw = w]

        if ( "`v'" == "v7" ) local w [pw = w]
        if ( "`v'" == "v8" ) local w [pw = w]

        disp "greg checks `v': `w'"

        qui greg price mpg mpg `w', by(foreign) `r'
            qui reg price mpg mpg if foreign == 0 `w'
            mata: check_gregress_consistency(`tol', 1, ., GtoolsRegress)
            qui reg price mpg mpg if foreign == 1 `w'
            mata: check_gregress_consistency(`tol', 2, ., GtoolsRegress)
        qui greg price mpg mpg mpg `w', by(foreign) robust `r'
            qui reg price mpg mpg mpg if foreign == 0 `w', robust
            mata: check_gregress_consistency(`tol', 1, ., GtoolsRegress)
            qui reg price mpg mpg mpg if foreign == 1 `w', robust
            mata: check_gregress_consistency(`tol', 2, ., GtoolsRegress)
        qui greg price mpg mpg `w', by(foreign) cluster(headroom) `r'
            qui reg price mpg mpg if foreign == 0 `w', cluster(headcode)
            mata: check_gregress_consistency(`tol', 1, ., GtoolsRegress)
            qui reg price mpg mpg if foreign == 1 `w', cluster(headcode)
            mata: check_gregress_consistency(`tol', 2, ., GtoolsRegress)

        qui greg price mpg mpg `w', absorb(rep78)
            qui areg price mpg mpg `w', absorb(rep78)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', absorb(rep78) robust
            qui areg price mpg mpg `w', absorb(rep78) robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', absorb(rep78) cluster(headroom)
            qui areg price mpg mpg `w', absorb(rep78) cluster(headroom)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)

        qui greg price mpg mpg `w', by(foreign) absorb(rep78)
            qui areg price mpg mpg if foreign == 0 `w', absorb(rep78)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui areg price mpg mpg if foreign == 1 `w', absorb(rep78)
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', by(foreign) absorb(rep78) robust
            qui areg price mpg mpg if foreign == 0 `w', absorb(rep78) robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui areg price mpg mpg if foreign == 1 `w', absorb(rep78) robust
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', by(foreign) absorb(rep78) cluster(headroom)
            qui areg price mpg mpg if foreign == 0 `w', absorb(rep78) cluster(headroom)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui areg price mpg mpg if foreign == 1 `w', absorb(rep78) cluster(headroom)
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)

        cap drop _*
        qui tab headroom, gen(_)
        qui greg price mpg mpg _* `w', absorb(rep78 headroom)
            qui reg price mpg mpg i.rep78 i.headcode `w'
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg _* `w', absorb(rep78 headroom) robust
            qui reg price mpg mpg i.rep78 i.headcode `w', robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg _* `w', absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg mpg i.rep78 i.headcode `w', vce(cluster headcode)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)

        qui greg price mpg mpg _* `w', by(foreign) absorb(rep78 headroom)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 0 `w'
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 1 `w'
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg _* `w', by(foreign) absorb(rep78 headroom) robust
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 0 `w', robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 1 `w', robust
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg _* `w', by(foreign) absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 0 `w', cluster(headroom)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 1 `w', cluster(headroom)
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "-----------------------"
disp "Collinearity Test 2: IV"
disp "-----------------------"
disp ""

    local tol 1e-6
    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)
    cap drop _*
    qui tab headcode, gen(_h)
    qui tab rep78,    gen(_r)
    qui gen _mpg          = mpg
    qui gen _mpg2         = mpg
    qui gen _mpg3         = mpg
    qui gen _price        = price
    qui gen _price2       = price
    qui gen _gear_ratio   = gear_ratio
    qui gen _weight       = weight
    qui gen _turn         = turn
    qui gen _displacement = displacement

    * Colinearity foo
    *
    * 1. Within
    *     - instrumented
    *     - instrument
    *     - exogenous
    *
    * 2. Across
    *     - (!) dependenet variable _and_ instrumented
    *     - (!) dependenet variable _and_ instrument
    *     - (!) dependenet variable _and_ exogenous
    *     - instrumented _and_ instrument
    *     - instrumented _and_ exogenous
    *     - instrument _and_ exogenous
    *
    * 3. Mixed Across
    *
    *     - dependenet _and_ instrumented _and_ instrument
    *     - dependenet _and_ instrumented _and_ exogenous
    *     - dependenet _and_ instrument _and_ exogenous
    *     - instrumented _and_ instrument _and_ exogenous

    local v
    local w
    foreach v in v1 v2 v3 v4 {
        local w
        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v3" ) local w [aw = w]
        if ( "`v'" == "v4" ) local w [pw = w]
        disp "iv checks `v': `w'"

        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars i.rep78
            if ( `"`av'"' == "v3" ) local avars i.rep78 i.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            if ( `"`av'"' == "v1" ) local dvars
            if ( `"`av'"' == "v2" ) unab  dvars: _r*
            if ( `"`av'"' == "v3" ) unab  dvars: _r* _h*

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "basic checks: `vce' `small' `absorb'"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight turn                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight turn       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight turn                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight turn `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight turn                           `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight turn           `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight turn                                `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight turn                           `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight turn            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight turn                            `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight turn                                         `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight turn                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight turn                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight turn                       `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight turn                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight turn `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight turn       `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight turn       `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight turn       `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn                  `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn  `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 1"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 2"

                qui givregress price (mpg = gear_ratio _gear_ratio)                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio)                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement)                             `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement)             `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio)                                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio)                               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio)                                            `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price)                                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price)                        `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price                                        `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg)                                                     `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg)                                          `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg                                          `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio                                   `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio                             `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio             `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2)                   `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2                   `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2                   `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 3"

                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `gvce' `absorb' noc
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `gvce' `absorb' noc
                qui givregress price (mpg = _mpg) weight                                              `w' , `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `gvce' `absorb' noc
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb' noc
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb' noc
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 4"
                }

                qui givregress price (mpg = gear_ratio turn _gear_ratio length) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn _gear_ratio length) weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio turn length displacement) weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio turn length displacement) weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn length) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio turn length  _price) weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _price) weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length _mpg) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn) _turn _gear_ratio weight                             `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length displacement) _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length displacement) _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio turn length displacement _price2) weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio turn length displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio turn length displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 5"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio displacement turn) _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio displacement turn) _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 7"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 8"

                if ( inlist(`"`av'"', "v2", "v3") ) {
                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight                        `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight        `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight                  `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight  `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (_price = gear_ratio turn) weight                                                          `w' , `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement `dvars' weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement `dvars' weight             `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _price `dvars' weight                         `w' , `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                               `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg `dvars' weight                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio `dvars' weight                        `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement `dvars' weight        `w' , `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
disp _skip(8) "check 10"
                }
            }
        }

        * expand 10
        * gen _by = mod(_n, 2)
        * local by by(_by)
        qui expand 2, gen(_expand)
        local by by(foreign)
        local if1 if foreign == 0
        local if2 if foreign == 1
        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars i.rep78
            if ( `"`av'"' == "v3" ) local avars i.rep78 i.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            if ( `"`av'"' == "v1" ) local dvars
            if ( `"`av'"' == "v2" ) unab  dvars: _r*
            if ( `"`av'"' == "v3" ) unab  dvars: _r* _h*

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "`by' checks: `vce' `small' `absorb'"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight turn                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight turn       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight turn       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight turn                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight turn `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight turn `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight turn                           `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight turn           `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight turn           `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight turn                                `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight turn                           `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight turn            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight turn            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight turn                            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight turn                                         `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight turn                              `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight turn                              `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight turn                       `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight turn                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight turn `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight turn `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight turn       `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight turn       `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight turn       `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn                  `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn  `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn  `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 1"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 2"

                qui givregress price (mpg = gear_ratio _gear_ratio)                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio)                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio)                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement)                             `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement)             `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement)             `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio)                                               `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio)                               `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio)                               `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio)                                            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price)                                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price)                        `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price)                        `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price                                        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg)                                                     `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg)                                          `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg                                          `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio                                   `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio                             `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio             `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio             `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2)                   `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2                   `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2                   `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3                              `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3              `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3              `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 3"

                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg = _mpg) weight                                              `w' , `by' `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `by' `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 4"
                }

                qui givregress price (mpg = gear_ratio turn _gear_ratio length) weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn _gear_ratio length) weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn _gear_ratio length) weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio turn length displacement) weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio turn length displacement) weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio turn length displacement) weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length) weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn length) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio turn length  _price) weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _price) weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length _price) weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length _mpg) weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn) _turn _gear_ratio weight                             `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length displacement) _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length displacement) _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length displacement) _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio turn length displacement _price2) weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio turn length displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio turn length displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 5"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _gear_ratio weight                            `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio displacement turn) _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio displacement turn) _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio displacement turn) _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 7"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio weight                            `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 8"

                if ( inlist(`"`av'"', "v2", "v3") ) {
                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight                        `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight        `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight        `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight                  `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight  `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight  `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (_price = gear_ratio turn) weight                                                          `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement `dvars' weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement `dvars' weight             `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement `dvars' weight             `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _price `dvars' weight                         `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                               `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight                               `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg `dvars' weight                               `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio `dvars' weight                        `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement `dvars' weight        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
disp _skip(8) "check 10"
                }
            }
        }
        qui drop if _expand
        qui drop _expand
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "----------------------------"
disp "Collinearity Test 3: Poisson"
disp "----------------------------"
disp ""

    local tol 1e-4
    * webuse ships, clear
    use /tmp/ships, clear
    qui expand 2
    qui gen by = 1.5 - (_n < _N / 2)
    qui gen w = _n
    qui tab ship, gen(_s)
    unab svars: _s*
    foreach v in v1 v2 v5 {
        disp "poisson checks `v'"
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [pw = w]
        if ( "`v'" == "v6" ) local w [pw = w]

        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', robust `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 1"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', cluster(ship) `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 2"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', by(by) robust `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 0.5, r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 1.5, r
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 3"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', by(by) cluster(ship) `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 0.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
        qui poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 1.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 4"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', absorb(ship) r
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w', r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 5"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', absorb(ship) cluster(ship)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w', cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 6"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', by(by) absorb(ship) robust
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 0.5, r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 1.5, r
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 7"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', by(by) absorb(ship) cluster(ship)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 0.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 1.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 8"
    }
end

cap mata mata drop check_gregress_consistency()
mata
void function check_gregress_consistency (
    real scalar tol,
    real scalar row,
    real vector col,
    class GtoolsRegressOutput scalar res,
    | real colvector missok)
{
    real scalar missokb, missokse
    real rowvector b, se, tolb, tolse, sameb, samese

    b  = st_matrix("r(table)")[1, col]
    se = st_matrix("r(table)")[2, col]

    if ( args() > 4 ) {
        missokb  = all(res.b[row, missok]  :== 0)
        missokse = all(res.se[row, missok] :== .)

        b[missok]  = res.b[row, missok]
        se[missok] = res.se[row, missok]
    }
    else {
        missokb  = 1
        missokse = 1
    }

    tolb   = reldif(b,  res.b[row, col])  :< tol
    tolse  = reldif(se, res.se[row, col]) :< tol

    sameb  = (b  :== res.b[row, col])
    samese = (se :== res.se[row, col])

    assert(all(colmax(tolb  \ sameb))  & missokb)
    assert(all(colmax(tolse \ samese)) & missokse)
}
end

***********************************************************************
*                               Testing                               *
***********************************************************************

* capture program drop simpleHDFE
* program simpleHDFE
*     syntax varlist, absorb(varlist) [tol(real 1e-8)]
*     gettoken y x: varlist
*     tempvar diff
*
*     local dmx
*     foreach xvar of local x {
*         tempvar `xvar'1
*         tempvar `xvar'2
*         local dmx `dmx' ``xvar'1'
*     }
*
*     qui gen double `diff' = 0
*     foreach xvar of local x {
*         qui gen double ``xvar'1' = `xvar'
*         qui gen double ``xvar'2' = `xvar'
*     }
*
*     tempvar `y'1 `y'2
*     qui gen double ``y'1' = `y'
*     qui gen double ``y'2' = `y'
*     local dmy ``y'1'
*
*     foreach avar of local absorb {
*         gstats transform (demean) `dmy' `dmx', by(`avar') replace
*     }
*
*     local supnorm = 1
*     while ( `supnorm' > `tol' ) {
*         foreach avar of local absorb {
*             gstats transform (demean) `dmy' `dmx', by(`avar') replace
*             qui replace `diff' = abs(``y'2' - ``y'1')
*             qui replace ``y'2' = ``y'1'
*             foreach xvar of local x {
*                 qui replace `diff' = `diff' + abs(``xvar'2' - ``xvar'1')
*                 qui replace ``xvar'2' = ``xvar'1'
*             }
*             sum `diff', meanonly
*             local supnorm = `r(max)'
*             if ( `supnorm' < `tol' ) break
*             disp `supnorm'
*         }
*     }
*
*     reg `dmy' `dmx', noc
* end

* Collinearity test
* -----------------

* cap mata mata drop my_lu()
* cap mata mata drop my_ldu()
* cap mata mata drop my_qr()
* cap mata mata drop my_householder()
* cap mata mata drop my_dot()
* cap mata mata drop my_norm()
*
* mata
* void function my_ldu (real matrix A, real scalar N, real matrix L, real vector D)
* {
*     real scalar i, j, k
*
*     L = J(N, N, 0)
*     for (j = 1; j <= N; j++) {
*         L[j, j] = 1
*     }
*     D = J(N, 1, 0)
*
*     for (i = 1; i <= N; i++) {
*         if ( i > 1 ) {
*             D[i] = A[i, i] - (L[i, 1::(i - 1)]:^2) * D[1::(i - 1)]
*         }
*         else {
*             D[i] = A[i, i]
*         }
*         for (j = i + 1; j <= N; j++) {
*             if ( i > 1 ) {
*                 L[j, i] = (A[j, i] - (L[j, 1::(i - 1)] :* L[i, 1::(i - 1)]) * D[1::(i - 1)]) / D[i]
*             }
*             else {
*                 L[j, i] = A[j, i] / D[i]
*             }
*         }
*     }
* }
*
* void function my_lu (real matrix A, real scalar N)
* {
*     real scalar i, j, k
*
*     for (j = 1; j <= N; j++) {
*         for (k = 1; k <= j - 1; k++) {
*             for (i = j; i <= N; i++) {
*                 A[i, j] = A[i, j] - A[i, k] * A[j, k]
*             }
*         }
*         A[j, j] = sqrt(A[j, j])
*         for (i = j + 1; i <= N; i++) {
*             A[i, j] = A[i, j] / A[j, j]
*         }
*     }
*
*     for (j = 1; j <= N; j++) {
*         for (i = 1; i < j; i++) {
*             A[i, j] = 0
*         }
*     }
* }
*
* void function my_qr (real matrix A, real scalar N, real matrix Q, real matrix H)
* {
*     real scalar i
*
*     Q = diag(J(1, N, 1))
*     for (i = 1; i < N; i++) {
*         H = diag(J(1, N, 1))
*         H[i::N, i::N] = my_householder(A[i::N, i], N - i + 1, H[i::N, i::N])
*         Q = Q * H
*         A = H * A
*     }
* }
*
* real matrix function my_householder (real vector a, real scalar N, real matrix H)
* {
*     real scalar i, j
*     real scalar anorm, adot
*
*     if ( a[1] < 0 ) {
*         anorm = -my_norm(a, N)
*     }
*     else {
*         anorm = my_norm(a, N)
*     }
*
*     adot = 1;
*     for (i = N; i > 1; i--) {
*         a[i] = a[i] / (a[1] + anorm)
*         adot = adot + a[i] * a[i];
*     }
*
*     a[1] = 1
*     adot = 2 / adot
*     for (i = 1; i <= N; i++) {
*         H[i, i] = 1 - adot * a[i] * a[i]
*         for (j = i + 1; j <= N; j++) {
*             H[i, j] = -adot * a[i] * a[j]
*         }
*     }
*
*     for (i = 1; i <= N; i++) {
*         for (j = 1; j < i; j++) {
*             H[i, j] = H[j, i]
*         }
*     }
*
*     return(H)
* }
*
* real scalar function my_dot (real vector a, real scalar N)
* {
*     real scalar i
*     real scalar dot
*     dot = 0
*     for (i = 1; i <= N; i++) {
*         dot = dot + a[i] * a[i]
*     }
*     return (dot)
* }
*
* real scalar function my_norm (real vector a, real scalar N)
* {
*     return (sqrt(my_dot(a, N)))
* }
* end

* IV via mata
* -----------

* mata: w  = st_data(., "w")
* mata: y  = st_data(., "price")
* mata: X  = st_data(., "mpg")
* mata: E  = st_data(., "weight turn ones")
* mata: Z  = st_data(., "gear_ratio")
* mata: ZZ = (E, Z)' * diag(w) * (E, Z)
* mata: Zi = invsym(ZZ)
* mata: PZ = (E, Z)' * diag(w) * X
* mata: BZ = Zi * PZ
* mata: PX = (E, Z) * BZ, E
* mata: XX = PX' * diag(w) * PX
* mata: Xi = invsym(XX)
* mata: Xy = PX' * diag(w) * y
* mata: b  = Xi * Xy
* mata: e  = y :- (X, E) * b
* mata: DD = PX' * diag(w :* e:^2) * PX
* mata: V  = Xi * DD * Xi
* mata: ZZ
* mata: PZ
* mata: BZ
* mata: XX
* mata: Xy
* mata: b
* mata: V

