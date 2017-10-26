*! version 0.8.1 26Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! implementation -egen- using C for faster processing

/*
 * syntax:
 *     gegen [type] varname = fun(args) [if] [in], [options]
 *     passed to fun are
 *         [type] varname = fun(args) [if] [in], [options]
 */

/*
 * stata's egen does not parse types correctly.  If the requested result is a
 * sum, stata will happily create a double, despite the risk of overflow.  If
 * the source variable is a double, stata will create a float, even though
 * that might cause a loss in precision. I do not imitate this behavior
 * because I consider it flawed. I upgrade types whenever necessary.
 *
 */

/*
 * TODO: implement label, lname, and truncate for group
 */

capture program drop gegen
program define gegen, byable(onecall) rclass
    version 13

    local 00 `0'
    syntax anything(equalok) [if] [in], [by(str) *]
    local byvars `by'
    local 0 `00'

    * Parse egen call
    * ---------------

    gettoken type 0 : 0, parse(" =(")
    gettoken name 0 : 0, parse(" =(")

    if ( `"`name'"' == "=" ) {
        local name  `"`type'"'
        local type  : set type
        local retype = 1
        local btype double
    }
    else {
        gettoken eqsign 0 : 0, parse(" =(")
        if ( `"`eqsign'"' != "=" ) {
            error 198
        }
        local btype `type'
        local retype = 0
    }

    confirm name `name'
    gettoken fcn  0: 0, parse(" =(")
    gettoken args 0: 0, parse(" ,") match(par)

    if ( "`fcn'"   == "total" ) local fcn sum
    if ( "`fcn'"   == "sem"   ) local fcn semean
    if ( "`fcn'"   == "seb"   ) local fcn sebinomial
    if ( "`fcn'"   == "sep"   ) local fcn sepoisson
    if ( `"`par'"' != "("     ) exit 198
    if ( "`fcn'"   == "sum"   ) local type `btype'

    * Parse by call
    * -------------

    if ( _by() ) local byvars `_byvars'

    * Pre-compiled functions
    * ----------------------

    local funcs tag        ///
                group      ///
                total      ///
                sum        ///
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
                sepoisson  ///
                pctile

    * If function does not exist, fall back on egen
    * ---------------------------------------------

    if !( `:list fcn in funcs' ) {
        confirm new variable `name'

        if ( "`c(adoarchive)'" == "1" ) {
            capture qui _stfilearchive find _g`fcn'.ado
            if ( _rc ) {
                di as error "`fcn'() is neither a gtools nor an egen function"
                exit 133
            }
        }
        else {
            capture qui findfile _g`fcn'.ado
            if ( `"`r(fn)'"' == "" ) {
                di as error "`fcn'() is neither a gtools nor an egen function"
                exit 133
            }
        }

        if ( `"`args'"' == "_all" ) | ( `"`args'"' == "*" ) {
            unab args : _all
        }

        local gtools_args hashlib(passthru) oncollision(passthru)
        syntax [if] [in] [, `gtools_args' *]

        if ( "`byvars'" == "" ) {
            di as txt "`fcn'() is not a gtools function and no by(); falling back on egen"
            cap noi egen `type' `name' = `fcn'(`args') `if' `in', `options'
            exit _rc
        }
        else {
            di as txt "`fcn'() is not a gtools function; will hash and use egen"
            local gopts `hashlib' `oncollision'
            local popts _type(`type') _name(`name') _fcn(`fcn') _args(`args') _byvars(`byvars')
            cap noi egen_fallback `if' `in', `gopts' `popts' `options'
            exit _rc
        }
    }

    gtools_timer on 97
    global GTOOLS_CALLER gegen

    * Parse syntax call if function is known
    * --------------------------------------

    syntax                        /// main call; must parse manually
        [if] [in] ,               /// subset
    [                             ///
        by(str)                   /// collapse by variabes
                                  ///
        p(real 50)                /// percentiles (only used with pctile)
                                  ///
        missing                   /// for group(), tag(); does not get rid of missing values
        counts(passthru)          /// for group(), tag(); create `counts' with group counts
        fill(str)                 /// for group(), tag(); fills rest of group with `fill'
                                  ///
        replace                   /// debugging
        Verbose                   /// debugging
        Benchmark                 /// print benchmark info
        hashlib(passthru)         /// path to hash library (Windows only)
        oncollision(passthru)     /// On collision, fall back to collapse or throw error
    ]

    local bench = ( "`benchmark'" != "" )
    local ifin `if' `in'

    * Parse quantiles
    * ---------------

    local ofcn `fcn'
    if ( "`fcn'" == "pctile" ) {
        local quantbad = !( (`p' < 100) & (`p' > 0) )
        if ( `quantbad' ) {
            di as error "Invalid quantile: `p'; p() should be in (0, 100)"
            cap timer clear 97
            global GTOOLS_CALLER ""
            exit 110
        }
        local fcn p`p'
    }
    else if ( `p' != 50  ) {
        di as err "Option {opt p()} not allowed"
        cap timer clear 97
        global GTOOLS_CALLER ""
        exit 198
    }

    * Target and stats
    * ----------------

    if ( "`replace'" == "" ) {
        confirm new variable `name'
        tempvar dummy
        local rename rename `dummy' `name'
        local addvar qui mata: st_addvar("`type'", "`dummy'")
    }
    else {
        cap confirm new variable `name'
        if ( _rc ) {
            local dummy `name'
            local rename ""
            local addvar ""
        }
        else {
            tempvar dummy
            local rename rename `dummy' `name'
            local addvar qui mata: st_addvar("`type'", "`dummy'")
        }
    }

    local targets targets(`dummy')
    local stats   stats(`fcn')

    * If tag or group requested, then do that right away
    * --------------------------------------------------

    local  opts `verbose' `benchmark' `hashlib' `oncollision'
    local sopts `counts'

    if ( inlist("`fcn'", "tag", "group") | (("`fcn'" == "count") & ("`args'" == "1")) ) {
        if ( "`fill'" != "" ) local fill fill(`fill')

        gtools_timer info 97 `"Plugin setup"', prints(`bench') off

        if ( "`fcn'" == "tag" ) {
            local action tag(`type' `dummy') gfunction(hash) unsorted
            local noobs qui replace `dummy' = 0
        }

        if ( "`fcn'" == "group" ) {
            local action gen(`type' `dummy') gfunction(hash) countmiss
            if ( `=_N' > 1 ) local s s
            local noobs di as txt "(`=_N' missing value`i' generated)"
        }

        if ( "`fcn'" == "count" ) {
            local missing missing
            local fill fill(group) 
            local action counts(`type' `dummy') gfunction(hash) countmiss unsorted
            if ( `=_N' > 1 ) local s s
            local noobs di as txt "(`=_N' missing value`i' generated)"
        }

        if ( ("`byvars'" != "") & inlist("`fcn'", "tag", "group") ) {
            di as err "egen ... `fcn'() may not be combined with with by"
            global GTOOLS_CALLER ""
            exit 190
        }

        if ( ("`byvars'" == "") & inlist("`fcn'", "tag", "group") ) {
            local byvars `args'
        }

        cap noi _gtools_internal `byvars' `ifin', `opts' `sopts' `action' `missing' `replace' `fill'
        local rc = _rc
        global GTOOLS_CALLER ""

        if ( `rc' == 41999 ) {
            egen `00'
            exit 0
        }
        else if ( `rc' == 42001 ) {
            if ( `=_N' > 0 ) `noobs'
            `rename'
            exit 0
        }
        else if ( `rc' ) {
            exit `rc'
        }

        `rename'
        exit 0
    }

    * Parse source(s)
    * ---------------

    cap ds `args'
    if ( _rc == 0 ) {
        local sametype 1
        local sources `r(varlist)'
        cap confirm numeric v `sources'
        if ( _rc ) {
            global GTOOLS_CALLER ""
            di as err "{opth `ofcn'(varlist)} must call a numeric variable list."
            exit _rc
        }
    }
    else {
        local sametype 0
        tempvar exp
        cap gen double `exp' = `args'
        if ( _rc ) {
            global GTOOLS_CALLER ""
            di as error "Invalid call; please specify {opth `ofcn'(varlist)} or {opth `ofcn'(exp)}."

            exit 198
        }
        local sources `exp'
    }

    * Parse target type
    * -----------------

    if ( ("`addvar'" != "") & `retype' ) {
        parse_target_type `sources', fcn(`ofcn') sametype(`sametype')
        local type = "`r(retype)'"
        local addvar qui mata: st_addvar("`type'", "`dummy'")
    }


    * Parse counts into freq for gfunction call
    * -----------------------------------------

    if ( "`counts'" != "" ) {
        local 0, `counts'
        syntax, [counts(str)]

        gettoken ftype fname: counts
        if ( "`fname'" == "" ) {
            local fname `ftype'
            if ( `=_N' < 2^31 ) local ftype long
            else local ftype double
        }

        cap confirm new variable `fname'
        if ( _rc ) {
            local rc = _rc
            if ( "`replace'" == "" ) {
                global GTOOLS_CALLER ""
                di as err "Variable `fname' exists; try a different name or run with -replace-"
                exit `rc'
            }
            else if ( ("`replace'" != "") & ("`addvar'" != "") ) {
                qui replace `fname' = .
                local replace ""
            }
        }
        else {
            if ( "`addvar'" == "" ) {
                local addvar qui mata: st_addvar("`ftype'", "`counts'")
            }
            else {
                local addvar qui mata: st_addvar(("`type'", "`ftype'"), ("`name'", "`counts'"))
                local replace ""
            }
        }

        local counts freq(`counts')
    }

    * Call the plugin
    * ---------------

    local unsorted = cond("`fill'" == "data", "", "unsorted")
    gtools_timer info 97 `"Plugin setup"', prints(`bench') off

    `addvar'
    local action sources(`sources') `targets' `stats' fill(`fill') `counts' countmiss
    cap noi _gtools_internal `byvars' `ifin', `unsorted' `opts' `action' missing `replace'
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 41999 ) {
        egen `00'
        exit 0
    }
    else if ( `rc' == 42001 ) {
        exit 0
    }
    else if ( `rc' ) exit `rc'

    return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'

    `rename'
    exit 0
end

capture program drop egen_fallback
program egen_fallback, sortpreserve
    syntax [if] [in],          ///
    [                          ///
        _type(str)             ///
        _name(str)             ///
        _fcn(str)              ///
        _args(str)             ///
        _byvars(str)           ///
        by(passthru)           ///
        oncollision(passthru)  ///
        fallback(passthru)     ///
        *                      ///
    ]

    tempvar dummy
    global EGEN_Varname  `_name'
    global EGEN_SVarname `_sortindex'

	local cvers = _caller()
    if ( "`_fcn'" == "mode" | "`_fcn'" == "concat" ) {
        local vv : display "version " string(`cvers') ", missing:"
    }

    tempvar byid
    hashsort `_byvars', group(`byid') `oncollision' `fallback'

    capture noisily `vv' _g`_fcn' `_type' `dummy' = (`_args') `if' `in', by(`byid') `options'
    global EGEN_SVarname
    global EGEN_Varname
    if ( _rc ) exit _rc

    quietly count if missing(`dummy')
    if ( `r(N)' ) {
        local s = cond(r(N) > 1, "s", "")
        di in bl "(" r(N) " missing value`s' generated)"
    }
    rename `dummy' `_name'
    exit 0
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

capture program drop parse_target_type
program parse_target_type, rclass
    syntax varlist, fcn(str) sametype(int)

    gettoken var restvars: varlist

    local maxtype: type `var'
    encode_vartype `maxtype'
    local maxcode `r(typecode)'

    foreach var in `restvars' {
        local stype: type `var'
        encode_vartype `stype'
        local scode `r(typecode)'
        if ( `scode' > `maxcode' ) {
            local maxtype `stype'
            local maxcode `scode'
        }
    }

    if ( `sametype' ) local retype_A `maxtype'
    else local retype_A: set type

    if ( "`maxtype'" == "double" ) local retype_B double
    else local retype_B: set type

    if ( `=_N' < 2^31 ) local retype_C long
    else local retype_C double

    if ( "`fcn'" == "tag"        ) return local retype = "byte"
    if ( "`fcn'" == "group"      ) return local retype = "`retype_C'"
    if ( "`fcn'" == "total"      ) return local retype = "double"
    if ( "`fcn'" == "sum"        ) return local retype = "double"
    if ( "`fcn'" == "mean"       ) return local retype = "`retype_B'"
    if ( "`fcn'" == "sd"         ) return local retype = "`retype_B'"
    if ( "`fcn'" == "max"        ) return local retype = "`retype_A'"
    if ( "`fcn'" == "min"        ) return local retype = "`retype_A'"
    if ( "`fcn'" == "count"      ) return local retype = "`retype_C'"
    if ( "`fcn'" == "median"     ) return local retype = "`retype_B'"
    if ( "`fcn'" == "iqr"        ) return local retype = "`retype_B'"
    if ( "`fcn'" == "percent"    ) return local retype = "`retype_B'"
    if ( "`fcn'" == "first"      ) return local retype = "`retype_A'"
    if ( "`fcn'" == "last"       ) return local retype = "`retype_A'"
    if ( "`fcn'" == "firstnm"    ) return local retype = "`retype_A'"
    if ( "`fcn'" == "lastnm"     ) return local retype = "`retype_A'"
    if ( "`fcn'" == "semean"     ) return local retype = "`retype_B'"
    if ( "`fcn'" == "sebinomial" ) return local retype = "`retype_B'"
    if ( "`fcn'" == "sepoisson"  ) return local retype = "`retype_B'"
    if ( "`fcn'" == "pctile"     ) return local retype = "`retype_B'"
end

capture program drop encode_vartype
program encode_vartype, rclass
    args vtype
         if ( "`vtype'" == "byte"   ) return scalar typecode = 1
    else if ( "`vtype'" == "int"    ) return scalar typecode = 2
    else if ( "`vtype'" == "long"   ) return scalar typecode = 3
    else if ( "`vtype'" == "float"  ) return scalar typecode = 4
    else if ( "`vtype'" == "double" ) return scalar typecode = 5
    else                              return scalar typecode = 0
end
