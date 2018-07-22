*! version 1.0.0 21Jul2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -levelsof- implementation using C for faster processing

capture program drop glevelsof
program glevelsof, rclass
    version 13

    if ( `=_N < 1' ) {
        di as err "no observations"
        exit 2000
    }

    global GTOOLS_CALLER glevelsof
    syntax anything           /// Variables to get levels of: [+|-]varname [[+|-]varname ...]
        [if] [in] ,           /// [if condition] [in start / end]
    [                         ///
        Separate(passthru)    /// Levels sepparator
        COLSeparate(passthru) /// Columns sepparator
        MISSing               /// Include missing values
        LOCal(str)            /// Store results in local
        Clean                 /// Clean strings
                              ///
        unsorted              /// Do not sort levels (faster)
        noLOCALvar            /// Do not store levels in a local macro (or in r(levels))
        numfmt(passthru)      /// Number format
        freq(passthru)        /// (not implemented) compute frequency counts
        store(passthru)       /// (not implemented) store in matrix or mata object
        gen(passthru)         /// Save unique levels in varlist
                              ///
        debug(passthru)       /// Print debugging info to console
        compress              /// Try to compress strL variables
        forcestrl             /// Force reading strL variables (stata 14 and above only)
        Verbose               /// Print info during function execution
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        hashlib(passthru)     /// (Windows only) Custom path to spookyhash.dll
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
                              ///
        GROUPid(str)          ///
        tag(passthru)         ///
        counts(passthru)      ///
        fill(passthru)        ///
        replace               ///
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( (`"`localvar'"' != "") & (`"`local'"' != "") ) {
        disp as txt "(option {opt local} ignored with option {nolocalvar})"
    }

    * Get varlist
    * -----------

    if ( `"`anything'"' != "" ) {
        local varlist `anything'
        local varlist: subinstr local varlist "+" "", all
        local varlist: subinstr local varlist "-" "", all
        cap ds `varlist'
        if ( _rc | ("`varlist'" == "") ) {
            local rc = _rc
            di as err "Malformed call: '`anything''"
            di as err "Syntax: [+|-]varname [[+|-]varname ...]"
            exit 111
        }
    }

    * Run levelsof
    * ------------

    local opts  `separate' `missing' `clean' `unsorted'

    local sopts `colseparate' `numfmt' `compress' `forcestrl'
    local sopts `sopts' `verbose' `benchmark' `benchmarklevel'
    local sopts `sopts' `hashlib' `oncollision' `hashmethod' `debug'

    local gopts gen(`groupid') `tag' `counts' `fill' `replace'
    local gopts `gopts' glevelsof(`localvar' `freq' `store' `gen')

    cap noi _gtools_internal `anything' `if' `in', `opts' `sopts' `gopts' gfunction(levelsof)
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 17999 ) {
        if ( `:list sizeof varlist' > 1 ) {
            di as err "Cannot use fallback with more than one variable."
            exit 17000
        }
        else if ( `"`localvar'`gen'`numfmt'"' != "" ) {
            di as err `"Cannot use fallback with option(s): `localvar' `gen' `numfmt'."'
            exit 17000
        }
        else if strpos("`anything'", "-") {
            di as err "Cannot use fallback with inverse order."
            exit 17000
        }
        else {
            levelsof `varlist' `if' `in', `opts'
            exit 0
        }
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' == 920 ) {
        disp as err _n(1) "try {opt gen(prefix)} {opt nolocal}; see {help glevelsof:help glevelsof} for details"
        exit `rc'
    }
    else if ( `rc' ) exit `rc'

    if ( `"`localvar'"' == "" ) {
        if ( `:list sizeof varlist' == 1 ) {
            cap confirm numeric variable `varlist'
            if ( _rc == 0 ) {
                local vals `"`r(levels)'"'
                local vals: subinstr local vals " 0." " .", all
                local vals: subinstr local vals "-0." "-.", all
                if ( "`local'"  != "" ) c_local `local' `"`vals'"'
                if ( "`silent'" == "" ) di as txt `"`vals'"'
                return local levels `"`vals'"'
            }
            else {
                if ( "`local'"  != "" ) c_local `local' `"`r(levels)'"'
                if ( "`silent'" == "" ) di as txt `"`r(levels)'"'
                return local levels `"`r(levels)'"'
            }
        }
        else {
            if ( "`local'"  != "" ) c_local `local' `"`r(levels)'"'
            if ( "`silent'" == "" ) di as txt `"`r(levels)'"'
            return local levels `"`r(levels)'"'
        }

        return local sep    `"`r(sep)'"'
        return local colsep `"`r(colsep)'"'
    }

    return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'
end
