*! version 0.1.0 18Aug2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Implementation of grouped regressions with HDFE

capture program drop gregress
program gregress, rclass
    version 13.1
    global GREG_RC 0
    global GTOOLS_CALLER gregress

    if ( `=_N < 1' ) {
        global GREG_RC 17001
        di as txt "no observations"
        exit 0
    }

    * syntax varlist(numeric ts fv) // a way to support this would be to filter it through mata
    * syntax anything(equalok)      // iv syntax
    syntax varlist(numeric)       /// depvar indepvars
        [if] [in]                 /// [if condition] [in start / end]
        [aw fw pw iw] ,           /// [weight type = exp]
    [                             ///
        by(str)                   /// Winsorize options
        noMISSing                 /// Exclude groups with any missing values by level
        Robust                    /// Robust SE
        cluster(str)              /// Cluster by varlist
        absorb(str)               /// Absorb each var in varlist as FE 
        poisson                   /// Poisson regression
        *                         /// Regress options
                                  ///
        compress                  /// Try to compress strL variables
        forcestrl                 /// Force reading strL variables (stata 14 and above only)
        Verbose                   /// Print info during function execution
        _CTOLerance(passthru)     /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                 /// Benchmark function
        BENCHmarklevel(int 0)     /// Benchmark various steps of the plugin
        HASHmethod(passthru)      /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)     /// error|fallback: On collision, use native command or throw error
        debug(passthru)           /// Print debugging info to console
    ]

    disp as txt "{bf:warning} gregress is beta software; use with caution"

    if ( `"`missing'"' == "nomissing" ) local missing
    else local missing missing

    if ( `"`by'"' != "" ) unab by: `by'

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    * NOTE(mauricio): We always make a todo variable because we want to
    * exclude missing values in varlist.

	if ( `"`weight'"' != "" ) {
		tempvar touse w
		qui gen double `w' `exp' `if' `in'
		local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        mark `touse' `if' `in' `wgt'
        markout `touse' `varlist' `cluster' `absorb'
        local if if `touse'
	}
    else {
        local weights
        local _varlist: copy local varlist
        local varlist `varlist' `cluster' `absorb'
        marksample touse, strok
        local varlist: copy local _varlist
        local if if `touse'
    }

    if ( `"`poisson'"' != "" ) {
        gettoken y x: varlist
        qui count if (`y' < 0) & `touse'
        if ( `r(N)' > 0 ) {
            disp as err "`y' must be non-negative"
            exit 198
        }
        qui count if (`y' != int(`y')) & `touse'
        if ( `r(N)' > 0 ) {
            disp as txt "{bf:note} you are responsible for interpretation of noncount dep. variable"
        }
    }

    local options `options' `robust' cluster(`cluster') absorb(`absorb') `poisson'
    local opts    `weights' `compress' `forcestrl' nods unsorted `missing'
    local opts    `opts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local opts    `opts' `oncollision' `hashmethod' `debug'
    local greg    gfunction(regress) gregress(`varlist', `options')

    cap noi _gtools_internal `by' `if' `in', `opts' `greg'
    local rc = _rc
    global GTOOLS_CALLER ""

    * Cleanup
    * -------

    if ( `rc' == 17999 ) {
        exit 17000
    }
    else if ( `rc' == 18401 ) {
        exit 2001
    }
    else if ( `rc' == 17001 ) {
        global GREG_RC 17001
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) exit `rc'

    * Returns
    * -------

    return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'
end
