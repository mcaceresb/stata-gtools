*! version 0.5.0 26Jan2020 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Fast implementation of reshape using C plugins

capture program drop greshape
program greshape, rclass
    version 13.1

    if ( inlist(`"`1'"', "clear", "query", "error", "i", "xij", "j", "xi") ) {
        disp as err "-reshape `1'- syntax is not supported; see {help greshape:help greshape}" _n
        picture err cmd
        exit 198
    }

    if ( inlist(`"`1'"', "") ) {
        disp as err `"Nothing to do. Specify long or gather, wide or spread"' _n
        picture err cmd
        exit 198
    }
    else if ( !inlist(`"`1'"', "long", "wide", "gather", "spread") ) {
        disp as err `"Unknown subcommand '`1''; supported: long or gather, wide or spread"' _n
        picture err cmd
        exit 198
    }

    if ( `=_N' == 0 ) {
        disp "(no observations)"
        exit
    }

    ***********************************************************************
    *                        Reshape wide or long                         *
    ***********************************************************************

    if ( inlist(`"`1'"', "wide", "spread") ) {
        local cmd Wide
    }
    else if ( inlist(`"`1'"', "long", "gather") ) {
        local cmd Long
    }
    else {
        disp as err `"Unknown subcommand '`1''; supported: long or gather, wide or spread"' _n
        picture err cmd
        exit 198
    }

    * ----------------------------------
    * Handle wide/spread and long/gather
    * ----------------------------------

    ClearReshape
    global GTOOLS_PARSE       ///
        unsorted              /// Do not sort the data
        compress              /// Try to compress strL variables
        forcestrl             /// Force reading strL variables (stata 14 and above only)
        Verbose               /// Print info during function execution
        _CTOLerance(passthru) /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
        debug(passthru)        // Print debugging info to console

    * gettoken sub args: 0
    cap noi `cmd' `*'
    local rc = _rc
    if ( `rc' == 17999 ) {
        CleanExit
        if inlist( `"`1'"', "spread", "gather") {
            di as err `"Cannot use fallback with `1'"'
            exit 17000
        }
        else {
            reshape `0'
            exit
        }
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        local rc 0
    }
    else if ( `rc' == 18101 ) {
        NonUniqueLongID
        local rc 9
    }
    else if ( `rc' == 18102 ) {
        NonUniqueWideJ
        local rc 9
    }
    else if ( `rc' == 18103 ) {
        NonUniqueWideXi
        local rc 9
    }
    CleanExit
    exit `rc'
end

* L | W | G
* X | X | ReS_Xij
* X | X | ReS_str
* X |   | ReS_uselabels
* X | X | ReS_i
* X | X | ReS_j
* X | X | ReS_jname
* X | X | ReS_nodupcheck
* X | X | ReS_nomisscheck
* X | X | ReS_cmd
*   | X | ReS_prefix
*   | X | ReS_labelformat
* X | X | ReS_Xij_stubs
* X |   | ReS_Xij_regex
* X |   | ReS_Xij_add
* X | X | ReS_Xij_keep
* X | X | ReS_Xij_keepnames
* X | X | ReS_Xij_names
*   | X | ReS_Xij_addtypes
*   | X | ReS_Xij_addvars
* X | X | ReS_atwl
* X | X | ReS_match
* X | X | ReS_jfile
*   | X | ReS_jcode
* X | X | ReS_jlen
* X | X | ReS_jv
* X | X | ReS_jv2
* X | X | ReS_Xi
* X | X | S_1
* ? | ? | S_1_full
* ? | ? | S_2
* X | X | rVANS

* ---------------------------------------------------------------------
* Reshape long

capture program drop Long
program define Long /* reshape long */

    ***********************************************************************
    *                          Parse Long Syntax                          *
    ***********************************************************************

    gettoken ReS_cmd 0: 0
    global ReS_cmd: copy local ReS_cmd
    global ReS_jname j
    global ReS_iname i

    local long_opts            ///
        [                      ///
            by(varlist)        /// reshape by groups of -by()-
            i(varlist)         /// reshape by groups of -i()-
            j(name) String     /// varnames by levels -j()-; look for string-like names
            KEYs(name)         /// varnames by levels -key()-
            xi(str)            /// Handle extraneous variables
            fast               /// Do not preserve and restore the original dataset. Saves speed
            nochecks           /// Do not do any checks
            CHECKlevel(real 4) /// Check level
            DROPMISSing        /// Drop missing values from reshape
            nodupcheck         /// Do not check for duplicates
            nomisscheck        /// Do not check for missing values or blanks in j
            match(str)         /// a string (e.g. @) to match or 'regex'
                               /// with match(regex), stubs must be of the form
                               ///
                               ///     regex/# regex/#
                               ///
                               /// where # is the group to be captured for the levels of j; the
                               /// default is 1. If no groups are found, the level is assumed to
                               /// be stub suffix (as would be the case w/o regex). For example:
                               ///
                               ///     st(.+)ub stub (foo|bar)stub([0-9]+)(alice|bob)/2
                               ///
                               /// is almost the the same as
                               ///
                               ///     st@ub stub@ foostub@alice barstub@bob foostub@alice barstub@bob
                               ///
                               /// The only difference is that @ in the latter 4 stubs will only
                               /// match numbers. Note that several parts of a variable name
                               /// match the group, the first match will be replaced even if the
                               /// user captures both separately. If this is really a concern,
                               /// you can specify ustrregex (Stata 14 and above only) and use
                               /// lookarounds:
                               ///
                               ///     (?<=(foo|bar)[0-9]{0,2}stub)([0-9]+)(?=alice|bob)
                               ///
                               /// everything other than the levels to match to j must be captured
                               /// in a lookbehind or lookahead. Note Stata does not support matches
                               /// of indeterminate length inside lookarounds (this is a limitation
                               /// that is not uncommon across several regex implementations).
                               ///
            ${GTOOLS_PARSE}    ///
        ]

    local gather_opts          ///
            VALUEs(name)       /// out variaable name
        [                      ///
            by(varlist)        /// reshape by groups of -i()-
            i(varlist)         /// reshape by groups of -i()-
            j(name)            /// varnames by levels -j()-
            KEYs(name)         /// varnames by levels -key()-
            xi(str)            /// Handle extraneous variables
            fast               /// Do not preserve and restore the original dataset. Saves speed
            DROPMISSing        /// Drop missing values from reshape
            USELabels          /// Use labels as values instead of variable names
            USELabelsvars(str) /// Use labels as values instead of variable names
            ${GTOOLS_PARSE}    ///
        ]

    syntax anything, ``ReS_cmd'_opts'
    local key: copy local keys

    * ------------------
    * Parse i, j aliases
    * ------------------

    if ( (`"`by'"' == "") & (`"`i'"' == "") & (`"`ReS_cmd'"' == "long") ) {
        disp as err "option {opt i()} (id variable) required"
        exit 198
    }

    if ( (`"`by'"' != "") & (`"`i'"' != "") ) {
        disp as err "i() and by() are aliases for the same option; use only one"
        exit 198
    }
    else if ( `"`by'"' != "" ) {
        global ReS_iname by
        local i: copy local by
    }

    if ( (`"`key'"' != "") & (`"`j'"' != "") ) {
        disp as err "j() and key() are aliases for the same option; use only one"
        exit 198
    }
    else if ( `"`key'"' != "" ) {
        global ReS_jname key
        local j: copy local key
    }

    * -------------------
    * Parse other options
    * -------------------

    c_local 0 `ReS_cmd' `anything', i(`i') j(`j') `string'

    if ( `"`checklevel'"' == "" ) local checklevel 4
    if ( `"`values'"'     == "" ) local values: copy local anything

    if ( `checklevel' > 3 ) {
    }
    else if ( `checklevel' > 2 ) {
        local misscheck nomisscheck
    }
    else if ( `checklevel' > 1 ) {
        local fast      fast
        local misscheck nomisscheck
    }
    else if ( `checklevel' > 0 ) {
        local fast      fast
        local unsorted  unsorted
        local misscheck nomisscheck
    }
    else if ( `checklevel' == 0 ) {
        local checks nochecks
    }

    if ( `"`checks'"' == "nochecks" ) {
        local fast      fast
        local dupcheck  nodupcheck
        local unsorted  unsorted
        local misscheck nomisscheck
    }

    if ( `"`ReS_cmd'"' == "gather" ) {
        local dupcheck   nodupcheck
        local unsorted   unsorted
        local misscheck  nomisscheck
        local string     string
        global ReS_jname key
    }

    if ( "`fast'" == "" ) preserve

    unab oldlist: _all
    if ( `"`i'"' == "" ) {
        unab anything: `anything'
        local restvars: list oldlist - anything
        local restvars: list restvars - j
        local i: copy local restvars
        if ( `"`xi'"' != "" ) {
            disp as txt "(note: -xi()- ignored without -$ReS_iname()-)"
        }
    }
    else {
        unab i: `i'
    }

    if ( `"`j'"' == "" ) local j _$ReS_jname

    if ( `"`match'"' == "" ) local match @

    if ( `"`uselabelsvars'"' != "" ) {
        local uselabels uselabels
    }
    else if ( `"`uselabels'"' != "" ) {
        unab uselabelsvars: _all
    }

    global ReS_uselabels: copy local uselabelsvars
    global ReS_str = ( `"`string'"' != "" )
    global ReS_atwl  `atwl'
    global ReS_match `match'
    global ReS_Xij   `values'
    global ReS_i     `i'
    global ReS_j     `j'

    * This defines $ReS_Xij_stubs and potentially overwrites ReS_Xij
    ParseStubsByMatch long

    if ( `"`ReS_cmd'"' == "gather" ) {
        unab ReS_Xij_names: `anything'
        cap noi confirm var `ReS_Xij_names'
        if _rc {
            disp as err "greshape spread requires explicit variable names"
            exit 198
        }
        global ReS_Xij_names: copy local ReS_Xij_names

        local restvars: list oldlist - ReS_Xij_names
        local restvars: list restvars - j
        cap assert `:list i == restvars'
        if ( _rc & (`"`xi'"' != "drop") ) {
            disp as err "greshape spread does not allow extraneous variables (Xi):"
            disp as err ""
            disp as err "    Xij -> `ReS_Xij_names'"
            disp as err "    $ReS_iname   -> `i'"
            disp as err "    Xi  -> `:list restvars - i'"
            disp as err ""
            disp as err "Specify xi(drop), leave $ReS_iname() blank, or include Xi somewhere in the reshape."
            exit 198
        }

        if ( `:list sizeof values' > 1 ) {
            disp as err "values() must be a new variable name"
            exit 198
        }
    }

    local opts `unsorted'              ///
               `compress'              ///
               `forcestrl'             ///
               `verbose'               ///
               `_ctolerance'           ///
               `benchmark'             ///
               bench(`benchmarklevel') ///
               `oncollision'           ///
               `hashmethod'            ///
               `debug'

    global ReS_nodupcheck  = ( `"`dupcheck'"'  == "nodupcheck" )
    global ReS_nomisscheck = ( `"`misscheck'"' == "nomisscheck" )
    if ( `"`ReS_cmd'"' != "gather" ) {
        if ( "`unsorted'" == "unsorted" ) {
            if ( $ReS_nodupcheck ) {
                disp as txt "(note: reshape left unsorted; duplicates check is skipped)"
            }
            else {
                disp as txt "(note: reshape left unsorted; original order not preserved)"
            }
        }
        else {
            if ( $ReS_nodupcheck ) {
                disp as txt "(note: reshape will be sorted; -nodupcheck- ignored)"
            }
        }
    }

    local oldobs = _N
    quietly describe, short
    local oldvars = r(k)

    ***********************************************************************
    *                         Macros and J values                         *
    ***********************************************************************

    Macros long
    confirm var $ReS_i $ReS_Xi
    capture confirm new var $ReS_j
    if ( _rc ) {
        di in blu "Target $ReS_jname($ReS_j) already exists (is the data already long?)"
        exit 198
    }

    if ( `"${GTOOLS_TEMPDIR}"' == "" ) {
        tempfile ReS_jfile
    }
    else {
        GreshapeTempFile ReS_jfile
    }
    global ReS_jfile `ReS_jfile'
    scalar __greshape_jfile = length(`"`ReS_jfile'"') + 1

    GetJLevels

    confirm var $ReS_i $ReS_Xi
    if ( $ReS_str ) {
        local string str($ReS_jlen)
        local jtype  str$ReS_jlen
    }
    else {
        local string str(0)
        local jtype  long
    }

    if ( inlist(`"`xi'"', "keep", "") ) {
    }
    else if ( `"`xi'"' == "drop" ) {
        global ReS_Xi
    }
    else {
        disp as err `"Invalid sytax -xi(`xi')-; specify first, keep, drop"'
        exit 198
    }

    if ( `"`ReS_cmd'"' == "gather" & `"${ReS_Xi}"' != "" ) {
        disp as err "Error parsing varlist. xi() should be blank"
        exit 198
    }

    GetXiTypes
    CopyScalars

    ***********************************************************************
    *                           Do the reshape                            *
    ***********************************************************************

    * ------------------------
    * Reshape the data to disk
    * ------------------------

    if ( $ReS_nodupcheck ) local cmd long fwrite
    else local cmd long write

    if ( `benchmarklevel' > 0 | `"`benchmark'"' != "" ) disp as txt "Writing reshape to disk:"
    if ( `"${GTOOLS_TEMPDIR}"' == "" ) {
        tempfile ReS_Data
    }
    else {
        GreshapeTempFile ReS_Data
    }
    mata: __greshape_w2l_meta = WideToLongMetaSave()
    global GTOOLS_CALLER greshape
    local gopts xij($ReS_Xij_names) xi($ReS_Xi) f(`ReS_Data') `string' `dropmissing'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts' missing
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------
    * Allocate space for long data
    * ----------------------------

    FreeTimer
    if ( `FreeTimer' ) timer on `FreeTimer'
    keep $ReS_i $ReS_Xij_keep $ReS_Xi
    * disp "debug: ($ReS_Xij_keep) ($ReS_Xij_keepnames)"
    mata __greshape_addtypes = ("`jtype'", J(1, `:word count $ReS_Xij_add', "double"))
    mata __greshape_addvars  = "$ReS_j", tokens(st_global("ReS_Xij_add"))
    mata (void) st_addvar(__greshape_addtypes, __greshape_addvars, 0)
    if ( (`"$ReS_Xij_keep"' != "") &(`"$ReS_Xij_keepnames"' != "") ) {
        rename ($ReS_Xij_keep) ($ReS_Xij_keepnames)
    }
    order $ReS_i $ReS_j $ReS_Xij_stubs $ReS_Xi
    if ( `"`dropmissing'"' != "" ) {
        * disp as txt "({bf:warning:} -dropmiss- will remove IDs with all missing values)"
        if ( `=scalar(__gtools_greshape_nrows)' <= `=_N' ) {
            qui keep in 1 / `=scalar(__gtools_greshape_nrows)'
        }
        else {
            qui set obs `=scalar(__gtools_greshape_nrows)'
        }
    }
    else {
        qui set obs `=_N * scalar(__greshape_klvls)'
        * qui expand `=scalar(__greshape_klvls)'
    }
    if ( `FreeTimer' ) {
        qui timer off `FreeTimer'
        qui timer list
        local s `:disp %9.3f `r(t`FreeTimer')''
        if ( `benchmarklevel' > 2 ) {
            disp _char(9) "reshape long step 4: allocated target dataset; `s' seconds."
        }
        timer clear `FreeTimer'
    }
    else if ( `benchmarklevel' > 2 ) {
        disp _char(9) "reshape long step 4: allocated target dataset; ??? seconds."
    }

    * ------------------
    * Read reshaped data
    * ------------------

    if ( `benchmarklevel' > 0 | `"`benchmark'"' != "" ) disp as txt _n "Reading reshape from disk:"
    local cmd long read
    global GTOOLS_CALLER greshape
    local gopts j($ReS_j) xij($ReS_Xij_stubs) xi($ReS_Xi) f(`ReS_Data') `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts' missing
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------------------
    * Finish in the same style as reshape.Long
    * ----------------------------------------

    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    /* Apply J value label and to variable label for LONG Format*/
    local isstr: copy global ReS_str
    local labn : char _dta[__JValLabName]
    if `"`labn'"' != "" & `"`isstr'"' == "0"  {
        local lab : char _dta[__JValLab]
        capture label define `labn' `lab'
        label values $ReS_j `labn'
        char define _dta[__JValLab] `""'
        char define _dta[__JValLabName] `""'
    }

    local jvlab : char _dta[__JVarLab]
    if `"`jvlab'"' != "" {
        label variable $ReS_j `"`jvlab'"'
        char define _dta[__JVarLab] `""'
    }

    * --------------------------------------------------
    * TODO: Is this of any value? Done in WideToLongMeta
    * --------------------------------------------------
    * /* Apply Xij variable label for LONG*/
    * local iii : char _dta[__XijVarLabTotal]
    * if `"`iii'"' == "" {
    *     local iii = -1
    * }
    * foreach var of global ReS_Xij_stubs {
    *     local var = subinstr(`"`var'"', `"$ReS_match"', "$ReS_atwl", 1)
    *     if (length(`"`var'"') < 21 ) {
    *         local xijlab : char _dta[__XijVarLab`var']
    *         if `"`xijlab'"' != "" {
    *             label variable `var' `"`xijlab'"'
    *             char define _dta[__XijVarLab`var'] `""'
    *         }
    *     }
    *     else {
    *         local ii = 1
    *         while `ii' <= `iii' {
    *             local xijlab : char _dta[__XijVarLab`ii']
    *             if (`"`xijlab'"' != "") {
    *                 local v =  ///
    *                 `substr'(`"`xijlab'"',1, ///
    *                 strpos(`"`xijlab'"', " ")-1)
    *                 if `"`v'"' == `"`var'"' {
    *                     local tlab :  ///
    *                     subinstr local ///
    *                     xijlab `"`v' "' ""
    *                     capture label variable ///
    *                     `var' `"`tlab'"'
    *                     capture char define ///
    *                     _dta[__XijVarLab`ii'] `""'
    *                     continue, break
    *                 }
    *             }
    *             local ii = `ii' + 1
    *         }
    *     }
    * }
    * --------------------------------------------------

    ReportL `oldobs' `oldvars'
    mata: WideToLongMetaApply(__greshape_w2l_meta)

    if ( "`fast'" == "" ) restore, not
end

* ---------------------------------------------------------------------
* Reshape wide

capture program drop Wide
program define Wide /* reshape wide */

    ***********************************************************************
    *                          Parse Wide Syntax                          *
    ***********************************************************************

    gettoken ReS_cmd 0: 0
    global ReS_cmd: copy local ReS_cmd
    global ReS_jname j
    global ReS_iname i

    local wide_opts            ///
        [                      ///
            i(varlist)         /// reshape by groups of -i()-
            by(varlist)        /// reshape by groups of -by()-
            j(varlist)         /// varnames by levels -j()-
            KEYs(varlist)      /// varnames by levels -key()-
            String             /// look for string-like names
            COLSeparate(str)   /// Columns sepparator for levels of j
            xi(str)            /// Handle extraneous variables
            fast               /// Do not preserve and restore the original dataset. Saves speed
            nochecks           /// Do not do any checks
            CHECKlevel(real 4) /// Check level
            nomisscheck        /// Do not check for missing values or blanks in j
            match(str)         /// a string (e.g. @) to match
            LABELFormat(str)   /// label format; default is '#keyvalue# #stublabel#'
            prefix(str)        /// a list with the variable prefix format. default
                               ///
                               ///     #stub# [#stub# #blank# ...]
                               ///
                               /// where #stub# simply uses the stub as the variable prefix.
                               /// @ syntax allowed. Examples of valid prefixes:
                               ///
                               ///     #stub# combo#stub# #stub#combo prefix mid@dle @suffix
                               ///
                               ///
            ${GTOOLS_PARSE}    ///
        ]

    local spread_opts        ///
        [                    ///
            j(varlist)       /// varnames by levels -j()-
            KEYs(varlist)    /// varnames by levels -key()-
            COLSeparate(str) /// Columns sepparator for levels of j
            by(varlist)      /// reshape by groups of -by()-
            i(varlist)       /// reshape by groups of -i()-
            xi(str)          /// Handle extraneous variables
            LABELFormat(str) /// label format; default is '#keyvalue# #stublabel#'
            prefix(str)      /// a list with the variable prefix format
            fast             /// Do not preserve and restore the original dataset. Saves speed
            ${GTOOLS_PARSE}  ///
        ]

    syntax anything(everything), ``ReS_cmd'_opts'
    local key: copy local keys

    * ------------------
    * Parse i, j aliases
    * ------------------

    if ( (`"`by'"' == "") & (`"`i'"' == "") & (`"`ReS_cmd'"' == "wide") ) {
        disp as err "option {opt i()} (grouping variable) required"
        exit 198
    }

    if ( (`"`by'"' != "") & (`"`i'"' != "") ) {
        disp as err "i() and by() are aliases for the same option; use only one"
        exit 198
    }
    else if ( `"`by'"' != "" ) {
        global ReS_iname by
        local i: copy local by
    }

    if ( (`"`key'"' == "") & (`"`j'"' == "") ) {
        if ( `"`ReS_cmd'"' == "spread" ) {
            disp as err "option {opt key:s()} required"
        }
        else {
            disp as err "option {opt j()} (keys) required"
        }
        exit 198
    }
    if ( (`"`key'"' != "") & (`"`j'"' != "") ) {
        disp as err "j() and keys() are aliases for the same option; use only one"
        exit 198
    }
    else if ( `"`key'"' != "" ) {
        global ReS_jname keys
        local j: copy local key
    }

    * -------------------
    * Parse other options
    * -------------------

    c_local 0 `ReS_cmd' `anything', i(`i') j(`j') `string'
    if ( `"`checklevel'"' == "" ) local checklevel 4

    if ( `checklevel' > 3 ) {
    }
    else if ( `checklevel' > 2 ) {
        local misscheck nomisscheck
    }
    else if ( `checklevel' > 1 ) {
        local fast      fast
        local misscheck nomisscheck
    }
    else if ( `checklevel' > 0 ) {
        local fast      fast
        local unsorted  unsorted
        local misscheck nomisscheck
    }
    else if ( `checklevel' == 0 ) {
        local checks nochecks
    }

    if ( `"`checks'"' == "nochecks" ) {
        local fast      fast
        local unsorted  unsorted
        local misscheck nomisscheck
    }

    if ( `"`ReS_cmd'"' == "spread" ) {
        local misscheck nomisscheck
        global ReS_jname keys
    }

    if ( "`fast'" == "" ) preserve

    if ( `"`match'"' == "" ) local match @

    if ( `"`labelformat'"' == "" ) {
        local labelformat #keyvalue# #stublabel#
    }
    else if ( `:list sizeof j' > 1 ) {
        disp as txt "(warning: labelformat() ignored with multiple $ReS_jname() variables)"
    }

    global ReS_atwl   `atwl'
    global ReS_match  `match'
    global ReS_Xij    `anything'
    global ReS_Xij_k  `:list sizeof anything'
    global ReS_jsep:  copy local colseparate
    global ReS_labelformat: copy local labelformat

    * This defines $ReS_Xij_stubs and potentially overwrites ReS_Xij
    ParseStubsByMatch wide

    * This is mainly for spread; i are all the excluded variables
    unab oldlist: _all
    unab ReS_Xij_stubs: $ReS_Xij_stubs
    local restvars: list oldlist - ReS_Xij_stubs
    local restvars: list restvars - j
    if ( `"`i'"' == "" ) {
        local i: copy local restvars
        if ( `"`xi'"' != "" ) {
            disp as txt "(note: -xi()- ignored without -$ReS_iname()-)"
        }
    }
    else {
        unab i: `i'
    }

    global ReS_j `j'
    global ReS_i `i'

    * If there are multiple prefixes, you must specify the same number
    * of prefixes as stubs; otherwise the prefix is taken for every
    * variable

    local ReS_Xij_stubs: copy global ReS_Xij_stubs
    local ReS_prefix:    copy local prefix

    local k1: list sizeof prefix
    local k2: list sizeof ReS_Xij_stubs
    if ( `k1' > 1 ) {
        if ( `k1' != `k2' ) {
            disp as err `"mismatch: `k1' prefixes for `k2' stubs"'
            exit 198
        }
    }
    else if ( (`k1' == 1) & (`k2' > 1) ) {
        local ReS_prefix
        forvalues kk = 1 / `k2' {
            local ReS_prefix `ReS_prefix' `prefix'
        }
    }
    global ReS_prefix: copy local ReS_prefix

    * Cannot have multiple stubs with the same name
    if ( `"`:list uniq ReS_Xij_stubs'"' != `"`ReS_Xij_stubs'"' ) {
        disp as err `"repeated variables not allowed"'
        exit 198
    }

    * Check that the spread call is sane

    if ( `"`ReS_cmd'"' == "spread" ) {
        cap assert `:list i == restvars'
        if ( _rc & (`"`xi'"' != "drop") ) {
            disp as err "greshape spread does not allow extraneous variables (Xi):"
            disp as err ""
            disp as err "    Xij -> $ReS_Xij"
            disp as err "    $ReS_jname   -> $ReS_j"
            disp as err "    $ReS_iname   -> $ReS_i"
            disp as err "    Xi  -> `:list restvars - i'"
            disp as err ""
            disp as err "Specify xi(drop), leave $ReS_iname() blank, or include Xi somewhere in the reshape."
            exit 198
        }
    }

    * gtools options!

    cap confirm str var `j'
    global ReS_str = (_rc == 0)

    local opts `unsorted'              ///
               `compress'              ///
               `forcestrl'             ///
               `verbose'               ///
               `_ctolerance'           ///
               `benchmark'             ///
               bench(`benchmarklevel') ///
               `oncollision'           ///
               `hashmethod'            ///
               `debug'

    global ReS_nodupcheck  = 0
    global ReS_nomisscheck = ( `"`misscheck'"' == "nomisscheck" )
    if ( "`unsorted'" == "unsorted" ) {
        disp as txt "(note: reshape left unsorted; original order not preserved)"
    }

    if ( `"`string'"' != "" ) {
        disp as txt "Option -string- ignored with {cmd:greshape wide}"
        local string
    }

    local oldobs = _N
    quietly describe, short
    local oldvars = r(k)

    ***********************************************************************
    *                         Macros and J values                         *
    ***********************************************************************

    Macros wide
    local rc = 0
    foreach var in $ReS_j {
        capture ConfVar `var'
        if ( _rc ) {
            di in blu "Source $ReS_jname(`var') does not exist (is the data already wide?)"
            exit 198
        }
        ConfVar `var'
    }
    confirm var $ReS_j $rVANS $ReS_i $ReS_Xi

    if ( `:list sizeof j' > 1 ) {
        disp as txt "({bf:warning}: labels of $ReS_jname() not saved with multiple variables)"
    }
    else {
        /* Save J value and variable label for LONG */
        local jlab : value label $ReS_j
        if "`jlab'" != "" {
            char define _dta[__JValLabName] `"`jlab'"'
            capture label list `jlab'
            if _rc == 0 & !missing(`r(min)') & !missing(`r(max)') {
                forvalues i = `r(min)'/`r(max)' {
                    local label : label `jlab' `i',  strict
                    if `"`label'"' != "" {
                        local char `"`char' `i' `"`label'"' "'
                    }
                }
                char define _dta[__JValLab] `"`char'"'
            }
        }
        local jvlab : variable label $ReS_j
        if `"`jvlab'"' != "" {
            char define _dta[__JVarLab] `"`jvlab'"'
        }
    }

    * --------------------------------------------------
    * TODO: Is this of any value? Done in LongToWideMeta
    * --------------------------------------------------
    * /* Save xij variable labels for LONG */
    * local iii = 1
    * foreach var of global ReS_Xij {
    *     local var = subinstr(`"`var'"', `"$ReS_match"', "$ReS_atwl", 1)
    *     local xijlab : variable label `var'
    *     if `"`xijlab'"' != "" {
    *         if (length(`"`var'"') < 21) {
    *             char define _dta[__XijVarLab`var'] `"`xijlab'"'
    *         }
    *         else {
    *             char define _dta[__XijVarLab`iii'] ///
    *                 `"`var' `xijlab'"'
    *             char define _dta[__XijVarLabTotal] `"`iii'"'
    *             local iii = `iii' + 1
    *         }
    *     }
    * }
    * --------------------------------------------------

    tempvar ReS_jcode
    if ( `"${GTOOLS_TEMPDIR}"' == "" ) {
        tempfile ReS_jfile
    }
    else {
        GreshapeTempFile ReS_jfile
    }
    global ReS_jcode: copy local ReS_jcode
    global ReS_jfile: copy local ReS_jfile
    scalar __greshape_jfile = length(`"`ReS_jfile'"') + 1

    GetJLevels
    foreach var in $ReS_j {
        ConfVar `var'
    }
    confirm var $ReS_j $ReS_Xi
    local ReS_Xi: copy global ReS_Xi
    local ReS_Xi: list ReS_Xi - ReS_jcode
    global ReS_Xi: copy local ReS_Xi

    if ( inlist(`"`xi'"', "keep", "") ) {
    }
    else if ( `"`xi'"' == "drop" ) {
        global ReS_Xi
    }
    else {
        disp as err `"Invalid sytax -xi(`xi')-; specify first, keep, drop"'
        exit 198
    }

    if ( `"`ReS_cmd'"' == "spread" & `"${ReS_Xi}"' != "" ) {
        disp as err "Error parsing varlist. xi() should be blank"
        exit 198
    }

    GetXiTypes
    CopyScalars

    ***********************************************************************
    *                           Do the reshape                            *
    ***********************************************************************

    * ------------------------
    * Reshape the data to disk
    * ------------------------

    if ( `benchmarklevel' > 0 | `"`benchmark'"' != "" ) disp as txt "Writing reshape to disk:"
    local cmd wide write
    keep $ReS_i $ReS_j $ReS_jcode $ReS_Xi $rVANS
    if ( `"${GTOOLS_TEMPDIR}"' == "" ) {
        tempfile ReS_Data
    }
    else {
        GreshapeTempFile ReS_Data
    }
    * disp "debug 1: $ReS_Xij"
    mata: __greshape_l2w_meta = LongToWideMetaSave(`"$ReS_cmd"' == "spread")
    global GTOOLS_CALLER greshape
    local gopts j($ReS_jcode) xij($rVANS) xi($ReS_Xi) f(`ReS_Data') `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts' missing
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------
    * Allocate space for wide data
    * ----------------------------

    qui keep in 1 / `:di %32.0f `r(J)''
    global S_FN
    global S_FNDATE

    FreeTimer
    if ( `FreeTimer' ) timer on `FreeTimer'
    rename ($ReS_Xij_keep) ($ReS_Xij_keepnames)
    mata __greshape_addtypes = tokens(st_global("ReS_Xij_addtypes"))
    mata __greshape_addvars  = tokens(st_global("ReS_Xij_addvars"))
    mata (void) st_addvar(__greshape_addtypes, __greshape_addvars, 0)
    keep  $ReS_i $ReS_Xij_names $ReS_Xi
    order $ReS_i $ReS_Xij_names $ReS_Xi
    if ( `FreeTimer' ) {
        qui timer off `FreeTimer'
        qui timer list
        local s `:disp %9.3f `r(t`FreeTimer')''
        if ( `benchmarklevel' > 2 ) {
            disp _char(9) "reshape wide step 4: allocated target dataset; `s' seconds."
        }
        timer clear `FreeTimer'
    }
    else if ( `benchmarklevel' > 2 ) {
        disp _char(9) "reshape wide step 4: allocated target dataset; ??? seconds."
    }

    * ------------------
    * Read reshaped data
    * ------------------

    if ( `benchmarklevel' > 0 | `"`benchmark'"' != "" ) disp as txt _n "Reading reshape from disk:"
    local cmd wide read
    global GTOOLS_CALLER greshape
    local gopts xij($ReS_Xij_names) xi($ReS_Xi) f(`ReS_Data') `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts' missing
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------------------
    * Finish in the same style as reshape.Wide
    * ----------------------------------------

    ReportW `oldobs' `oldvars'
    mata: LongToWideMetaApply(__greshape_l2w_meta, `"$ReS_cmd"' == "spread")

    if ( "`fast'" == "" ) restore, not
end

* ---------------------------------------------------------------------
* Stub matches

capture program drop ParseStubsByMatch
program ParseStubsByMatch
    if ( inlist(`"$ReS_match"', "regex", "ustrregex") ) {
        if ( `"`1'"' != "long" ) {
            disp as err `"match($ReS_match) only allowed when reshaping wide to long"'
            exit 198
        }

        unab allvars: _all
        local ReS_Xi
        local ReS_Xij_regex
        local ReS_Xij_stubs
        if ( `"$ReS_match"' == "ustrregex" ) {
            cap disp ustrregexm("a", "a")
            if ( _rc ) {
                disp as err "ustrregex is only available in Stata 14+"
                exit 198
            }
            foreach stub of global ReS_Xij {
                local any 0
                local rep 0
                if ( `"`group'"' == "" ) local group 1
                foreach var of varlist `allvars' {
                    if ustrregexm(`"`var'"', `"`stub'"') {
                        local new `=ustrregexrf(`"`var'"', `"`stub'"', "@")'
                        if ( !`:list new in ReS_Xij' ) {
                            local ReS_Xij       `ReS_Xij'       `=ustrregexrf(`"`var'"', `"`stub'"', "@")'
                            local ReS_Xij_regex `ReS_Xij_regex' `stub'
                            local ReS_Xij_stubs `ReS_Xij_stubs' `=ustrregexrf(`"`var'"', `"`stub'"', "")'
                            local any 1
                        }
                        else {
                            local rep 1
                        }
                        * disp `"`var'"', `"`stub'"', `any'
                    }
                }
                if ( `any' == 0 ) {
                    if ( `rep' ) {
                        disp as err "no new variables matched regex: `stub' (you probably have repeated stubs)"
                        exit 198
                    }
                    else {
                        disp as err "no variables matched stub regex: `stub'"
                        exit 198
                    }
                }
            }
        }
        else {
            foreach stub of global ReS_Xij {
                local any 0
                local rep 0
                gettoken stub  group: stub,  p(/)
                gettoken slash group: group, p(/)
                local group `group'
                if ( `"`group'"' == "" ) local group 1
                foreach var of varlist `allvars' {
                    if regexm(`"`var'"', `"`stub'"') {
                        cap local rg = regexs(`group')
                        if ( `"`rg'"' != "" ) {
                            local new `=regexr(`"`var'"', `"`rg'"', "@")'
                            if ( !`:list new in ReS_Xij' ) {
                                local ReS_Xij       `ReS_Xij'       `=regexr(`"`var'"', `"`rg'"', "@")'
                                local ReS_Xij_regex `ReS_Xij_regex' `stub'
                                local ReS_Xij_stubs `ReS_Xij_stubs' `=regexr(`"`var'"', `"`rg'"', "")'
                                local any 1
                            }
                            else {
                                local rep 1
                            }
                        }
                    }
                    * disp `"`var'"', `"`stub'"', `any'
                }
                if ( `any' == 0 ) {
                    if ( `rep' ) {
                        disp as err "no new variables matched regex: `stub' (you probably have repeated stubs)"
                        exit 198
                    }
                    else {
                        disp as err "no variables matched stub regex: `stub'"
                        exit 198
                    }
                }
            }
        }

        global ReS_match @
        global ReS_Xij:       copy local ReS_Xij
        global ReS_Xij_regex: copy local ReS_Xij_regex
        global ReS_Xij_stubs: copy local ReS_Xij_stubs

    }
    else {
        global ReS_Xij_stubs: subinstr global ReS_Xij `"$ReS_match"' "", all
        if ( `"`1'"' == "wide" ) {
            local ReS_Xij
            local ReS_Xij_stubs
            foreach stub of global ReS_Xij {
                local var: subinstr local stub `"$ReS_match"' ""
                unab vars: `var'
                if ( index(`"`stub'"', `"$ReS_match"') & (`"`var'"' != `"`vars'"') ) {
                    disp as err "error parsing stubs; cannot specify a custom match with varlist syntax"
                    exit 198
                }
                else if ( index(`"`stub'"', `"$ReS_match"') == 0 ) {
                    foreach var of local vars {
                        local ReS_Xij `ReS_Xij' `var'
                    }
                }
                else {
                    local ReS_Xij `ReS_Xij' `stub'
                }
                foreach var of local vars {
                    local ReS_Xij_stubs `ReS_Xij_stubs' `var'
                }
            }
            global ReS_Xij:       copy local ReS_Xij
            global ReS_Xij_stubs: copy local ReS_Xij_stubs
        }
    }

    * disp "$ReS_Xij"
    * disp "$ReS_Xij_stubs"
    * disp "$ReS_Xij_regex"
end

* ---------------------------------------------------------------------
* GetJLevels

capture program drop GetJLevels
program define GetJLevels

    * ---------------------------
    * TODO: Is this of any value?
    * ---------------------------
    * local varlist "req ex"
    * parse "_all"
    * {
    *     local n : word count `varlist'
    *     local __greshape_dsname
    *     parse "`varlist'", parse(" ")
    *     local i 0
    *     while `++i' <= `n' {
    *         disp `"`i', ``i''"'
    *         local __greshape_dsname `"`__greshape_dsname'"' `"``i''"'
    *     }
    * }
    * mata: __greshape_dsname = tokens(st_local("__greshape_dsname"))'
    * ---------------------------

    unab varlist: _all
    mata: __greshape_dsname = tokens(st_local("varlist"))'

    if inlist("$ReS_cmd", "wide") {
        FillvalL
        FillXi 1
    }
    else if inlist("$ReS_cmd", "spread" ) {
        FillvalL
    }
    else if inlist("$ReS_cmd", "long") {
        FillvalW
        FillXi 0
    }
    else if inlist("$ReS_cmd", "gather") {
        FillvalW
    }
    else {
        disp as err "Uknown subcommand: $ReS_cmd"
        exit 198
    }

    global S_1 1
end

capture program drop FillvalW
program define FillvalW
    tempname jlen
    mata: `jlen' = 0
    if ( "$ReS_cmd" != "gather" ) {
        FindVariablesByCharacter

        capture mata: assert(all(__greshape_res :== ""))
        if _rc == 0 {
            no_xij_found
            /* NOTREACHED */
        }

        if ( !$ReS_str ) {
            mata: __greshape_res = strtoreal(__greshape_res)
            mata: __greshape_sel = selectindex(__greshape_res :< .)
        }
        else {
            mata: __greshape_sel = selectindex(__greshape_res :!= "")
        }

        mata: __greshape_res = sort(uniqrows(__greshape_res[__greshape_sel]), 1)
        mata: st_numscalar("__greshape_kout",  cols(tokens(st_global(`"ReS_Xij"'))))
        mata: st_numscalar("__greshape_klvls", rows(__greshape_res))
        if ( `=(__greshape_klvls)' == 0 ) {
            disp as err "variable j contains all missing values"
            exit 498
        }

        if ( !$ReS_str ) {
            mata: SaveJValuesReal(__greshape_res)
            mata: __greshape_res = strofreal(__greshape_res)
        }
        else {
            mata: (void) SaveJValuesString(__greshape_res, "")
        }
        mata: __greshape_xijname = sort(uniqrows(__greshape_dsname[__greshape_sel]), 1)
    }
    else {
        mata: __greshape_res = tokens(st_global("ReS_Xij_names"))'
        mata: st_numscalar("__greshape_kout",  cols(tokens(st_global(`"ReS_Xij"'))))
        mata: st_numscalar("__greshape_klvls", rows(__greshape_res))
        if ( `=(__greshape_klvls)' == 0 ) {
            disp as err "variable j contains all missing values"
            exit 498
        }

        if ( `"$ReS_uselabels"' != "" ) {
            local 0: copy global ReS_uselabels
            cap syntax varlist, [exclude]
            if ( _rc ) {
                disp as err "option uselabels[()] incorrectly specified"
                syntax varlist, [exclude]
                exit 198
            }
            else {
                if ( `"`exclude'"' != "" ) {
                    unab ReS_uselabels: _all
                    local ReS_uselabels: list ReS_uselabels - varlist
                    global ReS_uselabels: copy local ReS_uselabels
                }
                else {
                    global ReS_uselabels: copy local varlist
                }
            }
        }

        mata: `jlen' = SaveJValuesString(__greshape_res, tokens(`"${ReS_uselabels}"')) - 1
        mata: __greshape_xijname = __greshape_res
    }

    mata: __greshape_maplevel = MakeMapLevel( /*
        */ __greshape_xijname,                /*
        */ __greshape_res,                    /*
        */ tokens(st_global(`"ReS_Xij"')),    /*
        */ (`"$ReS_cmd"' == "gather"))

    mata: st_matrix("__greshape_maplevel", __greshape_maplevel)

    mata: __greshape_rc = CheckVariableTypes(    /*
        */ tokens(st_global(`"ReS_Xij_names"')), /*
        */ __greshape_res,                       /*
        */ tokens(st_global(`"ReS_Xij"')),       /*
        */ tokens(st_global(`"ReS_Xij_stubs"')), /*
        */ (`"$ReS_cmd"' == "gather"))

    mata: st_numscalar("__greshape_rc", __greshape_rc)
    if ( `=scalar(__greshape_rc)' ) {
        mata: mata drop `jlen'
        exit 198
    }

    scalar __greshape_nrows = .
    scalar __greshape_ncols = .

    mata: st_global("ReS_jv",   invtokens(__greshape_res'))
    mata: st_global("ReS_jlen", strofreal(`jlen' > 0? `jlen': max(strlen(__greshape_res))))
    mata: mata drop `jlen'

    di in gr "(note: $ReS_jname = $ReS_jv)"
    global ReS_jv2: copy global ReS_jv
end

capture program drop FindVariablesByCharacter
program FindVariablesByCharacter
    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    cap mata ustrregexm("a", "a")
    if ( _rc ) local regex regex
    else local regex ustrregex

    local ReS_Xij_regex: copy global ReS_Xij_regex

    parse "$ReS_Xij", parse(" ")
    local i 1
    mata: __greshape_res = J(rows(__greshape_dsname), 1, "")
    mata: __greshape_u   = J(rows(__greshape_dsname), 1, "")
    while "``i''" != "" {
        gettoken exp ReS_Xij_regex: ReS_Xij_regex

        local m    = length(`"$ReS_match"')
        local _l   = index("``i''", `"$ReS_match"')
        local l    = cond(`_l' == 0, length("``i''") + 1, `_l')
        local lft  = `substr'("``i''", 1, `l' - 1)
        local rgt  = `substr'("``i''", `l' + `m', .)
        local rgtl = length("`rgt'")
        local minl = length("`lft'") + `rgtl'

        if ( `"`exp'"' == "" ) {
            mata: __greshape_u = selectindex( /*
                */ (strlen(__greshape_dsname) :> `minl') :& /*
                */ (`substr'(__greshape_dsname, 1, `l' - 1) :== `"`lft'"') :& /*
                */ (`substr'(__greshape_dsname, -`rgtl', .) :== `"`rgt'"'))
        }
        else {
            mata: __greshape_u = selectindex( /*
                */ (strlen(__greshape_dsname) :> `minl') :& /*
                */ (`substr'(__greshape_dsname, 1, `l' - 1) :== `"`lft'"') :& /*
                */ (`substr'(__greshape_dsname, -`rgtl', .) :== `"`rgt'"') :& /*
                */ (`regex'm(__greshape_dsname, `"`exp'"')))
        }

        mata: st_local("any", strofreal(length(__greshape_u) > 0))
        if ( `any' ) {
            mata: __greshape_res[__greshape_u] = `substr'( /*
                */ __greshape_dsname[__greshape_u], `l', .)

            mata: __greshape_res[__greshape_u] = `substr'( /*
                */ __greshape_res[__greshape_u], 1, /*
                */ strlen(__greshape_res[__greshape_u]) :- `rgtl')

            capture mata: assert(all(__greshape_res[__greshape_u] :!= ""))
        }
        else cap error 0

        if _rc {
            di in red as smcl ///
            "variable {bf:`lft'`rgt'} already defined"
            exit 110
        }
        local i = `i' + 1
    }
end

capture mata: mata drop MakeMapLevel()
capture mata: mata drop GetVariableFromStub()
capture mata: mata drop GetVariableFromStubPrefix()
mata:
real matrix function MakeMapLevel(
    string colvector dsname,
    string colvector res,
    string rowvector xij,
    real scalar gather)
{
    real scalar i, j, k, l
    real matrix maplevel
    string rowvector ordered
    string scalar sr

    k = 1
    ordered  = J(1, cols(xij) * rows(res), "")
    maplevel = J(cols(xij), rows(res), 0)

    for (i = 1; i <= cols(xij); i++) {
        for (j = 1; j <= rows(res); j++) {
            sr = gather? res[j]: GetVariableFromStub(xij[i], res[j])
            if ( any(dsname :== sr) ) {
                maplevel[i, j] = k
                ordered[k] = sr
                k++
            }
        }
    }

    st_global("ReS_Xij_names", invtokens(ordered))
    st_numscalar("__greshape_kxij", cols(ordered))
    return(maplevel)
}

string scalar function GetVariableFromStub(string scalar s, string scalar r)
{
    real scalar l, m
    string scalar left, right

    m = strlen(st_global(`"ReS_match"'))
    l = strpos(s, st_global(`"ReS_match"'))
    l = (l == 0)? strlen(s) + 1: l
    left  = substr(s, 1, l - 1)
    right = substr(s, l + m, .)
    return(left + r + right)
}

string scalar function GetVariableFromStubPrefix(
    string scalar stub,
    string scalar level,
    string scalar prefix)
{
    real scalar l, m
    string scalar left, right, out

    s = subinstr(prefix, "#blank#", "",   .)
    s = subinstr(s,      "#stub#",  stub, .)

    m = strlen(st_global(`"ReS_match"'))
    l = strpos(s, st_global(`"ReS_match"'))
    l = (l == 0)? strlen(s) + 1: l
    left  = substr(s, 1, l - 1)
    right = substr(s, l + m, .)
    return(left + level + right)
}

end

cap mata ustrregexm("a", "a")
if ( _rc ) local regex regex
else local regex ustrregex

capture mata: mata drop CheckVariableTypes()
mata:
real scalar function CheckVariableTypes(
    string rowvector dsname,
    string colvector res,
    string rowvector xij,
    string rowvector xij_stubs,
    real scalar gather)
{
    real scalar i, j, k, t, ix
    real colvector sel
    real rowvector types
    string colvector keep
    string colvector keepnames
    string colvector add
    string scalar sr, v

    k = 0
    types = J(1, cols(dsname), 0)
    highest = J(cols(xij), 2, 0)
    for (i = 1; i <= cols(xij); i++) {
        for (j = 1; j <= rows(res); j++) {
            sr = gather? res[j]: GetVariableFromStub(xij[i], res[j])
            ix = selectindex(dsname :== sr)
            t  = highest[i, 1]
            if ( length(ix) > 1 ) {
                errprintf("stub %s had repeated matches (do you have repeated stubs?)\n",
                          xij[i])
                return(198)
            }
            else if ( length(ix) ) {
                v = st_vartype(sr)
                if ( `regex'm(v, "str([1-9][0-9]*|L)") ) {
                    if ( t > 0 ) {
                        errprintf("%s type mismatch with other %s variables\n",
                                  sr, xij[i])
                        return(198)
                    }
                    l = `regex's(1)
                    if ( l == "L" ) {
                        errprintf("strL variables not supported\n")
                        return(198)
                    }
                    if ( t > -strtoreal(l) ) {
                        highest[i, 1] = -strtoreal(l)
                        highest[i, 2] = ix
                    }
                    types[ix] = strtoreal(l)
                }
                else {
                    if ( v == "byte" ) {
                        types[ix] = 0
                        if ( t < 1 ) {
                            highest[i, 1] = 1
                            highest[i, 2] = ix
                        }
                    }
                    else if ( v == "int" ) {
                        types[ix] = 0
                        if ( t < 2 ) {
                            highest[i, 1] = 2
                            highest[i, 2] = ix
                        }
                    }
                    else if ( v == "long" ) {
                        types[ix] = 0
                        if ( t < 3 ) {
                            highest[i, 1] = 3
                            highest[i, 2] = ix
                        }
                        if ( t == 4 ) {
                            highest[i, 1] = .
                            highest[i, 2] = .
                        }
                    }
                    else if ( v == "float" ) {
                        types[ix] = 0
                        if ( t < 2 ) {
                            highest[i, 1] = 4
                            highest[i, 2] = ix
                        }
                        if ( t == 3 ) {
                            highest[i, 1] = .
                            highest[i, 2] = .
                        }
                    }
                    else if ( v == "double" ) {
                        types[ix] = 0
                        highest[i, 1] = 5
                        highest[i, 2] = ix
                    }
                    else {
                        errprintf("unknown variable type: %s\n", v)
                        return(198)
                    }
                }
            }
        }
    }

    sel       = highest[., 2]
    keepnames = xij_stubs[selectindex(sel :!= .)]
    keep      = dsname[sel[selectindex(sel :!= .)]]
    add       = xij_stubs[selectindex(sel :== .)]

    st_matrix("__greshape_types", types)

    st_global("ReS_Xij_keepnames", invtokens(keepnames))
    st_global("ReS_Xij_keep",      invtokens(keep))
    st_global("ReS_Xij_add",       invtokens(add))

    return(0)
}
end

capture mata: mata drop SaveJValuesReal()
capture mata: mata drop SaveJValuesString()
mata:
void function SaveJValuesReal(real colvector res)
{
    real scalar i, fh
    colvector C
    fh = fopen(st_global("ReS_jfile"), "w")
    C  = bufio()
    for(i = 1; i <= rows(res); i++) {
        fbufput(C, fh, "%8z", res[i])
    }
    fclose(fh)
}

real scalar function SaveJValuesString(string colvector res, string rowvector uselabelsvars)
{
    real scalar i, fh, max, uselabels
    string scalar fmt, vlbl
    string colvector reslbl
    colvector C

    uselabels = length(uselabelsvars) > 0

    fh = fopen(st_global("ReS_jfile"), "w")
    C  = bufio()
    if ( uselabels ) {
        reslbl = J(rows(res), 1, "")
        for(i = 1; i <= rows(res); i++) {
            if ( length(selectindex(res[i] :== uselabelsvars)) > 0 ) {
                vlbl = st_varlabel(res[i])
                reslbl[i] = (strtrim(vlbl) == "")? res[i]: vlbl
            }
            else {
                reslbl[i] = res[i]
            }
        }
        max = max(strlen(reslbl)) + 1
        fmt = sprintf("%%%gS", max)
        for(i = 1; i <= rows(reslbl); i++) {
            fbufput(C, fh, fmt, reslbl[i] + (max - strlen(reslbl[i])) * char(0))
        }
    }
    else {
        max = max(strlen(res)) + 1
        fmt = sprintf("%%%gS", max)
        for(i = 1; i <= rows(res); i++) {
            fbufput(C, fh, fmt, res[i] + (max - strlen(res[i])) * char(0))
        }
    }
    fclose(fh)

    return(max)
}
end

capture program drop no_xij_found
program no_xij_found
    di as smcl in red "no xij variables found"
    di as smcl in red "{p 4 4 2}"
    di as smcl in red "You typed something like"
    di as smcl in red "{bf:reshape wide a b, $ReS_iname(i) $ReS_jname(j)}.{break}"
    di as smcl in red "{bf:reshape} looked for existing variables"
    di as smcl in red "named {bf:a}{it:#} and {bf:b}{it:#} but"
    di as smcl in red "could not find any.  Remember this picture:"
    di as smcl in red
    picture err cmds
    exit 111
end

capture program drop FillvalL
program define FillvalL
    cap mata bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr
    local ReS_j: copy global ReS_j

    if ( `"$ReS_jsep"' == "" ) local ReS_jsep `" "'
    else local ReS_jsep: copy global ReS_jsep

    if ( `:list sizeof ReS_j' > 1 ) local clean clean
    glevelsof $ReS_j, silent local(ReS_jv) cols(`"`ReS_jsep'"') group($ReS_jcode) missing `clean'
    scalar __greshape_klvls = `r(J)'
    mata: st_global("ReS_jvraw", st_local("ReS_jv"))

    if ( ("$ReS_cmd" != "spread") | ($ReS_Xij_k > 1) ) {
        mata: __greshape_jv = strtoname("_" :+ tokens(st_local("ReS_jv"))')
        mata: __greshape_jv = `substr'(__greshape_jv, 2, strlen(__greshape_jv))
    }
    else {
        mata: __greshape_jv = strtoname(tokens(st_local("ReS_jv"))')
    }

    * Not sure if blank selectindex is 1 by 0 or 0 by 1 or 0 by 0
    mata: __greshape_jv_ = selectindex(__greshape_jv :== "")
    mata: st_numscalar("__greshape_jv_", /*
        */ min((rows(__greshape_jv_), cols(__greshape_jv_))))
    if ( `=scalar(__greshape_jv_)' ) {
        mata: __greshape_jv[__greshape_jv_] = J(1, rows(__greshape_jv_), "_")
    }

    mata: st_global("ReS_jv", invtokens(__greshape_jv'))
    cap mata: assert(sort(__greshape_jv, 1) == sort(uniqrows(__greshape_jv), 1))
    if _rc {
        disp as err "j defines non-unique or invalid names"
        exit 198
    }

    * mata: (void) SaveJValuesString(__greshape_jv, "")
    di in gr "(note: $ReS_jname = $ReS_jv)"
    global ReS_jv2: copy global ReS_jv

    CheckVariableTypes
end

capture program drop CheckVariableTypes
program CheckVariableTypes
    cap disp ustrregexm("a", "a")
    if ( _rc ) local regex regex
    else local regex ustrregex

    local i: copy global rVANS
    local k: copy global ReS_Xij
    local j: copy global ReS_jv
    local p: copy global ReS_prefix
    gettoken j1 jrest: j

    global ReS_Xij_keep: copy global rVANS
    global ReS_Xij_keepnames

    global ReS_Xij_names
    global ReS_Xij_addvars
    global ReS_Xij_addtypes

    if ( ("$ReS_cmd" != "spread") | ($ReS_Xij_k > 1) ) {

        * Allow for custom user-defined prefixes and such. This is
        * useful in gather but in wide it's basically a convoluted
        * rename scheme...

        foreach stub of local k {
            gettoken var    i: i
            gettoken prefix p: p

            local prefix `prefix'
            if ( `"`prefix'"' != "" ) {
                local prefix: subinstr local prefix `"#blank#"' `""'
                local prefix: subinstr local prefix `"#stub#"'  `"`stub'"'
                local stub: copy local prefix
            }

            if ( index(`"`stub'"', `"$ReS_match"') > 0 ) {
                local _var: subinstr local stub `"$ReS_match"' `"`j1'"'
            }
            else {
                local _var `stub'`j1'
            }

            global ReS_Xij_keepnames $ReS_Xij_keepnames `_var'
            global ReS_Xij_names     $ReS_Xij_names     `_var'

            foreach jv of local jrest {

                if ( index(`"`stub'"', `"$ReS_match"') > 0 ) {
                    local _var: subinstr local stub `"$ReS_match"' `"`jv'"'
                }
                else {
                    local _var `stub'`jv'
                }

                global ReS_Xij_addtypes $ReS_Xij_addtypes `:type `var''
                global ReS_Xij_addvars  $ReS_Xij_addvars  `_var'
                global ReS_Xij_names    $ReS_Xij_names    `_var'
            }
        }
    }
    else {

        * Allow for custom user-defined prefixes and such. This is
        * useful in gather but in wide it's basically a convoluted
        * rename scheme...

        foreach var of local i {

            local stub:   copy local k
            local prefix: copy local p

            local prefix `prefix'
            if ( `"`prefix'"' != "" ) {
                local prefix: subinstr local prefix `"#blank#"' `""'
                local prefix: subinstr local prefix `"#stub#"'  `"`stub'"'
                local stub: copy local prefix
            }
            else local stub

            if ( index(`"`stub'"', `"$ReS_match"') > 0 ) {
                local _var: subinstr local stub `"$ReS_match"' `"`j1'"'
            }
            else {
                local _var `stub'`j1'
            }

            global ReS_Xij_keepnames $ReS_Xij_keepnames `_var'
            global ReS_Xij_names     $ReS_Xij_names     `_var'

            foreach jv of local jrest {

                if ( index(`"`stub'"', `"$ReS_match"') > 0 ) {
                    local _var: subinstr local stub `"$ReS_match"' `"`jv'"'
                }
                else {
                    local _var `stub'`jv'
                }

                global ReS_Xij_addtypes $ReS_Xij_addtypes `:type `var''
                global ReS_Xij_addvars  $ReS_Xij_addvars  `_var'
                global ReS_Xij_names    $ReS_Xij_names    `_var'
            }
        }
    }

    scalar __greshape_kout     = `:list sizeof k'
    scalar __greshape_kxij     = `:list sizeof k' * `:list sizeof j'
    scalar __greshape_nrows    = .
    scalar __greshape_ncols    = .
    matrix __greshape_maplevel = 0

    local __greshape_types
    capture matrix drop __greshape_types
    foreach var of varlist $rVANS {
        if ( `regex'm("`:type `var''", "str([1-9][0-9]*|L)") ) {
            if ( `regex's(1) == "L" ) {
                disp as err "Unsupported type `:type `var''"
                exit 198
            }
            local __greshape_types `__greshape_types' `=`regex's(1)'
            * matrix __greshape_types = nullmat(__greshape_types), `=`regex's(1)'
        }
        else if ( inlist("`:type `var''", "byte", "int", "long", "float", "double") ) {
            local __greshape_types `__greshape_types' 0
            * matrix __greshape_types = nullmat(__greshape_types), 0
        }
        else {
            disp as err "Unknown type `:type `var''"
            exit 198
        }
    }
    mata: st_matrix("__greshape_types", /*
        */ strtoreal(tokens(st_local("__greshape_types"))))
end

capture program drop FillXi
program define FillXi /* {1|0} */ /* 1 if islong currently */
    local islong `1'
    if `islong' { /* long to wide */
        unab ReS_Xi:   _all
        unab ReS_i:    $ReS_i
        unab ReS_j:    $ReS_j
        unab ReS_Xij:  $rVANS
        local ReS_Xi:  list ReS_Xi - ReS_i
        local ReS_Xi:  list ReS_Xi - ReS_j
        local ReS_Xi:  list ReS_Xi - ReS_Xij
        global ReS_Xi: copy local ReS_Xi
    }
    else { /* wide to long */
        unab ReS_Xi:   _all
        unab ReS_i:    $ReS_i
        local ReS_j:   copy global ReS_j
        unab ReS_Xij:  $ReS_Xij_names
        local ReS_Xi:  list ReS_Xi - ReS_i
        local ReS_Xi:  list ReS_Xi - ReS_j
        local ReS_Xi:  list ReS_Xi - ReS_Xij
        global ReS_Xi: copy local ReS_Xi
    }

    * ---------------------------
    * TODO: Is this of any value?
    * ---------------------------
    * local name __greshape_dsname
    * quietly {
    *     if `islong' {
    *         Dropout __greshape_dsname $ReS_j $ReS_i
    *         parse "", parse(" ")
    *         local i 1
    *         while "``i''" != "" {
    *             Subname ``i'' $ReS_atwl
    *             mata: `name' = `name'[selectindex(`name' :!= `"$S_1"')]
    *             local i = `i' + 1
    *         }
    *     }
    *     else { /* wide */
    *         Dropout __greshape_dsname $ReS_j $ReS_i
    *         parse "$ReS_Xij", parse(" ")
    *         local i 1
    *         while "``i''" != "" {
    *             local j 1
    *             local jval : word `j' of $ReS_jv
    *             while "`jval'"!="" {
    *                 Subname ``i'' `jval'
    *                 mata: `name' = `name'[selectindex(`name' :!= `"$S_1"')]
    *                 local j = `j' + 1
    *                 local jval : word `j' of $ReS_jv
    *             }
    *             local i = `i' + 1
    *         }
    *     }
    *     mata: st_local("N", strofreal(length(`name')))
    *     local i 1
    *     while ( `i' <= `=`N'' ) {
    *         mata: st_local("nam", `name'[`i'])
    *         global ReS_Xi $ReS_Xi `nam'
    *         local i = `i' + 1
    *     }
    * }
    * ---------------------------
end

capture program drop GetXiTypes
program GetXiTypes
    cap disp ustrregexm("a", "a")
    if ( _rc ) local regex regex
    else local regex ustrregex

    if ( "$ReS_Xi" != "" ) {
        local __greshape_xitypes
        cap matrix drop __greshape_xitypes
        foreach var of varlist $ReS_Xi {
            if ( `regex'm("`:type `var''", "str([1-9][0-9]*|L)") ) {
                if ( `regex's(1) == "L" ) {
                    disp as err "Unsupported type `:type `var''"
                    exit 198
                }
                local __greshape_xitypes `__greshape_xitypes' `=`regex's(1)'
                * matrix __greshape_xitypes = nullmat(__greshape_xitypes), `=`regex's(1)'
            }
            else if ( inlist("`:type `var''", "byte", "int", "long", "float", "double") ) {
                local __greshape_xitypes `__greshape_xitypes' 0
                * matrix __greshape_xitypes = nullmat(__greshape_xitypes), 0
            }
            else {
                disp as err "Unknown type `:type `var''"
                exit 198
            }
        }
        mata: st_matrix("__greshape_xitypes", /*
            */ strtoreal(tokens(st_local("__greshape_xitypes"))))
    }
    else {
        matrix __greshape_xitypes = .
    }
end

capture program drop Dropout
program define Dropout /* varname varnames */
    local name "`1'"
    local i 2
    while `"``i''"' != "" {
        mata: `name' = `name'[selectindex(`name' :!= `"``i''"')]
        local i = `i' + 1
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

capture program drop CopyScalars
program CopyScalars
    scalar __gtools_greshape_klvls = __greshape_klvls
    scalar __gtools_greshape_kout  = __greshape_kout
    scalar __gtools_greshape_kxij  = __greshape_kxij
    scalar __gtools_greshape_ncols = __greshape_ncols
    scalar __gtools_greshape_nrows = __greshape_nrows
    scalar __gtools_greshape_jfile = __greshape_jfile

    matrix __gtools_greshape_xitypes  = __greshape_xitypes
    matrix __gtools_greshape_types    = __greshape_types
    matrix __gtools_greshape_maplevel = __greshape_maplevel
end

capture program drop CleanExit
program CleanExit
    foreach f of global GTOOLS_TEMPFILES_GRESHAPE {
        cap erase `"${GTOOLS_TEMPDIR}/`f'"'
    }
    global GTOOLS_TEMPFILES_GRESHAPE
    global GTOOLS_TEMPFILES_GRESHAPE_I

    Macdrop
    mac drop GTOOLS_PARSE

    capture mata mata drop __greshape_maplevel
    capture mata mata drop __greshape_dsname
    capture mata mata drop __greshape_jv
    capture mata mata drop __greshape_jv_
    capture mata mata drop __greshape_res
    capture mata mata drop __greshape_sel
    capture mata mata drop __greshape_addtypes
    capture mata mata drop __greshape_addvars
    capture mata mata drop __greshape_u
    capture mata mata drop __greshape_xijname
    capture mata mata drop __greshape_rc
    capture mata mata drop __greshape_l2w_meta
    capture mata mata drop __greshape_w2l_meta

    capture scalar drop __greshape_jv_
    capture scalar drop __greshape_rc
    capture scalar drop __greshape_klvls
    capture scalar drop __greshape_kout
    capture scalar drop __greshape_kxij
    capture scalar drop __greshape_ncols
    capture scalar drop __greshape_nrows
    capture scalar drop __greshape_jfile

    capture scalar drop __gtools_greshape_klvls
    capture scalar drop __gtools_greshape_kout
    capture scalar drop __gtools_greshape_kxij
    capture scalar drop __gtools_greshape_ncols
    capture scalar drop __gtools_greshape_nrows
    capture scalar drop __gtools_greshape_jfile

    capture matrix drop __greshape_xitypes
    capture matrix drop __greshape_types
    capture matrix drop __greshape_maplevel

    capture matrix drop __gtools_greshape_xitypes
    capture matrix drop __gtools_greshape_types
    capture matrix drop __gtools_greshape_maplevel
end

* ---------------------------------------------------------------------
* Helpers taken near-verbatim from reshape.ado

capture program drop Macdrop
program define Macdrop
    mac drop ReS_cmd           ///
             ReS_Xij           ///
             ReS_Xij_regex     ///
             ReS_Xij_stubs     ///
             ReS_Xij_k         ///
             ReS_Xij_add       ///
             ReS_Xij_keep      ///
             ReS_Xij_keepnames ///
             ReS_Xij_names     ///
             ReS_Xij_addtypes  ///
             ReS_Xij_addvars   ///
             ReS_nodupcheck    ///
             ReS_nomisscheck   ///
             ReS_match         ///
             ReS_atwl          ///
             ReS_uselabels     ///
             ReS_i             ///
             ReS_iname         ///
             ReS_j             ///
             ReS_jname         ///
             ReS_jfile         ///
             ReS_jsep          ///
             ReS_jcode         ///
             ReS_jlen          ///
             ReS_jv            ///
             ReS_jv2           ///
             ReS_jvraw         ///
             ReS_prefix        ///
             ReS_labelformat   ///
             ReS_str           ///
             ReS_Xi            ///
             S_1               ///
             S_1_full          ///
             S_2               ///
             rVANS
end

capture program drop picture
program picture
    args how cmds

    if ("`how'"=="err") {
        local how "as smcl in red"
    }
    else {
        local how "as smcl in green"
    }

/*
----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
         long                                wide
        +---------------+                   +------------------+
        | i   j   a   b |                   | i   a1 a2  b1 b2 |
        |---------------| <---greshape ---> |------------------|
        | 1   2   1   2 |                   | 1    1  3   2  4 |
        | 1   2   3   4 |                   | 2    5  7   6  8 |
        | 2   1   5   6 |                   +------------------+
        | 2   2   7   8 |
        +---------------+
                                                 j existing variable
                                                /
    long to wide:  greshape wide a b, i(i) j(j)

        wide to long:  greshape long a b, i(i) j(j)
                                            \
                                                 j new variable

         123456789012345                     123456789012345678
        +---------------+1234567890123456789+------------------+
        | i   j   a   b |                   | i   a1 a2  b1 b2 |
        |---------------| <---greshape ---> |------------------|
        | 1   2   1   2 |                   | 1    1  3   2  4 |
        | 1   2   3   4 |                   | 2    5  7   6  8 |
        | 2   1   5   6 |                   +------------------+
        | 2   2   7   8 |
        +---------------+
*/

    di `how' _col(9) " {it:long}" _skip(33) "{it:wide}"
    di `how' _col(9) ///
        "{c TLC}{hline 15}{c TRC}" _skip(20) ///
        "{c TLC}{hline 18}{c TRC}"
    di `how' _col(9) "{c |} {it:i   j}   a   b {c |}" _skip(20) ///
                  "{c |} {it:i}   a1 a2  b1 b2 {c |}"
    di `how' _col(9) "{c |}{hline 15}{c |}" ///
                  " <--- {bf:greshape} ---> " ///
                  "{c |}{hline 18}{c |}"
    di `how' _col(9) "{c |} 1   1   1   2 {c |}" _skip(20) ///
                  "{c |} 1   1   3   2  4 {c |}"
    di `how' _col(9) "{c |} 1   2   3   4 {c |}" _skip(20) ///
                  "{c |} 2   5   7   6  8 {c |}"
    di `how' _col(9) "{c |} 2   1   5   6 {c |}" _skip(20) ///
                  "{c BLC}{hline 18}{c BRC}"
    di `how' _col(9) "{c |} 2   2   7   8 {c |}"
    di `how' _col(9) "{c BLC}{hline 15}{c BRC}"
    if ("`cmds'" != "") {
        di `how'
        di `how' _col(9) ///
        "long to wide: " ///
        "{bf:greshape wide a b, $ReS_iname(}{it:i}{bf:) j(}{it:j}{bf:)}  " ///
        "  ({it:j} existing variable)"
        di `how' _col(9) ///
        "wide to long: " ///
        "{bf:greshape long a b, $ReS_iname(}{it:i}{bf:) j(}{it:j}{bf:)}  " ///
        "  ({it:j}    new   variable)"
    }
end

capture program drop ConfVar
program define ConfVar /* varname */
    capture syntax varname
    if ( _rc == 0 ) {
        gettoken lhs : 0
        if ( `"`lhs'"' == `"`varlist'"' ) {
            exit 0
        }
    }
    di in red as smcl `"variable {bf:`0'} not found"'
    exit 111
end

capture program drop ReportL
program define ReportL /* old_obs old_vars */
    Report1 `1' `2' wide long

    local n : word count $ReS_jv
    di in gr "$ReS_jname (`n' values)         " _col(43) "->" _col(48) /*
    */ in ye "$ReS_j"
    di in gr "xij variables:"
    parse "$ReS_Xij", parse(" ")
    local xijn : char _dta[ReS_Xij_n]
    if `"`xijn'"' != "" {
        forvalues i = 1/`xijn' {
            char _dta[ReS_Xij_wide`i']
            char _dta[ReS_Xij_long`i']
        }
        char _dta[ReS_Xij_n]
    }
    local i 0
    while ( `"`1'"' != "" ) {
        RepF "`1'"
        local skip = 39 - length("$S_1")
        di in ye _skip(`skip') "$S_1" _col(43) in gr "->" /*
        */ in ye _col(48) "$S_2"
        local ++i
        char _dta[ReS_Xij_wide`i'] "$S_1_full"
        char _dta[ReS_Xij_long`i'] "$S_2"
        mac shift
    }
    char _dta[ReS_Xij_n] "`i'"
    di in smcl in gr "{hline 77}"
end

capture program drop RepF
program define RepF /* element from ReS_Xij */
    local v "`1'"
    if "$ReS_jv2" != "" {
        local n : word count $ReS_jv2
        parse "$ReS_jv2", parse(" ")
    }
    else {
        local n : word count $ReS_jv
        parse "$ReS_jv", parse(" ")
    }
    if `n'>=1 {
        Subname `v' `1'
        local list $S_1
    }
    if `n'>=2 {
        Subname `v' `2'
        local list `list' $S_1
    }
    if `n'==3 {
        Subname `v' ``n''
        local list `list' $S_1
    }
    else if `n'>3 {
        Subname `v' ``n''
        local list `list' ... $S_1
    }

    local flist
    forvalues i=1/`n' {
        Subname `v' ``i''
        local flist `flist' $S_1
    }
    global S_1_full `flist'

    Subname `v' $ReS_atwl
    global S_2 $S_1
    global S_1 `list'
end

capture program drop Report1
program define Report1 /* <#oobs> <#ovars> {wide|long} {long|wide} */
    local oobs  "`1'"
    local ovars "`2'"
    local wide  "`3'"
    local long  "`4'"

    di in smcl _n in gr "Data" _col(36) "`wide'" _col(43) /*
    */ "->" _col(48) "`long'" _n "{hline 77}"

    di in gr "Number of obs." _col(19) in ye %21.0gc `oobs' /*
    */ in gr _col(43) "->   " in ye %-21.0gc _N

    quietly desc, short

    di in gr "Number of variables" _col(19) in ye %21.0gc `ovars' /*
    */ in gr _col(43) "->   " in ye %-21.0gc r(k)
end

capture program drop ReportW
program define ReportW /* old_obs old_vars */
    Report1 `1' `2' long wide

    local n : word count $ReS_jv2
    local col = 31+(9-length("$ReS_j"))
    di in gr "$ReS_jname (`n' values)        " /*
        */ _col(`col') in ye "$ReS_j" in gr _col(43) "->" /*
        */ _col(48) "(dropped)"
    di in gr "xij variables:"
    parse "$ReS_Xij", parse(" ")
    if ( `"`xijn'"' != "" ) {
        forvalues i = 1/`xijn' {
            char _dta[ReS_Xij_wide`i']
            char _dta[ReS_Xij_long`i']
        }
        char _dta[ReS_Xij_n]
    }
    local i 0
    while ( `"`1'"' != "" ) {
        RepF "`1'"
        local skip = 39 - length("$S_2")
        di in ye _skip(`skip') "$S_2" _col(43) in gr "->" /*
        */ in ye _col(48) "$S_1"
        local ++i
        char _dta[ReS_Xij_wide`i'] "$S_1_full"
        char _dta[ReS_Xij_long`i'] "$S_2"
        mac shift
    }
    char _dta[ReS_Xij_n] "`i'"
    di in smcl in gr "{hline 77}"
end

capture program drop Macros
program define Macros /* reshape macro check utility */
    capture ConfVar $ReS_j
    if ( _rc == 0 ) {
        if ( $ReS_nomisscheck == 0 ) {
            if ( $ReS_str == 0 ) {
                capture assert $ReS_j<.
                if _rc {
                    di in red as smcl ///
                    "variable {bf:$ReS_j} contains missing values"
                    exit 498
                }
            }
            else {
                capture assert trim($ReS_j) != ""
                if _rc {
                    di in red as smcl ///
                    "variable {bf:$ReS_j} contains missing values"
                    exit 498
                }
                capture assert $ReS_j == trim($ReS_j)
                if _rc {
                    di in red as smcl ///
                "variable {bf:$ReS_j} has leading or trailing blanks"
                    exit 498
                }
            }
        }
    }

    if ( "$ReS_i" == "" ) {
        NotDefd "reshape i"
    }

    if ( "$ReS_Xij" == "" ) {
        NotDefd "reshape xij"
    }

    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    global rVANS: copy global ReS_Xij_stubs
    global S_1

    * ---------------------------
    * TODO: Is this of any value?
    * ---------------------------
    * global rVANS
    * parse "$ReS_Xij", parse(" ")
    * local i 1
    * while "``i''"!="" {
    *     Subname ``i''
    *     global rVANS "$rVANS $S_1"
    *     local i = `i' + 1
    * }
    * global S_1
    * ---------------------------
    * TODO: Is this of any value?
    * ---------------------------
end

capture program drop NotDefd
program define NotDefd /* <message> */
    hasanyinfo hasinfo
    if (`hasinfo') {
        di in red as smcl `"{bf:`*'} not defined"'
        exit 111
    }
    di as err "data have not been reshaped yet"
    di as err in smcl "{p 4 4 2}"
    di as err in smcl "What you typed is a syntax error because"
    di as err in smcl "the data have not been {bf:reshape}d"
    di as err in smcl "previously.  The basic syntax of
    di as err in smcl "{bf:reshape} is"
    di as err in smcl
    picture err cmds
    exit 111
end

capture program drop hasanyinfo
program define hasanyinfo
    args macname

    local cons   : char _dta[ReS_i]
    local grpvar : char _dta[ReS_j]
    local values : char _dta[ReS_jv]
    local vars   : char _dta[ReS_Xij]
    local car    : char _dta[Res_Xi]
    local atwl   : char _dta[ReS_atwl]
    local isstr  : char _dta[ReS_str]

    local hasinfo 0
    local hasinfo = `hasinfo' | (`"`cons'"'   != "")
    local hasinfo = `hasinfo' | (`"`grpvar'"' != "")
    local hasinfo = `hasinfo' | (`"`values'"' != "")
    local hasinfo = `hasinfo' | (`"`values'"' != "")
    local hasinfo = `hasinfo' | (`"`vars'"'   != "")
    local hasinfo = `hasinfo' | (`"`car'"'    != "")
    local hasinfo = `hasinfo' | (`"`atwl'"'   != "")
    local hasinfo = `hasinfo' | (`"`isstr'"'  != "")

    c_local `macname' `hasinfo'
end

capture program drop Subname
program define Subname /* <name-maybe-with-@> <tosub> */
    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr
    local name "`1'"
    local sub  "`2'"
    local m = length(`"$ReS_match"')
    local l = index("`name'", `"$ReS_match"')
    local l = cond(`l' == 0, length("`name'") + 1, `l')
    local a = `substr'("`name'", 1, `l' - 1)
    local c = `substr'("`name'", `l' + `m', .)
    global S_1 "`a'`sub'`c'"
end

capture program drop NonUniqueLongID
program define NonUniqueLongID
	di in red as smcl ///
	    "variable {bf:id} does not uniquely identify the observations"
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Your data are currently wide."
	di in red as smcl "You are performing a {bf:reshape long}."
	di in red as smcl "You specified {bf:$ReS_iname($ReS_i)} and {bf:$ReS_jname($ReS_j)}."
	di in red as smcl "In the current wide form, variable {bf:$ReS_i}"
	di in red as smcl "should uniquely identify the observations."
	di in red as smcl "Remember this picture:"
	di in red
	picture err
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Type {stata gduplicates examples $ReS_i} for examples of"
	di in red as smcl "problem observations."
	di in red as smcl "{p_end}"
end

capture program drop NonUniqueWideJ
program NonUniqueWideJ
    di in red as smcl ///
    "values of variable {bf:$ReS_j} not unique within {bf:$ReS_i}"
    di in red as smcl "{p 4 4 2}"
    di in red as smcl "Your data are currently long."
    di in red as smcl "You are performing a {bf:reshape wide}."
    di in red as smcl "You specified {bf:$ReS_iname($ReS_i)} and"
    di in red as smcl "{bf:$ReS_jname($ReS_j)}."
    di in red as smcl "There are observations within"
    di in red as smcl "{bf:$ReS_iname($ReS_i)} with the same value of"
    di in red as smcl "{bf:$ReS_jname($ReS_j)}.  In the long data,"
    di in red as smcl "variables {bf:$ReS_iname()} and {bf:$ReS_jname()} together"
    di in red as smcl "must uniquely identify the observations."
    di in red as smcl
    picture err
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Type {stata gduplicates examples $ReS_i $ReS_j} for examples of"
	di in red as smcl "problem observations."
	di in red as smcl "{p_end}"
end

capture program drop NonUniqueWideXi
program NonUniqueWideXi
	* TODO: List problem variables
    * forvalues i = 1 / `nxi' {
    *     if ( __greshape_xiproblem[`i'] ) {
    *         di in red as smcl ///
    *         "variable {bf:`1'} not constant within {bf:$ReS_i}"
    *     }
    * }
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Your data are currently long."
	di in red as smcl "You are performing a {bf:reshape wide}."
	di in red as smcl "You typed something like"
	di in red
	di in red as smcl "{p 8 8 2}"
	di in red as smcl "{bf:. reshape wide a b, $ReS_iname($ReS_i) $ReS_jname($ReS_j)}"
	di in red
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "There are variables other than {bf:a},"
	di in red as smcl "{bf:b}, {bf:$ReS_i}, {bf:$ReS_j} in your data."
	di in red as smcl "They must be constant within"
	di in red as smcl "{bf:$ReS_i} because that is the only way they can"
	di in red as smcl "fit into wide data without loss of information."
	di in red
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "The variable or variables listed above are"
	di in red as smcl "not constant within {bf:$ReS_i}.
	di in red
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "You must either add the variables"
	di in red as smcl "to the list of xij variables to be reshaped,"
	di in red as smcl "or {bf:drop} them."
	di in red as smcl "{p_end}"
end

capture program drop ClearReshape
program ClearReshape
    char _dta[ReS_ver]
    char _dta[ReS_i]
    char _dta[ReS_j]
    char _dta[ReS_jv]
    char _dta[ReS_Xij]
    char _dta[Res_Xi]
    char _dta[ReS_atwl]
    char _dta[ReS_str]
    local xijn : char _dta[ReS_Xij_n]
    if "`xijn'" != "" {
        forvalues i = 1/`xijn' {
            char _dta[ReS_Xij_wide`i']
            char _dta[ReS_Xij_long`i']
        }
        char _dta[ReS_Xij_n]
    }
    CleanExit
end

***********************************************************************
*                            Labels, etc.                             *
***********************************************************************

cap mata ustrregexm("a", "a")
if ( _rc ) local regex regex
else local regex ustrregex

capture mata: mata drop LongToWideMetaSave()
capture mata: mata drop LongToWideMetaApply()
capture mata: mata drop WideToLongMetaSave()
capture mata: mata drop WideToLongMetaApply()
capture mata: mata drop ApplyDefaultFormat()
capture mata: mata drop ApplyCustomLabelFormat()

mata:
transmorphic scalar LongToWideMetaSave(real scalar spread)
{
    transmorphic scalar LongToWideMeta
    string rowvector rVANS, ReS_Xij,ReS_jv, ReS_jvraw, ReS_prefix
    string scalar ReS_j, ReS_jvlb, ReS_labelformat
    string scalar newvar, var, stub, lvl, fmt, lbl, fmtlbl
    string matrix chars, _chars
    real scalar i, j, k, prefix, njvars

    // Get all the meta info! Note that the label formatting only
    // happens with single-variable input for keys()/j(), so we
    // only grab the "first" element (because they get ignored
    // if there are any other elements).

    LongToWideMeta  = asarray_create()
    fmt             = "%s[%s]"
    rVANS           = tokens(st_global("rVANS"))
    ReS_Xij         = tokens(st_global("ReS_Xij"))
    ReS_jv          = tokens(st_global("ReS_jv"))
    ReS_jvraw       = tokens(st_global("ReS_jvraw"))
    ReS_prefix      = tokens(st_global("ReS_prefix"))
    ReS_j           = tokens(st_global("ReS_j"))[1]
    njvars          = cols(tokens(st_global("ReS_j")))
    ReS_jvlb        = st_varvaluelabel(ReS_j)
    ReS_labelformat = st_global("ReS_labelformat")
    prefix          = (length(ReS_prefix) > 0)

    asarray(LongToWideMeta, "rVANS",      rVANS)
    asarray(LongToWideMeta, "ReS_Xij",    ReS_Xij)
    asarray(LongToWideMeta, "ReS_jv",     ReS_jv)
    asarray(LongToWideMeta, "ReS_jvraw",  ReS_jvraw)
    asarray(LongToWideMeta, "ReS_prefix", ReS_prefix)

    // Keep labels, value labels, formats, and characteristics of
    // each source variable. All will be applied to (copied to) each
    // corresponding wide variable.

    spread = (spread & (cols(ReS_Xij) == 1))
    for (i = 1; i <= cols(ReS_Xij); i++) {
        stub = ReS_Xij[i]
        var  = rVANS[i]
        for (j = 1; j <= cols(ReS_jv); j++) {
            lvl = ReS_jv[j]
            lbl = ReS_jvraw[j]
            chars  = J(0, 2, "")
            _chars = st_dir("char", var, "*")
            if ( prefix ) {
                newvar = GetVariableFromStubPrefix(stub, lvl, ReS_prefix[i])
            }
            else {
                newvar = spread? lvl: GetVariableFromStub(stub, lvl)
            }
            for (k = 1; k <= rows(_chars); k++) {
                chars = chars \ (
                    sprintf(fmt, newvar, _chars[k]),
                    st_global(sprintf(fmt, var, _chars[k]))
                )
            }
            if ( njvars > 1 ) {
                fmtlbl = lbl + " " + st_varlabel(var)
            }
            else {
                fmtlbl = ApplyCustomLabelFormat(
                    ReS_labelformat,
                    var,
                    st_varlabel(var),
                    ReS_j,
                    st_varlabel(ReS_j),
                    lbl,
                    ReS_jvlb
                )
            }
            // asarray(LongToWideMeta, newvar + "lbl", lbl + " " + st_varlabel(var))
            asarray(LongToWideMeta, newvar + "lbl", fmtlbl)
            asarray(LongToWideMeta, newvar + "fmt", st_varformat(var))
            asarray(LongToWideMeta, newvar + "vlb", st_varvaluelabel(var))
            asarray(LongToWideMeta, newvar + "chr", chars)
        }
    }

    return (LongToWideMeta)
}

void LongToWideMetaApply(transmorphic scalar LongToWideMeta, real scalar spread)
{

    string rowvector ReS_Xij,ReS_jv, ReS_prefix
    string scalar newvar, stub, lvl
    string matrix chars
    real scalar i, j, k, prefix

    ReS_Xij    = asarray(LongToWideMeta, "ReS_Xij")
    ReS_jv     = asarray(LongToWideMeta, "ReS_jv")
    ReS_prefix = asarray(LongToWideMeta, "ReS_prefix")
    prefix     = (length(ReS_prefix) > 0)

    spread = (spread & (cols(ReS_Xij) == 1))
    for (i = 1; i <= cols(ReS_Xij); i++) {
        stub = ReS_Xij[i]
        for (j = 1; j <= cols(ReS_jv); j++) {
            lvl = ReS_jv[j]
            if ( prefix ) {
                newvar = GetVariableFromStubPrefix(stub, lvl, ReS_prefix[i])
            }
            else {
                newvar = spread? lvl: GetVariableFromStub(stub, lvl)
            }
            st_varlabel(newvar,  asarray(LongToWideMeta, newvar + "lbl"))
            st_varformat(newvar, asarray(LongToWideMeta, newvar + "fmt"))

            // Value labels only for numeric
            if ( `regex'm(st_vartype(newvar), "str([1-9][0-9]*|L)") == 0 ) {
                st_varvaluelabel(newvar, asarray(LongToWideMeta, newvar + "vlb"))
            }

            chars = asarray(LongToWideMeta, newvar + "chr")
            for (k = 1; k <= rows(chars); k++) {
                st_global(chars[k, 1], chars[k, 2])
            }

        }
    }
}

transmorphic scalar WideToLongMetaSave()
{
    transmorphic scalar WideToLongMeta
    string rowvector ReS_Xij, ReS_Xij_names, ReS_jv
    string scalar var, nam, fmt, what, lvl
    string scalar _lb2, _lbl, _fmt, _vlb
    string matrix chars, _chars
    string matrix notes, _notes, note0, _note0
    real matrix maplevel
    real scalar i, j, k, notek, noten
    real scalar any_lbl, any_lb2, any_fmt, any_vlb
    real scalar ever_lbl, ever_fmt, ever_vlb

    maplevel = st_matrix("__greshape_maplevel")

    WideToLongMeta = asarray_create()
    fmt     = "%s[%s]"
    ReS_Xij = tokens(st_global("ReS_Xij_stubs"))
    ReS_jv  = tokens(st_global("ReS_jv"))
    ReS_Xij_names = tokens(st_global("ReS_Xij_names"))

    asarray(WideToLongMeta, "ReS_Xij", ReS_Xij)
    asarray(WideToLongMeta, "ReS_jv",  ReS_jv)

    ever_lbl = 0
    ever_fmt = 0
    ever_vlb = 0

    // Keep labels, value labels, formats, and characteristics of each
    // set of source variables. All will be applied to (copied to) each
    // corresponding single long variable. Since this is a many to one,
    // Labels, value labels, and formats are discarded if there is more
    // than one (TODO: Add optionfor which to keep?).
    //
    // Notes are appended in the order they appear. We keep a unique set
    // of notes from the source variables in the target variable. Note
    // that variable notes are saved as variable characteristics, so we
    // apply all variable characteristics first and all the (unique)
    // notes second (we do not mind collisions and such, in part because
    // it's a hassle but also because variable characteristics are such
    // an advanced feature anyway that any user using them ought to
    // be defining their behavior explicitly, so I don't even want to
    // tinker with that too much).

    what = ""
    for (i = 1; i <= rows(maplevel); i++) {
        var    = ReS_Xij[i]
        chars  = J(0, 2, "")
        notes  = J(0, 2, "")
        _notes = J(0, 1, "")
        noten  = 0
        for (j = 1; j <= cols(maplevel); j++) {
            if ( maplevel[i, j] ) {
                lvl = ReS_jv[j]
                nam = ReS_Xij_names[maplevel[i, j]]
                _chars = st_dir("char", nam, "*")
                for (k = 1; k <= rows(_chars); k++) {
                    chars = chars \ (
                        sprintf(fmt, var, _chars[k]),
                        st_global(sprintf(fmt, nam, _chars[k]))
                    )
                }

                note0 = st_global(sprintf(fmt, nam, "note0"))
                if ( note0 != "" ) {
                    notek = strtoreal(note0)
                    if ( notek < . ) {
                        for (k = 1; k <= notek; k++) {
                            _note0 = st_global(sprintf(fmt, nam, "note" + strofreal(k)))
                            if ( any(_note0 :== _notes) == 0 ) {
                                _notes = _notes \ _note0
                            }
                        }
                    }
                }
            }
        }

        any_lbl = 0
        any_lb2 = 0
        any_fmt = 0
        any_vlb = 0

        _lbl = st_varlabel(nam)
        _lb2 = substr(st_varlabel(nam), strlen(lvl) + 1, .)
        _fmt = st_varformat(nam)
        _vlb = st_varvaluelabel(nam)
        for (j = 1; j <= cols(maplevel); j++) {
            if ( maplevel[i, j] ) {
                lvl = ReS_jv[j]
                nam = ReS_Xij_names[maplevel[i, j]]
                any_lbl = any_lbl | (_lbl != st_varlabel(nam))
                any_lb2 = any_lb2 | (_lb2 != substr(st_varlabel(nam), strlen(lvl) + 1, .))
                any_fmt = any_fmt | (_fmt != st_varformat(nam))
                any_vlb = any_vlb | (_vlb != st_varvaluelabel(nam))
            }
        }

        // _notes = uniqrows(_notes)
        if ( rows(_notes) > 0 ) {
            noten = rows(_notes)
            notes = J(noten + 1, 2, "")
            notes[1, .] = (sprintf(fmt, var, "note0"), strofreal(noten))
            for (k = 1; k <= noten; k++) {
                notes[1 + k, .] = (sprintf(fmt, var, "note" + strofreal(k)), _notes[k])
            }
        }

        if ( any_lbl == 0 ) {
            asarray(WideToLongMeta, var + "lbl", _lbl)
        }
        else if ( any_lb2 == 0 ) {
            any_lbl = 0
            asarray(WideToLongMeta, var + "lbl", _lb2)
        }
        else {
            any_lbl = 1
            any_lb2 = 1
            asarray(WideToLongMeta, var + "lbl", "")
        }

        asarray(WideToLongMeta, var + "fmt", any_fmt? "": _fmt)
        asarray(WideToLongMeta, var + "vlb", any_vlb? "": _vlb)
        asarray(WideToLongMeta, var + "chr", chars)
        asarray(WideToLongMeta, var + "nts", notes)

        ever_lbl = ever_lbl | any_lbl
        ever_fmt = ever_fmt | any_fmt
        ever_vlb = ever_vlb | any_vlb
    }

    if ( ever_lbl )
        what = "labels"

    if ( ever_vlb )
        what = (what == "")? "value labels": what + ", value labels"

    if ( ever_fmt )
        what = (what == "")? "variable formats": what + ", variable formats"

    if ( what != "" )
        printf("(note: cannot preserve %s when reshaping long)\n", what)

    return (WideToLongMeta)
}

void WideToLongMetaApply(transmorphic scalar WideToLongMeta)
{
    string rowvector ReS_Xij
    string scalar var
    string matrix chars, notes
    real scalar i, k, f

    ReS_Xij = asarray(WideToLongMeta, "ReS_Xij")
    for (i  = 1; i <= cols(ReS_Xij); i++) {
        var = ReS_Xij[i]
        st_varlabel(var, asarray(WideToLongMeta, var + "lbl"))

        if ( `regex'm(st_vartype(var), "str([1-9][0-9]*|L)") == 0 ) {
            st_varvaluelabel(var, asarray(WideToLongMeta, var + "vlb"))
        }

        f = asarray(WideToLongMeta, var + "fmt")
        if ( f == "" ){
            ApplyDefaultFormat(var)
        }
        else {
            st_varformat(var, asarray(WideToLongMeta, var + "fmt"))
        }

        chars = asarray(WideToLongMeta, var + "chr")
        for (k = 1; k <= rows(chars); k++) {
            st_global(chars[k, 1], chars[k, 2])
        }

        notes = asarray(WideToLongMeta, var + "nts")
        for (k = 1; k <= rows(notes); k++) {
            st_global(notes[k, 1], notes[k, 2])
        }
    }

}

// If variable formats collide, reset to default format
void function ApplyDefaultFormat(string scalar var)
{
    string scalar v, l, f
    v = st_vartype(var)
    f = ""
    if ( `regex'm(v, "str([1-9][0-9]*|L)") ) {
        l = `regex's(1)
        if ( l == "L" ) {
            f = "%9s"
        }
        else {
            f = "%" + `regex's(1) + "s"
        }
    }
    else {
        if ( v == "byte" ) {
            f = "%8.0g"
        }
        else if ( v == "int" ) {
            f = "%8.0g"
        }
        else if ( v == "long" ) {
            f = "%12.0g"
        }
        else if ( v == "float" ) {
            f = "%9.0g"
        }
        else if ( v == "double" ) {
            f = "%10.0g"
        }
        else {
            f = ""
        }
    }
    if ( f != "" ) {
        st_varformat(var, f)
    }
}

string scalar function ApplyCustomLabelFormat(
    string scalar fmt,       // Label format
    string scalar stbnam,    // stub variable name
    string scalar stblbl,    // stub variable label
    string scalar varnam,    // Key variable name
    string scalar varlbl,    // Key variable label
    string scalar varval,    // Key variable value
    string scalar varvlbnam) // Key variable value label name
{
    string scalar regstbnam
    string scalar regstblbl
    string scalar regvarnam
    string scalar regvarlbl
    string scalar regvarval
    string scalar regvarvlb
    string scalar varvlb
    string scalar out
    real scalar numlbl

    numlbl = st_isnumvar(varnam)? strtoreal(varval): .
    varvlb = varvlbnam == ""? "": st_vlmap(varvlbnam, numlbl)

    regstbnam = "#stubname#"
    regstblbl = "#stublabel#"
    regvarnam = "#keyname#"
    regvarlbl = "#keylabel#"
    regvarval = "#keyvalue#"
    regvarvlb = "#keyvaluelabel#"

    // Fallbacks
    if ( stblbl == "" ) stblbl = stbnam
    if ( varlbl == "" ) varlbl = varnam
    if ( varvlb == "" ) varvlb = varval

    out = subinstr(fmt, regstbnam, stbnam, .)
    out = subinstr(out, regstblbl, stblbl, .)
    out = subinstr(out, regvarnam, varnam, .)
    out = subinstr(out, regvarlbl, varlbl, .)
    out = subinstr(out, regvarval, varval, .)
    out = subinstr(out, regvarvlb, varvlb, .)

    return(out)
}
end

capture program drop GreshapeTempFile
program GreshapeTempFile
    if ( `"${GTOOLS_TEMPFILES_GRESHAPE_I}"' == "" ) {
        local  GTOOLS_TEMPFILES_GRESHAPE_I = 1
        global GTOOLS_TEMPFILES_GRESHAPE_I = 1
    }
    else {
        local  GTOOLS_TEMPFILES_GRESHAPE_I = ${GTOOLS_TEMPFILES_GRESHAPE_I} + 1
        global GTOOLS_TEMPFILES_GRESHAPE_I = ${GTOOLS_TEMPFILES_GRESHAPE_I} + 1
    }
    local f ${GTOOLS_TEMPDIR}/__gtools_tmpfile_greshape_`GTOOLS_TEMPFILES_GRESHAPE_I'
    global GTOOLS_TEMPFILES_GRESHAPE ${GTOOLS_TEMPFILES_GRESHAPE} __gtools_tmpfile_greshape_`GTOOLS_TEMPFILES_GRESHAPE_I'
    c_local `0': copy local f
end

***********************************************************************
*                           TODO Eventually                           *
***********************************************************************

* --------------------------------
* TODO: Add collapse syntax for xi
* --------------------------------

* --------------------------------------------------------------------------------------------------------
* TODO: for gather
*
*     greshape gather (type target1 "Label" = varlist1) [(type target2 "label" = varlist2) ...], i(i) j(j)
*     * 1 problem var
*     disp as err "Incomparible types: taget1 is type but source var1 is type"
*     * N problem var
*     disp as err "Incomparible types for variables:"
*                 "taget1 is type but source var1 is type"
*                 "..."
*     * With option force: Just go! No type checking. Set to missing if type is not compat.
*     * Option for converting numeric to string? sprintf(...)
* --------------------------------------------------------------------------------------------------------

* ----------------------------------------------------
* TODO: Add values of j to subset? j(j 2005 2006 2007)
*                                  j(j 2005-2007)
*                                  j(j a b c ...)
* ----------------------------------------------------

* -------------------------------------------------------------
* TODO: better atwl, basically. match(num|str|anything|/regex/)
* -------------------------------------------------------------
