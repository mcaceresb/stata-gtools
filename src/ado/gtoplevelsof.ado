*! version 1.2.0 23Mar2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Calculate the top groups by count of a varlist (jointly).

cap program drop gtoplevelsof
program gtoplevelsof, rclass
    global GTOP_RC 0
    version 13.1

    if ( `=_N < 1' ) {
        global GTOP_RC 17001
        di as txt "no observations"
        exit 0
    }

    global GTOOLS_CALLER gtoplevelsof
    syntax anything            ///
        [if] [in]              /// [if condition] [in start / end]
        [aw fw pw] ,           /// [weight type = exp]
    [                          ///
        ntop(str)              /// Number of levels to display
        freqabove(real 0)      /// Only include above this count
        pctabove(real 0)       /// Only include above this pct
                               ///
        alpha                  /// Sort top levels by level, not by freq
        noOTHer                /// Do not add summary row with "other" group to table
        noNGroups              /// Do not add number of groups to "Other" row
        missrow                /// Incldue missings as a sepparate row
        GROUPMISSing           /// Count as missing if any variable is missing
        noMISSing              /// Exclude missing values
        NODS DS                /// Parse - as varlist (ds) or negative (nods)
        silent                 /// Do not try to print the levels
                               ///
        MATAsave               /// Save results in mata
        MATAsavename(str)      /// mata save name
        OTHerlabel(str)        /// Label for "other" row
        MISSROWlabel(str)      /// Count as missing if any variable is missing
        pctfmt(str)            /// How to format percentages
                               ///
        noVALUELABels          /// Do (not) map value labels
        HIDECONTlevels         /// Hide level name previous level is the same
        VARABBrev(int -1)      /// Abbrev print of var names
        colmax(numlist)        /// Maximum number of characters to print per column
        colstrmax(numlist)     /// Maximum number of characters to print per column (strings)
        numfmt(passthru)       /// How to format numbers
                               ///
        Separate(passthru)     /// Levels sepparator
        COLSeparate(passthru)  /// Columns sepparator (only with 2+ vars)
        Clean                  /// Clean strings
        LOCal(str)             /// Store variable levels in local
        MATrix(str)            /// Store result in matrix
                               ///
        noWARNing              /// Do not warn about how tab might sometimes be faster
        debug(passthru)        /// Print debugging info to console
        compress               /// Try to compress strL variables
        forcestrl              /// Force reading strL variables (stata 14 and above only)
        Verbose                /// debugging
        _CTOLerance(passthru)  /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark              /// Benchmark function
        BENCHmarklevel(int 0)  /// Benchmark various steps of the plugin
        HASHmethod(passthru)   /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)  /// On collision, fall back or error
                               ///
        group(str)             ///
        tag(passthru)          ///
        counts(passthru)       ///
        fill(passthru)         ///
        replace                ///
    ]

    if ( (`"`matasave'"' != "") & (`"`local'"' != "") ) {
        disp as err "Option local() not allowed with option -matasave-"
        exit 198
    }

    if ( (`"`matasavename'"' != "") & (`"`local'"' != "") ) {
        disp as err "Option local() not allowed with option -matasave()-"
        exit 198
    }

    if ( (`"`matasave'"' != "") & (`"`matrix'"' != "") ) {
        disp as err "Option matrix() not allowed with option -matasave-"
        exit 198
    }

    if ( (`"`matasavename'"' != "") & (`"`matrix'"' != "") ) {
        disp as err "Option matrix() not allowed with option -matasave()-"
        exit 198
    }

    if ( `"`matasavename'"' != "" ) local matasave     matasave
    if ( `"`matasavename'"' == "" ) local matasavename GtoolsByLevels

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( `"`colseparate'"' == "" ) {
        local colseparate colseparate(`"  "')
    }

    if ( `"`pctfmt'"' == "" ) {
        local pctfmt `"%5.1f"'
    }

    if ( `"`matasave'"' == "" ) {
        if ( `"`numfmt'"' == "" ) {
            local numfmt numfmt(`"%.8g"')
        }
    }
    else {
        if ( `"`numfmt'"' == "" ) {
            local numfmt numfmt(`"%16.0g"')
        }
    }

    if !regexm(`"`pctfmt'"', "%[0-9]+\.[0-9]+(gc?|fc?|e)") {
        di as err "Percent format must be %(width).(digits)(f|g); e.g. %.16g (default), %20.5f"
        exit 198
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

    * Parse options
    * -------------

    if ( "`missing'" == "nomissing" ) {
         if ( ("`missrow'" != "") | ("`groupmissing'" != "") ) {
            di as err "-nomissing- not allowed with -groupmissing- or -missrow[()]-"
            exit 198
         }
    }
    local missing  = cond("`missing'" == "", "missing",  "")

    if ( (`pctabove' < 0) | (`pctabove' > 100) ) {
        di as err "-pctabove()- must be between 0 and 100"
        exit 198
    }

    local invert
    if ( `"`ntop'"' == "" ) {
        local ntop 10
    }
    else {
        cap confirm number `ntop'
        if ( _rc ) {
            cap assert mi(`ntop')
            if ( _rc ) {
                disp as err "Option -ntop()- must be a number or missing."
                exit 198
            }
        }
        if ( mi(`ntop') ) {
            if ( (substr(`"`ntop'"', 1, 1) == "-") ) {
                local invert invert
            }
        }
        else {
            if ( `ntop' < 0 ) {
                local invert invert
            }
        }
        local ntop = `ntop'
    }

    local ntop ntop(`ntop')
    local pct  pct(`pctabove')
    local freq freq(`freqabove')

    if ( ("`missrow'" != "") | ("`missrowlabel'" != "") ) {
        if ( "`groupmissing'" != "" ) {
            if ( "`missrowlabel'" != "" ) {
                local groupmiss misslab(`"`missrowlabel'"') groupmiss
            }
            else {
                local missrowlabel Missing (any)
                local groupmiss    misslab(Missing (any)) groupmiss
            }
        }
        else {
            if ( "`missrowlabel'" != "" ) {
                local groupmiss misslab(`"`missrowlabel'"')
            }
            else {
                local missrowlabel Missing
                local groupmiss    misslab(Missing)
            }
        }
    }

    if ( ("`other'" == "") | ("`otherlabel'" != "") ) {
        if ( "`otherlabel'" != "" ) {
            local otherlab otherlab(`"`otherlabel'"')
        }
        else {
            local otherlabel Other
            local otherlab   otherlab(Other)
        }
    }

    local gtop gtop(`ntop'        /*
                 */ `pct'         /*
                 */ `groupmiss'   /*
                 */ `otherlab'    /*
                 */ `freq'        /*
                 */ `alpha'       /*
                 */ `invert'      /*
                 */ `matasave'    /*
                 */ `valuelabels' /*
                 */ `silent'      /*
                 */ matasavename(`matasavename'))


    if ( `"`weight'"' != "" ) {
        tempvar touse w
        qui gen double `w' `exp' `if' `in'
        local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        mark `touse' `if` 'in' `wgt'
        local if if `touse'
    }
    else local weights

    * Call the internals
    * ------------------

    local opts  `clean' `separate' `colseparate' `missing' `gtop' `numfmt' `ds' `nods'
    local sopts `compress' `forcestrl' `_ctolerance'
    local sopts `sopts' `verbose' `benchmark' `benchmarklevel'
    local sopts `sopts' `oncollision' `hashmethod' `debug'

    local gopts gen(`group') `tag' `counts' `fill' `replace' `weights'
    cap noi _gtools_internal `anything' `if' `in', `opts' `sopts' `gopts' gfunction(top)

    local rc = _rc
    global GTOOLS_CALLER ""
    if ( `rc' == 17999 ) {
        exit 17000
    }
    else if ( `rc' == 17001 ) {
        global GTOP_RC 17001
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) {
        exit `rc'
    }

    local byvars = `"`r(byvars)'"'
    local bynum  = `"`r(bynum)'"'
    local bystr  = `"`r(bystr)'"'

    tempname invertmat
    mata: `invertmat' = st_matrix("r(invert)")

    local abbrev = `varabbrev'
    if ( `abbrev' == -1 ) {
        foreach v of local varlist {
            local abbrev = max(`abbrev', length("`v'"))
        }
    }

    local k = 0
    local abbrevlist ""
    foreach v of local varlist {
        local ++k
        local abbrev = max(`abbrev', 5)
        mata: st_local("invert", strofreal(`invertmat'[`k']))
        if ( `invert' ) {
            local avar       `:di %`abbrev's abbrev("`v'", `abbrev')'
            local abbrevlist `abbrevlist' -`avar'
        }
        else {
            local abbrevlist `abbrevlist' `:di %`abbrev's abbrev("`v'", `abbrev')'
        }
    }

    tempname gmat
    if ( `"`silent'"' == "" ) {
        if ( `"`matasave'"' == "" ) {
            mata: GtoolsGtopPrintTop(      /*
                */ `:list sizeof varlist', /*
                */ tokens("`abbrevlist'"), /*
                */ __gtools_top_matrix,    /*
                */ __gtools_top_num,       /*
                */ "",                     /*
                */ 0)
        }
        else {
            mata: GtoolsGtopPrintTop(        /*
                */ `:list sizeof varlist',   /*
                */ tokens("`abbrevlist'"),   /*
                */ `matasavename'.toplevels, /*
                */ `matasavename'.numx,      /*
                */ `matasavename'.printed,   /*
                */ 1)
        }
    }
    else {
        if ( `"`matasave'"' == "" ) {
            cap mata st_matrix(`"`gmat'"', /*
                */ __gtools_top_matrix[    /*
                */ selectindex(__gtools_top_matrix[., 1] :!= 0), .])
        }
    }

    if ( `"`_post_msg_gtop_matanote'"' != "" ) {
        disp as txt `"`_post_msg_gtop_matanote'"'
    }

    if ( `"`_post_msg_gtop_matawarn'"' != "" ) {
        disp as err `"`_post_msg_gtop_matawarn'"'
    }

    if ( `"`matasave'"' == "" ) {
        mata st_local("vals", st_global("r(levels)"))
        matrix colnames `gmat' = ID N Cum Pct PctCum
        if ( "`local'"  != "" ) c_local `local': copy local vals
        if ( "`matrix'" != "" ) matrix `matrix' = `gmat'
        return local levels: copy local vals
        return matrix toplevels = `gmat'
    }
    else {
        return local matalevels `"`matasavename'"'
    }

    return scalar N     = r(N)
    return scalar J     = r(J)
    return scalar minJ  = r(minJ)
    return scalar maxJ  = r(maxJ)
    return scalar alpha = r(alpha)
    return scalar ntop  = r(ntop)
    return scalar nrows = r(nrows)

    cap mata: mata drop __gtools_top_matrix
    cap mata: mata drop __gtools_top_num
    cap mata: mata drop `invertmat'

    * if ( `c(MP)' & (`r(J)' < 11) & ("`warning'" != "nowarning") & (`:list sizeof varlist' == 1) ) {
    *     disp as txt "(Note: {cmd:tab} can be faster than {cmd:gtop} with few groups.)"
    * }
end
