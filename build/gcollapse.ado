*! version 0.8.1 26Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -collapse- implementation using C for faster processing

capture program drop gcollapse
program gcollapse, rclass
    version 13

    global GTOOLS_CALLER gcollapse
    syntax [anything(equalok)]       /// main call; must parse manually
        [if] [in] ,                  /// subset
    [                                ///
        by(str)                      /// collapse by variabes
        cw                           /// case-wise non-missing
        fast                         /// do not preserve/restore
                                     ///
        replaceby                    /// debugging
        replace                      /// debugging
        Verbose                      /// debugging
        Benchmark                    /// print benchmark info
        hashlib(passthru)            /// path to hash library (Windows only)
        oncollision(passthru)        /// On collision, fall back to collapse or throw error
                                     /// freq(passthru) /// include number of observations in group
                                     ///
        merge                        /// merge statistics back to original data, replacing where applicable
                                     ///
        LABELFormat(passthru)        /// label format; (#stat#) #sourcelabel# is the default
        LABELProgram(passthru)       /// program to prettify stats
                                     ///
        double                       /// do all operations in double precision
        forceio                      /// use disk temp drive for writing/reading collapsed data
        forcemem                     /// use memory for writing/reading collapsed data
                                     ///
        debug_io_check(real 1e6)     /// (experimental) Threshold to check for I/O speed gains
        debug_io_threshold(real 10)  /// (experimental) Threshold to switch to I/O instead of RAM
    ]

    if ( "`by'" != "" ) {
        local clean_by `by'
        local clean_by: subinstr local clean_by "+" "", all
        local clean_by: subinstr local clean_by "-" "", all
        local clean_by `clean_by'
        cap ds `clean_by'
        if ( _rc | ("`clean_by'" == "") ) {
            local rc = _rc
            di as err "Malformed call: by(`by')"
            di as err "Syntas: by([+|-]varname [[+|-]varname ...])"
            CleanExit
            exit 111
        }
        local clean_by `r(varlist)'
    }

    * Parse options
    * -------------

    if ( ("`forceio'" != "") & ("`merge'" != "") ) {
        di as err "-merge- with -forceio- is inefficient and hence not allowed."
        CleanExit
        exit 198
    }

    if ( ("`forceio'" != "") & ("`forcemem'" != "") ) {
        di as err "only specify one of -forceio- and -forcemem-; cannot do both at the same time."
        CleanExit
        exit 198
    }

    local verb  = ( "`verbose'"   != "" )
    local bench = ( "`benchmark'" != "" )

    if ( "`fast'" == "" ) preserve

    * Parse collapse statement to get sources, targets, and stats
    * -----------------------------------------------------------

    gtools_timer on 97
    cap noi parse_vars `anything' `if' `in', `cw' `labelformat' `labelprogram'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    local __gtools_uniq_targets : list uniq __gtools_targets
    local nonunique: list __gtools_targets - __gtools_uniq_targets
    if ( `:list sizeof nonunique' != 0 ) {
        di as err "Repeat targets not allowed: `:list uniq nonunique'"
        CleanExit
        exit 198
    }

    * Subset if requested
    * -------------------

    if ( ("`if'" != "") | ("`cw'" != "") ) {
        marksample touse, strok novarlist
        if ("`cw'" != "") {
            markout `touse' `gtools_uniq_vars', strok
        }
        if ( "`merge'" == "" ) {
            qui keep if `touse'
            local if ""
        }
        else local if if `touse'
    }

    if ( `=_N' == 0 ) {
        di as err "no observations"
        CleanExit
        exit 2000
    }

    * Parse variables to keep, drop, rename, recast
    * ---------------------------------------------

    * Parse variables to keep (by variables, sources) and drop (all else).
    * Also parse which source variables to recast (see below; we try to use
    * source variables as their first target to save memory)

    cap noi parse_keep_drop, by(`clean_by') `merge' `double' `replace' `replaceby' ///
        __gtools_targets(`__gtools_targets')                                       ///
        __gtools_vars(`__gtools_vars')                                             ///
        __gtools_stats(`__gtools_stats')                                           ///
        __gtools_uniq_vars(`__gtools_uniq_vars')                                   ///
        __gtools_uniq_stats(`__gtools_uniq_stats')                                  //

    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    local dropme       ""
    local keepvars     "`r(keepvars)'"
    local added        "`r(added)'"
    local memvars      "`r(memvars)'"
    local check_recast "`r(check_recast)'"

    scalar __gtools_k_targets    = `:list sizeof __gtools_targets'
    scalar __gtools_k_vars       = `:list sizeof __gtools_vars'
    scalar __gtools_k_stats      = `:list sizeof __gtools_stats'
    scalar __gtools_k_uniq_vars  = `:list sizeof __gtools_uniq_vars'
    scalar __gtools_k_uniq_stats = `:list sizeof __gtools_uniq_stats'

    mata: gtools_vars     = tokens(`"`__gtools_vars'"')
    mata: gtools_targets  = tokens(`"`__gtools_targets'"')
    mata: gtools_stats    = tokens(`"`__gtools_stats'"')

    mata: gtools_pos      = gtools_vars :== gtools_targets
    mata: gtools_io_order = selectindex(gtools_pos), selectindex(!gtools_pos)

    cap noi CheckMatsize `clean_by'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    cap noi CheckMatsize `__gtools_vars'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    cap noi CheckMatsize `__gtools_targets'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    cap noi CheckMatsize `__gtools_stats'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    * Timers!
    * -------

    local msg "Parsed by variables, sources, and targets"
    gtools_timer info 97 `"`msg'"', prints(`bench')

    ***********************************************************************
    *                   Recast variables to save memory                   *
    ***********************************************************************

    * Recast sources, if applicable
    mata: st_numscalar("__gtools_k_recast", cols(__gtools_recastvars))
    if ( `=scalar(__gtools_k_recast)' > 0 ) {
        local gtools_recastvars ""
        local gtools_recastsrc  ""
        forvalues k = 1 / `=scalar(__gtools_k_recast)' {
            mata: st_local("var", __gtools_recastvars[`k'])
            tempvar dropvar
            rename `var' `dropvar'
            local dropme `dropme' `dropvar'
            local gtools_recastvars `gtools_recastvars' `var'
            local gtools_recastsrc  `gtools_recastsrc'  `dropvar'
        }

        qui mata: st_addvar(__gtools_recasttypes, __gtools_recastvars, 1)
        if ( `=_N > 0' ) {
            cap noi _gtools_internal, recast(targets(`gtools_recastvars') sources(`gtools_recastsrc'))
            if ( _rc ) {
                local rc = _rc
                CleanExit
                exit `rc'
            }
        }

        local msg `"Recast source variables to save memory"'
        gtools_timer info 97 `"`msg'"', prints(`bench')
    }

    ***********************************************************************
    *                             I/O switch                              *
    ***********************************************************************

    tempfile __gtools_file
    scalar __gtools_k_extra = __gtools_k_targets - __gtools_k_uniq_vars

    local sources  sources(`__gtools_vars')
    local stats    stats(`__gtools_stats')
    local targets  targets(`__gtools_targets')
    local opts     missing replace `verbose' `benchmark' `hashlib' `oncollision'
    local action  `sources' `targets' `stats'

    local switch = (`=scalar(__gtools_k_extra)' > 3) & (`debug_io_check' < `=_N')
    local mem    = ("`forcemem'" != "") | ("`merge'" != "") | (`=scalar(__gtools_k_extra)' == 0)
    local io     = ("`forceio'"  != "") & (`=scalar(__gtools_k_extra)' > 0)

    if ( `io' ) {
        * Re-order statistics (we try to use sources as targets; if the
        * source was used as a target for any statistic other than the
        * first, then we need to re-order the summary stats).
        local gtools_stats ""
        forvalues k = 1 / `=scalar(__gtools_k_targets)' {
            mata: st_local("stat", gtools_stats[gtools_io_order[`k']])
            local gtools_stats `gtools_stats' `stat'
        }
        local gtools_uniq_stats: list uniq gtools_stats

        * Drop rest of vars
        local plugvars `clean_by' `__gtools_uniq_vars'
        local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme - plugvars'
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

        local gcollapse gcollapse(forceio, fname(`__gtools_file'))
        local action    `action' fill(data)
        local stats     stats(`gtools_stats')
    }
    else if ( !`mem' & `switch' ) {
        * Re-order statistics (we try to use sources as targets; if the
        * source was used as a target for any statistic other than the
        * first, then we need to re-order the summary stats).
        local gtools_stats ""
        forvalues k = 1 / `=scalar(__gtools_k_targets)' {
            mata: st_local("stat", gtools_stats[gtools_io_order[`k']])
            local gtools_stats `gtools_stats' `stat'
        }
        local gtools_uniq_stats: list uniq gtools_stats

        * Replace source vars in memory, since they already exist
        local plugvars `clean_by' `__gtools_uniq_vars'

        * It will be faster to add targets with fewer variables in
        * memory. Dropping superfluous variables also saves memory.
        local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme  - plugvars'

        * Drop extra vars
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))
        local msg `"Dropped superfluous variables"'
        gtools_timer info 97 `"`msg'"', prints(`bench')

        * Benchmark adding 2 variables to gauge how long it might take to
        * add __gtools_k_extra variables.
        tempvar __gtools_index __gtools_ix __gtools_info
        cap noi benchmark_memvars, index(`__gtools_index') ix(`__gtools_ix') info(`__gtools_info')
        if ( _rc ) {
            local rc = _rc
            CleanExit
            exit `rc'
        }

        local st_time = `r(st_time)'
        gtools_timer info 97 `"`r(st_str)'"', prints(`bench')

        if ( `st_time' > 0 ) {
            * Call the plugin with switch option
            * ----------------------------------

            local st_time   st_time(`=`st_time' / `debug_io_threshold'')
            local ixinfo    ixinfo(`__gtools_index' `__gtools_ix' `__gtools_info')
            local gcollapse gcollapse(switch, `st_time' fname(`__gtools_file') `ixinfo')
            local action    `action' fill(data)
            local stats     stats(`gtools_stats')
        }
        else {

            * If benchmark was 0, add the vars right now
            * ------------------------------------------

            qui mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
            local msg "Generated additional targets"
            gtools_timer info 97 `"`msg'"', prints(`bench')

            local gcollapse gcollapse(memory)
            local action    `action' fill(data)
        }
    }
    else {

        local plugvars `clean_by' `__gtools_uniq_vars'
        if ( "`merge'" == "" ) local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme - plugvars'

        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))
        local msg `"Dropped superfluous variables"'
        gtools_timer info 97 `"`msg'"', prints(`bench')

        if ( ("`forceio'" == "forceio") & (`=scalar(__gtools_k_extra)' == 0) ) {
            if ( `verb' ) di as text "(ignored -forceio- because sources are being used as targets)"
        }

        if ( "`added'" != "" ) qui mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
        local msg "Generated additional targets"
        gtools_timer info 97 `"`msg'"', prints(`bench')

        local gcollapse gcollapse(memory, `merge')
        local action    `action' `:di cond("`merge'" == "", "fill(data)", "unsorted")'
    }

    cap noi _gtools_internal `by' `if' `in', `opts' `action' `gcollapse' gfunction(collapse)
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }
    local used_io = `r(used_io)'
    local r_N     = `r(N)'
    local r_J     = `r(J)'
    local r_minJ  = `r(minJ)'
    local r_maxJ  = `r(maxJ)'

    * Return values
    * -------------

    return scalar N    = `r_N'
    return scalar J    = `r_J'
    return scalar minJ = `r_minJ'
    return scalar maxJ = `r_maxJ'

    ***********************************************************************
    *                               Finish                                *
    ***********************************************************************

    if ( "`merge'" == "" ) {

        * Keep only the collapsed data
        * ----------------------------

        qui {
            if ( `=`r_J' > 0' ) keep in 1 / `:di %21.0g `r_J''
            else if ( `=`r_J' == 0' ) {
                keep in 1
                drop if 1
            }
            else if ( `=`r_J' < 0' ) {
                di as err "The plugin returned a negative number of groups."
                di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
                CleanExit
                exit 42200
            }
            ds *
        }
        if ( `=_N' == 0 ) di as txt "(no observations)"

        * Make sure no extra variables are present
        * ----------------------------------------

        local memvars  `r(varlist)'
        local keepvars `clean_by' `__gtools_targets'
        local dropme   `:list memvars - keepvars'
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

        * If we collapsed to disk, read back the data
        * -------------------------------------------

        if ( (`=_N > 0') & (`=scalar(__gtools_k_extra)' > 0) & ( `used_io' | ("`forceio'" == "forceio") ) ) {
            gtools_timer on 97

            qui mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
            gtools_timer info 97 `"Added extra targets after collapse"', prints(`bench')

            local __gtools_iovars: list __gtools_targets - __gtools_uniq_vars
            local gcollapse gcollapse(read, fname(`__gtools_file'))
            cap noi _gtools_internal, `gcollapse' `action' gfunction(collapse)
            if ( _rc ) {
                local rc = _rc
                CleanExit
                exit `rc'
            }

            gtools_timer info 97 `"Read extra targets from disk"', prints(`bench')
        }

        * Order variables if they are not in user-requested order
        * -------------------------------------------------------

        local order = 0
        qui ds *
        local varorder `r(varlist)'
        local varsort  `clean_by' `__gtools_targets'
        foreach varo in `varorder' {
            gettoken svar varsort: varsort
            if ("`varo'" != "`vars'") local order = 1
        }
        if ( `order' ) order `clean_by' `__gtools_targets'

        * Label the things in the style of collapse
        * -----------------------------------------

        forvalues k = 1 / `:list sizeof __gtools_targets' {
            mata: st_varlabel(gtools_targets[`k'], __gtools_labels[`k'])
            mata: st_varformat(gtools_targets[`k'], __gtools_formats[`k'])
        }
    }
    else {
        forvalues k = 1 / `:list sizeof __gtools_targets' {
            mata: st_varlabel(gtools_targets[`k'], __gtools_labels[`k'])
        }
        forvalues k = 1 / `:list sizeof __gtools_targets' {
            mata: st_varformat(gtools_targets[`k'], __gtools_formats[`k'])
        }
    }

    ***********************************************************************
    *                            Program Exit                             *
    ***********************************************************************

    gtools_timer on 97
    if ( "`fast'" == "" ) restore, not

    local msg "Program exit executed"
    gtools_timer info 97 `"`msg'"', prints(`bench') off

    CleanExit
    exit 0
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

***********************************************************************
*                          Gcollapse helpers                          *
***********************************************************************

capture program drop parse_vars
program parse_vars
    syntax [anything(equalok)] ///
        [if] [in] ,            /// subset
    [                          ///
        cw                     /// case-wise non-missing
        labelformat(str)       /// label prefix
        labelprogram(str)      /// label prefix
    ]

    * Parse gcollapse call into list of sources, targets, stats
    * ---------------------------------------------------------

    if ( "`anything'" == "" ) {
        di as err "invalid syntax"
        exit 198
    }
    else {
        ParseList `anything'
    }

    * Get format and labels from sources
    * ----------------------------------

    if ( "`labelformat'" == "") local labelformat "(#stat#) #sourcelabel#"
    local lnice_regex "(.*)(#stat:pretty#)(.*)"
    local lpre_regex  "(.*)(#stat#)(.*)"
    local lPre_regex  "(.*)(#Stat#)(.*)"
    local lPRE_regex  "(.*)(#STAT#)(.*)"
    local ltxt_regex  "(.*)(#sourcelabel#)(.*)"
    local lsub_regex  "(.*)#sourcelabel:([0-9]+):([.0-9]+)#(.*)"

    mata: __gtools_formats = J(1, `:list sizeof __gtools_targets', "")
    mata: __gtools_labels  = J(1, `:list sizeof __gtools_targets', "")
    forvalues k = 1 / `:list sizeof __gtools_targets' {
        local vl = `"`:variable label `:word `k' of `__gtools_vars'''"'
        local vl = cond(`"`vl'"' == "", `"`:word `k' of `__gtools_vars''"', `"`vl'"')
        local vp = `"`:word `k' of `__gtools_stats''"'

        if ( "`labelprogram'" == "" ) GtoolsPrettyStat `vp'
        else `labelprogram' `vp'
        local vpretty = `"`r(prettystat)'"'

        if ( `"`vpretty'"' == "#default#" ) {
            GtoolsPrettyStat `vp'
            local vpretty = `"`r(prettystat)'"'
        }

        local lfmt_k = `"`labelformat'"'

        if !regexm(`"`vl'"', "`ltxt_regex'") {
            while regexm(`"`lfmt_k'"', "`ltxt_regex'") {
                local lfmt_k = regexs(1) + `"`vl'"' + regexs(3)
            }
        }
        if !regexm(`"`vl'"', "`lsub_regex'") {
            while regexm(`"`lfmt_k'"', "`lsub_regex'") {
                local lfmt_k = regexs(1) + substr(`"`vl'"', `:di regexs(2)', `:di regexs(3)') + regexs(4)
            }
        }
        if !regexm(`"`vpretty'"', "`lnice_regex'") {
            while regexm(`"`lfmt_k'"', "`lnice_regex'") {
                local lfmt_k = regexs(1) + `"`vpretty'"' + regexs(3)
            }
        }
        if !regexm(`"`vp'"', "`lpre_regex'") {
            while regexm(`"`lfmt_k'"', "`lpre_regex'") {
                local lfmt_k = regexs(1) + `"`vp'"' + regexs(3)
            }
        }
        if !regexm(`"`vp'"', "`lPre_regex'") {
            while regexm(`"`lfmt_k'"', "`lPre_regex'") {
                local lfmt_k = regexs(1) + proper(`"`vp'"') + regexs(3)
            }
        }
        if !regexm(`"`vp'"', "`lPRE_regex'") {
            while regexm(`"`lfmt_k'"', "`lPRE_regex'") {
                local lfmt_k = regexs(1) + upper(`"`vp'"') + regexs(3)
            }
        }
        mata: __gtools_labels[`k'] = `"`lfmt_k'"'

        local vf = "`:format `:word `k' of `__gtools_vars'''"
        local vf = cond("`:word `k' of `__gtools_stats''" == "count", "%8.0g", "`vf'")
        mata: __gtools_formats[`k'] = "`vf'"
    }

    * Available Stats
    * ---------------

    local stats sum        ///
                mean       ///
                sd         ///
                max        ///
                min        ///
                count      ///
                median     ///
                iqr        ///
                percent    ///
                first      ///
                last       ///
                firstnm    ///
                lastnm     ///
                semean     ///
                sebinomial ///
                sepoisson

    * Parse quantiles
    local anyquant  = 0
    local quantiles : list __gtools_uniq_stats - stats
    foreach quantile of local quantiles {
        local quantbad = !regexm("`quantile'", "^p([0-9][0-9]?(\.[0-9]+)?)$")
        if ( `quantbad' ) {
            di as error "Invalid stat: (`quantile')"
            error 110
        }
        if ("`quantile'" == "p0") {
            di as error "Invalid stat: (`quantile'; maybe you meant 'min'?)"
            error 110
        }
        if ("`quantile'" == "p100") {
            di as error "Invalid stat: (`quantile'; maybe you meant 'max'?)"
            error 110
        }
    }

    * Locals one level up
    * -------------------

    c_local __gtools_targets    `__gtools_targets'
    c_local __gtools_vars       `__gtools_vars'
    c_local __gtools_stats      `__gtools_stats'
    c_local __gtools_uniq_vars  `__gtools_uniq_vars'
    c_local __gtools_uniq_stats `__gtools_uniq_stats'
end

capture program drop parse_keep_drop
program parse_keep_drop, rclass
    syntax,                      ///
    [                            ///
        replace                  ///
        replaceby                ///
        merge                    ///
        double                   ///
        by(varlist)              ///
        __gtools_targets(str)    ///
        __gtools_vars(str)       ///
        __gtools_stats(str)      ///
        __gtools_uniq_vars(str)  ///
        __gtools_uniq_stats(str) ///
    ]

    * The code assumes targets either do not exist or are named the same as
    * the source variable. If a target exists in memory but is not one of the
    * sources, rename the target to a dummy

    local __gtools_i = 0
    if ( "`merge'" == "" ) {
        foreach var in `__gtools_targets' {
            cap confirm variable `var'
            if ( (_rc == 0) & !`:list var in __gtools_vars' ) {
                cap confirm variable __gtools`__gtools_i'
                while ( _rc == 0 ) {
                    local ++__gtools_i
                    cap confirm variable __gtools`__gtools_i'
                }
                rename `var' __gtools`__gtools_i'
            }
        }
    }

    * Try to be smart about creating target variables
    * -----------------------------------------------

    local __gtools_keepvars `__gtools_uniq_vars'

    * If not merging, then be smart about creating new variable columns
    if ( "`merge'" == "" ) {
        scalar __gtools_merge = 0

        local __gtools_vars      " `__gtools_vars' "
        local __gtools_uniq_vars " `__gtools_uniq_vars' "
        local __gtools_keepvars  " `__gtools_keepvars' "

        local __gtools_vars:      subinstr local __gtools_vars      " "  "  ", all
        local __gtools_uniq_vars: subinstr local __gtools_uniq_vars " "  "  ", all
        local __gtools_keepvars:  subinstr local __gtools_keepvars  " "  "  ", all

        local K: list sizeof __gtools_targets
        forvalues k = 1 / `K' {
            qui ds *
            local memvars `r(varlist)'

            local k_target: word `k' of `__gtools_targets'
            local k_var:    word `k' of `__gtools_vars'
            local k_stat:   word `k' of `__gtools_stats'

            * Only use as target if the type matches
            * parse_ok_astarget, sourcevar(`k_var') targetvar(`k_target') stat(`k_stat') `double'
            * if ( `:list k_var in __gtools_uniq_vars' & `r(ok_astarget)' ) {

            * Always try to use as target; will recast if necessary
            if ( `:list k_var in __gtools_uniq_vars' ) {
                local __gtools_uniq_vars: list __gtools_uniq_vars - k_var
                if ( !`:list k_var in __gtools_targets' & !`:list k_target in memvars' ) {
                    local __gtools_vars      " `__gtools_vars' "
                    local __gtools_uniq_vars " `__gtools_uniq_vars' "
                    local __gtools_keepvars  " `__gtools_keepvars' "
                    local __gtools_vars:      subinstr local __gtools_vars      " `k_var' " " `k_target' ", all
                    local __gtools_uniq_vars: subinstr local __gtools_uniq_vars " `k_var' " " `k_target' ", all
                    local __gtools_keepvars:  subinstr local __gtools_keepvars  " `k_var' " " `k_target' ", all
                    local __gtools_vars      `__gtools_vars'
                    local __gtools_uniq_vars `__gtools_uniq_vars'
                    local __gtools_keepvars  `__gtools_keepvars'
                    rename `k_var' `k_target'
                }
            }
        }
        local __gtools_vars      " `__gtools_vars' "
        local __gtools_uniq_vars " `__gtools_uniq_vars' "
        local __gtools_keepvars  " `__gtools_keepvars' "
        local __gtools_vars:      subinstr local __gtools_vars      "  " " ", all
        local __gtools_uniq_vars: subinstr local __gtools_uniq_vars "  " " ", all
        local __gtools_keepvars:  subinstr local __gtools_keepvars  "  " " ", all
        local __gtools_vars      `__gtools_vars'
        local __gtools_uniq_vars `__gtools_uniq_vars'
        local __gtools_keepvars  `__gtools_keepvars'

        local keepvars `by' `__gtools_keepvars'
    }
    else {
        scalar __gtools_merge = 1
        if ( "`replace'" == "" ) {
            local intersection: list __gtools_targets & __gtools_vars
            if ( "`intersection'" != "" ) {
                di as error "targets also sources with no replace: `intersection'"
                error 110
            }
        }
    }

    local intersection: list __gtools_targets & by
    if ( "`intersection'" != "" ) {
        if ( "`replaceby'" == "" ) {
            di as error "targets also in by() with no replaceby: `intersection'"
            error 110
        }
    }

    * Variables in memory; will compare to keepvars
    * ---------------------------------------------

    * Unfortunately, this is necessary for C. We cannot create variables from
    * C, and we cannot halt the C execution, create the final data in Stata,
    * and then go back to C.

    qui ds *
    local memvars `r(varlist)'
    local added  ""

    mata: __gtools_addvars     = J(1, 0, "")
    mata: __gtools_addtypes    = J(1, 0, "")
    mata: __gtools_recastvars  = J(1, 0, "")
    mata: __gtools_recasttypes = J(1, 0, "")

    c_local __gtools_vars      `__gtools_vars'
    c_local __gtools_uniq_vars `__gtools_keepvars'

    local check_recast ""
    foreach var of local __gtools_targets {
        gettoken sourcevar __gtools_vars:  __gtools_vars
        gettoken collstat  __gtools_stats: __gtools_stats

        * I try to match Stata's types when possible
        if regexm("`collstat'", "first|last|min|max") {
            * First, last, min, max can preserve type, clearly
            local targettype: type `sourcevar'
        }
        else if ( "`double'" != "" ) {
            local targettype double
        }
        else if ( ("`collstat'" == "count") & (`=_N' < 2^31) ) {
            * Counts can be long if we have fewer than 2^31 observations
            * (largest signed integer in long variables can be 2^31-1)
            local targettype long
        }
        else if ( ("`collstat'" == "count") & !(`=_N' < 2^31) ) {
            local targettype double
        }
        else if ( ("`collstat'" == "sum") | ("`:type `sourcevar''" == "long") ) {
            * Sums are double so we don't overflow; some operations on long
            * variables with target float can be inaccurate
            local targettype double
        }
        else if inlist("`:type `sourcevar''", "double") {
            * If variable is double, then keep that type
            local targettype double
        }
        else {
            * Otherwise, store results in specified user-default type
            local targettype `c(type)'
        }

        * Create target variables as applicable. If it's the first instance,
        * we use it to store the first summary statistic requested for that
        * variable and recast as applicable.

        cap confirm variable `var'
        if ( _rc ) {
            mata: __gtools_addvars  = __gtools_addvars,  "`var'"
            mata: __gtools_addtypes = __gtools_addtypes, "`targettype'"
            local added `added' `var'
        }
        else {
            * We only recast integers. Floats and doubles are preserved unless
            * requested or the target is a sum.
            parse_ok_astarget, sourcevar(`var') targetvar(`var') stat(`collstat') `double'
            local recast = !(`r(ok_astarget)')

            if ( `recast' ) {
                mata: __gtools_recastvars  = __gtools_recastvars,  "`var'"
                mata: __gtools_recasttypes = __gtools_recasttypes, "`targettype'"
            }
        }
    }

    return local keepvars     = "`keepvars'"
    return local added        = "`added'"
    return local memvars      = "`memvars'"
    return local check_recast = "`check_recast'"
end

capture program drop parse_ok_astarget
program parse_ok_astarget, rclass
    syntax, sourcevar(varlist) targetvar(str) stat(str) [double]
    local ok_astarget = 0
    local sourcetype  = "`:type `sourcevar''"

    * I try to match Stata's types when possible
    if regexm("`stat'", "first|last|min|max") {
        * First, last, min, max can preserve type, clearly
        local targettype `sourcetype'
        local ok_astarget = 1
    }
    else if ( "`double'" != "" ) {
        local targettype double
        local ok_astarget = ("`:type `sourcevar''" == "double")
    }
    else if ( ("`stat'" == "count") & (`=_N' < 2^31) ) {
        * Counts can be long if we have fewer than 2^31 observations
        * (largest signed integer in long variables can be 2^31-1)
        local targettype long
        local ok_astarget = inlist("`:type `sourcevar''", "long", "double")
    }
    else if ( ("`stat'" == "count") & !(`=_N' < 2^31) ) {
        local targettype double
    }
    else if ( ("`stat'" == "sum") | ("`:type `sourcevar''" == "long") ) {
        * Sums are double so we don't overflow. Floats can't handle some
        * perations on long variables properly.
        local targettype double
        local ok_astarget = ("`:type `sourcevar''" == "double")
    }
    else if inlist("`:type `sourcevar''", "double") {
        local targettype double
        local ok_astarget = 1
    }
    else {
        * Otherwise, store results in specified user-default type
        local targettype `c(type)'
        if ( "`targettype'" == "float" ) {
            local ok_astarget = inlist("`:type `sourcevar''", "float", "double")
        }
        else {
            local ok_astarget = inlist("`:type `sourcevar''", "double")
        }
    }
    return local ok_astarget = `ok_astarget'
end

capture program drop benchmark_memvars
program benchmark_memvars, rclass
    syntax, index(str) ix(str) info(str)
    if ( `=_N' < 2^31 ) {
        local itype  long
        local factor = 2 / 3
        local bytes  = 12
    }
    else {
        local itype double
        local factor = 1 / 3
        local bytes  = 24
    }

    {
        cap timer off 96
        cap timer clear 96
        timer on 96
    }
    qui mata: st_addvar(("`itype'"), ("`index'"), 1)
    {
        cap timer off 96
        qui timer list
        local total_time = r(t96)
        cap timer clear 96
        timer on 96
    }
    qui mata: st_addvar(("`itype'"), ("`ix'"), 1)
    {
        cap timer off 96
        qui timer list
        local total_time = `total_time' + r(t96)
        cap timer clear 96
        timer on 96
    }

    qui mata: st_addvar(("`itype'"), ("`info'"), 1)
    {
        cap timer off 96
        qui timer list
        local total_time = `total_time' + r(t96)
        cap timer clear 96
    }

    local mib     = `=_N * 8 / 1024 / 1024'
    local mib_str = trim("`:di %15.2gc 2 * `mib''")
    local n_str   = trim("`:di %15.0gc `=_N''")
    return local st_str  = `"Added index and info (`n_str' obs; approx `mib_str'MiB)"'
    return local st_time = max(`total_time', 0.001) * scalar(__gtools_k_extra) * `factor'
    * return local st_time = `total_time' * scalar(__gtools_k_extra) * `factor'
end

***********************************************************************
*       Parsing is adapted from Sergio Correia's fcollapse.ado        *
***********************************************************************

capture program drop ParseList
program define ParseList
    syntax [anything(equalok)]
    local stat mean

    * Trim spaces
    while strpos("`0'", "  ") {
        local 0: subinstr local 0 "  " " "
    }
    local 0 `0'

    while (trim("`0'") != "") {
        GetStat stat 0 : `0'
        GetTarget target 0 : `0'
        gettoken vars 0 : 0
        unab vars : `vars'
        foreach var of local vars {
            if ("`target'" == "") local target `var'

            if ( "`stat'" == "sem" ) local stat semean
            if ( "`stat'" == "seb" ) local stat sebinomial
            if ( "`stat'" == "sep" ) local stat sepoisson

            local full_vars    `full_vars'    `var'
            local full_targets `full_targets' `target'
            local full_stats   `full_stats'   `stat'

            local target
        }
    }

    * Check that targets don't repeat
    local dups : list dups targets
    if ("`dups'" != "") {
        di as error "repeated targets in collapse: `dups'"
        error 110
    }

    c_local __gtools_targets    `full_targets'
    c_local __gtools_stats      `full_stats'
    c_local __gtools_vars       `full_vars'
    c_local __gtools_uniq_stats : list uniq full_stats
    c_local __gtools_uniq_vars  : list uniq full_vars
end

capture program drop GetStat
program define GetStat
    _on_colon_parse `0'
    local before `s(before)'
    gettoken lhs rhs : before
    local rest `s(after)'

    gettoken stat rest : rest , match(parens)
    if ("`parens'" != "") {
        c_local `lhs' `stat'
        c_local `rhs' `rest'
    }
