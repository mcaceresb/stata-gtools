*! version 0.6.4 06Feb2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Hash-based implementation of -sort- and -gsort- using C-plugins

capture program drop hashsort
program define hashsort
    version 13

    global GTOOLS_CALLER hashsort
    syntax anything,           /// Variables to sort by: [+|-]varname [[+|-]varname ...]
    [                          ///
        GENerate(passthru)     /// Generate variable with sort order
        replace                /// Replace generated variable, if it exists
        sortgen                /// Sort by generated variable, if applicable
        skipcheck              /// Turn off internal is sorted check
                               ///
        Verbose                /// Print info during function execution
        BENCHmark              /// Benchmark function
        BENCHmarklevel(int 0)  /// Benchmark various steps of the plugin
        HASHmethod(passthru)   /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        hashlib(passthru)      /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru)  /// error|fallback: On collision, use native command or throw error
                               ///
        tag(passthru)          ///
        counts(passthru)       ///
        invertinmata           ///
                               ///
                               /// Unsupported sort options
                               /// ------------------------
                               ///
        stable                 /// Hashsort is always stable
        Mfirst                 ///
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( "`stable'" != "" ) {
        di as txt "hashsort is always -stable-"
    }

    if ( ("`mfirst'" == "") & (strpos("`anything'", "-") > 0) ) {
        di as txt "(note: missing values will be sorted first)"
    }

    if ( "`generate'" != "" ) local skipcheck skipcheck

    local  opts `verbose' `benchmark' `benchmarklevel' `hashlib' `oncollision' `hashmethod'
    local eopts `invertinmata' `sortgen' `skipcheck'
    local gopts `generate' `tag' `counts' `replace'
    cap noi _gtools_internal `anything', missing `opts' `gopts' `eopts' gfunction(sort)
    global GTOOLS_CALLER ""
    local rc = _rc

    if ( `rc' == 17999 ) {
        if regexm("`anything'", "[\+\-]") {
            gsort `anything', `generate' mfirst
            exit 0
        }
        else {
            sort `anything'
            exit 0
        }
    }
    else if ( `rc' ) exit `rc'
end
