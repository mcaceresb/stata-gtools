*! version 0.5.5 16Jan2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -isid- implementation using C for faster processing

capture program drop gisid
program gisid
    version 13

    global GTOOLS_CALLER gisid
    syntax varlist            /// Variables to check
        [if] [in] ,           /// [if condition] [in start / end]
    [                         ///
        Missok                /// Missing values in varlist are OK
        Verbose               /// Print info during function execution
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        hashlib(passthru)     /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
                              ///
                              /// Unsupported isid options
                              /// ------------------------
        Sort                  ///
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

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

    local opts `miss' `verbose' `benchmark' `benchmarklevel' `hashlib' `oncollision' `hashmethod'
    cap noi _gtools_internal `varlist' `if' `in', unsorted `opts' gfunction(isid)
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 17999 ) {
        isid `varlist' `if' `in', `missok'
        exit 0
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) exit `rc'
end