end

capture program drop GetTarget
program define GetTarget
    _on_colon_parse `0'
    local before `s(before)'
    gettoken lhs rhs : before
    local rest `s(after)'

    local rest : subinstr local rest "=" "= ", all
    gettoken target rest : rest, parse("= ")
    gettoken eqsign rest : rest
    if ("`eqsign'" == "=") {
        c_local `lhs' `target'
        c_local `rhs' `rest'
    }
end

capture program drop CleanExit
program CleanExit
    cap mata: mata drop __gtools_formats
    cap mata: mata drop __gtools_labels

    cap mata: mata drop __gtools_addvars
    cap mata: mata drop __gtools_addtypes
    cap mata: mata drop __gtools_recastvars
    cap mata: mata drop __gtools_recasttypes

    cap mata: mata drop gtools_vars
    cap mata: mata drop gtools_targets
    cap mata: mata drop gtools_stats

    cap mata: mata drop gtools_pos
    cap mata: mata drop gtools_io_order

    cap mata: mata drop __gtools_asfloat
    cap mata: mata drop __gtools_checkrecast
    cap mata: mata drop __gtools_norecast
    cap mata: mata drop __gtools_keeprecast

    cap mata: mata drop __gtools_iovars

    cap scalar drop __gtools_k_recast
    cap scalar drop __gtools_merge

    cap scalar drop __gtools_k_extra
    cap scalar drop __gtools_k_targets
    cap scalar drop __gtools_k_vars
    cap scalar drop __gtools_k_stats
    cap scalar drop __gtools_k_uniq_vars
    cap scalar drop __gtools_k_uniq_stats

    cap timer off   97
    cap timer clear 97

    global GTOOLS_CALLER ""
