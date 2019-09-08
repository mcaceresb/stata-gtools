capture program drop checks_gregress
program checks_gregress
    local tol 1e-8

    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)

    foreach v in v1 v2 vv5 v7 {
        disp "greg checks `v'"
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [aw = w]
        if ( "`v'" == "v6" ) local w [aw = w]

        if ( "`v'" == "v7" ) local w [pw = w]
        if ( "`v'" == "v8" ) local w [pw = w]

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

    local tol 1e-4
    webuse ships, clear
    expand 2
    gen by = 1.5 - (_n < _N / 2)
    gen w = _n
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

        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship) `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')

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

        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) r
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')

        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) cluster(ship)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')

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
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

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

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

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
    greg y x1 x2 x3 x4, r mata(r1)
    greg y x1 x2 x3 x4, cluster(g) mata(r1)
    greg y x1 x2 x3 x4, absorb(g)

    greg y x1 x2 x3 x4 [fw = w], mata(r1)
    greg y x1 x2 x3 x4 [fw = w], r mata(r1)
    greg y x1 x2 x3 x4 [fw = w], cluster(g) mata(r1)
    greg y x1 x2 x3 x4 [fw = w], absorb(g)

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    if ( `c(MP)' ) {
        local tol 1e-8
        clear all
        set matsize 10000
        set maxvar 50000
        set obs 10000
        gen g = ceil(runiform()*10)
        gen e = rnormal() * 5
        forvalues i = 1 / 1000 {
            gen x`i' = rnormal() * `i' + `i'
        }
        gen y = - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e

        greg y x*, mata(r1)

        * Fairly slow...
        greg y x*, cluster(g) mata(r1)
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
