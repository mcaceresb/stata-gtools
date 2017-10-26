*! version 0.2.0 24Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -isid- implementation using C for faster processing

capture program drop glevelsof
program glevelsof, rclass
    version 13

    if ( `=_N < 1' ) {
        di as err "no observations"
        exit 2000
    }

    global GTOOLS_CALLER glevelsof
    syntax varlist [if] [in] , ///
    [                          ///
        Separate(passthru)     /// Levels sepparator
        COLSeparate(passthru)  /// Columns sepparator
        MISSing                /// Include missing values
        LOCal(str)             /// Store results in local
        Clean                  /// Clean strings
        silent                 /// Do not print levels
                               ///
        Verbose                /// debugging
        Benchmark              /// print benchmark info
        hashlib(passthru)      /// path to hash library (Windows)
        oncollision(passthru)  /// On collision, fall back or error
                               ///
        group(str)             ///
        tag(passthru)          ///
        counts(passthru)       ///
        replace                ///
    ]

    local opts  `separate' `missing' `clean'
    local sopts `colseparate' `verbose' `benchmark' `hashlib' `oncollision'
    local gopts gen(`group') `tag' `counts' `replace'
    cap noi _gtools_internal `varlist' `if' `in', `opts' `sopts' `gopts' gfunction(levelsof)
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 41999 ) {
        if ( `:list sizeof varlist' > 1 ) {
            di as err "Cannot use fallback with more than one variable."
            exit 42000
        }
        else {
            levelsof `varlist' `if' `in', `opts'
            exit 0
        }
    }
    else if ( `rc' == 42001 ) {
        exit 0
    }
    else if ( `rc' ) exit `rc'

    if ( `:list sizeof varlist' == 1 ) {
        cap confirm numeric variable `varlist'
        if ( _rc == 0 ) {
            local vals `"`r(levels)'"'
            local vals: subinstr local vals " 0." " .", all
            local vals: subinstr local vals "-0." "-.", all
            if ( "`local'"  != "" ) c_local `local' `"`vals'"'
            if ( "`silent'" == "" ) di as txt `"`vals'"'
            return local levels `"`vals'"'
        }
        else {
            if ( "`local'"  != "" ) c_local `local' `"`r(levels)'"'
            if ( "`silent'" == "" ) di as txt `"`r(levels)'"'
            return local levels `"`r(levels)'"'
        }
    }
    else {
        if ( "`local'"  != "" ) c_local `local' `"`r(levels)'"'
        if ( "`silent'" == "" ) di as txt `"`r(levels)'"'
        return local levels `"`r(levels)'"'
    }

    return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'
end
