capture program drop sim
program sim, rclass
    syntax, [offset(str) n(int 100) nj(int 10) string float]
    qui {
        if ("`offset'" == "") local offset 0
        clear
        set obs `n'
        gen group = ceil(`nj' *  _n / _N) + `offset'
        gen rsort = runiform()
        sort rsort
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") tostring group, replace
    }
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/build
shell cd ..; make; cd -
cap program drop gtools
program gtools, plugin using("gtools.plugin")

capture program drop gcollapse
program gcollapse
    local outvars sum mean
    qui foreach var of local outvars {
        mata: st_addvar("double", "`var'", 1)
    }
    scalar __gtools_J = .
    plugin call gtools group rsort `outvars'
    qui {
        keep in 1 / `:di scalar(__gtools_J)'
        keep group `outvars'
    }
end

capture program drop dummy
program dummy
    args nj
    timer clear
    preserve
    timer on 98
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
    timer off 98
    qui timer list
        * l in 1/5
        * l in `:di `nj' - 5' / `nj'
    restore, preserve
    timer clear
    timer on 99
        qui gcollapse
    timer off 99
    qui timer list
        * l in 1/5
        * l in `:di `nj' - 5' / `nj'
    restore
    di "Results for N = " trim("`:di %21.0gc _N'") "; nj = " trim("`:di %21.0gc `nj''")
    di "    gtools = `:di trim("`:di %21.4gc r(t99)'")' seconds"
    di "    ftools = `:di trim("`:di %21.4gc r(t98)'")' seconds"
    di "    ratio  = `:di trim("`:di %21.4gc r(t98) / r(t99)'")'"
    timer clear
end

***********************************************************************
*                            Ingegers only                            *
***********************************************************************

* Number of groups
* ----------------

forvalues exp = 1 / 6 {
    sim, n(10000000) nj(`:di 10^`exp'')
    dummy `r(nj)'
}

forvalues exp = 1 / 6 {
    sim, n(10000000) nj(`:di 10^`exp'')
    dummy `r(nj)'
}

* Number of observations
* ----------------------

forvalues exp = 2 / 7 {
    sim, n(`:di 10^`exp'') nj(`:di 10^`:di `exp' - 1'')
    dummy `r(nj)'
}

* Offset
* ------

forvalues exp = 6 / 12 {
    di "`exp'"
    sim, n(1000000) nj(100000) offset(`:di 10^`exp'')
    dummy `r(nj)'
}

* Strings
* -------

forvalues exp = 2 / 7 {
    sim, n(`:di 10^`exp'') nj(`:di 10^`:di `exp' - 1'') string
    preserve
        timer clear
        timer on 98
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 98
        qui timer list
        local r98 = `r(t98)'
    restore
    sim, n(`:di 10^`exp'') nj(`:di 10^`:di `exp' - 1'')
    preserve
        timer clear
        timer on 99
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 99
        qui timer list
        local r99 = `r(t99)'
    restore
    timer clear
    di "Results for N = " trim("`:di %21.0gc 10^`exp''") "; nj = " trim("`:di %21.0gc 10^`:di `exp' - 1''")
    di "    string  = `:di trim("`:di %21.4gc `r98''")' seconds"
    di "    integer = `:di trim("`:di %21.4gc `r99''")' seconds"
    di "    ratio   = `:di trim("`:di %21.4gc `r98' / `r99''")'"
}

forvalues exp = 1 / 5 {
    sim, n(1000000) nj(`:di 10^`exp'') string
    preserve
        timer clear
        timer on 98
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 98
        qui timer list
        local r98 = `r(t98)'
    restore
    sim, n(1000000) nj(`:di 10^`exp'')
    preserve
        timer clear
        timer on 99
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 99
        qui timer list
        local r99 = `r(t99)'
    restore
    timer clear
    di "Results for N = " trim("`:di %21.0gc 10^`exp''") "; nj = " trim("`:di %21.0gc 10^`:di `exp' - 1''")
    di "    string  = `:di trim("`:di %21.4gc `r98''")' seconds"
    di "    integer = `:di trim("`:di %21.4gc `r99''")' seconds"
    di "    ratio   = `:di trim("`:di %21.4gc `r98' / `r99''")'"
}

