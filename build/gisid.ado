*! version 0.3.0 31Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -isid- implementation using C for faster processing

capture program drop gisid
program gisid
    version 13

    global GTOOLS_CALLER gisid
    syntax varlist              /// Variables to check
        [if] [in] ,             /// [if condition] [in start / end]
    [                           ///
        Missok                  /// Missing values in varlist are OK
        Verbose                 /// Print info during function execution
        Benchmark               /// Benchmark various steps of the plugin
        hashlib(passthru)       /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru)   /// error|fallback: On collision, use native command or throw error
                                ///
                                /// Unsupported isid options
                                /// ------------------------
        Sort                    ///
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
