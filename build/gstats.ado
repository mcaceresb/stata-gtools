*! version 0.1.2 16Dec2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Implementation of several statistical functions and transformations

capture program drop gstats
program gstats, rclass
    version 13.1
    global GTOOLS_CALLER gstats

    gettoken stat 0: 0
    local stats dir winsor

    if ( `"`stat'"' == "" ) {
        disp as err "Nothing to do. See {help gstats:help gstats} or {stata gstats dir}."
        exit 198
    }

    if ( !`:list stat in stats' ) {
        disp as err "Unknown stat `stats'. See {help gstats:help gstats} or {stata gstats dir}."
        exit 198
    }

    if ( `"`stat'"' == "dir" ) {
        gettoken dir stats: stats
        disp as txt "Available:"
        foreach stat of local stats {
            disp as txt "    {help gstats `stat'}"
        }
        exit 0
    }

    syntax varlist            /// Variables to check
        [if] [in]             /// [if condition] [in start / end]
        [aw fw pw iw] ,       /// [weight type = exp]
    [                         ///
        *                     /// Options for subprograms
        by(varlist)           /// Winsorize options
                              ///
        compress              /// Try to compress strL variables
        forcestrl             /// Force reading strL variables (stata 14 and above only)
        Verbose               /// Print info during function execution
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        hashlib(passthru)     /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
        debug(passthru)       /// Print debugging info to console
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

	if ( `"`weight'"' != "" ) {
		tempvar touse w
		qui gen double `w' `exp' `if' `in'
		local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        mark `touse' `if' `in' `wgt'
        local if if `touse'
	}
    else local weights

    local opts   `weights' `compress' `forcestrl' nods unsorted
    local opts   `opts' `verbose' `benchmark' `benchmarklevel'
    local opts   `opts' `hashlib' `oncollision' `hashmethod' `debug'
    local gstats  gfunction(stats) gstats(`stat' `varlist', `options')

    cap noi _gtools_internal `by' `if' `in', `opts' `gstats'
    local rc = _rc
    global GTOOLS_CALLER ""

    return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'
    if ( `"`stat'"' == "winsor" ) {
        return scalar cutlow  = r(gstats_winsor_cutlow)
        return scalar cuthigh = r(gstats_winsor_cuthigh)
    }

    if ( `rc' == 17999 ) {
        exit 17000
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) exit `rc'

    * return add
end
