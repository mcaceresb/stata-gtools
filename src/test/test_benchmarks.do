* IDEAS!
* ======
*
* graph 1: best stata performance
*
*     - Increasing J ("log scale"; N = 10M; J = 10, 100, 1k, 10k, 100k, 1M (?))
*         - stata
*             - [X] Banalced panel
*             - [ ] Unbanalced panel
*         - gtools
*             - [X] Banalced panel
*             - [ ] Unbanalced panel
*     - Increasing N ("log scale"; J = 100; N = 100k, 1M, 10M, 100M (?))
*         - stata
*             - [X] Banalced panel
*             - [ ] Unbanalced panel
*         - gtools
*             - [X] Banalced panel
*             - [ ] Unbanalced panel
*
* graph 2: worse stata performance
*
*     ibid
*
* table by J
*
*                     | Balanced Panel | Unbalanced Panel |
*                     | -------------- | ---------------- |
*     | N     | J     | stata | gtools | stata  | gtools  | vars              |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | int               |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | int int           |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | double            |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | double double     |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | string            |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | string string     |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 10M   | 10    |       |        |        |         | int double string |
*     |       | 100   |       |        |        |         |                   |
*     |       | 1k    |       |        |        |         |                   |
*     |       | 10k   |       |        |        |         |                   |
*     |       | 100k  |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*
* table by N
*
*                     | Balanced Panel | Unbalanced Panel |
*                     | -------------- | ---------------- |
*     | N     | J     | stata | gtools | stata  | gtools  | vars              |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | int               |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | int int           |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | double            |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | double double     |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | string            |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | string string     |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |
*     | 100k  | 10    |       |        |        |         | int double string |
*     | 1M    |       |       |        |        |         |                   |
*     | 10M   |       |       |        |        |         |                   |
*     | ----- | ----- | ----- | ------ | ------ | ------- | ----------------- |

* TODO: take out the double J? Maybe too much...
* do /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/src/test/test_benchmarks.do

