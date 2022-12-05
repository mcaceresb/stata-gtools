*! version 0.2.1 14Apr2020 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Estimate linear regression via OLS by group and with HDFE

capture program drop gregress
program gregress, rclass

    if !inlist(`"${GTOOLS_BETA}"', "1", "I KNOW WHAT I AM DOING") {
        disp as err `"This function is in beta; to use, you must enable beta features via"'
        disp as err `""'
        disp as err `"    global GTOOLS_BETA = "I KNOW WHAT I AM DOING""'
        disp as err `""'
        disp as err `"gtools functions in beta are subject to change."'
        exit 198
    }

    if ( ("${GTOOLS_GREGTABLE}" == "1")  & replay() ) {
        Replay `0'
        exit 0
    }

    version 13.1
    global GREG_RC 0
    global GTOOLS_CALLER gregress

    if ( `=_N < 1' ) {
        global GREG_RC 17001
        di as txt "no observations"
        exit 0
    }

    * syntax varlist(numeric ts fv) // a way to support this would be to filter it through mata
    syntax anything(equalok)      /// depvar indepvars
        [if] [in]                 /// [if condition] [in start / end]
        [aw fw pw]    ,           /// [weight type = exp]
    [                             ///
        by(str)                   /// Winsorize options
        noMISSing                 /// Exclude groups with any missing values by level
        Robust                    /// Robust SE
        cluster(str)              /// Cluster by varlist
        absorb(varlist)           /// Absorb each var in varlist as FE
        glm                       /// estimate glm
        family(str)               /// glm family
        IVregress                 /// IV regression
        *                         /// Regress options
                                  ///
        compress                  /// Try to compress strL variables
        forcestrl                 /// Force reading strL variables (stata 14 and above only)
        Verbose                   /// Print info during function execution
        _CTOLerance(passthru)     /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                 /// Benchmark function
        BENCHmarklevel(int 0)     /// Benchmark various steps of the plugin
        HASHmethod(passthru)      /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        oncollision(passthru)     /// error|fallback: On collision, use native command or throw error
        debug(passthru)           /// Print debugging info to console
    ]

    disp as txt "{bf:warning:} gregress is beta software and meant for testing."
    disp as txt "Use in production is {bf:NOT} recommended; proceed with caution."

    if ( `"`missing'"' == "nomissing" ) local missing
    else local missing missing

    if ( `"`by'"' != "" ) unab by: `by'

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    * Parse IV syntax
    * ---------------

    * NOTE(mauricio): IV will only be allowed with input colmajor.

    * NOTE(mauricio): I put the instruments at the start so I can add a
    * constant. I will only have one memory alloc to X and then point to
    * ivz = X, ivendog = X + kz * N, ivexog = X + (kz + kendog) + N

    * NOTE(mauricio): Confirm var does not apparently allow for
    * wildcards; expand before confirm var. A consequence of this is
    * that the first variable listed is assumed to be the dependent
    * variable. Warn the user this might not be their intended behavior
    * if the first token passed is a wildcard.

    local ivok 0
    if regexm(`"`anything'"', ".+\((.+=.+)\)") {

        * Here I am rather inflexible with the notation. I think the
        * danger of bugs from unforseen mistakes are greater than the
        * upside of flexible notation.

        local iveq   = regexr(regexs(1), "\(|\)", "")
        local ivexog = trim(regexr("`anything'", "\(.+=.+\)", ""))

        * In keeping with this idea, the syntax _must_ be
        *
        *     indep [exog] (endog = instrument) [exog]
        *
        * where indep is a single variable and exog is optinal.

        unab ivexog: `ivexog'
        cap noi confirm var `ivexog'
        if ( _rc ) {
            disp as err "Error parsing IV syntax: No dependent variable detected"
            exit 198
        }

        gettoken ivendog ivinstruments: iveq, p(=)
        gettoken _ ivinstruments: ivinstruments

        unab ivinstruments: `ivinstruments'
        cap noi confirm var `ivinstruments'
        if ( _rc ) {
            disp as err "Instruments required for IV"
            exit 198
        }

        unab ivendog: `ivendog'
        cap noi confirm var `ivendog'
        if ( _rc ) {
            disp as err "Endogenous covariates required for IV"
            exit 198
        }

        * Note we expanded each set of variables above so this _should_
        * be an accurate cound of how many variables there are.

        gettoken ivdepvar ivexog: ivexog
        local ivkendog: list sizeof ivendog
        local ivkexog:  list sizeof ivexog
        local ivkz:     list sizeof ivinstruments

        * There is a slight issue here in that there is no colinearity
        * check implemented _before_ the under-identification check.
        * However, after the colinarity check if there are not enough
        * instruments both beta and se are set to missing.

        if ( `ivkz' < `ivkendog' ) {
            disp as error "Need at least as many instruments as endogenous variables (received `ivkz' < `ivkendog')"
            exit 198
        }

        * Finally, you can't have a variable that is both
        *
        * - dependenet variable _and_ instrumented
        * - dependenet variable _and_ instrument
        * - dependenet variable _and_ exogenous
        * - instrumented _and_ instrument
        * - instrumented _and_ exogenous
        * - instrument _and_ exogenous

        local problems: list ivdepvar & ivendog
        if ( `"`problems'"' != `""' ) {
            disp as error "`problems' included as both regressand and endogenous variable"
            exit 198
        }

        local problems: list ivdepvar & ivexog
        if ( `"`problems'"' != `""' ) {
            disp as error "`problems' included as both regressand and exogenous variable"
            exit 198
        }

        local problems: list ivdepvar & ivinstruments
        if ( `"`problems'"' != `""' ) {
            disp as error "`problems' included as both regressand and instrument"
            exit 198
        }

        local problems: list ivendog  & ivexog
        if ( `"`problems'"' != `""' ) {
            disp as error "included as both an endogenous and exogenous variable: `problems'"
            exit 198
        }

        local problems: list ivendog  & ivinstruments
        if ( `"`problems'"' != `""' ) {
            disp as error "included as both an endogenous variable and an instrument: `problems'"
            exit 198
        }

        local problems: list ivexog   & ivinstruments
        if ( `"`problems'"' != `""' ) {
            disp as error "included as both an exogenous variable and an instrument: `problems'"
            exit 198
        }

        * Note that each set of variables is passed, unabbreviated
        * already, as options so that no further parsing is necessary.

        unab  varlist: `ivdepvar' `ivendog' `ivexog' `ivinstruments'
        local ivopts ivkendog(`ivkendog') ivkexog(`ivkexog') ivkz(`ivkz')
        local ivregress ivregress
        local ivok 1
    }
    else {

        * Without IV, the only issue is that of unabbreviating the varlist.
        unab varlist: `anything'
    }

    * Parse rest of regression syntax
    * -------------------------------

    * gegen and gcollapse are better suited for implicit constant-only
    * models.  The user can also generate a variable of ones and request
    * that the constant be supressed. However, I will not allow an
    * implicit constant-only model because it's annoying to code and has
    * little added value.

    confirm var `varlist'
    if ( `:list sizeof varlist' == 1 ) {
        disp as err "constant-only models not allowed; varlist required"
        exit 198
    }

    * If ivregress requested, implicitly or otherwise, then check the
    * parsing. Again, hard stop because it's probably not good to be
    * overly flexible.

    if ( (`ivok' == 0) & ("`ivregress'" != "") ) {
        disp as err "Could not parse input into IV syntax"
        exit 198
    }

    * NOTE(mauricio): ivpoisson is not as straightforward as adapting
    * the poisson code, which iterates over OLS. Don't try it.

    local glmfamilies binomial poisson
    local nglm: list sizeof family

    if ( (`"`glm'"' == "") & (`nglm' > 0) ) {
        disp as err "Input error: GLM family requested without specifying glm"
        exit 198
    }

    if ( (`"`glm'"' != "") & (`nglm' == 0) ) {
        disp as err "Input error: GLM requires specifying model family()"
        exit 198
    }

    if ( `nglm' > 1 ) {
        disp as err "Input error: Cannot request multiple GLM models: `family'"
        exit 198
    }

    if ( (`"`glm'"' != "") & (!`:list family in glmfamilies') ) {
        disp as err "Input error: GLM family() must be one of: `glmfamilies'"
        exit 198
    }

    if ( ("`ivregress'" != "") & `nglm' ) {
        disp as err "Input error: IV and GLM (`family') requested at the same time"
        exit 198
    }

    * TODO: xx the idea is to eventually allow other links even for the
    * same family, I think

    if ( `"`family'"' == "binomial" ) local glmlink logit
    if ( `"`family'"' == "poisson" )  local glmlink log

    * NOTE(mauricio): We always make a todo variable because we want
    * to exclude missing values in varlist. Furthermore, I think this
    * is the place where we ought to exclude observations once the
    * -dropsingletons- option is added (to drop singleton groups)
    * and the program to automagically detect colinear groups (with
    * multi-way hdfe).

	if ( `"`weight'"' != "" ) {
		tempvar touse w
		qui gen double `w' `exp' `if' `in'
		local wgt `"[`weight'=`w']"'
        local weights weights(`weight' `w')
        mark `touse' `if' `in' `wgt'
        markout `touse' `varlist' `cluster' `absorb', strok
        local if if `touse'
	}
    else {
        local weights
        local _varlist: copy local varlist
        local varlist `varlist' `cluster' `absorb'
        marksample touse, strok
        local varlist: copy local _varlist
        local if if `touse'
    }

    * binary models require the variable be be 0/1:

    if ( `"`family'"' == "binomial" ) {
        gettoken y x: varlist
        qui count if !inlist(`y', 0, 1) & `touse'
        if ( `r(N)' > 0 ) {
            disp as err "`y' must be binary (0/1)"
            exit 198
        }
    }

    * Recall that the poisson model is a count model, so the variable
    * must be a natural number (i.e. non-negative integer). However, I
    * think I ought to allow users to have non-count variables if they
    * deem it necessary---the warning should be enough. The algorithm
    * fails, however, with negative numbers, so that _is_ a hard stop.

    if ( `"`family'"' == "poisson" ) {
        gettoken y x: varlist
        qui count if (`y' < 0) & `touse'
        if ( `r(N)' > 0 ) {
            disp as err "`y' must be non-negative"
            exit 198
        }
        qui count if (`y' != int(`y')) & `touse'
        if ( `r(N)' > 0 ) {
            disp as txt "{bf:note} you are responsible for interpretation of non-count dep. variable"
        }
    }

    * NOTE(mauricio): I don't think this warning is necessary anymore. The
    * main issue is no longer the collinearity check taking forever (it's
    * fairly quick now) but with the X' X matrix multiplication.  It's
    * _very_ slow and the main bottleneck, but not unreasonably slow given
    * the other speed gains.
    *
    * local kall: list sizeof varlist
    * local ratio = log(1e10 / _N)^2
    * if ( `kall' > max(`ratio', 16) ) {
    *     disp as txt "{bf:beta warning}: 'wide' model (large # of regressors) detected; performance may suffer"
    * }

    * Standard call to internals
    * --------------------------

    local options `options' `robust' cluster(`cluster') absorb(`absorb') glmfam(`family') glmlink(`glmlink')
    local opts    `weights' `compress' `forcestrl' nods unsorted `missing'
    local opts    `opts' `verbose' `benchmark' `benchmarklevel' `_ctolerance'
    local opts    `opts' `oncollision' `hashmethod' `debug'
    local greg    gfunction(regress) gregress(`varlist', `options' `ivopts')

    cap noi _gtools_internal `by' `if' `in', `opts' `greg'
    local rc = _rc
    global GTOOLS_CALLER ""

    * Cleanup
    * -------

    if ( `rc' == 17999 ) {
        exit 17000
    }
    else if ( `rc' == 18401 ) {
        exit 2001
    }
    else if ( `rc' == 17001 ) {
        global GREG_RC 17001
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) exit `rc'

    * Returns
    * -------

    return scalar N     = `r(N)'
    return scalar J     = `r(J)'
    return scalar minJ  = `r(minJ)'
    return scalar maxJ  = `r(maxJ)'
    return local cmd    = "gregress"
    return local mata: copy local saveGregressMata

    if ( "${GTOOLS_GREGTABLE}" == "1" ) Display `saveGregressMata', touse(`touse')
end

capture program drop Replay
program Replay, eclass
    if ( (`"`r(cmd)'"' != "gregress") | (`"`r(mata)'"' == "") ) error 301
    Display `r(mata)', repost `options'
end

capture program drop Display
program Display, eclass
    syntax [namelist(max = 1)], [repost touse(str) *]
    tempname by
    if ( "`namelist'" == "" ) {
        disp as txt "Cannot display table without cached results; use option -mata()- to save"
    }
    else {
        mata st_numscalar("`by'", `namelist'.by)
        if ( `=scalar(`by')' == 0)  {
            tempname colnames sel nmiss
            FreeMatrix b V
            mata st_local("caller", `namelist'.caller)
            mata st_local("setype", `namelist'.setype)
            mata st_matrix("`b'", `namelist'.b[1, .])
            mata st_matrix("`V'", `namelist'.Vcov)
            mata `colnames' = `namelist'.xvarlist, J(1, `namelist'.cons, "_cons")
            mata `nmiss'    = missing(`namelist'.se)
            mata `sel'      = selectindex(`namelist'.se :>= .)
            mata `colnames'[`sel'] = J(1, `nmiss', "o.") :+ `colnames'[`sel']
            mata st_matrixcolstripe("`b'", (J(cols(`colnames'), 1, ""), `colnames''))
            mata st_matrixrowstripe("`b'", ("", `namelist'.yvarlist[1]))
            mata st_matrixcolstripe("`V'", (J(cols(`colnames'), 1, ""), `colnames''))
            mata st_matrixrowstripe("`V'", (J(cols(`colnames'), 1, ""), `colnames''))
            if "`repost'" == "" {
                if ( "`touse'" != "" ) qui count if `touse'
                else qui count
                ereturn post `b' `V', esample(`touse') obs(`r(N)')
            }
            else {
                ereturn repost b = `b' V = `V'
            }
            if ( "`setype'" == "cluster" ) ereturn local vcetype "Cluster"
            if ( "`setype'" == "robust"  ) ereturn local vcetype "Robust"
            if ( "`setype'" != "homoskedastic"  ) ereturn local vce "`setype'"
            disp _n(1) "`caller' with `setype' SE"
            _coef_table, `options'
        }
        else {
            disp as txt "Cannot display table with by(); use {stata mata `namelist'.print()}"
        }
    }
end

capture program drop FreeMatrix
program FreeMatrix
    local FreeCounter 0
    local FreeMatrix
    foreach FM of local 0 {
        cap error 0
        while ( _rc == 0 ) {
            cap confirm matrix Gtools`++FreeCounter'
            c_local `FM' Gtools`FreeCounter'
        }
    }
end
