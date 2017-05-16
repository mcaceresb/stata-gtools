*! version 0.1 14May2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -collapse- implementation using C for faster processing

capture program drop gcollapse
program gcollapse
    version 13
    syntax [anything(equalok)] /// main call; must parse manually
        [if] [in] ,            /// subset
    [                          ///
        by(varlist)            /// collapse by variabes
        cw                     /// case-wise non-missing
        fast                   /// do not preserve/restore
        Verbose                /// debugging
        smart                  /// use Stata's collapse if data is sorted
        unsorted               /// do not sort final output (current implementation of final
                               /// sort is super slow bc it uses Stata)
        unsafe                 /// planned
        nomissing              /// planned
    ]
    if ("`fast'" == "") preserve

    if ("`verbose'" == "") {
        local verbose = 0
        scalar __gtools_verbose = 0
    }
    else {
        local verbose = 1
        scalar __gtools_verbose = 1
    }

    * Collapse to summary stats
    * -------------------------

	if ("`by'" == "") {
		tempvar byvar
		gen byte `byvar' = 0
		local by `byvar'
	}
    else {
        qui ds `by'
        local by `r(varlist)'
    }

    * If data already sorted, no need to make a fuzz
    * ----------------------------------------------

	local smart = ("`smart'" != "") & ("`anything'" != "") & ("`by'" != "")
    if ( `smart' ) {
        local sortedby: sortedby
        local stata = 1
        if (`: list by == sortedby') {
            if (`verbose') di as text "data already sorted; calling -collapse-"
        }
        else if (`:list by === sortedby') {
            if (`verbose') di as text "data sorted in similar order (`sortedby'); calling -collapse-"

        }
        else local stata = 0

        if (`stata') {
            collapse `anything' `if' `in' , by(`by') `fast' `cw'
            exit
        }
    }

    * Parse anything
    * --------------

	if ("`anything'" == "") {
        di as err "invalid syntax"
        exit 198
	}
	else {
		ParseList `anything'
	}

    local gtools_targets    `__gtools_targets'
    local gtools_vars       `__gtools_vars'
    local gtools_stats      `__gtools_stats'
	local gtools_uniq_vars  `__gtools_uniq_vars'
	local gtools_uniq_stats `__gtools_uniq_stats'

    local stats sum     ///
                mean    ///
                sd      ///
                max     ///
                min     ///
                count   ///
                median  ///
                iqr     ///
                percent ///
                first   ///
                last    ///
                firstnm ///
                lastnm

    local quantiles : list gtools_uniq_stats - stats
	foreach quantile of local quantiles {
        local quantbad = !regexm("`quantile'", "^p[0-9][0-9]?(\.[0-9]+)?$")
		if (`quantbad' | ("`quantile'" == "p0")) {
			di as error "Invalid stat: (`quantile')"
			error 110
		}
	}

	local intersection: list gtools_targets & by
	if ("`intersection'" != "") {
		di as error "targets in collapse are also in by(): `intersection'"
		error 110
	}

    * Call plugin
    * -----------

	if  ( ("`if'`in'" != "") | ("`cw'" != "") ) {
		marksample touse, strok novarlist
		if ("`cw'" != "") {
			markout `touse' `by' `gtools_uniq_vars', strok
		}
		keep if `touse'
    }

    ParseByTypes `by'

    * slow, but saves mem
    keep `by' `gtools_uniq_vars'

    * Unfortunately, this is necessary for C
    qui foreach var of local gtools_targets {
        gettoken sourcevar __gtools_vars: __gtools_vars
        gettoken collstat  __gtools_stats: __gtools_stats
        cap confirm variable `var'
        if regexm("`collstat'", "first|last|min|max") local targettype: type `sourcevar'
        else local targettype double
        di "type for `var' is `targettype'"
        if ( _rc ) mata: st_addvar("`targettype'", "`var'", 1)
        else recast `targettype' `var'
    }

    * This is not, but I need to figure out how to handle strings in C
    * efficiently; will improve on a future release.
    local bystr_orig  ""
    local bystr       ""
    qui foreach byvar of varlist `by' {
        local bytype: type `byvar'
        if regexm("`bytype'", "str([1-9][0-9]*|L)") {
            tempvar `byvar'
            mata: st_addvar("`bytype'", "``byvar''", 1)
            local bystr `bystr' ``byvar''
            local bystr_orig `bystr_orig' `byvar'
        }
    }

    * Some info for C
    scalar __gtools_l_targets    = length("`gtools_targets'")
    scalar __gtools_l_vars       = length("`gtools_vars'")
    scalar __gtools_l_stats      = length("`gtools_stats'")
	scalar __gtools_l_uniq_vars  = length("`gtools_uniq_vars'")
	scalar __gtools_l_uniq_stats = length("`gtools_uniq_stats'")

    scalar __gtools_k_targets    = `:list sizeof gtools_targets'
    scalar __gtools_k_vars       = `:list sizeof gtools_vars'
    scalar __gtools_k_stats      = `:list sizeof gtools_stats'
	scalar __gtools_k_uniq_vars  = `:list sizeof gtools_uniq_vars'
	scalar __gtools_k_uniq_stats = `:list sizeof gtools_uniq_stats'

    * Position of input to each target variable
    cap matrix drop __gtools_outpos
    foreach var of local gtools_vars {
        matrix __gtools_outpos = nullmat(__gtools_outpos), (`:list posof `"`var'"' in gtools_uniq_vars' - 1)
    }

    * Position of string variables
    cap matrix drop __gtools_strpos
    foreach var of local bystr_orig {
        matrix __gtools_strpos = nullmat(__gtools_strpos), `:list posof `"`var'"' in by'
    }

    cap matrix drop __gtools_numpos
    local bynum `:list by - bystr_orig'
    foreach var of local bynum {
        matrix __gtools_numpos = nullmat(__gtools_numpos), `:list posof `"`var'"' in by'
    }

    * Time just the plugin
    {
        cap timer off 99
        cap timer clear 99
        timer on 99
    }

    * J will contain how many obs to keep; nstr contains # of string grouping vars
    scalar __gtools_J    = 1
    scalar __gtools_nstr = `:list sizeof bystr'
    plugin call gtools `by' `gtools_uniq_vars' `gtools_targets' `bystr'

    { 
        timer off 99
        qui timer list
        if ("`verbose'" != "") di "The plugin executed in `:di trim("`:di %21.4gc r(t99)'")' seconds"
        timer off 99
        timer clear 99
    }

    * Keep only one obs per group; keep only relevant vars
    qui {
        keep in 1 / `:di scalar(__gtools_J)'
        keep `by' `gtools_targets'

        * This is really slow; implement in C
        if ("`unsorted'" == "") sort `by'
    }

	if ("`fast'" == "") restore, not
end

* This mostly is taken from Sergio Correia's fcollapse.ado
* --------------------------------------------------------

capture program drop ParseList
program define ParseList
	syntax [anything(equalok)]
	local stat mean

    * Trim spaces
    while strpos("`0'", "  ") {
        local 0: subinstr local 0 "  " " "
    }
    local 0 = trim("`0'")

	while (trim("`0'") != "") {
		GetStat stat 0 : `0'
		GetTarget target 0 : `0'
		gettoken vars 0 : 0
		unab vars : `vars'
		foreach var of local vars {
			if ("`target'" == "") local target `var'

            local full_vars    `full_vars'    `var'    
            local full_targets `full_targets' `target' 
            local full_stats   `full_stats'   `stat'   

			local target
		}
	}

	* Check that targets don't repeat
	local dups : list dups targets
	if ("`dups'" != "") {
		di as error "repeated targets in collapse: `dups'"
		error 110
	}

	c_local __gtools_targets    `full_targets'
    c_local __gtools_stats      `full_stats'
    c_local __gtools_vars       `full_vars'
	c_local __gtools_uniq_stats : list uniq full_stats
	c_local __gtools_uniq_vars  : list uniq full_vars
end

capture program drop GetStat
program define GetStat
	_on_colon_parse `0'
	local before `s(before)'
	gettoken lhs rhs : before
	local rest `s(after)'

	gettoken stat rest : rest , match(parens)
	if ("`parens'" != "") {
		c_local `lhs' `stat'
		c_local `rhs' `rest'
	}
end

capture program drop GetTarget
program define GetTarget
	_on_colon_parse `0'
	local before `s(before)'
	gettoken lhs rhs : before
	local rest `s(after)'

	local rest : subinstr local rest "=" "= ", all
	gettoken target rest : rest, parse("= ")
	gettoken eqsign rest : rest
	if ("`eqsign'" == "=") {
		c_local `lhs' `target'
		c_local `rhs' `rest'
	}
