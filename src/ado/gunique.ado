*! version 0.2.0 31Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -unique- implementation using C for faster processing

capture program drop gunique
program gunique, rclass
    version 13

    if ( `=_N < 1' ) {
        di as err "no observations"
        exit 2000
    }

    global GTOOLS_CALLER gunique
    syntax varlist [if] [in] , ///
    [                          ///
        Detail                 /// Summary statistics for group counts
        MISSing                /// Include missing values
        Verbose                /// Print info during function execution
        Benchmark              /// Benchmark various steps of the plugin
        hashlib(passthru)      /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru)  /// error|fallback: On collision, use native command or throw error
                               ///
                               /// Unused unique options
                               /// -------------------
        by(varname)            ///
        GENerate(name)         ///
    ]

    if ( "`by'" != "" ) {
        di as err "Option -by()- is not implemented"
        exit 198
    }

    if ( "`generate'" != "" ) {
        di as err "Option -generate()- is not implemented"
        exit 198
    }

    local opts `missing' `verbose' `benchmark' `hashlib' `oncollision' seecount
    if ( "`detail'" != "" ) {
        tempvar count
        local dopts counts(`count') fill(data)
        cap noi _gtools_internal `varlist' `if' `in', unsorted `opts' `dopts'  gfunction(unique)
        local rc = _rc
        global GTOOLS_CALLER ""

        if ( `rc' == 17999 ) {
            unique `varlist' `if' `in', `detail'
            exit 0
        }
        else if ( `rc' == 17001 ) {
            exit 0
        }
        else if ( `rc' ) exit `rc'

        return scalar N      = `r(N)'
        return scalar J      = `r(J)'
        return scalar unique = `r(J)'
        return scalar minJ   = `r(minJ)'
        return scalar maxJ   = `r(maxJ)'

        sum `count' in 1 / `=r(J)', d
    }
    else {
        cap noi _gtools_internal `varlist' `if' `in', countonly unsorted `opts' gfunction(unique)
        local rc = _rc
        global GTOOLS_CALLER ""

        if ( `rc' == 17999 ) {
            unique `varlist' `if' `in', `detail'
            exit 0
        }
        else if ( `rc' == 17001 ) {
            exit 0
        }
        else if ( `rc' ) exit `rc'

        return scalar N      = `r(N)'
        return scalar J      = `r(J)'
        return scalar unique = `r(J)'
        return scalar minJ   = `r(minJ)'
        return scalar maxJ   = `r(maxJ)'
    }
end
