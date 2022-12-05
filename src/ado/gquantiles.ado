*! version 1.0.1 23Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! faster implementation of pctile, xtile, and _pctile using C plugins

capture program drop gquantiles
program gquantiles, rclass
    version 13.1

    if ( `=_N < 1' ) {
        error 2000
    }

    gtools_timer on 97

    global GTOOLS_CALLER gquantiles
    syntax [anything(equalok)]          /// newvar = exp, exp
        [if] [in]                       /// [if condition] [in start / end]
        [aw fw pw] ,                    /// [weight type = exp]
    [                                   ///
                                        /// Standard options
                                        /// ----------------
                                        ///
        Nquantiles(int 0)               /// Number of quantiles
        Cutpoints(passthru)             /// Use cutpoints instead of percentiles of `exp'
        Percentiles(str)                /// Percentiles to compute
        ALTdef                          /// Alternative definition
                                        ///
                                        /// Extras (ways to specify cutoffs)
                                        /// --------------------------------
                                        ///
        Quantiles(passthru)             /// Alias for percentiles
        cutoffs(passthru)               /// Use specified cutoffs instead of quantiles
        quantmatrix(passthru)           /// Name of matrix with quantiles
        cutmatrix(passthru)             /// Name of matrix with cutoffs
        CUTQuantiles(passthru)          /// Use percentiles specified in cutquantiles
                                        ///
                                        /// Augmented standard options
                                        /// --------------------------
                                        ///
        returnlimit(real 1001)          /// Set to missing (.) to have no return limit; REALLY SLOW to tinker
        cutifin                         /// Read quantiles() or cutquantiles() within [if] [in]
        cutby                           /// Read quantiles() or cutquantiles() within [if] [in]
        dedup                           /// Remove duplicates from quantiles() or cutquantiles()
        _pctile                         /// Set return values in the style of pctile
        pctile                          /// Call pctile
        xtile                           /// Call xtile
        PCTILEvar(name)                 /// Compute pctile when xtile is main call
        XTILEvar(name)                  /// Compute xtile when pctile is main call
        GENp(name)                      /// Store bin counts for nq/cutpoints/percentiles/etc.
                                        ///
                                        /// Extras (Other)
                                        /// --------------
                                        ///
        binfreq                         /// Return bin frequencies
        BINFREQvar(name)                /// Return bin count with options quantiles or cutoffs
                                        ///
        by(str)                         /// By variabes: [+|-]varname [[+|-]varname ...]
        replace                         /// Replace newvar, if it exists
        noinit                          /// Do not initialize targets with missing values
        strict                          /// Exit with error if nq < # if in and non-missing
        minmax                          /// Store r(min) and r(max) (pctiles must be in (0, 100))
        method(passthru)                /// Method to compute quantiles: (1) qsort, (2) qselect
                                        ///
                                        /// Standard gtools options
                                        /// -----------------------
                                        ///
        debug(passthru)                 /// Print debugging info to console
        compress                        /// Try to compress strL variables
        forcestrl                       /// Force reading strL variables (stata 14 and above only)
        Verbose                         /// Print info during function execution
        _CTOLerance(passthru)           /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                       /// Benchmark function
        BENCHmarklevel(int 0)           /// Benchmark various steps of the plugin
        HASHmethod(passthru)            /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)           /// error|fallback: On collision, use native command or throw error
                                        ///
        GROUPid(str)                    ///
        tag(passthru)                   ///
        counts(passthru)                ///
        fill(passthru)                  ///
    ]

    local if0:     copy local if
    local in0:     copy local in
    local weight0: copy local weight
    local exp0:    copy local exp
    mata st_local("ifin", st_local("if") + " " + st_local("in"))

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    local gfallbackmaybe = "`replace'`init'`by'`pctilevar'`xtilevar'`minmax'`cutoffs'`quantmatrix'`cutmatrix'`cutquantiles'`binfreq'`binfreqvar'" == ""

    local gen_pctile = ("`pctile'" != "") | ("`pctilevar'" != "")
    local gen_xtile  = ("`xtile'"  != "") | ("`xtilevar'"  != "")
    local gen_any    = `gen_pctile' | `gen_xtile'

    if ( (`gen_any' == 0) &  ("`_pctile'" == "") ) {
        di as err "Nothing to do. Specify _pctile, xtile[()], or pctile[()]"
        CleanExit
        exit 198
    }

    if ( ("`pctilevar'" == "") & ("`xtilevar'" == "") & ("`_pctile'" == "") & (strpos(`"`anything'"', "=") == 0) ) {
		di in txt "(note: no targets will be generated)"
    }

    local early_rc = 0
	if ( (`"`weight'"' != "") & ("`altdef'" != "") ) {
		di in err "altdef option cannot be used with weights"
        local early_rc = 198
	}

    if ("`pctile'" != "") & ("`xtile'" != "") {
        di as err "Specify only one of -xtile- or -pctile-."
        di as err "To specify a second variable, try -xtile()- or -pctile()-."
        local early_rc = 198
    }

    if ( ("`pctile'" != "") | ("`xtile'" != "") ) {
        if ( "`_pctile'" != "" ) {
            di as err "You should specify -xtile()- or -pctile()- if you want to call _pctile"
            local early_rc = 198
        }
    }

    if ( "`by'" != "" ) {
        if ( `gen_pctile' & ("`strict'" != "strict") ) {
            di as err "by() with -pctile- requires option -strict-"
            local early_rc = 198
        }

        if ( !(`gen_xtile') & !(`gen_pctile') ) {
            di as err "by() requires -xtile- or -pctile-"
            local early_rc = 198
        }

        if ( "`minmax'" != "" ) {
            di as err "by() does not allow option -minmax-"
            di as err"(note: you might be looking for {help gcollapse} with the -merge- option)"
            local early_rc = 198
        }

        if ( "`_pctile'" != "" ) {
            di as err "by() does not allow _pctile; try pctile[()]"
            local early_rc = 198
        }

        if ( "`binfreq'" != "" ) {
            di as err "by() does not allow -binfreq-"
            local early_rc = 198
        }

        if ( ("`binfreqvar'" != "") & ("`strict'" != "strict") ) {
            di as err "by() with -binfreq()- requires option -strict-"
            local early_rc = 198
        }

        if ( `gen_pctile' & ("`groupid'" == "") ) {
            disp as txt "Suggestion: by() with pctile() is more useful with groupid()"
        }

        if ( ("`binfreqvar'" != "") & ("`groupid'" == "") ) {
            disp as txt "Suggestion: by() with binfreq() is more useful with groupid()"
        }
    }

    * Can only specify one way of determining which quantiles to compute
    * ------------------------------------------------------------------

    if ( ("`quantiles'" != "") & ("`percentiles'" != "") ) {
        di as err "Options quantile() and percentiles() are redundant."
        local early_rc = 198
    }
    else if ("`quantiles'" == "") {
        local quantiles quantiles(`percentiles')
    }

    if ( ("`cutpoints'" != "") | ("`cutoffs'" != "") ) {
        if ( "`genp'" != "" ) {
            di as err "Option genp() not allowed with cutpoints() or cutoffs()"
            local early_rc = 198
        }
    }

    * Make sure variables to generate don't exist (or replace)
    * --------------------------------------------------------

    foreach togen in genp pctilevar xtilevar {
        if ( "``togen''" != "" ) {
            cap confirm new variable ``togen''
            if ( _rc & ("`replace'" == "") ) {
                di as err "Option `togen'() invalid; ``togen'' already exists."
                local early_rc = 198
            }
            local nvar : list sizeof `togen'
            if ( `nvar' > 1 ) {
                di as err "only one variable allowed in `togen'()"
                local early_rc = 198
            }
        }
    }

    if ( "`binfreqvar'" != "" ) {
        local binaddvar binfreqvar(`binfreqvar')
    }

    * Parse number of quantiles
    * -------------------------

    if ( (`nquantiles' > `=_N + 1') & ("`strict'" != "") ) {
        di in red "nquantiles() must be less than or equal to " /*
        */ "number of observations plus one"
        local early_rc = 198
    }
    if ( `nquantiles' >= 2 ) local fall_nq nquantiles(`nquantiles')
    local nquantiles nquantiles(`nquantiles')

    if ( `early_rc' ) {
        CleanExit
        exit `early_rc'
    }

    * Parse main call
    * ---------------

    local 0 `anything'
    cap syntax newvarname =/exp
    if ( _rc ) {
        cap syntax varname =/exp
        if ( _rc ) {
            cap confirm numeric var `anything'
            if ( _rc ) {
                tempvar touse xsources
                mark `touse' `ifin'
                cap gen double `xsources' = `anything' if `touse'
                if ( _rc ) {
                    if ( ("`xtile'" != "") | ("`pctile'" != "") ) {
                        CleanExit
                        di as err "Invalid syntax. Requried: newvarname = exp"
                        exit 198
                    }
                    else {
                        di as err "Invalid expression"
                        CleanExit
                        exit 198
                    }
                }
                local ifin if `touse' `in0'
            }
            else {
                local xsources `anything'
                local ifin: copy local ifin
            }
        }
        else if ( "`replace'" == "" ) {
            di as err "Variable `varlist' already exists"
            CleanExit
            exit 110
        }
        else if ( ("`xtile'" == "") & ("`pctile'" == "") ) {
            di as err "varname = exp requires option -xtile- or -pctile-"
            CleanExit
            exit 198
        }
        else {
            cap confirm numeric var `exp'
            if ( _rc ) {
                tempvar touse xsources
                mark `touse' `ifin'
                cap gen double `xsources' = `exp' if `touse'
                if ( _rc ) {
                    di as err "Invalid expression"
                    CleanExit
                    exit 198
                }
                local ifin if `touse' `in0'
            }
            else {
                local xsources `exp'
                local ifin: copy local ifin
            }
        }
    }
    else {
        if ( ("`xtile'" == "") & ("`pctile'" == "") ) {
            di as err "newvarname = exp requires option -xtile- or -pctile-"
            CleanExit
            exit 198
        }
        cap confirm numeric var `exp'
        if ( _rc ) {
            tempvar touse xsources
            mark `touse' `ifin'
            cap gen double `xsources' = `exp' if `touse'
            if ( _rc ) {
                di as err "Invalid expression"
                CleanExit
                exit 198
            }
            local ifin if `touse' `in0'
        }
        else {
            local xsources `exp'
            local ifin: copy local ifin
        }
    }

    cap unab xsources: `xsources'
    if ( _rc ) {
        disp "unable to parse source variables or expression"
        CleanExit
        exit 198
    }

    if ( `:list sizeof xsources' > 1 ) {
        disp "multiple sources not allowed"
        CleanExit
        exit 198
    }

    if ( "`binfreq'" != "" ) {
        local binadd binfreq
    }

    if ( "`pctile'" != "" ) local pctilevar `varlist'
    if ( "`xtile'"  != "" ) local xtilevar  `varlist'

    local genp    genp(`genp')
    local pctile  pctile(`pctilevar')
    local varlist `xtilevar'

    * Pass arguments to internals
    * ---------------------------

	if ( `"`weight0'"' != "" ) {
		tempvar touse0 w
		qui gen double `w' `exp0' `ifin'
		local wgt `"[`weight0'=`w']"'
        local weights weights(`weight0' `w')
        mark `touse0' `ifin' `wgt'
        local ifin if `touse0' `in0'
	}
    else local weights

    if ( ("`xtile'" != "") | ("`pctile'" != "") ) {
        local fallback `xtile'`pctile' `varlist' = `exp' `ifin' `wgt', `fall_nq' `cutpoints' `altdef'
    }
    else {
        local fallback _pctile `xsources' `ifin' `wgt', `fall_nq' `altdef' p(`percentiles')
    }

    local bench = ( "`benchmark'" != "" )
    local msg "Parsed quantile call"
    gtools_timer info 97 `"`msg'"', prints(`bench') off

    local opts `compress' `forcestrl' `_ctolerance'
    local opts `opts' `verbose' `benchmark' `benchmarklevel'
    local opts `opts' `oncollision' `hashmethod' `debug'
    local opts `opts' gen(`groupid') `tag' `counts' `fill' `weights'

    local gqopts `varlist', xsources(`xsources') `_pctile' `pctile' `genp'
    local gqopts `gqopts' `binadd' `binaddvar' `nquantiles' `quantiles'
    local gqopts `gqopts' `cutoffs' `cutpoints' `quantmatrix'
    local gqopts `gqopts' `cutmatrix' `cutquantiles' `cutifin' `cutby'
    local gqopts `gqopts' `dedup' `replace' `init' `altdef' `method' `strict'
    local gqopts `gqopts' `minmax' returnlimit(`returnlimit')

    cap noi _gtools_internal `by' `ifin', missing unsorted `opts' gquantiles(`gqopts') gfunction(quantiles)
    local rc = _rc

    if ( `rc' == 17999 ) {
        CleanExit
        if ( `gfallbackmaybe' ) {
            `fallback'
            exit 0
        }
        else {
            disp as err "(note: cannot use fallback)"
            exit 17000
        }
    }
    else if ( `rc' == 17001 ) {
        CleanExit
        exit 2000
    }
    else if ( `rc' ) {
        CleanExit
        exit `rc'
    }

    * Return values
    * -------------

    if ( "`binfreq'" == "" ) local bin pct
    if ( "`binfreq'" != "" ) local bin freq

    if ( "`by'" != "" ) {
        return scalar N      = `r(N)'
        return scalar Nx     = `r(Nxvars)'
        return scalar J      = `r(J)'
        return scalar minJ   = `r(minJ)'
        return scalar maxJ   = `r(maxJ)'
        CleanExit
        exit 0
    }
    else {
        return scalar N = `r(Nxvars)'
    }
    local Nx = `r(Nxvars)'

    if ( "`minmax'" != "" ) {
        return scalar min = r(min)
        return scalar max = r(max)
    }

    if ( "`quantiles'" != "" ) {
        return local quantiles = "`r(quantiles)'"
    }

    if ( "`cutoffs'" != "" ) {
        return local  cutoffs  = "`r(cutoffs)'"
    }

    if ( `r(nquantiles)' > 0 ) {
        return scalar nquantiles = `r(nquantiles)'
        local Nout = `r(nquantiles)' - 1
        local nqextra = "`r(nqextra)'"
        if ( `: list posof "quantiles" in nqextra' ) {
            mata: st_matrix("__gtools_r_qused", st_matrix("r(quantiles_used)")[1::`Nout']')
            return matrix quantiles_used = __gtools_r_qused
        }
        if ( `: list posof "bin" in nqextra' ) {
            mata: st_matrix("__gtools_r_qbin", st_matrix("r(quantiles_bincount)")[1::`Nout']')
            if ("`binfreq'" != "") {
                return matrix quantiles_binfreq = __gtools_r_qbin
            }
        }
        if ( "`_pctile'" != "" ) {
            local nreturn = cond(`returnlimit' > 0, min(`Nout', `returnlimit'), `Nout')
            if ( "`pctilevar'" != "" ) {
                forvalues i = 1 / `nreturn' {
                    return scalar r`i' = `pctilevar'[`i']
                }
            }
            else if ( `: list posof "quantiles" in nqextra' ) {
                mata: st_matrix("__gtools_r_qused", st_matrix("r(quantiles_used)")[1::`Nout']')
                forvalues i = 1 / `nreturn' {
                    return scalar r`i' = __gtools_r_qused[`i', 1]
                }
                cap scalar drop `rscalar'
            }
            else {
                di as err "Cannot set _pctile return values with nquantiles() but no pctile()"
                CleanExit
                exit 198
            }
        }
    }

    if ( `r(nquantiles2)' > 0 ) {
        return scalar nquantiles_used = `r(nquantiles2)'
        local Nout = `r(nquantiles2)'
        mata: st_matrix("__gtools_r_qused", st_matrix("r(quantiles_used)")[1::`r(nquantiles2)']')
        mata: st_matrix("__gtools_r_qbin",  st_matrix("r(quantiles_bincount)")[1::`r(nquantiles2)']')
        return matrix quantiles_used = __gtools_r_qused
        if ("`binfreq'" != "") {
            return matrix quantiles_binfreq = __gtools_r_qbin
        }
        if ( "`_pctile'" != "" ) {
            mata: st_matrix("__gtools_r_qused", st_matrix("r(quantiles_used)")[1::`Nout']')
            local nreturn = cond(`returnlimit' > 0, min(`r(nquantiles2)', `returnlimit'), `r(nquantiles2)')
            forvalues i = 1 / `nreturn' {
                return scalar r`i' = __gtools_r_qused[`i', 1]
            }
        }
    }

    if ( `r(ncutpoints)' > 0 ) {
        return scalar ncutpoints = `r(ncutpoints)'
        local Nout = `r(ncutpoints)'
    }

    if ( `r(ncutoffs)' > 0 ) {
        return scalar ncutoffs_used =  `r(ncutoffs)'
        local Nout = `r(ncutoffs)'
        mata: st_matrix("__gtools_r_qused", st_matrix("r(cutoffs_used)")[1::`r(ncutoffs)']')
        mata: st_matrix("__gtools_r_qbin",  st_matrix("r(cutoffs_bincount)")[1::`r(ncutoffs)']')
        return matrix cutoffs_used = __gtools_r_qused
        if ("`binfreq'" != "") {
            return matrix cutoffs_binfreq =  __gtools_r_qbin
        }
    }

    if ( `r(nquantpoints)' > 0 ) {
        return scalar nquantpoints = `r(nquantpoints)'
        local Nout = `r(nquantpoints)'
        if ( "`_pctile'" != "" ) {
            if ( "`pctilevar'" != "" ) {
                local nreturn = cond(`returnlimit' > 0, min(`r(nquantpoints)', `returnlimit'), `r(nquantpoints)')
                forvalues i = 1 / `nreturn' {
                    return scalar r`i' = `pctilevar'[`i']
                }
            }
            else {
                di as err "Cannot set _pctile return values with cutquantiles() but no pctile()"
                CleanExit
                exit 198
            }
        }
    }

    return scalar nqused = `Nout'
    return scalar method_ratio = `r(method_ratio)'

    CleanExit
    exit 0
end

capture program drop gtools_timer
program gtools_timer, rclass
    syntax anything, [prints(int 0) end off]
    tokenize `"`anything'"'
    local what  `1'
    local timer `2'
    local msg   `"`3'; "'

    if ( inlist("`what'", "start", "on") ) {
        cap timer off `timer'
        cap timer clear `timer'
        timer on `timer'
    }
    else if ( inlist("`what'", "info") ) {
        timer off `timer'
        qui timer list
        return scalar t`timer' = `r(t`timer')'
        return local pretty`timer' = trim("`:di %21.4gc r(t`timer')'")
        if ( `prints' ) di `"`msg'`:di trim("`:di %21.4gc r(t`timer')'")' seconds"'
        timer off `timer'
        timer clear `timer'
        timer on `timer'
    }

    if ( "`end'`off'" != "" ) {
        timer off `timer'
        timer clear `timer'
    }
end

capture program drop CleanExit
program CleanExit
    global GTOOLS_CALLER ""

    cap matrix drop __gtools_r_qused
    cap matrix drop __gtools_r_qbin
    cap matrix drop __gtools_r_qpct

    cap timer off   97
    cap timer clear 97
end
