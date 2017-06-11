*! version 0.5.0 10Jun2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -collapse- implementation using C for faster processing

capture program drop gcollapse
program gcollapse
    version 13
    syntax [anything(equalok)]        /// main call; must parse manually
        [if] [in] ,                   /// subset
    [                                 ///
        by(varlist)                   /// collapse by variabes
        cw                            /// case-wise non-missing
        fast                          /// do not preserve/restore
        Verbose                       /// debugging
        Benchmark                     /// print benchmark info
        smart                         /// check if data is sorted to speed up hashing
        unsorted                      /// do not sort final output (current implementation of final
                                      /// sort is super slow bc it uses Stata)
        double                        /// Do all operations in double precision
        merge                         /// Merge statistics back to original data, replacing where applicable
                                      ///
        debug_force_single            /// (experimental) Force non-multi-threaded version
        debug_force_multi             /// (experimental) Force muti-threading
        debug_checkhash               /// (experimental) Check for hash collisions
        debug_read_method(int 0)      /// (experimental) Choose a method for reading data from Stata
        debug_collapse_method(int 0)  /// (experimental) Choose a method for collapsing the data
        debug_io_check(real 1e6)      /// (experimental) Threshold to check for I/O speed gains
        debug_io_threshold(int 100)   /// (experimental) Threshold to switch to I/O instead of RAM
    ]
    if !inlist("`c(os)'", "Unix") di as err "Not available for `c(os)`, only Unix."

    ***********************************************************************
    *                       Parsing syntax options                        *
    ***********************************************************************

    if ( ("`merge'" != "") & ("`if'" != "") ) {
        di as err "combining -merge- with -if- is currently buggy; a fix is planned v0.5.1"
        exit 198
    }

    * Parse options (no variable manupulation)
    parse_opts, `verbose' `benchmark'                          ///
                `debug_force_single'                           ///
                `debug_force_multi'                            ///
                `debug_checkhash'                              ///
                debug_read_method(`debug_read_method')         ///
                debug_collapse_method(`debug_collapse_method') ///
                                                                //

    local multi       = "`r(muti)'"
    local plugin_call = "`r(plugin_call)'"
    local verbose     = `r(verbose)'
    local benchmark   = `r(benchmark)'
    local checkhash   = `r(checkhash)'

    scalar __gtools_verbose   = `verbose'
    scalar __gtools_benchmark = `benchmark'
    scalar __gtools_checkhash = `checkhash'
    scalar __gtools_collapse_method = `r(collapse_method)'
    scalar __gtools_read_method     = `r(read_method)'

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

    * Parse the things
    parse_vars `anything' `if' `in', by(`by') `cw' smart(`smart') v(`verbose') `multi'
    local indexed = `r(indexed)'
    if ( `indexed' ) {
        tempvar bysmart
        by `by': gen long `bysmart' = (_n == 1)
    }

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

    local dropme   = "`r(dropme)'"
    local keepvars = "`r(keepvars)'"
    local added    = "`r(added)'"
    local memvars  = "`r(memvars)'"

    * This is not, strictly speaking, necessary, but I have yet to
    * figure out how to handle strings in C efficiently; will improve on
    * a future release.
    local bystr_orig  ""
    local bystr       ""
    qui foreach byvar of varlist `by' {
        local bytype: type `byvar'
        if regexm("`bytype'", "str([1-9][0-9]*|L)") {
            tempvar `byvar'
            * mata: st_addvar("`bytype'", "``byvar''", 1)
            mata: __gtools_addvars  = __gtools_addvars,  "``byvar''"
            mata: __gtools_addtypes = __gtools_addtypes, "`bytype'"
            local bystr `bystr' ``byvar''
            local bystr_orig `bystr_orig' `byvar'
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

    * Position of input to each target variable (note C has 0-based indexing)
    cap matrix drop __gtools_outpos
    foreach var of local gtools_vars {
        matrix __gtools_outpos = nullmat(__gtools_outpos), (`:list posof `"`var'"' in gtools_uniq_vars' - 1)
    }

    * Position of string variables (the position in the variable list
    * passed to C has 1-based indexing, however)
    cap matrix drop __gtools_strpos
    foreach var of local bystr_orig {
        matrix __gtools_strpos = nullmat(__gtools_strpos), `:list posof `"`var'"' in by'
    }

    * Position of numeric variables (ibid.)
    cap matrix drop __gtools_numpos
    local bynum `:list by - bystr_orig'
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

    * Use I/O instead of memory for results (faster for J small)
    * ----------------------------------------------------------

*     if 0 & ( `=_N' > `debug_io_check' ) {
*         mata: st_addvar(("double", "double"), ("index", "info"), 1)
*         local MiB = trim("`:di %15.2gc `=_N * 8 * 2' / 1024 / 1024'")
*         gtools_timer info 97 `"Added 2 8-byte variables (approx `MiB'MiB)"', prints(`benchmark')
*         local rate_stata = `=8 * 2 * _N / `r(t97)''
*
*         `plugin_call' `by' index info, index
*         local rate_c = 1024 * 1024 / `=scalar(__gtools_bench_c)'
*
*         mata: st_numscalar("kadd", cols(__gtools_addvars))
*         local time_c     = `=scalar(kadd) * scalar(__gtools_J) * 8 / ( `rate_c' + `rate_stata')'
*         local time_stata = `=scalar(kadd) * _N * 8 / rate_stata'
*
*         if ( `time_c' * threshold < `time_stata' )
*         tempfile __gtools_collapsed_file
*         cap `noi' `plugin_call' `plugvars', collapse write `__gtools_collapsed_file'
*
*         keep in 1 / `:di scalar(__gtools_J)'
*         mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
*         order `by' `gtools_targets'
*         set obs `:di scalar(__gtools_J)'
*         cap `noi' `plugin_call' `by' `gtools_targets', read `__gtools_collapsed_file'
*
*         local time_c     = `=scalar(kadd) * scalar(__gtools_J) * 8 / ( `rate_c' + `rate_stata')'
*         local time_stata = `=scalar(kadd) * _N * 8 / rate_stata'
*     }

    * Drop superfluous variables; generate target variables
    * -----------------------------------------------------

    {
        if ( "`merge'"  == "" ) local dropme `dropme' `:list memvars - keepvars'
        if ( ("`added'" != "") | ("`bystr'"  != "") ) {
            mata: st_numscalar("krecast", cols(__gtools_recastvars))
            mata: __gtools_recastsrc  = J(1, 0, "")
            forvalues k = 1 / `=scalar(krecast)' {
                mata: st_local("var", __gtools_recastvars[`k'])
                tempvar dropvar
                rename `var' `dropvar'
                local dropme `dropme' `dropvar'
                mata: __gtools_recastsrc = __gtools_recastsrc, "`dropvar'"
            }
            qui mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
            qui forvalues k = 1 / `=scalar(krecast)' {
                mata: st_local("var",     __gtools_recastvars[`k'])
                mata: st_local("dropvar", __gtools_recastsrc[`k'])
                replace `var' = `dropvar'
            }
        }
        if ( "`dropme'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))
        ds *
    }
    if ( `verbose' ) di as text "In memory: `r(varlist)'"

    * Timers!
    * -------

    * End timer for keep/drop; benchmark plugin
    local msg "Parsed by variables, sources, and targets"
    gtools_timer info 97 `"`msg'"', prints(`benchmark')

    ***********************************************************************
    *          Run the plugin; sort the data after if applicable          *
    ***********************************************************************

    * Run the plugin:
    *    - The variables are passed after being parsed above; order is VERY important
    *    - J will contain how many obs to keep
    *    - nstr contains # of string grouping vars
    *    - indexed notes whether the data is already sorted
    local plugvars `by' `gtools_uniq_vars' `gtools_targets' `bystr' `bysmart'
    scalar __gtools_J    = `=_N'
    scalar __gtools_nstr = `:list sizeof bystr'
    scalar __gtools_indexed = cond(`indexed', `:list sizeof plugvars', 0)

    cap `noi' `plugin_call' `plugvars', collapse
    if ( _rc != 0 ) exit _rc

    * End timer for plugin time; benchmark just the program exit
    local msg "The plugin executed"
    gtools_timer info 97 `"`msg'"', prints(`benchmark')

    * Keep only one obs per group; keep only relevant vars
    qui if ( "`merge'" == "" ) {
        keep in 1 / `:di scalar(__gtools_J)'
        qui ds *
        local memvars  `r(varlist)'
        local keepvars `by' `gtools_targets'
        local dropme   `:list memvars - keepvars'
        if ( "`dropme'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))

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

        * This is really slow; implement in C
        if ( "`unsorted'" == "" ) sort `by'
    }
    else {
        local dropvars ""
        if ( "`bystr'" != "" ) local dropvars `dropvars' `bystr'
        if ( `indexed' )       local dropvars `dropvars' `bysmart'
        local dropvars = trim("`dropvars'")
        if ( "` dropvars'" != "" ) mata: st_dropvar((`:di subinstr(`""`dropvars'""', " ", `"", ""', .)'))
    }

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
    cap mata: mata drop __gtools_recastsrc

    cap scalar drop __gtools_indexed
    cap scalar drop __gtools_nstr
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
    cap scalar drop __gtools_read_method
    cap scalar drop __gtools_collapse_method

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
        return local t`timer'      = `r(t`timer')'
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
    syntax,                          ///
    [                                ///
        Verbose                      /// debugging
        Benchmark                    /// print benchmark info
        debug_force_single           /// (experimental) Force non-multi-threaded version
        debug_force_multi            /// (experimental) Force muti-threading
        debug_checkhash              /// (experimental) Check for hash collisions
        debug_read_method(int 0)     /// (experimental) Choose a method for reading data from Stata
        debug_collapse_method(int 0) /// (experimental) Choose a method for collapsing the data
    ]


    * Verbose and benchmark printing
    * ------------------------------

    if ("`verbose'" == "") {
        local verbose = 0
    }
    else {
        local verbose = 1
    }

    if ("`benchmark'" == "") {
        local benchmark = 0
    }
    else {
        local benchmark = 1
    }
    if ( `verbose'  | `benchmark' ) local noi noisily

    * Choose plugin version
    * ---------------------

    cap `noi' plugin call gtoolsmulti_plugin, check
    if ( _rc ) {
        if ( `verbose'  ) di "(note: failed to load multi-threaded version; using fallback)"
        local plugin_call plugin call gtools_plugin
        local multi ""
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
        local debug_read_method     = 3
        local debug_collapse_method = 2
        local plugin_call plugin call gtoolsmulti_plugin
    }

    if ( "`debug_force_single'" != "" ) {
        di as txt "(warning: forcing non-multi-threaded version)"
        local multi ""
        * local debug_read_method = 1
        local debug_collapse_method = 1
        local plugin_call plugin call gtools_plugin
    }

    * Parse reading method
    * --------------------

    if !inlist(`debug_read_method', 0, 1, 2, 3) {
        di as err "data copying method #`debug_read_method' unknown; available: 1 (sequential), 2 (grouped), 3 (parallel)"
        exit 198
    }
    else if ( `debug_read_method' != 0 ) {
        di as text "(warning: custom reading methods in beta)"
        if ( ("`multi'" == "") & !inlist(`debug_read_method', 1, 2) ) {
            di as err "data copying method #`debug_read_method' unknown; available: 1 (sequential), 2 (grouped)"
            exit 198
        }
        if ( ("`multi'" != "") & !inlist(`debug_read_method', 1, 3) ) {
            di as err "data copying method #`debug_read_method' unknown; available: 1 (sequential), 3 (parallel)"
            exit 198
        }
    }

    * Parse collapse method
    * ---------------------

    if !inlist(`debug_collapse_method', 0, 1, 2) {
        di as err "data collapse method #`debug_collapse_method' unknown; available: 1 (sequential), 2 (parallel)"
        exit 198
    }
    else if ( `debug_collapse_method' != 0 ) {
        di as text "(warning: custom collapsing methods in beta)"
        if ( "`multi'" == "" ) {
            di "(note: data collapsing method only available for option -multi-)"
        }
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

    return local multi           = "`muti'"
    return local plugin_call     = "`plugin_call'"
    return local verbose         = `verbose'
    return local benchmark       = `benchmark'
    return local checkhash       = `checkhash'
    return local read_method     = `debug_read_method'
    return local collapse_method = `debug_collapse_method'
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
    ]

    * If data already sorted, create index
    * ------------------------------------

    if ( `smart' ) {
        local sortedby: sortedby
        local indexed = ( `=_N' < 2^31 )
        if ( "`sortedby'" == "" ) {
            local indexed = 0
        }
        else if ( `: list by == sortedby' ) {
            if ( `verbose' ) di as text "data already sorted; indexing in stata"
        }
        else {
            forvalues k = 1 / `:list sizeof by' {
                if ( "`:word `k' of `by''" != "`:word `k' of `sortedby''" ) local indexed = 0
                * di "`:word `k' of `by'' vs `:word `k' of `sortedby''"
            }
            if ( `indexed' ) {
                if ( `verbose' ) di as text "data sorted in similar order (`sortedby'); indexing in stata"
            }
        }

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
        local __gtools_stats      = subinstr(" `__gtools_stats' ",       "`quantile'", regexs(1), .)
        local __gtools_uniq_stats = subinstr(" `__gtools_uniq_stats' ",  "`quantile'", regexs(1), .)
    }
    local __gtools_stats      = trim("`__gtools_stats'")
    local __gtools_uniq_stats = trim("`__gtools_uniq_stats'")

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

    cap parse_by_types `by', `multi'
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
    syntax varlist, [multi]
    cap matrix drop __gtools_byk
    cap matrix drop __gtools_bymin
    cap matrix drop __gtools_bymax
    cap matrix drop c_gtools_bymiss
    cap matrix drop c_gtools_bymin
    cap matrix drop c_gtools_bymax

    * Check whether we only have integers
    local varnum ""
    local knum  = 0
    local khash = 0
    foreach byvar of varlist `varlist' {
        if inlist("`:type `byvar''", "byte", "int", "long") {
            local ++knum
            local varnum `varnum' `byvar'
        }
        else local ++khash
    }

    * If so, set up min and max in C. Later we will check whether we can
    * use a bijection of the by variables to the whole numbers as our
    * index, which is faster than hashing.
    if ( (`knum' > 0) & (`khash' == 0) ) {
        matrix c_gtools_bymiss = J(1, `knum', 0)
        matrix c_gtools_bymin  = J(1, `knum', 0)
        matrix c_gtools_bymax  = J(1, `knum', 0)
        cap plugin call gtools`multi'_plugin `varnum', setup
        if ( _rc ) exit _rc
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
        local bytype: type `byvar'
        if inlist("`bytype'", "byte", "int", "long") {
            * qui count if mi(`byvar')
            * local addmax = (`r(N)' > 0)
            * qui sum `byvar'
            * matrix __gtools_bymin = nullmat(__gtools_bymin), `r(min)'
            * matrix __gtools_bymax = nullmat(__gtools_bymax), `r(max)' + `addmax'
            matrix __gtools_byk   = nullmat(__gtools_byk), -1
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

        local __gtools_vars      = subinstr(" `__gtools_vars' ",      " ", "  ", .)
        local __gtools_uniq_vars = subinstr(" `__gtools_uniq_vars' ", " ", "  ", .)
        local __gtools_keepvars  = subinstr(" `__gtools_keepvars' ",  " ", "  ", .)
        local K = `:list sizeof __gtools_targets'
        forvalues k = 1 / `K' {
            local k_target: word `k' of `__gtools_targets'
            local k_var:    word `k' of `__gtools_vars'
            local k_stat:   word `k' of `__gtools_stats'
            * Only use as target if the type matches
            parse_ok_astarget, sourcevar(`k_var') targetvar(`k_target') stat(`k_stat') `double'
            if ( `:list k_var in __gtools_uniq_vars' & `r(ok_astarget)' ) {
                local __gtools_uniq_vars: list __gtools_uniq_vars - k_var
                if ( !`:list k_var in __gtools_targets' ) {
                    local __gtools_vars      = trim(subinstr(" `__gtools_vars' ",      " `k_var' ", " `k_target' ", .))
                    local __gtools_uniq_vars = trim(subinstr(" `__gtools_uniq_vars' ", " `k_var' ", " `k_target' ", .))
                    local __gtools_keepvars  = trim(subinstr(" `__gtools_keepvars'  ", " `k_var' ", " `k_target' ", .))
                    rename `k_var' `k_target'
                }
            }
        }
        local __gtools_vars      = trim(subinstr(" `__gtools_vars' ",      "  ", " ", .))
        local __gtools_uniq_vars = trim(subinstr(" `__gtools_uniq_vars' ", "  ", " ", .))
        local __gtools_keepvars  = trim(subinstr(" `__gtools_keepvars' ",  "  ", " ", .))

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

    local dropme ""
    local added  ""

    mata: __gtools_addvars    = J(1, 0, "")
    mata: __gtools_addtypes   = J(1, 0, "")
    mata: __gtools_recastvars = J(1, 0, "")

    c_local __gtools_vars      `__gtools_vars'
    c_local __gtools_uniq_vars `__gtools_keepvars'

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
                if ( `verbose' ) di as text "    `var' will be recast as `targettype'"
                mata: __gtools_addvars    = __gtools_addvars,    "`var'"
                mata: __gtools_addtypes   = __gtools_addtypes,   "`targettype'"
                mata: __gtools_recastvars = __gtools_recastvars, "`var'"
            }
        }
    }

    return local dropme   = "`dropme'"
    return local keepvars = "`keepvars'"
    return local added    = "`added'"
    return local memvars  = "`memvars'"
end

* Check if variable is OK to use as target
* ----------------------------------------

capture program drop parse_ok_astarget
program parse_ok_astarget, rclass
    syntax, sourcevar(varlist) targetvar(str) stat(str) [double]
    local ok_astarget = 0
    local sourcetype = "`:type `sourcevar''"

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

***********************************************************************
*                         Define the plugins                          *
***********************************************************************

cap program drop gtools_plugin
if inlist("`c(os)'", "Unix") program gtools_plugin, plugin using("gtools.plugin")

cap program drop gtoolsmulti_plugin
if inlist("`c(os)'", "Unix") cap program gtoolsmulti_plugin, plugin using("gtools_multi.plugin")

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
    local 0 = trim("`0'")

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
