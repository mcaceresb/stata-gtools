*! version 0.1.0 03Nov2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! faster implementation of xtile and fastxtile using C for faster processing

capture program drop fasterxtile
program define fasterxtile
    version 13

    if ( `=_N < 1' ) {
        error 2000
    }

    global GTOOLS_CALLER gquantiles
    syntax newvarname =/exp,        /// newvar = exp
        [if] [in] ,                 /// [if condition] [in start / end]
    [                               ///
        Nquantiles(str)             /// Number of quantiles
        Cutpoints(varname numeric)  /// Use cutpoints instead of percentiles of `exp'
        ALTdef                      /// Alternative definition
                                    ///
        by(str)                     /// By variabes: [+|-]varname [[+|-]varname ...]
        replace                     /// Replace newvar, if it exists
        MISSing                     /// Replace newvar, if it exists
                                    ///
        Verbose                     /// Print info during function execution
        BENCHmark                   /// Benchmark function
        BENCHmarklevel(int 0)       /// Benchmark various steps of the plugin
        hashlib(passthru)           /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru)       /// error|fallback: On collision, use native command or throw error
                                    ///
        gen(passthru)               ///
        tag(passthru)               ///
        counts(passthru)            ///
        fill(passthru)              ///
    ]

	if ( "`nquantiles'" != "" ) {
		if ( "`cutpoints'" != "" ) {
			di as err "both nquantiles() and cutpoints() " ///
			          "cannot be specified"
			exit 198
		}

		if ( `nquantiles' < 2 ) {
			di as err "nquantiles() must be greater than or " ///
                      "equal to 2"
			exit 198
		}

		* Implement this internally
		* -------------------------

		* qui count if `touse'
		* if ( `nquanti' > `=`r(N)' + 1' ) {
		* 	di in red "nquantiles() must be less than or " ///
        *               "equal to number of observations plus one"
		* 	exit 198
		* }
	}
	else if ( "`cutpoints'" == "" ) {
		local nquantiles 2
	}
    else {
		local nquantiles 0
    }

    local nquantiles nquantiles(`nquantiles')
    local cutpoints  cutpoints(`cutpoints')

    local fallback `varlist' = `exp' `if' `in', `nquantiles' `cutpoints' `altdef'
    local fallback_ok = ( "`by'`replace'" != "" )

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    * exp is either a numeric variable list or an expression
    * ------------------------------------------------------

    cap confirm var numeric `exp'
    if ( _rc ) {
        tempvar touse xvars
        mark `touse' `if' `in'
        qui gen double `xvars' = `exp' if `touse'
        local ifin if `touse' in `in'
    }
    else {
        local xvars `exp'
        local ifin  `if' `in'
    }

    * Pass arguments to internals
    * ---------------------------

    local  opts `verbose' `benchmark' `benchmarklevel' `hashlib' `oncollision'
    local  opts `opts' `gen' `tag' `counts' `fill'
    local gopts gquantiles(`varlist', gen xvars(`xvars') `missing' `nquantiles' `cutpoints' `altdef')
    cap noi _gtools_internal `by' `ifin', missing unsorted `opts' `gopts' gfunction(quantles)
    global GTOOLS_CALLER ""
    local rc = _rc

    if ( `rc' == 17999 ) {
        if ( `fallback_ok' ) {
            xtile `fallback'
            exit 0
        }
        else {
            disp as err "Cannot use fallback with -by- or -replace-"
            exit 17000
        }
    }
    else if ( `rc' ) exit `rc'

    if ( "`by'" != "" ) {
        return scalar N      = `r(N)'
        return scalar J      = `r(J)'
        return scalar minJ   = `r(minJ)'
        return scalar maxJ   = `r(maxJ)'
    }
end
