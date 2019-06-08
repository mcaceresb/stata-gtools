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
