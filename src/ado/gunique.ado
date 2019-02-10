*! version 1.0.1 23Jan2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -unique- implementation using C for faster processing

capture program drop gunique
program gunique, rclass
    version 13.1

    if ( `=_N < 1' ) {
        di as err "no observations"
        exit 2000
    }

    syntax varlist [if] [in] , ///
    [                          ///
        Detail                 /// Summary statistics for group counts
        MISSing                /// Include missing values
        by(str)                /// by variabes: [+|-]varname [[+|-]varname ...]
        GENerate(name)         /// Store uniques in generate (default _Unique)
        replace                /// Replace variable specifyed by generate if it exists
                               ///
        compress               /// Try to compress strL variables
        forcestrl              /// Force reading strL variables (stata 14 and above only)
        Verbose                /// Print info during function execution
        _CTOLerance(passthru)  /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark              /// Benchmark function
        BENCHmarklevel(int 0)  /// Benchmark various steps of the plugin
        HASHmethod(passthru)   /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)  /// error|fallback: On collision, use native command or throw error
        debug(passthru)        /// Print debugging info to console
    ]
    local seecount  seecount
    local unsorted  unsorted
    local countonly countonly

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( "`by'" != "" ) {
        if ( "`generate'" == "" ) {
            capture confirm new variable _Unique
            if ( _rc ) {
                if ( "`replace'" == "" ) {
                    di as err "Variable _Unique already exists."
                    di as err "Use the gen() option to specify a new variable."
                    exit 110
                }
            }
            local generate _Unique
        }
        else {
            cap confirm new variable `generate'
            if ( _rc ) {
                if ( "`replace'" == "" ) {
                    di as err "`generate' already exists."
                    exit 110
                }
            }
        }

        local seecount  ""
        * local unsorted  ""
        local countonly ""

        tempvar id
        local gopts gen(`id')
        if ( "`missing'" == "" ) local ifid if !mi(`id')

        local type double
        if ( `=_N' < 2^21 ) local type long
    }

    global GTOOLS_CALLER gunique
    local opts `missing' `seecount' `compress' `forcestrl'
    local opts `opts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local opts `opts' `oncollision' `hashmethod' `debug' `gopts'

    if ( "`detail'" != "" ) {
        tempvar count
        local dopts counts(`count') fill(data)
        cap noi _gtools_internal `varlist' `if' `in', `unsorted' `opts' `dopts' gfunction(unique)
        local rc = _rc
        global GTOOLS_CALLER ""

        if ( `rc' == 17999 ) {
            unique `varlist' `if' `in', `detail'
            exit 0
        }
        else if ( `rc' == 17001 ) {
            di as txt "(no observations)"
            exit 0
        }
        else if ( `rc' ) exit `rc'

        return scalar N      = `r(N)'
        return scalar J      = `r(J)'
        return scalar unique = `r(J)'
        return scalar minJ   = `r(minJ)'
        return scalar maxJ   = `r(maxJ)'

        local nunique = `r(J)'
        local r_Ndisp = trim(`"`: di %21.0gc `r(N)''"')
        local r_Jdisp = trim(`"`: di %21.0gc `r(J)''"')

        sum `count' in 1 / `=r(J)', d
    }
    else {
        cap noi _gtools_internal `varlist' `if' `in', `countonly' `unsorted' `opts' gfunction(unique)
        local rc = _rc
        global GTOOLS_CALLER ""

        if ( `rc' == 17999 ) {
            unique `varlist' `if' `in', `detail'
            exit 0
        }
        else if ( `rc' == 17001 ) {
            di as txt "(no observations)"
            exit 0
        }
        else if ( `rc' ) exit `rc'

        return scalar N      = `r(N)'
        return scalar J      = `r(J)'
        return scalar unique = `r(J)'
        return scalar minJ   = `r(minJ)'
        return scalar maxJ   = `r(maxJ)'

        local nunique = `r(J)'
        local r_Ndisp = trim(`"`: di %21.0gc `r(N)''"')
        local r_Jdisp = trim(`"`: di %21.0gc `r(J)''"')
    }

    if ( "`by'" != "" ) {
        gegen `type' `generate' = tag(`by' `id') `ifid', missing `replace'
        gegen `generate' = sum(`generate'), by(`by') replace

        di as txt ""
        di as txt "'`varlist'' had `r_Jdisp' unique values in `r_Ndisp' observations."
        di as txt "Variable `generate' has the number of unique values of '`varlist'' by '`by''."

        if ( "`detail'" != "" ) {
            if ( `=`nunique'' > 5 ) {
                local header = `"The top 5 frequency counts of `generate' for the levels of '`by'' are"'
            }
            else {
                local header = `"The frequency counts of `generate' for the levels of '`by'' are"'
            }
            di as txt `"`header'"'
            gtoplevelsof `by' `generate' if `generate' > 0, ntop(5)
        }
    }
end
