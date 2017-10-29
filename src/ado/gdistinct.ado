*! version 0.1.3 29Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -distinct- implementation using C for faster processing

capture program drop gdistinct
program gdistinct, rclass
    version 13

    if ( `=_N < 1' ) {
        di as err "no observations"
        exit 2000
    }

    global GTOOLS_CALLER gunique
    syntax [varlist] [if] [in] ,  ///
    [                             ///
        MISSing                   /// include missing values
        Joint                     /// report distinct values for varlist jointly
        MINimum(int 0)            /// Report distinct only for groups with at least min
        MAXimum(int -1)           /// Report distinct only for groups with at most max
        Abbrev(int -1)            /// Abbrev print of var names
        Verbose                   /// debugging
        Benchmark                 /// print benchmark info
        hashlib(passthru)         /// path to hash library (Windows)
        oncollision(passthru)     /// On collision, fall back or error
    ]

	if ( `maximum' == -1 ) local maximum .

	if ( `minimum' > `maximum' ) {
		local swap    `minimum'
		local minimum `maximum'
		local maximum `swap'
		di as txt "min(`maximum') max(`minimum') interpreted as min(`minimum') max(`maximum')"
	}

    local opts `missing' `verbose' `benchmark' `hashlib' `oncollision'
	if ( "`joint'" != "" ) {
        cap noi _gtools_internal `varlist' `if' `in', countonly unsorted `opts' gfunction(unique)
        local r_N         = `r(N)'
        local r_J         = `r(J)'
        local r_ndistinct = `r(J)'
        local r_minJ      = `r(minJ)'
        local r_maxJ      = `r(maxJ)'

        local rc  = _rc
        global GTOOLS_CALLER ""
        if ( `rc' == 17999 ) {
            distinct `varlist' `if' `in', `missing' `joint' min(`minimum') max(`maximum') a(`abbrev')
            exit 0
        }
        else if ( `rc' == 17001 ) {
            exit 0
        }
        else if ( `rc' ) exit `rc'

		di
		di in text "        Observations"
		di in text "      total   distinct"
		if ( (`r_J' >= `minimum') & (`r_J' <= `maximum') ) {
            di as res %11.0g `r_N' "  " %9.0g `r_J'
		}
    }
    else {
		if ( `abbrev' == -1 ) {
			foreach v of local varlist {
				local abbrev = max(`abbrev', length("`v'"))
			}
		}

		local abbrev = max(`abbrev', 5)
		local abbp2  = `abbrev' + 2
		local abbp3  = `abbrev' + 3

        local k = 0
        mata: __gtools_distinct = J(2, `:list sizeof varlist', "")
		foreach v of local varlist {
            cap noi _gtools_internal `v' `if' `in', countonly unsorted `opts' gfunction(unique)
            local r_N         = `r(N)'
            local r_J         = `r(J)'
            local r_ndistinct = `r(J)'
            local r_minJ      = `r(minJ)'
            local r_maxJ      = `r(maxJ)'

            local rc  = _rc
            if ( `rc' == 17999 ) {
                global GTOOLS_CALLER ""
                distinct `varlist' `if' `in', `missing' `joint' min(`minimum') max(`maximum') a(`abbrev')
            }
            else if ( `rc' == 17001 ) {
                global GTOOLS_CALLER ""
                cap mata: mata drop __gtools_distinct
                exit 0
            }
            else if ( `rc' ) {
                global GTOOLS_CALLER ""
                cap mata: mata drop __gtools_distinct
                exit `rc'
            }

            if ( (`r_J' >= `minimum') & (`r_J' <= `maximum') ) {
                local ++k
                mata: __gtools_distinct[1, `k'] = `"" " as txt %`abbrev's abbrev("`v'", `abbrev')"'
                mata: __gtools_distinct[2, `k'] = `"" {c |}  " as res %9.0g `r_N' "  " %9.0g `r_J'"'
            }
		}

		di
		di as txt _col(`abbp3') "{c |}        Observations"
		di as txt _col(`abbp3') "{c |}      total   distinct"
		di as txt "{hline `abbp2'}{c +}{hline 22}"
        forvalues i = 1 / `k' {
            mata: st_local("d1", __gtools_distinct[1, `i'])
            mata: st_local("d2", __gtools_distinct[2, `i'])
            di `d1' ///
            `d2'
        }
        cap mata: mata drop __gtools_distinct
    }

    return scalar N         = `r_N'
    return scalar J         = `r_J'
    return scalar ndistinct = `r_J'
    return scalar minJ      = `r_minJ'
    return scalar maxJ      = `r_maxJ'
end