end

capture program drop CheckMatsize
program CheckMatsize
    syntax [anything], [nvars(int 0)]
    if ( `nvars' == 0 ) local nvars `:list sizeof anything'
    if ( `nvars' > `c(matsize)' ) {
        cap set matsize `=`nvars''
        if ( _rc ) {
            di as err _n(1) "{bf:# variables > matsize (`nvars' > `c(matsize)'). Tried to run}"
            di        _n(1) "    {stata set matsize `=`nvars''}"
            di        _n(1) "{bf:but the command failed. Try setting matsize manually.}"
            exit 908
        }
    }
end

capture program drop GtoolsPrettyStat
program GtoolsPrettyStat, rclass
    if ( `"`0'"' == "sum"         ) local prettystat "Sum"
    if ( `"`0'"' == "mean"        ) local prettystat "Mean"
    if ( `"`0'"' == "sd"          ) local prettystat "St Dev."
    if ( `"`0'"' == "max"         ) local prettystat "Max"
    if ( `"`0'"' == "min"         ) local prettystat "Min"
    if ( `"`0'"' == "count"       ) local prettystat "Count"
    if ( `"`0'"' == "percent"     ) local prettystat "Percent"
    if ( `"`0'"' == "median"      ) local prettystat "Median"
    if ( `"`0'"' == "iqr"         ) local prettystat "IQR"
    if ( `"`0'"' == "first"       ) local prettystat "First"
    if ( `"`0'"' == "firstnm"     ) local prettystat "First Non-Miss."
    if ( `"`0'"' == "last"        ) local prettystat "Last"
    if ( `"`0'"' == "lastnm"      ) local prettystat "Last Non-Miss."
    if ( `"`0'"' == "semean"      ) local prettystat "SE Mean"
    if ( `"`0'"' == "sebinomial"  ) local prettystat "SE Mean (Binom)"
    if ( `"`0'"' == "sepoisson"   ) local prettystat "SE Mean (Pois)"
    if regexm(`"`0'"', "^p([0-9][0-9]?(\.[0-9]+)?)$") {
        local p = `:di regexs(1)'
             if ( mod(`p', 10) == 1 ) local prettystat "`p'st Pctile"
        else if ( mod(`p', 10) == 2 ) local prettystat "`p'nd Pctile"
        else if ( mod(`p', 10) == 3 ) local prettystat "`p'rd Pctile"
        else                          local prettystat "`p'th Pctile" 
    }
    return local prettystat = `"`prettystat'"'
end
