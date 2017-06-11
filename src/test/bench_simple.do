do bench_gcollapse.do
do ../ado/gcollapse.ado
do ../ado/gegen.ado

set rmsg on
local stats sum
local stats mean count min max sum
local anything x1 x2 x3 x4 x5 x6 x7 x8 x9

local collapse ""
foreach stat of local stats {
    local collapse `collapse' (`stat')
    foreach var of local anything {
        local collapse `collapse' `stat'_`var' = `var'
    }
}

* bench_sim, n(100000000) nj(15000000) nvars(9)
* save ~caceres/Downloads/TMP100M, replace
* local by groupstr
* bench_sim, n(30000000) nj(4500000) nvars(9)
* preserve
*     gcollapse `collapse', by(`by') v b
* restore, preserve
*     gcollapse `collapse', by(`by') v b debug_read_method(1) debug_collapse_method(1)
* restore, preserve
*     gcollapse `collapse', by(`by') debug_force_single debug_read_method(1) v b
* restore, preserve
*     gcollapse `collapse', by(`by') debug_force_single debug_read_method(2) v b
* restore
