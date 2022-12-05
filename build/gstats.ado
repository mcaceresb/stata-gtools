*! version 0.5.0 11Jun2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Implementation of several statistical functions and transformations

capture program drop gstats
program gstats, rclass
    version 13.1
    global GTOOLS_CALLER gstats
    gettoken stat 0: 0

    local alias_tabstat tab    ///
                        tabs   ///
                        tabst  ///
                        tabsta

    local alias_summarize su      ///
                          sum     ///
                          summ    ///
                          summa   ///
                          summar  ///
                          summari ///
                          summariz

    local alias_transform range moving

    local alias_winsor winsorize

    local alias_hdfe   residualize

    local stats_sorted tabstat ///
                       summarize

    local stats dir         ///
                winsor      ///
                hdfe        ///
                transform   ///
                range       ///
                moving      ///
                tabstat     ///
                summarize

    if ( `:list stat in alias_transform' ) local statprefix statprefix(`stat'|)

    local alias
    foreach a of local stats {
        local alias `alias' alias_`a'
        if ( `:list stat in alias_`a'' ) {
            local stat `a'
        }
    }

    if ( `"`stat'"' == "" ) {
        disp as err "Nothing to do. See {help gstats:help gstats} or {stata gstats dir}."
        exit 198
    }

    if ( !`:list stat in stats' & !`:list stat in alias' ) {
        disp as err "Unknown stat `stat'. See {help gstats:help gstats} or {stata gstats dir}."
        exit 198
    }

    if ( `"`stat'"' == "dir" ) {
        gettoken dir stats: stats
        disp as txt "Available:"
        foreach stat of local stats {
            disp as txt "    {help gstats `stat'}"
        }
        exit 0
    }

    if ( `"`stat'"' == "hdfe" & !inlist(`"${GTOOLS_BETA}"', "1", "I KNOW WHAT I AM DOING") ) {
        disp as err `"This function is in beta; to use, you must enable beta features via"'
        disp as err `""'
        disp as err `"    global GTOOLS_BETA = "I KNOW WHAT I AM DOING""'
        disp as err `""'
        disp as err `"gtools functions in beta are subject to change."'
        exit 198
    }

    syntax anything(equalok)   /// Variables/things to check
        [if] [in]              /// [if condition] [in start / end]
        [aw fw pw iw] ,        /// [weight type = exp]
    [                          ///
        *                      /// Options for subprograms
        by(str)                /// Winsorize options
        noMISSing              /// Exclude groups with any missing values by level
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

    if ( `"`missing'"' == "nomissing" ) local missing
    else local missing missing

    local unsorted = cond(`:list stat in stats_sorted', "", "unsorted")

    if ( `"`by'"' != "" ) unab by: `by'

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( ("`weight'" == "iweight") & ("`stat'" == "hdfe") ) {
        disp as err "iweight not allowed"
        exit 101
    }

	if ( `"`weight'"' != "" ) {
		tempvar touse w
		qui gen double `w' `exp' `if' `in'
		local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        mark `touse' `if' `in' `wgt'
        local if if `touse'
	}
    else local weights

    local opts   `weights' `compress' `forcestrl' nods `unsorted' `missing'
    local opts   `opts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local opts   `opts' `oncollision' `hashmethod' `debug'
    local gstats  gfunction(stats) gstats(`stat' `anything', `options' `statprefix')

    cap noi _gtools_internal `by' `if' `in', `opts' `gstats'
    local rc = _rc
    global GTOOLS_CALLER ""

    * Special handling of exit behavior
    * ---------------------------------

    if ( `"`stat'"' == "summarize" ) {
        if ( inlist(`rc', 17001, 18201) ) {
            return scalar N     = 0
            return scalar sum_w = 0
            return scalar sum   = 0
        }
    }

    * Cleanup
    * -------

    if ( `rc' == 17999 ) {
        exit 17000
    }
    else if ( `rc' == 17001 ) {
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' == 18201 ) {
        exit 0
    }
    else if ( `rc' == 18402 ) {
        di as txt "gstats_hdfe: maximum number of iterations exceeded; convergence not achieved"
        exit 430
    }
    else if ( `rc' == 18301 ) {
        di as txt "gstats_transform: internal parsing error (unexpected number of stats in transform)"
        exit `rc'
    }
    else if ( `rc' ) exit `rc'

    * Returns
    * -------

    * return scalar N      = `r(N)'
    return scalar J      = `r(J)'
    return scalar minJ   = `r(minJ)'
    return scalar maxJ   = `r(maxJ)'

    * Extra returns
    * -------------

    if ( `"`stat'"' == "hdfe" ) {
        tempname hdfe_nabsorb
        matrix `hdfe_nabsorb' = r(hdfe_nabsorb)
        return scalar N = `r(hdfe_nonmiss)'
        if `r(hdfe_saveabs)' {
            return matrix nabsorb = `hdfe_nabsorb'
        }
        if `r(hdfe_saveinfo)' {
            return scalar iter  = `r(hdfe_iter)'
            return scalar feval = `r(hdfe_feval)'
        }
        return local algorithm = "`r(hdfe_method)'"
    }

    if ( `"`stat'"' == "winsor" ) {
        return scalar cutlow  = r(gstats_winsor_cutlow)
        return scalar cuthigh = r(gstats_winsor_cuthigh)
    }

    if ( `"`stat'"' == "summarize" ) {
        if ( `r(gstats_summarize_tabstat)' ) {
            * disp as txt "({bf:warning}: r() results not currently saved)"
        }

        {
            return scalar N     = r(gstats_summarize_N)      // number of observations
            return scalar sum_w = r(gstats_summarize_sum_w)  // sum of the weights
            return scalar sum   = r(gstats_summarize_sum)    // sum of variable
            return scalar mean  = r(gstats_summarize_mean)   // mean
            return scalar min   = r(gstats_summarize_min)    // minimum
            return scalar max   = r(gstats_summarize_max)    // maximum

            if ( `r(gstats_summarize_normal)' ) {
                return scalar Var = r(gstats_summarize_Var)  // variance
                return scalar sd  = r(gstats_summarize_sd)   // standard deviation
            }

            if ( `r(gstats_summarize_detail)' ) {
                return scalar p1        = r(gstats_summarize_p1)       // 1st percentile (detail only)
                return scalar p5        = r(gstats_summarize_p5)       // 5th percentile (detail only)
                return scalar p10       = r(gstats_summarize_p10)      // 10th percentile (detail only)
                return scalar p25       = r(gstats_summarize_p25)      // 25th percentile (detail only)
                return scalar p50       = r(gstats_summarize_p50)      // 50th percentile (detail only)
                return scalar p75       = r(gstats_summarize_p75)      // 75th percentile (detail only)
                return scalar p90       = r(gstats_summarize_p90)      // 90th percentile (detail only)
                return scalar p95       = r(gstats_summarize_p95)      // 95th percentile (detail only)
                return scalar p99       = r(gstats_summarize_p99)      // 99th percentile (detail only)
                return scalar skewness  = r(gstats_summarize_skewness) // skewness (detail only)
                return scalar kurtosis  = r(gstats_summarize_kurtosis) // kurtosis (detail only)

                return scalar smallest1 = r(gstats_summarize_smallest1) // smallest
                return scalar smallest2 = r(gstats_summarize_smallest2) // 2nd smallest
                return scalar smallest3 = r(gstats_summarize_smallest3) // 3rd smallest
                return scalar smallest4 = r(gstats_summarize_smallest4) // 4th smallest
                return scalar largest4  = r(gstats_summarize_largest4)  // 4th largest
                return scalar largest3  = r(gstats_summarize_largest3)  // 3rd largest
                return scalar largest2  = r(gstats_summarize_largest2)  // 2nd largest
                return scalar largest1  = r(gstats_summarize_largest1)  // largest
            }
        }

        if ( `r(gstats_summarize_pooled)' ) {
            return local varlist `r(statvars)'
        }
    }
end
