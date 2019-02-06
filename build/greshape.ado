*! version 0.1.0 05Feb2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Fast implementation of reshape using C plugins

***********************************************************************
*                   TODO before merging to develop                    *
***********************************************************************

* -----------------------------------------------------------------------------------
* TODO: Copy the xi variables; they are ignored atm
*       Check Xi is fine internally with reshaep wide once you add Xi
*       Add collapse syntax (after; first just implement keep/drop with unique check)
* -----------------------------------------------------------------------------------

***********************************************************************
*                           TODO Eventually                           *
***********************************************************************

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

* ------------------------------------------
* TODO: Give user options over no xij found?
* ------------------------------------------

* -----------------------------------------------
* TODO: Just allow j to be string in reshape wide
* -----------------------------------------------

* ------------------------------------------------------------------------------
* TODO: Note in doc: greshape does not support highlighting problem observations
*       General note: Extended reshape syntax not supported
* ------------------------------------------------------------------------------

* ----------------------------------------------------
* TODO: Add values of j to subset? j(j 2005 2006 2007)
*                                  j(j 2005-2007)
*                                  j(j a b c ...)
* ----------------------------------------------------

* -------------------------------------------------------------
* TODO: better atwl, basically. match(num|str|anything|/regex/)
* -------------------------------------------------------------

* ---------------------------------------------------
* TODO: Make cols an option when you allow multiple j
* ---------------------------------------------------

