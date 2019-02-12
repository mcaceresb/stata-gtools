*! version 1.0.2 23Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Frequency counts using C-plugins for a speedup.

cap program drop gcontract
program gcontract, rclass
    version 13.1

    if ( `=_N' == 0 ) {
        di as err "no observations"
        exit 2000
    }

    global GTOOLS_CALLER gcontract
    syntax anything [if] [in] [fw],  /// [if condition] [in start / end] [fw = exp]
    [                                ///
        Freq(string)                 /// Name of frequency variable
        CFreq(name)                  /// Add cummulative frequency in cfreq
        Percent(name)                /// Add percentages in percent
        CPercent(name)               /// Add cummulative percentages in cpercent
        FLOAT                        /// Store percentages in float variables
        FORMat(string)               /// Format for percentage variables
        Zero                         /// Include varlist combinations with 0 frequency
        noMISS                       /// Exclude rows with missing values in varlist
        NODS DS                      /// Parse - as varlist (ds) or negative (nods)
                                     ///
        fast                         /// Do not preserve and restore the original dataset. Saves speed
                                     /// but leaves data unusable if the user hits Break.
        unsorted                     /// Do not sort the data; faster
                                     ///
        debug(passthru)              ///
        compress                     /// Try to compress strL variables
        forcestrl                    /// Force reading strL variables (stata 14 and above only)
        Verbose                      /// Print info during function execution
        _CTOLerance(passthru)        /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                    /// print function benchmark info
        BENCHmarklevel(int 0)        /// print plugin benchmark info
        HASHmethod(passthru)         /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)        /// error|fallback: On collision, use native command or throw error
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')
    local missing = cond("`miss'" == "nomiss", "", "missing")

    if ( ("`ds'" != "") & ("`nods'" != "") ) {
        di as err "-ds- and -nods- mutually exclusive"
        exit 198
    }

	* Set type and format for generated numeric variables
	* ---------------------------------------------------

	if ( (`"`percent'"' == "") & (`"`cpercent'"' == "") & (`"`float'"' != "") ) {
		di as error "percent or cpercent must be specified"
		exit 198
	}
	else if ( `"`float'"' == "" ) {
		local numtype "double"
	}
	else {
		local numtype "float"
	}

    if ( `=_N < maxlong()' ) {
        local freqtype long
    }
    else {
        local freqtype double
    }

	if ( (`"`percent'"' == "") & (`"`cpercent'"' == "") & (`"`format'"' != "") ) {
		di as error "percent or cpercent must be specified"
		exit 198
	}
	else  if `"`format'"' == "" {
		local format "%8.2f"
	}

	* Check generated variables
	* -------------------------

	if ( "`zero'" != "" ) {
		capture confirm new variable _fillin
		if ( _rc != 0 ) {
			di as error "_fillin already defined"
			exit 110
		}
	}

	* Parse variable names
	* --------------------

	if ( `"`freq'"' == "" ) {
		capture confirm new variable _freq
		if ( _rc == 0 ) {
			local freq "_freq"
		}
		else {
			di as error "_freq already defined: " ///
			            "use freq() option to specify frequency variable"
			exit 110
		}
	}
	else {
		confirm new variable `freq'
	}

    local types   `freqtype'
    local newvars `freq'
    local cwhich   1

	if ( `"`cfreq'"' != "" ) {
		confirm new variable `cfreq'
        local newvars `newvars' `cfreq'
        local types   `types'   `freqtype'
        local cwhich   `cwhich' 1
	}
    else {
        local cwhich   `cwhich' 0
    }

	if ( `"`percent'"' != "" ) {
		confirm new variable `percent'
        local newvars `newvars' `percent'
        local types   `types'   `numtype'
        local cwhich   `cwhich' 1
	}
    else {
        local cwhich   `cwhich' 0
    }

	if ( `"`cpercent'"' != "" ) {
		confirm new variable `cpercent'
        local newvars `newvars' `cpercent'
        local types   `types'   `numtype'
        local cwhich   `cwhich' 1
	}
    else {
        local cwhich   `cwhich' 0
    }

    * Get varlist
    * -----------

    if ( `"`anything'"' != "" ) {
        local varlist: copy local anything
        local varlist: subinstr local varlist "+" " ", all
        if ( strpos(`"`varlist'"', "-") & ("`ds'`nods'" == "") ) {
            disp as txt "'-' interpreted as negative; use option -ds- to interpret as varlist"
            disp as txt "(to suppress this warning, use option -nods-)"
        }
        if ( "`ds'" != "" ) {
            local varlist `varlist'
            if ( "`varlist'" == "" ) {
                di as err "Invalid varlist: `anything'"
                exit 198
            }
            cap ds `varlist'
            if ( _rc ) {
                cap noi ds `varlist'
                exit _rc
            }
            local varlist `r(varlist)'
            local anything: copy local varlist
        }
        else {
            local parse: copy local varlist
            local varlist: subinstr local varlist "-" " ", all
            local varlist `varlist'
            if ( "`varlist'" == "" ) {
                di as err "Invalid list: `anything'"
                di as err "Syntax: [+|-]varname [[+|-]varname ...]"
                exit 198
            }
            cap ds `varlist'
            if ( _rc ) {
                local notfound
                foreach var of local varlist {
                    cap confirm var `var'
                    if ( _rc  ) {
                        local notfound `notfound' `var'
                    }
                }
                if ( `:list sizeof notfound' > 0 ) {
                    if ( `:list sizeof notfound' > 1 ) {
                        di as err "Variables not found: `notfound'"
                    }
                    else {
                        di as err "Variable `notfound' not found"
                    }
                }
                exit 111
            }
            local varlist
            local anything
            while ( `:list sizeof parse' ) {
                gettoken var parse: parse, p(" -")
                local neg
                if inlist("`var'", "-") {
                    gettoken var parse: parse, p(" -")
                    local neg -
                }
                cap ds `var'
                if ( _rc ) {
                    local rc = _rc
                    di as err "Variable '`var'' does not exist."
                    di as err "Syntax: [+|-]varname [[+|-]varname ...]"
                    exit `rc'
                }
                foreach v of varlist `var' {
                    local anything `anything' `neg'`v'
                    local varlist  `varlist' `v'
                }
            }
        }
    }
    if ( "`ds'" == "" ) local nods nods

    * Create variables
    * ----------------

    if ( "`fast'" == "" ) preserve
    gtools_timer on 97

    if ( `"`if'`in'"' != "" ) qui keep `if' `in' 
    if ( `"`weight'"' != "" ) {
        tempvar w touse
        qui gen double `w' `exp'
        local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        mark `touse' `wgt'
        qui keep if `touse'
    }
    else local weights

    qui ds *
    local memvars  `r(varlist)'
    local keepvars `varlist' `w'
    local dropvars: list memvars - keepvars
    if ( "`dropvars'" != "" ) qui mata: st_dropvar(tokens(`"`dropvars'"'))
    qui mata: st_addvar(tokens(`"`types'"'), tokens(`"`newvars'"'))

    local bench = ( "`benchmark'" != "" )
    local msg "Added target variables"
    gtools_timer info 97 `"`msg'"', prints(`bench') off

    * Call the plugin
    * ---------------

    local opts `weights' `missing' `unsorted' `compress' `forcestrl' `ds' `nods'
    local opts `opts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local opts `opts' `oncollision' `hashmethod' `debug'

    local gcontract gcontract(`newvars', contractwhich(`cwhich'))
    cap noi _gtools_internal `anything', `opts' gfunction(contract) `gcontract'

    local rc = _rc
    global GTOOLS_CALLER ""
    if ( `rc' == 17999 ) {
        if ( strpos("`anything'", "-") & ("`ds'" == "") ) {
            di as err "Cannot use fallback with inverted sorting."
            exit 17000
        }
        else {
            local copts f(`freq')        ///
                        cf(`cfreq')      ///
                        p(`percent')     ///
                        cp(`cpercent')   ///
                        `float'          ///
                        format(`format') ///
                        `zero'           ///
                        `miss'
            contract `varlist', `copts'
            if ( "`fast'" == "" ) restore, not
            exit 0
        }
    }
    else if ( `rc' == 17001 ) {
        error 2000
    }
    else if ( `rc' ) {
        exit `rc'
    }

    local r_N     = `r(N)'
    local r_J     = `r(J)'
    local r_minJ  = `r(minJ)'
    local r_maxJ  = `r(maxJ)'
    matrix __gtools_invert = r(invert)

    return scalar N    = `r_N'
    return scalar J    = `r_J'
    return scalar minJ = `r_minJ'
    return scalar maxJ = `r_maxJ'

    * Exit in the style of contract
    * -----------------------------

    qui keep in 1 / `:di %21.0g `r_J''
	if ( "`zero'" != "" ) {
		qui fillin `varlist'
		qui replace `freq' = 0 if `freq' >= .
		qui drop _fillin
        cap confirm var `percent'
        if ( _rc == 0 ) {
            qui replace `percent' = 0 if `percent' >= .
        }
        if ( "`cpercent'`cfreq'" != "" ) {
            foreach var of varlist `cfreq' `cpercent' {
                qui replace `var' = 0 in 1  if `var'[1] >= .
                if ( `=_N' > 1 ) {
                    qui replace `var' = `var'[_n - 1] in 2 / `=_N' if `var' >= .
                }
            }
        }
	}

	qui compress `freq' `cfreq' `percent' `cpercent'

    if ( "`percent'`cpercent'" != "" ) {
        format `format' `percent' `cpercent'
    }

    * Set sort var using varlist
    * --------------------------

    if ( "`unsorted'" == "" ) {
        mata: st_local("invert", strofreal(sum(st_matrix("__gtools_invert"))))
        if ( `invert' ) {
            mata: st_numscalar("__gtools_first_inverted", ///
                               selectindex(st_matrix("__gtools_invert"))[1])
            if ( `=scalar(__gtools_first_inverted)' > 1 ) {
                local sortvars ""
                forvalues i = 1 / `=scalar(__gtools_first_inverted) - 1' {
                    local sortvars `sortvars' `:word `i' of `varlist''
                }
                sort `sortvars'
            }
        }
        else {
            sort `varlist'
        }

        cap scalar drop __gtools_first_inverted
        cap matrix drop __gtools_invert
    }

    if ( "`fast'" == "" ) restore, not
end


***********************************************************************
*                           Generic helpers                           *
***********************************************************************

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
