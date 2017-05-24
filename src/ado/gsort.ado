*! version 0.1 23May2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! implementation of -sort- for sorting the results of gcollapse

capture program drop gsort
program define gsort
    version 13
    syntax varlist
    if ("`c(os)'" != "Unix") di as err "Not available for `c(os)`, only Unix."

    qui ds *
    local memvars `r(varlist)'
    local restvars: list varlist - memvars
    foreach var of varlist restvars {
        if regexm("`:type var'", "str") {
            di as err "-gsort- is only designed to sort -gcollapse- results; non-sorting variabes must be numeric."
            exit 198
        }
    }
    di as err "-gsort- is a planned feature for gcollapse-0.5.0"
    exit 198
    scalar __gtools_kvars_sort = `:list sizeof varlist'
    * TODO: Implement something like parse-bytype, but somewhat simpler
    * since you don't need the bijection stuff, etc. Just numeric or
    * string length.
    * gsort_plugin `varlist' `restvars'
end

cap program drop gsort_plugin
if ("`c(os)'" == "Unix") program gsort_plugin, plugin using("gsort.plugin")
