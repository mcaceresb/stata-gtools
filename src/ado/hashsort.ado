*! version 1.0.1 23Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Hash-based implementation of -sort- and -gsort- using C-plugins

capture program drop hashsort
program define hashsort
    version 13.1

    global GTOOLS_CALLER hashsort
    syntax anything,           /// Variables to sort by: [+|-]varname [[+|-]varname ...]
    [                          ///
        GENerate(passthru)     /// Generate variable with sort order
        replace                /// Replace generated variable, if it exists
        sortgen                /// Sort by generated variable, if applicable
        skipcheck              /// Turn off internal is sorted check
                               ///
        compress               /// Try to compress strL variables
        forcestrl              /// Force reading strL variables (stata 14 and above only)
        Verbose                /// Print info during function execution
        _CTOLerance(passthru)  /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark              /// Benchmark function
        BENCHmarklevel(int 0)  /// Benchmark various steps of the plugin
        HASHmethod(passthru)   /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)  /// error|fallback: On collision, use native command or throw error
        debug(passthru)        /// Print debugging info to console
                               ///
        tag(passthru)          ///
        counts(passthru)       ///
        fill(passthru)         ///
        invertinmata           ///
                               ///
                               /// Unsupported sort options
                               /// ------------------------
                               ///
        stable                 /// Hashsort is always stable
        mlast                  ///
        Mfirst                 ///
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( "`stable'" != "" ) {
        di as txt "hashsort is always -stable-"
    }

    * mfirst is set by default, unlike gsort
    if ( ("`mfirst'" != "") & ("`mlast'" != "") ) {
        di as err "Cannot request both {opt mfirst} and {opt mlast}"
    }

    * mfirst is set by default, unlike gsort
    if ( ("`mfirst'" == "") & ("`mlast'" == "") & (strpos("`anything'", "-") > 0) ) {
        di as txt "(note: missing values will be sorted first)"
    }

    * mfirst is set by default
    if ( ("`mfirst'" == "") & ("`mlast'" == "") ) {
        local mfirst mfirst
    }

    if ( "`generate'" != "" ) local skipcheck skipcheck

    local opts  `compress' `forcestrl' nods
    local opts  `opts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local opts  `opts' `oncollision' `hashmethod' `debug'
    local eopts `invertinmata' `sortgen' `skipcheck'
    local gopts `generate' `tag' `counts' `fill' `replace' `mlast'
    cap noi _gtools_internal `anything', missing `opts' `gopts' `eopts' gfunction(sort)
    global GTOOLS_CALLER ""
    local rc = _rc

    if ( `rc' == 17999 ) {
        if regexm("`anything'", "[\+\-]") {
            gsort `anything', `generate' `mfirst'
            exit 0
        }
        else {
            sort `anything'
            exit 0
        }
    }
    else if ( `rc' == 17001 ) {
        exit 0
    }
    else if ( `rc' ) exit `rc'
end
