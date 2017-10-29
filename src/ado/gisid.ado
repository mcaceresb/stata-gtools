*! version 0.2.4 29Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -isid- implementation using C for faster processing

capture program drop gisid
program gisid
    version 13

    global GTOOLS_CALLER gisid
    syntax varlist [if] [in] , ///
    [                          ///
        Missok                 /// missing ok
        Verbose                /// debugging
        Benchmark              /// print benchmark info
        hashlib(passthru)      /// path to hash library (Windows)
        oncollision(passthru)  /// On collision, fall back or error
                               ///
                               /// Unused isid options
                               /// -------------------
        Sort                   ///
    ]

    if ( "`sort'" != "" ) {
        di as err "Option -sort- is not implemented"
        exit 198
    }

    if ( "`missok'" == "" ) {
        local miss exitmissing
    }
    else {
        local miss missing
    }

    local opts `miss' `verbose' `benchmark' `hashlib' `oncollision'
    cap noi _gtools_internal `varlist' `if' `in', unsorted `opts' gfunction(isid)
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 17999 ) {
        isid `varlist' `if' `in', `missok'
        exit 0
    }
    else if ( `rc' == 17001 ) {
        exit 0
    }
    else if ( `rc' ) exit `rc'
end
