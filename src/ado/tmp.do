*! version 0.1.0 29Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! (beta) Fast implementation of reshape using C plugins

capture program drop greshape
program greshape, rclass
    version 13.1
    global GTOOLS_CALLER greshape

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

    if ( inlist(`"`1'"', "wide", "long") ) {
        DoNew `*'
        exit
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
            DoNew `*'
            char _dta[ReS_ver] "v.2"
        }
        exit
    }

    if ( `"`syntax'"' == "v.1" ) {
        disp as err "Old syntax is not supported by -greshape-"
        exit 198
    }
    else DoNew `*'
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

    * ------------------------------------------
    * TODO: I believe this is the actual reshape
    * ------------------------------------------

    * Ok, so the problem is that reshape is a whole...thing...in Stata;
    * like, it's nnot just literal reshaping, but an antire thing...
    * Ugh... If only my brain could let that go..

    disp "    preserve"
    disp "    Macros2"
    disp "        FillvalL"
    disp "        FillvalW"
    disp "        FillXi"
    disp "    if $S_1 restore, preserve"
    * preserve
    * Macros2
    * if $S_1 {
    *     restore, preserve
    * }
    confirm var $ReS_i $Res_Xi

    disp "    Verluniq"
    disp "        drop _all"
    disp "        set obs 1"
    disp "        gen type $ReS_j = missing"
    disp "        save new"
    disp "        restore, preserve"
    disp "        append using new"
    disp "        drop if $ReS_j == missing"
    * tempfile new
    * Verluniq
    * quietly {
    *     mkrtmpST
    *     drop _all
    *     set obs 1
    *     if $ReS_str {
    *         gen str32 $ReS_j = ""
    *     }
    *     else gen float $ReS_j = .
    *     save "`new'", replace
    *     parse "$ReS_jv", parse(" ")
    *     while "`1'"!="" {
    *         restore, preserve
    *         noisily Longdo `1'
    *         append using "`new'"
    *         save "`new'", replace
    *         mac shift
    *     }
    *     if $ReS_str {
    *         drop if $ReS_j == ""
    *     }
    *     else drop if $ReS_j >= .
    *     global rtmpST
    *     compress $ReS_j
    * }
    * global S_FN
    * global S_FNDATE
    * local syntax: char _dta[ReS_ver]
    * if "`syntax'" != "v.1" {
    *     order $ReS_i $ReS_j
    *     $ReS_Call sort $ReS_i $ReS_j
    * }
    * restore, not

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
    local preserv "`1'"

    /* determine whether anything to do */
    capture ConfVar $ReS_j
    local islong = (_rc==0)
    local dovalW 0
    local dovalL 0
    local docar 0
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

    * --------------
    * TODO: FillvalL
    * --------------

    disp "        -> FillvalL"
    * if `dovalL' {
    *     FillvalL
    * }

    /* nothing to do */
    if `dovalW'==0 & `docar'==0 {
        global S_1 0 /* S_1==0 -> data in memory unchanged */
        exit
    }

    * ---------------------------
    * TODO: Convert data to names
    * ---------------------------

    disp "        -> preserve and convert to names"
    * /* convert data to names */
    * `preserv'
    * local varlist "req ex"
    * parse "_all"
    * quietly {
    *     drop _all
    *     local n : word count `varlist'
    *     set obs `n'
    *     gen str32 name = ""
    *     parse "`varlist'", parse(" ")
    *     local i 1
    *     while `i' <= `n' {
    *         replace name = "``i''" in `i'
    *         local i = `i' + 1
    *     }
    * }

    * ---------------------
    * TODO: FillvalW FillXi
    * ---------------------

    disp "        -> FillvalW and FillXi"
    disp "        -> file saves!"
    * /* call Fillval and FillXi as required */
    * if `dovalW' & `docar' {
    *     tempfile dsname
    *     quietly save "`dsname'"
    *     FillvalW
    *     quietly use "`dsname'", clear
    *     FillXi `islong'
    * }
    * else if `dovalW' {
    *     FillvalW
    * }
    * else FillXi `islong'

    global S_1 1
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
    disp `"DoNew"'
    disp `"`0'"'

    local c "`1'"
    mac shift

    if ( `"`c'"' == "i" ) {
        if ( "`*'" == "" ) error 198
        unabbrev `*', max(10) min(1)
        char _dta[ReS_i] "`s(varlist)'"
        exit
    }

    if ( `"`c'"' == "j" ) {
        * J `*'
        * exit
        disp as err "j not yet supported by greshape"
        exit 198
    }

    if ( `"`c'"' == "xij" ) {
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
            * Simple long `*'
            disp as err "simple long not yet supported by greshape"
            exit 198
        }
        capture noisily Long `*'
        Macdrop
        exit _rc
    }

    if ( `"`c'"' == "wide" ) { /* reshape wide */
        if ( `"`1'"' != "" ) {
            * Simple wide `*'
            disp as err "simple wide not yet supported by greshape"
            exit 198
        }
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
        * capture noisily Qerror `*'
        Macdrop
        disp as err "qerror not yet supported by greshape"
        exit 198
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
    Qlist 44 "`ccons'" `cons'

    di in smcl in gr /*
    */ "{c |}  within-group variable" _col(32) "{c |} greshape j " _c

    Qlist 44 "`cgrpvar'" `grpvar' `values'
    di in smcl in gr /*
    */ "{c |}   and its range" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr "{c |}" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr /*
    */ "{c |} Variable X definitions:" _col(32) "{c |}" _col(79) "{c |}"

    di in smcl in gr /*
    */ "{c |}  varying within group" _col(32) "{c |} greshape xij " _c
    Qlist 46 "`cvars'" `vars'

    di in smcl in gr /*
    */ "{c |}  constant within group (opt) {c |} greshape xi  " _c
    Qlist 46 "`ccar'" `car'

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
    if _rc { exit }

    capture confirm string var `grpvar'
    if _rc==0 {
        if !`isstr' {
            di in red as smcl ///
        "variable {bf:`grpvar'} is string; specify {bf:string} option"
            exit 109
        }
    }
    else {
        if `isstr' {
            di in red as smcl "variable {bf:`grpvar'} is numeric"
            exit 109
        }
    }
end

capture program drop Subname
program define Subname /* <name-maybe-with-@> <tosub> */
    local name "`1'"
    local sub "`2'"
    local l = index("`name'","@")
    local l = cond(`l'==0, length("`name'")+1,`l')
    local a = bsubstr("`name'",1,`l'-1)
    local c = bsubstr("`name'",`l'+1,.)
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
