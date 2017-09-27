*! version 0.7.1 27Sep2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -collapse- implementation using C for faster processing

capture program drop gcollapse
program gcollapse
    version 13
    if inlist("`c(os)'", "MacOSX") {
        di as err "Not available for `c(os)'."
        exit 198
    }

    syntax [anything(equalok)]        /// main call; must parse manually
        [if] [in] ,                   /// subset
    [                                 ///
        by(varlist)                   /// collapse by variabes
        cw                            /// case-wise non-missing
        fast                          /// do not preserve/restore
        Verbose                       /// debugging
        Benchmark                     /// print benchmark info
                                      ///
        smart                         /// check if data is sorted to speed up hashing
        merge                         /// merge statistics back to original data, replacing where applicable
                                      ///
        double                        /// do all operations in double precision
        forceio                       /// use disk temp drive for writing/reading collapsed data
        forcemem                      /// use memory for writing/reading collapsed data
        hashlib(str)                  /// path to hash library (Windows only)
                                      /// greedy /// (Planned) skip the memory-saviung recasts and drops
                                      ///
        oncollision(str)              /// (experimental) On collision, fall back to collapse or throw error
        debug_checkhash               /// (experimental) Check for hash collisions
        debug_force_hash              /// (experimental) Force use of SpookyHash (usually slower)
        debug_force_single            /// (experimental) Force non-multi-threaded version
        debug_force_multi             /// (experimental) Force muti-threading
        debug_io_check(real 1e6)      /// (experimental) Threshold to check for I/O speed gains
        debug_io_threshold(real 10)   /// (experimental) Threshold to switch to I/O instead of RAM
        debug_io_read_method(int 0)   /// (experimental) Read back using mata or C
    ]

    * Check you will find the hash library (Windows only)
    * ---------------------------------------------------

    if ( "`hashlib'" == "" ) {
        local hashlib `c(sysdir_plus)'s/spookyhash.dll
        local hashusr 0
    }
    else local hashusr 1
    if ( ("`c(os)'" == "Windows") & `hashusr' ) {
        cap confirm file spookyhash.dll
        if ( _rc | `hashusr' ) {
            cap findfile spookyhash.dll
            if ( _rc | `hashusr' ) {
                cap confirm file `"`hashlib'"'
                if ( _rc ) {
                    local url https://raw.githubusercontent.com/mcaceresb/stata-gtools
                    local url `url'/master/spookyhash.dll
                    di as err `"'`hashlib'' not found."'
                    di as err "Download {browse "`url'":here} or run {opt gtools, dependencies}"'
                    exit 198
                }
            }
            else local hashlib `r(fn)'
            mata: __gtools_hashpath = ""
            mata: __gtools_dll = ""
            mata: pathsplit(`"`hashlib'"', __gtools_hashpath, __gtools_dll)
            mata: st_local("__gtools_hashpath", __gtools_hashpath)
            mata: mata drop __gtools_hashpath
            mata: mata drop __gtools_dll
            local path: env PATH
            if inlist(substr(`"`path'"', length(`"`path'"'), 1), ";") {
                mata: st_local("path", substr(`"`path'"', 1, `:length local path' - 1))
            }
            local __gtools_hashpath: subinstr local __gtools_hashpath "/" "\", all
            local newpath `"`path';`__gtools_hashpath'"'
            local truncate 2048
            if ( `:length local newpath' > `truncate' ) {
                local loops = ceil(`:length local newpath' / `truncate')
                mata: __gtools_pathpieces = J(1, `loops', "")
                mata: __gtools_pathcall   = ""
                mata: for(k = 1; k <= `loops'; k++) __gtools_pathpieces[k] = substr(st_local("newpath"), 1 + (k - 1) * `truncate', `truncate')
                mata: for(k = 1; k <= `loops'; k++) __gtools_pathcall = __gtools_pathcall + " `" + `"""' + __gtools_pathpieces[k] + `"""' + "' "
                mata: st_local("pathcall", __gtools_pathcall)
                mata: mata drop __gtools_pathcall __gtools_pathpieces
                cap plugin call env_set, PATH `pathcall'
            }
            else {
                cap plugin call env_set, PATH `"`path';`__gtools_hashpath'"'
            }
            if ( _rc ) {
                di as err "Unable to add '`__gtools_hashpath'' to system PATH."
                exit _rc
            }
        }
        else local hashlib spookyhash.dll
    }
    scalar __gtools_l_hashlib = length(`"`hashlib'"')

    ***********************************************************************
    *                       Parsing syntax options                        *
    ***********************************************************************

    local website_url  https://github.com/mcaceresb/stata-gtools/issues
    local website_disp github.com/mcaceresb/stata-gtools

    if ( "`oncollision'" == "" ) local oncollision fallback
    if ( !inlist("`oncollision'", "fallback", "error") ) {
        di as err "option -oncollision()- must be 'fallback' or 'error'"
        exit 198
    }

    if ( ("`merge'" != "") & ("`if'" != "") ) {
        di as err "combining -merge- with -if- is currently buggy; a fix is planned v0.5.1"
        exit 198
    }

    if ( ("`forceio'" != "") & ("`merge'" != "") ) {
        di as err "-merge- with -forceio- is inefficient and hence not allowed."
        exit 198
    }

    if ( ("`forceio'" != "") & ("`forcemem'" != "") ) {
        di as err "only specify one of -forceio- and -forcemem-; cannot do both at the same time."
        exit 198
    }

    * Parse options (no variable manupulation)
    parse_opts, `verbose' `benchmark'  ///
                hashlib(`hashlib')     ///
                `debug_force_single'   ///
                `debug_force_multi'    ///
                `debug_checkhash'      ///
                                        //

    local multi       "`r(muti)'"
    local plugin_call "`r(plugin_call)'"
    local verbose     `r(verbose)'
    local benchmark   `r(benchmark)'
    local checkhash   `r(checkhash)'

    * While C can read macros, it's generally easier to read scalars
    scalar __gtools_verbose   = `verbose'
    scalar __gtools_benchmark = `benchmark'
    scalar __gtools_checkhash = `checkhash'

    * -gegen- option; included here so plugin is consistent but it
    * is ignored for gcollapse
    scalar __gtools_missing = 0

    if ( `verbose'  | `benchmark' ) local noi noisily

    ***********************************************************************
    *                Parse summary stats and by variables                 *
    ***********************************************************************

    * Timers!
    * -------

    * 98 will be used for the function execution; 97 will be a step timer
    gtools_timer on 98
    gtools_timer on 97

    * Start the actual function execution
    * -----------------------------------

    if ( "`fast'" == "" ) preserve

    * Check if data is sorted already
    local smart = ( "`smart'" != "" ) & ( "`anything'" != "" ) & ( "`by'" != "" )

    * If by is not specified, collapse to single row
    if ( "`by'" == "" ) {
        tempvar byvar
        gen byte `byvar' = 0
        local by `byvar'
    }
    else {
        qui ds `by'
        local by `r(varlist)'
    }

    * Parse
    * - smart option: if data is sorted, index in Stata
    * - by variables: figure out variable types (will choose different
    *                 algorithms if all are numeric vs a mix)
    * - subset: If applicable, drop missings (cw) or keep if in.
    * - check plugin: Use multi-threaded if correctly loaded; fall back
    *                 on single-threaded otherwise.
    parse_vars `anything' `if' `in', by(`by') `cw' smart(`smart') v(`verbose') `multi' `debug_force_hash'
    local indexed `r(indexed)'
    if ( `=_N' == 0 ) {
        di as err "no observations"
        exit 2000
    }
    if ( `indexed' ) {
        tempvar bysmart
        by `by': gen long `bysmart' = (_n == 1)
    }

    * Parse variables to keep (by variables, sources) and drop (all
    * else). Also parse which source variables to recast (see below; we
    * try to use source variables as their first target to save memory)
    parse_keep_drop, by(`by') `merge' `double'     ///
        bysmart(`bysmart')                         ///
        indexed(`indexed')                         ///
        verbose(`verbose')                         ///
        __gtools_targets(`__gtools_targets')       ///
        __gtools_vars(`__gtools_vars')             ///
        __gtools_stats(`__gtools_stats')           ///
        __gtools_uniq_vars(`__gtools_uniq_vars')   ///
        __gtools_uniq_stats(`__gtools_uniq_stats') ///
                                                   //

    local dropme       "`r(dropme)'"
    local keepvars     "`r(keepvars)'"
    local added        "`r(added)'"
    local memvars      "`r(memvars)'"
    local check_recast "`r(check_recast)'"

    * Get a list with all string by variables
    local bystr ""
    qui foreach byvar of varlist `by' {
        local bytype: type `byvar'
        if regexm("`bytype'", "str([1-9][0-9]*|L)") {
            local bystr `bystr' `byvar'
        }
    }

    * Locals to be read by C (via c_local)
    * ------------------------------------

    local gtools_targets    `__gtools_targets'
    local gtools_vars       `__gtools_vars'
    local gtools_stats      `__gtools_stats'
    local gtools_uniq_vars  `__gtools_uniq_vars'
    local gtools_uniq_stats `__gtools_uniq_stats'
*
    scalar __gtools_l_targets    = length("`gtools_targets'")
    scalar __gtools_l_vars       = length("`gtools_vars'")
    scalar __gtools_l_stats      = length("`gtools_stats'")
    scalar __gtools_l_uniq_vars  = length("`gtools_uniq_vars'")
    scalar __gtools_l_uniq_stats = length("`gtools_uniq_stats'")

    scalar __gtools_k_targets    = `:list sizeof gtools_targets'
    scalar __gtools_k_vars       = `:list sizeof gtools_vars'
    scalar __gtools_k_stats      = `:list sizeof gtools_stats'
    scalar __gtools_k_uniq_vars  = `:list sizeof gtools_uniq_vars'
    scalar __gtools_k_uniq_stats = `:list sizeof gtools_uniq_stats'

    local gtools_orig_stats      `gtools_stats'
    local gtools_orig_uniq_stats `gtools_uniq_stats'

    * mata: gtools_vars     = `:di subinstr(`""`gtools_vars'""',    " ", `"", ""', .)'
    * mata: gtools_targets  = `:di subinstr(`""`gtools_targets'""', " ", `"", ""', .)'
    * mata: gtools_stats    = `:di subinstr(`""`gtools_stats'""',   " ", `"", ""', .)'
    mata: gtools_vars     = tokens(`"`gtools_vars'"')
    mata: gtools_targets  = tokens(`"`gtools_targets'"')
    mata: gtools_stats    = tokens(`"`gtools_stats'"')

    mata: gtools_pos      = gtools_vars :== gtools_targets
    mata: gtools_io_order = selectindex(gtools_pos), selectindex(!gtools_pos)

    * Check matrix size will be able to handle the number of variables.
    * If not, try setting matsize to a number larger than the number
    * of variables. If it fails exit with error and prompt the user to
    * try to set matsize manually; this should display Stata's message
    * noting the matsize limit for their version.
    local bynum `:list by - bystr'

    cap noi check_matsize `bystr'
    if ( _rc ) exit _rc

    cap noi check_matsize `bynum'
    if ( _rc ) exit _rc

    cap noi check_matsize `gtools_vars'
    if ( _rc ) exit _rc

    * Position of input to each target variable (note C has 0-based indexing)
    cap matrix drop __gtools_outpos
    foreach var of local gtools_vars {
        matrix __gtools_outpos = nullmat(__gtools_outpos), (`:list posof `"`var'"' in gtools_uniq_vars' - 1)
    }

    * Position of string variables (the position in the variable list
    * passed to C has 1-based indexing, however)
    cap matrix drop __gtools_strpos
    foreach var of local bystr {
        matrix __gtools_strpos = nullmat(__gtools_strpos), `:list posof `"`var'"' in by'
    }

    * Position of numeric variables (ibid.)
    cap matrix drop __gtools_numpos
    foreach var of local bynum {
        matrix __gtools_numpos = nullmat(__gtools_numpos), `:list posof `"`var'"' in by'
    }

    * Timers!
    * -------

    * End timer for parsing; benchmark keep/drop
    local msg "Parsed by variables, sources, and targets"
    gtools_timer info 97 `"`msg'"', prints(`benchmark')

    ***********************************************************************
    *                     Set up data for the plugin                      *
    ***********************************************************************

    * Recast variables to save mem
    * ----------------------------

    * Recast variables when there is no better option
    mata: st_numscalar("__gtools_k_recast", cols(__gtools_recastvars))
    if ( `=scalar(__gtools_k_recast)' > 0 ) {

        local totry: list sizeof check_recast
        if ( ("`double'" == "") & (`:list sizeof check_recast' > 0) ) {
            cap noi check_matsize `check_recast'
            if ( _rc ) exit _rc

            * Since recasting variables is really expensive, we will not recast
            * variables where the summary stat is a sum and the result cannot be
            * larger than +/-10^38 (see help data_types).
            matrix c_gtools_bymiss = J(1, `:list sizeof check_recast', 0)
            matrix c_gtools_bymin  = J(1, `:list sizeof check_recast', 0)
            matrix c_gtools_bymax  = J(1, `:list sizeof check_recast', 0)

            if ( (`=_N > 0') & (`:list sizeof check_recast' > 0) ) {
                cap `plugin_call' `check_recast', setup
                if ( _rc ) exit _rc
                mata: c_gtools_bymin   = (`=_N' :* st_matrix("c_gtools_bymin")) :> -10^38
                mata: c_gtools_bymax   = (`=_N' :* st_matrix("c_gtools_bymax")) :< 10^38
                mata: __gtools_asfloat = ( c_gtools_bymin :& c_gtools_bymax )
            }

            * mata: __gtools_checkrecast = (`:di subinstr(`""`check_recast'""', " ", `"", ""', .)')
            mata: __gtools_checkrecast = tokens(`"`check_recast'"')
            mata: __gtools_norecast    = J(1, 0, .)
            mata: __gtools_keeprecast  = J(1, 0, .)
            mata: for (k = 1; k <= cols(__gtools_checkrecast); k++) ///
                __gtools_norecast = __gtools_norecast,              ///
                (__gtools_asfloat[k]? selectindex(__gtools_checkrecast[k] :== __gtools_recastvars): J(1, 0, .))
            mata: for (k = 1; k <= cols(__gtools_recastvars); k++) ///
                __gtools_keeprecast = __gtools_keeprecast,         ///
                (sum(k :== __gtools_norecast)? J(1, 0, .): k)

            * Lease floats as is when their sum won't overflow
            mata: __gtools_recastvars  = __gtools_recastvars [__gtools_keeprecast]
            mata: __gtools_recasttypes = __gtools_recasttypes[__gtools_keeprecast]
            mata: st_numscalar("__gtools_k_recast", cols(__gtools_recastvars))
        }

        * Recast variables as doubles if the sum might overflow
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
                cap `noi' `plugin_call' `gtools_recastvars' `gtools_recastsrc', recast
                if ( _rc != 0 ) exit _rc
            }
            gtools_timer info 97 `"Recast source variables to save memory"', prints(`benchmark')
        }
        else {
            if ( `verbose' ) di as txt "(skipped recasting `totry' floats; to force recasting run with option -double-)"
        }
    }

    * Use I/O instead of memory for results (faster for J small)
    * ----------------------------------------------------------

    tempfile __gtools_file
    scalar __gtools_k_extra = __gtools_k_targets - __gtools_k_uniq_vars

    local used_io    = 0
    local tried_io   = 0
    local check_data = (`=_N' > `debug_io_check') & (`=scalar(__gtools_k_extra)' > 3) & (`=_N > 0')
    local check_io   = ("`merge'" == "") & ("`forcemem'" == "") & ("`forceio'" == "")

    * Only check if data is large and there are more than 3 extra variables
    if ( `check_data' & `check_io' ) {

        * Re-order statistics (we try to use sources as targets; if the
        * source was used as a target for any statistic other than the
        * first, then we need to re-order the summary stats).
        local gtools_stats ""
        forvalues k = 1 / `=scalar(__gtools_k_targets)' {
            mata: st_local("stat", gtools_stats[gtools_io_order[`k']])
            local gtools_stats `gtools_stats' `stat'
        }
        local gtools_uniq_stats: list uniq gtools_stats

        * We replace source variables in memory, since they already exist in memory
        local plugvars `by' `gtools_uniq_vars' `gtools_uniq_vars' index info `bysmart'

        * It will be faster to add targets with fewer variables in
        * memory. Dropping superfluous variables also saves memory.
        local dropme `dropme' `:list memvars - keepvars'
        local dropme `:list dropme  - plugvars'
        * if ( "`dropme'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))
        gtools_timer info 97 `"Dropped superfluous variables"', prints(`benchmark')

        * Initialize __gtools_J; pass whether the data was indexed in stata
        scalar __gtools_J = `=_N'
        scalar __gtools_indexed = cond(`indexed', `:list sizeof plugvars', 0)

        * Benchmark adding 2 variables to gauge how long it might take
        * to add __gtools_k_extra variables.
        qui {
            mata: st_addvar(("double"), ("index"), 1)
            mata: st_addvar(("double"), ("info"), 1)
            local MiB    = `=_N * 8 * 2' / 1024 / 1024
            local MiBstr = trim("`:di %15.2gc `MiB''")
            local Nstr   = trim("`:di %15.0gc `=_N''")
        }
        gtools_timer info 97 `"Added index and info (`Nstr' obs; approx `MiBstr'MiB)"', prints(`benchmark')
        scalar __gtools_bench_st  = `r(t97)' / `MiB'
        scalar __gtools_mib_base  = scalar(__gtools_k_extra) * 8 / 1024 / 1024
        scalar __gtools_io_thresh = `debug_io_threshold'

        * Collapse the data. If it will be faster to collapse to disk,
        * this stores the results in binary format to `__gtools_file'.
        * If it will be slower, then it stores the index and info
        * variabes in memory (it will be faster to pick up the execution
        * from there than re-hash and re-sort).
        cap `noi' `plugin_call' `plugvars', collapse index `"`__gtools_file'"'
        if ( _rc == 42000 ) {
            di as err "There may be 128-bit hash collisions!"
            di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
            if ( "`oncollision'" == "fallback" ) {
                cap noi collision_handler `0'
                if ( "`fast'" == "" ) restore, not
                exit _rc
            }
            else exit 42000 
        }
        else if ( _rc != 0 ) exit _rc

        * If we collapsed to disk, no need to collapse to memory
        local used_io = `=scalar(__gtools_used_io)'

        * If we did not collapse to disk, note that we tried it so we
        * pick up from having already hashed and sorted the data.
        local tried_io = 1 & !`used_io'

        if ( `used_io' ) {
            if ( `benchmark' ) gtools_timer info 97 `"Wrote collapsed data to disk"', prints(1)
            else if ( `verbose' ) di "Will read collapsed data back into memory from disk."
        }
        else {
            if ( `benchmark' ) gtools_timer info 97 `"Indexed by variables"', prints(1)
            else if ( `verbose' ) di "Will generate targets in memory before collapse."
        }
    }

    * If we tried to use IO, pick up from where we left off
    if ( `tried_io' ) {

        * If we tried IO, shiffle the summary stats back
        local gtools_stats      `gtools_orig_stats'
        local gtools_uniq_stats `gtools_orig_uniq_stats'

        local plugvars `by' `gtools_uniq_vars' `gtools_targets' index info
        scalar __gtools_indexed = `:list sizeof plugvars' - 1

        * Add the targets to memory
        qui {
            if ( "`added'"  != "" ) mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
            ds *
        }
        if ( `verbose' ) di as text "In memory: `r(varlist)'"
        local msg "Generated additional targets"
        gtools_timer info 97 `"`msg'"', prints(`benchmark')

        * Collapse to memory using hashed data index and info
        cap `noi' `plugin_call' `plugvars', collapse ixfinish `"`__gtools_file'"'
        if ( _rc != 0 ) exit _rc

        gtools_timer info 97 `"Collapsed indexed data to memory"', prints(`benchmark')
    }
    else if ( !`used_io' ) {

        * If we did not try to use IO and we have not collapsed to disk, then:
        if ( ("`forceio'" == "forceio") & ("`merge'" == "") & (`=scalar(__gtools_k_extra)' > 0) & (`=_N > 0') ) {
            * Use IO anyway if the user requested it.

            * Re-order statistics (we try to use sources as targets; if the
            * source was used as a target for any statistic other than the
            * first, then we need to re-order the summary stats).
            local gtools_stats ""
            forvalues k = 1 / `=scalar(__gtools_k_targets)' {
                mata: st_local("stat", gtools_stats[gtools_io_order[`k']])
                local gtools_stats `gtools_stats' `stat'
            }
            local gtools_uniq_stats: list uniq gtools_stats

            local plugvars `by' `gtools_uniq_vars' `gtools_uniq_vars' `bysmart'
            scalar __gtools_J = `=_N'
            scalar __gtools_indexed = cond(`indexed', `:list sizeof plugvars', 0)

            if ( "`merge'"  == "" ) local dropme `dropme' `:list memvars - keepvars'
            local dropme `:list dropme - plugvars'
            * if ( "`dropme'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))
            if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

            qui ds *
            if ( `verbose' ) di as text "In memory: `r(varlist)'"
            cap `noi' `plugin_call' `plugvars', collapse ixwrite `"`__gtools_file'"'
            if ( _rc == 42000 ) {
                di as err "There may be 128-bit hash collisions!"
                di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
                if ( "`oncollision'" == "fallback" ) {
                    cap noi collision_handler `0'
                    if ( "`fast'" == "" ) restore, not
                    exit _rc
                }
                else exit 42000 
            }
            else if ( _rc != 0 ) exit _rc
            gtools_timer info 97 `"Collapsed data to disk (forced by user)"', prints(`benchmark')
        }
        else {
            * Do the regular gcollapse (drop extra vars; add targets in
            * memory, then full collapse run)

            local plugvars `by' `gtools_uniq_vars' `gtools_targets' `bysmart'
            scalar __gtools_J = `=_N'
            scalar __gtools_indexed = cond(`indexed', `:list sizeof plugvars', 0)

            if ( "`merge'"  == "" ) local dropme `dropme' `:list memvars - keepvars'
            local dropme `:list dropme - plugvars'
            * if ( "`dropme'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))
            if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

            if ( ("`forceio'" == "forceio") & (`=scalar(__gtools_k_extra)' == 0) ) {
                if ( `verbose' ) di as text "(ignored option -forceio- because sources are being used as targets)"
            }

            qui {
                if ( "`added'"  != "" ) mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
                ds *
            }
            if ( `verbose' ) di as text "In memory: `r(varlist)'"
            local msg "Generated additional targets"
            gtools_timer info 97 `"`msg'"', prints(`benchmark')

            * Run the full plugin:
            if ( `=_N > 0' ) {
                cap `noi' `plugin_call' `plugvars', collapse
                if ( _rc == 42000 ) {
                    di as err "There may be 128-bit hash collisions!"
                    di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
                    if ( "`oncollision'" == "fallback" ) {
                        cap noi collision_handler `0'
                        if ( "`fast'" == "" ) restore, not
                        exit _rc
                    }
                    else exit 42000 
                }
                else if ( _rc != 0 ) exit _rc
            }

            * End timer for plugin time; benchmark just the program exit
            local msg "The plugin executed"
            gtools_timer info 97 `"`msg'"', prints(`benchmark')
        }
    }

    ***********************************************************************
    *                   Keep only relevant observations                   *
    ***********************************************************************

    * Keep only one obs per group; keep only relevant vars
    if ( "`merge'" == "" ) {
        qui {
            if ( `=scalar(__gtools_J) > 0' ) keep in 1 / `:di %21.0g scalar(__gtools_J)'
            else if ( `=scalar(__gtools_J) == 0' ) drop if 1
            else if ( `=scalar(__gtools_J) < 0' ) {
                di as err "The plugin returned a negative number of groups."
                di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
            }
            ds *
        }
        if ( `=_N' == 0 ) di as txt "(no observations)"

        * make sure no extra variables are present
        local memvars  `r(varlist)'
        local keepvars `by' `gtools_targets'
        local dropme   `:list memvars - keepvars'
        * if ( "`dropme'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))
        if ( "`dropme'" != "" ) mata: st_dropvar(tokens(`"`dropme'"'))

        * If we collapsed to disk, read back the data
        if ( (`=_N > 0') & (`=scalar(__gtools_k_extra)' > 0) & ( `used_io' | ("`forceio'" == "forceio") ) ) {
            qui mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
            gtools_timer info 97 `"Added extra targets after collapse"', prints(`benchmark')

            * For debugging, we can choose to read it back using mata or C
            local __gtools_iovars: list gtools_targets - gtools_uniq_vars
            * mata: __gtools_iovars = (`:di subinstr(`""`__gtools_iovars'""', " ", `"", ""', .)')
            mata: __gtools_iovars = tokens(`"`__gtools_iovars'"')
            if ( `debug_io_read_method' == 0 ) {
                cap `noi' `plugin_call' `__gtools_iovars', collapse read `"`__gtools_file'"'
                if ( _rc != 0 ) exit _rc
            }
            else {
                local nrow = `:di %21.0g scalar(__gtools_J)'
                local ncol = `=scalar(__gtools_k_extra)'
                mata: __gtools_data = gtools_get_collapsed (`"`__gtools_file'"', `nrow', `ncol')
                mata: st_store(., __gtools_iovars, __gtools_data)
            }
            gtools_timer info 97 `"Read extra targets from disk"', prints(`benchmark')
        }

        * Order variables if they are not in user-requested order
        local order = 0
        qui ds *
        local varorder `r(varlist)'
        local varsort  `by' `gtools_targets'
        foreach varo in `varorder'  {
            gettoken svar varsort: varsort
            if ("`varo'" != "`vars'") local order = 1
        }
        if ( `order' ) order `by' `gtools_targets'

        * Label the things in the style of collapse
        forvalues k = 1 / `:list sizeof gtools_targets' {
            mata: st_varlabel("`:word `k' of `gtools_targets''", __gtools_labels[`k'])
        }
    }
    else {
        * If merge was requested, only drop temporary variables (all
        * data should stay in memory for merge, since we are mimicing a
        * merge; note, however, that this assumes -update replace-, so
        * collapsing without explicitly naming the target will replace
        * the source).
        local dropvars ""
        if ( `indexed' ) local dropvars `dropvars' `bysmart'
        local dropvars `dropvars'
        * if ( "` dropvars'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropvars'""', " ", `"", ""', .)'))
        if ( "` dropvars'" != "" ) mata: st_dropvar(tokens(`"`dropvars'"'))
    }

    ***********************************************************************
    *                            Program Exit                             *
    ***********************************************************************

    if ( "`fast'" == "" ) restore, not

    * End timer for program exit time; end step timer
    local msg "Program exit executed"
    gtools_timer info 97 `"`msg'"', prints(`benchmark') off

    * End timer for program total time; end total timer
    local msg "The program executed"
    gtools_timer info 98 `"`msg'"', prints(`benchmark') off

    * Clean up after yourself
    * -----------------------

    cap mata: mata drop __gtools_labels
    cap mata: mata drop __gtools_addvars
    cap mata: mata drop __gtools_addtypes
    cap mata: mata drop __gtools_recastvars
    cap mata: mata drop __gtools_recasttypes
    cap mata: mata drop __gtools_recastsrc
    cap mata: mata drop __gtools_iovars
    cap mata: mata drop __gtools_data
    cap mata: mata drop __gtools_checkrecast
    cap mata: mata drop __gtools_norecast
    cap mata: mata drop __gtools_keeprecast
    cap mata: mata drop __gtools_asfloat

    cap mata: mata drop gtools_vars
    cap mata: mata drop gtools_targets
    cap mata: mata drop gtools_stats
    cap mata: mata drop gtools_pos
    cap mata: mata drop gtools_io_order

    cap scalar drop __gtools_l_hashlib
    cap scalar drop __gtools_indexed
    cap scalar drop __gtools_J
    cap scalar drop __gtools_k_uniq_stats
    cap scalar drop __gtools_k_uniq_vars
    cap scalar drop __gtools_k_stats
    cap scalar drop __gtools_k_vars
    cap scalar drop __gtools_k_targets
    cap scalar drop __gtools_l_uniq_stats
    cap scalar drop __gtools_l_uniq_vars
    cap scalar drop __gtools_l_stats
    cap scalar drop __gtools_l_vars
    cap scalar drop __gtools_l_targets
    cap scalar drop __gtools_merge
    cap scalar drop __gtools_benchmark
    cap scalar drop __gtools_verbose
    cap scalar drop __gtools_checkhash
    cap scalar drop __gtools_k_extra
    cap scalar drop __gtools_k_recast
    cap scalar drop __gtools_used_io
    cap scalar drop __gtools_io_thresh
    cap scalar drop __gtools_mib_base
    cap scalar drop __gtools_bench_st
    cap scalar drop __gtools_is_int

    cap matrix drop __gtools_outpos
    cap matrix drop __gtools_strpos
    cap matrix drop __gtools_numpos
    cap matrix drop __gtools_byk
    cap matrix drop __gtools_bymin
    cap matrix drop __gtools_bymax
    cap matrix drop c_gtools_bymiss
    cap matrix drop c_gtools_bymin
    cap matrix drop c_gtools_bymax

    exit 0
end

* Time the things
* ---------------

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
        if ( `prints' ) di `"`msg'`:di trim("`:di %21.4gc r(t`timer')'")' seconds"'
        return scalar t`timer' = `r(t`timer')'
        return local pretty`timer' = trim("`:di %21.4gc r(t`timer')'")
        timer off `timer'
        timer clear `timer'
        timer on `timer'
    }

    if ( "`end'`off'" != "" ) {
        timer off `timer'
        timer clear `timer'
    }
end

* Parse options for the main function
* -----------------------------------

capture program drop parse_opts
program parse_opts, rclass
    syntax,                ///
    [                      ///
        Verbose            /// debugging
        Benchmark          /// print benchmark info
        hashlib(str)       ///
        debug_force_single /// (experimental) Force non-multi-threaded version
        debug_force_multi  /// (experimental) Force muti-threading
        debug_checkhash    /// (experimental) Check for hash collisions
    ]


    * Verbose and benchmark printing
    * ------------------------------

    if ( "`verbose'" == "" ) {
        local verbose = 0
    }
    else {
        local verbose = 1
    }

    if ( "`benchmark'" == "" ) {
        local benchmark = 0
    }
    else {
        local benchmark = 1
    }
    if ( `verbose'  | `benchmark' ) local noi noisily

    * Choose plugin version
    * ---------------------

    cap plugin call gtoolsmulti_plugin, check
    if ( _rc ) {
        if ( `verbose'  ) di as txt "(note: failed to load multi-threaded version; using fallback)"
        local plugin_call plugin call gtools_plugin
        local multi ""
        cap `noi' plugin call gtools_plugin, check
        if ( _rc ) {
            di as err "Failed to load -gtools.plugin-"
            exit 198
        }
    }
    else {
        local plugin_call plugin call gtoolsmulti_plugin
        local multi multi
    }

    * Check if specified single or multi-threading
    * --------------------------------------------

    if ( "`debug_force_multi'" != "" ) {
        di as txt "(warning: forcing multi-threaded version)"
        local multi multi
        local plugin_call plugin call gtoolsmulti_plugin
    }

    if ( "`debug_force_single'" != "" ) {
        di as txt "(warning: forcing non-multi-threaded version)"
        local multi ""
        local plugin_call plugin call gtools_plugin
    }

    * Check hash collisions in C
    * --------------------------

    if ("`debug_checkhash'" == "") {
        local checkhash = 0
    }
    else {
        di as txt "(warning: Code to check for hash collisions is in beta)"
        local checkhash = 1
    }

    return local multi        = "`muti'"
    return local plugin_call  = "`plugin_call'"
    return local verbose      = `verbose'
    return local benchmark    = `benchmark'
    return local checkhash    = `checkhash'
end

* Parse summary stats and by variables
* ------------------------------------

capture program drop parse_vars
program parse_vars, rclass
    syntax [anything(equalok)]  ///
        [if] [in] ,             /// subset
    [                           ///
        by(varlist)             /// collapse by variabes
        cw                      /// case-wise non-missing
        smart(int 0)            /// check if data is sorted to speed up hashing
                                ///
        multi                   ///
        Verbose(int 0)          ///
                                ///
        debug_force_hash        /// Force use of SpookyHash (usually slower)
    ]

    * If data already sorted, create index
    * ------------------------------------

    if ( `smart' ) {
        local sortedby: sortedby
        local indexed = ( `=_N' < 2^31 )
        if ( "`sortedby'" == "" ) {
            * If the data is not sorted, you will have to sort it
            local indexed = 0
        }
        else if ( `: list by == sortedby' ) {
            * If the data is sorted by the by variables, you're in luck
            if ( `verbose' ) di as text "data already sorted; indexing in stata"
        }
        else if ( `: list by === sortedby' ) {
            * If the data is sorted by the by variables but in a different order.
            * The order does not matter for the final groupings (we will sort the
            * collapsed data in the correct order, however).
            * if ( `verbose' ) di as text "data sorted using by variables; indexing in stata"

            * TODO: The theory behind this is sound but it requires some
            * debugging for it to work correctly (since you can't do by `by'
            * because it's not sorted. Debug and implement). // 2017-06-14 15:15 EDT
            local indexed = 0
        }
        else {
            * If the data is sorted by more variables than the by variables
            * check the first K variables (for K by vars) are the same.
            forvalues k = 1 / `:list sizeof by' {
                if ( "`:word `k' of `by''" != "`:word `k' of `sortedby''" ) local indexed = 0
                * di "`:word `k' of `by'' vs `:word `k' of `sortedby''"
            }
            if ( `indexed' ) {
                if ( `verbose' ) di as text "data sorted in similar order (`sortedby'); indexing in stata"
            }
        }

        * If indexed, subset now so when we create the indicator it is correct
        qui if ( `indexed' ) {
            if  ( ("`if'`in'" != "") | ("`cw'" != "") ) {
                marksample touse, strok novarlist
                if ("`cw'" != "") {
                    markout `touse' `by' `gtools_uniq_vars', strok
                }
                keep if `touse'
            }
        }
    }
    else local indexed 0

    * Parse anything
    * --------------

    if ( "`anything'" == "" ) {
        di as err "invalid syntax"
        exit 198
    }
    else {
        ParseList `anything'
    }

    * Variable labels after collapse
    * ------------------------------

    mata: __gtools_labels = J(1, `:list sizeof __gtools_targets', "")
    forvalues k = 1 / `:list sizeof __gtools_targets' {
        local vl = "`:variable label `:word `k' of `__gtools_vars'''"
        local vl = cond("`vl'" == "", "`:word `k' of `__gtools_vars''", "`vl'")
        local vl = "(`:word `k' of `__gtools_stats'') `vl'"
        mata: __gtools_labels[`k'] = "`vl'"
    }

    * Available Stats
    * ---------------

    local stats sum mean sd max min count median iqr percent first last firstnm lastnm

    * Parse quantiles
    local anyquant = 0
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
        local __gtools_stats      " `__gtools_stats' "
        local __gtools_uniq_stats " `__gtools_uniq_stats' "
        local __gtools_stats:      subinstr local __gtools_stats      "`quantile'" "`:di regexs(1)'", all
        local __gtools_uniq_stats: subinstr local __gtools_uniq_stats "`quantile'" "`:di regexs(1)'", all
    }
    local __gtools_stats      `__gtools_stats'
    local __gtools_uniq_stats `__gtools_uniq_stats'

    * Can't collapse grouping variables
    * ---------------------------------

    local intersection: list __gtools_targets & by
    if ("`intersection'" != "") {
        di as error "targets in collapse are also in by(): `intersection'"
        error 110
    }

    * Subset if requested
    * -------------------

    qui if ( (("`if'`in'" != "") | ("`cw'" != "")) & ("`touse'" == "") ) {
        marksample touse, strok novarlist
        if ("`cw'" != "") {
            markout `touse' `by' `gtools_uniq_vars', strok
        }
        keep if `touse'
    }

    * Parse type of each by variable
    * ------------------------------

    cap noi check_matsize `by'
    if ( _rc ) exit _rc

    cap parse_by_types `by', `multi' `debug_force_hash'
    if ( _rc ) exit _rc

    * Locals to be read by C
    * ----------------------

    c_local __gtools_targets    `__gtools_targets'
    c_local __gtools_vars       `__gtools_vars'
    c_local __gtools_stats      `__gtools_stats'
    c_local __gtools_uniq_vars  `__gtools_uniq_vars'
    c_local __gtools_uniq_stats `__gtools_uniq_stats'

    return local indexed = `indexed'
end

* Set up plugin call
* ------------------

capture program drop parse_by_types
program parse_by_types
    syntax varlist, [multi] [debug_force_hash]
    cap matrix drop __gtools_byk
    cap matrix drop __gtools_bymin
    cap matrix drop __gtools_bymax
    cap matrix drop c_gtools_bymiss
    cap matrix drop c_gtools_bymin
    cap matrix drop c_gtools_bymax

    * If any strings, skip integer check
    local kmaybe  = 1
    local usehash = ( "`debug_force_hash'" != "" )
    foreach byvar of varlist `varlist' {
        if regexm("`:type `byvar''", "str") local kmaybe = 0
    }
    if ( `usehash' ) local kmaybe = 0

    * Check whether we only have integers. We also check whether        .
    * floats|doubles are integers in disguise                          .
    local varnum ""
    local knum    = 0
    local khash   = 0
    local intlist ""
    foreach byvar of varlist `varlist' {
        if ( `kmaybe' ) {
            if inlist("`:type `byvar''", "byte", "int", "long") {
                local ++knum
                local varnum `varnum' `byvar'
                local intlist `intlist' 1
            }
            else if inlist("`:type `byvar''", "float", "double") {
                if ( `=_N > 0' ) {
                    cap plugin call gtools`multi'_plugin `byvar', isint
                    if ( _rc ) exit _rc
                }
                else scalar __gtools_is_int = 0
                if ( `=scalar(__gtools_is_int)' ) {
                    local ++knum
                    local varnum `varnum' `byvar'
                    local intlist `intlist' 1
                }
                else {
                    local kmaybe = 0
                    local ++khash
                    local intlist `intlist' 0
                }
            }
            else {
                local kmaybe = 0
                local ++khash
                local intlist `intlist' 0
            }
        }
        else {
            local ++khash
            local intlist `intlist' 0
        }
    }
    else {
        foreach byvar of varlist `varlist' {
            local intlist `intlist' 0
        }
    }

    * If so, set up min and max in C. Later we will check whether we can
    * use a bijection of the by variables to the whole numbers as our
    * index, which is faster than hashing.
    if ( (`knum' > 0) & (`khash' == 0) & (`usehash' == 0) ) {
        matrix c_gtools_bymiss = J(1, `knum', 0)
        matrix c_gtools_bymin  = J(1, `knum', 0)
        matrix c_gtools_bymax  = J(1, `knum', 0)
        if ( `=_N > 0' ) {
            cap plugin call gtools`multi'_plugin `varnum', setup
            if ( _rc ) exit _rc
        }
        matrix __gtools_bymin = c_gtools_bymin
        matrix __gtools_bymax = c_gtools_bymax + c_gtools_bymiss
    }

    * See 'help data_types'; we encode string types as their length,
    * integer types as -1, and other numeric types as 0. Each are
    * handled differently when hashing:
    *     - All integer types: Try to map them to the natural numbers
    *     - All same type: Invoke loop that reads the same type
    *     - A mix of types: Invoke loop that reads a mix of types
    *
    * The loop that reads a mix of types switches from reading strings
    * to reading numeric variables in the order the user specified the
    * by variables, which is necessary for the hash to be consistent.
    * But this version of the loop is marginally slower than the version
    * that reads the same type throughout.
    *
    * Last, we need to know the length of the data to read them into
    * C and hash them. Numeric data are 8 bytes (we will read them
    * as double) and strings are read into a string buffer, which is
    * allocated the length of the longest by string variable.

    foreach byvar of varlist `varlist' {
        gettoken is_int intlist: intlist
        local bytype: type `byvar'
        if ( (`is_int' | inlist("`bytype'", "byte", "int", "long")) & (`usehash' == 0) ) {
            matrix __gtools_byk = nullmat(__gtools_byk), -1
        }
        else {
            matrix __gtools_bymin = J(1, `:list sizeof varlist', 0)
            matrix __gtools_bymax = J(1, `:list sizeof varlist', 0)

            if regexm("`bytype'", "str([1-9][0-9]*|L)") {
                if (regexs(1) == "L") {
                    tempvar strlen
                    gen `strlen' = length(`byvar')
                    qui sum `strlen'
                    matrix __gtools_byk = nullmat(__gtools_byk), `r(max)'
                }
                else {
                    matrix __gtools_byk = nullmat(__gtools_byk), `:di regexs(1)'
                }
            }
            else if inlist("`bytype'", "float", "double") {
                matrix __gtools_byk = nullmat(__gtools_byk), 0
            }
            else if ( inlist("`bytype'", "byte", "int", "long") & `usehash' ) {
                matrix __gtools_byk = nullmat(__gtools_byk), 0
            }
            else {
                di as err "variable `byvar' has unknown type '`bytype''"
            }
        }
    }
end

* Get keep/drop info
* ------------------

capture program drop parse_keep_drop
program parse_keep_drop, rclass
    syntax,                      ///
    [                            ///
        merge                    ///
        double                   ///
        by(varlist)              ///
        bysmart(varlist)         ///
        indexed(int 0)           ///
        Verbose(int 0)           ///
        __gtools_targets(str)    ///
        __gtools_vars(str)       ///
        __gtools_stats(str)      ///
        __gtools_uniq_vars(str)  ///
        __gtools_uniq_stats(str) ///
    ]

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
            parse_ok_astarget, sourcevar(`k_var') targetvar(`k_target') stat(`k_stat') `double'
            if ( `:list k_var in __gtools_uniq_vars' & `r(ok_astarget)' ) {
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

        * slow, but saves mem
        if ( `indexed' ) local keepvars `by' `bysmart' `__gtools_keepvars'
        else local keepvars `by' `__gtools_keepvars'
    }
    else scalar __gtools_merge = 1

    * Variables in memory; will compare to keepvars
    qui ds *
    local memvars `r(varlist)'

    * Unfortunately, this is necessary for C. We cannot create variables
    * from C, and we cannot halt the C execution, create the final data
    * in Stata, and then go back to C.


    * Variables in memory; will compare to keepvars
    * ---------------------------------------------

    qui ds *
    local memvars `r(varlist)'
    local dropme ""
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
        else if ( ("`collstat'" == "sum") | ("`:type `sourcevar''" == "long") ) {
            * Sums are double so we don't overflow, but I don't
            * know why operations on long integers are also double.
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

        * Create target variables as applicable. If it's the first
        * instance, we use it to store the first summary statistic
        * requested for that variable and recast as applicable.
        cap confirm variable `var'
        if ( _rc ) {
            * mata: st_addvar("`targettype'", "`var'", 1)
            mata: __gtools_addvars  = __gtools_addvars,  "`var'"
            mata: __gtools_addtypes = __gtools_addtypes, "`targettype'"
            local added `added' `var'
        }
        else {
            * We only recast integer types. Floats and doubles are
            * preserved unless requested. This portion of the code
            * should only ever appear if we have not specified a target
            * with a different name and the source variable is not the
            * right type. It is usually slow.

            local source_float_double  = inlist("`:type `var''", "float", "double")
            local target_long_int_byte = inlist("`targettype'", "byte", "int", "long")
            local already_double    = inlist("`:type `var''", "double")
            local already_same_type = ("`targettype'" == "`:type `var''")
            local already_higher    = (`source_float_double' & `target_long_int_byte')
            * local recast = !`already_same_type' & ( ("`double'" != "") | !`already_double' )
            local recast = !( `already_same_type' | `already_double' | `already_higher' )

            if ( `recast' ) {
                if ( ("`collstat'" == "sum") & ("`targettype'" == "double") & ("`:type `var''" == "float") ) {
                    local check_recast `check_recast' `var'
                }
                mata: __gtools_recastvars  = __gtools_recastvars,  "`var'"
                mata: __gtools_recasttypes = __gtools_recasttypes, "`targettype'"
            }
        }
    }

    return local dropme       = "`dropme'"
    return local keepvars     = "`keepvars'"
    return local added        = "`added'"
    return local memvars      = "`memvars'"
    return local check_recast = "`check_recast'"
end

* Check if variable is OK to use as target
* ----------------------------------------

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
        local ok_astarget = inlist("`:type `sourcevar''", "long", "float", "double")
    }
    else if ( ("`stat'" == "sum") | ("`:type `sourcevar''" == "long") ) {
        * Sums are double so we don't overflow, but I don't
        * know why operations on long integers are also double.
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
        if ("`targettype'" == "float") {
            local ok_astarget = inlist("`:type `sourcevar''", "float", "double")
        }
        else {
            local ok_astarget = inlist("`:type `sourcevar''", "double")
        }
    }
    return local ok_astarget = `ok_astarget'
end

capture program drop check_matsize
program check_matsize
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

***********************************************************************
*                            mata helpers                             *
***********************************************************************

cap mata: mata drop gtools_get_collapsed()
mata
real matrix function gtools_get_collapsed (string scalar fname, real scalar nrow, real scalar ncol)
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

***********************************************************************
*                         Define the plugins                          *
***********************************************************************

cap program drop env_set
program env_set, plugin using("env_set_`:di lower("`c(os)'")'.plugin")

* Windows hack
if ( "`c(os)'" == "Windows" ) {
    cap confirm file spookyhash.dll
    if ( _rc ) {
        cap findfile spookyhash.dll
        if ( _rc ) {
            local url https://raw.githubusercontent.com/mcaceresb/stata-gtools
            local url `url'/master/spookyhash.dll
            di as err `"gtools: `hashlib'' not found."'
            di as err `"gtools: download {browse "`url'":here} or run {opt gtools, dependencies}"'
            exit _rc
        }
        mata: __gtools_hashpath = ""
        mata: __gtools_dll = ""
        mata: pathsplit(`"`r(fn)'"', __gtools_hashpath, __gtools_dll)
        mata: st_local("__gtools_hashpath", __gtools_hashpath)
        mata: mata drop __gtools_hashpath
        mata: mata drop __gtools_dll
        local path: env PATH
        if inlist(substr(`"`path'"', length(`"`path'"'), 1), ";") {
            mata: st_local("path", substr(`"`path'"', 1, `:length local path' - 1))
        }
        local __gtools_hashpath: subinstr local __gtools_hashpath "/" "\", all
        local newpath `"`path';`__gtools_hashpath'"'
        local truncate 2048
        if ( `:length local newpath' > `truncate' ) {
            local loops = ceil(`:length local newpath' / `truncate')
            mata: __gtools_pathpieces = J(1, `loops', "")
            mata: __gtools_pathcall   = ""
            mata: for(k = 1; k <= `loops'; k++) __gtools_pathpieces[k] = substr(st_local("newpath"), 1 + (k - 1) * `truncate', `truncate')
            mata: for(k = 1; k <= `loops'; k++) __gtools_pathcall = __gtools_pathcall + " `" + `"""' + __gtools_pathpieces[k] + `"""' + "' "
            mata: st_local("pathcall", __gtools_pathcall)
            mata: mata drop __gtools_pathcall __gtools_pathpieces
            cap plugin call env_set, PATH `pathcall'
        }
        else {
            cap plugin call env_set, PATH `"`path';`__gtools_hashpath'"'
        }
        if ( _rc ) {
            cap confirm file spookyhash.dll
            if ( _rc ) {
                cap plugin call env_set, PATH `"`__gtools_hashpath'"'
                if ( _rc ) {
                    di as err `"gtools: Unable to add '`__gtools_hashpath'' to system PATH."'
                    di as err `"gtools: download {browse "`url'":here} or run {opt gtools, dependencies}"'
                    exit _rc
                }
            }
        }
    }
}

* The legacy versions segfault if they are not loaded first (Unix only)
if ( `"`:di lower("`c(os)'")'"' == "unix" ) {
    cap program drop __gtools_plugin
    cap program __gtools_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'_legacy.plugin"')

    cap program drop __gtoolsmulti_plugin
    cap program __gtoolsmulti_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'_multi_legacy.plugin"')

    * But we only want to use them when multi-threading fails normally
    cap program drop gtoolsmulti_plugin
    cap program gtoolsmulti_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'_multi.plugin"')
    if ( _rc ) {
        cap program drop gtools_plugin
        program gtools_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'_legacy.plugin"')

        cap program drop gtoolsmulti_plugin
        cap program gtoolsmulti_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'_multi_legacy.plugin"')
    }
    else {
        cap program drop gtools_plugin
        program gtools_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'.plugin"')
    }
}
else {
    cap program drop gtools_plugin
    program gtools_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'.plugin"')

    cap program drop gtoolsmulti_plugin
    cap program gtoolsmulti_plugin, plugin using(`"gtools_`:di lower("`c(os)'")'_multi.plugin"')
}

* This is very inelegant, but I have debugging fatigue, and this seems to work.

***********************************************************************
*                        Fallback to collapse                         *
***********************************************************************

capture program drop collision_handler
program collision_handler
    syntax [anything(equalok)] [if] [in] , [by(passthru) cw fast *]
    di as txt "Falling back on -collapse-"
    collapse `anything' `if' `in', `by' `cw' `fast'
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
