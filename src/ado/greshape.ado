*! version 0.1.0 29Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! (beta) Fast implementation of reshape using C plugins

* TODO: What happens if disk full; what error do you get and what not... GET return code from fwrite!!! ya crazy...
*
* TODO: xi(collapse syntax!!! the default being first + checking all iden; if any have explicit stats, don't check; allow strings!)
*
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
* TODO: Check unique by ID
* TODO: Optimize because the assumption is that i is unique!
* TODO: But why does i have to be unique? No real reason; dispense later on...
*       Maybe bc of lossy stuff from long to wide and back? Just add option...
*
* TODO: Sort levels (mind that strings are not sorted as nubmers; also mind var order)
*
* TODO: greshape with no observations
*
* TODO: gtools options
*
* TODO: xi variables
*
* TODO: timers!
*
* TODO: Subset j with a numlist or similar; e.g. j(year 2001 2003 2004)
*
* TODO: Do this? greshape does not support highlighting problem observations with the fastreshape error command ex post
*
* TODO: Clue for atwl? fastreshape does not support the atwl(char) argument. Use the @ character ins
*
* TODO: xi([varlist], {keep|drop})
*
* TODO: reshape pivot long (reshape gather?)
*       Would be equivaent to the R long!
*       1. NO hashing or whatever; no need to sort.
*       2. Reshape as you you read the data
*       3. reshape long
*           // reshape as you read (~much faster; no sort)
*           for (i = 0; i < N; i++) {
*               for (j = 0; j < jvars; j++) {
*                   for (k = 0; k < kvars; k++) {
*                       output[i * ktot + j, k] = source[i, k];
*                   }
*                   output[i * ktot + j, kvars]     = varnames[j];
*                   output[i * ktot + j, kvars + 1] = source[i, kvars + 1];
*               }
*           }
*           // Save to disk; allocate in memory (~much faster; fewer variables)
*           // read from disk back to stata (~much slower; j is always string)
*       4. reshape wide
*           // basically the same, no?
*           // You need to encode j; if group is unbalanced then output missing...
*           // This is more or less identical except for variable naming!
*
* TODO: Tests
*
* 1. str only i
*     - num only xij
*         * j num
*         * j str
*     - str only xij
*         * j num
*         * j str
*     - mix of num and str
*         * j num
*         * j str
* 2. num only i
*     - num only xij
*         * j num
*         * j str
*     - str only xij
*         * j num
*         * j str
*     - mix of num and str
*         * j num
*         * j str
* 3. mix of num and str
*     - num only xij
*         * j num
*         * j str
*     - str only xij
*         * j num
*         * j str
*     - mix of num and str
*         * j num
*         * j str

/*
cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/src/ado
qui do _gtools_internal.ado

clear
set obs 10
gen i = _n
gen j = _n
gen long  x = _n
gen float z = runiform()
reshape wide x z, i(i) j(j)

clear
set obs 5
gen i = _n
gen float x15 = _n
gen str21 z10 = "hello!"
gen float z20 = runiform()
reshape long z, i(i) j(j)

qui do greshape.ado
set rmsg on
clear
clear _all
* set obs 10000000
set obs 5
gen y = _n
gen long  x1  = _n
gen float x2  = runiform()
gen float x15 = _n
gen float z10 = _n
gen float z20 = runiform()
gen double z15 = runiform()
preserve
    greshape clear
    greshape long x z, i(y) j(j)
restore

* preserve
*     reshape clear
*     reshape long x z, i(y) j(j)
* restore
* preserve
*     reshape clear
*     fastreshape long x, i(y) j(j)
* restore
* gen j = "123456789012345678901234567890 " + string(_j)
* drop _j
* reshape wide x, i(y) j(j) string
* set tracedepth 3
* set trace off

set rmsg on
use /home/mauricio/bulk/lib/benchmark-stata-r/1e7, clear
gduplicates drop id1 id2 id3, force
hashsort id1 id2 id3
* keep if _n < _N/10
foreach v of varlist id4 id5 id6 v1 v2 v3{
    rename `v' v_`v'
}
preserve
reshape long v_, i(id1 id2 id3) j(variable) string
restore

preserve
fastreshape long v_, i(id1 id2 id3) j(variable) string
restore

qui do greshape.ado
preserve
greshape long v_, i(id1 id2 id3) j(variable) string
restore

*/

capture program drop greshape
program greshape, rclass
    version 13.1

    ***********************************************************************
    *                                Clear                                *
    ***********************************************************************

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

    ***********************************************************************
    *                        Reshape wide or long                         *
    ***********************************************************************

    global GTOOLS_PARSE          ///
        unsorted                 /// Do not sort the data
        nodupcheck               /// Do not check for duplicates
        compress                 /// Try to compress strL variables
        forcestrl                /// Force reading strL variables (stata 14 and above only)
        Verbose                  /// Print info during function execution
        _CTOLerance(passthru)    /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                /// Benchmark function
        BENCHmarklevel(passthru) /// Benchmark various steps of the plugin
        HASHmethod(passthru)     /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)    /// error|fallback: On collision, use native command or throw error
        debug(passthru)           // Print debugging info to console

    global ReS_nodupcheck = ( `"`dupcheck'"' == "nodupcheck" )
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

    syntax [anything], [* ${GTOOLS_OPTS}]
    * global GTOOLS_CALL `if' `in'
    global GTOOLS_OPTS `unsorted'       ///
                       `compress'       ///
                       `forcestrl'      ///
                       `verbose'        ///
                       `_ctolerance'    ///
                       `benchmark'      ///
                       `benchmarklevel' ///
                       `oncollision'    ///
                       `hashmethod'     ///
                       `debug'

    if ( inlist(`"`1'"', "wide", "long") ) {
        cap noi DoNew `*'
        local rc = _rc
        CleanExit
        if ( `rc' == 17999 ) {
            reshape `*'
            exit 0
        }
        else if ( `rc' == 17001 ) {
            di as txt "(no observations)"
            exit 0
        }
        else if ( `rc' ) exit `rc'
        else exit 0
    }

    ***********************************************************************
    *                            Anything else                            *
    ***********************************************************************

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
            cap noi DoNew `*'
            local rc = _rc
            char _dta[ReS_ver] "v.2"
            CleanExit
        }
    }
    else if ( `"`syntax'"' == "v.1" ) {
        disp as err "Old syntax is not supported by -greshape-"
        exit 198
    }
    else {
        cap noi DoNew `*'
        local rc = _rc
        CleanExit
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
    else exit 0
end

* ---------------------------------------------------------------------
* DoNew

capture program drop DoNew
program define DoNew
    disp "debug greshape/DoNew: `*'"
    local c "`1'"
    mac shift

    if ( `"`c'"' == "i" ) {
        if ( "`*'" == "" ) error 198
        unabbrev `*', max(10) min(1)
        char _dta[ReS_i] "`s(varlist)'"
        exit
    }

    if ( `"`c'"' == "j" ) {
        J `*'
        exit
    }

    if ( `"`c'"' == "xij" ) {
        Xij `*'
        exit
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
            Simple wide `*'
        }
        capture noisily Wide `*'
        Macdrop
        exit _rc
    }

    cap disp bsubstr(" ", 1, 1)
    if ( _rc ) local substr substr
    else local substr bsubstr

    if `"`c'"' == `substr'("error", 1, max(3, length("`c'"))) {
        capture noisily Qerror `*'
        Macdrop
        exit
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

    greshape clear
    greshape i `i'
    greshape j `jvar' `jvals' `string'
    greshape xij `list' `atwl'
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

    tempfile ReS_jfile
    global ReS_jfile `ReS_jfile'
    scalar __gtools_greshape_jfile = length(`"`ReS_jfile'"') + 1
    Macros2
    confirm var $ReS_i $Res_Xi
    if ( $ReS_str ) {
        local string str($ReS_jlen)
        local jtype  str$ReS_jlen
    }
    else {
        local string str(0)
        local jtype  long
    }

    * --------------------------------------------------------
    * TODO: Copy the xi variables; they are ignored atm
    * --------------------------------------------------------

    * ReS_i    i
    * ReS_j    j
    * ReS_jv   j values [TODO: Dispense with this; write to file]
    * ReS_Xij  reshape variables
    * Res_Xi   non-reshape variables (must be constant within group)
    * ReS_str  whether there are string variables involved; shouldn't be a problem
    * rVANS    Not sure [TODO: Figure it out]
    * ReS_atwl Not sure [TODO: Figure it out; something about @ character in syntax]

    * ------------------------
    * Reshape the data to disk
    * ------------------------

    if ( $ReS_nodupcheck ) local cmd long fwrite
    else local cmd long write

    tempfile ReS_Data
    global GTOOLS_CALLER greshape
    local gopts xij($ReS_Xij_names) xi($Res_Xi) f(`ReS_Data') $ReS_atwl `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) ${GTOOLS_OPTS}
    cap noi _gtools_internal ${ReS_i}, `gopts'
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------
    * Allocate space for long data
    * ----------------------------

    FreeTimer
    if ( `FreeTimer' ) timer on `FreeTimer'
    keep $ReS_i $ReS_Xij_keep $Res_Xi
    * disp "debug: ($ReS_Xij_keep) ($ReS_Xij_keepnames)"
    mata __greshape_types = ("`jtype'", J(1, `:word count $ReS_Xij_add', "double"))
    mata __greshape_vars  = "$ReS_j", tokens("$ReS_Xij_add")
    mata (void) st_addvar(__greshape_types, __greshape_vars, 0)
    if ( (`"$ReS_Xij_keep"' != "") &(`"$ReS_Xij_keepnames"' != "") ) {
        rename ($ReS_Xij_keep) ($ReS_Xij_keepnames)
    }
    order $ReS_i $ReS_j $ReS_Xij $Res_Xi
    qui set obs `=_N * scalar(__gtools_greshape_klvls)'
    * qui expand `=scalar(__gtools_greshape_klvls)'
    if ( `FreeTimer' ) {
        qui timer off `FreeTimer'
        qui timer list
        local s `:disp %9.3f `r(t`FreeTimer')''
        disp _char(9) "reshape long step 4: allocated target dataset; `s' seconds."
    }
    else {
        disp _char(9) "reshape long step 4: allocated target dataset; ??? seconds."
    }

    * ------------------
    * Read reshaped data
    * ------------------

    * desc
    local cmd long read
    global GTOOLS_CALLER greshape
    local gopts j($ReS_j) xij($ReS_Xij) xi($Res_Xi) f(`ReS_Data') $ReS_atwl `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) ${GTOOLS_OPTS}
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

* ---------------------------------------------------------------------
* Reshape wide

capture program drop Wide
program define Wide /* reshape wide */
    local oldobs = _N
    quietly describe, short
    local oldvars = r(k)

    Macros
    capture ConfVar $ReS_j
    if _rc {
        di in blu "(already wide)"
        exit
    }
    ConfVar $ReS_j
    confirm var $ReS_j $rVANS $ReS_i $Res_Xi

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

    * -------------------------------------------------------------------
    * TODO: Get levels of J/encode internally; also check uniq internally
    * -------------------------------------------------------------------

    tempvar ReS_jcode
    tempfile ReS_jfile
    global ReS_jcode: copy local ReS_jcode
    global ReS_jfile: copy local ReS_jfile
    scalar __gtools_greshape_jfile = length(`"`ReS_jfile'"') + 1

    Macros2
    ConfVar $ReS_j
    confirm var $ReS_j $Res_Xi
    Veruniq
    CheckVariableTypes

    * --------------------------------------------------------
    * TODO: Copy the xi variables; they are ignored atm
    * --------------------------------------------------------

    * ReS_i    i
    * ReS_j    j
    * ReS_jv   j values [TODO: Dispense with this; write to file]
    * ReS_Xij  reshape variables
    * Res_Xi   non-reshape variables (must be constant within group)
    * ReS_str  whether there are string variables involved; shouldn't be a problem
    * rVANS    ReS_Xij in wide; why is this different? Figure it out
    * ReS_atwl Not sure [TODO: Figure it out; something about @ character in syntax]

    * ------------------------
    * Reshape the data to disk
    * ------------------------

    if ( $ReS_nodupcheck ) {
        disp as txt "(note: option -nodupcheck- ignored with greshape wide)"
    }
    local cmd wide write

    keep $ReS_i $ReS_j $ReS_jcode $Res_Xi $rVANS
    tempfile ReS_Data
    global GTOOLS_CALLER greshape
    local gopts j($ReS_jcode) xij($rVANS) xi($Res_Xi) f(`ReS_Data') $ReS_atwl `string'
    local gopts greshape(`cmd', `gopts') gfunction(reshape) ${GTOOLS_OPTS}
    cap noi _gtools_internal ${ReS_i}, `gopts'
    global GTOOLS_CALLER ""
    if ( _rc ) exit _rc

    * ----------------------------
    * Allocate space for wide data
    * ----------------------------

    keep in 1 / `:di %32.0f `r(J)''
    global S_FN
    global S_FNDATE

    FreeTimer
    if ( `FreeTimer' ) timer on `FreeTimer'
    rename ($ReS_Xij_keep) ($ReS_Xij_keepnames)
    mata __greshape_types = tokens("$ReS_Xij_addtypes")
    mata __greshape_vars  = tokens("$ReS_Xij_addvars")
    mata (void) st_addvar(__greshape_types, __greshape_vars, 0)
    order $ReS_i $ReS_j $ReS_Xij_names $Res_Xi
    if ( `FreeTimer' ) {
        qui timer off `FreeTimer'
        qui timer list
        local s `:disp %9.3f `r(t`FreeTimer')''
        disp _char(9) "reshape wide step 4: allocated target dataset; `s' seconds."
    }
    else {
        disp _char(9) "reshape wide step 4: allocated target dataset; ??? seconds."
    }

    exit 17004

    * ------------------
    * Read reshaped data
    * ------------------

    * desc
    local cmd wide read
    * global GTOOLS_CALLER greshape
    * local gopts j($ReS_j) xij($ReS_Xij_names) xi($Res_Xi) f(`ReS_Data') $ReS_atwl `string'
    * local gopts greshape(`cmd', `gopts') gfunction(reshape) ${GTOOLS_OPTS}
    * cap noi _gtools_internal ${ReS_i}, `gopts'
    * global GTOOLS_CALLER ""
    * if ( _rc ) exit _rc

    * ----------------------------------------
    * Finish in the same style as reshape.Wide
    * ----------------------------------------

    local syntax: char _dta[ReS_ver]
    if "`syntax'" != "v.1" {
        ReportW `oldobs' `oldvars'
    }
end

/*
    Widefix #

    Assumption when called:  currently in memory are single observations
    per $ReS_i corresponding to $ReS_j==#

    go through $ReS_Xij and rename each ${ReS_Xij}#
*/

capture program drop Widefix
program define Widefix /* # */ /* reshape wide utility */
    local val "`1'"
    parse "$ReS_Xij", parse(" ")
    while "`1'" != "" {
        Subname `1' `val'
        local new $S_1
        capture confirm new var `new'
        if _rc {
            capture confirm var `new'
            if _rc {
                di in red as smcl ///
                "{bf:`new'} invalid variable name"
                exit 198
            }
            else {
                di in red as smcl ///
                "variable {bf:`new'} already defined"
                exit 110
            }
        }
        Subname `1' $ReS_atwl
        rename $S_1 `new'
        label var `new' "`val' $S_1"
        mac shift
    }
end

* ---------------------------------------------------------------------
* Macros2: Levels of ReS_j

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
            * TODO: Give user options over this (see top)
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
    mata: st_numscalar("__gtools_greshape_kout",  cols(tokens(`"$ReS_Xij"')))
    mata: st_numscalar("__gtools_greshape_klvls", rows(__greshape_res))
    if ( `=(__gtools_greshape_klvls)' == 0 ) {
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

    mata: __greshape_rc = CheckVariableTypes( /*
        */ tokens(`"$ReS_Xij_names"'), /*
        */ __greshape_res,             /*
        */ tokens(`"$ReS_Xij"'))

    mata: st_numscalar("__greshape_rc", __greshape_rc)
    if ( `=scalar(__greshape_rc)' ) exit 198

    scalar __gtools_greshape_nrows = .
    scalar __gtools_greshape_ncols = .

    mata: st_matrix("__gtools_greshape_maplevel", __greshape_maplevel)

    mata: st_global("ReS_jv",   invtokens(__greshape_res'))
    mata: st_global("ReS_jlen", strofreal(max(strlen(__greshape_res))))

    di in gr "(note: j = $ReS_jv)"
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
    st_numscalar("__gtools_greshape_kxij", cols(ordered))
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

    st_matrix("__gtools_greshape_types", types)

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
    * TODO: Make cols an option
    glevelsof $ReS_j, silent local(ReS_jv) cols(" ") group($ReS_jcode)
    scalar __gtools_greshape_klvls = `r(J)'
    if ( 1 ) {
        * TODO: Strict let fail with spaces; otherwise replace
        mata: __greshape_jv  = tokens(st_local("ReS_jv"))'
        mata: __greshape_jv_ = `substr'(__greshape_jv, 1, 1) :!= "_"
        mata: __greshape_jv  = strtoname(__greshape_jv)
        mata: __greshape_jv  = `substr'(__greshape_jv, 1 :+ __greshape_jv_, strlen(__greshape_jv))
        mata: st_global("ReS_jv", invtokens(__greshape_jv'))
        cap mata: assert(sort(__greshape_jv', 1) == uniqrows(__greshape_jv'))
        if _rc {
            disp as err "j defines non-unique or invalid names"
        }
        mata: SaveJValuesString(__greshape_jv)
    }
    else {
        global ReS_jv: copy local ReS_jv
    }
    di in gr "(note: j = $ReS_jv)"
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
            global ReS_Xij_names    $ReS_Xij_names    `var'`j1'
        }
    }

    scalar __gtools_greshape_kout     = `:list sizeof k'
    scalar __gtools_greshape_kxij     = `:list sizeof k' * `:list sizeof j'
    scalar __gtools_greshape_nrows    = .
    scalar __gtools_greshape_ncols    = .
    matrix __gtools_greshape_maplevel = 0

    capture matrix drop __gtools_greshape_types
    foreach var of varlist $rVANS {
        if ( `regex'm("`:type `var''", "str([1-9][0-9]*|L)") ) {
            if ( `regex's(1) == "L" ) {
                disp as err "Unknown type `:type `var''"
                exit 198
            }
            matrix __gtools_greshape_types = nullmat(__gtools_greshape_types), `=`regex's(1)'
        }
        else if ( inlist("`:type `var''", "byte", "int", "long", "float", "double") ) {
            matrix __gtools_greshape_types = nullmat(__gtools_greshape_types), 0
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

capture program drop Veruniq
program define Veruniq

    * ---------------------------------
    * TODO: Make this an internal check
    * ---------------------------------

    cap gisid $ReS_i $ReS_jcode
    if _rc {
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
        di in red as smcl "Type {bf:reshape error} for a list"
        di in red as smcl "of the problem variables."
        di in red as smcl "{p_end}"
        exit 9
    }

    * -------------------------------------------------
    * TODO: Check Xi is fine internally once you add Xi
    * -------------------------------------------------

    if "$Res_Xi"=="" {
        exit
    }
    * $ReS_Call sort $ReS_i $Res_Xi $ReS_j
    * tempvar cnt1 cnt2
    * quietly by $ReS_i: gen `c(obs_t)' `cnt1' = _N
    * quietly by $ReS_i $Res_Xi: gen `c(obs_t)' `cnt2' = _N
    * capture assert `cnt1' == `cnt2'
    * if _rc==0 {
    *     exit
    * }
    * parse "$Res_Xi", parse(" ")
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
    mac drop ReS_Xij           ///
             ReS_Xij_add       ///
             ReS_Xij_keep      ///
             ReS_Xij_keepnames ///
             ReS_Xij_names     ///
             ReS_Xij_addtypes  ///
             ReS_Xij_addvars   ///
             ReS_nodupcheck    ///
             ReS_atwl          ///
             ReS_i             ///
             ReS_j             ///
             ReS_jfile         ///
             ReS_jcode         ///
             ReS_jlen          ///
             ReS_jv            ///
             ReS_jv2           ///
             ReS_str           ///
             Res_Xi            ///
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

capture program drop J
program define J /* reshape j [ #[-#] [...] | <str> <str> ...] [, string] */
    if "`*'"=="" {
        error 198
    }
    parse "`*'", parse(" -,")
    local grpvar "`1'"
    mac shift

    local isstr 0
    while "`1'"!="" & "`1'"!="," {
        if "`2'" == "-" {
            local i1 `1'
            local i2 `3'
            confirm integer number `i1'
            confirm integer number `i2'
            if `i1' >= `i2' {
                di in red "`i1'-`i2':  invalid range"
                exit 198
            }
            while `i1' <= `i2' {
                local values `values' `i1'
                local i1 = `i1' + 1
            }
            mac shift 3
        }
        else {
            capture confirm integer number `1'
            local isstr = `isstr' | _rc
            local values `values' `1'
            mac shift
        }
    }

    if "`1'"=="," {
        local options "String"
        parse "`*'"
        if `isstr' & "`string'"=="" {
            di in red as smcl /*
*/ "must specify option {bf:string} if string values are to be specified"
            exit 198
        }
        if "`string'"!="" {
            local isstr 1
        }
    }
    Chkj `grpvar' `isstr'
    char _dta[ReS_j] "`grpvar'"
    char _dta[ReS_jv] "`values'"
    char _dta[ReS_str] `isstr'
end

capture program drop Xij
program define Xij /* <names-maybe-with-@>[, atwl(string) */
    if ( `"`*'"'=="" ) error 198
    parse "`*'", parse(" ,")
    while "`1'" != "" & "`1'"!="," {
        local list "`list' `1'"
        mac shift
    }
    if "`list'"=="" {
        error 198
    }
    local list `list'
    if "`1'"=="," {
        local options "ATwl(string)"
        parse "`*'"
    }
    char _dta[ReS_Xij] "`list'"
    char _dta[ReS_atwl] "`atwl'"
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

capture program drop CleanExit
program CleanExit
    Macdrop

    capture mata mata drop __greshape_dsname
    capture mata mata drop __greshape_jv
    capture mata mata drop __greshape_jv_
    capture mata mata drop __greshape_maplevel
    capture mata mata drop __greshape_res
    capture mata mata drop __greshape_sel
    capture mata mata drop __greshape_types
    capture mata mata drop __greshape_u
    capture mata mata drop __greshape_vars
    capture mata mata drop __greshape_xijname
    capture mata mata drop __greshape_rc

    capture scalar drop __gtools_greshape_klvls
    capture scalar drop __gtools_greshape_kout
    capture scalar drop __gtools_greshape_kxij
    capture scalar drop __gtools_greshape_ncols
    capture scalar drop __gtools_greshape_nrows
    capture scalar drop __gtools_greshape_jfile
    capture scalar drop __greshape_rc

    capture matrix drop __gtools_greshape_types
    capture matrix drop __gtools_greshape_maplevel
end

* ---------------------------------------------------------------------
* Qerror

capture program drop Qerror
program define Qerror
    Macros
    Macros2
    capture ConfVar $ReS_j
    if ( _rc == 0 ) {
        QerrorW
    }
    else QerrorL
end

capture program drop QerrorW
program define QerrorW
    ConfVar $ReS_j
    confirm var $ReS_j $ReS_Xij $ReS_i $Res_Xi
    capture gisid $ReS_i $ReS_j
    if _rc {
        Msg1
        di in gr /*
    */ "The data are in the long form;  j should be unique within i." _n
        di in gr /*
        */ "There are multiple observations on the same " /*
        */ in ye "$ReS_j" in gr " within " /*
        */ in ye "$ReS_i" in gr "." _n

        * tempvar bad
        * quietly by $ReS_i $ReS_j: gen byte `bad' = _N!=1
        * quietly count if `bad'
        * di in gr /*
        * */ "The following " r(N) /*
        * */ " of " _N /*
        * */ " observations have repeated $ReS_j values:"
        * list $ReS_i $ReS_j if `bad'
        * di in gr _n "(data now sorted by $ReS_i $ReS_j)"
        * exit

        gduplicates examples $ReS_i $ReS_j, nowarn
        hashsort $ReS_i $ReS_j
        di in gr _n "(data now sorted by $ReS_i $ReS_j)"
        exit
    }
    if "$Res_Xi"=="" {
        di in gr "$ReS_j is unique within $ReS_i;"
        di in gr "there is no error with which " /*
        */ _quote "reshape error" _quote " can help."
        exit
    }

    * NOTE(mauricio): Maybe one day make this fast; not today

    tempvar cnt1 cnt2
    gegen `c(obs_t)' `cnt1' = count(1), by($ReS_i)
    gegen `c(obs_t)' `cnt2' = count(1), by($ReS_i $Res_Xi)
    capture assert `cnt1' == `cnt2'
    if _rc==0 {
        di in gr "$ReS_j is unique within $ReS_i and"
        di in gr "all the " _quote "reshape xi" _quote /*
        */ " variables are constant within $ReS_j;"
        di in gr "there is no error with which " /*
        */ _quote "reshape error" _quote " can help."
        exit
    }

    Msg1
    local n : word count $ReS_Xij
    if `n'==1 {
        di in gr "xij variable is " in ye "$ReS_Xij" in gr "."
    }
    else di in gr "xij variables are " in ye "$ReS_Xij" in gr "."
    di in gr "Thus, the following variable(s) should be constant within i:"
    di in ye _col(7) "$Res_Xi"

    * NOTE(mauricio): Maybe one day make this fast; not today

    hashsort $ReS_i $ReS_j
    tempvar bad
    parse "$Res_Xi", parse(" ")
    while "`1'"!=""  {
        capture by $ReS_i: assert `1'==`1'[1]
        if _rc {
            qui by $ReS_i: gen long `bad' = /*
                */ cond(_n==_N,sum(`1'!=`1'[1]),0)
            qui count if `bad'
            di _n in ye "`1'" in gr " not constant within i (" /*
                */ in ye "$ReS_i" in gr ") for " /*
                */ r(N) " value" _c
            if r(N)==1 {
                di in gr " of i:"
            }
            else di in gr "s of i:"
            qui by $ReS_i: replace `bad' = `bad'[_N]
            list $ReS_i $ReS_j `1' if `bad'
            drop `bad'
        }
        mac shift
    }
    di in gr _n "(data now sorted by $ReS_i $ReS_j)"
end
program define Msg1
    di _n in gr "i (" in ye "$ReS_i" in gr /*
    */ ") indicates the top-level grouping such as subject id."
    di in gr "j (" in ye "$ReS_j" in gr /*
    */ ") indicates the subgrouping such as time."
end
program define QerrorL
    confirm var $ReS_i
    local id "$ReS_i"
    hashsort `id'
    capture gisid `id'
    if _rc==0 {
        di in gr "`id' is unique; there is no problem on this score"
        exit
    }
    di _n in gr "i (" in ye "`id'" in gr /*
    */ ") indicates the top-level grouping such as subject id."
    di _n in gr /*
*/ "The data are currently in the wide form; there should be a single" /*
    */ _n "observation per i."
    gduplicates examples `id'
    * quietly count if `bad'
    * di _n in gr r(N) " of " _N /*
    * */ " observations have duplicate i values:"
    * list `id' if `bad'
    di in gr _n "(data now sorted by `id')"
end
