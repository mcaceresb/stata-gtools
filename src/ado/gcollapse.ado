*! version 1.1.3 23Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -collapse- implementation using C for faster processing

capture program drop gcollapse
program gcollapse, rclass
    version 13.1
    global GTOOLS_USER_VARABBREV `c(varabbrev)'
    local 00 `0'

    * Grab some free timers
    FreeTimer
    local t97: copy local FreeTimer
    global GTOOLS_T97: copy local t97
    gtools_timer on `t97'

    FreeTimer
    local t96: copy local FreeTimer
    if ( `t96' == 0 ) {
        disp as txt "(note: at least one timer required; overriding timer 96)"
        local t96 96
    }
    global GTOOLS_T96: copy local t96
    gtools_timer on `t96'

    global GTOOLS_CALLER gcollapse
    syntax [anything(equalok)]       /// Main function call:
                                     /// [(stat)] varlist [ [(stat)] ... ]
                                     /// [(stat)] target = source [target = source ...] [ [(stat)] ...]
        [if] [in]                    /// [if condition] [in start / end]
        [aw fw iw pw] ,              /// [weight type = exp]
    [                                ///
        by(str)                      /// Collapse by variabes: [+|-]varname [[+|-]varname ...]
        cw                           /// Drop ocase-wise bservations where sources are missing.
        fast                         /// Do not preserve and restore the original dataset. Saves speed
                                     /// but leaves data unusable if the user hits Break.
                                     ///
        merge                        /// Merge statistics back to original data, replacing if applicable
        replace                      /// Allow replacing existing variables with output with merge
        freq(passthru)               /// Include frequency count with observations per group
                                     ///
        LABELFormat(passthru)        /// Custom label engine: (#stat#) #sourcelabel# is the default
        LABELProgram(passthru)       /// Program to parse labelformat (see examples)
                                     ///
        missing                      /// Preserve missing values for sums
        rawstat(passthru)            /// Ignore weights for selected variables
                                     ///
                                     ///
        WILDparse                    /// parse assuming wildcard renaming
        unsorted                     /// Do not sort the data; faster
        forceio                      /// Use disk temp drive for writing/reading collapsed data
        forcemem                     /// Use memory for writing/reading collapsed data
        double                       /// Generate all targets as doubles
        sumcheck                     /// Check whether sum will overflow
        NODS DS                      /// Parse - as varlist (ds) or negative (nods)
                                     ///
        compress                     /// Try to compress strL variables
        forcestrl                    /// Force reading strL variables (stata 14 and above only)
        Verbose                      /// Print info during function execution
        _subtract                    /// (Undocumented) Subtract result from source variable
        _CTOLerance(passthru)        /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                    /// print function benchmark info
        BENCHmarklevel(int 0)        /// print plugin benchmark info
        HASHmethod(passthru)         /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)        /// error|fallback: On collision, use native command or throw error
                                     ///
        debug                        /// (internal) Debug
        DEBUG_level(int 0)           /// (internal) Debug (passed to internals)
        debug_replaceby              /// (internal) Allow replacing by variables with output
        debug_io_read(int 1)         /// (internal) Read IO data using mata or C
        debug_io_check(real 1e6)     /// (internal) Threshold to check for I/O speed gains
        debug_io_threshold(real 10)  /// (internal) Threshold to switch to I/O instead of RAM
    ]

    * Pre-option parsing
    * ------------------

    if ( "`debug'" != "" ) local debug_level 9
    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( "`missing'" != "" ) {
        local keepmissing keepmissing
        disp "Option -missing- is deprecated. Use (nansum) or (rawnansum) instead."
    }

    local replaceby = cond("`debug_replaceby'" == "", "", "replaceby")
    local gfallbackok = `"`replaceby'`replace'`freq'`merge'`labelformat'`labelprogram'`rawstat'"' == `""'

    if ( ("`ds'" != "") & ("`nods'" != "") ) {
        di as err "-ds- and -nods- mutually exclusive"
        exit 198
    }

    * Parse by call (make sure varlist is valid)
    * ------------------------------------------

    if ( `"`by'"' != "" ) {
        local clean_by: copy local by
        local clean_by: subinstr local clean_by "+" " ", all
        if ( strpos(`"`clean_by'"', "-") & ("`ds'`nods'" == "") ) {
            disp as txt "'-' interpreted as negative; use option -ds- to interpret as varlist"
            disp as txt "(to suppress this warning, use option -nods-)"
        }
        if ( "`ds'" != "" ) {
            local clean_by `clean_by'
            if ( "`clean_by'" == "" ) {
                di as err "Invalid varlist: `by'"
                clean_all 198
                exit 198
            }
            cap ds `clean_by'
            if ( _rc ) {
                cap noi ds `clean_by'
                local rc = _rc
                clean_all `rc'
                exit `rc'
            }
            local clean_by `r(varlist)'
        }
        else {
            local clean_by: subinstr local clean_by "-" " ", all
            local clean_by `clean_by'
            if ( "`clean_by'" == "" ) {
                di as err "Invalid list: `by'"
                di as err "Syntax: [+|-]varname [[+|-]varname ...]"
                CleanExit
                exit 198
            }
            cap ds `clean_by'
            if ( _rc ) {
                local notfound
                foreach var of local clean_by {
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
                CleanExit
                exit 111
            }
            qui ds `clean_by'
            local clean_by `r(varlist)'
        }
    }
    if ( "`ds'" == "" ) local nods nods

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "Running {cmd:gcollapse} with debug level `debug_level'"
        disp as txt "{hline 72}"
        disp as txt `""'
        disp as txt `"    anything:           `anything'"'
        disp as txt `"    [if] [in]:          `if' `in'"'
        disp as txt `""'
        disp as txt `"    by:                 `by'"'
        disp as txt `"    cw:                 `cw'"'
        disp as txt `"    fast:               `fast'"'
        disp as txt `""'
        disp as txt `"    merge:              `merge'"'
        disp as txt `"    replace:            `replace'"'
        disp as txt `"    compress:           `compress'"'
        disp as txt `"    forcestrl:          `forcestrl'"'
        disp as txt `"    freq:               `freq'"'
        disp as txt `"    labelformat:        `labelformat'"'
        disp as txt `"    labelprogram:       `labelprogram'"'
        disp as txt `"    unsorted:           `unsorted'"'
        disp as txt `"    forceio:            `forceio'"'
        disp as txt `"    forcemem:           `forcemem'"'
        disp as txt `"    double:             `double'"'
        disp as txt `""'
        disp as txt `"    verbose:            `verbose'"'
        disp as txt `"    benchmark:          `benchmark'"'
        disp as txt `"    benchmarklevel:     `benchmarklevel'"'
        disp as txt `"    hashmethod:         `hashmethod'"'
        disp as txt `"    oncollision:        `oncollision'"'
        disp as txt `""'
        disp as txt `"    debug_replaceby:    `debug_replaceby'"'
        disp as txt `"    debug_io_read:      `debug_io_read'"'
        disp as txt `"    debug_io_check:     `debug_io_check'"'
        disp as txt `"    debug_io_threshold: `debug_io_threshold'"'
        disp as txt "{hline 72}"
        disp as txt `""'
    }

    * Parse options
    * -------------

    if ( ("`forceio'" != "") & ("`merge'" != "") ) {
        di as err "{opt merge} with {opt forceio} is" ///
                  " inefficient and hence not allowed."
        CleanExit
        exit 198
    }

    if ( ("`forceio'" != "") & ("`forcemem'" != "") ) {
        di as err "only specify one of {opt forceio} and {opt forcemem};" ///
                  " cannot do both at the same time."
        CleanExit
        exit 198
    }

    local verb  = ( "`verbose'"   != "" )
    local bench = ( "`benchmark'" != "" )

    if ( "`fast'" == "" ) preserve

    * Parse collapse statement to get sources, targets, and stats
    * -----------------------------------------------------------

    gtools_timer on `t97'
    cap noi parse_vars `anything' `if' `in', ///
        `cw' `labelformat' `labelprogram' `freq' `wildparse'

    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    local __gtools_gc_uniq_targets : list uniq __gtools_gc_targets
    local nonunique: list __gtools_gc_targets - __gtools_gc_uniq_targets
    if ( `:list sizeof nonunique' != 0 ) {
        di as err "Repeat targets not allowed: `:list uniq nonunique'"
        CleanExit
        exit 198
    }

    foreach var of local __gtools_gc_uniq_vars {
        cap noi confirm numeric variable `var'
        if ( _rc ) {
            local rc = _rc
            CleanExit
            exit `rc'
        }
    }

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "{cmd:gcollapse} debug level `debug_level'"
        disp as txt "{hline 72}"
        disp as txt `"parse_vars"'
        disp as txt `"    anything:           `anything'"'
        disp as txt `"    [if] [in]:          `if' `in'"'
        disp as txt `""'
        disp as txt `"    cw:                 `cw'"'
        disp as txt `"    fast:               `fast'"'
        disp as txt `""'
        disp as txt `"    freq:               `freq'"'
        disp as txt `"    labelformat:        `labelformat'"'
        disp as txt `"    labelprogram:       `labelprogram'"'
        disp as txt `""'
        disp as txt "    __gtools_gc_targets:    `__gtools_gc_targets'"
        disp as txt "    __gtools_gc_vars:       `__gtools_gc_vars'"
        disp as txt "    __gtools_gc_stats:      `__gtools_gc_stats'"
        disp as txt "    __gtools_gc_uniq_vars:  `__gtools_gc_uniq_vars'"
        disp as txt "    __gtools_gc_uniq_stats: `__gtools_gc_uniq_stats'"
        disp as txt `""'
        disp as txt "{hline 72}"
        disp as txt `""'
    }

    * Parse weights
    * -------------

    if ( `:list posof "count" in __gtools_gc_uniq_stats' > 0 ) {
        if ( `"`weight'"' == "aweight" ) {
            local awnote 1
        }
        else local awnote 0
    }
    else if ( `:list posof "nmissing" in __gtools_gc_uniq_stats' > 0 ) {
        if ( `"`weight'"' == "aweight" ) {
            local awnote 1
        }
        else local awnote 0
    }
    else local awnote 0

    if ( `:list posof "variance" in __gtools_gc_uniq_stats' > 0 ) {
        if ( `"`weight'"' == "pweight" ) {
            di as err "variance not allowed with pweights"
            exit 135
        }
    }
    if ( `:list posof "cv" in __gtools_gc_uniq_stats' > 0 ) {
        if ( `"`weight'"' == "pweight" ) {
            di as err "cv not allowed with pweights"
            exit 135
        }
    }
    if ( `:list posof "sd" in __gtools_gc_uniq_stats' > 0 ) {
        if ( `"`weight'"' == "pweight" ) {
            di as err "sd not allowed with pweights"
            exit 135
        }
    }
    if ( `:list posof "semean" in __gtools_gc_uniq_stats' > 0 ) {
        if ( inlist(`"`weight'"', "pweight", "iweight") ) {
            di as err "semean not allowed with `weight's"
            exit 135
        }
    }
    if ( `:list posof "sebinomial" in __gtools_gc_uniq_stats' > 0 ) {
        if ( inlist(`"`weight'"', "aweight", "iweight", "pweight") ) {
            di as err "sebinomial not allowed with `weight's"
            exit 135
        }
    }
    if ( `:list posof "sepoisson" in __gtools_gc_uniq_stats' > 0 ) {
        if ( inlist(`"`weight'"', "aweight", "iweight", "pweight") ) {
            di as err "sepoisson not allowed with `weight's"
            exit 135
        }
    }
    if ( regexm("^select", `"`__gtools_gc_uniq_stats'"') ) {
        if ( inlist(`"`weight'"', "iweight") ) {
            di as err "select not allowed with `weight's"
            exit 135
        }
    }

	if ( `"`weight'"' != "" ) {
		tempvar w
		qui gen double `w' `exp' `if' `in'
		local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
	}
    else local weights

    * Subset if requested
    * -------------------

    if ( (`"`if'`wgt'"' != `""') | ("`cw'" != "") ) {
        * marksample touse, strok novarlist
        tempvar touse
        mark `touse' `if' `in' `wgt'
        if ( "`cw'" != "" ) {
            markout `touse' `gtools_uniq_vars', strok
        }
        if ( "`merge'" == "" ) {
            qui keep if `touse'
            local ifin ""
        }
        else local ifin if `touse' `in'
    }
    else {
        local ifin `in'
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

    set varabbrev off
    cap noi parse_keep_drop, by(`clean_by') `double'       ///
        `merge' `replace' `replaceby' `sumcheck' `weights' ///
        __gtools_gc_targets(`__gtools_gc_targets')         ///
        __gtools_gc_vars(`__gtools_gc_vars')               ///
        __gtools_gc_stats(`__gtools_gc_stats')             ///
        __gtools_gc_uniq_vars(`__gtools_gc_uniq_vars')     ///
        __gtools_gc_uniq_stats(`__gtools_gc_uniq_stats')

    set varabbrev ${GTOOLS_USER_VARABBREV}
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    local dropme       ""
    local keepvars     "`r(keepvars)' `w'"
    local added        "`r(added)'"
    local memvars      "`r(memvars)'"
    local check_recast "`r(check_recast)'"

    scalar __gtools_gc_k_targets    = `:list sizeof __gtools_gc_targets'
    scalar __gtools_gc_k_vars       = `:list sizeof __gtools_gc_vars'
    scalar __gtools_gc_k_stats      = `:list sizeof __gtools_gc_stats'
    scalar __gtools_gc_k_uniq_vars  = `:list sizeof __gtools_gc_uniq_vars'
    scalar __gtools_gc_k_uniq_stats = `:list sizeof __gtools_gc_uniq_stats'

    mata: gtools_vars     = tokens(`"`__gtools_gc_vars'"')
    mata: gtools_targets  = tokens(`"`__gtools_gc_targets'"')
    mata: gtools_stats    = tokens(`"`__gtools_gc_stats'"')

    cap noi CheckMatsize `clean_by'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    cap noi CheckMatsize `__gtools_gc_vars'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    cap noi CheckMatsize `__gtools_gc_targets'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    cap noi CheckMatsize `__gtools_gc_stats'
    if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "{cmd:gcollapse} debug level `debug_level'"
        disp as txt "{hline 72}"
        disp as txt `"parse_keep_drop"'
        disp as txt `""'
        disp as txt `"    by:                 `by'"'
        disp as txt `"    clean_by:           `clean_by'"'
        disp as txt `""'
        disp as txt `"    merge:              `merge'"'
        disp as txt `"    double:             `double'"'
        disp as txt `"    replace:            `replace'"'
        disp as txt `"    compress:           `compress'"'
        disp as txt `"    forcestrl:          `forcestrl'"'
        disp as txt `"    replaceby:          `replaceby'"'
        disp as txt `""'
        disp as txt `"    __gtools_gc_targets:    `__gtools_gc_targets'"'
        disp as txt `"    __gtools_gc_vars:       `__gtools_gc_vars'"'
        disp as txt `"    __gtools_gc_stats:      `__gtools_gc_stats'"'
        disp as txt `"    __gtools_gc_uniq_vars:  `__gtools_gc_uniq_vars'"'
        disp as txt `"    __gtools_gc_uniq_stats: `__gtools_gc_uniq_stats'"'
        disp as txt `""'
        disp as txt `"    dropme:              `dropme'"'
        disp as txt `"    keepvars:            `keepvars'"'
        disp as txt `"    added:               `added'"'
        disp as txt `"    memvars:             `memvars'"'
        disp as txt `"    check_recast:        `check_recast'"'
        disp as txt `""'
        disp as txt `"    scalar __gtools_gc_k_targets    = `=scalar(__gtools_gc_k_targets)'"'
        disp as txt `"    scalar __gtools_gc_k_vars       = `=scalar(__gtools_gc_k_vars)'"'
        disp as txt `"    scalar __gtools_gc_k_stats      = `=scalar(__gtools_gc_k_stats)'"'
        disp as txt `"    scalar __gtools_gc_k_uniq_vars  = `=scalar(__gtools_gc_k_uniq_vars)'"'
        disp as txt `"    scalar __gtools_gc_k_uniq_stats = `=scalar(__gtools_gc_k_uniq_stats)'"'
        disp as txt `""'
        disp as txt "{hline 72}"
        disp as txt `""'
    }

    * Timers!
    * -------

    local msg "Parsed by variables, sources, and targets"
    gtools_timer info `t97' `"`msg'"', prints(`bench')

    ***********************************************************************
    *                   Recast variables to save memory                   *
    ***********************************************************************

    * Recast sources, if applicable
    mata: st_numscalar("__gtools_gc_k_recast", cols(__gtools_gc_recastvars))
    if ( `=scalar(__gtools_gc_k_recast)' > 0 ) {
        local gtools_recastvars ""
        local gtools_recastsrc  ""
        forvalues k = 1 / `=scalar(__gtools_gc_k_recast)' {
            mata: st_local("var", __gtools_gc_recastvars[`k'])
            tempvar dropvar
            rename `var' `dropvar'
            local dropme `dropme' `dropvar'
            local gtools_recastvars `gtools_recastvars' `var'
            local gtools_recastsrc  `gtools_recastsrc'  `dropvar'
        }

        qui mata: st_addvar(__gtools_gc_recasttypes, __gtools_gc_recastvars, 1)
        if ( `=_N > 0' ) {
            cap noi _gtools_internal, ///
                recast(targets(`gtools_recastvars') sources(`gtools_recastsrc'))
            if ( _rc ) {
                local rc = _rc
                CleanExit
                exit `rc'
            }
        }

        local msg `"Recast source variables to save memory"'
        gtools_timer info `t97' `"`msg'"', prints(`bench')
    }

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "{cmd:gcollapse} debug level `debug_level'"
        disp as txt "{hline 72}"
        disp as txt `"recast"'
        disp as txt `""'
        disp as txt `"    gtools_recastvars   `gtools_recastvars'"'
        disp as txt `"    gtools_recastsrc    `gtools_recastsrc'"'
        disp as txt `""'
        disp as txt "{hline 72}"
        disp as txt `""'
    }

    ***********************************************************************
    *                               Reorder                               *
    ***********************************************************************

    local _: list memvars - __gtools_gc_uniq_vars
    local memorder: list memvars - _

    mata: gtools_vars_mem = tokens("`memorder'")
    mata: gtools_pos      = gtools_vars :== gtools_targets
    mata: gtools_io_order = selectindex(gtools_pos), selectindex(!gtools_pos)

    * First, make sure that the sources used as targets appear first
    mata: gtools_vars      = gtools_vars      [gtools_io_order]
    mata: gtools_targets   = gtools_targets   [gtools_io_order]
    mata: gtools_stats     = gtools_stats     [gtools_io_order]
    mata: __gtools_gc_labels  = __gtools_gc_labels  [gtools_io_order]
    mata: __gtools_gc_formats = __gtools_gc_formats [gtools_io_order]

    * Now make sure that the sources are in memory order
    tempname k1 k2 ord
    mata: `k1'  = cols(gtools_vars_mem)
    mata: `k2'  = cols(gtools_vars)
    mata: `ord' = gtools_vars[1::`k1']
    mata: gtools_mem_order = J(1, 0, .)
    mata: for(k = 1; k <= `k1'; k++) gtools_mem_order = gtools_mem_order, selectindex(gtools_vars_mem[k] :== `ord')
    mata: gtools_mem_order = (`k2' > `k1')? gtools_mem_order, ((`k1' + 1)::`k2')': gtools_mem_order
    cap mata: mata drop `k'
    cap mata: mata drop `ord'

    mata: gtools_vars      = gtools_vars      [gtools_mem_order]
    mata: gtools_targets   = gtools_targets   [gtools_mem_order]
    mata: gtools_stats     = gtools_stats     [gtools_mem_order]
    mata: __gtools_gc_labels  = __gtools_gc_labels  [gtools_mem_order]
    mata: __gtools_gc_formats = __gtools_gc_formats [gtools_mem_order]

    * At each step we reordered stats, soruces, and targets!
    local __gtools_gc_order   `__gtools_gc_targets'
    local __gtools_gc_vars    ""
    local __gtools_gc_targets ""
    local __gtools_gc_stats   ""
    forvalues k = 1 / `=scalar(__gtools_gc_k_targets)' {
        mata: st_local("var",  gtools_vars   [`k'])
        mata: st_local("targ", gtools_targets[`k'])
        mata: st_local("stat", gtools_stats  [`k'])
        local __gtools_gc_vars     `__gtools_gc_vars'    `var'
        local __gtools_gc_targets  `__gtools_gc_targets' `targ'
        local __gtools_gc_stats    `__gtools_gc_stats'   `stat'
    }
    local __gtools_gc_uniq_stats: list uniq __gtools_gc_stats
    local __gtools_gc_uniq_vars:  list uniq __gtools_gc_vars

    ***********************************************************************
    *                             I/O switch                              *
    ***********************************************************************

    tempfile __gtools_gc_file
    scalar __gtools_gc_k_extra = __gtools_gc_k_targets - __gtools_gc_k_uniq_vars

    local sources  sources(`__gtools_gc_vars')
    local stats    stats(`__gtools_gc_stats')
    local targets  targets(`__gtools_gc_targets')
    local opts     missing replace `keepmissing' `compress' `forcestrl' `_subtract' `_ctolerance'
    local opts     `opts' `verbose' `benchmark' `benchmarklevel' `hashmethod' `ds' `nods'
    local opts     `opts' `oncollision' debug(`debug_level') `rawstat'
    local action   `sources' `targets' `stats'

    local switch = (`=scalar(__gtools_gc_k_extra)' > 3) & (`debug_io_check' < `=_N')
    local mem    = ("`forcemem'" != "") ///
                 | ("`merge'"    != "") ///
                 | (`=scalar(__gtools_gc_k_extra)' == 0)
    local io     = ("`forceio'"  != "") & (`=scalar(__gtools_gc_k_extra)' > 0)

    if ( `io' ) {
        * Drop rest of vars
        local plugvars `clean_by' `__gtools_gc_uniq_vars'
        local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme - plugvars'
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

        local gcollapse gcollapse(forceio, fname(`__gtools_gc_file'))
        local action    `action' fill(data) `unsorted'
    }
    else if ( !`mem' & `switch' ) {

        * Replace source vars in memory, since they already exist
        local plugvars `clean_by' `__gtools_gc_uniq_vars'

        * It will be faster to add targets with fewer variables in
        * memory. Dropping superfluous variables also saves memory.
        local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme  - plugvars'

        * Drop extra vars
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))
        local msg `"Dropped superfluous variables"'
        gtools_timer info `t97' `"`msg'"', prints(`bench')

        * Benchmark adding 2 variables to gauge how long it might take to
        * add __gtools_gc_k_extra variables.
        tempvar __gtools_gc_index __gtools_gc_ix __gtools_gc_info
        cap noi benchmark_memvars,     ///
            index(`__gtools_gc_index') ///
            ix(`__gtools_gc_ix')       ///
            info(`__gtools_gc_info')
        if ( _rc ) {
            local rc = _rc
            CleanExit
            exit `rc'
        }

        local st_time = `r(st_time)'
        gtools_timer info `t97' `"`r(st_str)'"', prints(`bench')

        if ( `st_time' > 0 ) {
            * Call the plugin with switch option
            * ----------------------------------

            local st_time   st_time(`=`st_time' / `debug_io_threshold'')
            local ixinfo    ixinfo(`__gtools_gc_index' `__gtools_gc_ix' `__gtools_gc_info')
            local gcollapse gcollapse(switch, `st_time' fname(`__gtools_gc_file') `ixinfo')
            local action    `action' fill(data) `unsorted'
        }
        else {

            * If benchmark was 0, add the vars right now
            * ------------------------------------------

            qui mata: st_addvar(__gtools_gc_addtypes, __gtools_gc_addvars, 1)
            local msg "Generated additional targets"
            gtools_timer info `t97' `"`msg'"', prints(`bench')

            local gcollapse gcollapse(memory)
            local action    `action' fill(data) `unsorted'
        }
    }
    else {

        local plugvars `clean_by' `__gtools_gc_uniq_vars'
        if ( "`merge'" == "" ) local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme - plugvars'

        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))
        local msg `"Dropped superfluous variables"'
        gtools_timer info `t97' `"`msg'"', prints(`bench')

        if ( ("`forceio'" == "forceio") & (`=scalar(__gtools_gc_k_extra)' == 0) ) {
            if ( `verb' ) {
                di as text "(ignored -forceio- because sources are being used as targets)"
            }
        }

        if ( "`added'" != "" ) {
            qui mata: st_addvar(__gtools_gc_addtypes, __gtools_gc_addvars, 1)
        }
        local msg "Generated additional targets"
        gtools_timer info `t97' `"`msg'"', prints(`bench')

        local gcollapse gcollapse(memory, `merge')
        local action    `action' `:di cond("`merge'" == "", "fill(data)", "unsorted")'
    }

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "{cmd:gcollapse} debug level `debug_level'"
        disp as txt "{hline 72}"
        disp as txt `"recast"'
        disp as txt `""'
        disp as txt `"    scalar __gtools_gc_k_extra = `=scalar(__gtools_gc_k_extra)'"'
        disp as txt `""'
        disp as txt `"    plugvars:      `plugvars'"'
        disp as txt `"    dropme:        `dropme'"'
        disp as txt `"    memvars:       `memvars'"'
        disp as txt `""'
        disp as txt `"    sources:       `sources'"'
        disp as txt `"    stats:         `stats'"'
        disp as txt `"    targets:       `targets'"'
        disp as txt `"    unsorted:      `unsorted'"'
        disp as txt `"    opts:          `opts'"'
        disp as txt `""'
        disp as txt `"    switch:        `switch'"'
        disp as txt `"    mem:           `mem'"'
        disp as txt `"    io:            `io'"'
        disp as txt `""'
        disp as txt `"    gtools_stats:  `gtools_stats'"'
        disp as txt `""'
        disp as txt `"    action:        `action'"'
        disp as txt `"    gcollapse:     `gcollapse'"'
        disp as txt `""'
        disp as txt "{hline 72}"
        disp as txt `""'

        disp `"_gtools_internal `by' `ifin', `opts' `weights' `action' `gcollapse' gfunction(collapse)"'
    }

    cap noi _gtools_internal `by' `ifin', `opts' `weights' `action' `gcollapse' gfunction(collapse)
    if ( _rc == 17999 ) {
        if ( "`gfallbackok'" != "" ) {
            di as err "Cannot use fallback with gtools-only options"
            exit 17000
        }
        local 0 `00'
        syntax [anything(equalok)] [if] [in] , [ by(passthru) cw fast *]
        collapse `anything' `if' `in', `by' `cw' `fast'
        exit 0
    }
    else if ( _rc == 17001 ) {
        local rc = _rc
        CleanExit
        error 2000
    }
    else if ( _rc ) {
        local rc = _rc
        CleanExit
        exit `rc'
    }
    local used_io = `r(used_io)'
    local r_N     = `r(N)'
    local r_J     = `r(J)'
    local r_minJ  = `r(minJ)'
    local r_maxJ  = `r(maxJ)'
    matrix __gtools_invert = r(invert)

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
            if ( `=`r_J' > 0' ) keep in 1 / `:di %32.0f `r_J''
            else if ( `=`r_J' == 0' ) {
                keep in 1
                drop if 1
            }
            else if ( `=`r_J' < 0' ) {
                di as err "The plugin returned a negative number of groups."
                di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
                CleanExit
                exit 17200
            }
            ds *
        }
        if ( `=_N' == 0 ) di as txt "(no observations)"

        * Make sure no extra variables are present
        * ----------------------------------------

        local memvars  `r(varlist)'
        local keepvars `clean_by' `__gtools_gc_targets'
        local dropme   `:list memvars - keepvars'
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

        * If we collapsed to disk, read back the data
        * -------------------------------------------

        local ifcond (`=_N > 0')                          ///
                   & (`=scalar(__gtools_gc_k_extra)' > 0) ///
                   & ( `used_io' | ("`forceio'" == "forceio") ) 
        if ( `ifcond' ) {
            gtools_timer on `t97'

            qui mata: st_addvar(__gtools_gc_addtypes, __gtools_gc_addvars, 1)
            gtools_timer info `t97' `"Added extra targets after collapse"', prints(`bench')

            local __gtools_gc_iovars: list __gtools_gc_targets - __gtools_gc_uniq_vars
            local gcollapse gcollapse(read, fname(`__gtools_gc_file'))
            if ( `debug_io_read' ) {
                cap noi _gtools_internal, `gcollapse' `action' gfunction(collapse)
                if ( _rc ) {
                    local rc = _rc
                    CleanExit
                    exit `rc'
                }
            }
            else {
                local nrow = `=_N'
                local ncol = `=scalar(__gtools_gc_k_extra)'
                mata: __gtools_gc_data = gtools_get_collapsed (`"`__gtools_gc_file'"', `nrow', `ncol')
                mata: st_store(., tokens(`"`__gtools_gc_iovars'"'), __gtools_gc_data)
                cap mata: mata drop __gtools_gc_data
            }

            gtools_timer info `t97' `"Read extra targets from disk"', prints(`bench')
        }

        * Order variables if they are not in user-requested order
        * -------------------------------------------------------

        local order = 0
        qui ds *
        local varorder `r(varlist)'
        local varsort  `clean_by' `__gtools_gc_order'
        foreach varo in `varorder' {
            gettoken svar varsort: varsort
            if ("`varo'" != "`vars'") local order = 1
        }
        if ( `order' ) order `clean_by' `__gtools_gc_order'

        * Label the things in the style of collapse
        * -----------------------------------------

        forvalues k = 1 / `:list sizeof __gtools_gc_targets' {
            mata: st_varlabel(gtools_targets[`k'], __gtools_gc_labels[`k'])
            mata: st_varformat(gtools_targets[`k'], __gtools_gc_formats[`k'])
        }
    }
    else {
        forvalues k = 1 / `:list sizeof __gtools_gc_targets' {
            mata: st_varlabel(gtools_targets[`k'], __gtools_gc_labels[`k'])
        }
        forvalues k = 1 / `:list sizeof __gtools_gc_targets' {
            mata: st_varformat(gtools_targets[`k'], __gtools_gc_formats[`k'])
        }
    }

    ***********************************************************************
    *                            Program Exit                             *
    ***********************************************************************

    if ( ("`unsorted'" == "") & ("`merge'" == "") ) {
        mata: st_local("invert", strofreal(sum(st_matrix("__gtools_invert"))))
        if ( `invert' ) {
            mata: st_numscalar("__gtools_first_inverted", ///
                               selectindex(st_matrix("__gtools_invert"))[1])
            if ( `=scalar(__gtools_first_inverted)' > 1 ) {
                local sortvars ""
                forvalues i = 1 / `=scalar(__gtools_first_inverted) - 1' {
                    local sortvars `sortvars' `:word `i' of `clean_by''
                }
                sort `sortvars'
            }
        }
        else if ( "`clean_by'" != "" ) {
            sort `clean_by'
        }
    }

    gtools_timer on `t97'
    if ( "`fast'" == "" ) restore, not

    local msg "Program exit executed"
    gtools_timer info `t97' `"`msg'"', prints(`bench') off

	if ( `awnote' ) {
		di as txt "(note: {bf:aweight}s not used to compute {bf:count}s or {bf:nmissing})"
	}

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

    * If timer is 0, then there were no free timers; skip this benchmark
    if ( `timer' == 0 ) exit 0

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

capture program drop FreeTimer
program FreeTimer
    qui {
        timer list
        local i = 99
        while ( (`i' > 0) & ("`r(t`i')'" != "") ) {
            local --i
        }
    }
    c_local FreeTimer `i'
end

***********************************************************************
*                          Gcollapse helpers                          *
***********************************************************************

cap mata: mata drop gtools_get_collapsed()
mata
real matrix function gtools_get_collapsed(
    string scalar fname,
    real scalar nrow,
    real scalar ncol)
{
    real scalar fh
    real matrix X
    colvector C
    fh = fopen(fname, "r")
    C = bufio()
    X = fbufget(C, fh, "%8z", nrow, ncol)
    fclose(fh)
    return (X)
}
end

capture program drop parse_vars
program parse_vars
    syntax [anything(equalok)] ///
        [if] [in] ,            /// subset
    [                          ///
        cw                     /// case-wise non-missing
        WILDparse              /// parse assuming wildcard renaming
        freq(str)              /// include number of observations in group
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
        if ( "`wildparse'" != "" ) {
            local rc = 0
            ParseListWild `anything', loc(__gtools_gc_call)

            local __gtools_bak_stats      `__gtools_gc_stats'
            local __gtools_bak_vars       `__gtools_gc_vars'
            local __gtools_bak_targets    `__gtools_gc_targets'
            local __gtools_bak_uniq_stats `__gtools_gc_uniq_stats'
            local __gtools_bak_uniq_vars  `__gtools_gc_uniq_vars'

            ParseList `__gtools_gc_call'

            cap assert ("`__gtools_gc_stats'" == "`__gtools_bak_stats'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_gc_vars'" == "`__gtools_bak_vars'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_gc_targets'" == "`__gtools_bak_targets'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_gc_uniq_stats'" == "`__gtools_bak_uniq_stats'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_gc_uniq_vars'" == "`__gtools_bak_uniq_vars'")
            local rc = max(_rc, `rc')

            if ( `rc' ) {
                disp as error "Wild parsing inconsistent with standard parsing."
                exit 198
            }
        }
        else {
            ParseList `anything'
        }
    }

    if ( "`freq'" != "" ) {
        local __gtools_gc_targets `__gtools_gc_targets' `freq'
        local __gtools_gc_stats   `__gtools_gc_stats' freq
        local __gtools_gc_vars    `__gtools_gc_vars' `:word 1 of `__gtools_gc_vars''
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

    mata: __gtools_gc_formats = J(1, `:list sizeof __gtools_gc_targets', "")
    mata: __gtools_gc_labels  = J(1, `:list sizeof __gtools_gc_targets', "")
    forvalues k = 1 / `:list sizeof __gtools_gc_targets' {
        local vl = `"`:variable label `:word `k' of `__gtools_gc_vars'''"'
        local vl = cond(`"`vl'"' == "", `"`:word `k' of `__gtools_gc_vars''"', `"`vl'"')
        local vp = `"`:word `k' of `__gtools_gc_stats''"'

        if ( "`labelprogram'" == "" ) GtoolsPrettyStat `vp'
        else `labelprogram' `vp'
        local vpretty = `"`r(prettystat)'"'

        if ( `"`vpretty'"' == "#default#" ) {
            GtoolsPrettyStat `vp'
            local vpretty = `"`r(prettystat)'"'
        }

        local lfmt_k = `"`labelformat'"'

        if ( "`vp'" == "freq" ) {
            if !regexm(`"`vl'"', "`ltxt_regex'") {
                while regexm(`"`lfmt_k'"', "`ltxt_regex'") {
                    local lfmt_k = regexs(1) + `""' + regexs(3)
                }
            }
            if !regexm(`"`vl'"', "`lsub_regex'") {
                while regexm(`"`lfmt_k'"', "`lsub_regex'") {
                    local lfmt_k = regexs(1) + `""' + regexs(4)
                }
            }
        }
        else {
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
        mata: __gtools_gc_labels[`k'] = `"`lfmt_k'"'

        local vf = "`:format `:word `k' of `__gtools_gc_vars'''"
        local vf = cond(inlist("`:word `k' of `__gtools_gc_stats''", "count", "freq", "nunique", "nmissing"), "%8.0g", "`vf'")
        mata: __gtools_gc_formats[`k'] = "`vf'"
    }

    * Available Stats
    * ---------------

    local stats sum        ///
                nansum     /// if every entry is missing, output . instead of 0
                mean       ///
                sd         ///
                variance   ///
                cv         ///
                max        ///
                min        ///
                range      ///
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
                sepoisson  ///
                nunique    ///
                nmissing   ///
                skewness   ///
                kurtosis   ///
                rawsum     ///
                rawnansum  //  if every entry is missing, output . instead of 0

    * Parse quantiles
    local anyquant  = 0
    local quantiles : list __gtools_gc_uniq_stats - stats

    foreach quantile of local quantiles {
        if regexm("`quantile'", "rawselect") {
            local select = regexm("`quantile'", "^rawselect(-|)([0-9]+)$")
            if ( `select' == 0 ) {
                di as error "Invalid stat: (`quantile'; did you mean rawselect# or rawselect-#?)"
                error 110
            }
            else if ( `=regexs(2)' == 0 ) {
                di as error "Invalid stat: (`quantile' not allowed; selection must be 1 or larger)"
                error 110
            }
        }
        else if regexm("`quantile'", "select") {
            local select = regexm("`quantile'", "^select(-|)([0-9]+)$")
            if ( `select' == 0 ) {
                di as error "Invalid stat: (`quantile'; did you mean select# or select-#?)"
                error 110
            }
            else if ( `=regexs(2)' == 0 ) {
                di as error "Invalid stat: (`quantile' not allowed; selection must be 1 or larger)"
                error 110
            }
        }
        else {
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
    }

    if ( "`freq'" != "" ) {
        local __gtools_gc_uniq_stats `__gtools_gc_uniq_stats' freq
    }

    * Locals one level up
    * -------------------

    * unab __gtools_gc_targets:   `__gtools_gc_targets'
    unab __gtools_gc_vars:      `__gtools_gc_vars'
    unab __gtools_gc_uniq_vars: `__gtools_gc_uniq_vars'

    c_local __gtools_gc_targets    `__gtools_gc_targets'
    c_local __gtools_gc_vars       `__gtools_gc_vars'
    c_local __gtools_gc_stats      `__gtools_gc_stats'
    c_local __gtools_gc_uniq_vars  `__gtools_gc_uniq_vars'
    c_local __gtools_gc_uniq_stats `__gtools_gc_uniq_stats'
end

capture program drop parse_keep_drop
program parse_keep_drop, rclass
    syntax,                         ///
    [                               ///
        weights(str)                ///
        replace                     ///
        replaceby                   ///
        merge                       ///
        double                      ///
        sumcheck                    ///
        by(varlist)                 ///
        __gtools_gc_targets(str)    ///
        __gtools_gc_vars(str)       ///
        __gtools_gc_stats(str)      ///
        __gtools_gc_uniq_vars(str)  ///
        __gtools_gc_uniq_stats(str) ///
    ]

    * The code assumes targets either do not exist or are named the same as
    * the source variable. If a target exists in memory but is not one of the
    * sources, rename the target to a dummy

    local __gtools_gc_i = 0
    if ( "`merge'" == "" ) {
        foreach var in `__gtools_gc_targets' {
            cap confirm variable `var'
            if ( (_rc == 0) & !`:list var in __gtools_gc_vars' ) {
                cap confirm variable __gtools_gc`__gtools_gc_i'
                while ( _rc == 0 ) {
                    local ++__gtools_gc_i
                    cap confirm variable __gtools_gc`__gtools_gc_i'
                }
                rename `var' __gtools_gc`__gtools_gc_i'
            }
        }
    }

    * Try to be smart about creating target variables
    * -----------------------------------------------

    local __gtools_gc_keepvars `__gtools_gc_uniq_vars'

    * If not merging, then be smart about creating new variable columns
    if ( "`merge'" == "" ) {
        scalar __gtools_gc_merge = 0

        local __gtools_gc_vars      " `__gtools_gc_vars' "
        local __gtools_gc_uniq_vars " `__gtools_gc_uniq_vars' "
        local __gtools_gc_keepvars  " `__gtools_gc_keepvars' "

        local __gtools_gc_vars:      subinstr local __gtools_gc_vars      " "  "  ", all
        local __gtools_gc_uniq_vars: subinstr local __gtools_gc_uniq_vars " "  "  ", all
        local __gtools_gc_keepvars:  subinstr local __gtools_gc_keepvars  " "  "  ", all

        local K: list sizeof __gtools_gc_targets
        forvalues k = 1 / `K' {
            unab memvars : _all

            local k_target: word `k' of `__gtools_gc_targets'
            local k_var:    word `k' of `__gtools_gc_vars'
            local k_stat:   word `k' of `__gtools_gc_stats'

            * Only use as target if the type matches
            * parse_ok_astarget, sourcevar(`k_var') targetvar(`k_target') stat(`k_stat') `double'
            * if ( `:list k_var in __gtools_gc_uniq_vars' & `r(ok_astarget)' ) {

            * Always try to use as target; will recast if necessary
            if ( `:list k_var in __gtools_gc_uniq_vars' ) {
                local __gtools_gc_uniq_vars: list __gtools_gc_uniq_vars - k_var
                if ( !`:list k_var in __gtools_gc_targets' & !`:list k_target in memvars' ) {
                    local __gtools_gc_vars      " `__gtools_gc_vars' "
                    local __gtools_gc_uniq_vars " `__gtools_gc_uniq_vars' "
                    local __gtools_gc_keepvars  " `__gtools_gc_keepvars' "
                    local __gtools_gc_vars:      subinstr local __gtools_gc_vars      " `k_var' " " `k_target' ", all
                    local __gtools_gc_uniq_vars: subinstr local __gtools_gc_uniq_vars " `k_var' " " `k_target' ", all
                    local __gtools_gc_keepvars:  subinstr local __gtools_gc_keepvars  " `k_var' " " `k_target' ", all
                    local __gtools_gc_vars      `__gtools_gc_vars'
                    local __gtools_gc_uniq_vars `__gtools_gc_uniq_vars'
                    local __gtools_gc_keepvars  `__gtools_gc_keepvars'
                    rename `k_var' `k_target'
                }
            }
        }
        local __gtools_gc_vars      " `__gtools_gc_vars' "
        local __gtools_gc_uniq_vars " `__gtools_gc_uniq_vars' "
        local __gtools_gc_keepvars  " `__gtools_gc_keepvars' "
        local __gtools_gc_vars:      subinstr local __gtools_gc_vars      "  " " ", all
        local __gtools_gc_uniq_vars: subinstr local __gtools_gc_uniq_vars "  " " ", all
        local __gtools_gc_keepvars:  subinstr local __gtools_gc_keepvars  "  " " ", all
        local __gtools_gc_vars      `__gtools_gc_vars'
        local __gtools_gc_uniq_vars `__gtools_gc_uniq_vars'
        local __gtools_gc_keepvars  `__gtools_gc_keepvars'

        local keepvars `by' `__gtools_gc_keepvars'
    }
    else {
        scalar __gtools_gc_merge = 1
        if ( "`replace'" == "" ) {
            local intersection: list __gtools_gc_targets & __gtools_gc_vars
            if ( "`intersection'" != "" ) {
                di as error "merge targets also sources with no replace: `intersection'"
                error 110
            }

            unab memvars: _all
            local intersection: list memvars - __gtools_gc_vars
            local intersection: list intersection - by
            local intersection: list __gtools_gc_targets & intersection
            if ( "`intersection'" != "" ) {
                di as error "merge targets exist with no replace: `intersection'"
                error 110
            }
        }
    }

    local intersection: list __gtools_gc_targets & by
    if ( "`intersection'" != "" ) {
        if ( "`replaceby'" == "" ) {
            di as error "targets also in by(): `intersection'"
            error 110
        }
    }

    * Variables in memory; will compare to keepvars
    * ---------------------------------------------

    * Unfortunately, this is necessary for C. We cannot create variables
    * from C, and we cannot halt the C execution, create the final data
    * in Stata, and then go back to C.

    unab memvars : _all
    local added  ""

    mata: __gtools_gc_addvars     = J(1, 0, "")
    mata: __gtools_gc_addtypes    = J(1, 0, "")
    mata: __gtools_gc_recastvars  = J(1, 0, "")
    mata: __gtools_gc_recasttypes = J(1, 0, "")

    c_local __gtools_gc_vars      `__gtools_gc_vars'
    c_local __gtools_gc_uniq_vars `__gtools_gc_keepvars'

    * If any of the other requested stats are not counts, freq, nunique,
    * or nmissing, upgrade! Otherwise you'll get the wrong result.

    local __gtools_upgrade
    local __gtools_upgrade_vars
    local __gtools_upgrade_list freq count nunique nmissing
    forvalues i = 1 / `:list sizeof __gtools_gc_targets' {
        local src:  word `i' of `__gtools_gc_vars'
        local stat: word `i' of `__gtools_gc_stats'
        if ( !`:list stat in __gtools_upgrade_list' ) {
            local __gtools_upgrade_vars `__gtools_upgrade_vars' `src'
        }
    }
    local __gtools_upgrade_vars: list uniq __gtools_upgrade_vars

    * If requested, check whether sum will overflow. Assign smallest
    * possible type given sum.

    local __gtools_sumok
    local __gtools_sumcheck
    gettoken wtype wvar: weights
    if ( ("`sumcheck'" != "") & inlist(`"`wtype'"', "fweight", "") ) {
        foreach var in `: list uniq __gtools_gc_vars' {
            if ( inlist("`:type `var''", "byte", "int", "long") ) {
                local __gtools_sumcheck `__gtools_sumcheck' `var'
            }
        }

        if ( `:list sizeof __gtools_sumcheck' > 0 ) {
            cap noi _gtools_internal, sumcheck(`__gtools_sumcheck') weights(`weights')
            if ( _rc ) {
                local rc = _rc
                CleanExit
                exit `rc'
            }

            matrix __gtools_sumcheck = r(sumcheck)
            forvalues i = 1 / `:list sizeof __gtools_sumcheck' {
                local s = __gtools_sumcheck[1, `i']
                if ( `s' > maxlong() ) {
                    local __gtools_sumok `__gtools_sumok' double
                    if ( mi(`s') ) {
                        disp as err "{bf:Overflow warning:} (sum) `:word `i' of `__gtools_sumcheck''"
                    }
                }
                else if ( `s' > maxint() ) {
                    local __gtools_sumok `__gtools_sumok' long
                }
                else if ( `s' > maxbyte() ) {
                    local __gtools_sumok `__gtools_sumok' int
                }
                else {
                    local __gtools_sumok `__gtools_sumok' byte
                }
            }
        }
    }

    * Loop through all the targets to determine which type is most
    * appropriate. Also check whether we can the source variable for the
    * first target; if not, we will recast the source variable.

    local check_recast ""
    foreach var of local __gtools_gc_targets {
        gettoken sourcevar __gtools_gc_vars:  __gtools_gc_vars
        gettoken collstat  __gtools_gc_stats: __gtools_gc_stats
        local upgrade = `:list sourcevar in __gtools_upgrade_vars'
        local sumtype = "double"

        * I try to match Stata's types when possible
        if regexm("`collstat'", "first|last|min|max|select|rawselect") {
            * First, last, min, max, and select can preserve type, clearly
            local targettype: type `sourcevar'
        }
        else if regexm("`collstat'", "range") {
            * Upgrade type by one
            local targettype: type `sourcevar'
            if ( `"`targettype'"' == "byte" ) {
                local targettype int
            }
            else if ( `"`targettype'"' == "int" ) {
                local targettype long
            }
            else if ( `"`targettype'"' == "long" ) {
                local targettype double
            }
            else if ( `"`targettype'"' == "float" ) {
                local targettype double
            }
            else if ( `"`targettype'"' == "double" ) {
                local targettype double
            }
        }
        else if ( inlist("`collstat'", "freq", "nunique") & ( `=_N < maxlong()' ) ) {
            * freqs can be long if we have fewer than 2^31 observations
            * (largest signed integer in long variables can be 2^31-1)
            local targettype = cond(`upgrade', "double", "long")
        }
        else if ( inlist("`collstat'", "freq", "nunique") & !( `=_N < maxlong()' ) ) {
            local targettype double
        }
        else if ( "`double'" != "" ) {
            local targettype double
        }
        else if ( inlist("`collstat'", "count", "nmissing") & (`=_N < maxlong()') & (`"`weights'"' == "") ) {
            * Counts can be long if we have fewer than 2^31 observations
            * (largest signed integer in long variables can be 2^31-1).
            * With weights, however, count is sum w_i, so the rules are
            * as with sums in that case.
            local targettype = cond(`upgrade', "double", "long")
        }
        else if ( inlist("`collstat'", "count", "nmissing") & !((`=_N < maxlong()') & (`"`weights'"' == "")) ) {
            local targettype double
        }
        else if ( inlist("`collstat'", "sum", "nansum", "rawsum", "rawnansum") ) {
            * Sums are double so we don't overflow; however, if the
            * user requested sumcheck we assign byte, int, and long the
            * smallest possible type.
            local targettype double
            if ( `:list sourcevar in __gtools_sumcheck' ) {
                local pos: list posof "`sourcevar'" in __gtools_sumcheck
                local targettype: word `pos' of `__gtools_sumok'
            }
            local sumtype: copy local targettype
        }
        else if ( "`:type `sourcevar''" == "long" ) {
            * Some operations on long variables with target float can be
            * inaccurate
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
            mata: __gtools_gc_addvars  = __gtools_gc_addvars,  "`var'"
            mata: __gtools_gc_addtypes = __gtools_gc_addtypes, "`targettype'"
            local added `added' `var'
        }
        else {
            * We only recast integers. Floats and doubles are preserved unless
            * requested or the target is a sum.
            parse_ok_astarget,     ///
                sourcevar(`var')   ///
                targetvar(`var')   ///
                stat(`collstat')   ///
                sumtype(`sumtype') ///
                `double' weights(`weights')
            local recast = !(`r(ok_astarget)')

            if ( `recast' ) {
                mata: __gtools_gc_recastvars  = __gtools_gc_recastvars,  "`var'"
                mata: __gtools_gc_recasttypes = __gtools_gc_recasttypes, "`targettype'"
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
    syntax, sourcevar(varlist) targetvar(str) stat(str) sumtype(str) [double weights(str)]
    local ok_astarget = 0
    local sourcetype  = "`:type `sourcevar''"

    * I try to match Stata's types when possible
    if regexm("`stat'", "first|last|min|max|select|rawselect") {
        * First, last, min, max, and select can preserve type, clearly
        local targettype `sourcetype'
        local ok_astarget = 1
    }
    else if regexm("`stat'", "range") {
        * Upgrade type by one
        local ok_astarget = 0
        if ( `"`sourcetype'"' == "byte" ) {
            local targettype int
        }
        else if ( `"`sourcetype'"' == "int" ) {
            local targettype long
        }
        else if ( `"`sourcetype'"' == "long" ) {
            local targettype double
        }
        else if ( `"`sourcetype'"' == "float" ) {
            local targettype double
        }
        else if ( `"`sourcetype'"' == "double" ) {
            local targettype double
            local ok_astarget = 1
        }
    }
    else if ( "`double'" != "" ) {
        local targettype double
        local ok_astarget = ("`:type `sourcevar''" == "double")
    }
    else if ( inlist("`stat'", "freq", "nunique") & ( `=_N < maxlong()' ) ) {
        local targettype long
        local ok_astarget = inlist("`:type `sourcevar''", "long", "double")
    }
    else if ( inlist("`stat'", "freq", "nunique") & !( `=_N < maxlong()' ) ) {
        local targettype double
    }
    else if ( inlist("`stat'", "count", "nmissing") & (`=_N < maxlong()') & (`"`weights'"' == "") ) {
        local targettype long
        local ok_astarget = inlist("`:type `sourcevar''", "long", "double")
    }
    else if ( inlist("`stat'", "count", "nmissing") & !((`=_N < maxlong()') & (`"`weights'"' == "")) ) {
        local targettype double
    }
    else if ( inlist("`stat'", "sum", "nansum", "rawsum", "rawnansum") ) {
        * Sums are double so we don't overflow; however, if the
        * user requested sumcheck we assign byte, int, and long the
        * smallest possible type.
        local targettype double
        local ok_astarget = ("`:type `sourcevar''" == "double")
        if ( !`ok_astarget' & ("`sumtype'" != "double") & ("`:type `sourcevar''" != "float") ) {
            if ( ("`:type `sourcevar''" == "long") & inlist("`sumtype'", "byte", "int", "long") ) {
                local ok_astarget = 1
            }
            else if ( ("`:type `sourcevar''" == "int") & inlist("`sumtype'", "byte", "int") ) {
                local ok_astarget = 1
            }
            else if ( ("`:type `sourcevar''" == "byte") & inlist("`sumtype'", "byte") ) {
                local ok_astarget = 1
            }
            else {
                local ok_astarget = 0
            }
        }
    }
    else if ( "`:type `sourcevar''" == "long" ) {
        * Some operations on long variables with target float can be
        * inaccurate
        local targettype double
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
    if ( `=_N < maxlong()' ) {
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
        cap timer off ${GTOOLS_T96}
        cap timer clear ${GTOOLS_T96}
        timer on ${GTOOLS_T96}
    }
    qui mata: st_addvar(("`itype'"), ("`index'"), 1)
    {
        cap timer off ${GTOOLS_T96}
        qui timer list
        local total_time = r(t${GTOOLS_T96})
        cap timer clear ${GTOOLS_T96}
        timer on ${GTOOLS_T96}
    }
    qui mata: st_addvar(("`itype'"), ("`ix'"), 1)
    {
        cap timer off ${GTOOLS_T96}
        qui timer list
        local total_time = `total_time' + r(t${GTOOLS_T96})
        cap timer clear ${GTOOLS_T96}
        timer on ${GTOOLS_T96}
    }

    qui mata: st_addvar(("`itype'"), ("`info'"), 1)
    {
        cap timer off ${GTOOLS_T96}
        qui timer list
        local total_time = `total_time' + r(t${GTOOLS_T96})
        cap timer clear ${GTOOLS_T96}
    }

    local mib     = `=_N * 8 / 1024 / 1024'
    local mib_str = trim("`:di %15.2gc 2 * `mib''")
    local n_str   = trim("`:di %15.0gc `=_N''")
    return local st_str  = `"Added index and info (`n_str' obs; approx `mib_str'MiB)"'
    return local st_time = max(`total_time', 0.001) * scalar(__gtools_gc_k_extra) * `factor'
    * return local st_time = `total_time' * scalar(__gtools_gc_k_extra) * `factor'
end

capture program drop CleanExit
program CleanExit
    set varabbrev ${GTOOLS_USER_VARABBREV}
    global GTOOLS_USER_VARABBREV
    global GTOOLS_CALLER

    cap mata: mata drop __gtools_gc_formats
    cap mata: mata drop __gtools_gc_labels

    cap mata: mata drop __gtools_gc_addvars
    cap mata: mata drop __gtools_gc_addtypes
    cap mata: mata drop __gtools_gc_recastvars
    cap mata: mata drop __gtools_gc_recasttypes

    cap mata: mata drop gtools_vars
    cap mata: mata drop gtools_targets
    cap mata: mata drop gtools_stats

    cap mata: mata drop gtools_pos
    cap mata: mata drop gtools_vars_mem
    cap mata: mata drop gtools_io_order
    cap mata: mata drop gtools_mem_order

    cap mata: mata drop __gtools_gc_asfloat
    cap mata: mata drop __gtools_gc_checkrecast
    cap mata: mata drop __gtools_gc_norecast
    cap mata: mata drop __gtools_gc_keeprecast

    cap mata: mata drop __gtools_gc_iovars

    cap scalar drop __gtools_gc_k_recast
    cap scalar drop __gtools_gc_merge

    cap scalar drop __gtools_gc_k_extra
    cap scalar drop __gtools_gc_k_targets
    cap scalar drop __gtools_gc_k_vars
    cap scalar drop __gtools_gc_k_stats
    cap scalar drop __gtools_gc_k_uniq_vars
    cap scalar drop __gtools_gc_k_uniq_stats

    cap scalar drop __gtools_first_inverted
    cap matrix drop __gtools_invert

    cap timer off   $GTOOLS_T97
    cap timer clear $GTOOLS_T97

    cap timer off   $GTOOLS_T96
    cap timer clear $GTOOLS_T96

    global GTOOLS_T97
    global GTOOLS_T96
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
    if ( `"`0'"' == "nansum"      ) local prettystat "Sum"
    if ( `"`0'"' == "mean"        ) local prettystat "Mean"
    if ( `"`0'"' == "sd"          ) local prettystat "St Dev."
    if ( `"`0'"' == "variance"    ) local prettystat "Variance"
    if ( `"`0'"' == "cv"          ) local prettystat "Coef. of variation"
    if ( `"`0'"' == "max"         ) local prettystat "Max"
    if ( `"`0'"' == "min"         ) local prettystat "Min"
    if ( `"`0'"' == "range"       ) local prettystat "Range"
    if ( `"`0'"' == "count"       ) local prettystat "Count"
    if ( `"`0'"' == "freq"        ) local prettystat "Group size"
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
    if ( `"`0'"' == "nunique"     ) local prettystat "N Unique"
    if ( `"`0'"' == "nmissing"    ) local prettystat "N Missing"
    if ( `"`0'"' == "skewness"    ) local prettystat "Skewness"
    if ( `"`0'"' == "kurtosis"    ) local prettystat "Kurtosis"
    if ( `"`0'"' == "rawsum"      ) local prettystat "Unweighted sum"
    if ( `"`0'"' == "rawnansum"   ) local prettystat "Unweighted sum"

    local match = 0
    if regexm(`"`0'"', "^rawselect(-|)([0-9]+)$") {
        if ( `"`:di regexs(1)'"' == "-" ) {
            local Pretty Largest (Unweighted)
        }
        else {
            local Pretty Smallest (Unweighted)
        }
        local p = `=regexs(2)'
        local match = 1
    }
    else if regexm(`"`0'"', "^select(-|)([0-9]+)$") {
        if ( `"`:di regexs(1)'"' == "-" ) {
            local Pretty Largest
        }
        else {
            local Pretty Smallest
        }
        local p = `=regexs(2)'
        local match = 1
    }
    else if regexm(`"`0'"', "^p([0-9][0-9]?(\.[0-9]+)?)$") {
        local p = `:di regexs(1)'
        local Pretty Pctile
        local match = 1
    }

    if ( `match' ) {
        if ( inlist(substr(`"`p'"', -2, 2), "11", "12", "13") ) {
            local prettystat "`s'th `Pretty'"
        }
        else {
                 if ( mod(`p', 10) == 1 ) local prettystat "`p'st `Pretty'"
            else if ( mod(`p', 10) == 2 ) local prettystat "`p'nd `Pretty'"
            else if ( mod(`p', 10) == 3 ) local prettystat "`p'rd `Pretty'"
            else                          local prettystat "`p'th `Pretty'"
        }
    }

    return local prettystat = `"`prettystat'"'
end

***********************************************************************
*         Parse assuming the call includes wildcard renaming          *
***********************************************************************

capture program drop ParseListWild
program ParseListWild
    syntax [anything(equalok)], [LOCal(str)]
    local stat mean

    if ( "`local'" == "" ) local local gcollapse_call

    * Trim spaces
    local 0 `anything'
    while strpos("`0'", "  ") {
        local 0: subinstr local 0 "  " " ", all
    }
    local 0 `0'

    * Parse each portion of the collapse call
    while (trim("`0'") != "") {
        GetStat   stat   0 : `0'
        GetTarget target 0 : `0'
        gettoken  vars   0 : 0

        * Must specify stat (if blank, we do the mean)
        if ( "`stat'" == "" ) {
            disp as err "option stat() requried"
            exit 198
        }

        if ( "`stat'" == "var"  ) local stat variance
        if ( "`stat'" == "sem"  ) local stat semean
        if ( "`stat'" == "seb"  ) local stat sebinomial
        if ( "`stat'" == "sep"  ) local stat sepoisson
        if ( "`stat'" == "skew" ) local stat skewness
        if ( "`stat'" == "kurt" ) local stat kurtosis

        * Parse bulk rename if applicable
        unab usources : `vars'
        if ( "`eqsign'" == "=" ) {
            cap noi rename `vars' `target'
            if ( _rc ) {
                disp as err "Targets cannot exist with option {opt wildparse}."
                exit `=_rc'
            }
            unab utargets : `target'
            rename (`utargets') (`usources')

            local full_vars    `full_vars'    `usources'
            local full_targets `full_targets' `utargets'

            local call `call' (`stat')
            foreach svar of varlist `usources' {
                gettoken tvar utargets: utargets
                local call `call' `tvar' = `svar'
                local full_stats  `full_stats' `stat'
            }
        }
        else {
            local call `call' (`stat') `usources'
            local full_vars    `full_vars'    `usources'
            local full_targets `full_targets' `usources'

            foreach svar of varlist `usources' {
                local full_stats `full_stats' `stat'
            }
        }

        local target
    }

    * Check that targets don't repeat
    local dups : list dups targets
    if ("`dups'" != "") {
        di as error "repeated targets in collapse: `dups'"
        error 110
    }

    * disp "`call'"
    c_local `local' `call'
    c_local __gtools_gc_targets    `full_targets'
    c_local __gtools_gc_stats      `full_stats'
    c_local __gtools_gc_vars       `full_vars'
    c_local __gtools_gc_uniq_stats : list uniq full_stats
    c_local __gtools_gc_uniq_vars  : list uniq full_vars
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

        * Must specify stat (if blank, we do the mean)
        if ( "`stat'" == "" ) {
            disp as err "option stat() requried"
            exit 198
        }

        foreach var of local vars {
            if ("`target'" == "") local target `var'

            if ( "`stat'" == "var"  ) local stat variance
            if ( "`stat'" == "sem"  ) local stat semean
            if ( "`stat'" == "seb"  ) local stat sebinomial
            if ( "`stat'" == "sep"  ) local stat sepoisson
            if ( "`stat'" == "skew" ) local stat skewness
            if ( "`stat'" == "kurt" ) local stat kurtosis

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

    c_local __gtools_gc_targets    `full_targets'
    c_local __gtools_gc_stats      `full_stats'
    c_local __gtools_gc_vars       `full_vars'
    c_local __gtools_gc_uniq_stats : list uniq full_stats
    c_local __gtools_gc_uniq_vars  : list uniq full_vars
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
        c_local eqsign "="
    }
    else {
        c_local eqsign
    }
end
