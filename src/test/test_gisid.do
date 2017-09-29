capture program drop checks_isid
program checks_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(5000) nj(100) njsub(4) string groupmiss outmiss
    gen ix = _n

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap gisid `by', `options' v b missok
        assert _rc == 459

        cap gisid `by' in 1, `options'
        assert _rc == 0

        cap gisid `by' if _n == 1, `options'
        assert _rc == 0

        cap gisid `by' if _n < 10 in 5, `options'
        assert _rc == 0
    }

    clear
    gen x = 1
    cap gisid x
    assert _rc == 0
end

capture program drop compare_isid
program compare_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss
    gen ix = _n

    local i 0
    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by rsort rnorm groupsub groupstr
        if ( `i' == 3 ) local by rsort rnorm groupstr
        if ( `i' == 6 ) local by rsort rnorm groupsub group
        if ( `i' == 9 ) local by rsort rnorm grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by ix groupsub groupstr
        if ( `i' == 3 ) local by ix groupstr
        if ( `i' == 6 ) local by ix groupsub group
        if ( `i' == 9 ) local by ix grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    qui replace ix = `=_N / 2' if _n > `=_N / 2'
    cap isid ix
    local rc_isid = _rc
    cap gisid ix, `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by(ix)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by ix groupsub groupstr
        if ( `i' == 3 ) local by ix groupstr
        if ( `i' == 6 ) local by ix groupsub group
        if ( `i' == 9 ) local by ix grouplong

        preserve
            qui keep in 100 / `=ceil(`=_N / 2')'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' in 100 / `=ceil(`=_N / 2')', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' in 100 / `=ceil(`=_N / 2')')

        preserve
            qui keep in `=ceil(`=_N / 2')' / `=_N'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' in `=ceil(`=_N / 2')' / `=_N', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' in `=ceil(`=_N / 2')' / `=_N')

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        preserve
            qui keep if _n < `=_N / 2'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n < `=_N / 2', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' if _n < `=_N / 2')

        preserve
            qui keep if _n > `=_N / 2'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n > `=_N / 2', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' if _n > `=_N / 2')

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        qui replace ix = 100 in 1 / 100

        preserve
            qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')')

        preserve
            qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N')

        qui replace ix = _n in 1 / 100
    }
end

capture program drop check_rc
program check_rc
    syntax anything, by(str)

    tokenize `anything'
    local rc_isid  `1'
    local rc_gisid `2'

    if ( `rc_isid' != `rc_gisid' ) {
        if ( `rc_isid' & (`rc_gisid' == 0) ) {
            di as err "    compare_isid (failed): isid `by' was an id but gisid returned error r(`rc_isid')"
            exit `rc_gisid'
        }
        else if ( (`rc_isid' == 0) & `rc_gisid' ) {
            di as err "    compare_isid (failed): gisid `by' was an id but isid returned error r(`rc_gisid')"
            exit `rc_isid'
        }
        else {
            di as err "    compare_isid (failed): `by' was not an id but isid and gisid returned different errors r(`rc_isid') vs r(`rc_gisid')"
            exit `rc_gisid'
        }
    }
    else {
        if ( _rc ) {
            di as txt "    compare_isid (passed): `by' was not an id"
        }
        else {
            di as txt "    compare_isid (passed): `by' was an id"
        }
    }
end
