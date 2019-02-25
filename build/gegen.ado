*! version 1.1.3 23Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! implementation -egen- using C for faster processing

/*
 * syntax:
 *     gegen [type] varname = fun(args) [if] [in], [options]
 *     passed to fun are
 *         [type] varname = fun(args) [if] [in], [options]
 */

/*
 * stata's egen does not parse types correctly.  If the requested result is
 * a sum, stata will happily create a float, despite the risk of overflow.
 * If the source variable is a double, stata will also create a float, even
 * though that might cause a loss in precision. I do not imitate this behavior
 * because I consider it flawed. I upgrade types whenever necessary.
 *
 */

/*
 * TODO: implement label, lname, and truncate for group
 */

capture program drop gegen
program define gegen, byable(onecall) rclass
    version 13.1

    local 00 `0'
    qui syntax anything(equalok) [if] [in] [aw fw iw pw], [by(str) *]
    local byvars `by'
    local 0 `00'

    * Parse weights
    * -------------

    local wgt = cond(`"`weight'"' != "", `"[`weight' `exp']"', "")

    * Parse egen call
    * ---------------

    gettoken type 0 : 0, parse(" =(")
    gettoken name 0 : 0, parse(" =(")

    if ( `"`name'"' == "=" ) {
        local name   `"`type'"'
        local type   : set type
        local retype = 1
        local btype  double
    }
    else {
        gettoken eqsign 0 : 0, parse(" =(")
        if ( `"`eqsign'"' != "=" ) {
            error 198
        }
        local btype  `type'
        local retype = 0
    }

    confirm name `name'
    gettoken fcn  0: 0, parse(" =(")
    gettoken args 0: 0, parse(" ,") match(par)

    if ( "`fcn'"   == "total" ) local fcn sum
    if ( "`fcn'"   == "var"   ) local fcn variance
    if ( "`fcn'"   == "sem"   ) local fcn semean
    if ( "`fcn'"   == "seb"   ) local fcn sebinomial
    if ( "`fcn'"   == "sep"   ) local fcn sepoisson
    if ( "`fcn'"   == "kurt"  ) local fcn kurtosis
    if ( "`fcn'"   == "skew"  ) local fcn skewness
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
                nansum     ///
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
                pctile     ///
                select     ///
                nmissing   ///
                skewness   ///
                kurtosis

    * If function does not exist, fall back on egen
    * ---------------------------------------------

    if !( `:list fcn in funcs' ) {
        confirm new variable `name'

        if ( `"`c(adoarchive)'"' == "1" ) {
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

        if ( `"`weight'"' != "" ) {
            di as txt "`fcn'() is not a gtools function; falling back on egen"
            di as err "weights are not allowed for egen-only functions"
            exit 101
        }

        if ( `"`args'"' == "_all" ) | ( `"`args'"' == "*" ) {
            unab args : _all
        }

        local gtools_args HASHmethod(passthru)     ///
                          oncollision(passthru)    ///
                          Verbose                  ///
                          _subtract                ///
                          _CTOLerance(passthru)    ///
                          compress                 ///
                          forcestrl                ///
                          NODS DS                  /// Parse - as varlist (ds) or negative (nods)
                          BENCHmark                ///
                          BENCHmarklevel(passthru) ///
                          gtools_capture(str)
        syntax [if] [in] [, `gtools_args' *]

        if ( "`byvars'" == "" ) {
            di as txt "`fcn'() is not a gtools function and no by(); falling back on egen"
            cap noi egen `type' `name' = `fcn'(`args') `if' `in', `options' `gtools_capture'
            exit _rc
        }
        else {
            di as txt "`fcn'() is not a gtools function; will hash and use egen"

            local gopts `hashmethod' `oncollision' `verbose' `_subtract' `_ctolerance'
            local gopts `gopts' `compress' `forcestrl' `benchmark' `benchmarklevel' `ds' `nods'

            local popts _type(`type') _name(`name') _fcn(`fcn') _args(`args') _byvars(`byvars')
            cap noi egen_fallback `if' `in', kwargs(`gopts') `popts' `options' `gtools_capture'
            exit _rc
        }
    }

    FreeTimer
    local t97: copy local FreeTimer
    gtools_timer on `t97'
    global GTOOLS_CALLER gegen

    * Parse syntax call if function is known
    * --------------------------------------

    * gegen [type] varname = fun(args) [if] [in], [options]

    syntax                        /// Main call was parsed manually
        [if] [in]                 /// [if condition] [in start / end]
        [aw fw iw pw] ,           /// [weight type = exp]
    [                             ///
        by(str)                   /// Collapse by variabes: [+|-]varname [[+|-]varname ...]
                                  ///
        p(real 50)                /// Percentile to compute, #.# (only with pctile). e.g. 97.5
        n(int 0)                  /// nth smallest to select (negative for largest)
                                  ///
        missing                   /// for group(), tag(); does not get rid of missing values
        counts(passthru)          /// for group(), tag(); create `counts' with group counts
        fill(str)                 /// for group(), tag(); fills rest of group with `fill'
                                  ///
        replace                   /// Replace target variable with output, if target already exists
                                  ///
        compress                  /// Try to compress strL variables
        forcestrl                 /// Force reading strL variables (stata 14 and above only)
        NODS DS                   /// Parse - as varlist (ds) or negative (nods)
        Verbose                   /// Print info during function execution
        _subtract                 /// (Undocumented) Subtract result from source variable
        _CTOLerance(passthru)     /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                 /// print function benchmark info
        BENCHmarklevel(int 0)     /// print plugin benchmark info
        HASHmethod(passthru)      /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)     /// error|fallback: On collision, use native command or throw error
        gtools_capture(passthru)  /// Ignored (captures fcn options if fcn is not known)
                                  ///
                                  /// Unsupported egen options
                                  /// ------------------------
                                  ///
        Label                     ///
        lname(passthru)           ///
        Truncate(passthru)        ///
   ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')
    local keepmissing = cond("`missing'" == "", "", "keepmissing")

    foreach opt in label lname truncate {
        if ( `"``opt''"' != "" ) {
            di as txt ("Option -`opt'- is not implemented."
            exit 198
        }
    }

    if ( "`gtools_capture'" != "" ) {
        di as txt ("option -gtools_capture()- ignored with supported function `fcn')"
    }

    local bench = ( "`benchmark'" != "" )

    if ( ("`ds'" != "") & ("`nods'" != "") ) {
        di as err "-ds- and -nods- mutually exclusive"
        exit 198
    }

    * Parse weights
    * -------------

    if ( `:list posof "variance" in fcn' > 0 ) {
        if ( `"`weight'"' == "pweight" ) {
            di as err "variance not allowed with pweights"
            exit 135
        }
    }
    if ( `:list posof "cv" in fcn' > 0 ) {
        if ( `"`weight'"' == "pweight" ) {
            di as err "cv not allowed with pweights"
            exit 135
        }
    }
    if ( `:list posof "sd" in fcn' > 0 ) {
        if ( `"`weight'"' == "pweight" ) {
            di as err "sd not allowed with pweights"
            exit 135
        }
    }
    if ( `:list posof "select" in fcn' > 0 ) {
        if ( inlist(`"`weight'"', "iweight") ) {
            di as err "select not allowed with `weight's"
            exit 135
        }
    }
    if ( `:list posof "semean" in fcn' > 0 ) {
        if ( inlist(`"`weight'"', "pweight", "iweight") ) {
            di as err "semean not allowed with `weight's"
            exit 135
        }
    }
    if ( `:list posof "sebinomial" in fcn' > 0 ) {
        if ( inlist(`"`weight'"', "aweight", "iweight", "pweight") ) {
            di as err "sebinomial not allowed with `weight's"
            exit 135
        }
    }
    if ( `:list posof "sepoisson" in fcn' > 0 ) {
        if ( inlist(`"`weight'"', "aweight", "iweight", "pweight") ) {
            di as err "sepoisson not allowed with `weight's"
            exit 135
        }
    }

	if ( `"`weight'"' != "" ) {
		tempvar w touse
		qui gen double `w' `exp' `if' `in'

		local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        local anywgt anywgt

        mark `touse' `if' `in' `wgt'
        local ifin if `touse' `in'
	}
    else {
		local wgt
        local weights
        local anywgt
        local ifin `if' `in'
    }

    * Parse quantiles
    * ---------------

    local ofcn `fcn'
    if ( "`fcn'" == "pctile" ) {
        local quantbad = !( (`p' < 100) & (`p' > 0) )
        if ( `quantbad' ) {
            di as error "Invalid quantile: `p'; p() should be in (0, 100)"
            cap timer clear `t97'
            global GTOOLS_CALLER ""
            exit 110
        }
        local fcn p`p'
    }
    else if ( `p' != 50  ) {
        di as err "Option {opt p()} not allowed"
        cap timer clear `t97'
        global GTOOLS_CALLER ""
        exit 198
    }

    * Parse selection
    * ---------------

    if ( "`fcn'" == "select" ) {
        if ( `n' == 0 ) {
            di as error "n() should be a positive or negative integer"
            cap timer clear `t97'
            global GTOOLS_CALLER ""
            exit 110
        }
        local fcn select`n'
    }
    else if ( `n' != 0  ) {
        di as err "Option {opt n()} not allowed"
        cap timer clear `t97'
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
        local noobs  ""
        local retype = `retype' & 1
    }
    else {

        * NOTE: Addvar should be "" with replace; the problem was that
        * the internals did not empty the variable before writing to
        * it. With if/in conditions, this caused problems because the
        * variable was not set to missing outside the range, as it
        * should.
        *
        * As a quickfix I thought I could just empty it before calling
        * internals. However, this causesd two issues: The variable
        * would be missing on error, and if the target is also a source,
        * the source would be all misssing when read by the plugin!
        *
        * The easiest fix was to require the target to not be in the
        * sources, but there was an easier fix! I already empty the
        * targets fot gcollapse, so I simply set that boolean to true
        * (init_targ) when gegen was called with replace! This impacts
        * the check in lines 489-492.

        cap confirm new variable `name'
        if ( _rc ) {
            local dummy `name'
            local rename ""
            local addvar ""
            local noobs qui replace `dummy' = .
            local retype = `retype' & 0
        }
        else {
            tempvar dummy
            local rename rename `dummy' `name'
            local addvar qui mata: st_addvar("`type'", "`dummy'")
            local noobs  ""
            local retype = `retype' & 1
        }
    }

    local targets targets(`dummy')
    local stats   stats(`fcn')

    * If tag or group requested, then do that right away
    * --------------------------------------------------

    local opts  `compress' `forcestrl' `_subtract' `_ctolerance'
    local opts  `opts' `verbose' `benchmark' `benchmarklevel'
    local opts  `opts' `oncollision' `hashmethod' `ds' `nods'
    local sopts `counts'

    if ( inlist("`fcn'", "tag", "group") | (("`fcn'" == "count") & ("`args'" == "1")) ) {
        if ( "`fill'" != "" ) local fill fill(`fill')

        if ( `"`weight'"' != "" ) {
            di as txt "(weights are ignored for egen function {opt `fcn'})"
        }

        gtools_timer info `t97' `"Plugin setup"', prints(`bench') off

        if ( "`fcn'" == "tag" ) {
            local action tag(`type' `dummy') gfunction(hash) unsorted
            local noobs qui replace `dummy' = 0
        }

        if ( inlist("`fcn'", "group", "count") ) {
            if ( `=_N' < maxbyte() ) {
                * All types are OK
            }
            else if ( `=_N' < `=2^24' ) {
                if inlist("`type'", "byte") {
                    * byte is no longer OK; int, float still OK
                    local upgraded = cond(`retype', "", "`type'")
                    local type int
                }
            }
            else if ( `=_N' < maxint() ) {
                if inlist("`type'", "byte", "float") {
                    * byte and float no longer OK; int still OK
                    local upgraded = cond(`retype', "", "`type'")
                    local type int
                }
            }
            else if ( `=_N' < maxlong() ) {
                if inlist("`type'", "byte", "int", "float") {
                    * byte, float, int no longer OK; must upgrade to long
                    local upgraded = cond(`retype', "", "`type'")
                    local type long
                }
            }
            else {
                if ( "`type'" != "double" ) {
                    * Only double can maintain precision
                    local upgraded = cond(`retype', "", "`type'")
                    local type double
                }
            }
        }

        if ( "`upgraded'" != "" ) {
            disp "(warning: user-requested type '`upgraded'' upgraded to '`type'')"
        }

        if ( "`fcn'" == "group" ) {
            local action gen(`type' `dummy') gfunction(hash) countmiss
            if ( `=_N' > 1 ) local s s
            local noobs qui replace `dummy' = .
            local notxt di as txt "(`=_N' missing value`s' generated)"
        }

        if ( "`fcn'" == "count" ) {
            local missing missing
            local fill fill(group)
            local action counts(`type' `dummy') gfunction(hash) countmiss unsorted
            if ( `=_N' > 1 ) local s s
            local noobs qui replace `dummy' = .
            local notxt di as txt "(`=_N' missing value`s' generated)"
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

        if ( `rc' == 17999 ) {
            local gtools_args `hashmethod'     ///
                              `oncollision'    ///
                              `verbose'        ///
                              `_subtract'      ///
                              `_ctolerance'    ///
                              `compress'       ///
                              `forcestrl'      ///
                              `nods' `ds'      ///
                              `benchmark'      ///
                              `benchmarklevel' ///
                              `gtools_capture'
            local gtools_opts `counts' fill(`fill') `replace' p(`p') `missing'
            collision_fallback, gtools_call(`"`type' `name' = `fcn'(`args') `ifin'"') `gtools_args' `gtools_opts'
            exit 0
        }
        else if ( `rc' == 17001 ) {
            if ( "${GTOOLS_DUPS}" == "" ) {
                if ( `=_N' > 0 ) {
                    `noobs'
                    `notxt'
                }
                `rename'
                exit 0
            }
            else {
                error 2000
            }
        }
        else if ( `rc' ) {
            exit `rc'
        }

        return scalar N    = `r(N)'
        return scalar J    = `r(J)'
        return scalar minJ = `r(minJ)'
        return scalar maxJ = `r(maxJ)'

        `rename'
        exit 0
    }

    * Parse source(s)
    * ---------------

    unab memvars: _all

    local rc = 0
    if ( !((`:list sizeof args' == 1) & (`:list args in memvars')) ) {
        tempvar exp
        cap gen double `exp' = `args'
        local rc = _rc
    }

    if ( ((`:list sizeof args' == 1) & (`:list args in memvars')) | `rc' ) {
        cap ds `args'
        if ( _rc ) {
            global GTOOLS_CALLER ""
            di as error "Invalid call; please specify {opth `ofcn'(varlist)} or {opth `ofcn'(exp)}."
            exit 198
        }
        else {
            local sametype 1
            local sources `r(varlist)'
            cap confirm numeric v `sources'
            if ( _rc ) {
                global GTOOLS_CALLER ""
                di as err "{opth `ofcn'(varlist)} must call a numeric variable list."
                exit _rc
            }

            * See notes in lines 294-310
            * if ( "`:list sources & dummy'" != "" ) { 
            *     if ( "`replace'" != "" ) local extra " even with -replace-"
            *     di as error "Variable `dummy' canot be a source and a target`extra'"
            *     exit 198
            * }
        }
    }
    else if ( `rc' == 0 ) {
        local sources `exp'
        local sametype 0
    }

    * cap ds `args'
    * if ( _rc == 0 ) {
    *     local sametype 1
    *     local sources `r(varlist)'
    *     cap confirm numeric v `sources'
    *     if ( _rc ) {
    *         global GTOOLS_CALLER ""
    *         di as err "{opth `ofcn'(varlist)} must call a numeric variable list."
    *         exit _rc
    *     }
    * }
    * else {
    *     local sametype 0
    *     tempvar exp
    *     cap gen double `exp' = `args'
    *     if ( _rc ) {
    *         global GTOOLS_CALLER ""
    *         di as error "Invalid call; please specify {opth `ofcn'(varlist)} or {opth `ofcn'(exp)}."
    *
    *         exit 198
    *     }
    *     local sources `exp'
    * }

    * Parse target type
    * -----------------

    * if ( ("`addvar'" != "") & `retype' ) {
    if ( `retype' ) {
        parse_target_type `sources', fcn(`ofcn') sametype(`sametype') `anywgt'
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
            if ( `=_N < maxlong()' ) local ftype long
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
    gtools_timer info `t97' `"Plugin setup"', prints(`bench') off

    `addvar'
    local action sources(`sources') `targets' `stats' fill(`fill') `counts' countmiss
    cap noi _gtools_internal `byvars' `ifin', `unsorted' `opts' `action' `weights' missing `keepmissing' `replace'
    local rc = _rc
    global GTOOLS_CALLER ""

    if ( `rc' == 17999 ) {
        if ( `"`weight'"' != "" ) {
            di as err "Cannot use fallback with weights."
            exit 17000
        }
        local gtools_args `hashmethod'     ///
                          `oncollision'    ///
                          `verbose'        ///
                          `_subtract'      ///
                          `_ctolerance'    ///
                          `compress'       ///
                          `forcestrl'      ///
                          `nods' `ds'      ///
                          `benchmark'      ///
                          `benchmarklevel' ///
                          `gtools_capture'
        local gtools_opts `counts' fill(`fill') `replace' p(`p') `missing'
        collision_fallback, gtools_call(`"`type' `name' = `fcn'(`args') `ifin'"') `gtools_args' `gtools_opts'
        exit 0
    }
    else if ( `rc' == 17001 ) {
        if ( "${GTOOLS_DUPS}" == "" ) {
            `noobs'
            `rename'
            exit 0
        }
        else {
            error 2000
        }
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
        kwargs(str)            ///
        *                      ///
    ]

    tempvar dummy
    global EGEN_Varname  `_name'
    global EGEN_SVarname `_sortindex'

	local cvers = _caller()
    if ( "`_fcn'" == "mode" | "`_fcn'" == "concat" ) {
        local vv : display "version " string(`cvers') ", missing:"
    }

    if ( "`: sortedby'" == "`_byvars'" ) {
        local byid `: sortedby'
    }
    else {
        tempvar byid
        hashsort `_byvars', gen(`byid') sortgen skipcheck `kwargs'
    }

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
        if ( `prints' ) {
            di `"`msg'`:di trim("`:di %21.4gc r(t`timer')'")' seconds"'
        }
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
    syntax varlist, fcn(str) sametype(int) [anywgt]

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

    if ( `=_N < maxlong()' & ("`anywgt'" == "") ) local retype_C long
    else local retype_C double

    if ( `"`maxtype'"' == "byte" ) {
        local retype_D int
    }
    else if ( `"`maxtype'"' == "int" ) {
        local retype_D long
    }
    else if ( `"`maxtype'"' == "long" ) {
        local retype_D double
    }
    else if ( `"`maxtype'"' == "float" ) {
        local retype_D double
    }
    else if ( `"`maxtype'"' == "double" ) {
        local retype_D double
    }

    if ( "`fcn'" == "tag"        ) return local retype = "byte"
    if ( "`fcn'" == "group"      ) return local retype = "`retype_C'"
    if ( "`fcn'" == "total"      ) return local retype = "double"
    if ( "`fcn'" == "sum"        ) return local retype = "double"
    if ( "`fcn'" == "nansum"     ) return local retype = "double"
    if ( "`fcn'" == "mean"       ) return local retype = "`retype_B'"
    if ( "`fcn'" == "sd"         ) return local retype = "`retype_B'"
    if ( "`fcn'" == "variance"   ) return local retype = "`retype_B'"
    if ( "`fcn'" == "cv"         ) return local retype = "`retype_B'"
    if ( "`fcn'" == "max"        ) return local retype = "`retype_A'"
    if ( "`fcn'" == "min"        ) return local retype = "`retype_A'"
    if ( "`fcn'" == "range"      ) return local retype = "`retype_D'"
    if ( "`fcn'" == "select"     ) return local retype = "`retype_A'"
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
    if ( "`fcn'" == "nunique"    ) return local retype = "`retype_C'"
    if ( "`fcn'" == "nmissing"   ) return local retype = "`retype_C'"
    if ( "`fcn'" == "skewness"   ) return local retype = "`retype_B'"
    if ( "`fcn'" == "kurtosis"   ) return local retype = "`retype_B'"
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

capture program drop collision_fallback
program collision_fallback
    local gtools_args HASHmethod(passthru)     ///
                      oncollision(passthru)    ///
                      Verbose                  ///
                      _subtract                ///
                      _CTOLerance(passthru)    ///
                      compress                 ///
                      forcestrl                ///
                      NODS DS                  ///
                      BENCHmark                ///
                      BENCHmarklevel(passthru) ///
                      gtools_capture(str)

    syntax, [`gtools_args' gtools_call(str) counts(str) fill(str) replace *]
    foreach opt in counts fill replace {
        if ( `"``opt''"' != "" ) {
            di as err "Cannot use fallback with option {opt `opt'}."
            exit 17000
        }
    }
    egen `gtools_call', `options'
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
