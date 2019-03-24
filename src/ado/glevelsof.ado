*! version 1.2.0 23Mar2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -levelsof- implementation using C for faster processing

capture program drop glevelsof
program glevelsof, rclass
    version 13.1

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
        NODS DS               /// Parse - as varlist (ds) or negative (nods)
        silent                /// Do not try to display levels in console
        MATAsave              /// Save results in mata
        MATAsavename(str)     /// mata save name
                              ///
        debug(passthru)       /// Print debugging info to console
        compress              /// Try to compress strL variables
        forcestrl             /// Force reading strL variables (stata 14 and above only)
        Verbose               /// Print info during function execution
        _CTOLerance(passthru) /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
                              ///
        GROUPid(str)          ///
        tag(passthru)         ///
        counts(passthru)      ///
        fill(passthru)        ///
        replace               ///
    ]

    if ( (`"`matasave'"' != "") & (`"`local'"' != "") ) {
        disp as err "Option local() not allowed with option -matasave-"
        exit 198
    }

    if ( (`"`matasavename'"' != "") & (`"`local'"' != "") ) {
        disp as err "Option local() not allowed with option -matasave()-"
        exit 198
    }

    if ( `"`matasavename'"' != "" ) local matasave     matasave
    if ( `"`matasavename'"' == "" ) local matasavename GtoolsByLevels

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( (`"`localvar'"' != "") & (`"`local'"' != "") ) {
        disp as txt "(option {opt local} ignored with option {nolocalvar})"
    }

    if ( ("`ds'" != "") & ("`nods'" != "") ) {
        di as err "-ds- and -nods- mutually exclusive"
        exit 198
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

    * Run levelsof
    * ------------

    local opts  `separate' `missing' `clean' `unsorted' `ds' `nods'

    local sopts `colseparate' `numfmt' `compress' `forcestrl'
    local sopts `sopts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local sopts `sopts' `oncollision' `hashmethod' `debug'

    local gopts gen(`groupid') `tag' `counts' `fill' `replace'
    local gopts `gopts' glevelsof(`localvar' `freq' `store' /*
        */ `gen' `silent' `matasave' matasavename(`matasavename'))

    cap noi _gtools_internal `anything' `if' `in', `opts' `sopts' `gopts' gfunction(levelsof)
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 17999 ) {
        if ( `:list sizeof varlist' > 1 ) {
            di as err "Cannot use fallback with more than one variable."
            exit 17000
        }
        else if ( `"`localvar'`gen'`numfmt'`matasave'"' != "" ) {
            di as err `"Cannot use fallback with option(s): `localvar' `gen' `numfmt' `matasave'."'
            exit 17000
        }
        else if ( strpos("`anything'", "-") & ("`ds'" == "") ) {
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
        disp as err _n(1) "try {opt gen(prefix)} {opt nolocal} or {opt mata(name)} {opt nolocal};" /*
            */ " see {help glevelsof:help glevelsof} for details"
        exit `rc'
    }
    else if ( `rc' ) exit `rc'

    if ( (`"`localvar'"' == "") & (`"`matasave'"' == "") ) {
        mata st_local("vals",   st_global("r(levels)"))
        mata st_local("sep",    st_global("r(sep)"))
        mata st_local("colsep", st_global("r(colsep)"))
        if ( `:list sizeof varlist' == 1 ) {
            cap confirm numeric variable `varlist'
            if ( _rc == 0 ) {
                local vals: subinstr local vals " 0." " .", all
                local vals: subinstr local vals "-0." "-.", all
            }
        }
        return local levels: copy local vals
        return local sep:    copy local sep
        return local colsep: copy local colsep
        if ( "`local'"  != "" ) c_local `local': copy local vals
        if ( "`silent'" == "" ) di as txt `"`vals'"'
        * if ( "`silent'" == "" ) mata st_global("r(levels)")
    }

    return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'
end
