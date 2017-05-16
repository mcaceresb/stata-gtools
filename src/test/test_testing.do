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
        gen rsort = runiform()
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

***********************************************************************
*                              fcollapse                              *
***********************************************************************

* sim, n(100000)    nj(10000)    string
* sim, n(1000000)   nj(100000)   string
* sim, n(5000000)   nj(500000)   string njsub(4)
* sim, n(10000000)  nj(10000)    string njsub(4)
* sim, n(30000000)  nj(3000000)  string sortg
* sim, n(100000000) nj(10000000) string sortg

* sim, n(10000000)  nj(1000000)  string njsub(4)
* sim, n(1000000)   nj(500000)   string njsub(4)
* sim, n(1000000)   nj(100000)   string njsub(4)
* sim, n(1000000)   nj(50000)    string njsub(4)
* sim, n(1000000)   nj(10000)    string njsub(4)
* sim, n(1000000)   nj(5000)     string njsub(4)

cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/build

local stats sum mean sd max min count percent first last firstnm lastnm
local collapse_nopct ""
foreach stat of local stats {
    local collapse_nopct `collapse_nopct' (`stat') `stat' = rsort
}

local stats sum mean sd max min count percent first last firstnm lastnm median iqr
local collapse_str ""
foreach stat of local stats {
    local collapse_str `collapse_str' (`stat') `stat' = rsort
}
local collapse_str `collapse_str' (p23) p23 = rsort
local collapse_str `collapse_str' (p77) p77 = rsort

set rmsg on
preserve
    gcollapse `collapse_str', by(groupstr) verbose
restore, preserve
    gcollapse `collapse_nopct', by(groupstr) verbose
restore
set rmsg off

set rmsg on
preserve
    fcollapse `collapse_str', by(groupstr) verbose
restore, preserve
    fcollapse `collapse_nopct', by(groupstr) verbose
restore
set rmsg off
