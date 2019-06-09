*! version 1.1.9  01mar2019  Ben Jann
* 1. estpost
* 2. estpost_summarize
* 3. estpost_tabulate
* 4. estpost_tabstat
* 5. estpost_ttest
* 6. estpost_correlate
* 7. estpost_stci (Stata 9 required)
* 8. estpost_ci
* 9. estpost_prtest
* 10. estpost__svy_tabulate
* 12. estpost_gtabstat
* 99. _erepost

* 1. estpost
program estpost, rclass // rclass => remove r()'s left behind by subcommand
    version 8.2
    local caller : di _caller()
    capt syntax [, * ]
    if _rc==0 { // => for bootstrap
        _coef_table_header
        ereturn display, `options'
        exit
    }
    gettoken subcommand rest : 0, parse(" ,:")
    capt confirm name `subcommand'
    if _rc {
        di as err "invalid subcommand"
        exit 198
    }

    local l = length(`"`subcommand'"')
         if `"`subcommand'"'==substr("summarize",1,max(2,`l')) local subcommand "summarize"
    else if `"`subcommand'"'==substr("tabulate",1,max(2,`l'))  local subcommand "tabulate"
    else if `"`subcommand'"'==substr("correlate",1,max(3,`l')) local subcommand "correlate"
    else if `"`subcommand'"'=="svy" {
        _estpost_parse_svy `macval(rest)'
    }
    else if substr(`"`subcommand'"',1,5)=="_svy_" {
        di as err "invalid subcommand"
        exit 198
    }

    capt local junk: properties estpost_`subcommand' // does not work in Stata 8
    if _rc==199 {
        di as err "invalid subcommand"
        exit 198
    }

    version `caller': estpost_`subcommand' `macval(rest)'
    //eret list
end
program _estpost_markout2 // marks out obs that are missing on *all* variables
    gettoken touse varlist: 0
    if `:list sizeof varlist'>0 {
        tempname touse2
        gen byte `touse2' = 0
        foreach var of local varlist {
            qui replace `touse2' = 1 if !missing(`var')
        }
        qui replace `touse' = 0 if `touse2'==0
    }
end
program _estpost_parse_svy
    version 9.2
    _on_colon_parse `0'
    local 0 `"`s(after)'"'
    gettoken subcommand rest : 0, parse(" ,")
    local l = length(`"`subcommand'"')
    if `"`subcommand'"'==substr("tabulate",1,max(2,`l'))  local subcommand "tabulate"
    c_local subcommand `"_svy_`subcommand'"'
    c_local rest `"`s(before)' : `rest'"'
end
program _estpost_namesandlabels // used by some routines such as estpost_tabulate
    version 8.2                 // returns locals names, savenames, and labels
    args varname values0 labels0 elabel
    if `"`values0'"'=="" { // generate values: 1 2 3 ...
        local i 0
        foreach label of local labels0 {
            local values0 `values0' `++i'
        }
    }
    local haslabels = "`elabel'"!=""
    if `"`labels0'"'=="" & "`varname'"!="" {
        local vallab: value label `varname'
    }
    while (1) {
        gettoken value values0 : values0
        if "`value'"=="" continue, break  //=> exit loop
        if `"`vallab'"'!="" {
            local lbl: label `vallab' `value', strict
        }
        else {
            gettoken lbl labels0 : labels0
        }
        if index("`value'",".") {
            local haslabels 1
            if `"`macval(lbl)'"'=="" {
                local lbl "`value'"
            }
            local value: subinstr local value "." "_missing_"
        }
        local names0 `names0' `value'
        if `"`macval(lbl)'"'!="" {
            local labels `"`macval(labels)'`lblspace'`value' `"`macval(lbl)'"'"'
            local lblspace " "
        }
        if `haslabels' continue
        if `"`macval(lbl)'"'=="" {
            local names `"`names'`space'`value'"'
            local savenames `"`savenames'`space'`value'"'
        }
        else {
            if regexm(`"`macval(lbl)'"', `"[:."]"') local haslabels 1
            else if length(`"`macval(lbl)'"')>30    local haslabels 1
            else {
                local names `"`names'`space'`"`lbl'"'"'
                local lbl: subinstr local lbl " " "_", all
                local savenames `"`savenames'`space'`lbl'"'
            }
        }
        local space " "
    }
    if `haslabels' {
        local names `names0'
        local savenames `names0'
    }
    c_local names       `"`names'"'         // to be used as matrix row- or colnames
    c_local savenames   `"`savenames'"'     // names without spaces (for matlist)
    if `haslabels' {
        c_local labels      `"`macval(labels)'"'    // label dictionary
    }
    else c_local labels ""
end
program _estpost_eqnamesandlabels // used by some routines such as estpost_tabulate
    version 8.2                   // returns locals eqnames and eqlabels
    args varname values0 labels0 elabel
    if `"`values0'"'=="" { // generate values: 1 2 3 ...
        local i 0
        foreach label of local labels0 {
            local values0 `values0' `++i'
        }
    }
    local haslabels = "`elabel'"!=""
    if `"`labels0'"'=="" & "`varname'"!="" {
        local vallab: value label `varname'
    }
    while (1) {
        gettoken value values0 : values0
        if "`value'"=="" continue, break  //=> exit loop
        if `"`vallab'"'!="" {
            local lbl: label `vallab' `value', strict
        }
        else {
            gettoken lbl labels0 : labels0
        }
        if index("`value'",".") {
            local haslabels 1
            if `"`macval(lbl)'"'=="" {
                local lbl "`value'"
            }
            local value: subinstr local value "." "_missing_"
        }
        local names0 `names0' `value'
        if `"`macval(lbl)'"'=="" local lbl "`value'"
        local labels `"`macval(labels)'`lblspace'`"`macval(lbl)'"'"'
        local lblspace " "
        if `haslabels' continue
        if `"`macval(lbl)'"'=="" {
            local names `"`names'`space'`value'"'
        }
        else {
            if regexm(`"`macval(lbl)'"', `"[:."]"') local haslabels 1
            else if length(`"`macval(lbl)'"')>30    local haslabels 1
            else {
                local names `"`names'`space'`"`lbl'"'"'
            }
        }
        local space " "
    }
    if `haslabels' {
        local names `names0'
    }
    c_local eqnames       `"`names'"'         // to be used as matrix roweqs or coleqs
    if `haslabels' {
        c_local eqlabels  `"`macval(labels)'"'        // list of labels
    }
    else c_local eqlabels ""
end

