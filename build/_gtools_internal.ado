*! version 0.1.4 29Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Encode varlist using Jenkin's 128-bit spookyhash via C plugins

capture program drop _gtools_internal
program _gtools_internal, rclass
    version 13

    if ( inlist("${GTOOLS_FORCE_PARALLEL}", "17900") ) {
        di as txt "(note: multi-threading is not available on this platform)"
    }

    local GTOOLS_CALLER $GTOOLS_CALLER
    local GTOOLS_CALLERS gegen glevelsof gisid hashsort gunique gcollapse
    if ( !(`:list GTOOLS_CALLER in GTOOLS_CALLERS') ) {
        di as err "_gtools_internal is not meant to be called directly. See {help gtools}"
        exit 198
    }

    if ( `=_N < 1' ) {
        di as err "no observations"
        exit 17001
    }

    local 00 `0'

    * Time the entire function execution
    gtools_timer on 99
    gtools_timer on 98

    ***********************************************************************
    *                           Syntax parsing                            *
    ***********************************************************************

    syntax [anything] [if] [in] , ///
    [                             ///
        Verbose                   /// debugging
        Benchmark                 /// print benchmark info
        hashlib(str)              /// path to hash library (Windows only)
        oncollision(str)          /// On collision, fall back or throw error
        gfunction(str)            /// Program to handle collision
        replace                   /// When writing to a variable directly from C,
                                  /// specify the variable can exist
                                  ///
                                  /// General options
                                  /// ---------------
                                  ///
        seecount                  /// print group info to console
        COUNTonly                 /// report group info and exit
        MISSing                   /// Include missing values
        unsorted                  /// Do not sort hash values; faster
        countmiss                 /// count # missing in output (only w/certain targets)
                                  ///
                                  /// Generic stats options
                                  /// ---------------------
                                  ///
        sources(str)              /// varlist must exist
        targets(str)              /// varlist must exist
        stats(str)                /// stats (one per target; if multiple targets
        freq(str)                 /// also collapse frequencies to variable
                                  /// then # targets must = # sources)
                                  ///
                                  /// gcollapse options
                                  /// -----------------
                                  ///
        gcollapse(str)            /// String for later parsing
        recast(str)               /// bulk recast
                                  ///
                                  /// gegen group options
                                  /// -------------------
                                  ///
        tag(str)                  /// 1 for first obs of group in range, 0 otherwise
        gen(str)                  /// variable where to store encoded index
        counts(str)               /// variable where to store group counts
        fill(str)                 /// for counts(); group fill order or value
                                  ///
                                  /// gisid options
                                  /// -------------
                                  ///
        EXITMissing               /// Throw error if there are any missing values.
                                  ///
                                  /// hashsort options
                                  /// ----------------
                                  ///
        sortindex(str)            /// keep sort index in memory
        sortgroup                 /// set sort by group variable
                                  ///
                                  /// glevelsof options
                                  /// -----------------
                                  ///
        Separate(str)             /// Levels sepparator
        COLSeparate(str)          /// Columns sepparator
        Clean                     /// Clean strings
    ]

    local ifin `if' `in'

    * Check you will find the hash library (Windows only)
    * ---------------------------------------------------

    if ( "`hashlib'" == "" ) {
        local hashlib `c(sysdir_plus)'s/spookyhash.dll
        local hashusr 0
    }
    else local hashusr 1
    if ( ("`c_os_'" == "windows") & `hashusr' ) {
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
                    clean_all
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
                local rc = _rc
                di as err "Unable to add '`__gtools_hashpath'' to system PATH."
                clean_all
                exit `rc'
            }
        }
        else local hashlib spookyhash.dll
    }

    ***********************************************************************
    *                             Bulk recast                             *
    ***********************************************************************

    if ( "`recast'" != "" ) {
        local 0  , `recast'
        syntax, sources(varlist) targets(varlist)
        if ( `:list sizeof sources' != `:list sizeof targets' ) {
            di as err "Must specify the same number of sources and targets"
            exit 198
        }
        scalar __gtools_k_recast = `:list sizeof sources'
        cap noi plugin call gtools_plugin `targets' `sources', recast
        local rc = _rc
        cap scalar drop __gtools_k_recast
        exit `rc'
    }

    ***********************************************************************
    *                    Execute the function normally                    *
    ***********************************************************************

    * What to do
    * ----------

    local gfunction_list hash egen levelsof isid sort unique collapse
    if ( "`gfunction'" == "" ) local gfunction hash
    if ( !(`:list gfunction in gfunction_list') ) {
        di as err "{opt gfunction()} was '`gfunction'' but expected one of: `gfunction_list'"
        clean_all
        exit 198
    }

    * Switches, options
    * -----------------

    local website_url  https://github.com/mcaceresb/stata-gtools/issues
    local website_disp github.com/mcaceresb/stata-gtools

    if ( "`oncollision'" == "" ) local oncollision fallback
    if ( !inlist("`oncollision'", "fallback", "error") ) {
        di as err "option -oncollision()- must be 'fallback' or 'error'"
        clean_all
        exit 198
    }

    * Check options compatibility
    * ---------------------------

    * Not true; need not be set with option -detail-.  This option is only for
    * speed so it's fine to rely on gunique.

    * if ( inlist("`gfunction'", "unique") ) {
    *     if ( "`countonly'" == "" ) {
    *         di as txt "(-gfunction(unique)- sets option -countonly- automatically)"
    *         local countonly countonly
    *     }
    * }

    if ( inlist("`gfunction'", "isid", "unique") ) {
        if ( "`unsorted'" == "" ) {
            di as txt "(-gfunction(`gfunction')- sets option -unsorted- automatically)"
            local unsorted unsorted
        }
    }

    if ( inlist("`gfunction'", "isid") ) {
        if ( "`exitmissing'`missing'" == "" ) {
            di as err "-gfunction(`gfunction')- must set either -exitmissing- or -missing-"
            clean_all
            exit 198
        }
    }

    if ( inlist("`gfunction'", "sort") ) {
        if ( "`if'" != "" ) {
            di as err "Cannot sort data with if condition"
            clean_all
            exit 198
        }
        if ( "`exitmissing'" != "" ) {
            di as err "Cannot specify -exitmissing- with -gfunction(sort)-"
            clean_all
            exit 198
        }
        if ( "`missing'" == "" ) {
            di as txt "(-gfunction(`gfunction')- sets option -missing- automatically)"
            local missing missing
        }
        if ( "`unsorted'" != "" ) {
            di as err "Cannot specify -unsorted- with -gfunction(sort)-"
            clean_all
            exit 198
        }
    }

    if ( ("`exitmissing'" != "") & ("`missing'" != "") ) {
        di as err "Cannot specify -exitmissing- with option -missing-"
        clean_all
        exit 198
    }

    if ( "`sortindex'" != "" ) {
        if ( !inlist("`gfunction'", "sort") ) {
            di as err "sort index only allowed with -gfunction(sort)-"
            clean_all
            exit 198
        }
    }

    if ( "`counts'`gen'`tag'" != "" ) {
        if ( "`countonly'" != "" ) {
            di as err "cannot generate targets with option -countonly-"
            clean_all
            exit 198
        }
        if ( !inlist("`gfunction'", "hash", "egen", "unique", "sort", "levelsof") ) {
            di as err "cannot generate targets with -gfunction(`gfunction')-"
            clean_all
            exit 198
        }
        if ( ("`gen'" == "") & !inlist("`gfunction'", "sort", "levelsof") ) {
            if ( "`unsorted'" == "" ) {
                di as txt "(-tag- and -counts- without -gen- sets option -unsorted- automatically)"
                local unsorted unsorted
            }
        }
    }

    if ( "`sources'`targets'`stats'" != "" ) {
        if ( !inlist("`gfunction'", "hash", "egen", "collapse") ) {
            di as err "cannot generate targets with -gfunction(`gfunction')-"
            clean_all
            exit 198
        }
    }

    if ( "`fill'" != "" ) {
        if ( "`counts'`targets'" == "" ) {
            di as err "{opt fill()} only allowed with {opth counts(newvarname)}"
            clean_all
            exit 198
        }
    }

    if ( "`separate'`colseparate'`clean'" != "" ) {
        local errmsg ""
        if ( "`separate'"    != "" ) local errmsg "`errmsg' separate(),"
        if ( "`colseparate'" != "" ) local errmsg "`errmsg' colseparate(), "
        if ( "`clean'"       != "" ) local errmsg "`errmsg' -clean-, "
        if ( !inlist("`gfunction'", "levelsof") ) {
            di as err "`errmsg' only allowed with -gfunction(levelsof)-"
            clean_all
            exit 198
        }
    }

    * Parse options into scalars, etc. for C
    * --------------------------------------

    local any_if    = ( "if'"        != "" )
    local verbose   = ( "`verbose'"   != "" )
    local benchmark = ( "`benchmark'" != "" )

    scalar __gtools_init_targ  = 0
    scalar __gtools_any_if     = `any_if'
    scalar __gtools_verbose    = `verbose'
    scalar __gtools_benchmark  = `benchmark'
    scalar __gtools_missing    = ( "`missing'"     != "" )
    scalar __gtools_unsorted   = ( "`unsorted'"    != "" )
    scalar __gtools_countonly  = ( "`countonly'"   != "" )
    scalar __gtools_seecount   = ( "`seecount'"    != "" )
    scalar __gtools_nomiss     = ( "`exitmissing'" != "" )
    scalar __gtools_replace    = ( "`replace'"     != "" )
    scalar __gtools_countmiss  = ( "`countmiss'"   != "" )

    * Parse glevelsof options
    * -----------------------

    if ( `"`separate'"' == "" ) local sep `" "'
	else local sep `"`separate'"'

    if ( `"`colseparate'"' == "" ) local colsep `"|"'
	else local colsep `"`colseparate'"'

    scalar __gtools_cleanstr   = ( "`clean'" != "" )
    scalar __gtools_sep_len    = length(`"`sep'"')
    scalar __gtools_colsep_len = length(`"`colsep'"')

    * Parse target names and group fill
    * ---------------------------------

    * confirm new variable `gen_name'
    * local 0 `gen_name'
    * syntax newvarname

    if ( "`tag'" != "" ) {
        gettoken tag_type tag_name: tag
        local tag_name `tag_name'
        local tag_type `tag_type'
        if ( "`tag_name'" == "" ) {
            local tag_name `tag_type'
            local tag_type byte
        }
        cap noi confirm_var `tag_name', `replace'
        if ( _rc ) exit _rc
        local new_tag = `r(newvar)'
    }

    if ( "`gen'" != "" ) {
        gettoken gen_type gen_name: gen
        local gen_name `gen_name'
        local gen_type `gen_type'
        if ( "`gen_name'" == "" ) {
            local gen_name `gen_type'
            if (`=_N' < 2^31) {
                local gen_type long
            }
            else {
                local gen_type double
            }
        }
        cap noi confirm_var `gen_name', `replace'
        if ( _rc ) exit _rc
        local new_gen = `r(newvar)'
    }

    scalar __gtools_group_data = 0
    scalar __gtools_group_fill = 0
    scalar __gtools_group_val  = .
    if ( "`counts'" != "" ) {
        {
            gettoken counts_type counts_name: counts
            local counts_name `counts_name'
            local counts_type `counts_type'
            if ( "`counts_name'" == "" ) {
                local counts_name `counts_type'
                if (`=_N' < 2^31) {
                    local counts_type long
                }
                else {
                    local counts_type double
                }
            }
            cap noi confirm_var `counts_name', `replace'
            if ( _rc ) exit _rc
            local new_counts = `r(newvar)'
        }
        if ( "`fill'" != "" ) {
            if ( "`fill'" == "group" ) {
                scalar __gtools_group_fill = 0
                scalar __gtools_group_val  = .
            }
            else if ( "`fill'" == "data" ) {
                scalar __gtools_group_data = 1
                scalar __gtools_group_fill = 0
                scalar __gtools_group_val  = .
            }
            else {
                cap confirm number `fill'
                cap local fill_value = `fill'
                if ( _rc ) {
                    di as error "'`fill'' found where number expected"
                    exit 7
                }
                * local 0 , fill(`fill')
                * syntax , [fill(real 0)]
                scalar __gtools_group_fill = 1
                scalar __gtools_group_val  = `fill'
            }
        }
    }
    else if ( "`targets'" != "" ) {
        if ( "`fill'" != "" ) {
            if ( "`fill'" == "missing" ) {
                scalar __gtools_group_fill = 1
                scalar __gtools_group_val  = .
            }
            else if ( "`fill'" == "data" ) {
                scalar __gtools_group_data = 1
                scalar __gtools_group_fill = 0
                scalar __gtools_group_val  = .
            }
        }
    }
    else if ( "`fill'" != "" ) {
        di as err "-fill- only allowed with option -count()- or -targets()-"
        clean_all
        exit 198
    }

    * Generate new variables
    * ----------------------

    local kvars_group = 0
    scalar __gtools_encode = 1
    mata:  __gtools_group_targets = J(1, 3, 0)
    mata:  __gtools_group_init    = J(1, 3, 0)

    if ( "`counts'`gen'`tag'" != "" ) {
        local topos 1
        local etargets `gen_name' `counts_name' `tag_name'
        mata: __gtools_togen_types = J(1, `:list sizeof etargets', "")
        mata: __gtools_togen_names = J(1, `:list sizeof etargets', "")

        * 111 = 8
        * 101 = 6
        * 011 = 7
        * 001 = 5
        * 110 = 4
        * 010 = 3
        * 100 = 2
        * 000 = 1

        if ( "`gen'" != "" ) {
            local ++kvars_group
            scalar __gtools_encode = __gtools_encode + 1
            if ( `new_gen' ) {
                mata: __gtools_togen_types[`topos'] = "`gen_type'"
                mata: __gtools_togen_names[`topos'] = "`gen_name'"
                local ++topos
            }
            else {
                mata:  __gtools_group_init[1] = 1
            }
            mata: __gtools_group_targets = J(1, 3, 1)
        }

        if ( "`counts'" != "" ) {
            local ++kvars_group
            scalar __gtools_encode = __gtools_encode + 2
            if ( `new_counts' ) {
                mata: __gtools_togen_types[`topos'] = "`counts_type'"
                mata: __gtools_togen_names[`topos'] = "`counts_name'"
                local ++topos
            }
            else {
                mata:  __gtools_group_init[2] = 1
            }
            mata: __gtools_group_targets[2] = __gtools_group_targets[2] + 1
            mata: __gtools_group_targets[3] = __gtools_group_targets[3] + 1
        }
        else {
            mata: __gtools_group_targets[2] = 0
        }

        if ( "`tag'" != "" ) {
            local ++kvars_group
            scalar __gtools_encode = __gtools_encode + 4
            if ( `new_tag' ) {
                mata: __gtools_togen_types[`topos'] = "`tag_type'"
                mata: __gtools_togen_names[`topos'] = "`tag_name'"
                local ++topos
            }
            else {
                mata:  __gtools_group_init[3] = 1
            }
            mata: __gtools_group_targets[3] = __gtools_group_targets[3] + 1
        }
        else {
            mata: __gtools_group_targets[3] = 0
        }

        qui mata: __gtools_togen_k = sum(__gtools_togen_names :!= missingof(__gtools_togen_names))
        qui mata: __gtools_togen_s = 1::((__gtools_togen_k > 0)? __gtools_togen_k: 1)
        qui mata: (__gtools_togen_k > 0)? st_addvar(__gtools_togen_types[__gtools_togen_s], __gtools_togen_names[__gtools_togen_s]): ""

        cap mata: mata drop __gtools_togen_types
        cap mata: mata drop __gtools_togen_names
        cap mata: mata drop __gtools_togen_k
        cap mata: mata drop __gtools_togen_s

        local msg "Generated targets"
        gtools_timer info 98 `"`msg'"', prints(`benchmark')
    }
    else local etargets ""

    scalar __gtools_k_group = `kvars_group'
    mata: st_matrix("__gtools_group_targets", __gtools_group_targets)
    mata: st_matrix("__gtools_group_init",    __gtools_group_init)
    mata: mata drop __gtools_group_targets
    mata: mata drop __gtools_group_init

    * Parse by types
    * --------------

    if ( "`anything'" != "" ) {
        local clean_anything `anything'
        local clean_anything: subinstr local clean_anything "+" "", all
        local clean_anything: subinstr local clean_anything "-" "", all
        local clean_anything `clean_anything'
        cap ds `clean_anything'
        if ( _rc | ("`clean_anything'" == "") ) {
            local rc = _rc
            di as err "Malformed call: '`anything''"
            di as err "Syntas: [+|-]varname [[+|-]varname ...]"
            clean_all
            exit 111
        }
        local clean_anything `r(varlist)'
        cap noi check_matsize `clean_anything'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }
    }

    cap noi parse_by_types `anything' `ifin'
    if ( _rc ) {
        local rc = _rc
        clean_all
        exit `rc'
    }

    local invert = `r(invert)'
    local byvars = "`r(varlist)'"
    local bynum  = "`r(varnum)'"
    local bystr  = "`r(varstr)'"

    if ( "`byvars'" != "" ) {
        cap noi check_matsize `byvars'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }
    }

    if ( "`targets'" != "" ) {
        cap noi check_matsize `targets'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }
    }

    if ( "`sources'" != "" ) {
        cap noi check_matsize `sources'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }
    }

    if ( inlist("`gfunction'", "levelsof") & ("`byvars'" == "") ) {
        di as err "gfunction(`gfunction') requires at least one variable."
        clean_all
        exit 198
    }

    * Parse position of by variables
    * ------------------------------

    if ( "`byvars'" != "" ) {
        cap matrix drop __gtools_strpos
        cap matrix drop __gtools_numpos

        foreach var of local bystr {
            matrix __gtools_strpos = nullmat(__gtools_strpos), ///
                                    `:list posof `"`var'"' in byvars'
        }

        foreach var of local bynum {
            matrix __gtools_numpos = nullmat(__gtools_numpos), ///
                                     `:list posof `"`var'"' in byvars'
        }
    }
    else {
        matrix __gtools_strpos = 0
        matrix __gtools_numpos = 0
    }

    local msg "Parsed by variables"
    gtools_timer info 98 `"`msg'"', prints(`benchmark')

    * Parse sources, targets, stats (sources and targets MUST exist!)
    * ---------------------------------------------------------------

    matrix __gtools_stats        = 0
    matrix __gtools_pos_targets  = 0
    scalar __gtools_k_vars       = 0
    scalar __gtools_k_targets    = 0
    scalar __gtools_k_stats      = 0

    if ( "`sources'`targets'`stats'" != "" ) {
        if ( "`gfunction'" == "collapse" ) {
            if regexm("`gcollapse'", "^(forceio|switch)") {
                local k_exist k_exist(sources)
            }
            if regexm("`gcollapse'", "^read") {
                local k_exist k_exist(targets)
            }
        }

        parse_targets, sources(`sources') targets(`targets') stats(`stats') `k_exist'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }

        if ( "`freq'" != "" ) {
            cap confirm variable `freq'
            if ( _rc ) {
                di as err "Target `freq' has to exist."
                exit 198
            }

            cap confirm numeric variable `freq'
            if ( _rc ) {
                di as err "Target `freq' must be numeric."
                exit 198
            }

            scalar __gtools_k_targets    = __gtools_k_targets + 1
            scalar __gtools_k_stats      = __gtools_k_stats   + 1
            matrix __gtools_stats        = __gtools_stats,        -14
            matrix __gtools_pos_targets  = __gtools_pos_targets,  0
        }

        local intersection: list __gtools_targets & byvars
        if ( "`intersection'" != "" ) {
            if ( "`replace'" == "" ) {
                di as error "targets in are also in by(): `intersection'"
                error 110
            }
        }

        local extravars `__gtools_sources' `__gtools_targets' `freq'
    }
    else local extravars ""

    ***********************************************************************
    *                           Call the plugin                           *
    ***********************************************************************

    local opts oncollision(`oncollision')
    if ( "`gfunction'" == "sort" ) {

        * Andrew Mauer's trick? From ftools
        * ---------------------------------

        local contained 0
        local sortvar : sortedby
        forvalues k = 1 / `:list sizeof byvars' {
            if ( "`:word `k' of `byvars''" == "`:word `k' of `sortvar''" ) local ++contained
        }
        * di "`contained'"

        * Check if already sorted
        if ( !`invert' & ("`sortvar'" == "`byvars'") ) {
            if ( "`verbose'" != "" ) di as txt "(already sorted; did not parse group info)"
            clean_all
            exit 0
        }
        else if ( !`invert' & (`contained' == `:list sizeof byvars') ) {
            * If the first k sorted variables equal byvars, just call sort
            if ( "`verbose'" != "" ) di as txt "(already sorted; did not parse group info)"
            sort `byvars'
            clean_all
            exit 0
        }
        else if ( "`sortvar'" != "" ) {
            * Andrew Maurer's trick to clear `: sortedby'
            loc sortvar : word 1 of `sortvar'
            loc val = `sortvar'[1]
            cap replace `sortvar' = 0         in 1
            cap replace `sortvar' = .         in 1
            cap replace `sortvar' = ""        in 1
            cap replace `sortvar' = "."       in 1
            cap replace `sortvar' = `val'     in 1
            cap replace `sortvar' = `"`val'"' in 1
            assert "`: sortedby'" == ""
        }

        * Use sortindex for the shuffle
        * -----------------------------

        cap noi hashsort_inner `byvars' `etargets', benchmark(`benchmark')
        cap noi rc_dispatch `byvars', rc(`=_rc') `opts'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }

        if ( "`gen_name'" == "" ) {
            if ( !`invert' ) sort `byvars'
        }
        else {
            sort `gen_name'
        }

        local msg "Stata reshuffle"
        gtools_timer info 98 `"`msg'"', prints(`benchmark') off

        if ( `=_N' < 2^31 ) {
            local stype long
        }
        else {
            stype double
        }
        if ( "`sortindex'" != "" ) gen `stype' `sortindex' = _n
    }
    else if ( "`gfunction'" == "collapse" ) {
        local 0 `gcollapse'
        syntax anything, [st_time(real 0) fname(str) ixinfo(str) merge]
        scalar __gtools_st_time   = `st_time'
        scalar __gtools_used_io   = 0
        scalar __gtools_ixfinish  = 0
        scalar __gtools_J         = _N
        scalar __gtools_init_targ = ( "`ifin'" != "" ) & ("`merge'" != "")

        if inlist("`anything'", "forceio", "switch") {
            local extravars `__gtools_sources' `__gtools_sources' `freq'
        }
        if inlist("`anything'", "read") {
            local extravars `: list __gtools_targets - __gtools_sources' `freq'
        }

        local plugvars `byvars' `etargets' `extravars' `ixinfo'
        cap noi plugin call gtools_plugin `plugvars' `ifin', collapse `anything' `"`fname'"'
        cap noi rc_dispatch `byvars', rc(`=_rc') `opts'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }

        if ( "`anything'" != "read" ) {
            scalar __gtools_J  = `r_J'
            return scalar N    = `r_N'
            return scalar J    = `r_J'
            return scalar minJ = `r_minJ'
            return scalar maxJ = `r_maxJ'
        }

        if ( `=scalar(__gtools_ixfinish)' ) {
            local msg "Switch code runtime"
            gtools_timer info 98 `"`msg'"', prints(`benchmark')

            qui mata: st_addvar(__gtools_addtypes, __gtools_addvars, 1)
            local msg "Added targets"
            gtools_timer info 98 `"`msg'"', prints(`benchmark')

            local extravars `__gtools_sources' `__gtools_targets' `freq'
            local plugvars `byvars' `etargets' `extravars' `ixinfo'
            cap noi plugin call gtools_plugin `plugvars' `ifin', collapse ixfinish `"`fname'"'
            if ( _rc ) {
                local rc = _rc
                clean_all
                exit `rc'
            }

            local msg "Finished collapse"
            gtools_timer info 98 `"`msg'"', prints(`benchmark') off
        }
        else {
            local msg "Plugin runtime"
            gtools_timer info 98 `"`msg'"', prints(`benchmark') off
        }

        return scalar used_io = `=scalar(__gtools_used_io)'
        local runtxt " (internals)"
    }
    else {
        if ( inlist("`gfunction'",  "unique", "egen") ) {
            local gcall hash
        }
        else local gcall `gfunction'

        cap noi plugin call gtools_plugin `byvars' `etargets' `extravars' `ifin', `gcall'
        cap noi rc_dispatch `byvars', rc(`=_rc') `opts'
        if ( _rc ) {
            local rc = _rc
            clean_all
            exit `rc'
        }

        local msg "Plugin runtime"
        gtools_timer info 98 `"`msg'"', prints(`benchmark') off
    }

    local msg "Total runtime`runtxt'"
    gtools_timer info 99 `"`msg'"', prints(`benchmark') off

    * Return values
    * -------------

    * generic
    if ( "`gfunction'" != "collapse" ) {
        return scalar N    = `r_N'
        return scalar J    = `r_J'
        return scalar minJ = `r_minJ'
        return scalar maxJ = `r_maxJ'
    }

    * levelsof
    if ( "`gfunction'" == "levelsof" ) {
        return local levels `"`vals'"'
    }

    clean_all
    exit 0
end

***********************************************************************
*                              hashsort                               *
***********************************************************************

capture program drop hashsort_inner
program hashsort_inner, sortpreserve
    syntax varlist [in], benchmark(int)
    cap noi plugin call gtools_plugin `varlist' `_sortindex' `in', hashsort
    if ( _rc ) {
        local rc = _rc
        clean_all
        exit `rc'
    }
    mata: st_store(., "`_sortindex'", invorder(st_data(., "`_sortindex'")))

    c_local r_N    = `r_N'
    c_local r_J    = `r_J'
    c_local r_minJ = `r_minJ'
    c_local r_maxJ = `r_maxJ'

    local msg "Plugin runtime"
    gtools_timer info 98 `"`msg'"', prints(`benchmark')
end

***********************************************************************
*                               Cleanup                               *
***********************************************************************

capture program drop clean_all
program clean_all
    cap scalar drop __gtools_init_targ
    cap scalar drop __gtools_any_if
    cap scalar drop __gtools_verbose
    cap scalar drop __gtools_benchmark
    cap scalar drop __gtools_countonly
    cap scalar drop __gtools_seecount
    cap matrix drop __gtools_unsorted
    cap scalar drop __gtools_nomiss
    cap scalar drop __gtools_missing
    cap scalar drop __gtools_hash
    cap scalar drop __gtools_encode
    cap scalar drop __gtools_replace
    cap scalar drop __gtools_countmiss

    cap scalar drop __gtools_kvars
    cap scalar drop __gtools_kvars_num
    cap scalar drop __gtools_kvars_int
    cap scalar drop __gtools_kvars_str

    cap scalar drop __gtools_group_data
    cap scalar drop __gtools_group_fill
    cap scalar drop __gtools_group_val

    cap scalar drop __gtools_cleanstr
    cap scalar drop __gtools_sep_len
    cap scalar drop __gtools_colsep_len

    cap scalar drop __gtools_k_vars
    cap scalar drop __gtools_k_targets
    cap scalar drop __gtools_k_stats
    cap scalar drop __gtools_k_group

    cap scalar drop __gtools_st_time
    cap scalar drop __gtools_used_io
    cap scalar drop __gtools_ixfinish
    cap scalar drop __gtools_J

    cap matrix drop __gtools_invert
    cap matrix drop __gtools_bylens
    cap matrix drop __gtools_numpos
    cap matrix drop __gtools_strpos

    cap matrix drop __gtools_group_targets
    cap matrix drop __gtools_group_init

    cap matrix drop __gtools_stats
    cap matrix drop __gtools_pos_targets

    cap timer off   99
    cap timer clear 99

    cap timer off   98
    cap timer clear 98
end

***********************************************************************
*                           Parse by types                            *
***********************************************************************

capture program drop parse_by_types
program parse_by_types, rclass
    syntax [anything] [if] [in]

    if ( "`anything'" == "" ) {
        matrix __gtools_invert = 0
        matrix __gtools_bylens = 0

        scalar __gtools_kvars     = 0
        scalar __gtools_kvars_int = 0
        scalar __gtools_kvars_num = 0
        scalar __gtools_kvars_str = 0

        return local invert  = 0
        return local varlist = ""
        return local varnum  = ""
        return local varstr  = ""

        exit 0
    }

    cap matrix drop __gtools_invert
    cap matrix drop __gtools_bylens

    * Parse whether to invert sort order
    * ----------------------------------

    local parse    `anything'
    local varlist  ""
    local skip   = 0
    local invert = 0
    while ( trim("`parse'") != "" ) {
        gettoken var parse: parse, p(" -+")
        if inlist("`var'", "-", "+") {
            matrix __gtools_invert = nullmat(__gtools_invert), ( "`var'" == "-" )
            local skip   = 1
            local invert = ( "`var'" == "-" )
        }
        else {
            cap ds `var'
            if ( _rc ) {
                local rc = _rc
                di as err "Variable '`var'' does not exist."
                di as err "Syntas: [+|-]varname [[+|-]varname ...]"
                clean_all
                exit `rc'
            }
            if ( `skip' ) {
                local skip = 0
            }
            else {
                matrix __gtools_invert = nullmat(__gtools_invert), 0
            }
            local varlist `varlist' `r(varlist)'
        }
    }

    * Check how many of each variable type we have
    * --------------------------------------------

    local kint  = 0
    local knum  = 0
    local kstr  = 0
    local kvars = 0

    local varint ""
    local varnum ""
    local varstr ""

    if ( "`varlist'" != "" ) {
        cap confirm variable `varlist'
        if ( _rc ) {
            di as err "{opt varlist} requried but received: `varlist'"
            exit 198
        }

        foreach byvar of varlist `varlist' {
            local ++kvars
            if inlist("`:type `byvar''", "byte", "int", "long") {
                local ++kint
                local ++knum
                local varint `varint' `byvar'
                local varnum `varnum' `byvar'
                matrix __gtools_bylens = nullmat(__gtools_bylens), 0
            }
            else if inlist("`:type `byvar''", "float", "double") {
                local ++knum
                local varnum `varnum' `byvar'
                matrix __gtools_bylens = nullmat(__gtools_bylens), 0
            }
            else {
                local ++kstr
                local varstr `varstr' `byvar'
                if regexm("`:type `byvar''", "str([1-9][0-9]*|L)") {
                    if (regexs(1) == "L") {
                        tempvar strlen
                        gen long `strlen' = length(`byvar')
                        qui sum `strlen', meanonly
                        matrix __gtools_bylens = nullmat(__gtools_bylens), `r(max)'
                    }
                    else {
                        matrix __gtools_bylens = nullmat(__gtools_bylens), `:di regexs(1)'
                    }
                }
                else {
                    di as err "variable `byvar' has unknown type '`:type `byvar'''"
                    exit 198
                }
            }
        }

        cap assert `kvars' == `:list sizeof varlist'
        if ( _rc ) {
            di as err "Error parsing syntax call; variable list was:" _n(1) "`anything'"
            exit 198
        }
    }

    * Parse which hashing strategy to use
    * -----------------------------------

    scalar __gtools_kvars     = `kvars'
    scalar __gtools_kvars_int = `kint'
    scalar __gtools_kvars_num = `knum'
    scalar __gtools_kvars_str = `kstr'
    scalar __gtools_biject    = 0

    * Return hash info
    * ----------------

    return local invert     = `invert'
    return local varlist    = "`varlist'"
    return local varnum     = "`varnum'"
    return local varstr     = "`varstr'"
end

***********************************************************************
*                        Generic hash helpers                         *
***********************************************************************

capture program drop confirm_var
program confirm_var, rclass
    syntax anything, [replace]
    local newvar = 1
    if ( "`replace'" != "" ) {
        cap confirm new variable `anything'
        if ( _rc ) {
            local newvar = 0
        }
        else {
            cap noi confirm name `anything'
            if ( _rc ) {
                local rc = _rc
                clean_all
                exit `rc'
            }
        }
    }
    else {
        cap confirm new variable `anything'
        if ( _rc ) {
            local rc = _rc
            clean_all
            cap noi confirm name `anything'
            if ( _rc ) {
                exit `rc'
            }
            else {
                di as err "Variable `anything' exists; try a different name or run with -replace-"
                exit `rc'
            }
        }
    }
    return scalar newvar = `newvar'
    exit 0
end

capture program drop rc_dispatch
program rc_dispatch
    syntax [varlist], rc(int) oncollision(str)

    local website_url  https://github.com/mcaceresb/stata-gtools/issues
    local website_disp github.com/mcaceresb/stata-gtools

    if ( `rc' == 17000 ) {
        di as err "There may be 128-bit hash collisions!"
        di as err `"This is a bug. Please report to {browse "`website_url'":`website_disp'}"'
        if ( "`oncollision'" == "fallback" ) {
            exit 17999
        }
        else {
            exit 17000
        }
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        exit 17001
    }
    else if ( `rc' == 459 ) {
		local kvars : word count `varlist'
        local s = cond(`kvars' == 1, "", "s")
        di as err "variable`s' `varlist' should never be missing"
        exit 459
    }
    else if ( `rc' == 17459 ) {
		local kvars : word count `varlist'
		local var  = cond(`kvars'==1, "variable", "variables")
		local does = cond(`kvars'==1, "does", "do")
		di as err "`var' `varlist' `does' not uniquely identify the observations"
        exit 459
    }
    else exit 0
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

capture program drop parse_targets
program parse_targets
    syntax, sources(str) targets(str) stats(str) [replace k_exist(str)]
    local k_vars    = `:list sizeof sources'
    local k_targets = `:list sizeof targets'
    local k_stats   = `:list sizeof stats'

    local uniq_sources: list uniq sources
    local uniq_targets: list uniq targets

    cap assert `k_targets' == `k_stats'
    if ( _rc ) {
        di as err " `k_targets' target(s) require(s) `k_targets' stat(s), but user passed `k_stats'"
        exit 198
    }

    if ( `k_targets' > 1 ) {
        cap assert `k_targets' == `k_vars'
        if ( _rc ) {
            di as err " `k_targets' targets require `k_targets' sources, but user passed `k_vars'"
            exit 198
        }
    }
    else if ( `k_targets' == 1 ) {
        cap assert `k_vars' > 0
        if ( _rc ) {
            di as err "Specify at least one source variable"
            exit 198
        }
        cap assert `:list sizeof uniq_sources' == `k_vars'
        if ( _rc ) {
            di as txt "(warning: repeat sources ignored with 1 target)"
        }
    }
    else {
        di as err "Specify at least one target"
        exit 198
    }

    local stats: subinstr local stats "total" "sum", all
    local allowed sum        ///
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

    cap assert `:list sizeof uniq_targets' == `k_targets'
    if ( _rc ) {
        di as err "Cannot specify multiple targets with the same name."
        exit 198
    }

    if ( "`k_exist'" != "targets" ) {
        foreach var of local uniq_sources {
            cap confirm variable `var'
            if ( _rc ) {
                di as err "Source `var' has to exist."
                exit 198
            }

            cap confirm numeric variable `var'
            if ( _rc ) {
                di as err "Source `var' must be numeric."
                exit 198
            }
        }
    }

    mata: __gtools_stats       = J(1, `k_stats',   .)
    mata: __gtools_pos_targets = J(1, `k_targets', 0)

    cap noi check_matsize `targets'
    if ( _rc ) exit _rc

    forvalues k = 1 / `k_targets' {
        local src: word `k' of `sources'
        local trg: word `k' of `targets'
        local st:  word `k' of `stats'

        if ( `:list st in allowed' ) {
            encode_stat `st'
            mata: __gtools_stats[`k'] = `r(statcode)'
        }
        else if regexm("`st'", "^p([0-9][0-9]?(\.[0-9]+)?)$") {
            if ( `:di regexs(1)' == 0 ) {
                di as error "Invalid stat: (`st'; maybe you meant 'min'?)"
                exit 110
            }
            mata: __gtools_stats[`k'] = `:di regexs(1)'
        }
        else if ( "`st'" == "p100" ) {
            di as error "Invalid stat: (`st'; maybe you meant 'max'?)"
            exit 110
        }
        else {
            di as error "Invalid stat: `st'"
            exit 110
        }

        if ( "`k_exist'" != "sources" ) {
            cap confirm variable `trg'
            if ( _rc ) {
                di as err "Target `trg' has to exist."
                exit 198
            }

            cap confirm numeric variable `trg'
            if ( _rc ) {
                di as err "Target `trg' must be numeric."
                exit 198
            }
        }

        mata: __gtools_pos_targets[`k'] = `:list posof `"`src'"' in uniq_sources' - 1
    }

    scalar __gtools_k_vars    = `:list sizeof uniq_sources'
    scalar __gtools_k_targets = `k_targets'
    scalar __gtools_k_stats   = `k_stats'

    c_local __gtools_sources `uniq_sources'
    c_local __gtools_targets `targets'

    mata: st_matrix("__gtools_stats",       __gtools_stats)
    mata: st_matrix("__gtools_pos_targets", __gtools_pos_targets)

    cap mata: mata drop __gtools_stats
    cap mata: mata drop __gtools_pos_targets
end

capture program drop encode_stat
program encode_stat, rclass
    if ( "`0'" == "sum"         ) local statcode -1
    if ( "`0'" == "mean"        ) local statcode -2
    if ( "`0'" == "sd"          ) local statcode -3
    if ( "`0'" == "max"         ) local statcode -4
    if ( "`0'" == "min"         ) local statcode -5
    if ( "`0'" == "count"       ) local statcode -6
    if ( "`0'" == "percent"     ) local statcode -7
    if ( "`0'" == "median"      ) local statcode 50
    if ( "`0'" == "iqr"         ) local statcode -9
    if ( "`0'" == "first"       ) local statcode -10
    if ( "`0'" == "firstnm"     ) local statcode -11
    if ( "`0'" == "last"        ) local statcode -12
    if ( "`0'" == "lastnm"      ) local statcode -13
    if ( "`0'" == "semean"      ) local statcode -15
    if ( "`0'" == "sebinomial"  ) local statcode -16
    if ( "`0'" == "sepoisson"   ) local statcode -17
    return scalar statcode = `statcode'
end

***********************************************************************
*                             Load plugin                             *
***********************************************************************

if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) local c_os_ macosx
else local c_os_: di lower("`c(os)'")

cap program drop env_set
program env_set, plugin using("env_set_`c_os_'.plugin")

* Windows hack
if ( "`c_os_'" == "windows" ) {
    cap confirm file spookyhash.dll
    if ( _rc ) {
        cap findfile spookyhash.dll
        if ( _rc ) {
            local rc = _rc
            local url https://raw.githubusercontent.com/mcaceresb/stata-gtools
            local url `url'/master/spookyhash.dll
            di as err `"gtools: `hashlib' not found."' _n(1) ///
                      `"gtools: download {browse "`url'":here} or run {opt gtools, dependencies}"'
            exit `rc'
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
                    local rc = _rc
                    di as err `"gtools: Unable to add '`__gtools_hashpath'' to system PATH."' _n(1) ///
                              `"gtools: download {browse "`url'":here} or run {opt gtools, dependencies}"'
                    exit `rc'
                }
            }
        }
    }
}

cap program drop gtools_plugin
if ( inlist("${GTOOLS_FORCE_PARALLEL}", "1") ) {
    cap program gtools_plugin, plugin using("gtools_`c_os_'_multi.plugin")
    if ( _rc ) {
        global GTOOLS_FORCE_PARALLEL 17900
        program gtools_plugin, plugin using("gtools_`c_os_'.plugin")
    }
}
else program gtools_plugin, plugin using("gtools_`c_os_'.plugin")