end

* Set up plugin call
* ------------------

capture program drop ParseByTypes
program ParseByTypes
    syntax varlist
    cap matrix drop __gtools_byk
    cap matrix drop __gtools_bymin
    cap matrix drop __gtools_bymax

    * See help data_types
    foreach byvar of varlist `varlist' {
        local bytype: type `byvar'
        if inlist("`bytype'", "byte", "int", "long") {
            qui sum `byvar'

            matrix __gtools_byk   = nullmat(__gtools_byk), -1
            matrix __gtools_bymin = nullmat(__gtools_bymin), `r(min)'
            matrix __gtools_bymax = nullmat(__gtools_bymax), `r(max)'
        }
        else {
            matrix __gtools_bymin = J(1, `:list sizeof varlist', 0)
            matrix __gtools_bymax = J(1, `:list sizeof varlist', 0)

            if regexm("`bytype'", "str([1-9][0-9]*|L)") {
                if (regexs(1) == "L") {
                    tempvar strlen
                    gen `strlen' = length(`byvar')
                    qui sum `strlen'
                    matrix __gtools_byk = nullmat(__gtools_byk), `r(max)'
                }
                else {
                    matrix __gtools_byk = nullmat(__gtools_byk), `:di regexs(1)'
                }
            }
            else if inlist("`bytype'", "float", "double") {
                matrix __gtools_byk = nullmat(__gtools_byk), 0
            }
            else {
                di as err "variable `byvar' has unknown type '`bytype''"
            }
        }
    }
end
