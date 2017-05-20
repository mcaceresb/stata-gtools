capture program drop sim
program sim, rclass
    syntax, [offset(str) n(int 100) nj(int 10) njsub(int 2) string float sortg replace groupmiss outmiss]
    qui {
        if ("`offset'" == "") local offset 0
        clear
        set obs `n'
        gen group  = ceil(`nj' *  _n / _N) + `offset'
        bys group: gen groupsub   = ceil(`njsub' *  _n / _N)
        bys group: gen groupfloat = ceil(`njsub' *  _n / _N) + 0.5
        gen rsort = runiform() - 0.5
        gen rnorm = rnormal()
        if ("`sortg'" == "")  sort rsort
        if ("`groupmiss'" != "") replace group = . if runiform() < 0.1
        if ("`outmiss'" != "") replace rsort = . if runiform() < 0.1
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
        gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    }
    sum rsort
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    compress
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

* !cd ..; ./build.py
* do gegen.ado
* cls
* cap drop z*
* bench_sim_ftools 100000 5
* gen long x = ceil(uniform() * 5000)

* bench_sim_ftools 100 3
* gen byte ifif = (runiform() > 0.5)
* gen long x = ceil(uniform() * 5)
* tostring x, gen(xstr)
* sort y1
* cap drop *_id
* cap drop *_tag
* gegen g_tag = tag(xstr)  if ifif, v
*  egen c_tag = tag(xstr)  if ifif
* assert g_tag == c_tag
* cap drop *_id
* cap drop *_tag
* gegen g_tag = tag(xstr)  if ifif in 10/87, v
*  egen c_tag = tag(xstr)  if ifif in 10/87
* assert g_tag == c_tag
* gegen g_id = group(xstr) if ifif in 10/87, v
* fegen f_id = group(xstr) if ifif in 10/87
*  egen c_id = group(xstr) if ifif in 10/87
* assert g_id == c_id      if ifif  in 10/87
* tab xstr g_id if ifif  in 10/87
* tab xstr c_id if ifif  in 10/87

* gegen z1 = mean(y1), by(x3)
* by  x3: gegen z2 = mean(y1)
* bys x3 (x1): gegen z3 = mean(y1)
* egen zz1 = mean(y1), by(x3)
* by  x3: egen zz2 = mean(y1)
* bys x3 (x1): egen zz3 = mean(y1)
* sum z*
* assert z1 == z1
* assert z2 == z2
* assert z3 == z3

* capture program drop checks_simplest_gegen
* program checks_simplest_gegen
*     syntax, [tol(real 1e-6) multi]
*     di _n(1) "{hline 80}" _n(1) "checks_simplest_gegen" _n(1) "{hline 80}" _n(1)
* 
*     * sim, n(500000) nj(8) njsub(4) string groupmiss outmiss
*     sim, n(50000) nj(8) njsub(4) string groupmiss outmiss
* 
*     local stats sum mean sd max min count percent first last firstnm lastnm median iqr
*     local egen_str ""
*     foreach stat of local stats {
*         local egen_str `egen_str' (`stat') `stat' = rnorm
*     }
*     local egen_str `egen_str' (p23) p23 = rnorm
*     local egen_str `egen_str' (p77) p77 = rnorm
* 
*     local i = 0
*     mytimer 9
*     preserve
*         mytimer 9 info
*         gegen `egen_str' (p2.5) p2_5 = rnorm, by(groupsub groupstr) verbose benchmark `multi'
*         mytimer 9 info "gegen 2 groups"
*         * l
*         tempfile f`i'
*         save `f`i''
*         local ++i
*     restore, preserve
*         mytimer 9 info
*         fegen `egen_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupsub group) verbose
*         mytimer 9 info "fegen 2 groups"
*         * l
*         tempfile f`i'
*         save `f`i''
*         local ++i
*     restore, preserve
*         mytimer 9 info
*         egen `egen_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupsub groupstr)
*         mytimer 9 info "egen 2 groups"
*         * l
*         tempfile f`i'
*         save `f`i''
*         local ++i
*     restore
* 
*     preserve
*         mytimer 9 info
*         gegen `egen_str' (p2.5) p2_5 = rnorm, by(groupstr) verbose benchmark `multi'
*         mytimer 9 info "gegen 1 group"
*         * l
*         tempfile f`i'
*         save `f`i''
*         local ++i
*     restore, preserve
*         mytimer 9 info
*         fegen `egen_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupstr) verbose
*         mytimer 9 info "fegen 1 group"
*         * l
*         tempfile f`i'
*         save `f`i''
*         local ++i
*     restore, preserve
*         mytimer 9 info
*         egen `egen_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupstr)
*         mytimer 9 info "egen 1 group"
*         * l
*         tempfile f`i'
*         save `f`i''
*         local ++i
*     restore
*     mytimer 9 off
* 
*     preserve
*     use `f2', clear
*         local bad_any = 0
*         local bad groupsub groupstr
*         foreach var in `stats' p23 p77 {
*             rename `var' c_`var'
*         }
*         merge 1:1 groupsub groupstr using `f0', assert(3)
*         foreach var in `stats' p23 p77 {
*             qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
*             if ( `r(N)' > 0 ) {
*                 gen byte bad_`var' = abs(`var' - c_`var') > `tol'
*                 local bad `bad' *`var'
*                 di "`var' has `:di r(N)' mismatches".
*                 local bad_any = 1
*             }
*         }
*         if ( `bad_any' ) {
*             order `bad'
*             l *count* `bad'
*         }
*         else {
*             di "gegen produced identical data to egen (tol = `tol')"
*         }
* 
*     restore, preserve
* 
*     use `f5', clear
*         local bad_any = 0
*         local bad groupstr
*         foreach var in `stats' p23 p77 {
*             rename `var' c_`var'
*         }
*         merge 1:1 groupstr using `f3', assert(3)
*         foreach var in `stats' p23 p77 {
*             qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
*             if ( `r(N)' > 0 ) {
*                 gen byte bad_`var' = abs(`var' - c_`var') > `tol'
*                 local bad `bad' *`var'
*                 di "`var' has `:di r(N)' mismatches".
*                 local bad_any = 1
*             }
*         }
*         if ( `bad_any' ) {
*             order `bad'
*             l *count* `bad'
*         }
*         else {
*             di "gegen produced identical data to egen (tol = `tol')"
*         }
*     restore
* 
*     di ""
*     di as txt "Passed! checks_simplest_gegen"
* end
* 
* capture program drop checks_byvars_gegen
* program checks_byvars_gegen
*     syntax, [multi]
*     di _n(1) "{hline 80}" _n(1) "checks_byvars_gegen" _n(1) "{hline 80}" _n(1)
* 
*     sim, n(1000) nj(250) string
*     set rmsg on
*     preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group groupsub) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong groupsub) verbose `multi'
*     restore, preserve
*         gegen (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr groupsub) verbose `multi'
*     restore
*     set rmsg off
* 
* 
*     di ""
*     di as txt "Passed! checks_byvars_gegen"
* end
* 
* capture program drop checks_options_gegen
* program checks_options_gegen
*     syntax, [multi]
*     di _n(1) "{hline 80}" _n(1) "checks_options_gegen" _n(1) "{hline 80}" _n(1)
* 
*     local stats mean count median iqr
*     local egen_str ""
*     foreach stat of local stats {
*         local egen_str `egen_str' (`stat') `stat' = rnorm `stat'2 = rnorm
*     }
* 
*     sim, n(200) nj(10) string outmiss
*     preserve
*         gegen `egen_str', by(groupstr) verbose benchmark `multi'
*         l
*     restore, preserve
*         gegen `egen_str', by(groupstr) verbose unsorted `multi'
*         l
*     restore, preserve
*         gegen `egen_str', by(groupstr) verbose benchmark cw `multi'
*         l
*     restore, preserve
*         gegen `egen_str', by(groupstr) double `multi'
*         l
*     restore, preserve
*         gegen `egen_str', by(groupstr) merge `multi'
*         l
*     restore
* 
*     sort groupstr groupsub
*     preserve
*         gegen `egen_str', by(groupstr groupsub) verbose benchmark `multi'
*         l in 1 / 5
*     restore, preserve
*         gegen `egen_str', by(groupstr groupsub) verbose benchmark smart `multi'
*         l in 1 / 5
*     restore, preserve
*         gegen `egen_str', by(groupsub groupstr) verbose benchmark smart `multi'
*         l in 1 / 5
*     restore, preserve
*         gegen `egen_str', by(groupstr) verbose benchmark `multi'
*         l in 1 / 5
*     restore, preserve
*         gegen `egen_str', by(groupstr) verbose benchmark smart `multi'
*         l in 1 / 5
*     restore, preserve
*         gegen `egen_str', by(groupsub) verbose benchmark smart `multi'
*         l
*     restore, preserve
*         gegen `egen_str', by(groupsub) verbose benchmark `multi'
*         l
*     restore
* 
*     di ""
*     di as txt "Passed! checks_options_gegen"
* end

* TODO: Edge cases (nothing in anything, no -by-, should mimic egen // 2017-05-16 08:03 EDT
