*! version 0.1.0 16May2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -collapse- implementation using C for faster processing

* TODO: If the number of observations is < 2^31 - 1, then count can be
* long instead of double. // 2017-05-16 07:28 EDT

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
        Benchmark              /// print benchmark info
        smart                  /// use Stata's collapse if data is sorted
        unsorted               /// do not sort final output (current implementation of final
                               /// sort is super slow bc it uses Stata)
        merge                  /// planned: merge back to original data
        unsafe                 /// planned: unsafe C execution
        nomissing              /// planned: data has no missing values
    ]
    if ("`c(os)'" != "Unix") di as err "Not available for `c(os)`, only Unix."

    if ("`merge'"     != "") di as err "Option -merge- not yet available (planned for next release)."
    if ("`unsafe'"    != "") di as err "Option -unsafe- not yet available (planned for next release)."
    if ("`nomissing'" != "") di as err "Option -nomissing- not yet available (planned for next release)."

    * Time the entire function execution
    {
        cap timer off 98
        cap timer clear 98
        timer on 98
    }

    * Time program setup
    {
        cap timer off 97
        cap timer clear 97
        timer on 97
    }

    if ("`fast'" == "") preserve


    // Verbose and benchmark printing
    // ------------------------------

    if ("`verbose'" == "") {
        local verbose = 0
        scalar __gtools_verbose = 0
    }
    else {
        local verbose = 1
        scalar __gtools_verbose = 1
    }

    if ("`benchmark'" == "") {
        local benchmark = 0
        scalar __gtools_benchmark = 0
    }
    else {
        local benchmark = 1
        scalar __gtools_benchmark = 1
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

    * Locals to be read by C
    local gtools_targets    `__gtools_targets'
    local gtools_vars       `__gtools_vars'
    local gtools_stats      `__gtools_stats'
	local gtools_uniq_vars  `__gtools_uniq_vars'
	local gtools_uniq_stats `__gtools_uniq_stats'

    * Available Stats
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

    * Parse quantiles
    local quantiles : list gtools_uniq_stats - stats
	foreach quantile of local quantiles {
        local quantbad = !regexm("`quantile'", "^p[0-9][0-9]?(\.[0-9]+)?$")
		if (`quantbad' | ("`quantile'" == "p0")) {
			di as error "Invalid stat: (`quantile')"
			error 110
		}
	}

    * Can't collapse grouping variables
	local intersection: list gtools_targets & by
	if ("`intersection'" != "") {
		di as error "targets in collapse are also in by(): `intersection'"
		error 110
	}

    * Call plugin
    * -----------

    * Subset if requested
	if  ( ("`if'`in'" != "") | ("`cw'" != "") ) {
		marksample touse, strok novarlist
		if ("`cw'" != "") {
			markout `touse' `by' `gtools_uniq_vars', strok
		}
		keep if `touse'
    }

    * Parse type of each by variable
    ParseByTypes `by'

    * Be smart about creating new variable columns
    local   gtools_vars      = subinstr(" `gtools_vars' ",        " ", "  ", .)
    local   gtools_uniq_vars = subinstr(" `gtools_uniq_vars' ",   " ", "  ", .)
    local __gtools_vars      = subinstr(" `__gtools_vars' ",      " ", "  ", .)
    local __gtools_uniq_vars = subinstr(" `__gtools_uniq_vars' ", " ", "  ", .)
    local K = `:list sizeof gtools_targets'
    forvalues k = 1 / `K' {
        local k_target: word `k' of `gtools_targets'
        local k_var:    word `k' of `gtools_vars'
        if ( `:list k_var in __gtools_uniq_vars' ) {
            local __gtools_uniq_vars: list __gtools_uniq_vars - k_var
            if ( !`:list k_var in __gtools_targets' ) {
                local   gtools_vars      = trim(subinstr(" `gtools_vars' ",        " `k_var' ", " `k_target' ", .))
                local   gtools_uniq_vars = trim(subinstr(" `gtools_uniq_vars' ",   " `k_var' ", " `k_target' ", .))
                local __gtools_vars      = trim(subinstr(" `__gtools_vars' ",      " `k_var' ", " `k_target' ", .))
                local __gtools_uniq_vars = trim(subinstr(" `__gtools_uniq_vars' ", " `k_var' ", " `k_target' ", .))
                rename `k_var' `k_target'
            }
        }
    }
    local   gtools_vars      = trim(subinstr(" `gtools_vars' ",        "  ", " ", .))
    local   gtools_uniq_vars = trim(subinstr(" `gtools_uniq_vars' ",   "  ", " ", .))
    local __gtools_vars      = trim(subinstr(" `__gtools_vars' ",      "  ", " ", .))
    local __gtools_uniq_vars = trim(subinstr(" `__gtools_uniq_vars' ", "  ", " ", .))

    * slow, but saves mem
    * keep `by' `gtools_uniq_vars'
    mata: st_keepvar((`:di subinstr(`""`by' `gtools_uniq_vars'""', " ", `"", ""', .)'))

    * Unfortunately, this is necessary for C
    local dropme ""
    qui foreach var of local gtools_targets {
        gettoken sourcevar __gtools_vars: __gtools_vars
        gettoken collstat  __gtools_stats: __gtools_stats
        cap confirm variable `var'
        if regexm("`collstat'", "first|last|min|max") local targettype: type `sourcevar'
        else local targettype double
        di "type for `var' is `targettype'"
        if ( _rc ) mata: st_addvar("`targettype'", "`var'", 1)
        else {
            local already_float_double = inlist("`:type `var''", "float", "double")
            local already_same_type    = ("`targettype'" == "`:type `var''")
            if !( `already_float_double' | `already_same_type' ) {
                tempname dropvar
                rename `var' `dropvar'
                local drop `drop' `dropvar'
                mata: st_addvar("`targettype'", "`var'", 1)
                replace `var' = `dropvar'
                * gen `targettype' `var' = `dropvar'
                * recast `targettype' `var'
            }
        }
    }

    * if ("`dropme'" != "") drop `dropme'
    if ("`dropme'" != "") mata: st_keepvar((`:di subinstr(`""`dropme'""', " ", `"", ""', .)'))

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

    * If benchmark, output program setup time
    {
        timer off 97
        qui timer list
        if ( `benchmark' ) di "Program set up executed in `:di trim("`:di %21.4gc r(t97)'")' seconds"
        timer off 97
        timer clear 97
    }

    * Time just the plugin
    {
        cap timer off 99
        cap timer clear 99
        timer on 99
    }

    * J will contain how many obs to keep; nstr contains # of string grouping vars
    scalar __gtools_J    = `=_N'
    scalar __gtools_nstr = `:list sizeof bystr'
    plugin call gcollapse_plugin `by' `gtools_uniq_vars' `gtools_targets' `bystr'

    * If benchmark, output pugin time
    {
        timer off 99
        qui timer list
        if ( `benchmark' ) di "The plugin executed in `:di trim("`:di %21.4gc r(t99)'")' seconds"
        timer off 99
        timer clear 99
    }

    * Time program exit
    {
        cap timer off 97
        cap timer clear 97
        timer on 97
    }

    * Keep only one obs per group; keep only relevant vars
    qui {
        keep in 1 / `:di scalar(__gtools_J)'
        keep `by' `gtools_targets'

        * This is really slow; implement in C
        if ("`unsorted'" == "") sort `by'
    }

	if ("`fast'" == "") restore, not

    * If benchmark, output program ending time
    {
        timer off 97
        qui timer list
        if ( `benchmark' ) di "Program exit executed in `:di trim("`:di %21.4gc r(t97)'")' seconds"
        timer off 97
        timer clear 97
    }

    * If benchmark, output function time
    {
        timer off 98
        qui timer list
        if ( `benchmark' ) di "The program executed in `:di trim("`:di %21.4gc r(t98)'")' seconds"
        timer off 98
        timer clear 98
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

cap program drop gcollapse_plugin
if ("`c(os)'" == "Unix") program gcollapse_plugin, plugin using("gcollapse.plugin")

* Parsing is adapted from Sergio Correia's fcollapse.ado
* ------------------------------------------------------

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
