clear
set obs 10
gen x = "a"
gen z = 0
gen a = 1
gen b = 1
gen c = 1

gcontract color
gcontract color pink

preserve
    gcollapse x
restore, preserve
    gcollapse z, by(a)
restore, preserve
    gcollapse z, by(a b c)
restore, preserve
    gcollapse z, by(a b c zz)
restore, preserve
    gcollapse z, by(a-zz)
restore, preserve
    gcollapse z, by(a-zz) nods
restore, preserve
    gcollapse z, by(a-zz) ds
restore, preserve
    gcollapse z, by(a-c)
restore, preserve
    gcollapse z, by(a-c) nods
restore, preserve
    gcollapse z, by(a-c) ds
restore, preserve
    gcollapse z, by(a - c)
restore, preserve
    gcollapse z, by(a - c) nods
restore, preserve
    gcollapse z, by(a - c) ds
restore

preserve
    gcontract a
restore, preserve
    gcontract a b c
restore, preserve
    gcontract a b c zz
restore, preserve
    gcontract a-zz
restore, preserve
    gcontract a-zz nods
restore, preserve
    gcontract a-zz ds
restore, preserve
    gcontract a-c
restore, preserve
    gcontract a-c nods
restore, preserve
    gcontract a-c ds
restore, preserve
    gcontract a - c
restore, preserve
    gcontract a - c nods
restore, preserve
    gcontract a - c ds
restore

glevelsof a
glevelsof a b c
glevelsof a b c zz
glevelsof a-zz
glevelsof a-zz, nods
glevelsof a-zz, ds
glevelsof a-c
glevelsof a-c, nods
glevelsof a-c, ds
glevelsof a - c,
glevelsof a - c, nods
glevelsof a - c, ds

gtop a
gtop a b c
gtop a b c zz
gtop a-zz
gtop a-zz, nods
gtop a-zz, ds
gtop a-c
gtop a-c, nods
gtop a-c, ds
gtop a - c,
gtop a - c, nods
gtop a - c, ds