* 2. estpost_summarize: wrapper for -summarize-
prog estpost_summarize, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax [varlist] [if] [in] [aw fw iw] [, ESample Quietly ///
        LISTwise CASEwise Detail MEANonly ]
    if "`casewise'"!="" local listwise listwise

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // gather results
    local nvars: list sizeof varlist
    tempname emptymat
    mat `emptymat' = J(1, `nvars', .)
    mat coln `emptymat' = `varlist'
    local i 0
    local rnames ""
    foreach v of local varlist {
        local ++i
        qui summarize `v' if `touse' [`weight'`exp'], `detail' `meanonly'
        local rnamesi: r(scalars)
        local rnamesi: list rnamesi - rnames
        if `"`rnamesi'"'!="" {
            foreach name of local rnamesi {
                tempname _`name'
                mat `_`name'' = `emptymat'
            }
            local rnames: list rnames | rnamesi
        }
        foreach rname of local rnames {
            mat `_`rname''[1,`i'] = r(`rname')
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        local rescoln
        foreach rname of local rnames {
            mat `res' = nullmat(`res'), `_`rname'''
            if "`rname'"=="N" {
                local rescoln `rescoln' e(count)
            }
            else {
                local rescoln `rescoln' e(`rname')
            }
        }
        mat coln `res' = `rescoln'
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            matlist `res', nohalf lines(oneline)
        }
        mat drop `res'
    }

    // post results
    local b
    local V
    if c(stata_version)<9 { // b and V required in Stata 8
        tempname b V
        mat `b' = J(1, `nvars', 0)
        mat coln `b' = `varlist'
        mat `V' = `b'' * `b'
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `b' `V', obs(`N') `esample'

    eret scalar k = `nvars'

    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local subcmd "summarize"
    eret local cmd "estpost"

    local nmat: list sizeof rnames
    forv i=`nmat'(-1)1 {
        local rname: word `i' of `rnames'
        if "`rname'"=="N" {
            eret matrix count = `_N'
            continue
        }
        eret matrix `rname' = `_`rname''
    }
end


* 2. estpost_tabulate: wrapper for -tabulate-
prog estpost_tabulate, eclass
    version 8.2
    local caller : di _caller() // not used
    syntax varlist(min=1 max=2) [if] [in] [fw aw iw pw] [, * ]
    if `:list sizeof varlist'==1 {
        version `caller': estpost_tabulate_oneway `0'
    }
    else {
        version `caller': estpost_tabulate_twoway `0'
    }
end
prog estpost_tabulate_oneway, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varname [if] [in] [fw aw iw] [, ESample Quietly ///
        noTOTal subpop(passthru) Missing sort noLabel ELabels ]

    // sample
    if "`missing'"!="" marksample touse, nov strok
    else               marksample touse, strok
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // handle string variables
    capt confirm numeric variable `varlist'
    if _rc {
        tempname varname
        qui encode `varlist' if `touse', generate(`varname')
    }
    else local varname `varlist'

    // gather results
    tempname count vals
    tab `varname' if `touse' [`weight'`exp'], nofreq ///
        matcell(`count') matrow(`vals') `subpop' `missing' `sort'
    local N = r(N)
    mat `count' = `count''
    local R = r(r)
    forv r = 1/`R' {
        local value: di `vals'[`r',1]
        local values `values' `value'
    }
    if "`label'"=="" {
        _estpost_namesandlabels `varname' "`values'" "" "`elabels'" // sets names, savenames, labels
    }
    else {
        _estpost_namesandlabels "" "`values'" "" "`elabels'"
    }
    if "`total'"=="" {
        mat `count' = `count', `N'
        local names `"`names' Total"'
        local savenames `"`savenames' Total"'
        local linesopt "lines(rowtotal)"
    }
    mat colname `count' = `names'
    tempname percent cum
    mat `percent' = `count'/`N'*100
    mat `cum' = J(1, colsof(`count'), .z)
    mat colname `cum' = `names'
    mat `cum'[1,1] = `count'[1,1]
    forv r = 2/`R' {
        mat `cum'[1,`r'] = `cum'[1,`r'-1] + `count'[1,`r']
    }
    mat `cum' = `cum'/`N'*100

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `count'', `percent'', `cum''
        mat coln `res' = e(b) e(pct) e(cumpct)
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g) nodotz
        }
        else {
            mat rown `res' = `savenames'
            matlist `res', nohalf `linesopt' rowtitle(`varlist') nodotz
        }
        mat drop `res'
        if `"`macval(labels)'"'!="" {
            di _n as txt "row labels saved in macro e(labels)"
        }
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = `count'' * `count' * 0
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `count' `V', depname(`varlist') obs(`N') `esample'
    eret scalar r = r(r)
    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local labels `"`macval(labels)'"'
    eret local depvar "`varlist'"
    eret local subcmd "tabulate"
    eret local cmd "estpost"
    eret mat cumpct = `cum'
    eret mat pct   = `percent'
end
prog estpost_tabulate_twoway, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist(min=2 max=2) [if] [in] [fw aw iw] [, ESample Quietly ///
        noTOTal Missing noLabel ELabels ///
        CHi2 Exact Exact2(passthru) Gamma LRchi2 Taub v All noLOg ]
    local v = upper("`v'")
    local qui2 "`quietly'"
    local hastests = `"`chi2'`exact'`exact2'`gamma'`lrchi2'`taub'`v'`all'"'!=""
    if `hastests' local nofreq nofreq
    else local qui2 "quietly"

    // sample
    if "`missing'"!="" marksample touse, nov strok
    else               marksample touse, strok
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // handle string variables
    gettoken rvar cvar : varlist
    gettoken cvar : cvar
    foreach d in r c {
        capt confirm numeric variable ``d'var'
        if _rc {
            tempname `d'varname
            qui encode ``d'var' if `touse', generate(``d'varname')
        }
        else local `d'varname ``d'var'
    }

    // gather results
    tempname cell rvals cvals
    if `hastests' {
        `quietly' di ""
    }
    `qui2' tab `rvarname' `cvarname' if `touse' [`weight'`exp'], `nofreq' ///
        matcell(`cell') matrow(`rvals') matcol(`cvals') `missing' ///
        `chi2' `exact' `exact2' `gamma' `lrchi2' `taub' `v' `all' `log'
    mat `cvals' = `cvals''
    local N = r(N)
    tempname rtot ctot
    mat `ctot' = J(1,rowsof(`cell'),1) * `cell'
    mat `rtot' =  `cell' * J(colsof(`cell'),1,1)
    foreach d in r c {
        local I = r(`d')
        forv i = 1/`I' {
            local value: di ``d'vals'[`i',1]
            local `d'values ``d'values' `value'
        }
    }
    if "`label'"=="" {
        _estpost_namesandlabels `rvarname' "`rvalues'" "" "`elabels'" // sets names, savenames, labels
        _estpost_eqnamesandlabels `cvarname' "`cvalues'" "" "`elabels'" // sets eqnames, eqlabels
    }
    else {
        _estpost_namesandlabels "" "`rvalues'" "" "`elabels'" // sets names, savenames, labels
        _estpost_eqnamesandlabels "" "`cvalues'" "" "`elabels'" // sets eqnames, eqlabels
    }
    local savenames0 `"`savenames'"'
    local savenames
    if "`total'"=="" {
        mat `ctot' = `ctot', `N'
        mat `cell' = (`cell', `rtot') \ `ctot'
        mat `rtot' = `rtot' \ `N'
        local names      `"`names' Total"'
        local savenames0 `"`savenames0' Total"'
        local eqnames    `"`eqnames' Total"'
    }
    mat rowname `cell' = `names'
    tempname count col row tot tmp
    forv i = 1/`=colsof(`cell')' {
        gettoken eq eqnames : eqnames
        mat `tmp' = `cell'[1...,`i']
        mat roweq `tmp' = `"`eq'"'
        mat `tmp' = `tmp''
        mat `count' = nullmat(`count'), `tmp'
        mat `col' = nullmat(`col'), `tmp' / `ctot'[1,`i']*100
        forv j = 1/`=colsof(`tmp')' {
            mat `tmp'[1,`j'] = `tmp'[1,`j'] / `rtot'[`j',1]*100
        }
        mat `row' = nullmat(`row'), `tmp'
        local savenames `"`savenames' `savenames0'"'
    }
    mat `tot' = `count' / `N'*100

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `count'', `tot'', `col'', `row''
        mat coln `res' = e(b) e(pct) e(colpct) e(rowpct)
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            mat rown `res' = `savenames'
            di _n as res %-12s abbrev("`cvar'",12) as txt " {c |}{space 44}"
            matlist `res', twidth(12) format(%9.0g) noblank nohalf rowtitle(`rvar')
        }
        mat drop `res'
        if `"`macval(labels)'`macval(eqlabels)'"'!="" {
            di ""
            if `"`macval(labels)'"'!="" {
                di as txt "row labels saved in macro e(labels)"
            }
            if `"`macval(eqlabels)'"'!="" {
                di as txt "column labels saved in macro e(eqlabels)"
            }
        }
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = `count'' * `count' * 0
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `count' `V', obs(`N') `esample'
    local rscalars: r(scalars)
    local rscalars: subinstr local rscalars "N" "", word
    foreach rsc of local rscalars {
        eret scalar `rsc' = r(`rsc')
    }
    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local labels `"`macval(labels)'"'
    eret local eqlabels `"`macval(eqlabels)16jun2015'"'
    eret local colvar "`cvar'"
    eret local rowvar "`rvar'"
    eret local subcmd "tabulate"
    eret local cmd "estpost"
    eret mat rowpct = `row'
    eret mat colpct = `col'
    eret mat pct = `tot'
end


* 4. estpost_tabstat: wrapper for -tabstat-
prog estpost_tabstat, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist [if] [in] [aw fw] [, ESample Quietly ///
          Statistics(passthru) stats(passthru) LISTwise CASEwise ///
          by(varname) noTotal Missing Columns(str) ELabels ]
    if "`casewise'"!="" local listwise listwise
    local l = length(`"`columns'"')
    if `"`columns'"'==substr("variables",1,max(1,`l')) local columns "variables"
    else if `"`columns'"'==substr("statistics",1,max(1,`l')) local columns "statistics"
    else if `"`columns'"'=="stats" local columns "statistics"
    else if `"`columns'"'=="" {
        if `:list sizeof varlist'>1 local columns "variables"
        else local columns "statistics"
    }
    else {
        di as err `"columns(`columns') invalid"'
        exit 198
    }

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    if "`by'"!="" {
        capt confirm string variable `by'
        local numby = (_rc!=0)
        if `numby' {
            tempname tmpby
            qui gen `:type `by'' `tmpby' = `by'
        }
        else local tmpby `by'
        if "`missing'"=="" markout `touse' `by', strok
        local byopt "by(`tmpby')"
    }
    else local numby 0
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // gather results
    if "`total'"!="" & "`by'"=="" {
        di as txt "nothing to post"
        eret clear
        exit
    }
    qui tabstat `varlist' if `touse' [`weight'`exp'], save ///
        `statistics' `stats' `byopt' `total' `missing' columns(`columns')
    tempname tmp
    capt confirm matrix r(StatTot)
    if _rc {
        mat `tmp' = r(Stat1)
    }
    else {
        mat `tmp' = r(StatTot)
    }
    if `"`columns'"'=="statistics" {
        local cnames: rownames `tmp'
        local cnames: subinstr local cnames "N" "count", word all
        local cnames: subinstr local cnames "se(mean)" "semean", word all
        local R = colsof(`tmp')
        local stats "`cnames'"
        local vars: colnames `tmp'
    }
    else {
        local cnames: colnames `tmp'
        local R = rowsof(`tmp')
        local stats: rownames `tmp'
        local stats: subinstr local stats "N" "count", word all
        local stats: subinstr local stats "se(mean)" "semean", word all
        local vars "`cnames'"
        local cnames: subinstr local cnames "b" "_b", word all
        local cnames: subinstr local cnames "V" "_V", word all
    }
    local j 0
    foreach cname of local cnames {
        tempname _`++j'
    }
    local groups: r(macros)
    local g: list sizeof groups
    local space
    local labels
    forv i = 1/`g' {
        local labels `"`labels'`space'`"`r(name`i')'"'"'
    }
    if `R'==1 {
        if `numby' {
            _estpost_namesandlabels "`by'" `"`labels'"' "" "`elabels'" // sets names, savenames, labels
        }
        else {
            _estpost_namesandlabels "" "" `"`labels'"' "`elabels'" // sets names, savenames, labels
        }
    }
    else {
        if `numby' {
            _estpost_eqnamesandlabels "`by'" `"`labels'"' "" "`elabels'" // sets eqnames, eqlabels
        }
        else {
            _estpost_eqnamesandlabels "" "" `"`labels'"' "`elabels'" // sets eqnames, eqlabels
        }
        local names `"`eqnames'"'
        local labels `"`macval(eqlabels)'"'
    }
    forv i = 1/`g' {
        gettoken name names : names
        mat `tmp' = r(Stat`i')
        mat rown `tmp' = `stats'
        if `"`columns'"'=="statistics" {
            mat `tmp' = `tmp''
        }
        if `R'==1 {
            mat rown `tmp' = `"`name'"'
        }
        else {
            mat roweq `tmp' = `"`name'"'
        }
        local j 0
        foreach cname of local cnames {
            local ++j
            mat `_`j'' = nullmat(`_`j''), `tmp'[1..., `j']'
        }
    }
    if "`total'"=="" {
        mat `tmp' = r(StatTot)
        mat rown `tmp' = `stats'
        if `"`columns'"'=="statistics" {
            mat `tmp' = `tmp''
        }
        if `g'>0 {
            if `R'==1 {
                mat rown  `tmp' = "Total"
                local savenames `"`savenames' Total"'
                local rowtotal "lines(rowtotal)"
            }
            else {
                mat roweq `tmp' = "Total"
                if `"`labels'"'!="" {
                    local labels `"`macval(labels)' Total"'
                }
            }
        }
        local j 0
        foreach cname of local cnames {
            local ++j
            mat `_`j'' = nullmat(`_`j''), `tmp'[1..., `j']'
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        local rescoln
        local j 0
        foreach cname of local cnames {
            local ++j
            mat `res' = nullmat(`res'), `_`j'''
            local rescoln `rescoln' e(`cname')
        }
        mat coln `res' = `rescoln'
        di _n as txt "Summary statistics: `stats'"
        di    as txt "     for variables: `vars'"
        if "`by'"!="" {
            di as txt "  by categories of: `by'"
        }
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            if `R'==1 & `g'>0 {
                mat rown `res' = `savenames'
            }
            matlist `res', nohalf `rowtotal' rowtitle(`by')
        }
        if `"`macval(labels)'"'!="" {
            di _n as txt "category labels saved in macro e(labels)"
        }
        mat drop `res'
    }

    // post results
    local b
    local V
    if c(stata_version)<9 { // b and V required in Stata 8
        tempname b V
        mat `b' = `_1' \ J(1, colsof(`_1'), 0)
        mat `b' = `b'[2,1...]
        mat `V' = `b'' * `b'
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `b' `V', obs(`N') `esample'

    eret local labels `"`macval(labels)'"'
    eret local byvar "`by'"
    eret local vars "`vars'"
    eret local stats "`stats'"
    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local subcmd "tabstat"
    eret local cmd "estpost"

    local nmat: list sizeof cnames
    forv j=`nmat'(-1)1 {
        local cname: word `j' of `cnames'
        eret matrix `cname' = `_`j''
    }
end


* 5. estpost_ttest: wrapper for -ttest- (two-sample)
prog estpost_ttest, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist(numeric) [if] [in] , by(varname) [ ESample Quietly ///
         LISTwise CASEwise UNEqual Welch ]
    if "`casewise'"!="" local listwise listwise

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    markout `touse' `by', strok
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // gather results
    local nvars: list sizeof varlist
    tempname diff count
    mat `diff' = J(1, `nvars', .)
    mat coln `diff' = `varlist'
    mat `count' = `diff'
    local mnames se /*sd*/ t df_t p_l p p_u N_1 mu_1 /*sd_1*/ N_2 mu_2 /*sd_2*/
    foreach m of local mnames {
        tempname `m'
        mat ``m'' = `diff'
    }
    local i 0
    foreach v of local varlist {
        local ++i
        qui ttest `v' if `touse', by(`by') `unequal' `welch'
        mat `diff'[1,`i'] = r(mu_1) - r(mu_2)
        mat `count'[1,`i'] = r(N_1) + r(N_2)
        foreach m of local mnames {
            mat ``m''[1,`i'] = r(`m')
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `diff'', `count''
        local rescoln "e(b) e(count)"
        foreach m of local mnames {
            mat `res' = `res', ``m'''
            local rescoln `rescoln' e(`m')
        }
        mat coln `res' = `rescoln'
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            matlist `res', nohalf lines(oneline)
        }
        mat drop `res'
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = diag(vecdiag(`se'' * `se'))
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `diff' `V', obs(`N') `esample'

    eret scalar k = `nvars'

    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local welch "`welch'"
    eret local unequal "`unequal'"
    eret local byvar "`by'"
    eret local subcmd "ttest"
    eret local cmd "estpost"

    local nmat: list sizeof mnames
    forv i=`nmat'(-1)1 {
        local m: word `i' of `mnames'
        eret matrix `m' = ``m''
    }
    eret matrix count = `count'
end


* 6. estpost_correlate: wrapper for -correlate-
prog estpost_correlate, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist [if] [in] [aw fw iw pw] [, ESample Quietly ///
        LISTwise CASEwise ///
        Matrix noHalf Print(real 1) /*Covariance*/ Bonferroni SIDak ]
    if "`casewise'"!="" local listwise listwise
    if "`bonferroni'"!="" & "`sidak'"!="" {
        di as err "only one of bonferroni and sidak allowed"
        exit 198
    }
    local pw = ("`weight'"=="pweight")
    if `:list sizeof varlist'<=1 & `"`matrix'"'=="" {
        di as err "too few variables specified"
        exit 102
    }
    if `"`matrix'"'!="" & `"`half'"'!="" local fullmatrix fullmatrix

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // gather results
    tempname b rho pval count
    if "`bonferroni'`sidak'"!="" {
        local nvars : list sizeof varlist
        local k = `nvars' * (`nvars'-1) / 2
    }
    foreach depvar of local varlist {
        if `"`fullmatrix'"'!="" {
            local indepvars `varlist'
        }
        else if `"`matrix'"'!="" {
            local indepvars `depvar' `ferest()'
        }
        else {
            local indepvars `ferest()'
        }
        foreach v of local indepvars {
            qui reg `depvar' `v' [`weight'`exp'] if `touse'
            local r = sqrt(e(r2)) * (-1)^(_b[`v']<0)
            local n = e(N)
            mat `b' = nullmat(`b'), `r'
            if "`depvar'"=="`v'" {
                mat `rho'  = nullmat(`rho'), `r'
                mat `count' = nullmat(`count'), `n'
                mat `pval' = nullmat(`pval'), .z
                continue
            }
            local p = Ftail(e(df_m), e(df_r), e(F))
            if `pw' {
                qui reg `v' `depvar' [`weight'`exp'] if `touse'
                local p = max(`p', Ftail(e(df_m), e(df_r), e(F)))
            }
            if "`bonferroni'"!="" {
                local p = min(1, `k'*`p')
            }
            else if "`sidak'"!="" {
                local p = min(1, 1 - (1-`p')^`k')
            }
            if `p'>`print' {
                local r .z
                local n .z
                local p .z
            }
            mat `rho'  = nullmat(`rho'), `r'
            mat `count' = nullmat(`count'), `n'
            mat `pval' = nullmat(`pval'), `p'
        }
        if `"`matrix'`fullmatrix'"'=="" {
            local colnames `indepvars'
            local depname `depvar'
            continue, break
        }
        foreach v of local indepvars {
            local colnames `"`colnames'`depvar':`v' "'
        }
    }
    mat coln `b' = `colnames'
    mat coln `rho' = `colnames'
    mat coln `count' = `colnames'
    mat coln `pval' = `colnames'
    local vce `"`e(vce)'"'          // from last -regress- call
    local vcetype `"`e(vcetype)'"'

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `b'', `rho'', `pval'', `count''
        mat coln `res' = e(b) e(rho) e(p) e(count)
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g) nodotz
        }
        else {
            matlist `res', nohalf lines(oneline) rowtitle(`depname') nodotz
        }
        mat drop `res'
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = `b'' * `b' * 0
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `b' `V', depname(`depname') obs(`N') `esample'
    eret local vcetype `"`vcetype'"'
    eret local vce `"`vce'"'
    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local depvar `depname'
    eret local subcmd "correlate"
    eret local cmd "estpost"
    eret matrix count = `count'
    eret matrix p = `pval'
    eret matrix rho = `rho'
end


* 7. estpost_stci: wrapper for -stci-
prog estpost_stci, eclass
    version 9.2                 // Stata 8 not supported because levelsof is used
    local caller : di _caller() // not used

    // syntax
    syntax [if] [in] [ , ESample Quietly by(varname) ///
        Median Rmean Emean p(numlist >0 <100 integer max=1) ///
        CCorr Level(real `c(level)') ELabels ]
    local stat "p50"
    if `"`p'"'!="" {
        local stat `"p`p'"'
        local p `"p(`p')"'
    }
    else if "`rmean'"!=""   local stat "rmean"
    else if "`emean'"!=""   local stat "emean"

    // sample
    marksample touse
    if `"`by'"'!="" {
        markout `touse' `by', strok
    }
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // get results
    tempname _`stat' se N_sub lb ub
    if "`by'"!="" {
        qui levelsof `by' if `touse', local(levels)
        capt confirm string variable `by'
        if _rc {
            local vallab: value label `by'
            if `"`vallab'"'!="" {
                _estpost_namesandlabels `by' `"`levels'"' "" "`elabels'" // sets names, savenames, labels
            }
            else {
                local names `"`levels'"'
                local savenames `"`levels'"'
            }
        }
        else {
            _estpost_namesandlabels `by' "" `"`levels'"' "`elabels'" // sets names, savenames, labels
        }
    }
    local levels `"`levels' "total""'
    local names `"`names' "total""'
    local savenames `"`savenames' "total""'
    gettoken l rest : levels, quotes
    while (`"`l'"'!="") {
        if `"`rest'"'=="" local lcond
        else              local lcond `" & `by'==`l'"'
        qui stci if `touse'`lcond', `median' `rmean' `emean' `p' `ccorr' level(`level')
        mat `_`stat'' = nullmat(`_`stat''), r(`stat')
        mat `se' = nullmat(`se'), r(se)
        mat `N_sub' = nullmat(`N_sub'), r(N_sub)
        mat `lb' = nullmat(`lb'), r(lb)
        mat `ub' = nullmat(`ub'), r(ub)
        gettoken l rest : rest, quotes
    }
    foreach m in _`stat' se N_sub lb ub {
        mat coln ``m'' = `names'
    }

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `N_sub'', `_`stat''', `se'', `lb'', `ub''
        mat coln `res' = e(count) e(`stat') e(se) e(lb) e(ub)
        di as txt "(confidence level is " `level' "%)"
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g) nodotz
        }
        else {
            mat rown `res' = `savenames'
            matlist `res', nohalf lines(rowtotal) nodotz
        }
        mat drop `res'
        if `"`labels'"'!="" {
            di _n as txt "labels saved in macro e(labels)"
        }
    }

    // post results
    local b
    local V
    if c(stata_version)<9 { // b and V required in Stata 8
        tempname b V
        mat `b' = `_`stat'' \ J(1, colsof(`_`stat''), 0)
        mat `b' = `b'[2,1...]
        mat `V' = `b'' * `b'
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `b' `V', obs(`N') `esample'
    eret scalar level = `level'

    eret local ccorr `ccorr'
    eret local labels `"`labels'"'
    eret local subcmd "stci"
    eret local cmd "estpost"

    eret matrix ub = `ub'
    eret matrix lb = `lb'
    eret matrix se = `se'
    eret matrix `stat' = `_`stat''
    eret matrix count = `N_sub'
end


* 8. estpost_ci: wrapper for -ci-
prog estpost_ci, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax [varlist] [if] [in] [aw fw], [ ESample Quietly ///
         LISTwise CASEwise Level(real `c(level)') ///
         Binomial EXAct WAld Wilson Agresti Jeffreys ///
         Poisson Exposure(varname) ///
         ]
    if "`casewise'"!="" local listwise listwise
    if "`exposure'"!="" local exposureopt "exposure(`exposure')"
    if "`binomial'"!="" & "`exact'`wald'`wilson'`agresti'`jeffreys'"=="" local exact exact

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // gather results
    local mnames se lb ub
    tempname mean count `mnames'
    local i 0
    foreach v of local varlist {
        local ++i
        qui ci `v' if `touse' [`weight'`exp'], level(`level') ///
            `binomial' `exact' `wald' `wilson' `agresti' `jeffreys' ///
            `poisson' `exposureopt'
        if r(N)>=. continue
        mat `mean' = nullmat(`mean'), r(mean)
        mat `count' = nullmat(`count'), r(N)
        foreach m of local mnames {
            mat ``m'' = nullmat(``m''), r(`m')
        }
        local rnames "`rnames' `v'"
    }
    capt confirm matrix `count'
    if _rc {
        di as txt "nothing to post"
        eret clear
        exit
    }
    foreach m in mean count `mnames' {
        mat coln ``m'' = `rnames'
    }
    if "`listwise'"=="" { // update sample
        if colsof(`count') < `: list sizeof varlist' {
            _estpost_markout2 `touse' `rnames'
            qui count if `touse'
            local N = r(N)
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `mean'', `count''
        local rescoln "e(b) e(count)"
        foreach m of local mnames {
            mat `res' = `res', ``m'''
            local rescoln `rescoln' e(`m')
        }
        mat coln `res' = `rescoln'
        di as txt "(confidence level is " `level' "%)"
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            matlist `res', nohalf lines(oneline)
        }
        mat drop `res'
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = diag(vecdiag(`se'' * `se'))
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `mean' `V', obs(`N') `esample'

    eret scalar k = colsof(`count')
    eret scalar level = `level'

    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local exposure "`exposure'"
    eret local poisson "`poisson'"
    eret local binomial "`exact'`wald'`wilson'`agresti'`jeffreys'"
    eret local subcmd "ci"
    eret local cmd "estpost"

    local nmat: list sizeof mnames
    forv i=`nmat'(-1)1 {
        local m: word `i' of `mnames'
        eret matrix `m' = ``m''
    }
    eret matrix count = `count'
end


* 9. estpost_prtest: wrapper for -prtest- (two-sample)
prog estpost_prtest, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist(numeric) [if] [in] , by(varname) [ ESample Quietly ///
         LISTwise CASEwise  ]
    if "`casewise'"!="" local listwise listwise

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    markout `touse' `by', strok
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    // gather results
    local nvars: list sizeof varlist
    tempname diff count
    mat `count' = J(1, `nvars', .)
    mat coln `count' = `varlist'
    mat `diff' = `count'
    local mnames se se0 z p_l p p_u N_1 P_1 N_2 P_2
    foreach m of local mnames {
        tempname `m'
        mat ``m'' = `count'
    }
    local i 0
    foreach v of local varlist {
        local ++i
        qui prtest `v' if `touse', by(`by')
        mat `count'[1,`i'] = r(N_1) + r(N_2)
        mat `diff'[1,`i'] = r(P_1) - r(P_2)
        mat `se'[1,`i'] = sqrt(r(P_1)*(1-r(P_1))/r(N_1) + r(P_2)*(1-r(P_2))/r(N_2))
        mat `se0'[1,`i'] = `diff'[1,`i'] / r(z)
        mat `p_l'[1,`i'] = normal(r(z))
        mat `p'[1,`i'] = (1-normal(abs(r(z))))*2
        mat `p_u'[1,`i'] = 1-normal(r(z))
        foreach m in z N_1 P_1 N_2 P_2 {
            mat ``m''[1,`i'] = r(`m')
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `diff'', `count''
        local rescoln "e(b) e(count)"
        foreach m of local mnames {
            mat `res' = `res', ``m'''
            local rescoln `rescoln' e(`m')
        }
        mat coln `res' = `rescoln'
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            matlist `res', nohalf lines(oneline)
        }
        mat drop `res'
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = diag(vecdiag(`se'' * `se'))
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `diff' `V', obs(`N') `esample'

    eret scalar k = `nvars'

    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local byvar "`by'"
    eret local subcmd "prtest"
    eret local cmd "estpost"

    local nmat: list sizeof mnames
    forv i=`nmat'(-1)1 {
        local m: word `i' of `mnames'
        eret matrix `m' = ``m''
    }
    eret matrix count = `count'
end


* 10. estpost__svy_tabulate: wrapper for -svy:tabulate-
prog estpost__svy_tabulate
    version 9.2
    local caller : di _caller()
    _on_colon_parse `0'
    local svyopts `"svyopts(`s(before)')"'
    local 0       `"`s(after)'"'
    syntax varlist(min=1 max=2) [if] [in] [ , * ]
    if `:list sizeof varlist'==1 {
        version `caller': _svy_tabulate_oneway `varlist' `if' `in', ///
            `svyopts' `options'
    }
    else {
         version `caller': _svy_tabulate_twoway `varlist' `if' `in', ///
            `svyopts' `options'
    }
end
prog _svy_tabulate_oneway
    version 9.2
    local caller : di _caller() // not used

    // syntax
    syntax varname [if] [in] [, ESample Quietly ///
        svyopts(str asis) MISSing Level(cilevel) ///
        noTOTal noMARGinals noLabel ELabels PROPortion PERcent ///
        CELl COUnt se ci deff deft * ]
    if "`marginals'"!=""   local total "nototal"
    else if "`total'"!=""  local marginals "nomarginals"

    // run svy:tabulate
    `quietly' svy `svyopts' : tabulate `varlist' `if' `in', ///
        level(`level') `cell' `count' `se' `ci' `deff' `deft' ///
        `missing' `marginals' `label' `proportion' `percent' `options'
    if "`count'"!="" & "`cell'`se'`ci'`deff'`deft'"=="" { // => return count in e(b)
        quietly svy `svyopts' : tabulate `varlist' `if' `in', count se ///
            level(`level') `missing' `marginals' `label' `proportion' `percent' `options'
    }

    // get labels
    qui levelsof `varlist' if e(sample), `missing' local(levels)
    local R : list sizeof levels
    if e(r)!=`R' {
        di as err "unexpected error; number of rows unequal number of levels"
        exit 499
    }
    capt confirm string variable `varlist'
    if _rc {
        if "`label'"=="" {
            _estpost_namesandlabels `varlist' "`levels'" "" "`elabels'" // sets names, savenames, labels
        }
        else {
            _estpost_namesandlabels "" "`levels'" "" "`elabels'" // sets names, savenames, labels
        }
    }
    else {
        _estpost_namesandlabels "" "" `"`levels'"' "`elabels'" // sets names, savenames, labels
    }

    // collect results
    tempname cell count obs b se lb ub deff deft
    local N_pop = cond(e(N_subpop)<., e(N_subpop), e(N_pop))
    local N_obs = cond(e(N_sub)<., e(N_sub), e(N))
    local tval = invttail(e(df_r), (100-`level')/200)
    if `tval'>=. local tval = invnormal(1 - (100-`level')/200)
    mat `cell'  = e(Prop)'
    mat `count' = `cell' * `N_pop'
    capture confirm matrix e(ObsSub)
    if _rc {
        mat `obs'   = e(Obs)'
    }
    else {
        mat `obs'   = e(ObsSub)'
    }
    capture confirm matrix e(Deff)
    if _rc local DEFF  ""
    else   {
        local DEFF deff
        mat `deff'  = e(Deff)
    }
    capture confirm matrix e(Deft)
    if _rc local DEFT  ""
    else   {
        local DEFT deft
        mat `deft'  = e(Deft)
    }
    mat `b' = e(b)
    mata: st_matrix(st_local("se"), sqrt(diagonal(st_matrix("e(V)")))')
    if "`total'"=="" {
        mat `cell'  = `cell', 1
        mat `count' = `count', `N_pop'
        mat `obs'   = `obs', `N_obs'
        if "`DEFF'"!="" mat `deff'  = `deff', .z
        if "`DEFT'"!="" mat `deft'  = `deft', .z
        if e(setype)=="count" {
            mat `b' = `b', `N_pop'
            mat `se' = `se', sqrt(el(e(V_col),1,1))
        }
        else { // e(setype)=="cell"
            mat `b' = `b', 1
            mat `se' = `se', 0
        }
        local names `"`names' "Total""'
        local savenames `"`savenames' "Total""'
        local linesopt "lines(rowtotal)"

    }
    if e(setype)!="count" {
        mata: st_matrix( st_local("lb"), invlogit( ///
            logit(st_matrix(st_local("b"))) - strtoreal(st_local("tval")) * ///
                st_matrix(st_local("se")) :/ ///
                (st_matrix(st_local("b")) :* (1 :- st_matrix(st_local("b"))))))
        mata: st_matrix( st_local("ub"), invlogit( ///
            logit(st_matrix(st_local("b"))) + strtoreal(st_local("tval")) * ///
                st_matrix(st_local("se")) :/ ///
                (st_matrix(st_local("b")) :* (1 :- st_matrix(st_local("b"))))))
        if "`total'"=="" {
            mat `lb'[1, colsof(`lb')] = .z
            mat `ub'[1, colsof(`ub')] = .z
        }
    }
    else {
        mata: st_matrix( st_local("lb"), st_matrix(st_local("b")) - ///
            strtoreal(st_local("tval")) * st_matrix(st_local("se")) )
        mata: st_matrix( st_local("ub"), st_matrix(st_local("b")) + ///
            strtoreal(st_local("tval")) * st_matrix(st_local("se")) )
    }
    foreach m in cell count obs b se lb ub `DEFF' `DEFT' {
        capt mat coln ``m'' = `names'
    }
    if "`percent'"!="" {
        mat `cell' = `cell' * 100
        if e(setype)!="count" {
            mat `b' = `b' * 100
            mat `se' = `se' * 100
            mat `lb' = `lb' * 100
            mat `ub' = `ub' * 100
        }
    }

    // display
    if "`quietly'"=="" {
        /*
        tempname res
        mat `res' = `b'', `se'', `lb'', `ub'', `deff'', `deft'' ///, `cell'', `count'', `obs''
        mat coln `res' = e(b) e(se) e(lb) e(ub) e(deff) e(deft) /// e(cell) e(count) e(obs)
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g) nodotz
        }
        else {
            mat rown `res' = `savenames'
            matlist `res', nohalf `linesopt' rowtitle(`varlist') nodotz
        }
        mat drop `res'
        */
        local plabel = cond("`percent'"!="","percentages","proportions")
        local blabel = cond("`e(setype)'"=="count", "weighted counts", "`e(setype)' `plabel'")
        di _n as txt "saved vectors:"
        di as txt %20s "e(b) = "     " " as res "`blabel'"
        di as txt %20s "e(se) = "    " " as res "standard errors of `blabel'"
        di as txt %20s "e(lb) = "    " " as res "lower `level'% confidence bounds for `blabel'"
        di as txt %20s "e(ub) = "    " " as res "upper `level'% confidence bounds for `blabel'"
        if "`DEFF'"!="" ///
            di as txt %20s "e(deff) = "  " " as res "deff for variances of `blabel'"
        if "`DEFT'"!="" ///
            di as txt %20s "e(deft) = "  " " as res "deft for variances of `blabel'"
        di as txt %20s "e(cell) = "  " " as res "cell `plabel'"
        di as txt %20s "e(count) = " " " as res "weighted counts"
        di as txt %20s "e(obs) = "   " " as res "number of observations"
        if `"`labels'"'!="" {
            di _n as txt "row labels saved in macro e(labels)"
        }
    }

    // post results
    erepost b=`b', cmd(estpost) nov `esample'
    qui estadd local labels `"`labels'"'
    qui estadd local subcmd "tabulate"
    qui estadd scalar level = `level'
    foreach m in obs count cell `DEFT' `DEFF' ub lb se {
        qui estadd matrix `m' = ``m'', replace
    }
end
prog _svy_tabulate_twoway
    version 9.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist(min=1 max=2) [if] [in] [, ESample Quietly ///
        svyopts(str asis) MISSing Level(cilevel) ///
        noTOTal noMARGinals noLabel ELabels PROPortion PERcent ///
        CELl COUnt COLumn row se ci deff deft * ]
    if "`marginals'"!=""   local total "nototal"
    else if "`total'"!=""  local marginals "nomarginals"

    // run svy:tabulate
    `quietly' svy `svyopts' : tabulate `varlist' `if' `in', ///
        level(`level') `cell' `count' `column' `row' `se' `ci' `deff' `deft' ///
        `missing' `marginals' `label' `proportion' `percent' `options'
    if `: word count `count' `column' `row''==1 & "`cell'`se'`ci'`deff'`deft'"=="" {
        quietly svy `svyopts' : tabulate `varlist' `if' `in', `count' `column' `row' se ///
            level(`level') `missing' `marginals' `label' `proportion' `percent' `options'
    }

    // get labels
    local rvar `"`e(rowvar)'"'
    qui levelsof `rvar' if e(sample), `missing' local(levels)
    local R : list sizeof levels
    if e(r)!=`R' {
        di as err "unexpected error; number of rows unequal number of rowvar levels"
        exit 499
    }
    capt confirm string variable `rvar'
    if _rc {
        if "`label'"=="" {
            _estpost_namesandlabels `rvar' "`levels'" "" "`elabels'" // sets names, savenames, labels
        }
        else {
            _estpost_namesandlabels "" "`levels'" "" "`elabels'" // sets names, savenames, labels
        }
    }
    else {
        _estpost_namesandlabels "" "" `"`levels'"' "`elabels'" // sets names, savenames, labels
    }
    local cvar `"`e(colvar)'"'
    qui levelsof `cvar' if e(sample), `missing' local(levels)
    local C : list sizeof levels
    if e(c)!=`C' {
        di as err "unexpected error; number of column unequal number of colvar levels"
        exit 499
    }
    local savenames0 `"`savenames'"'
    local savenames
    capt confirm string variable `cvar'
    if _rc {
        if "`label'"=="" {
            _estpost_eqnamesandlabels `cvar' "`levels'" "" "`elabels'" // sets eqnames, eqlabels
        }
        else {
            _estpost_eqnamesandlabels "" "`levels'" "" "`elabels'" // sets eqnames, eqlabels
        }
    }
    else {
        _estpost_eqnamesandlabels "" "" `"`levels'"' "`elabels'" // sets eqnames, eqlabels
    }

    // collect results
    tempname tmp cell row col count obs b se lb ub deff deft
    local N_pop = cond(e(N_subpop)<., e(N_subpop), e(N_pop))
    local N_obs = cond(e(N_sub)<., e(N_sub), e(N))
    local tval = invttail(e(df_r), (100-`level')/200)
    if `tval'>=. local tval = invnormal(1 - (100-`level')/200)
    mat `cell' = e(Prop)    // r x c matrix
    mat `cell' = (`cell', `cell' * J(`C',1,1)) \ (J(1,`R',1) * `cell', 1)
    mat `count' = `cell' * `N_pop'
    mat `tmp' = `cell'[1..., `C'+1]
    mata: st_matrix(st_local("row"), st_matrix(st_local("cell")) :/ ///
        st_matrix(st_local("tmp")))
    mat `tmp' = `cell'[`R'+1, 1...]
    mata: st_matrix(st_local("col"), st_matrix(st_local("cell")) :/ ///
        st_matrix(st_local("tmp")))
    mat drop `tmp'
    capture confirm matrix e(ObsSub)
    if _rc {
        mat `obs' = e(Obs)    // r x c matrix
    }
    else {
        mat `obs' = e(ObsSub) // r x c matrix
    }
    capt confirm matrix e(Deff)
    if _rc local DEFF ""
    else {
        local DEFF deff
        mat `deff'  = e(Deff)   // vector
    }
    capt confirm matrix e(Deft)
    if _rc local DEFT ""
    else {
        local DEFT deft
        mat `deft'  = e(Deft)   // vector
    }
    mat `b' = e(b)          // vector
    mata: st_matrix(st_local("se"), sqrt(diagonal(st_matrix("e(V)")))') // vector
    if e(setype)=="count"       local btype count
    else if e(setype)=="row"    local btype row
    else if e(setype)=="column" local btype col
    else                        local btype cell
    foreach m in `DEFF' `DEFT' b se { // vector -> r x c matrix
        forv r = 1/`R' {
            local from = (`r'-1)*`C' + 1
            local to = `r'*`C'
            mat `tmp' = nullmat(`tmp') \ ``m''[1, `from'..`to']
        }
        mat drop ``m''
        mat rename `tmp' ``m''
    }
    if "`total'"=="" {
        mat `obs' = (`obs', `obs' * J(`C',1,1)) \ (J(1,`R',1) * `obs', `N_obs')
        if "`DEFF'"!="" mat `deff'  = (`deff', e(Deff_row)') \ (e(Deff_col), .z)
        if "`DEFT'"!="" mat `deft'  = (`deft', e(Deft_row)') \ (e(Deft_col), .z)
        mat `b' = (`b', ``btype''[1..`R',`C'+1]) \ ``btype''[`R'+1,1...]
        mata: st_matrix(st_local("se"), ///
            ((st_matrix(st_local("se")), sqrt(diagonal(st_matrix("e(V_row)")))) ///
            \ (sqrt(diagonal(st_matrix("e(V_col)")))', .z)))
        if "`btype'"=="row" {
            mat `se' = `se'[1..., 1..`C'], J(`R'+1, 1, .z)
        }
        else if "`btype'"=="col" {
            mat `se' = `se'[1..`R', 1...] \ J(1, `C'+1, .z)
        }
        local names `"`names' "Total""'
        local savenames0 `"`savenames0' "Total""'
        local eqnames `"`eqnames' "Total""'
    }
    else {
        mat `cell' = `cell'[1..`R', 1..`C']
        mat `count' = `count'[1..`R', 1..`C']
        mat `row' = `row'[1..`R', 1..`C']
        mat `col' = `col'[1..`R', 1..`C']
    }
    if "`btype'"!="count" {
        mata: st_matrix( st_local("lb"), invlogit( ///
            logit(st_matrix(st_local("b"))) - strtoreal(st_local("tval")) * ///
                st_matrix(st_local("se")) :/ ///
                (st_matrix(st_local("b")) :* (1 :- st_matrix(st_local("b"))))))
        mata: st_matrix( st_local("ub"), invlogit( ///
            logit(st_matrix(st_local("b"))) + strtoreal(st_local("tval")) * ///
                st_matrix(st_local("se")) :/ ///
                (st_matrix(st_local("b")) :* (1 :- st_matrix(st_local("b"))))))
    }
    else {
        mata: st_matrix( st_local("lb"), st_matrix(st_local("b")) - ///
            strtoreal(st_local("tval")) * st_matrix(st_local("se")) )
        mata: st_matrix( st_local("ub"), st_matrix(st_local("b")) + ///
            strtoreal(st_local("tval")) * st_matrix(st_local("se")) )
    }
    if "`total'"=="" {
        if "`btype'"=="row" {
            mat `lb' = `lb'[1..., 1..`C'] , J(`R'+1, 1, .z)
            mat `ub' = `ub'[1..., 1..`C'] , J(`R'+1, 1, .z)
        }
        else if  "`btype'"=="col" {
            mat `lb' = `lb'[1..`R', 1...] \ J(1, `C'+1, .z)
            mat `ub' = `ub'[1..`R', 1...] \ J(1, `C'+1, .z)
        }
        else {
            mat `lb'[`R'+1, `C'+1] = .z
            mat `ub'[`R'+1, `C'+1] = .z
        }
    }
    foreach m in cell count obs row col `DEFF' `DEFT' b se lb ub { // r x c matrix -> vector
        mat rown ``m'' = `names'
        gettoken eq rest : eqnames
        forv c = 1/`=colsof(``m'')' {
            mat roweq ``m'' = `"`eq'"'
            mat `tmp' = nullmat(`tmp'), ``m''[1...,`c']'
            gettoken eq rest : rest
        }
        mat drop ``m''
        mat rename `tmp' ``m''
    }
    if "`percent'"!="" {
        mat `cell' = `cell' * 100
        mat `col' = `col' * 100
        mat `row' = `row' * 100
        if e(setype)!="count" {
            mat `b' = `b' * 100
            mat `se' = `se' * 100
            mat `lb' = `lb' * 100
            mat `ub' = `ub' * 100
        }
    }

    // display
    if "`quietly'"=="" {
        /*
        forv c = 1/`=colsof(`cell')' {
            local savenames `"`savenames' `savenames0'"'
        }
        tempname res
        mat `res' = `b'', `se'', `lb'', `ub'', `deff'', `deft'', `cell'', `row'', `col'', `count'', `obs''
        mat coln `res' = e(b) e(se) e(lb) e(ub) e(deff) e(deft) e(cell) e(row) e(col) e(count) e(obs)
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g) nodotz
        }
        else {
            mat rown `res' = `savenames'
            di _n as res %-12s abbrev("`cvar'",12) as txt " {c |}{space 44}"
            matlist `res', twidth(12) format(%9.0g) noblank nohalf ///
                rowtitle(`rvar') nodotz
        }
        mat drop `res'
        */
        local plabel = cond("`percent'"!="","percentages","proportions")
        local blabel = cond("`e(setype)'"=="count", "weighted counts", "`e(setype)' `plabel'")
        di _n as txt "saved vectors:"
        di as txt %20s "e(b) = "     " " as res "`blabel'"
        di as txt %20s "e(se) = "    " " as res "standard errors of `blabel'"
        di as txt %20s "e(lb) = "    " " as res "lower `level'% confidence bounds for `blabel'"
        di as txt %20s "e(ub) = "    " " as res "upper `level'% confidence bounds for `blabel'"
        if "`DEFF'"!="" ///
            di as txt %20s "e(deff) = "  " " as res "deff for variances of `blabel'"
        if "`DEFT'"!="" ///
            di as txt %20s "e(deft) = "  " " as res "deft for variances of `blabel'"
        di as txt %20s "e(cell) = "  " " as res "cell `plabel'"
        di as txt %20s "e(row) = "   " " as res "row `plabel'"
        di as txt %20s "e(col) = "   " " as res "column `plabel'"
        di as txt %20s "e(count) = " " " as res "weighted counts"
        di as txt %20s "e(obs) = "   " " as res "number of observations"
        if `"`labels'`eqlabels'"'!="" {
            di ""
            if `"`labels'"'!="" {
                di as txt "row labels saved in macro e(labels)"
            }
            if `"`eqlabels'"'!="" {
                di as txt "column labels saved in macro e(eqlabels)"
            }
        }
    }

    // post results
    erepost b=`b', cmd(estpost) nov `esample'
    qui estadd local eqlabels `"`eqlabels'"'
    qui estadd local labels `"`labels'"'
    qui estadd local subcmd "tabulate"
    qui estadd scalar level = `level'
    foreach m in obs count row col cell `DEFT' `DEFF' ub lb se {
        qui estadd matrix `m' = ``m'', replace
    }
end

* 11. estpost_margins: wrapper for -margins- (Stata 11)
prog estpost_margins, eclass
    version 11
    local caller : di _caller()

    // syntax
    _parse comma anything 0 : 0
    syntax [ , /*ESample*/ Quietly ///
        post * ]
    if "`post'"!="" {
        di as err "post not allowed"
        exit 198
    }

    // run margins
    `quietly' version `caller': margins `anything', `options'

    // post results
    capt postrtoe, noclear resize
    if _rc<=1 {     // -postrtoe- does not work, e.g., with -regress-
        error _rc   // _rc=1 (break)
        exit
    }
    tempname b V
    mat `b' = r(b)
    mat `V' = r(V)
    erepost b = `b' V = `V' /*, `esample'*/
    foreach r in `:r(scalars)' {
        eret scalar `r' = r(`r')
    }
    foreach r in `:r(macros)' {
        eret local `r' `"`r(`r')'"'
    }
    tempname tmp
    foreach r in `:r(matrices)' {
        if inlist("`r'", "b", "V") continue
        mat `tmp' = r(`r')
        eret matrix `r' = `tmp'
    }
end

* 12. estpost_gtabstat: wrapper for -gstats tabstat- (gtools required)
prog estpost_gtabstat, eclass
    version 13.1
    local caller : di _caller() // not used

    cap gtools
    if ( _rc ) {
        disp as err "gtools required for estpost gtabstat"
        exit 111
    }

    // syntax
    syntax varlist [if] [in] [aw fw] [, ESample Quietly ///
          Statistics(passthru) stats(passthru) LISTwise CASEwise ///
          by(varname) Missing Columns(str) ELabels ]
    if "`casewise'"!="" local listwise listwise
    local l = length(`"`columns'"')
    if `"`columns'"'==substr("variables",1,max(1,`l')) local columns "variables"
    else if `"`columns'"'==substr("statistics",1,max(1,`l')) local columns "statistics"
    else if `"`columns'"'=="stats" local columns "statistics"
    else if `"`columns'"'=="" {
        if `:list sizeof varlist'>1 local columns "variables"
        else local columns "statistics"
    }
    else {
        di as err `"columns(`columns') invalid"'
        exit 198
    }

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    if "`by'"!="" {
        capt confirm string variable `by'
        local numby = (_rc!=0)

        // NOTE(mauricio): Not sure what this does. I think it's just
        // a copy of the by variable so that _estpost_eqnamesandlabels
        // parses the numeric input back into value labels?
        //
        // if `numby' {
        //     tempname tmpby
        //     qui gen `:type `by'' `tmpby' = `by'
        // }
        // else local tmpby `by'
        // local byopt "by(`tmpby')"

        if "`missing'"=="" markout `touse' `by', strok
        local byopt by(`by')
    }
    else local numby 0
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

    if ( `"`missing'"' == "" ) local missing nomissing

    // gather results
    tempname tmp
    tempname gtabstat
    qui gstats tabstat `varlist' if `touse' [`weight'`exp'], mata(`gtabstat') ///
        `statistics' `stats' `byopt' `missing' columns(`columns')

    mata st_local("stats",  invtokens(`gtabstat'.statnames))
    mata st_local("vars",   invtokens(`gtabstat'.statvars))
    mata st_local("R",      strofreal(`gtabstat'.ksources))
    mata st_local("g",      strofreal(`gtabstat'.kby? `gtabstat'.J: 0))

    local stats: subinstr local stats "N" "count", word all
    local stats: subinstr local stats "se(mean)" "semean", word all

    if `"`columns'"'=="statistics" {
        local cnames: copy local stats
    }
    else {
        local cnames: copy local vars
    }
    local cnames: subinstr local cnames "b" "_b", word all
    local cnames: subinstr local cnames "V" "_V", word all

    local j 0
    foreach cname of local cnames {
        tempname _`++j'
    }

    local space
    local labels
    forv i = 1/`g' {
        if `numby' {
            mata st_local("name", sprintf(st_varformat(`gtabstat'.byvars[1]), `gtabstat'.getnum(`i', 1)))
        }
        else {
            mata st_local("name", `gtabstat'.getchar(`i', 1, 0))
        }
        local labels `"`labels'`space'`"`name'"'"'
    }

    if `R'==1 {
        if `numby' {
            _estpost_namesandlabels "`by'" `"`labels'"' "" "`elabels'"   // sets names, savenames, labels
        }
        else {
            _estpost_namesandlabels "" "" `"`labels'"' "`elabels'"       // sets names, savenames, labels
        }
    }
    else {
        if `numby' {
            _estpost_eqnamesandlabels "`by'" `"`labels'"' "" "`elabels'" // sets eqnames, eqlabels
        }
        else {
            _estpost_eqnamesandlabels "" "" `"`labels'"' "`elabels'"     // sets eqnames, eqlabels
        }
        local names `"`eqnames'"'
        local labels `"`macval(eqlabels)'"'
    }

    tempname glabname
    tempname glabstat
    tempname glabvar
    tempname glabmat

    forv i = 1/`g' {
        mata `glabname' = `gtabstat'.getf(`i', 1, .)
        mata `glabmat'  = `gtabstat'.colvar? `gtabstat'.getOutputGroup(`i'): `gtabstat'.getOutputGroup(`i')'

        if `"`columns'"'=="statistics"  {
            mata `glabstat' = (J(`gtabstat'.kstats,   1, ""),         `gtabstat'.statnames')
            mata `glabvar'  = (J(`gtabstat'.ksources, 1, `glabname'), `gtabstat'.statvars')
        }
        else {
            mata `glabstat' = (J(`gtabstat'.kstats,   1, `glabname'), `gtabstat'.statnames')
            mata `glabvar'  = (J(`gtabstat'.ksources, 1, ""),         `gtabstat'.statvars')
        }

        mata st_matrix("`tmp'", `glabmat')
        mata st_matrixrowstripe("`tmp'", `glabstat')
        mata st_matrixcolstripe("`tmp'", `glabvar')

        if `"`columns'"'=="statistics"  {
            mat `tmp' = `tmp''
            if ( `R'==1 ) {
                mata `glabstat' = ("", `glabname')
                mata `glabvar'  = (J(`gtabstat'.kstats, 1, ""), `gtabstat'.statnames')
                mata st_matrixrowstripe("`tmp'", `glabstat')
                mata st_matrixcolstripe("`tmp'", `glabvar')
            }
        }

        local j 0
        foreach cname of local cnames {
            local ++j
            mat `_`j'' = nullmat(`_`j''), `tmp'[1..., `j']'
        }
    }

    if ( `g' == 0 ) {
        mata `glabmat'  = `gtabstat'.colvar? `gtabstat'.output: `gtabstat'.output'
        mata `glabstat' = (J(`gtabstat'.kstats,   1, ""), `gtabstat'.statnames')
        mata `glabvar'  = (J(`gtabstat'.ksources, 1, ""), `gtabstat'.statvars')

        mata st_matrix("`tmp'", `glabmat')
        mata st_matrixrowstripe("`tmp'", `glabstat')
        mata st_matrixcolstripe("`tmp'", `glabvar')
        if `"`columns'"'=="statistics" {
            mat `tmp' = `tmp''
        }

        local j 0
        foreach cname of local cnames {
            local ++j
            mat `_`j'' = nullmat(`_`j''), `tmp'[1..., `j']'
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        local rescoln
        local j 0
        foreach cname of local cnames {
            local ++j
            mat `res' = nullmat(`res'), `_`j'''
            local rescoln `rescoln' e(`cname')
        }
        mat coln `res' = `rescoln'
        di _n as txt "Summary statistics: `stats'"
        di    as txt "     for variables: `vars'"
        if "`by'"!="" {
            di as txt "  by categories of: `by'"
        }
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            if `R'==1 & `g'>0 {
                mat rown `res' = `savenames'
            }
            matlist `res', nohalf `rowtotal' rowtitle(`by')
        }
        if `"`macval(labels)'"'!="" {
            di _n as txt "category labels saved in macro e(labels)"
        }
        mat drop `res'
    }

    // post results
    local b
    local V
    if c(stata_version)<9 { // b and V required in Stata 8
        tempname b V
        mat `b' = `_1' \ J(1, colsof(`_1'), 0)
        mat `b' = `b'[2,1...]
        mat `V' = `b'' * `b'
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `b' `V', obs(`N') `esample'

    eret local labels `"`macval(labels)'"'
    eret local byvar "`by'"
    eret local vars "`vars'"
    eret local stats "`stats'"
    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local subcmd "tabstat"
    eret local cmd "estpost"

    local nmat: list sizeof cnames
    forv j=`nmat'(-1)1 {
        local cname: word `j' of `cnames'
        eret matrix `cname' = `_`j''
    }

    cap mata mata drop `gtabstat'
    cap mata mata drop `glabname'
    cap mata mata drop `glabstat'
    cap mata mata drop `glabvar'
    cap mata mata drop `glabmat'
end

* 99.
* copy of erepost.ado, version 1.0.1, Ben Jann, 30jul2007
* 14jan2009: noV option added => repost e(b) and remove e(V) if not specified
prog erepost, eclass
    version 8.2
    syntax [anything(equalok)] [, NOV cmd(str) noEsample Esample2(varname) REName ///
        Obs(passthru) Dof(passthru) PROPerties(passthru) * ]
    if "`esample'"!="" & "`esample2'"!="" {
        di as err "only one allowed of noesample and esample()"
        exit 198
    }
// parse [b = b] [V = V]
    if `"`anything'"'!="" {
        tokenize `"`anything'"', parse(" =")
        if `"`7'"'!="" error 198
        if `"`1'"'=="b" {
            if `"`2'"'=="=" & `"`3'"'!="" {
                local b `"`3'"'
                confirm matrix `b'
            }
            else error 198
            if `"`4'"'=="V" {
                if `"`5'"'=="=" & `"`6'"'!="" {
                    local v `"`6'"'
                    confirm matrix `b'
                }
                else error 198
            }
            else if `"`4'"'!="" error 198
        }
        else if `"`1'"'=="V" {
            if `"`4'"'!="" error 198
            if `"`2'"'=="=" & `"`3'"'!="" {
                local v `"`3'"'
                confirm matrix `v'
            }
            else error 198
        }
        else error 198
    }
//backup existing e()'s
    if "`esample2'"!="" {
        local sample "`esample2'"
    }
    else if "`esample'"=="" {
        tempvar sample
        gen byte `sample' = e(sample)
    }
    local emacros: e(macros)
    if `"`properties'"'!="" {
        local emacros: subinstr local emacros "properties" "", word
    }
    foreach emacro of local emacros {
        local e_`emacro' `"`e(`emacro')'"'
    }
    local escalars: e(scalars)
    if `"`obs'"'!="" {
        local escalars: subinstr local escalars "N" "", word
    }
    if `"`dof'"'!="" {
        local escalars: subinstr local escalars "df_r" "", word
    }
    foreach escalar of local escalars {
        tempname e_`escalar'
        scalar `e_`escalar'' = e(`escalar')
    }
    local ematrices: e(matrices)
    if "`v'"=="" & "`nov'"!="" {   // added 14jan2009
        local nov V
        local ematrices : list ematrices - nov
    }
    if "`b'"=="" & `:list posof "b" in ematrices' {
        tempname b
        mat `b' = e(b)
    }
    if "`v'"=="" & `:list posof "V" in ematrices' {
        tempname v
        mat `v' = e(V)
    }
    local bV "b V"
    local ematrices: list ematrices - bV
    foreach ematrix of local ematrices {
        tempname e_`ematrix'
        matrix `e_`ematrix'' = e(`ematrix')
    }
// rename
    if "`b'"!="" & "`v'"!="" & "`rename'"!="" {
        local eqnames: coleq `b', q
        local vnames: colnames `b'
        mat coleq `v' = `eqnames'
        mat coln `v' = `vnames'
        mat roweq `v' = `eqnames'
        mat rown `v' = `vnames'
    }
// post results
    if "`esample'"=="" {
        eret post `b' `v', esample(`sample') `obs' `dof' `properties' `options'
    }
    else {
        eret post `b' `v', `obs' `dof' `properties' `options'
    }
    foreach emacro of local emacros {
        eret local `emacro' `"`e_`emacro''"'
    }
    if `"`cmd'"'!="" {
        eret local cmd `"`cmd'"'
    }
    foreach escalar of local escalars {
        eret scalar `escalar' = scalar(`e_`escalar'')
    }
    foreach ematrix of local ematrices {
        eret matrix `ematrix' = `e_`ematrix''
    }
end
