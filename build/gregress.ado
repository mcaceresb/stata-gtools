*! version 0.2.0 25Aug2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Estimate linear regression via OLS by group and with HDFE

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
    syntax anything(equalok)      /// depvar indepvars
        [if] [in]                 /// [if condition] [in start / end]
        [aw fw pw iw] ,           /// [weight type = exp]
    [                             ///
        by(str)                   /// Winsorize options
        noMISSing                 /// Exclude groups with any missing values by level
        Robust                    /// Robust SE
        cluster(str)              /// Cluster by varlist
        absorb(str)               /// Absorb each var in varlist as FE
        POISson                   /// Poisson regression
        IVregress                 /// IV regression
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

    * Parse IV syntax

    * NOTE(mauricio): IV will only be allowed with input colmajor.
    
    * NOTE(mauricio): I put the instruments at the start so I can add a
    * constant. I will only have one memory alloc to X and then point to
    * ivz = X, ivendog = X + kz * N, ivexog = X + (kz + kendog) + N

    local ivok 0
    if regexm(`"`anything'"', ".+\((.+=.+)\)") {
        local iveq   = regexr(regexs(1), "\(|\)", "")
        local ivexog = trim(regexr("`anything'", "\(.+=.+\)", ""))

        cap noi confirm var `ivexog'
        if ( _rc ) {
            disp as err "Error parsing IV syntax: No dependent variable detected"
            exit 198
        }

        gettoken ivendog ivinstruments: iveq, p(=)
        gettoken _ ivinstruments: ivinstruments

        cap noi confirm var `ivinstruments'
        if ( _rc ) {
            disp as err "Instruments required for IV"
            exit 198
        }

        cap noi confirm var `ivendog'
        if ( _rc ) {
            disp as err "Endogenous covariates required for IV"
            exit 198
        }

        unab ivexog:        `ivexog'
        unab ivendog:       `ivendog'
        unab ivinstruments: `ivinstruments'
        gettoken ivdepvar ivexog: ivexog

        local ivkendog: list sizeof ivendog
        local ivkexog:  list sizeof ivexog
        local ivkz:     list sizeof ivinstruments

        if ( `ivkz' < `ivkendog' ) {
            disp as error "Need at least as many instruments as endogenous variables (received `ivkz' < `ivkendog')"
            exit 198
        }

        unab  varlist: `ivdepvar' `ivendog' `ivexog' `ivinstruments'
        local ivopts ivkendog(`ivkendog') ivkexog(`ivkexog') ivkz(`ivkz')
        local ivregress ivregress
        local ivok 1
    }
    else {
        unab varlist: `anything'
    }

    confirm var `varlist'
    if ( `:list sizeof varlist' == 1 ) {
        disp as err "constant-only models not allowed; varlist required"
        exit 198
    }

    if ( (`ivok' == 0) & ("`ivregress'" != "") ) {
        disp as err "Could not parse input into IV syntax"
        exit 198
    }

    if ( ("`ivregress'" != "") & ("`poisson'" != "") ) {
        disp as err "Input error: IV and poisson requested at the same time"
        exit 198
    }

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
    local greg    gfunction(regress) gregress(`varlist', `options' `ivopts')

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
