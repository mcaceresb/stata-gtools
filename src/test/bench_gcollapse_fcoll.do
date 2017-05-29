capture program drop bench_switch_fcoll
program bench_switch_fcoll
    syntax anything, style(str) [*]
    if !inlist("`style'", "ftools", "gtools") {
        di as error "Don't know benchmark style '`style''; available: ftools, gtools"
        exit 198
    }

    local 0 `anything', `options'
    if ( "`style'" == "ftools" ) {
        syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7) *]
        if ("`stats'" == "") local stats sum
        local i = 0
        local N ""
        local L N
        local dstr J = 100
        di "Benchmarking `L' for `dstr'; by(`by')"
        di "    vars  = `anything'"
        di "    stats = `stats'"

        mata: print_matrix = J(1, 0, "")
        mata: sim_matrix   = J(1, 0, "")
        forvalues k = `kmin' / `kmax' {
            mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 2 * 10^`k'''"
            mata: sim_matrix   = sim_matrix,   "bench_sim_ftools `:di %21.0g 2 * 10^`k'' `kvars'"
            local N `N' `:di %21.0g 2 * 10^`k''
        }
    }
    else {
        * syntax anything, by(str) [margin(str) nj(int 10) pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6) *]
        syntax anything, by(str) [margin(str) nj(int 10) pct(str) stats(str) obsexp(int 6) kmin(int 4) kmax(int 7) nvars(int 2) *]
        if !inlist("`margin'", "N", "J") {
            di as error "Don't know margin '`margin''; available: N, J"
            exit 198
        }

        if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
        local stats `stats' `pct'
        local i = 0
        local N ""
        local L `margin'
        local jstr = trim("`:di %21.0gc `nj''")
        local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
        local dstr = cond("`L'" == "N", "J = `jstr'", "N = `nstr'")
        di "Benchmarking `L' for `dstr'; by(`by')"
        di "    vars  = `anything'"
        di "    stats = `stats'"

        mata: print_matrix = J(1, 0, "")
        mata: sim_matrix   = J(1, 0, "")
        forvalues k = `kmin' / `kmax' {
            if ( "`L'" == "N" ) {
                mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 2 * 10^`k'''"
                mata: sim_matrix   = sim_matrix, "bench_sim, n(`:di %21.0g 2 * 10^`k'') nj(`nj') njsub(2) nvars(`nvars')"
            }
            else {
                mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 10^`k'''"
                mata: sim_matrix   = sim_matrix, "bench_sim, n(`:di %21.0g 5 * 10^`obsexp'') nj(`:di %21.0g 10^`k'') njsub(2) nvars(`nvars')"
            }
            local J `J' `:di %21.0g 10^`k''
            local N `N' `:di %21.0g 2 * 10^`k''
        }
    }

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    forvalues k = 1 / `:di `kmax' - `kmin' + 1' {
        mata: st_local("sim",   sim_matrix[`k'])
        qui `sim'
        mata: printf(print_matrix[`k'])
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse-default ")
                qui gcollapse `collapse', by(`by') `options' fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') \n")
        restore
    }

    local i = 1
    di "Results varying `L' for `dstr'; by(`by')"
    di "|              `L' | gcollapse | fcollapse | ratio (f/g) |"
    di "| -------------- | --------- | --------- | ----------- |"
    foreach nn in ``L'' {
        local ii  = `i' + 1
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
    }
    timer clear
end