capture program drop greshape
program greshape, rclass
    version 13.1

    if ( inlist(`"`1'"', "clear", "query", "error", "i", "xij", "j", "xi") ) {
        disp as err "-reshape `1'- syntax is not supported; see {help greshape:help greshape}" _n
        picture err cmd
        exit 198
    }

    * TODO: Implement gather and spread
    if ( inlist(`"`1'"', "gather", "spread") ) {
        disp as err `"`1' not yet allowed"'
        exit 198
    }

    if ( !inlist(`"`1'"', "long", "wide", "gather", "spread") ) {
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

    global GTOOLS_PARSE       ///
        unsorted              /// Do not sort the data
        nodupcheck            /// Do not check for duplicates
        nomisscheck           /// Do not check for missing values or blanks in j
        compress              /// Try to compress strL variables
        forcestrl             /// Force reading strL variables (stata 14 and above only)
        Verbose               /// Print info during function execution
        _CTOLerance(passthru) /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
        debug(passthru)        // Print debugging info to console

    gettoken sub args: 0
    cap noi `cmd' `args'
    local rc = _rc
    if ( `rc' == 17999 ) {
        CleanExit
        reshape `0'
        exit 0
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
* X | X | ReS_i
* X | X | ReS_j
* X | X | ReS_nodupcheck
* X | X | ReS_nomisscheck
* X | X | ReS_cmd
* X |   | ReS_Xij_add
* X | X | ReS_Xij_keep
* X | X | ReS_Xij_keepnames
* X | X | ReS_Xij_names
*   | X | ReS_Xij_addtypes
*   | X | ReS_Xij_addvars
* X | X | ReS_atwl
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

    global ReS_cmd long
    syntax [anything],    ///
        i(varlist)        /// reshape by groups of -i()-
        [j(name) string]  /// varnames by levels -j()-; look for string-like names
        [fast]            /// Do not preserve and restore the original dataset. Saves speed
        [atwl(str)]       /// replace @ with atwl?
        [${GTOOLS_PARSE}] /// varnames by levels -j()-; look for string-like names

    if ( "`fast'" == "" ) preserve

    if ( `"`j'"' == "" ) local j _j
    global ReS_str = ( `"`string'"' != "" )
    global ReS_atwl `atwl'
    global ReS_Xij  `anything'
    global ReS_i    `i'
    global ReS_j    `j'

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

    local oldobs = _N
    quietly describe, short
    local oldvars = r(k)

    ***********************************************************************
    *                         Macros and J values                         *
    ***********************************************************************

    Macros
    confirm var $ReS_i $ReS_Xi
    capture confirm new var $ReS_j
    if ( _rc ) {
        di in blu "Target j($ReS_j) already exists (is the data already long?)"
        exit 198
    }

    tempfile ReS_jfile
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
    CopyScalars

    ***********************************************************************
    *                           Do the reshape                            *
    ***********************************************************************

    if ( "$ReS_Xi" != "" ) {
        disp as err "Extra variables not yet allowed:"
        disp as err "    $ReS_Xi"
        exit 198
    }

    * ------------------------
    * Reshape the data to disk
    * ------------------------

    if ( $ReS_nodupcheck ) local cmd long fwrite
    else local cmd long write

    tempfile ReS_Data
    global GTOOLS_CALLER greshape
    local gopts xij($ReS_Xij_names) xi($ReS_Xi) f(`ReS_Data') `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts'
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
    mata __greshape_addvars  = "$ReS_j", tokens("$ReS_Xij_add")
    mata (void) st_addvar(__greshape_addtypes, __greshape_addvars, 0)
    if ( (`"$ReS_Xij_keep"' != "") &(`"$ReS_Xij_keepnames"' != "") ) {
        rename ($ReS_Xij_keep) ($ReS_Xij_keepnames)
    }
    order $ReS_i $ReS_j $ReS_Xij $ReS_Xi
    qui set obs `=_N * scalar(__greshape_klvls)'
    * qui expand `=scalar(__greshape_klvls)'
    if ( `FreeTimer' ) {
        qui timer off `FreeTimer'
        qui timer list
        local s `:disp %9.3f `r(t`FreeTimer')''
        if ( `benchmarklevel' > 2 ) {
            disp _char(9) "reshape long step 4: allocated target dataset; `s' seconds."
        }
    }
    else if ( `benchmarklevel' > 2 ) {
        disp _char(9) "reshape long step 4: allocated target dataset; ??? seconds."
    }

    * ------------------
    * Read reshaped data
    * ------------------

    local cmd long read
    global GTOOLS_CALLER greshape
    local gopts j($ReS_j) xij($ReS_Xij) xi($ReS_Xi) f(`ReS_Data') `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts'
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

    /* Apply Xij variable label for LONG*/
    local iii : char _dta[__XijVarLabTotal]
    if `"`iii'"' == "" {
        local iii = -1
    }

    foreach var of global ReS_Xij {
        local var = subinstr(`"`var'"', "@", "$ReS_atwl", 1)
        if (length(`"`var'"') < 21 ) {
            local xijlab : char _dta[__XijVarLab`var']
            if `"`xijlab'"' != "" {
                label variable `var' `"`xijlab'"'
                char define _dta[__XijVarLab`var'] `""'
            }
        }
        else {
            local ii = 1
            while `ii' <= `iii' {
                local xijlab : char _dta[__XijVarLab`ii']
                if (`"`xijlab'"' != "") {
                    local v =  ///
                    `substr'(`"`xijlab'"',1, ///
                    strpos(`"`xijlab'"', " ")-1)
                    if `"`v'"' == `"`var'"' {
                        local tlab :  ///
                        subinstr local ///
                        xijlab `"`v' "' ""
                        capture label variable ///
                        `var' `"`tlab'"'
                        capture char define ///
                        _dta[__XijVarLab`ii'] `""'
                        continue, break
                    }
                }
                local ii = `ii' + 1
            }
        }
    }
    ReportL `oldobs' `oldvars'

    if ( "`fast'" == "" ) restore, not
end

* ---------------------------------------------------------------------
* Reshape wide

capture program drop Wide
program define Wide /* reshape wide */

    ***********************************************************************
    *                          Parse Long Syntax                          *
    ***********************************************************************

    global ReS_cmd wide
    syntax [anything],    ///
        i(varlist)        /// reshape by groups of -i()-
        j(name) [string]  /// varnames by levels -j()-; look for string-like names
        [fast]            /// Do not preserve and restore the original dataset. Saves speed
        [atwl(str)]       /// replace @ with atwl?
        [${GTOOLS_PARSE}] /// varnames by levels -j()-; look for string-like names

    if ( "`fast'" == "" ) preserve

    global ReS_atwl `atwl'
    global ReS_Xij  `anything'
    global ReS_i    `i'
    global ReS_j    `j'

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

    global ReS_nodupcheck  = ( `"`dupcheck'"'  == "nodupcheck" )
    global ReS_nomisscheck = ( `"`misscheck'"' == "nomisscheck" )
    if ( "`unsorted'" == "unsorted" ) {
        if ( $ReS_nodupcheck ) {
            disp as txt "(note: reshape left unsorted)"
        }
        else {
            disp as txt "(note: reshape left unsorted; original order not preserved)"
        }
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

    Macros
    capture ConfVar $ReS_j
    if ( _rc ) {
        di in blu "Source j($ReS_j) does not exist (is the data already wide?)"
        exit 198
    }
    ConfVar $ReS_j
    confirm var $ReS_j $rVANS $ReS_i $ReS_Xi

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

    /* Save xij variable labels for LONG */
    local iii = 1
    foreach var of global ReS_Xij {
        local var = subinstr(`"`var'"', "@", "$ReS_atwl", 1)
        local xijlab : variable label `var'
        if `"`xijlab'"' != "" {
            if (length(`"`var'"') < 21) {
                char define _dta[__XijVarLab`var'] `"`xijlab'"'
            }
            else {
                char define _dta[__XijVarLab`iii'] ///
                    `"`var' `xijlab'"'
                char define _dta[__XijVarLabTotal] `"`iii'"'
                local iii = `iii' + 1
            }
        }
    }

    tempvar ReS_jcode
    tempfile ReS_jfile
    global ReS_jcode: copy local ReS_jcode
    global ReS_jfile: copy local ReS_jfile
    scalar __greshape_jfile = length(`"`ReS_jfile'"') + 1

    GetJLevels
    ConfVar $ReS_j
    confirm var $ReS_j $ReS_Xi
    CheckVariableTypes
    CopyScalars

    ***********************************************************************
    *                           Do the reshape                            *
    ***********************************************************************

    if ( "$ReS_Xi" != "" ) {
        disp as err "Extra variables not yet allowed:"
        disp as err "    $ReS_Xi"
        exit 198
    }

    * ------------------------
    * Reshape the data to disk
    * ------------------------

    if ( $ReS_nodupcheck ) {
        disp as txt "(note: option -nodupcheck- ignored with greshape wide)"
    }
    local cmd wide write

    keep $ReS_i $ReS_j $ReS_jcode $ReS_Xi $rVANS
    local ReS_Xi: copy global ReS_Xi
    local ReS_Xi: list ReS_Xi - ReS_jcode
    global ReS_Xi: copy local ReS_Xi
    tempfile ReS_Data
    global GTOOLS_CALLER greshape
    local gopts j($ReS_jcode) xij($rVANS) xi($ReS_Xi) f(`ReS_Data') $ReS_atwl `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts'
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
    mata __greshape_addtypes = tokens("$ReS_Xij_addtypes")
    mata __greshape_addvars  = tokens("$ReS_Xij_addvars")
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
    }
    else if ( `benchmarklevel' > 2 ) {
        disp _char(9) "reshape wide step 4: allocated target dataset; ??? seconds."
    }

    * ------------------
    * Read reshaped data
    * ------------------

    local cmd wide read
    global GTOOLS_CALLER greshape
    local gopts xij($ReS_Xij_names) xi($ReS_Xi) f(`ReS_Data') $ReS_atwl `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) `opts'
    cap noi _gtools_internal ${ReS_i}, `gopts'
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------------------
    * Finish in the same style as reshape.Wide
    * ----------------------------------------

    ReportW `oldobs' `oldvars'

    if ( "`fast'" == "" ) restore, not
end

* ---------------------------------------------------------------------
* GetJLevels

capture program drop GetJLevels
program define GetJLevels

    /* determine whether anything to do */
    capture ConfVar $ReS_j
    local islong = (_rc==0)
    local dovalW 0
    local dovalL 0
    local docar  0

    if "$ReS_jv"=="" {
        if `islong' {
            local dovalL 1
        }
        else local dovalW 1
    }

    if "$ReS_Xi"=="" {
        local docar 1
    }

    if `dovalL' {
        FillvalL
    }

    /* nothing to do */
    if `dovalW'==0 & `docar'==0 {
        global S_1 0 /* S_1==0 -> data in memory unchanged */
        exit
    }

    /* convert data to names */
    local varlist "req ex"
    parse "_all"
    quietly {
        local n : word count `varlist'
        mata: __greshape_dsname = J(`n', 1, "")
        parse "`varlist'", parse(" ")
        local i 0
        while `++i' <= `n' {
            mata: __greshape_dsname[`i'] = `"``i''"'
        }
    }

    /* call Fillval and FillXi as required    */
    if `dovalW' & `docar' {
        FillvalW
        FillXi `islong'
    }
    else if `dovalW' {
        FillvalW
    }
    else {
        FillXi `islong'
    }

    global S_1 1
end

capture program drop FillvalW
program define FillvalW
    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    parse "$ReS_Xij", parse(" ")
    quietly {
        local i 1
        mata: __greshape_res = J(rows(__greshape_dsname), 1, "")
        mata: __greshape_u   = J(rows(__greshape_dsname), 1, "")
        while "``i''" != "" {
            local l    = index("``i''","@")
            local l    = cond(`l' == 0, length("``i''")+1, `l')
            local lft  = `substr'("``i''", 1, `l'-1)
            local rgt  = `substr'("``i''", `l'+1, .)
            local rgtl = length("`rgt'")
            local minl = length("`lft'") + `rgtl'

            mata: __greshape_u = selectindex( /*
                */ (strlen(__greshape_dsname) :> `minl') :& /*
                */ (`substr'(__greshape_dsname, 1, `l' - 1) :== `"`lft'"') :& /*
                */ (`substr'(__greshape_dsname, -`rgtl', .) :== `"`rgt'"'))

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

        capture mata: assert(all(__greshape_res :== ""))
        if _rc == 0 {
            no_xij_found
            /* NOTREACHED */
        }
    }

    if ( !$ReS_str ) {
        mata: __greshape_res = strtoreal(__greshape_res)
        mata: __greshape_sel = selectindex(__greshape_res :< .)
    }
    else {
        mata: __greshape_sel = selectindex(__greshape_res :!= "")
    }
    mata: __greshape_res = sort(uniqrows(__greshape_res[__greshape_sel]), 1)
    mata: st_numscalar("__greshape_kout",  cols(tokens(`"$ReS_Xij"')))
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
        mata: SaveJValuesString(__greshape_res)
    }
    mata: __greshape_xijname = sort(uniqrows(__greshape_dsname[__greshape_sel]), 1)

    mata: __greshape_maplevel = MakeMapLevel( /*
        */ __greshape_xijname, /*
        */ __greshape_res,     /*
        */ tokens(`"$ReS_Xij"'))

    mata: st_matrix("__greshape_maplevel", __greshape_maplevel)

    mata: __greshape_rc = CheckVariableTypes( /*
        */ tokens(`"$ReS_Xij_names"'), /*
        */ __greshape_res,             /*
        */ tokens(`"$ReS_Xij"'))

    mata: st_numscalar("__greshape_rc", __greshape_rc)
    if ( `=scalar(__greshape_rc)' ) exit 198

    scalar __greshape_nrows = .
    scalar __greshape_ncols = .

    mata: st_global("ReS_jv",   invtokens(__greshape_res'))
    mata: st_global("ReS_jlen", strofreal(max(strlen(__greshape_res))))

    di in gr "(note: j = $ReS_jv)"
    global ReS_jv2: copy global ReS_jv
end

capture mata: mata drop MakeMapLevel()
mata:
real matrix function MakeMapLevel(
    string colvector dsname,
    string colvector res,
    string rowvector xij)
{
    real scalar i, j, k
    real matrix maplevel
    string scalar r, s
    string rowvector ordered

    k = 1
    ordered  = J(1, cols(xij) * rows(res), "")
    maplevel = J(cols(xij), rows(res), 0)
    for (i = 1; i <= cols(xij); i++) {
        for (j = 1; j <= rows(res); j++) {
            s  = xij[i]
            r  = res[j]
            if ( any(dsname :== (s + r)) ) {
                maplevel[i, j] = k
                ordered[k] = s + r
                k++
            }
        }
    }

    st_global("ReS_Xij_names", invtokens(ordered))
    st_numscalar("__greshape_kxij", cols(ordered))
    return(maplevel)
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
    string rowvector xij)
{
    real scalar i, j, k, t, ix
    real colvector sel
    real rowvector types
    string colvector keep
    string colvector keepnames
    string colvector add
    string scalar r, s, v

    k = 0
    types = J(1, cols(dsname), 0)
    highest = J(cols(xij), 2, 0)
    for (i = 1; i <= cols(xij); i++) {
        for (j = 1; j <= rows(res); j++) {
            s  = xij[i]
            r  = res[j]
            ix = selectindex(dsname :== (s + r))
            t  = highest[i, 1]
            if ( length(ix) ) {
                v = st_vartype(s + r)
                if ( `regex'm(v, "str([1-9][0-9]*|L)") ) {
                    if ( t > 0 ) {
                        errprintf("%s type mismatch with other %s variables\n",
                                  s + r, xij[i])
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
    keepnames = xij[selectindex(sel :!= .)]
    keep      = dsname[sel[selectindex(sel :!= .)]]
    add       = xij[selectindex(sel :== .)]

    st_matrix("__greshape_types", types)

    st_global("ReS_Xij_keepnames", invtokens(keepnames))
    st_global("ReS_Xij_keep", invtokens(keep))
    st_global("ReS_Xij_add",  invtokens(add))

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

void function SaveJValuesString(string colvector res)
{
    real scalar i, fh, max
    string scalar fmt
    colvector C
    fh  = fopen(st_global("ReS_jfile"), "w")
    C   = bufio()
    max = max(strlen(res)) + 1
    fmt = sprintf("%%%gS", max)
    for(i = 1; i <= rows(res); i++) {
        fbufput(C, fh, fmt, res[i] + (max - strlen(res[i])) * char(0))
    }
    fclose(fh)
}
end

capture program drop no_xij_found
program no_xij_found
    di as smcl in red "no xij variables found"
    di as smcl in red "{p 4 4 2}"
    di as smcl in red "You typed something like"
    di as smcl in red "{bf:reshape wide a b, i(i) j(j)}.{break}"
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
    glevelsof $ReS_j, silent local(ReS_jv) cols(" ") group($ReS_jcode) missing
    scalar __greshape_klvls = `r(J)'
    mata: __greshape_jv = strtoname("_" :+ tokens(st_local("ReS_jv"))')
    mata: __greshape_jv = `substr'(__greshape_jv, 2, strlen(__greshape_jv))
    mata: st_global("ReS_jv", invtokens(__greshape_jv'))
    cap mata: assert(sort(__greshape_jv', 1) == uniqrows(__greshape_jv'))
    if _rc {
        disp as err "j defines non-unique or invalid names"
    }
    * mata: SaveJValuesString(__greshape_jv)
    di in gr "(note: j = $ReS_jv)"
    local ReS_jv2: copy global ReS_jv
end

capture program drop CheckVariableTypes
program CheckVariableTypes
    cap disp ustrregexm("a", "a")
    if ( _rc ) local regex regex
    else local regex ustrregex

    local k: copy global rVANS
    local j: copy global ReS_jv
    gettoken j1 jrest: j

    global ReS_Xij_keep: copy global rVANS
    global ReS_Xij_keepnames
    global ReS_Xij_names
    global ReS_Xij_addvars
    global ReS_Xij_addtypes

    foreach var of local k {
        global ReS_Xij_keepnames $ReS_Xij_keepnames `var'`j1'
        global ReS_Xij_names     $ReS_Xij_names     `var'`j1'
        foreach jv of local jrest {
            global ReS_Xij_addtypes $ReS_Xij_addtypes `:type `var''
            global ReS_Xij_addvars  $ReS_Xij_addvars  `var'`jv'
            global ReS_Xij_names    $ReS_Xij_names    `var'`jv'
        }
    }

    scalar __greshape_kout     = `:list sizeof k'
    scalar __greshape_kxij     = `:list sizeof k' * `:list sizeof j'
    scalar __greshape_nrows    = .
    scalar __greshape_ncols    = .
    matrix __greshape_maplevel = 0

    capture matrix drop __greshape_types
    foreach var of varlist $rVANS {
        if ( `regex'm("`:type `var''", "str([1-9][0-9]*|L)") ) {
            if ( `regex's(1) == "L" ) {
                disp as err "Unknown type `:type `var''"
                exit 198
            }
            matrix __greshape_types = nullmat(__greshape_types), `=`regex's(1)'
        }
        else if ( inlist("`:type `var''", "byte", "int", "long", "float", "double") ) {
            matrix __greshape_types = nullmat(__greshape_types), 0
        }
        else {
            disp as err "Unknown type `:type `var''"
            exit 198
        }
    }
end

capture program drop FillXi
program define FillXi /* {1|0} */ /* 1 if islong currently */
    local islong `1'
    local name __greshape_dsname
    quietly {
        if `islong' {
            Dropout __greshape_dsname $ReS_j $ReS_i
            parse "$ReS_Xij", parse(" ")
            local i 1
            while "``i''" != "" {
                Subname ``i'' $ReS_atwl
                mata: `name' = `name'[selectindex(`name' :!= `"$S_1"')]
                local i = `i' + 1
            }
        }
        else { /* wide */
            Dropout __greshape_dsname $ReS_j $ReS_i
            parse "$ReS_Xij", parse(" ")
            local i 1
            while "``i''" != "" {
                local j 1
                local jval : word `j' of $ReS_jv
                while "`jval'"!="" {
                    Subname ``i'' `jval'
                    mata: `name' = `name'[selectindex(`name' :!= `"$S_1"')]
                    local j = `j' + 1
                    local jval : word `j' of $ReS_jv
                }
                local i = `i' + 1
            }
        }

        mata: st_local("N", strofreal(length(`name')))
        local i 1
        while ( `i' <= `=`N'' ) {
            mata: st_local("nam", `name'[`i'])
            global ReS_Xi $ReS_Xi `nam'
            local i = `i' + 1
        }
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

capture program drop CopyScalars
program CopyScalars
    scalar __gtools_greshape_klvls = __greshape_klvls
    scalar __gtools_greshape_kout  = __greshape_kout
    scalar __gtools_greshape_kxij  = __greshape_kxij
    scalar __gtools_greshape_ncols = __greshape_ncols
    scalar __gtools_greshape_nrows = __greshape_nrows
    scalar __gtools_greshape_jfile = __greshape_jfile

    matrix __gtools_greshape_types    = __greshape_types
    matrix __gtools_greshape_maplevel = __greshape_maplevel
end

capture program drop CleanExit
program CleanExit
    Macdrop
    mac drop GTOOLS_OPTS GTOOLS_PARSE

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

    capture matrix drop __greshape_types
    capture matrix drop __greshape_maplevel

    capture matrix drop __gtools_greshape_types
    capture matrix drop __gtools_greshape_maplevel
end

* ---------------------------------------------------------------------
* TODO

capture program drop Veruniq
program define Veruniq

    * ----------------------------
    * TODO: Check that j is unique
    * ----------------------------

    * cap gisid $ReS_i $ReS_jcode
    * if _rc {
    *     di in red as smcl ///
    *     "values of variable {bf:$ReS_j} not unique within {bf:$ReS_i}"
    *     di in red as smcl "{p 4 4 2}"
    *     di in red as smcl "Your data are currently long."
    *     di in red as smcl "You are performing a {bf:reshape wide}."
    *     di in red as smcl "You specified {bf:i($ReS_i)} and"
    *     di in red as smcl "{bf:j($ReS_j)}."
    *     di in red as smcl "There are observations within"
    *     di in red as smcl "{bf:i($ReS_i)} with the same value of"
    *     di in red as smcl "{bf:j($ReS_j)}.  In the long data,"
    *     di in red as smcl "variables {bf:i()} and {bf:j()} together"
    *     di in red as smcl "must uniquely identify the observations."
    *     di in red as smcl
    *     picture err
    *     di in red as smcl "{p 4 4 2}"
    *     di in red as smcl "Type {bf:reshape error} for a list"
    *     di in red as smcl "of the problem variables."
    *     di in red as smcl "{p_end}"
    *     exit 9
    * }

    * ------------------------
    * TODO: Check Xi is unique
    * ------------------------

    * if "$ReS_Xi"=="" {
    *     exit
    * }
    * $ReS_Call sort $ReS_i $ReS_Xi $ReS_j
    * tempvar cnt1 cnt2
    * quietly by $ReS_i: gen `c(obs_t)' `cnt1' = _N
    * quietly by $ReS_i $ReS_Xi: gen `c(obs_t)' `cnt2' = _N
    * capture assert `cnt1' == `cnt2'
    * if _rc==0 {
    *     exit
    * }
    * parse "$ReS_Xi", parse(" ")
    * while "`1'"!=""  {
    *     capture by $ReS_i: assert `1'==`1'[1]
    *     if _rc {
    *         di in red as smcl ///
    *         "variable {bf:`1'} not constant within {bf:$ReS_i}"
    *     }
    *     mac shift
    * }
    * di in red as smcl "{p 4 4 2}"
    * di in red as smcl "Your data are currently long."
    * di in red as smcl "You are performing a {bf:reshape wide}."
    * di in red as smcl "You typed something like"
    * di in red
    * di in red as smcl "{p 8 8 2}"
    * di in red as smcl "{bf:. reshape wide a b, i($ReS_i) j($ReS_j)}"
    * di in red
    * di in red as smcl "{p 4 4 2}"
    * di in red as smcl "There are variables other than {bf:a},"
    * di in red as smcl "{bf:b}, {bf:$ReS_i}, {bf:$ReS_j} in your data."
    * di in red as smcl "They must be constant within"
    * di in red as smcl "{bf:$ReS_i} because that is the only way they can"
    * di in red as smcl "fit into wide data without loss of information."
    * di in red
    * di in red as smcl "{p 4 4 2}"
    * di in red as smcl "The variable or variables listed above are"
    * di in red as smcl "not constant within {bf:$ReS_i}.
    * di in red as smcl "Perhaps the values are in error."
    * di in red as smcl "Type {bf:reshape error} for a list of the"
    * di in red as smcl "problem observations."
    * di in red
    * di in red as smcl "{p 4 4 2}"
    * di in red as smcl "Either that, or the values vary because"
    * di in red as smcl "they should vary, in which"
    * di in red as smcl "case you must either add the variables"
    * di in red as smcl "to the list of xij variables to be reshaped,"
    * di in red as smcl "or {bf:drop} them."
    * di in red as smcl "{p_end}"
    * exit 9
end

* ---------------------------------------------------------------------
* Helpers taken near-verbatim from reshape.ado

capture program drop Macdrop
program define Macdrop
    mac drop ReS_cmd           ///
             ReS_Xij           ///
             ReS_Xij_add       ///
             ReS_Xij_keep      ///
             ReS_Xij_keepnames ///
             ReS_Xij_names     ///
             ReS_Xij_addtypes  ///
             ReS_Xij_addvars   ///
             ReS_nodupcheck    ///
             ReS_nomisscheck   ///
             ReS_atwl          ///
             ReS_i             ///
             ReS_j             ///
             ReS_jfile         ///
             ReS_jcode         ///
             ReS_jlen          ///
             ReS_jv            ///
             ReS_jv2           ///
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
        "{bf:greshape wide a b, i(}{it:i}{bf:) j(}{it:j}{bf:)}  " ///
        "  ({it:j} existing variable)"
        di `how' _col(9) ///
        "wide to long: " ///
        "{bf:greshape long a b, i(}{it:i}{bf:) j(}{it:j}{bf:)}  " ///
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
    di in gr "j variable (`n' values)" _col(43) "->" _col(48) /*
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

    di in smcl _n in gr /*
    */ "Data" _col(36) "`wide'" _col(43) "->" _col(48) "`long'" /*
    */ _n "{hline 77}"

    di in gr "Number of obs." _col(32) in ye %8.0g `oobs' /*
    */ in gr _col(43) "->" in ye %8.0g _N

    quietly desc, short

    di in gr "Number of variables" _col(32) in ye %8.0g `ovars' /*
    */ in gr _col(43) "->" in ye %8.0g r(k)
end

capture program drop ReportW
program define ReportW /* old_obs old_vars */
    Report1 `1' `2' long wide

    local n : word count $ReS_jv2
    local col = 31+(9-length("$ReS_j"))
    di in gr "j variable (`n' values)" /*
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

    * NOTE: This takes the value of j to be position at @ instead of at
    * the end

    global rVANS
    parse "$ReS_Xij", parse(" ")
    local i 1
    while "``i''"!="" {
        Subname ``i''
        global rVANS "$rVANS $S_1"
        local i = `i' + 1
    }
    global S_1
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

capture program drop Subname
program define Subname /* <name-maybe-with-@> <tosub> */
    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr
    local name "`1'"
    local sub "`2'"
    local l = index("`name'","@")
    local l = cond(`l'==0, length("`name'")+1,`l')
    local a = `substr'("`name'",1,`l'-1)
    local c = `substr'("`name'",`l'+1,.)
    global S_1 "`a'`sub'`c'"
end

capture program drop NonUniqueLongID
program define NonUniqueLongID
	di in red as smcl ///
	    "variable {bf:id} does not uniquely identify the observations"
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Your data are currently wide."
	di in red as smcl "You are performing a {bf:reshape long}."
	di in red as smcl "You specified {bf:i($ReS_i)} and {bf:j($ReS_j)}."
	di in red as smcl "In the current wide form, variable {bf:$ReS_i}"
	di in red as smcl "should uniquely identify the observations."
	di in red as smcl "Remember this picture:"
	di in red
	picture err
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Type {stata gduplicates examples $ReS_i} for examples of"
	di in red as smcl "problem observations."
	di in red as smcl "{p_end}"
	exit 9
end

capture program drop NonUniqueWideJ
program NonUniqueWideJ
    di in red as smcl ///
    "values of variable {bf:$ReS_j} not unique within {bf:$ReS_i}"
    di in red as smcl "{p 4 4 2}"
    di in red as smcl "Your data are currently long."
    di in red as smcl "You are performing a {bf:reshape wide}."
    di in red as smcl "You specified {bf:i($ReS_i)} and"
    di in red as smcl "{bf:j($ReS_j)}."
    di in red as smcl "There are observations within"
    di in red as smcl "{bf:i($ReS_i)} with the same value of"
    di in red as smcl "{bf:j($ReS_j)}.  In the long data,"
    di in red as smcl "variables {bf:i()} and {bf:j()} together"
    di in red as smcl "must uniquely identify the observations."
    di in red as smcl
    picture err
	di in red as smcl "{p 4 4 2}"
	di in red as smcl "Type {stata gduplicates examples $ReS_i $ReS_j} for examples of"
	di in red as smcl "problem observations."
	di in red as smcl "{p_end}"
    exit 9
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
	di in red as smcl "{bf:. reshape wide a b, i($ReS_i) j($ReS_j)}"
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
	exit 9
end
