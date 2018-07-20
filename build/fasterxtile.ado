*! version 0.7.1 19Jul2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! faster implementation of xtile and fastxtile using C for faster processing
*! (note: this is a wrapper for gquantiles)

capture program drop fasterxtile
program define fasterxtile
    version 13

    if ( `=_N < 1' ) {
        error 2000
    }

	_parsewt "aweight fweight pweight" `0'
	local 0   `"`s(newcmd)'"'  /* command minus weight statement   */
	local wgt `"`s(weight)'"'  /* contains [weight=exp] or nothing */

    syntax newvarname =/exp        /// newvar = exp
        [if] [in] ,                /// [if condition] [in start / end]
    [                              ///
        by(passthru)               /// By variabes: [+|-]varname [[+|-]varname ...]
        Nquantiles(str)            /// Number of quantiles
        Cutpoints(varname numeric) /// Use cutpoints instead of percentiles
        ALTdef                     /// Alternative definition
                                   ///
        method(passthru)           /// Quantile method: (1) qsort, (2) qselect
        strict                     /// Exit if nquantiles > # non-missing obs
        Verbose                    /// Print info during function execution
        BENCHmark                  /// Benchmark function
        BENCHmarklevel(passthru)   /// Benchmark various steps of the plugin
        HASHmethod(passthru)       /// Hashing method: 1 (biject), 2 (spooky)
        hashlib(passthru)          /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru)      /// error|fallback: On collision, use native command or throw error
                                   ///
        compress                   ///
        debug(passthru)            ///
        GROUPid(passthru)          ///
        tag(passthru)              ///
        counts(passthru)           ///
        fill(passthru)             ///
    ]

	if ( (`"`weight'"' != "") & ("`altdef'" != "") ) {
		di in err "altdef option cannot be used with weights"
        exit 198
	}

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

        * if ( `nquantiles' > `=_N + 1' ) {
        *     di as err "nquantiles() must be less than or equal to " ///
        *               "number of observations plus one"
		* 	exit 198
        * }
        local nquantiles nquantiles(`nquantiles')
	}
	else if ( "`cutpoints'" == "" ) {
        local nquantiles nquantiles(2)
	}

    if ( "`cutpoints'" != "" ) {
        unab cutpoints: `cutpoints'
        local cutpoints cutpoints(`cutpoints')
    }

    local   opts `verbose'        ///
                 `benchmark'      ///
                 `benchmarklevel' ///
                 `hashlib'        ///
                 `oncollision'    ///
                 `hashmethod'     ///
                 `compress'       ///
                 `replace'        ///
                 `groupid'        ///
                 `debug'          ///
                 `tag'            ///
                 `counts'         ///
                 `fill'

    local gqopts `nquantiles' `cutpoints' `altdef' `strict' `opts' `method'
    gquantiles `varlist' = `exp' `if' `in' `wgt', xtile `gqopts' `by'
end
