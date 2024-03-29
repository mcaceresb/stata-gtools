* Checks in greshape
* ------------------
*
* 1. Unique j
* 2. Unique Xi
* 3. Missing j values
* 4. preserve, restore
* 5. Unique i
* 6. unsorted

capture program drop checks_greshape
program checks_greshape
    qui checks_inner_greshape_errors
    qui checks_inner_greshape_errors nochecks

    qui checks_inner_greshape_long
    qui checks_inner_greshape_long nochecks
    qui checks_inner_greshape_long " " xi
    qui checks_inner_greshape_long nochecks xi

    qui checks_inner_greshape_wide
    qui checks_inner_greshape_wide nochecks
    qui checks_inner_greshape_wide " " xi
    qui checks_inner_greshape_wide nochecks xi

    * Random check: chars, labels, etc.
    * ---------------------------------

    sysuse auto, clear
    note price: Hello, there!
    note price: GENERAL KENOBI!!!
    note price: You are a bold one.
    char price[varname] #GiraffesAreFake
    char price[note17]  This should not be listed by notes

    note mpg: I don't like sand
    note mpg: It's coarse and rough and irritating and it gets everywhere
    note mpg: It used to bother me that Anakin commits genocide and Padme stays with him.
    note mpg: But I think it's just supposed to show how much she's drawn to the dark side.
    note mpg: I mean, she did leave Jar Jar in charge, and Jar Jar did give Palpatine emergency powers
    note mpg: #JarJarWasSupposedToBeASithLordButYallRuinedItWithYourBickering
    char mpg[varname] Thisis my fight song
    char mpg[note11]  My I'm all right song

    label define pr .a A .b B
    label define mp .a C .b D
    label values price pr
    label values mpg   mp
    replace price = .a if mod(_n, 2)
    replace mpg   = .b if _n > 50

    preserve
        greshape wide price mpg, i(make) j(foreign)
        desc price* mpg*
    restore, preserve
        greshape wide price mpg, i(make) j(foreign) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore, preserve
        greshape wide price mpg, i(make) j(foreign) labelf(#stubname#, #keylabel# == #keyvalue#)
        desc price* mpg*
    restore, preserve
        label drop origin
        greshape wide price mpg, i(make) j(foreign) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(fstr) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(fstr)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(fstr foreign)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(foreign fstr) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore

    preserve
        greshape wide price mpg, i(make) j(foreign)
        greshape long price mpg, i(make) j(foreign)

        greshape wide price mpg, i(make) j(foreign)
        gen long   price2 = _n    
        gen double price3 = 3.14
        note price2: When the night!
        note price3: Has coooome....
        greshape long price mpg, i(make) j(foreign)
    restore

    preserve
        greshape spread price, i(make) j(foreign) xi(drop)
        greshape gather _*, j(foreign) values(price)
    restore

    preserve
        greshape spread mpg, i(make) j(foreign) xi(drop)
        greshape gather _*,  j(foreign) values(mpg)
    restore

    preserve
        greshape spread price mpg,   i(make) j(foreign) xi(drop)
        greshape gather price* mpg*, j(foreign) values(price_mpg)
    restore

    gen long   price2 = _n    
    gen double price3 = 3.14
    note price2: When the night!
    note price3: Has coooome....

    preserve
        greshape spread price, i(make) j(foreign) xi(drop)
        greshape gather _*, j(foreign) values(price)
    restore

    preserve
        greshape spread mpg, i(make) j(foreign) xi(drop)
        greshape gather _*,  j(foreign) values(mpg)
    restore
                                                              
    preserve
        greshape spread price mpg,   i(make) j(foreign) xi(drop)
        greshape gather price* mpg*, j(foreign) values(price_mpg)
    restore

    * Check dropmiss
    * --------------

    clear
    set obs 10
    gen i = _n
    gen x1 = 1
    gen x2 = 2
    gen z1 = "a"
    gen z2 = "bb"
    preserve
        greshape gather x*, values(x) key(var) dropmiss
    restore, preserve
        greshape long x, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long x, by(i) key(var) dropmiss
    restore, preserve
        greshape gather z*, values(z) key(var) dropmiss
    restore, preserve
        greshape long z, by(i) key(var) dropmiss nochecks
    restore
        greshape long z, by(i) key(var) dropmiss

    clear
    set obs 10
    gen i = _n
    gen x1 = 1
    gen x2 = 2
    gen x3 = .
    gen z1 = "a"
    gen z2 = "bb"
    gen z3 = ""
    preserve
        greshape gather x*, values(x) key(var) dropmiss
    restore, preserve
        greshape long x, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long x, by(i) key(var) dropmiss
    restore, preserve
        greshape gather z*, values(z) key(var) dropmiss
    restore, preserve
        greshape long z, by(i) key(var) dropmiss nochecks
    restore
        greshape long z, by(i) key(var) dropmiss

    clear
    set obs 10
    gen i = _n
    gen x1 = 1
    gen x2 = 2
    gen x3 = 3
    gen x4 = .
    gen x5 = 5
    replace x1 = . in 1
    replace x2 = . in 1
    replace x3 = . in 1
    replace x5 = . in 1
    replace x1 = . in 2
    replace x2 = . in 3
    replace x3 = . in 4
    replace x5 = . in 5
    replace x1 = . in 6
    replace x2 = . in 7
    replace x3 = . in 8
    replace x5 = . in 9

    gen z1 = "a"
    gen z2 = "bb"
    gen z3 = "ccc"
    gen z4 = ""
    gen z5 = "eeeee"
    replace z1 = "" in 1
    replace z2 = "" in 1
    replace z3 = "" in 1
    replace z5 = "" in 1
    replace z1 = "" in 2
    replace z2 = "" in 3
    replace z3 = "" in 4
    replace z5 = "" in 5
    replace z1 = "" in 6
    replace z2 = "" in 7
    replace z3 = "" in 8
    replace z5 = "" in 9

    preserve
        greshape gather x*, values(x) key(var) dropmiss
    restore, preserve
        greshape long x, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long x, by(i) key(var) dropmiss
    restore, preserve
        greshape gather z*, values(z) key(var) dropmiss
    restore, preserve
        greshape long z, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long z, by(i) key(var) dropmiss
    restore, preserve
        greshape long x z, by(i) key(var) dropmiss
    restore, preserve
        greshape long x z, by(i) key(var) nochecks dropmiss
    restore, preserve
        greshape long x z, by(i) key(var) nochecks
    restore
        greshape long x z, by(i) key(var)

    exit 0
end

capture program drop compare_greshape
program compare_greshape
    local n 500
    qui gen_data, n(`n')
    qui expand 100
    qui `noisily' random_draws, random(2) double
    gen long   ix_num = _n
    gen str    ix_str = "str" + string(_n)
    gen double ix_dbl = _pi + _n
    cap drop strL*
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di _n(1) "{hline 80}" _n(1) "compare_greshape, N = `N', J = `J' `options'" _n(1) "{hline 80}" _n(1)

    rename double? dbl?
    rename int?    num?

    compare_fail_greshape versus_greshape dbl random,      j(_j) i(ix_num num1)
    compare_fail_greshape versus_greshape dbl random,      j(_j) i(ix_num num1 num2)
    compare_fail_greshape versus_greshape dbl random str_, j(_j) i(ix_num num1 num2 num3) string

    compare_fail_greshape versus_greshape num random,      j(_j) i(ix_dbl dbl1)
    compare_fail_greshape versus_greshape num random str_, j(_j) i(ix_dbl dbl1 dbl2 dbl3) string

    compare_fail_greshape versus_greshape dbl num random, j(_j) i(ix_str str_32)
    compare_fail_greshape versus_greshape dbl num random, j(_j) i(ix_str str_32 str_12 str_4) string

    compare_fail_greshape versus_greshape random, j(_j) i(ix_str str_32 num3 dbl3) string
    compare_fail_greshape versus_greshape random, j(_j) i(ix_num num1 dbl2 dbl3)   string

    disp
end

capture program drop compare_fail_greshape
program compare_fail_greshape
    gettoken cmd 0: 0
    syntax [anything], [tol(real 1e-6) *]
    cap `cmd' `0'
    if ( _rc ) {
        di "    compare_greshape (failed): `anything', `options'"
        exit _rc
    }
    else {
        di "    compare_greshape (passed): greshape wide/long gave identical data (via cf); `anything', `options'"
    }
end

***********************************************************************
*                               Errors                                *
***********************************************************************

capture program drop checks_inner_greshape_errors
program checks_inner_greshape_errors

    foreach v in v1 v2 {
        clear
        set obs 5
        gen i1 = _n
        gen i2 = -_n
        gen i3 = "why?" + string(mod(_n, 3))
        gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
        expand 3
        if "`v'" == "v1" bys i1: gen j = "@#" + string(_n) + "|"
        else bys i1: gen j = _n + _N
        gen w = "|" + string(_n / 3) + "/"
        gen x = _N - _n
        gen y = _n / 2
        gen r = runiform()
        sort r
        drop r

        preserve
            greshape wide x y w, i(i1) j(j)
            assert _rc == 0
        restore, preserve
            cap greshape wide x, i(i1) j(j)
            assert _rc == 9
        restore, preserve
            if "`v'" == "v1" replace j = "2" if i1 == 1
            else replace j = 2 if i1 == 1
            cap greshape wide x y, i(i1) j(j)
            assert _rc == 9
        restore, preserve
            rename (i3 i4) (a3 a4)
            cap greshape long a, i(i1 i2) j(_j)
            assert _rc == 9
        restore, preserve
            cap greshape long i, i(i1 i2 j) j(_j)
            assert _rc == 198
        restore, preserve
            cap greshape long a, i(i1 i? j) j(_j)
            assert _rc == 111
        restore, preserve
            rename (i3 i4) (a3 a4)
            cap greshape long a, i(i1 i? j) j(_j)
            assert _rc == 0
        restore

        label var i3 "hey-o i3"
        label var i4 "bye-a i4"
        preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop)
            l in 1/10
        restore, preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop) uselabels
            l in 1/10
        restore, preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop) uselabels(i3)
            l in 1/10
        restore, preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop) uselabels(i3, exclude)
            l in 1/10
        restore
    }

    clear
    set obs 5
    gen bykey      = _n
    gen st1ub      = _n
    gen st2ub      = -_n
    gen foo3bar    = "foobar" + string(mod(_n, 3))
    gen foo4bar    = "foobar" + string(-_n) + "thisIsLongRight?"
    gen ali9ce5bob = "ali9cebob" + string(mod(_n, 3))
    gen ali9ce6bob = "ali9cebob" + string(-_n) + "thisIsLongRight?"
    gen w = "|" + string(_n / 3) + "/"
    gen x = _N - _n
    gen y = _n / 2
    gen r = runiform()
    sort r
    drop r

    preserve
        greshape long st(.+)ub (foo|alice)([0-9]+)(bar|bob)/2, by(bykey) j(j) match(regex)
        greshape wide st@ub foobar ali9ce*bob, by(bykey) j(j)
        greshape long st(.+)ub (foo|ali9ce)([0-9]+)(bar|bob)/2, by(bykey) j(j) match(regex)
    restore, preserve
        if ( `c(stata_version)' >= 14 ) {
            greshape long (?<=st).+(?=ub) (?<=(foo|ali\d{0,5}ce))(\d+)(?=(bar|bob)), by(bykey) j(j) match(ustrregex)
            greshape wide stub foo@bar ali9ce@bob, by(bykey) j(j)
        }
    restore
end

***********************************************************************
*                             Basic Tests                             *
***********************************************************************

capture program drop checks_inner_greshape_wide
program checks_inner_greshape_wide
    args opts extras

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsWideRight?"
    gen ca = "constant | " + string(_n) + " | group "
    gen cb = int(20 * runiform())
    expand 3
    bys i?: gen j1 = mod(_n, 6)
    bys i?: gen j2 = "waffle" + string(mod(_n, 6))
    gen str10  x  = "some"
    replace    x  = "whenever" in 4/ 9
    replace    x  = "wherever" in 9/l
    gen str20  p  = "another long one" + string(mod(_n, 4))
    replace    p  = "this b"   in 3 / 7
    replace    p  = "this c"   in 11/l
    gen float  z  = _n
    replace    z  = runiform() in 4 / 8
    replace    z  = runiform() in 12/l
    gen double w  = _n * 3.14
    replace    w  = rnormal()  in 7/l
    gen int    y  = _n
    replace    y  = int(10 * runiform()) in 3/l

    if ( `"`extras'"' != "" ) local xi ca cb
    else drop ca cb

disp as err "    set 1 `xi'"
    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 j1 z `xi'
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 z `xi'
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 w z `xi'
        greshape wide w z, i(i1) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j1 x `xi'
        greshape wide x, i(i1) j(j1) string `opts'
        l
    restore, preserve
        keep i1 j1 x p `xi'
        greshape wide x p, i(i1) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j1 x z `xi'
        greshape wide x z, i(i1) j(j1) string `opts'
        l
    restore, preserve
        drop i2-i4 j2
        greshape wide p w x y z, i(i1) j(j1) string `opts'
        l
    restore

disp as err "    set 2 `xi'"
    preserve
        * 1.1 num xij
        keep i1 j2 z `xi'
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 z `xi'
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 w z `xi'
        greshape wide w z, i(i1) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j2 x `xi'
        greshape wide x, i(i1) j(j2) string `opts'
        l
    restore, preserve
        keep i1 j2 x p `xi'
        greshape wide x p, i(i1) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j2 x z `xi'
        greshape wide x z, i(i1) j(j2) string `opts'
        l
    restore, preserve
        drop i2-i4 j1 `xi'
        greshape wide p w x y z, i(i1) j(j2) string `opts'
        l
    restore

disp as err "    set 3 `xi'"
    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i1 i2 j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i3 i4 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 4 `xi'"
    preserve
        * 1.1 num xij
        keep i1 i2 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i1 i2 j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i3 i4 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

disp as err "    set 5 `xi'"
    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 j1 z `xi'
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 z `xi'
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 w z `xi'
        greshape wide w z, i(i4) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j1 x `xi'
        greshape wide x, i(i4) j(j1) string `opts'
        l
    restore, preserve
        keep i4 j1 x p `xi'
        greshape wide x p, i(i4) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j1 x z `xi'
        greshape wide x z, i(i4) j(j1) string `opts'
        l
    restore, preserve
        drop i1-i3 j2
        greshape wide p w x y z, i(i4) j(j1) string `opts'
        l
    restore

disp as err "    set 6 `xi'"
    preserve
        * 1.1 num xij
        keep i4 j2 z `xi'
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 z `xi'
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 w z `xi'
        greshape wide w z, i(i4) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j2 x `xi'
        greshape wide x, i(i4) j(j2) string `opts'
        l
    restore, preserve
        keep i4 j2 x p `xi'
        greshape wide x p, i(i4) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j2 x z `xi'
        greshape wide x z, i(i4) j(j2) string `opts'
        l
    restore, preserve
        drop i1-i3 j1
        greshape wide p w x y z, i(i4) j(j2) string `opts'
        l
    restore

disp as err "    set 7 `xi'"
    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i3 i4 j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i1 i2 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 8 `xi'"
    preserve
        * 1.1 num xij
        keep i3 i4 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i3 i4 j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i1 i2 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

disp as err "    set 9 `xi'"
    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.1 str xij
        keep i? j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i? j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 10 `xi'"
    preserve
        * 1.1 num xij
        keep i? j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i? j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i? j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore
end

capture program drop checks_inner_greshape_long
program checks_inner_greshape_long
    args opts extras

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
    gen ca = "constant | " + string(_n) + " | group "
    gen cb = int(20 * runiform())
    gen str5   xa  = "some"
    gen str8   xb  = "whenever"
    gen str10  xd  = "wherever"
    gen str20  pa  = "another long one" + string(mod(_n, 4))
    gen str8   pb  = "this b"
    gen str10  pd  = "this c"
    gen long   z1  = _n
    gen float  z2  = runiform()
    gen float  zd  = runiform()
    gen float  w1  = _n * 3.14
    gen double w5  = rnormal()
    gen int    y2  = _n
    gen float  y7  = int(10 * runiform())

    if ( `"`extras'"' != "" ) local xi ca cb
    else drop ca cb

disp as err "    set 1 `xi'"
    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 z1 z2 `xi'
        greshape long z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 z1 z2 `xi'
        greshape long z, i(i1) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i1 w* z* `xi'
        greshape long w z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 w* z* `xi'
        greshape long w z, i(i1) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i1 x* `xi'
        greshape long x, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* `xi'
        greshape long x, i(i1) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i1 x* p* `xi'
        greshape long x p, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* p* `xi'
        greshape long x p, i(i1) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 x* z* `xi'
        greshape long x z, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* z* `xi'
        greshape long x z, i(i1) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i2-i4
        greshape long p w x y z, i(i1) j(j) string `opts'
        l
    restore, preserve
        drop i2-i4
        greshape long p w x y z, i(i1) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 2 `xi'"
    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i1 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i1 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i3 i4
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i3 i4
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 3 `xi'"
    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i1 i2 i3
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2 i3
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 4 `xi'"
    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i3 i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i3 i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i1 i2
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 5 `xi'"
    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i? i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i? i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i? i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i? i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_greshape
program bench_greshape
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2) double
    qui hashsort random1
    gen long   ix_num = _n
    gen str    ix_str = "str" + string(_n)
    gen double ix_dbl = _pi + _n
    cap drop strL*

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs reshape, obs = `N', J = `J' (in seconds)"
    di as txt " reshape | greshape | ratio (c/g) | varlist"
    di as txt " ------- | -------- | ----------- | -------"

    rename double? dbl?
    rename int?    num?

    versus_greshape dbl random,      j(_j) i(ix_num num1)
    versus_greshape dbl random,      j(_j) i(ix_num num1 num2)
    versus_greshape dbl random str_, j(_j) i(ix_num num1 num2 num3) string

    versus_greshape num random,      j(_j) i(ix_dbl dbl1)
    versus_greshape num random str_, j(_j) i(ix_dbl dbl1 dbl2 dbl3) string

    versus_greshape dbl num random, j(_j) i(ix_str str_32)
    versus_greshape dbl num random, j(_j) i(ix_str str_32 str_12 str_4) string

    di _n(1) "{hline 80}" _n(1) "bench_greshape, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_greshape
program versus_greshape, rclass
    syntax [anything], [i(str) j(str) *]

    preserve
        timer clear
        timer on 42
        qui reshape long `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_long = r(t42)
        tempfile a
        qui save `"`a'"'

        timer clear
        timer on 42
        qui reshape wide `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_wide = r(t42)
        tempfile b
        qui save `"`b'"'
    restore

    preserve
        timer clear
        timer on 43
        qui greshape long `anything', i(`i') j(`j') `options' check(2)
        timer off 43
        qui timer list
        local time_glong = r(t43)
        cf * using `"`a'"'

        timer clear
        timer on 43
        qui greshape wide `anything', i(`i') j(`j') `options' check(2)
        timer off 43
        qui timer list
        local time_gwide = r(t43)
        cf * using `"`b'"'
    restore

    local rs = `time_long'  / `time_glong'
    di as txt " `:di %7.3g `time_long'' | `:di %8.3g `time_glong'' | `:di %11.4g `rs'' | long `anything', i(`i')"
    local rs = `time_wide'  / `time_gwide'
    di as txt " `:di %7.3g `time_wide'' | `:di %8.3g `time_gwide'' | `:di %11.4g `rs'' | wide `anything', i(`i')"
end

***********************************************************************
*                               Testing                               *
***********************************************************************
