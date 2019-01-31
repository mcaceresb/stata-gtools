*! version 0.1.0 29Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! (beta) Fast implementation of reshape using C plugins

* TODO: {keepxi|dropxi}
*
* {opt:keepxi} keeps variables not named in the reshape statement. This
* is computationally expensive because {cmd:greshape} has to check
* whether or not they are constant within each {cmd:i} group (if they
* are not then {cmd:greshape} will fail).
*
* {opt:dropxi} drops variables not named in the reshape statement.
*
* match(numbers|strings|anything|/regex/)
*
* TODO: Careful with reshape {wide|long} x x1 x2; is x missing or excluded?
*
* TODO: Optimize because the assumption is that i is unique!
*
* TODO: Why does i have to be unique? No real reason; dispense later on...
*       Maybe bc of lossy stuff from long to wide and back? Just add option...
*
* TODO: Sort levels (mind that strings are not sorted as nubmers; also mind var order)

capture program drop greshape
program greshape, rclass
    version 13.1

    global GTOOLS_PARSE       ///
        compress              /// Try to compress strL variables
        forcestrl             /// Force reading strL variables (stata 14 and above only)
        Verbose               /// Print info during function execution
        _CTOLerance(passthru) /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark             /// Benchmark function
        BENCHmarklevel(int 0) /// Benchmark various steps of the plugin
        HASHmethod(passthru)  /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru) /// error|fallback: On collision, use native command or throw error
        debug(passthru)       //  Print debugging info to console

    u_mi_not_mi_set reshape other
    global ReS_Call : di "version " string(_caller()) ":"

    if ( `"`1'"' == "clear" ) {
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
        exit
    }

    local i = 0

    disp `"debug greshape: *"' _n(1) `"    * = `*'"'
    while ( `"``i''"' != "" ) {
        disp `"    `i++' = ``i''"'
    }

    if ( inlist(`"`1'"', "wide", "long") ) {
        disp "debug greshape: 1"
        cap noi DoNew `*'
        if ( _rc == 17999 ) {
            reshape `0'
            exit 0
        }
        else if ( _rc == 17001 ) {
            di as txt "(no observations)"
            exit 0
        }
        else if ( _rc ) exit _rc
        else exit 0
    }

    local syntax : char _dta[ReS_ver]

    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    if ( `"`1'"' == "" | `"`1'"' == `substr'("query", 1, length(`"`1'"')) ) {
        if ( `"`syntax'"' == "" | `"`syntax'"' == "v.2" ) {
            Query
            exit
        }
        local 1 "query"
    }

    if ( `"`syntax'"' == "" ) {
        IfOld `1'
        if ( `s(oldflag)' ) {
            disp as err "Old syntax is not supported by -greshape-"
            exit 198
        }
        else {
            disp "debug greshape: 2"
            cap noi DoNew `*'
            local rc = _rc
            char _dta[ReS_ver] "v.2"
        }
    }
    else if ( `"`syntax'"' == "v.1" ) {
        disp as err "Old syntax is not supported by -greshape-"
        exit 198
    }
    else {
        disp "debug greshape: 3"
        cap noi DoNew `*'
        local rc = _rc
    }

    if ( `rc' == 17999 ) {
        reshape `0'
        exit 0
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) exit `rc'
end

* ---------------------------------------------------------------------
* Reshape long

capture program drop Long
program define Long /* reshape long */
    local oldobs = _N
    quietly describe, short
    local oldvars = r(k)

    Macros
    confirm var $ReS_i $Res_Xi
    capture confirm new var $ReS_j
    if _rc {
        di in blu "(already long)"
        exit
    }

	Macros2
	confirm var $ReS_i $Res_Xi

    * ------------------------------------------
    * TODO: I believe this is the actual reshape
    * ------------------------------------------

    disp "{hline 26}"
    disp "DEBUG: THIS IS THE RESHAPE"
    disp "{hline 26}"

    * global GTOOLS_OPTS `weights' `compress' `forcestrl' `_ctolerance'
    * global GTOOLS_OPTS ${GTOOLS_OPTS} `verbose' `benchmark' `benchmarklevel'
    * global GTOOLS_OPTS ${GTOOLS_OPTS} `oncollision' `hashmethod' `debug'
    * global GTOOLS_CALL `if' `in'

    * ReS_i    i
	* ReS_j    j
    * ReS_jv   j values
    * ReS_Xij  reshape variables
    * Res_Xi   non-reshape variables (must be constant within group)
    * ReS_str  whether there are string variables involved; shouldn't be a problem
    *
    * Not sure; they have to do with the variable renaming/etc. syntax of reshape
    * rVANS
    * ReS_atwl
    * S_1
    * S_2
    * S_1_full

    foreach res in ReS_i ReS_j ReS_jv ReS_Xij ReS_Xij_names Res_Xi ReS_str rVANS ReS_atwl S_1 S_2 S_1_full {
        disp "    `res': ${`res'}"
    }
    if ( $ReS_str ) local string string
    * $ReS_jv
    * TODO: Check unique by ID

    * Reshape the data to disk
    * ------------------------

    tempfile ReS_Data
    global GTOOLS_CALLER greshape
    local gopts greshape(long, xij($ReS_Xij_names) xi($Res_Xi) f(`ReS_Data') $ReS_atwl string)
    local gopts `gopts' gfunction(reshape) ${GTOOLS_OPTS}
    cap noi _gtools_internal ${ReS_i}, `gopts'
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * Reshape the data to memory
    * --------------------------

    keep  $ReS_i $ReS_Xij_keep $Res_Xi
    * desc
    * disp "[$ReS_Xij_add] ($ReS_Xij_keep) ($ReS_Xij_keepnames)"
    mata: __greshape_types = ("long", J(1, `:word count $ReS_Xij_add', "double"))
    mata: __greshape_vars  = "$ReS_j", tokens("$ReS_Xij_add")
    mata: (void) st_addvar(__greshape_types, __greshape_vars, 0)
    rename ($ReS_Xij_keep) ($ReS_Xij_keepnames)
    order $ReS_i $ReS_j $ReS_Xij $Res_Xi
    qui expand `=scalar(__gtools_greshape_klvls)'
    * _char(9) "reshape long step 4: allocated new dataset in Stata";

    * Read reshaped data
    * ------------------

    desc
    disp "$ReS_i $ReS_j $ReS_Xij $Res_Xi"
    global GTOOLS_CALLER greshape
    local gopts greshape(long, j($ReS_j) xij($ReS_Xij) xi($Res_Xi) f(`ReS_Data') $ReS_atwl string read)
    local gopts `gopts' gfunction(reshape) ${GTOOLS_OPTS}
    cap noi _gtools_internal ${ReS_i}, `gopts'
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc
    * _char(9) "reshape long step 5: read reshaped data into Stata"

    disp "{hline 24}"
    disp "DEBUG: THE PLUGIN RAN!!!"
    disp "{hline 24}"
    exit 17123

    * cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/src/ado
    * qui do _gtools_internal.ado

    * qui do greshape.ado
    * set rmsg on
    * clear
    * clear _all
    * set obs 1000000
    * * set obs 5
    * gen y = _n
    * gen long  x1  = _n
    * gen float x2  = runiform()
    * gen float x15 = _n
    * gen float z10 = _n
    * gen float z20 = runiform()
    * gen double z15 = runiform()
    * preserve
    *     greshape clear
    *     greshape long x z, i(y) j(j)
    * restore
    * preserve
    *     reshape clear
    *     reshape long x, i(y) j(j)
    * restore
    * preserve
    *     reshape clear
    *     fastreshape long x, i(y) j(j)
    * restore

    * gen j = "123456789012345678901234567890 " + string(_j)
    * drop _j
    * reshape wide x, i(y) j(j) string
    *
    * set tracedepth 3
    * set trace off

    * -----------------------------------------------
    * TODO: I believe the above is the actual reshape
    * -----------------------------------------------

    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    /* Apply J value label and to variable label for LONG Format*/
    local isstr : char _dta[ReS_str]
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

    if `"`syntax'"' != "v.1" {
        ReportL `oldobs' `oldvars'
    }
end

capture program drop Macros2
program define Macros2 /* [preserve] */ /* returns S_1 */

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

    if "$Res_Xi"=="" {
        local syntax : char _dta[ReS_ver]
        if "`syntax'"=="v.2" {
            local docar 1
        }
    }

    if `dovalL' {
        * FillvalL
        disp as err "greshape/Macros2/FillvalL not yet supported by greshape"
        exit 198
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
            * TODO: Give user options over this (see top)
            /* NOTREACHED */
        }
    }

    if !$ReS_str {
        mata: __greshape_sel = selectindex(strtoreal(__greshape_res) :< .)
    }
    else {
        mata: __greshape_sel = selectindex(__greshape_res :!= "")
    }
    mata: __greshape_xijname = sort(uniqrows(__greshape_dsname[__greshape_sel]), 1)
    mata: __greshape_res     = sort(uniqrows(__greshape_res[__greshape_sel]), 1)

    mata: __greshape_maplevel = MakeMapLevel( /*
        */ __greshape_xijname, __greshape_res, tokens(`"$ReS_Xij"'))

    mata: __greshape_highest = GetHighestLevel( /*
        */ __greshape_xijname, __greshape_res, tokens(`"$ReS_Xij"'))

    scalar __gtools_greshape_nrows = .
    scalar __gtools_greshape_ncols = .

    mata: st_numscalar("__gtools_greshape_kout",  cols(tokens(`"$ReS_Xij"')))
    mata: st_numscalar("__gtools_greshape_klvls", rows(__greshape_res))
    mata: st_matrix("__gtools_greshape_maplevel", __greshape_maplevel)

    mata: st_global("ReS_Xij_names", invtokens(__greshape_xijname'))
    mata: st_global("ReS_jv", invtokens(__greshape_res'))
    di in gr "(note: j = $ReS_jv)"
end

capture mata: mata drop MakeMapLevel()
mata:
real matrix function MakeMapLevel(
    string colvector dsname,
    string colvector res,
    string rowvector xij)
{
    real scalar i, j, ix
    real matrix maplevel
    string scalar r, s

    maplevel = J(cols(xij), rows(res), .)
    for (i = 1; i <= cols(xij); i++) {
        for (j = 1; j <= rows(res); j++) {
            s  = xij[i]
            r  = res[j]
            ix = selectindex(dsname :== (s + r))
            maplevel[i, j] = length(ix)? ix: 0
        }
    }

    return(maplevel)
}
end

capture mata: mata drop GetHighestLevel()
mata:
void function GetHighestLevel(
    string colvector dsname,
    string colvector res,
    string rowvector xij)
{
    real scalar i, j, ix
    real matrix maplevel
    real  colvector sel
    string colvector keep
    string colvector keepnames
    string colvector add
    string scalar r, s

    highest = J(cols(xij), 2, 0)
    for (i = 1; i <= cols(xij); i++) {
        for (j = 1; j <= rows(res); j++) {
            s  = xij[i]
            r  = res[j]
            ix = selectindex(dsname :== (s + r))
            if ( length(ix) ) {
                if ( st_vartype(s + r) == "byte" ) {
                    if ( highest[i, 1] < 1 ) {
                        highest[i, 1] = 1
                        highest[i, 2] = ix
                    }
                }
                else if ( st_vartype(s + r) == "int" ) {
                    if ( highest[i, 1] < 2 ) {
                        highest[i, 1] = 2
                        highest[i, 2] = ix
                    }
                }
                else if ( st_vartype(s + r) == "long" ) {
                    if ( highest[i, 1] < 3 ) {
                        highest[i, 1] = 3
                        highest[i, 2] = ix
                    }
                    if ( highest[i, 1] == 4 ) {
                        highest[i, 1] = .
                        highest[i, 2] = .
                    }
                }
                else if ( st_vartype(s + r) == "float" ) {
                    if ( highest[i, 1] < 2 ) {
                        highest[i, 1] = 4
                        highest[i, 2] = ix
                    }
                    if ( highest[i, 1] == 3 ) {
                        highest[i, 1] = .
                        highest[i, 2] = .
                    }
                }
                else if ( st_vartype(s + r) == "double" ) {
                    highest[i, 1] = 5
                    highest[i, 2] = ix
                }
            }
        }
    }

    sel       = highest[., 2]
    keepnames = xij[selectindex(sel :!= .)]
    keep      = dsname[sel[selectindex(sel :!= .)]]'
    add       = xij[selectindex(sel :== .)]

    st_global("ReS_Xij_keepnames", invtokens(keepnames))
    st_global("ReS_Xij_keep",      invtokens(keep))
    st_global("ReS_Xij_add",       invtokens(add))
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

	qui glevelsof $ReS_j, silent local(ReS_jv)
    if ( 0 ) {
        * TODO: Strict let fail with spaces; otherwise replace
        mata: __greshape_jv  = tokens(st_local("ReS_jv"))
        mata: __greshape_jv_ = `substr'(__greshape_jv, 1, 1) :!= "_"
        mata: __greshape_jv  = strtoname(__greshape_jv)
        mata: __greshape_jv  = `substr'(__greshape_jv, 1 :+ __greshape_jv_, strlen(__greshape_jv))
        cap mata: assert(__greshape_jv' == uniqrows(__greshape_jv'))
        if _rc {
            disp as err "j defines non-unique or invalid names"
        }
    }
    else {
        global ReS_jv: copy local ReS_jv
    }
    di in gr "(note: j = $ReS_jv)"
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
            global Res_Xi $Res_Xi `nam'
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

* ---------------------------------------------------------------------
* Reshape simple

capture program drop Simple
program define Simple /* {wide|long} <funnylist>, i(varlist) [j(varname [values])] */

    local cmd "`1'"
    mac shift
    parse "`*'", parse(" ,")
    while "`1'"!="" & "`1'"!="," {
        local list `list' `1'
        mac shift
    }

    if ( `"`list'"' == "" ) {
        error 198
    }

    if ( `"`1'"' != "," ) {
        di as smcl in red "option {bf:i()} required"
        di in red
        picture err cmds
        exit 198
    }

    local options "I(string) J(string) ATwl(string) String"
    parse "`*'"
    if ( `"`i'"' == "" ) {
        di as smcl in red "option {bf:i()} required"
        di in red
        picture err cmds
        exit 198
    }
    unabbrev `i'
    local i "`s(varlist)'"

    if ( `"`j'"' != "" ) {
        parse "`j'", parse(" ")
        local jvar "`1'"
        mac shift
        local jvals "`*'"
    }
    else local jvar "_j"

    if ( `"`cmd'"' == "wide" ) {
        /* When reshaping wide we can -unab- the variable list */
        capture unab list : `list' /* ignore _rc, error caught later */
        /* When reshaping wide we can -unab- the j variable */
        capture unab jvar : `jvar' /* use -unab- not -ConfVar- here */
        if _rc {
            if _rc==111 {
                if ("`jvar'"=="_j") {
                    di as smcl in red ///
                    "option {bf:j()} required"
                    picture err cmds
                    exit 198
                }
                di in red "variable `jvar' not found"
                di as smcl in red "{p 4 4 2}"
                di as smcl in red "Data are already wide."
                di as smcl in red "{p_end}"
                exit 111
            }
            ConfVar `jvar'
            exit 198    /* just in case */
        }
    }
    else {
        capture confirm new var `jvar'
        if _rc {
            if _rc==110 {
                di in red "variable `jvar' already exists"
                di as smcl in red "{p 4 4 2}"
                di as smcl in red "Data are already long."
                di as smcl in red "{p_end}"
                exit 110
            }
            confirm new var `jvar'
            exit 198 /* just in case */
        }
    }

    if ( `"`atwl'"' != "" ) {
        local atwl "atwl(`atwl')"
    }

    if ( `"`string'"' != "" ) {
        local string ", string"
    }

    * ---------------------------------------------------------
    * TODO: This is not the reshape; this sets the variables...
    * ---------------------------------------------------------
    * TODO: Replace all these with greshape
    $ReS_Call reshape clear
    $ReS_Call reshape i `i'
    $ReS_Call reshape j `jvar' `jvals' `string'
    $ReS_Call reshape xij `list' `atwl'
    * ---------------------------------------------------------
    * TODO: This is not the reshape; this sets the variables...
    * ---------------------------------------------------------
end

* ---------------------------------------------------------------------
* Helpers taken near-verbatim from reshape.ado

capture program drop IfOld
program define IfOld, sclass
    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    if `"`1'"' == "" {
        sret local oldflag 0
        exit
    }
    local l = length("`1'")
    if `"`1'"' == `substr'("groups", 1, `l') | /*
    */ `"`1'"' == `substr'("vars",   1, `l') | /*
    */ `"`1'"' == `substr'("cons",   1, `l') | /*
    */ `"`1'"' == `substr'("query",  1, `l') {
        sret local oldflag 1
        exit
    }
    sret local oldflag 0
end

capture program drop Macdrop
program define Macdrop
    mac drop ReS_j ReS_jv ReS_i ReS_Xij rVANS Res_Xi /*
    */ ReS_atwl ReS_str S_1 S_2 S_1_full
end

capture program drop DoNew
program define DoNew
    disp "debug greshape/DoNew: `0'"
    local c "`1'"
    mac shift

    if ( `"`c'"' == "i" ) {
        if ( "`*'" == "" ) error 198
        unabbrev `*', max(10) min(1)
        char _dta[ReS_i] "`s(varlist)'"
        exit
    }

    if ( `"`c'"' == "j" ) {
        disp "debug greshape/DoNew: J"
        * J `*'
        * exit
        disp as err "j not yet supported by greshape"
        exit 198
    }

    if ( `"`c'"' == "xij" ) {
        disp "debug greshape/DoNew: Xij"
        * Xij `*'
        * exit
        disp as err "xij not yet supported by greshape"
        exit 198
    }

    if ( `"`c'"' == "xi" ) {
        sret clear
        if ( `"`*'"' != "" ) {
            unabbrev `*'
        }
        char _dta[Res_Xi] "`s(varlist)'"
        exit
    }

    if ( `"`c'"' == "" ) { /* reshape */
        Query
        exit
    }

    if ( `"`c'"' == "long" ) { /* reshape long */
        if ( `"`1'"' != "" ) {
            Simple long `*'
        }
        disp "debug greshape/DoNew: Long"
        capture noisily Long `*'
        Macdrop
        exit _rc
    }

    if ( `"`c'"' == "wide" ) { /* reshape wide */
        if ( `"`1'"' != "" ) {
            * capture noisily Simple wide `*'
            disp "debug greshape/DoNew: Simple wide"
            disp as err "simple wide not yet supported by greshape"
            exit 198
            exit _rc
        }
        disp "debug greshape/DoNew: Wide"
        * capture noisily Wide `*'
        Macdrop
        disp as err "wide not yet supported by greshape"
        exit 198
        exit _rc
    }

    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    if `"`c'"' == `substr'("error", 1, max(3, length("`c'"))) {
        disp "debug greshape/DoNew: Qerror"
        * capture noisily Qerror `*'
        Macdrop
        disp as err "qerror not yet supported by greshape"
        exit 198
        exit _rc
    }

    IfOld `c'
    if ( `s(oldflag)' ) {
        disp as err "Old syntax is not supported by -greshape-"
        exit 198
    }
    di as err "invalid syntax"
    di as err as smcl "{p 4 4 2}"
    di as err as smcl ///
    "In the {bf:greshape} command that you typed, " ///
    "you omitted the word {bf:wide} or {bf:long},"
    di as err as smcl ///
    "or substituted some other word for it.  You should have typed"
    di as err
    di as err as smcl "        . {bf:greshape wide} {it:varlist}{bf:, ...}"
    di as err "    or"
    di as err as smcl "        . {bf:greshape long} {it:varlist}, ..."
    di as err
    di as err as smcl "{p 4 4 2}"
    di as err as smcl "You might have omitted {it:varlist}, too."
    di as err as smcl "The basic syntax of {bf:greshape} is"
    di as err as smcl "{p_end}"
    di as err
    picture err cmd
    exit 198
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

capture program drop Query
program define Query
    if ( `"`*'"' != "" ) {
        error 198
    }
    local cons   : char _dta[ReS_i]
    local grpvar : char _dta[ReS_j]
    local values : char _dta[ReS_jv]
    local vars   : char _dta[ReS_Xij]
    local car    : char _dta[Res_Xi]
    local atwl   : char _dta[ReS_atwl]
    local isstr  : char _dta[ReS_str]

    local hasinfo 0
    local hasinfo = `hasinfo' | ("`cons'"!="")
    local hasinfo = `hasinfo' | ("`grpvar'"!="")
    local hasinfo = `hasinfo' | ("`values'"!="")
    local hasinfo = `hasinfo' | ("`values'"!="")
    local hasinfo = `hasinfo' | ("`vars'"!="")
    local hasinfo = `hasinfo' | ("`car'"!="")
    local hasinfo = `hasinfo' | ("`atwl'"!="")
    local hasinfo = `hasinfo' | ("`isstr'"!="")


    if ( `"`grpvar'"' != "" ) {
        capture ConfVar `grpvar'
        if _rc {
            di in gr " (data are wide)"
        }
        else di in gr " (data are long)"
    }
    else {
        di in gr " (data have not been reshaped yet)"
    }
    di

    if ( !`hasinfo' ) {
        di as smcl in green "    Syntax reminder:"
        picture txt cmds
        di in green
        di as smcl in green "{p 4 4 2}"
        di as smcl in green "See {helpb greshape:help greshape}"
        di as smcl in green "for more information."
        di as smcl in green "{p_end}"
        exit
        /*NOTREACHED*/
    }

    if ( `"`cons'"' == "" ) {
        local ccons "in gr"
        local cons "<varlist>"
    }

    if ( `"`grpvar'"' == "" ) {
        local cgrpvar "in gr"
        local grpvar "<varname>"
        if "`values'"=="" {
            local values "[<#> - <#>]"
        }
    }
    else if ( `isstr' ) {
        local values "`values', string"
    }

    if ( `"`vars'"' == "" ) {
        local cvars "in gr"
        local vars "<varnames-without-#j-suffix>"
    }
    else {
        if ( `"`atwl'"' != "" ) {
            local vars "`vars', atwl(`atwl')"
        }
    }

    if ( `"`car'"' == "" ) {
        local ccar "in gr"
        local car "<varlist>"
    }

    di in smcl in gr "{c TLC}{hline 30}{c TT}{hline 46}{c TRC}" _n /*
    */ "{c |} Xij" _col(32) "{c |} Command/contents" _col(79) "{c |}" _n /*
    */ in gr "{c LT}{hline 30}{c +}{hline 46}{c RT}"

    di in smcl in gr /*
    */ "{c |} Subscript i,j definitions:" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr /*
    */ "{c |}  group id variable(s)" _col(32) "{c |} greshape i " _c
    Qlist 45 "`ccons'" `cons'

    di in smcl in gr /*
    */ "{c |}  within-group variable" _col(32) "{c |} greshape j " _c

    Qlist 45 "`cgrpvar'" `grpvar' `values'
    di in smcl in gr /*
    */ "{c |}   and its range" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr "{c |}" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr /*
    */ "{c |} Variable X definitions:" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr /*
    */ "{c |}  varying within group" _col(32) "{c |} greshape xij " _c
    Qlist 47 "`cvars'" `vars'

    di in smcl in gr /*
    */ "{c |}  constant within group (opt) {c |} greshape xi  " _c
    Qlist 47 "`ccar'" `car'

    di in smcl in gr "{c BLC}{hline 30}{c BT}{hline 46}{c BRC}"

    local cons   : char _dta[ReS_i]
    local grpvar : char _dta[ReS_j]
    local values : char _dta[ReS_jv]
    local vars   : char _dta[ReS_Xij]
    local car    : char _dta[Res_Xi]

    if ( `"`cons'"' == "" ) {
        di in gr as smcl "First type " ///
        "{bf:greshape i} to define the i variable."
        exit
    }
    if ( `"`grpvar'"' == "" ) {
        di in gr as smcl "Type " ///
        "{bf:greshape j} " ///
        "to define the j variable and, optionally, values."
        exit
    }
    if ( `"`vars'"' == "" ) {
        di in gr as smcl "Type "///
        "{bf:greshape xij} ///
        " to define variables that vary within i."
        exit
    }
    if ( `"`car'"' == "" ) {
        di in gr as smcl ///
            "Optionally type {bf:greshape xi} " ///
            "to define variables that are constant within i."
    }

    capture ConfVar `grpvar'
    if _rc {
        di in gr as smcl "Type " ///
        "{bf:greshape long}" ///
        " to convert the data to long form."
        exit
    }
    di in gr as smcl "Type {bf:greshape wide}" ///
        " to convert the data to wide form."
end

capture program drop Qlist
program define Qlist /* col <optcolor> stuff */
    local col `1'
    local clr "`2'"
    mac shift 2
    while ( `"`1'"' != "" ) {
        local l = length("`1'")
        if ( (`col' + `l' + 1) >= 79 ) {
            local skip = 79 - `col'
            di in smcl in gr _skip(`skip') "{c |}" _n /*
            */ "{c |}" _col(32) "{c |} " _c
            local col 34
        }
        di in ye `clr' "`1' " _c
        local col = `col' + `l' + 1
        mac shift
    }
    local skip = 79 - `col'
    di in smcl in gr _skip(`skip') "{c |}"
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

* ---------------------------------------------------------------------
* Second set of helpers

capture program drop Macros
program define Macros /* reshape macro check utility */
    global ReS_j    : char _dta[ReS_j]
    global ReS_jv   : char _dta[ReS_jv]
    global ReS_jv2
    global ReS_i    : char _dta[ReS_i]
    global ReS_Xij  : char _dta[ReS_Xij]
    global Res_Xi   : char _dta[Res_Xi]
    global ReS_atwl : char _dta[ReS_atwl]
    global ReS_str  : char _dta[ReS_str]
    local syntax    : char _dta[ReS_ver]

    if ( "$ReS_j" == "" ) {
        if ( `"`syntax'"' == "v.1" ) {
            NotDefd "reshape groups"
        }
        else NotDefd "reshape j"
    }

    capture ConfVar $ReS_j
    if _rc==0 {
        Chkj $ReS_j $ReS_str
        if $ReS_str==0 {
            capture assert $ReS_j<.
            if _rc {
                di in red as smcl ///
                "variable {bf:$ReS_j} contains missing values"
                exit 498
            }
        }
        else {
            capture assert trim($ReS_j)!=""
            if _rc {
                di in red as smcl ///
                "variable {bf:$ReS_j} contains missing values"
                exit 498
            }
            capture assert $ReS_j==trim($ReS_j)
            if _rc {
                di in red as smcl ///
            "variable {bf:$ReS_j} has leading or trailing blanks"
                exit 498
            }
        }
    }

    if "$ReS_jv"=="" {
        if "`syntax'"=="v.1" {
            NotDefd "reshape groups"
        }
    }
    if "$ReS_i"=="" {
        if "`syntax'"=="v.1" {
            NotDefd "reshape cons"
        }
        else    NotDefd "reshape i"
    }
    if "$ReS_Xij"=="" {
        if "`syntax'"=="v.1" {
            NotDefd "reshape vars"
        }
        else NotDefd "reshape xij"
    }

    global rVANS
    parse "$ReS_Xij", parse(" ")
    local i 1
    while "``i''"!="" {
        Subname ``i'' $ReS_atwl
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

capture program drop Chkj
program define Chkj /* j whether-string */
    local grpvar "`1'"
    local isstr `2'

    capture ConfVar `grpvar'
    if ( _rc ) exit

    capture confirm string var `grpvar'
    if ( _rc == 0 ) {
        if ( !`isstr' ) {
            di in red as smcl ///
        "variable {bf:`grpvar'} is string; specify {bf:string} option"
            exit 109
        }
    }
    else {
        if ( `isstr' ) {
            di in red as smcl "variable {bf:`grpvar'} is numeric"
            exit 109
        }
    }
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

capture program drop mkrtmpST
program define mkrtmpST
    global rtmpST
    parse "$ReS_Xij", parse(" ")
    while "`1'" != "" {
        local ct "empty"
        local i 1
        local val : word `i' of $ReS_jv
        while "`val'" != "" {
            Subname `1' `val'
            local van "$S_1"
            capture confirm var `van'
            if _rc==0 {
                local nt : type `van'
                Recast "`ct'" `nt'
                local ct "$S_1"
                if "`ct'"=="" {
                    noi di in red as smcl ///
    "variable {bf:`van'} type mismatch with other {bf:`1'} variables"
                    exit 198
                }
            }
            else {
                capture confirm new var `van'
                if _rc {
                    di in red as smcl ///
     "variable {bf:`van'} implied name too long"
                    exit 198
                }
            }
            local i=`i'+1
            local val : word `i' of $ReS_jv
        }
        if "`ct'"=="empty" {
            local ct "byte"
        }
        global rtmpST "$rtmpST `ct'"
        mac shift
    }
end
