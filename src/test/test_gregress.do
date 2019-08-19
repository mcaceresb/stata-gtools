capture program drop checks_gregress
program checks_gregress

    sysuse auto, clear
    egen headcode = group(headroom)
    gen byte ones = 1

    reg price rep78 mpg headcode
    greg price rep78 mpg headcode, v mata(g1)
    greg price rep78 mpg headcode, v mata(g2) rowmajor
    greg price rep78 mpg headcode, v mata(g3) colmajor
    mata: g1.b  \ g2.b  \ g3.b
    mata: g1.se \ g2.se \ g3.se

    reg price rep78 mpg headcode, r
    greg price rep78 mpg headcode, mata(g1) v r
    greg price rep78 mpg headcode, mata(g2) v r rowmajor
    greg price rep78 mpg headcode, mata(g3) v r colmajor
    mata: g1.b  \ g2.b  \ g3.b
    mata: g1.se \ g2.se \ g3.se

    gen fdbl = 0.5 - foreign
    reg price rep78 mpg headcode, cluster(fdbl)
    greg price rep78 mpg headcode, mata(g1) v cluster(fdbl) bench(3)
    greg price rep78 mpg headcode, mata(g2) v cluster(fdbl) rowmajor
    greg price rep78 mpg headcode, mata(g3) v cluster(fdbl) colmajor
    mata: g1.b  \ g2.b  \ g3.b
    mata: g1.se \ g2.se \ g3.se

    areg price rep78 mpg headcode, absorb(foreign)
    greg price rep78 mpg headcode, mata(g1) v absorb(foreign) bench(3)
    greg price rep78 mpg headcode, mata(g2) v absorb(foreign) colmajor
    mata: g1.b  \ g2.b
    mata: g1.se \ g2.se

    * {
    *     local varlist rep78 mpg headcode ones
    *     marksample touse
    *     mata: y = st_data(., "price", st_local("touse"))
    *     mata: X = st_data(., tokens("`varlist'"), st_local("touse"))
    *     mata: XX = X' * X
    *     mata: Xy = X' * y
    *     mata: b  = invsym(XX) * Xy
    *     mata: e  = y - X * b
    *     mata: D  = X' * diag(e:^2) * X
    *     mata: D
    *     mata: D * invsym(XX)
    *     mata: invsym(XX) * D * invsym(XX)
    *     mata: diagonal(invsym(XX) * D * invsym(XX))
    *     mata: XX
    *     mata: Xy
    *     mata: invsym(XX) * Xy
    * }

    by foreign: reg price rep78 mpg headcode
    greg price rep78 mpg headcode, mata(g1) v by(foreign)
    greg price rep78 mpg headcode, mata(g2) v by(foreign) colmajor
    greg price rep78 mpg headcode, mata(g3) v by(foreign) rowmajor
    mata: g1.b  \ g2.b  \ g3.b
    mata: g1.se \ g2.se \ g3.se

    by foreign: reg price rep78 mpg headcode, r
    greg price rep78 mpg headcode, mata(g1)  v by(foreign) r
    greg price rep78 mpg headcode, mata(g2)  v by(foreign) r colmajor
    greg price rep78 mpg headcode, mata(g3)  v by(foreign) r rowmajor
    mata: g1.b  \ g2.b  \ g3.b
    mata: g1.se \ g2.se \ g3.se

    by foreign: areg price rep78 mpg, absorb(headcode)
    greg price rep78 mpg, mata(g1)  v by(foreign) absorb(headcode)
    greg price rep78 mpg, mata(g2)  v by(foreign) absorb(headcode) colmajor
    mata: g1.b  \ g2.b
    mata: g1.se \ g2.se

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    clear
    set rmsg on
    set obs 10000
    gen e = rnormal() * 50
    gen g = ceil(runiform()*100)
    forvalues i = 1 / 4 {
        gen x`i' = rnormal() * `i' + `i'
    }
    gen byte ones = 1
    gen y = 5 - 4 * x1 + 3 * x2 - 2 * x3 + x4 + g + e

    reg y x1 x2 x3 x4
    areg y x1 x2 x3 x4, absorb(g)
    greg y x1 x2 x3 x4, absorb(g) mata(coefs)
    mata: (coefs.b  \ coefs.se)'
    greg y x1 x2 x3 x4, absorb(g) prefix(hdfe(_hdfe_)) mata(coefs)
    mata: (coefs.b  \ coefs.se)'
    greg y x1 x2 x3 x4, absorb(g) prefix(hdfe(_hdfe_)) replace
    greg y x1 x2 x3 x4, absorb(g) prefix(b(_b_))
    greg y x1 x2 x3 x4, absorb(g) prefix(se(_se_))
    greg y x1 x2 x3 x4, absorb(g) gen(b(_bx1 _bx2 _bx3 _bx4))
    greg y x1 x2 x3 x4, absorb(g) gen(hdfe(_hy _hx1 _hx2 _hx3 _hx4))
    greg y x1 x2 x3 x4, absorb(g) gen(se(_sex1 _sex2 _sex3 _sex4))
    assert (_hdfe_y == _hy)
    foreach var in x1 x2 x3 x4 {
        assert (_hdfe_`var' == _h`var')
        assert (_b_`var' == _b`var')
        assert (_se_`var' == _se`var')
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    clear
    set rmsg on
    set obs 10000000
    gen e = rnormal() * 20
    gen g = ceil(runiform()*100)
    forvalues i = 1 / 4 {
        gen x`i' = rnormal() * `i' + `i'
    }
    gen byte ones = 1
    gen y = 5 - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e

    reg  y x1 x2 x3 x4
    greg y x1 x2 x3 x4, bench(3) v colmajor
    greg y x1 x2 x3 x4, bench(3) v rowmajor

    reg  y x1 x2 x3 x4, r
    greg y x1 x2 x3 x4, r bench(3) v colmajor
    greg y x1 x2 x3 x4, r bench(3) v rowmajor

    reg  y x1 x2 x3 x4, cluster(g)
    greg y x1 x2 x3 x4, cluster(g) bench(3) v colmajor
    greg y x1 x2 x3 x4, cluster(g) bench(3) v rowmajor

    areg y x1 x2 x3 x4, absorb(g)
    greg y x1 x2 x3 x4, absorb(g) bench(3) v colmajor

    sort g

    reg y x1  x2 x3 x4, cluster(g)
    greg y x1 x2 x3 x4, cluster(g) bench(3) v colmajor
    greg y x1 x2 x3 x4, cluster(g) bench(3) v rowmajor

    areg    y x1 x2 x3 x4, absorb(g)
    reghdfe y x1 x2 x3 x4, absorb(g)
    greg    y x1 x2 x3 x4, absorb(g) bench(3) v colmajor

    {
        local varlist x1 x2 x3 x4 ones
        marksample touse
        mata: y = st_data(., "y", st_local("touse"))
        mata: X = st_data(., tokens("`varlist'"), st_local("touse"))
        mata: XX = X' * X
        mata: Xy = X' * y
        mata: invsym(XX) * Xy
    }
    * mata: XX
    * mata: det(XX)
    * mata: invsym(XX)
    * mata: XX * invsym(XX)

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    clear all
    set matsize 10000
    set maxvar 50000
    set rmsg on
    set obs 250
    gen g = ceil(runiform()*10)
    gen e = rnormal() * 5
    forvalues i = 1 / 4000 {
        gen x`i' = rnormal() * `i' + `i'
    }
    gen y = - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e

    * reg y x*
    greg y x*, bench(3) colmajor
    greg y x*, bench(3) rowmajor

    greg y x*, bench(3) colmajor by(g)
    greg y x*, bench(3) rowmajor by(g)

    greg y x*, bench(3) colmajor absorb(g)

    * super slow ):
    * greg y x*, bench(3) colmajor cluster(g)
    * greg y x*, bench(3) rowmajor cluster(g)

    {
        local varlist x*
        marksample touse
        mata: y = st_data(., "y", st_local("touse"))
        mata: X = st_data(., tokens("`varlist'"), st_local("touse"))
        mata: XX = X' * X
        mata: Xy = X' * y
        mata: _tmp_ = invsym(XX)
        * mata: I = _tmp_ * XX
        mata: b = _tmp_ * Xy
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    * Set up
    clear all
    set obs 10000000
    set seed 123

    * Generate a dataset
    gen g = ceil(runiform()*1000)
    gen x = runiform()
    gen y = g + g*x + rnormal()
    sort g
    tempfile t1
    save `t1'

    * Test with regressby
    use `t1', clear
    timer on 1
    regressby y x, by(g) nocov
    timer off 1
    list in 1

    * Test with regressby
    use `t1', clear
    timer on 2
    gregress y x, by(g)
    timer off 2

    * Test with regressby
    use `t1', clear
    timer on 3
    gregress y x, by(g)
    timer off 3

    * * Test with asreg
    * use `t1', clear
    * timer on 4
    * by g: asreg y x
    * timer off 4
    * list in 1

    timer list

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    clear
    local N 1000000
    local G 10000
    set rmsg on
    set obs `N'
    gen g1 = int(runiform() * `G')
    gen g2 = int(runiform() * `G')
    gen g3 = int(runiform() * `G')
    gen g4 = int(runiform() * `G')
    gen x1 = runiform()
    gen x2 = runiform()
    gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + 20 * rnormal()

    greg y x1 x2, absorb(g1 g2 g3) save(mata(greg))
    mata greg.b', greg.se'
    reghdfe y x1 x2, absorb(g1 g2 g3)

    greg y x1 x2, absorb(g1 g2 g3) save(mata(greg)) r
    mata greg.b', greg.se'
    reghdfe y x1 x2, absorb(g1 g2 g3) vce(robust)

    greg y x1 x2, absorb(g1 g2 g3) cluster(g4) save(mata(greg))
    mata greg.b', greg.se'
    reghdfe y x1 x2, absorb(g1 g2 g3) vce(cluster g4)

    * greg y x1 x2
    * greg y x1 x2, absorb(g1 g2 g3) by(g4)
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(mata(zz))
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(mata(zz) prefix(b(_b_) se(_se_)))
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(mata(zz) prefix(b(_b_) se(_se_))) replace
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(mata(zz) gen(b(b1 b2) se(se1 se2)))
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(mata(zz) gen(b(b1 b2) se(se1 se2))) replace
    *
    * cap drop _b_*
    * cap drop _se_*
    * cap drop b1 b2
    * cap drop se1 se2
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(prefix(b(_b_) se(_se_)))
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(prefix(b(_b_) se(_se_))) replace
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(gen(b(b1 b2) se(se1 se2)))
    * greg y x1 x2, absorb(g1 g2 g3) by(g4) save(gen(b(b1 b2) se(se1 se2))) replace

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    set rmsg on
    use "DT1.dta", clear
    tab v1, gen(_v)
    reg v3 v1 v2 id4 id5
    reg v3 _v2-_v5 v2 id4 id5
    gegen _id3 = group(id3)

    * reghdfe v3 v2 id4 id5 _v2-_v5, absorb(id6) tolerance(1e-6)
    * reghdfe v3 v2 id4 id5 _v2-_v5, absorb(id6 _id3) tolerance(1e-6)

    * reghdfe v3 v2 id4 id5 _v2-_v5, absorb(id6)     vce(cluster id6)
    * reghdfe v3 v2 id4 id5 _v2-_v5, absorb(id6 id1) vce(cluster id6)
    * * reghdfe v3 v2 id4 id5 _v2-_v5, absorb(id6 id3) vce(cluster id6)

    * simpleHDFE v3 v2 id4 id5 _v2-_v5, absorb(id6)
    * simpleHDFE v3 v2 id4 id5 _v2-_v5, absorb(id6 id3)
    * simpleHDFE v3 v2 id4 id5 _v2-_v5, absorb(id6 id1)
    *
    * greg v3 v2 id4 id5 _v2-_v5, absorb(id6)      bench(3)
    * greg v3 v2 id4 id5 _v2-_v5, absorb(id6 id1)  bench(3)
    * * greg v3 v2 id4 id5 _v2-_v5, absorb(id6 id3) bench(3)
    *
    * greg v3 v2 id4 id5 _v2-_v5, absorb(id6)      cluster(id6) bench(3)
    * mata (GtoolsRegress.b \ GtoolsRegress.se)'
    * greg v3 v2 id4 id5 _v2-_v5, absorb(id6 id1)   cluster(id6) bench(3)
    * mata (GtoolsRegress.b \ GtoolsRegress.se)'
    * * greg v3 v2 id4 id5 _v2-_v5, absorb(id6 id3)  cluster(id6) bench(3)
    * * mata (GtoolsRegress.b \ GtoolsRegress.se)'

    * DT1 <- DT[1:(nrow(DT)/2)]
    * DT1[, "iv1"] = as.numeric(DT1[, "v1"] == 1)
    * DT1[, "iv2"] = as.numeric(DT1[, "v1"] == 2)
    * DT1[, "iv3"] = as.numeric(DT1[, "v1"] == 3)
    * DT1[, "iv4"] = as.numeric(DT1[, "v1"] == 4)
    * DT1[, "iv5"] = as.numeric(DT1[, "v1"] == 5)
    * system.time(res1 <- felm(v3 ~ v1 + v2 + id4 + id5, DT1))
    * system.time(res2 <- felm(v3 ~ v2 + id4 + id5 + iv2 + iv3 + iv4 + iv5, DT1))
    * system.time(res3 <- felm(v3 ~ v2 + id4 + id5 + iv2 + iv3 + iv4 + iv5 | id6 | 0 | id6, DT1))
    * system.time(res4 <- felm(v3 ~ v2 + id4 + id5 + iv2 + iv3 + iv4 + iv5 | id6 + id3 | 0 | id6, DT1))
    * system.time(res5 <- felm(v3 ~ v2 + id4 + id5 + iv2 + iv3 + iv4 + iv5 | id6 + id1 | 0 | id6, DT1))
end

* capture program drop simpleHDFE
* program simpleHDFE
*     syntax varlist, absorb(varlist) [tol(real 1e-8)]
*     gettoken y x: varlist
*     tempvar diff
*
*     local dmx
*     foreach xvar of local x {
*         tempvar `xvar'1
*         tempvar `xvar'2
*         local dmx `dmx' ``xvar'1'
*     }
*
*     qui gen double `diff' = 0
*     foreach xvar of local x {
*         qui gen double ``xvar'1' = `xvar'
*         qui gen double ``xvar'2' = `xvar'
*     }
*
*     tempvar `y'1 `y'2
*     qui gen double ``y'1' = `y'
*     qui gen double ``y'2' = `y'
*     local dmy ``y'1'
*
*     foreach avar of local absorb {
*         gstats transform (demean) `dmy' `dmx', by(`avar') replace
*     }
*
*     local supnorm = 1
*     while ( `supnorm' > `tol' ) {
*         foreach avar of local absorb {
*             gstats transform (demean) `dmy' `dmx', by(`avar') replace
*             qui replace `diff' = abs(``y'2' - ``y'1')
*             qui replace ``y'2' = ``y'1'
*             foreach xvar of local x {
*                 qui replace `diff' = `diff' + abs(``xvar'2' - ``xvar'1')
*                 qui replace ``xvar'2' = ``xvar'1'
*             }
*             sum `diff', meanonly
*             local supnorm = `r(max)'
*             if ( `supnorm' < `tol' ) break
*             disp `supnorm'
*         }
*     }
*
*     reg `dmy' `dmx', noc
* end
