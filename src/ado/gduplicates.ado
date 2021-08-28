*! version 1.0.0 20Sep2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -duplicates- implementation using -gegen tag- for faster processing

capture program drop gduplicates
program gduplicates, rclass
    version 13.1

    local 00 `0'
    gettoken cmd 0 : 0, parse(" ,")
    local l = length("`cmd'")

    * Get subcommand
    * --------------

    if ( `l' == 0 ) {
        di "{err}subcommand needed; see help on {help gduplicates##|_new:gduplicates}"
        exit 198
    }

    if ( substr("report", 1,  max(1, `l')) == "`cmd'" ) {
        local cmd "report"
    }
    else if ( substr("examples", 1, max(1, `l')) == "`cmd'" ) {
        local cmd "examples"
    }
    else if ( substr("list", 1, max(1, `l')) == "`cmd'" ) {
        local cmd "list"
    }
    else if ( substr("browse", 1, max(1, `l')) == "`cmd'" ) {
        local cmd "browse"
        disp "{p 0 0 2}As of Stata 11.0, browse is no longer a valid"        ///
             "{cmd}duplicates subcommand; hence gtools will not support it." ///
             "{result}See {help duplicates##remarks:Remarks} under help"     ///
             "{helpb duplicates} for an explanation.{p_end}"
        exit 198
    }
    else if ( substr("tag", 1, max(1, `l')) == "`cmd'" ) {
        local cmd "tag"
    }
    else if ( "drop" == "`cmd'" ) {
        * OK
    }
    else {
        di "{err}illegal {cmd}gduplicates {err}gsubcommand"
        exit 198
    }

    * Check syntax
    * ------------

    if ( "`cmd'" == "drop" ) {
        capture syntax varlist [if] [in], [gtools(str)]
        if ( _rc == 0 ) {
            di "{err}force option required with {cmd}gduplicates drop {it}varlist{rm}"
            exit 198
        }

        capture syntax varlist [if] [in], force [gtools(str)]
        if ( _rc ) {
            syntax [varlist] [if] [in], [gtools(str)]
            unab varlist : _all
            * local varlist : subinstr local varlist "`_sortindex'" ""
            local vartext "{txt} all variables"
        }
        else local vartext "{res} `varlist'"
    }
    else if "`cmd'" == "tag" {
        syntax [varlist(default=none)] [if] [in], Generate(str) [gtools(str)]
        capture confirm new variable `generate'
        if ( _rc ) {
            di as err "generate() must specify new variable"
            exit _rc
        }

        if ( "`varlist'" == "" ) {
            unab varlist : _all
            * local varlist : subinstr local varlist "`_sortindex'" ""
            local vartext "{txt} all variables"
        }
        else local vartext "{res} `varlist'"
    }
    else {
        syntax [varlist(default=none)] [if] [in] [ , SORTed UNSORTed gtools(str) * ]
        if ( "`varlist'" == "" ) {
            unab varlist : _all
            * local varlist : subinstr local varlist "`_sortindex'" ""
            local vartext "{txt} all variables"
        }
        else local vartext "{res} `varlist'"
    }

    * Dedup algorithm
    * ---------------

    tempvar example Ngroup freq surplus dgroup order
    /*
        order   1 up    _n when called
        dgroup  0       if unique on varlist (not a "duplicated" group)
                1 up    labels groups which share identical values on varlist
        Ngroup  1       if unique on varlist
                2 up    is # in each dgroup
        example 1       to show if showing examples -- and to keep if -drop-
                0       to drop if -drop-
        freq    #       # in each group
        surplus #       # of surplus observations
    */

    di _n "{p 0 4}{txt}Duplicates in terms of `vartext'{p_end}"

    * tag - count duplicates by group
    * -------------------------------

    if ( "`cmd'" == "tag" ) {
        global GTOOLS_DUPS gduplicates
        cap noi gegen `generate' = count(1) `if' `in', by(`varlist') missing `gtools'
        global GTOOLS_DUPS ""

        if ( _rc == 2000 ) {
            error 2000
        }
        else if ( _rc ) {
            error _rc
        }

        qui replace `generate' = `generate' - 1
        qui compress `generate'
        exit 0
    }

    * report - stats on duplicates
    * ----------------------------

    if ( "`cmd'" == "report" ) {
        if ( `"`if'"' != "" ) {
            marksample touse, novarlist
            local ifin if `touse' `in'
        }
        else {
            mata st_local("ifin", st_local("if") + " " + st_local("in"))
        }

        global GTOOLS_DUPS gduplicates
        * cap noi gegen `Ngroup' = count(1) `ifin', by(`varlist') missing `gtools'
        cap noi gegen `example' = tag(`varlist') `ifin', counts(`Ngroup') missing `gtools'
        global GTOOLS_DUPS ""

        if ( _rc == 2000 ) {
            error 2000
        }
        else if ( _rc ) {
            error _rc
        }

        return scalar unique_value = `r(J)'

        global GTOOLS_DUPS gduplicates
        cap noi gegen `freq' = count(1) `ifin', by(`Ngroup') missing `gtools'
        global GTOOLS_DUPS ""

        if ( _rc == 2000 ) {
            error 2000
        }
        else if ( _rc ) {
            error _rc
        }

        gen `surplus' = `freq' - ( `freq' / `Ngroup' )

        label var `Ngroup'  "copies"
        label var `freq'    "observations"
        label var `surplus' "surplus"

        tabdisp `Ngroup' if `example', cell(`freq' `surplus')
        local varcount: word count `varlist'

        exit 0
    }

    * drop
    * ----

    if ( "`cmd'" == "drop" ) {
        if ( `"`if'`in'"' != "" ) {
            marksample touse, novarlist
            local ifin if `touse' `in'
        }

        global GTOOLS_DUPS gduplicates
        cap noi gegen `example' = tag(`varlist') `ifin', missing `gtools'
        global GTOOLS_DUPS ""

        if ( _rc == 2000 ) {
            error 2000
        }
        else if ( _rc ) {
            error _rc
        }

        * bail out now if no duplicates
        if ( `r(N)' == `r(J)' ) {
            di _n as txt "(0 observations are duplicates)"
            exit 0
        }

        di
        if ( `"`if'`in'"' == "" ) {
            noisily keep if `example'
        }
        else {
            noisily keep if `example' | !`touse'
        }
        exit 0
    }

    * examples or list
    * ----------------

    local opts varlist(`varlist') ifin(`if' `in') cmd(`cmd')
    * if ( "`unsorted'" == "" ) {
    if ( "`sorted'" != "" ) {
        cap noi examplesList, `opts' gtools(`gtools') `options'
        exit _rc
    }
    else {
        cap noi examplesListUnsorted, `opts' gtools(`gtools') `options'
        exit _rc
    }
end

* Examples and list
* -----------------

capture program drop examplesListUnsorted
program examplesListUnsorted
    syntax, varlist(str) cmd(str) [ifin(str asis) gtools(str) noWARNing *]

    tempvar example Ngroup freq surplus dgroup order

    global GTOOLS_CALLER ghash
    local  opts missing gfunction(hash) `gtools'
    local gopts gen(`dgroup') counts(`Ngroup') tag(`example')

    cap noi _gtools_internal `varlist' `ifin', `gopts' `opts'
    global GTOOLS_CALLER ""

    if ( _rc == 17999 ) {
        duplicates `0'
        exit 0
    }
    else if ( _rc == 17001 ) {
        error 2000
    }
    else if ( _rc ) {
        exit _rc
    }

    * bail out now if no duplicates
    if ( `r(J)' == `r(N)' ) {
        di _n as txt "(0 observations are duplicates)"
        exit 0
    }
    else {
        di _n as txt "`=`r(N)' - `r(J)'' observations are duplicates. Examples:"
    }

    if ( `"`warning'"' != "nowarning" ) {
        disp "({cmd}note: {cmd}`cmd' {txt}left unsorted to improve performance; use option {cmd}sort {txt}to mimic {cmd}duplicates)"
    }

    qui replace `dgroup' = 0 if ( `Ngroup' == 1 ) | mi(`dgroup')
    gen long `order' = _n

    if ( "`cmd'" == "examples" ) {
        char `order'[varname]  "e.g. obs:"
        char `dgroup'[varname] "group:"
        char `Ngroup'[varname] "#"
        if ( `r(J)' ) > 1 {
            local lopts subvarname noobs `options'
            local lvars `dgroup' `Ngroup' `order' `varlist'
            list `lvars' if `example' & `dgroup', `lopts'
        }
        else {
            local lopts subvarname noobs `options'
            local lvars `Ngroup' `order' `varlist'
            list `lvars' if `example' & `dgroup', `lopts'
        }
    }
    else if ( "`cmd'" == "list" ) {
        char `order'[varname]  "obs:"
        char `dgroup'[varname] "group:"
        * char `order'[varname] "obs:"
        if ( `r(J)' > 1 ) {
            local lopts subvarname noobs `options'
            local lvars `dgroup' `order' `varlist'
            list `lvars' if `dgroup', `lopts'
        }
        else {
            list `order' `varlist' if `dgroup', subvarname noobs `options'
        }
    }
end

capture program drop examplesList
program examplesList, sortpreserve
    syntax, varlist(str) cmd(str) [ifin(str asis) gtools(str) noWARNing *]

    tempvar example Ngroup freq surplus dgroup order

    global GTOOLS_CALLER ghash
    local  opts missing gfunction(hash) `gtools'
    local gopts gen(`dgroup') counts(`Ngroup') tag(`example')

    cap noi _gtools_internal `varlist' `ifin', `gopts' `opts'
    global GTOOLS_CALLER ""

    if ( _rc == 17999 ) {
        duplicates `0'
        exit 0
    }
    else if ( _rc == 17001 ) {
        error 2000
    }
    else if ( _rc ) {
        exit _rc
    }

    * bail out now if no duplicates
    if ( `r(J)' == `r(N)' ) {
        di _n as txt "(0 observations are duplicates)"
        exit 0
    }
    else {
        di _n as txt "`=`r(N)' - `r(J)'' observations are duplicates. Examples:"
    }

    qui replace `dgroup' = 0 if ( `Ngroup' == 1 ) | mi(`dgroup')
    gen long `order' = _n
    sort `dgroup' `order'

    if ( "`cmd'" == "examples" ) {
        char `order'[varname]  "e.g. obs:"
        char `dgroup'[varname] "group:"
        char `Ngroup'[varname] "#"
        if ( `r(J)' ) > 1 {
            local lopts subvarname noobs `options'
            local lvars `dgroup' `Ngroup' `order' `varlist'
            list `lvars' if `example' & `dgroup', `lopts'
        }
        else {
            local lopts subvarname noobs `options'
            local lvars `Ngroup' `order' `varlist'
            list `lvars' if `example' & `dgroup', `lopts'
        }
    }
    else if ( "`cmd'" == "list" ) {
        char `order'[varname]  "obs:"
        char `dgroup'[varname] "group:"
        * char `order'[varname] "obs:"
        if ( `r(J)' > 1 ) {
            local lopts subvarname noobs `options'
            local lvars `dgroup' `order' `varlist'
            list `lvars' if `dgroup', `lopts'
        }
        else {
            local lopts subvarname noobs `options'
            local lvars `order' `varlist'
            list `lvars' if `dgroup', `lopts'
        }
    }

    * disp "{cmd}Warning: {txt}Performance gains are negligible without option {cmd}unsorted"
end