capture program drop bench_v2
program bench_v2
    cap mkdir bench_v2

    ssc install winsor2
    ssc install astile

    * -------
    * Regular
    * -------

    bench_v2_run bench_v2_gcollapse_simple
    mata: gtools_bench_v2_save("bench_v2/gcollapse_simple", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gcollapse_complex
    mata: gtools_bench_v2_save("bench_v2/gcollapse_complex", ("r(r1)", "r(r2)"))

    * TODO: bench_v2_run bench_v2_greshape,         smallj greshape
    * TODO: mata: gtools_bench_v2_save("bench_v2/gcollapse_reshape", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gcontract
    mata: gtools_bench_v2_save("bench_v2/gcontract", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gegen
    mata: gtools_bench_v2_save("bench_v2/gegen", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gisid
    mata: gtools_bench_v2_save("bench_v2/gisid", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gisid, ix(ix)
    mata: gtools_bench_v2_save("bench_v2/gisid_ix", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gunique
    mata: gtools_bench_v2_save("bench_v2/gunique", ("r(r1)", "r(r2)"))

    * TODO: bench_v2_run bench_v2_gduplicates
    * TODO: mata: gtools_bench_v2_save("bench_v2/gduplicates", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gduplicates,      drop
    mata: gtools_bench_v2_save("bench_v2/gduplicates_drop", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_hashsort,         sort
    mata: gtools_bench_v2_save("bench_v2/hashsort_sort", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_hashsort,         gsort
    mata: gtools_bench_v2_save("bench_v2/hashsort_gsort", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gquantiles,       smallj noby vars(rnorm_big_dbl) xtile
    mata: gtools_bench_v2_save("bench_v2/gquantiles_xtile", "r(r2)")

    bench_v2_run bench_v2_gquantiles,       smallj noby vars(rnorm_big_dbl) pctile
    mata: gtools_bench_v2_save("bench_v2/gquantiles_pctile", "r(r2)")

    bench_v2_run bench_v2_gstats_sum,       smallj noby vars(rnorm_big_dbl runif_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/gstats_sum", "r(r2)")

    bench_v2_run bench_v2_gstats_winsor,    smallj noby vars(rnorm_big_dbl runif_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/gstats_winsor", "r(r2)")

    bench_v2_run bench_v2_glevelsof,        smallj single
    mata: gtools_bench_v2_save("bench_v2/glevelsof", "r(r2)")

    bench_v2_run bench_v2_gstats_tab,       smallj single vars(rnorm_big_dbl runif_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/gstats_tab", "r(r2)")

    bench_v2_run bench_v2_gquantiles_by,    smallj vars(rnorm_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/gquantiles_by", "r(r2)")

    bench_v2_run bench_v2_gstats_winsor_by, smallj vars(rnorm_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/gstats_winsor_by", "r(r2)")

    * ------
    * Limits
    * ------

    bench_v2_run bench_v2_gcollapse_simple,  jmin(6) jmax(6) nmin(8) nmax(8) by(int1)
    mata: gtools_bench_v2_save("bench_v2/limits_gcollapse_simple", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gcollapse_complex, jmin(6) jmax(6) nmin(8) nmax(8) by(int1)
    mata: gtools_bench_v2_save("bench_v2/limits_gcollapse_complex", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gcontract,         jmin(6) jmax(6) nmin(8) nmax(8) by(int1)
    mata: gtools_bench_v2_save("bench_v2/limits_gcontract", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gegen,             jmin(6) jmax(6) nmin(8) nmax(8) by(int1)
    mata: gtools_bench_v2_save("bench_v2/limits_gegen", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gisid,             jmin(6) jmax(6) nmin(8) nmax(8) by(int1)
    mata: gtools_bench_v2_save("bench_v2/limits_gisid", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gisid,             jmin(6) jmax(6) nmin(8) nmax(8) by(int1) ix(ix)
    mata: gtools_bench_v2_save("bench_v2/limits_gisid_ix", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gunique,           jmin(6) jmax(6) nmin(8) nmax(8) by(int1)
    mata: gtools_bench_v2_save("bench_v2/limits_gunique", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gduplicates,       jmin(6) jmax(6) nmin(8) nmax(8) by(int1) drop
    mata: gtools_bench_v2_save("bench_v2/limits_gduplicates_drop", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_hashsort,          jmin(6) jmax(6) nmin(8) nmax(8) by(int1) sort
    mata: gtools_bench_v2_save("bench_v2/limits_hashsort_sort", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_hashsort,          jmin(6) jmax(6) nmin(8) nmax(8) by(int1) gsort
    mata: gtools_bench_v2_save("bench_v2/limits_hashsort_gsort", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gquantiles,        jmin(6) jmax(6) nmin(8) nmax(8) smallj noby vars(rnorm_big_dbl) xtile
    mata: gtools_bench_v2_save("bench_v2/limits_gquantiles_xtile", "r(r2)")

    bench_v2_run bench_v2_gquantiles,        jmin(6) jmax(6) nmin(8) nmax(8) smallj noby vars(rnorm_big_dbl) pctile
    mata: gtools_bench_v2_save("bench_v2/limits_gquantiles_pctile", "r(r2)")

    bench_v2_run bench_v2_gstats_sum,        jmin(6) jmax(6) nmin(8) nmax(8) smallj noby vars(rnorm_big_dbl runif_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/limits_gstats_sum", "r(r2)")

    bench_v2_run bench_v2_gstats_winsor,     jmin(6) jmax(6) nmin(8) nmax(8) smallj noby vars(rnorm_big_dbl runif_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/limits_gstats_winsor", "r(r2)")

    bench_v2_run bench_v2_glevelsof,         jmin(3) jmax(3) nmin(8) nmax(8) by(int1) single
    mata: gtools_bench_v2_save("bench_v2/limits_glevelsof", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gstats_tab,        jmin(3) jmax(3) nmin(8) nmax(8) by(int1) single vars(rnorm_big_dbl runif_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/limits_gstats_tab", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gquantiles_by,     jmin(3) jmax(3) nmin(8) nmax(8) by(int1) vars(rnorm_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/limits_gquantiles_by", ("r(r1)", "r(r2)"))

    bench_v2_run bench_v2_gstats_winsor_by,  jmin(3) jmax(3) nmin(8) nmax(8) by(int1) vars(rnorm_big_dbl)
    mata: gtools_bench_v2_save("bench_v2/limits_gstats_winsor_by", ("r(r1)", "r(r2)"))
end

***********************************************************************
*                          Bench Programs!!                           *
***********************************************************************

capture program drop bench_v2_gstats_winsor
program bench_v2_gstats_winsor, rclass
    syntax, [vars(str) *]

    timer clear
    timer on 42
    qui winsor2 `vars', s(_w)
    timer off 42
    qui timer list
    local time_winsor = r(t42)
    cap drop *_w

    timer clear
    timer on 43
    qui gstats winsor `vars', s(_g) `options'
    timer off 43
    qui timer list
    local time_gwinsor = r(t43)
    cap drop *_g

    local rs = `time_winsor'  / `time_gwinsor'
    tempname bench
    matrix `bench' = (`time_winsor', `time_gwinsor', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_winsor'' | `:di %7.3g `time_gwinsor'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gstats_sum
program bench_v2_gstats_sum, rclass
    syntax, [vars(str) *]

    timer clear
    timer on 42
    qui sum `vars', detail
    timer off 42
    qui timer list
    local time_sum = r(t42)

    timer clear
    timer on 43
    qui gstats sum `vars', detail `options'
    timer off 43
    qui timer list
    local time_gsum = r(t43)

    local rs = `time_sum'  / `time_gsum'
    tempname bench
    matrix `bench' = (`time_sum', `time_gsum', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_sum'' | `:di %7.3g `time_gsum'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gstats_tab
program bench_v2_gstats_tab, rclass
    syntax varlist, [vars(str) *]

    timer clear
    timer on 42
    qui tabstat `vars', by(`varlist')
    timer off 42
    qui timer list
    local time_tab = r(t42)

    timer clear
    timer on 43
    qui gstats tab `vars', by(`varlist') `options'
    timer off 43
    qui timer list
    local time_gtab = r(t43)

    local rs = `time_tab'  / `time_gtab'
    tempname bench
    matrix `bench' = (`time_tab', `time_gtab', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_tab'' | `:di %7.3g `time_gtab'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gquantiles
program bench_v2_gquantiles, rclass
    syntax, [xtile pctile vars(str) *]
    tempvar p_var
    tempvar g_var

    timer clear
    timer on 42
    qui `xtile' `pctile' `p_var' = `vars', nq(10)
    timer off 42
    qui timer list
    local time_quantiles = r(t42)

    timer clear
    timer on 43
    qui gquantiles `g_var' = `vars', nq(10) `xtile' `pctile' `options'
    timer off 43
    qui timer list
    local time_gquantiles = r(t43)

    local rs = `time_quantiles'  / `time_gquantiles'
    tempname bench
    matrix `bench' = (`time_quantiles', `time_gquantiles', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_quantiles'' | `:di %7.3g `time_gquantiles'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gquantiles_by
program bench_v2_gquantiles_by, rclass
    syntax varlist, [vars(str) *]
    tempvar p_var
    tempvar g_var

    timer clear
    timer on 42
    qui astile `p_var' = `vars', by(`varlist')
    timer off 42
    qui timer list
    local time_quantiles = r(t42)

    timer clear
    timer on 43
    qui gquantiles `g_var' = `vars', xtile by(`varlist') `options'
    timer off 43
    qui timer list
    local time_gquantiles = r(t43)

    local rs = `time_quantiles'  / `time_gquantiles'
    tempname bench
    matrix `bench' = (`time_quantiles', `time_gquantiles', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_quantiles'' | `:di %7.3g `time_gquantiles'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gstats_winsor_by
program bench_v2_gstats_winsor_by, rclass
    syntax varlist, [vars(str) *]

    timer clear
    timer on 42
    qui winsor2 `vars', by(`varlist') s(_w)
    timer off 42
    qui timer list
    local time_winsor = r(t42)
    cap drop *_w

    timer clear
    timer on 43
    qui gstats winsor `vars', by(`varlist') s(_g) `options'
    timer off 43
    qui timer list
    local time_gwinsor = r(t43)
    cap drop *_g

    local rs = `time_winsor'  / `time_gwinsor'
    tempname bench
    matrix `bench' = (`time_winsor', `time_gwinsor', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_winsor'' | `:di %7.3g `time_gwinsor'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_hashsort
program bench_v2_hashsort, rclass
    syntax [anything], [sort gsort ix(varname) *]

    preserve
        timer clear
        timer on 42
        qui `sort' `gsort' `anything' `ix'
        timer off 42
        qui timer list
        local time_sort = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui hashsort `anything' `ix', `options'
        timer off 43
        qui timer list
        local time_gsort = r(t43)
    restore

    local rs = `time_sort'  / `time_gsort'
    tempname bench
    matrix `bench' = (`time_sort', `time_gsort', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_sort'' | `:di %7.3g `time_gsort'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gunique
program bench_v2_gunique, rclass
    syntax varlist, [*]

    timer clear
    timer on 42
    qui unique `varlist'
    timer off 42
    qui timer list
    local time_unique = r(t42)

    timer clear
    timer on 43
    qui gunique `varlist', `options'
    timer off 43
    qui timer list
    local time_gunique = r(t43)

    local rs = `time_unique'  / `time_gunique'
    tempname bench
    matrix `bench' = (`time_unique', `time_gunique', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_unique'' | `:di %7.3g `time_gunique'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_glevelsof
program bench_v2_glevelsof, rclass
    syntax varlist, [*]

    timer clear
    timer on 42
    qui levelsof `varlist', missing
    timer off 42
    qui timer list
    local time_levelsof = r(t42)

    timer clear
    timer on 43
    qui glevelsof `varlist', missing `options'
    timer off 43
    qui timer list
    local time_glevelsof = r(t43)

    local rs = `time_levelsof'  / `time_glevelsof'
    tempname bench
    matrix `bench' = (`time_levelsof', `time_glevelsof', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_levelsof'' | `:di %7.3g `time_glevelsof'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gegen
program bench_v2_gegen, rclass
    syntax varlist, [ix(varname) *]
    tempvar e_id
    tempvar g_id

    timer clear
    timer on 42
    qui egen `e_id' = group(`varlist' `ix'), missing
    timer off 42
    qui timer list
    local time_egen = r(t42)

    timer clear
    timer on 43
    qui gegen `g_id' = group(`varlist' `ix'), `options' missing
    timer off 43
    qui timer list
    local time_gegen = r(t43)

    local rs = `time_egen'  / `time_gegen'
    tempname bench
    matrix `bench' = (`time_egen', `time_gegen', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_egen'' | `:di %7.3g `time_gegen'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gduplicates
program bench_v2_gduplicates, rclass
    syntax varlist, [drop report tag *]

    if ( "`drop'" != "" ) {
        local force force
    }

    preserve
        timer clear
        timer on 42
        qui duplicates `tag' `drop' `report' `varlist', `force'
        timer off 42
        qui timer list
        local time_duplicates = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui gduplicates `tag' `drop' `report' `varlist', `force' gtools(`options')
        timer off 43
        qui timer list
        local time_gduplicates = r(t43)
    restore

    local rs = `time_duplicates'  / `time_gduplicates'
    tempname bench
    matrix `bench' = (`time_duplicates', `time_gduplicates', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_duplicates'' | `:di %7.3g `time_gduplicates'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gcontract
program bench_v2_gcontract, rclass
    syntax varlist, [*]

    preserve
        timer clear
        timer on 42
        qui contract `varlist'
        timer off 42
        qui timer list
        local time_contract = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui gcontract `varlist', `options'
        timer off 43
        qui timer list
        local time_gcontract = r(t43)
    restore

    local rs = `time_contract'  / `time_gcontract'
    tempname bench
    matrix `bench' = (`time_contract', `time_gcontract', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_contract'' | `:di %7.3g `time_gcontract'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gcollapse_simple
program bench_v2_gcollapse_simple
    syntax varlist, [*]
    bench_v2_gcollapse `varlist', stats(mean) vars(runif_small_flt rnorm_small_flt runif_big_flt rnorm_big_flt)
    c_local bench_disp: copy local bench_disp
    mata: st_matrix("r(bench)", st_matrix("r(bench)"))
end

capture program drop bench_v2_gcollapse_complex
program bench_v2_gcollapse_complex
    syntax varlist, [*]
    bench_v2_gcollapse `varlist', stats(median sd) vars(rnorm_big_dbl)
    c_local bench_disp: copy local bench_disp
    mata: st_matrix("r(bench)", st_matrix("r(bench)"))
end

capture program drop bench_v2_gcollapse
program bench_v2_gcollapse, rclass
    syntax varlist, [stats(str) vars(varlist) *]

    local collapse_str
    foreach stat of local stats {
        foreach var of varlist `vars' {
            local collapse_str `collapse_str' (`stat') `var'_`stat' = `var'
        }
    }

    preserve
        timer clear
        timer on 42
        qui collapse `collapse_str', by(`anything') fast
        timer off 42
        qui timer list
        local time_collapse = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui gcollapse `collapse_str', by(`anything') `options' fast
        timer off 43
        qui timer list
        local time_gcollapse = r(t43)
    restore

    local rs = `time_collapse'  / `time_gcollapse'
    tempname bench
    matrix `bench' = (`time_collapse', `time_gcollapse', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_collapse'' | `:di %7.3g `time_gcollapse'' | `:di %11.3g `rs'' |"'
end

capture program drop bench_v2_gisid
program bench_v2_gisid, rclass
    syntax varlist, [ix(varname) *]

    timer clear
    timer on 42
    cap isid `varlist' `ix', missok
    assert inlist(_rc, 0, 459)
    timer off 42
    qui timer list
    local time_isid = r(t42)

    timer clear
    timer on 43
    cap gisid `varlist' `ix', `options' missok
    assert inlist(_rc, 0, 459)
    timer off 43
    qui timer list
    local time_gisid = r(t43)

    local rs = `time_isid'  / `time_gisid'
    tempname bench
    matrix `bench' = (`time_isid', `time_gisid', `rs')
    return matrix bench = `bench'

    c_local bench_disp = `"| `:di %7.3g `time_isid'' | `:di %7.3g `time_gisid'' | `:di %11.3g `rs'' |"'
end

***********************************************************************
*                           Bench Wrappers!                           *
***********************************************************************

capture program drop bench_v2_run
program bench_v2_run, rclass
    syntax anything, [noby smallj single BYvar(str) jmin(int 1) jmax(int 5) nmin(int 5) nmax(int 7) gsort *]
    tokenize `anything'
    local program: copy local 1
    local test:    copy local 2

    if ( `"`program'"' == "" ) {
        disp as err "program requried"
        exit 198
    }

    cap matrix drop r1
    cap matrix drop r2
    cap matrix drop r3

    * local gvars int1
    if ( `"`single'"' == "" ) {
        if ( `"`gsort'"' != "" ) {
            local gvars -int1                ///
                      |  int1 -int2          ///
                      | -double1             ///
                      |  double1 -double2    ///
                      | -str_short           ///
                      |  str_short -str_long ///
                      |  int1 -double1 -str_mid
        }
        else {
            local gvars int1               ///
                      | int1 int2          ///
                      | double1            ///
                      | double1 double2    ///
                      | str_short          ///
                      | str_short str_long ///
                      | int1 double1 str_mid
        }
    }
    else {
        local gvars int1      ///
                  | int2      ///
                  | double1   ///
                  | double2   ///
                  | str_short ///
                  | str_long
    }

    if `"`byvar'"' != "" {
        local gvars: copy local byvar
    }

    if ( `"`smallj'"' == "" ) {
        disp ""
        disp "---------------------"
        disp "Increasing J, N = 10M"
        disp "---------------------"
        disp ""

        local id = 0
        forvalues i = `jmin' / `jmax' {
            if ( `"`test'"' == "" ) qui bench_v2_gen `:disp %21.0f 1e`i'' `:disp %21.0f 1e7'
            local _gvars: copy local gvars
            while ( trim(`"`_gvars'"') != "" ) {
                gettoken vars _gvars: _gvars, p(|)
                gettoken pipe _gvars: _gvars, p(|)
                `program' `vars', `options' `gsort'
                disp `"`:disp %9.0f `++id'', N = `:disp %21.0fc 1e7', `:disp %21.0fc 1e`i'' `bench_disp' `vars'"'
                matrix r1 = nullmat(r1) \ (1, `id', `:disp %21.0f 1e7', `:disp %21.0f 1e`i'', r(bench))
            }
        }
    }
    else {
        matrix r1 = J(1, 7, .)
    }

    disp ""
    disp "--------------------"
    disp "Increasing N, J = 10"
    disp "--------------------"
    disp ""

    local id = 0
    forvalues i = `nmin' / `nmax' {
        if ( `"`test'"' == "" ) qui bench_v2_gen 10 `:disp %21.0f 1e`i''
        local _gvars: copy local gvars
        if ( `"`by'"' == "" ) {
            while ( trim(`"`_gvars'"') != "" ) {
                gettoken vars _gvars: _gvars, p(|)
                gettoken pipe _gvars: _gvars, p(|)
                `program' `vars', `options' `gsort'
                disp `"`:disp %9.0f `++id'', N = `:disp %21.0fc 1e`i'', `:disp %21.0fc 10' `bench_disp' `vars'"'
                matrix r2 = nullmat(r2) \ (2, `id', `:disp %21.0f 1e`i'', 10, r(bench))
            }
        }
        else {
            `program', `options' `gsort'
            disp `"`:disp %9.0f `++id'', N = `:disp %21.0fc 1e`i'', `:disp %21.0fc 10' `bench_disp' `vars'"'
            matrix r2 = nullmat(r2) \ (2, `id', `:disp %21.0f 1e`i'', 10, r(bench))
        }
    }

    * disp ""
    * disp "--------------------------"
    * disp "Increasing N, J = 10% of N"
    * disp "--------------------------"
    * disp ""
    *
    * local id = 0
    * forvalues i = 5 / 7 {
    *     if ( `"`test'"' == "" ) qui bench_v2_gen `:disp %21.0f 1e`=`i'-1'' `:disp %21.0f 1e`i''
    *     local _gvars: copy local gvars
    *     while ( trim(`"`_gvars'"') != "" ) {
    *         gettoken vars _gvars: _gvars, p(|)
    *         gettoken pipe _gvars: _gvars, p(|)
    *         `program' `vars', `options' `gsort'
    *         disp `"`:disp %9.0f `++id'', N = `:disp %21.0fc 1e`i'', `:disp %21.0fc 1e`=`i'-1'', `bench_disp' `vars'"'
    *         matrix r3 = nullmat(r3) \ (2, `id', `:disp %21.0f 1e`i'', `:disp %21.0f 1e`=`i'-1'', r(bench))
    *     }
    * }

    return matrix r1 = r1
    return matrix r2 = r2
end

capture program drop bench_v2_gen
program bench_v2_gen
    args j n njvar

    clear
    set obs `j'

    * -----------------
    * Generate strings!
    * -----------------

    ralpha str_long,  l(5)
    ralpha str_mid,   l(3)
    ralpha str_short, l(1)

    * if ( `c(stata_version)' >= 14 ) {
    *     local chars char(40 + mod(_n, 50))
    *     forvalues i = 1 / 50 {
    *         local chars `chars' + char(40 + mod(_n + `i', 50))
    *     }
    *
    *     forvalues i = 35 / 115 {
    *         disp `i', char(`i')
    *     }
    *
    *     gen strL strL1 = str_long  + `chars'
    *     gen strL strL2 = str_mid   + `chars'
    *     gen strL strL3 = str_short + `chars'
    *     forvalues i = 1 / 42 {
    *         replace strL1 = strL1 + `chars'
    *         replace strL2 = strL2 + `chars'
    *         replace strL3 = strL3 + `chars'
    *     }
    * }

    local chars9
    forvalues i = 1 / 9 {
        local chars9 `chars9' + char(40 + mod(_n + `i', 50))
    }
    local chars27
    forvalues i = 10 / 36 {
        local chars27 `chars27' + char(40 + mod(_n + `i', 50))
    }
    gen str4 str_4   = str_mid  + str_short
    gen str12 str_12 = str_mid  `chars9'
    gen str32 str_32 = str_long `chars27'

    * ---------------------------
    * Note blanks are not missing
    * ---------------------------

    replace str_32 = "            " in 1 / 10
    replace str_12 = "   "          in 1 / 10
    replace str_4  = " "            in 1 / 10

    replace str_32 = "            " if mod(_n, 21) == 0
    replace str_12 = "   "          if mod(_n, 34) == 0
    replace str_4  = " "            if mod(_n, 55) == 0

    * if ( `c(stata_version)' >= 14 ) {
    *     replace strL1 = "            " in 1 / 10
    *     replace strL2 = "   "          in 1 / 10
    *     replace strL3 = " "            in 1 / 10
    *
    *     replace strL1 = "            " if mod(_n, 21) == 0
    *     replace strL2 = "   "          if mod(_n, 34) == 0
    *     replace strL3 = " "            if mod(_n, 55) == 0
    * }

    replace str_32 = "|singleton|" in `j'
    replace str_12 = "|singleton|" in `j'
    replace str_4  = "|singleton|" in `j'

    * --------------------
    * Integers and doubles
    * --------------------

    gen long   int1  = floor(uniform() * 1000)
    gen double int2  = floor(rnormal())
    gen long   int3  = floor(rnormal() * 5 + 10)

    gen double double1 = uniform() * 1000
    gen double double2 = rnormal()
    gen double double3 = rnormal() * 5 + 10

    replace int1    = 99999  in `j'
    replace double1 = 9999.9 in `j'

    * -------------------
    * Things to summarize
    * -------------------

    if ( `"`njvar'"' != "" ) {
        local nj = ceil(`n' / `j')
        gen expand = (`nj' - `njvar') + runiform() * (2 * `njvar')
        expand expand
    }
    else if ( `n' > `j' ) {
        local expand = ceil(`n' / `j')
        expand `expand'
    }

    gen float  runif_small_flt = runiform()
    gen double runif_small_dbl = runiform()
    gen float  rnorm_small_flt = rnormal()
    gen double rnorm_small_dbl = rnormal()
    gen float  runif_big_flt   = 10 * runiform()
    gen double runif_big_dbl   = 10 * runiform()
    gen float  rnorm_big_flt   = 10 * rnormal()
    gen double rnorm_big_dbl   = 10 * rnormal()

    gen long ix = _n
    * sort runif_big_dbl
end

cap mata: mata drop gtools_bench_v2_save()
mata:
void function gtools_bench_v2_save(string scalar outf, string matrix outmats)
{
    real scalar i, j
    real scalar fh
    real matrix R

    R = J(0, 7, .)
    for (i = 1; i <= length(outmats); i++) {
        R = R \ st_matrix(outmats[i])
    }

    fh = fopen(outf, "rw")
    fwrite(fh, sprintf("%16s|%16s|%16s|%16s|%16s|%16s|%16s\n", "version", "id", "N", "J", "stata", "gtools", "ratio"))
    for (i = 1; i <= rows(R); i++) {
        for (j = 1; j <= cols(R); j++) {
            fwrite(fh, sprintf("%16.0g", R[i, j]))
            if ( j < cols(R) ) {
                fwrite(fh, "|")
            }
        }
        fwrite(fh, sprintf("\n"))
    }
    fclose(fh)
}
end

* replace int3 = .  in 1
* replace int3 = .a in 2
* replace int3 = .b in 3
* replace int3 = .c in 4
* replace int3 = .d in 5
* replace int3 = .e in 6
* replace int3 = .f in 7
* replace int3 = .g in 8
* replace int3 = .h in 9
* replace int3 = .i in 10
* replace int3 = .j in 11
* replace int3 = .k in 12
* replace int3 = .l in 13
* replace int3 = .m in 14
* replace int3 = .n in 15
* replace int3 = .o in 16
* replace int3 = .p in 17
* replace int3 = .q in 18
* replace int3 = .r in 19
* replace int3 = .s in 20
* replace int3 = .t in 21
* replace int3 = .u in 22
* replace int3 = .v in 23
* replace int3 = .w in 24
* replace int3 = .x in 25
* replace int3 = .y in 26
* replace int3 = .z in 27
*
* replace double3 = .  in 1
* replace double3 = .a in 2
* replace double3 = .b in 3
* replace double3 = .c in 4
* replace double3 = .d in 5
* replace double3 = .e in 6
* replace double3 = .f in 7
* replace double3 = .g in 8
* replace double3 = .h in 9
* replace double3 = .i in 10
* replace double3 = .j in 11
* replace double3 = .k in 12
* replace double3 = .l in 13
* replace double3 = .m in 14
* replace double3 = .n in 15
* replace double3 = .o in 16
* replace double3 = .p in 17
* replace double3 = .q in 18
* replace double3 = .r in 19
* replace double3 = .s in 20
* replace double3 = .t in 21
* replace double3 = .u in 22
* replace double3 = .v in 23
* replace double3 = .w in 24
* replace double3 = .x in 25
* replace double3 = .y in 26
* replace double3 = .z in 27