* Floats
* ------

forvalues exp = 2 / 7 {
    sim, n(`:di 10^`exp'') nj(`:di 10^`:di `exp' - 1'') float
    preserve
        timer clear
        timer on 98
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 98
        qui timer list
        local r98 = `r(t98)'
    restore
    sim, n(`:di 10^`exp'') nj(`:di 10^`:di `exp' - 1'')
    preserve
        timer clear
        timer on 99
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 99
        qui timer list
        local r99 = `r(t99)'
    restore
    timer clear
    di "Results for N = " trim("`:di %21.0gc 10^`exp''") "; nj = " trim("`:di %21.0gc 10^`:di `exp' - 1''")
    di "    float   = `:di trim("`:di %21.4gc `r98''")' seconds"
    di "    integer = `:di trim("`:di %21.4gc `r99''")' seconds"
    di "    ratio   = `:di trim("`:di %21.4gc `r98' / `r99''")'"
}

forvalues exp = 1 / 5 {
    sim, n(1000000) nj(`:di 10^`exp'') float
    preserve
        timer clear
        timer on 98
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 98
        qui timer list
        local r98 = `r(t98)'
    restore
    sim, n(1000000) nj(`:di 10^`exp'')
    preserve
        timer clear
        timer on 99
        fcollapse (sum) sum = rsort (mean) mean = rsort, by(group) verbose
        timer off 99
        qui timer list
        local r99 = `r(t99)'
    restore
    timer clear
    di "Results for N = " trim("`:di %21.0gc 10^`exp''") "; nj = " trim("`:di %21.0gc 10^`:di `exp' - 1''")
    di "    float   = `:di trim("`:di %21.4gc `r98''")' seconds"
    di "    integer = `:di trim("`:di %21.4gc `r99''")' seconds"
    di "    ratio   = `:di trim("`:di %21.4gc `r98' / `r99''")'"
}

**
 * The idea is to preserve variable types whenever possible. So for
 *     max min first last firstnm lastnm
 *
 * There is no change in type.
 *     sum is long for byte/int/long and double for floats/doubles
 *     count is long for everything
 *     mean median percent iqr sd p[0-9]{1,2}(\.\d+)? are doubles
 *
 * In the case of median, iqr, and percentiles, in case of ties an
 * average is given, hence the possibility of doubles being required.
 *
 * Done
 * - Proof of concept code has been written and results in a 5-6x speed
 *   improvement over ftools
 *
 * Roadblocks
 * - Proof of concept uses an indexed group---that is, a group indexed 1
 *   through J, where J is the number of unique elements in the group.
 *   ftools supposedly uses hashes to group the data; not sure how to
 *   implement in C.
 * - Memory use is through the roof because C requires the target variable
 *   exist in Stata; not sure there is a way around this...
 *
 * Solutions
 * - Use SpookyHash, which is the newer implementation of Jenkin's
 *   one-at-a-time hash function implemented in mata as hash1. This
 *   should be a very fast hashing function and not add too much overhead
 *   to your program. So
 *   - Write ghash.c with all the hashing programs
 *   - The idea is to get a gsl vector of numbers, which correspond to a
 *     set of keys (see __factor_hash1() in ftools) and sort on that vector.
 *   - Careful with string data because that's not a thing in GSL.
 *
 *
 * The idea is to create an array with the hashes and csort on that array into
 * - gsl matrix?
 * - hash table where each element is a vector?
 * - Just have the same limitation of same type: Store keys in array
 * Collitions ): Have to do search (linear probing, trees) OR do the 128-bit
 * if you get into the billions of keys, you get collisions: http://burtleburtle.net/bob/hash/spooky.html
 * See also:
 *    http://stackoverflow.com/questions/18439520/is-there-a-128-bit-integer-in-c
 *    https://github.com/centaurean/spookyhash
 *    https://en.wikipedia.org/wiki/Jenkins_hash_function#SpookyHash
 *    https://github.com/sergiocorreia/ftools
 * Use this:  http://stackoverflow.com/questions/26695133/how-to-sort-3-arrays-together-in-c
 **
