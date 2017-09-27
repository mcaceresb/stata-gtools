*! version 0.7.1 27Sep2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! implementation of by-able -egen- functions using C for faster processing

/*
 * syntax:
 *     gegen [type] varname = fun(args) [if] [in], [options]
 *     passed to fun are
 *         [type] varname = fun(args) [if] [in], [options]
 */

* Adapted from egen.ado
capture program drop gegen
program define gegen, byable(onecall)
    version 13
    if inlist("`c(os)'", "MacOSX") {
        di as err "Not available for `c(os)'."
        exit 198
    }
    local 00 `0'

    * Time the entire function execution
    {
        cap timer off 98
        cap timer clear 98
        timer on 98
    }

    * Time program setup
    {
        cap timer off 97
        cap timer clear 97
        timer on 97
    }

    * Parse egen call
    * ---------------

    gettoken type 0 : 0, parse(" =(")
    gettoken name 0 : 0, parse(" =(")

    if (`"`name'"' == "=" ) {
        local name `"`type'"'
        local type : set type
    }
    else {
        gettoken eqsign 0 : 0, parse(" =(")
        if ( `"`eqsign'"' != "=" ) {
            error 198
        }
    }

    confirm new variable `name'
    gettoken fcn 0 : 0, parse(" =(")
    gettoken args 0 : 0, parse(" ,") match(par)

    if ( "`fcn'" == "total" ) local fcn sum
    if ( `"`par'"' != "("  ) exit 198

    * TODO: Figure this out // 2017-05-19 18:00 EDT
    * if ( (`"`args'"' == "_all" ) | (`"`args'"' == "*") ) {
    *     unab args : _all
    *     local args : subinstr local args "`_sortindex'"  "", all word
    * }


    * Available functions
    local funcs tag      ///
                group    ///
                total    ///
                sum      ///
                mean     ///
                sd       ///
                max      ///
                min      ///
                count    ///
                median   ///
                iqr      ///
                percent  ///
                first    ///
                last     ///
                firstnm  ///
                lastnm   ///
                pctile

    if !( `:list fcn in funcs' ) {
        di as err "-gegen `fcn'- not supported."
        exit 198
    }

    * Parse egen by, if, in, and options
    * ----------------------------------

    syntax                       /// main call; must parse manually
        [if] [in] ,              /// subset
    [                            ///
        by(varlist)              /// collapse by variabes
                                 ///
        p(real 50)               /// percentiles (only used with pctile)
                                 ///
        missing                  /// for group(); treats
                                 ///
        Verbose                  /// debugging
        Benchmark                /// print benchmark info
        smart                    /// check if data is sorted to speed up hashing
        hashlib(str)             /// path to hash library (Windows only)
                                 ///
        debug_force_single       /// (experimental) Force non-multi-threaded version
        debug_force_multi        /// (experimental) Force muti-threading
        debug_checkhash          /// (experimental) Check for hash collisions
        oncollision(str)         /// (experimental) On collision, fall back to collapse or throw error
    ]

    * Misc options
    * ------------

    local website_url  https://github.com/mcaceresb/stata-gtools/issues
    local website_disp github.com/mcaceresb/stata-gtools

    if ( "`oncollision'" == "" ) local oncollision fallback
    if ( !inlist("`oncollision'", "fallback", "error") ) {
        di as err "option -oncollision()- must be 'fallback' or 'error'"
        exit 198
    }

    if ( "`missing'" == "" ) {
        scalar __gtools_missing = 0
    }
    else {
        if !inlist("`fcn'", "tag", "group", "total") {
            di as err "Option {opt missing} not allowed"
            exit 198
        }
        scalar __gtools_missing = 1
    }

    * Verbose and benchmark printing
    * ------------------------------

    if ("`verbose'" == "") {
        local verbose = 0
        scalar __gtools_verbose = 0
    }
    else {
        local verbose = 1
        scalar __gtools_verbose = 1
    }

    if ("`benchmark'" == "") {
        local benchmark = 0
        scalar __gtools_benchmark = 0
    }
    else {
        local benchmark = 1
        scalar __gtools_benchmark = 1
    }
    if ( `verbose'  | `benchmark' ) local noi noisily

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
                    exit _rc
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

    * Check plugin loads
    * ------------------

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
        scalar __gtools_checkhash = 0
    }
    else {
        local checkhash = 1
        scalar __gtools_checkhash = 1
    }

    * Parse quantiles
    * ---------------

    if ( "`fcn'" == "pctile" ) {
        local quantbad = !( (`p' < 100) & (`p' > 0) )
        if ( `quantbad' ) {
            di as error "Invalid quantile: `p'; p() should be in (0, 100)"
            error 110
        }
        * local fcn p`p'
        local fcn `p'
    }
    else if ( `p' != 50  ) {
        di as err "Option {opt p()} not allowed"
        exit 198
    }

    * Parse variable(s)
    * -----------------

    tempvar dummy
    cap qui ds `args'
    if ( _rc == 0 ) {
        local gtools_vars `r(varlist)'
    }
    else {
        tempvar exp
        cap gen `type' `exp' = `args'
        if ( _rc ) {
            di as error "Invalid call; please specify {opth `fcn'(varlist)} or {opth `fcn'(exp)}."
            exit 198
        }
        local gtools_vars `exp'
    }
    local gtools_targets `dummy'
    local gtools_stats   `fcn'

    * Tag and group are handled sepparately
    if inlist("`fcn'", "tag", "group") local by `gtools_vars'

    * Parse by call
    * -------------

    if ( _by() ) local by `_byvars'
    if ( "`by'" == "" ) {
        * if inlist("`fcn'", "tag", "group") {
            tempvar byvar
            gen byte `byvar' = 0
            local by `byvar'
        * }
        * else {
        *     di as err "-gegen- only provides support for by-able egen functions"
        *     exit 198
        * }
    }
    else {
        qui ds `by'
        local by `r(varlist)'
    }

    * Parse missing option for group; else just pass `if' `in'
    * --------------------------------------------------------

    if ( inlist("`fcn'", "group", "tag") ) {
		if ( "`missing'" == "" ) {
            marksample touse
            markout `touse' `by', strok
            local sub if `touse' `in'
        }
        else local sub `if' `in'
    }
    else local sub `if' `in'

    * If data already sorted, create index
    * ------------------------------------

    local bysmart ""
    if ( "`smart'" != "" ) {
        local sortedby: sortedby
        local indexed = (`=_N' < 2^31)
        if ( "`sortedby'" == "" ) {
            local indexed = 0
        }
        else if ( `: list by == sortedby' ) {
            if (`verbose') di as text "data already sorted; indexing in stata"
        }
        else if ( `:list by === sortedby' ) {
            local byorig `by'
            local by `sortedby'
            if ( `verbose' & `indexed' ) di as text "data sorted in similar order (`sortedby'); indexing in stata"
        }
        else {
            forvalues k = 1 / `:list sizeof by' {
                if ("`:word `k' of `by''" != "`:word `k' of `sortedby''") local indexed = 0
                di "`:word `k' of `by'' vs `:word `k' of `sortedby''"
            }
        }

        if ( `indexed' ) {
            if inlist("`fcn'", "tag", "group") local restrict `sub'
            tempvar bysmart
            qui by `by': gen long `bysmart' = (_n == 1) `restrict'
            if ( "`fcn'" == "tag" ) {
                qui count if missing(`bysmart')
                if ( `r(N)' ) {
                    local s = cond(r(N) > 1, "s", "")
                    di in bl "(" r(N) " missing value`s' generated)"
                }
                rename `bysmart' `name'
                exit 0
            }
            if ( "`fcn'" == "group" ) {
                qui replace `bysmart' = sum(`bysmart')
                qui count if missing(`bysmart')
                if ( `r(N)' ) {
                    local s = cond(r(N) > 1, "s", "")
                    di in bl "(" r(N) " missing value`s' generated)"
                }
                rename `bysmart' `name'
                exit 0
            }
        }
    }
    else local indexed 0

    * Info for C
    * ----------

    scalar __gtools_l_stats = length("`gtools_stats'")
    scalar __gtools_k_vars  = `:list sizeof gtools_vars'

    * Get a list with all string by variables
    local bystr ""
    qui foreach byvar of varlist `by' {
        local bytype: type `byvar'
        if regexm("`bytype'", "str([1-9][0-9]*|L)") {
            local bystr `bystr' `byvar'
        }
    }

    * Parse type of each by variable
    cap parse_by_types `by', `multi'
    if ( _rc ) exit _rc
    scalar __gtools_merge = 1

    * Add dummy variable; will rename to target variable
    qui mata: st_addvar("`type'", "`dummy'")

    * Position of string variables
    cap matrix drop __gtools_strpos
    foreach var of local bystr {
        matrix __gtools_strpos = nullmat(__gtools_strpos), `:list posof `"`var'"' in by'
    }

    * Position of numeric variables
    cap matrix drop __gtools_numpos
    local bynum `:list by - bystr'
    foreach var of local bynum {
        matrix __gtools_numpos = nullmat(__gtools_numpos), `:list posof `"`var'"' in by'
    }

    * If benchmark, output program setup time
    {
        timer off 97
        qui timer list
        if ( `benchmark' ) di "Program set up executed in `:di trim("`:di %21.4gc r(t97)'")' seconds"
        timer off 97
        timer clear 97
    }

    * Run the plugin
    * --------------

    * Time just the plugin
    {
        cap timer off 99
        cap timer clear 99
        timer on 99
    }

    local plugvars `by' `gtools_vars' `gtools_targets' `bysmart'
    scalar __gtools_indexed = cond(`indexed', `:list sizeof plugvars', 0)
    if ( `=_N > 0' ) {
        cap `noi' `plugin_call' `plugvars' `sub', egen `fcn'
        if ( _rc == 42000 ) {
            di as err "There may be 128-bit hash collisions!"
            di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
            if ( "`oncollision'" == "fallback" ) {
                cap noi collision_handler `00'
                exit _rc
            }
            else exit 42000 
        }
        else if ( _rc == 42001 ) {
            di as txt "(no observations)"
            if ( "`fcn'" == "tag" ) qui replace `dummy' = 0
        }
        else if ( _rc != 0 ) exit _rc
    }

    * If benchmark, output pugin time
    {
        timer off 99
        qui timer list
        if ( `benchmark' ) di "The plugin executed in `:di trim("`:di %21.4gc r(t99)'")' seconds"
        timer off 99
        timer clear 99
    }

    * Time program exit
    {
        cap timer off 97
        cap timer clear 97
        timer on 97
    }

    * if ( "`fcn'" == "tag" ) qui replace `dummy' = 0 if mi(`dummy')
    quietly count if missing(`dummy')
    if ( `r(N)' ) {
        local s = cond(r(N) > 1, "s", "")
        di in bl "(" r(N) " missing value`s' generated)"
    }
    rename `dummy' `name'

    * If benchmark, output program ending time
    {
        timer off 97
        qui timer list
        if ( `benchmark' ) di "Program exit executed in `:di trim("`:di %21.4gc r(t97)'")' seconds"
        timer off 97
        timer clear 97
    }

    * If benchmark, output function time
    {
        timer off 98
        qui timer list
        if ( `benchmark' ) di "The program executed in `:di trim("`:di %21.4gc r(t98)'")' seconds"
        timer off 98
        timer clear 98
    }

    * Clean up after yourself
    * -----------------------

    cap scalar drop __gtools_l_hashlib
    cap scalar drop __gtools_indexed
    cap scalar drop __gtools_l_stats
    cap scalar drop __gtools_benchmark
    cap scalar drop __gtools_verbose
    cap scalar drop __gtools_checkhash

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

    * If so, set up min and max in C
    if ( (`knum' > 0) & (`khash' == 0) ) {
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

    * See help data_types
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

* Load plugins
* ------------

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
    syntax [anything(equalok)]   ///
        [if] [in] ,              ///
    [                            ///
        Verbose                  ///
        Benchmark                ///
        smart                    ///
        hashlib(str)             ///
                                 ///
        debug_force_single       ///
        debug_force_multi        ///
        debug_checkhash          ///
        oncollision(str)         ///
        *                        ///
    ]
    di as txt "Falling back on -egen-"
    egen `anything' `if' `in', `options'
end
