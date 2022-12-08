*! version 1.10.1 05Dec2022 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! gtools function internals

* rc 17000
* rc 17001 - no observations
* rc 17002 - strL variables and version < 14
* rc 17003 - strL variables and version >= 14
* rc 17004 - strL variables could not be compressed
* rc 17005 - strL contains binary data
* rc 17006 - strL variables unknown error
* rc 17800 - More than 2^31-1 obs
* rc 17801 - gtools has not been compiled for a X-bit architecture
* rc 18101 - greshape long id variables not unique
* rc 18102 - greshape wide j variables not unique within id
* rc 18103 - greshape wide xi variables not unique within id
* rc 18201 - gstats all variables are non-numeric (soft exit)
* rc 18301 - gstats transform; unexpected number of stats passed to transform
* rc 18401 - gregress k > N (too many vars/absorb levels)
* rc 18402 - hdfe maximum number of iterations
* --------
* rc 17459 - isid special error
* rc 17900 - multi-threading not available
* rc 17901 - generic not implemented
* rc 17902 - gtools API OOM
* rc 17999 - collision error
* --------
* > 0 to < 100 strict gives quantiles
* -1 to -100 stats are regular stats
* -101 to -200 stats are analogues with special nan handling
* -201 to -300 stats are analogues with special gstats handling
* 1000 + # selects the #th smallest
* - 1000 - # selects the #th largest
* 1000.5 + # rawselects the #th smallest
* - 1000.5 - # rawselects the #th largest

capture program drop _gtools_internal
program _gtools_internal, rclass
    version 13.1

    if ( `"`0'"' == "_check" ) {
        cap noi plugin call gtools_plugin, check
        exit _rc
    }

    if ( `"${GTOOLS_TEMPDIR}"' == "" ) {
        tempfile gregfile
        tempfile gregbfile
        tempfile gregsefile
        tempfile gregvcovfile
        tempfile gregclusfile
        tempfile gregabsfile
        tempfile ghdfeabsfile
        tempfile gstatsfile
        tempfile gbyvarfile
        tempfile gbycolfile
        tempfile gbynumfile
        tempfile gtopnumfile
        tempfile gtopmatfile
    }
    else {
        GtoolsTempFile gregfile
        GtoolsTempFile gregbfile
        GtoolsTempFile gregsefile
        GtoolsTempFile gregvcovfile
        GtoolsTempFile gregclusfile
        GtoolsTempFile gregabsfile
        GtoolsTempFile ghdfeabsfile
        GtoolsTempFile gstatsfile
        GtoolsTempFile gbyvarfile
        GtoolsTempFile gbycolfile
        GtoolsTempFile gbynumfile
        GtoolsTempFile gtopnumfile
        GtoolsTempFile gtopmatfile
    }

    global GTOOLS_GREG_FILE:     copy local gregfile
    global GTOOLS_GREGB_FILE:    copy local gregbfile
    global GTOOLS_GREGSE_FILE:   copy local gregsefile
    global GTOOLS_GREGVCOV_FILE: copy local gregvcovfile
    global GTOOLS_GREGCLUS_FILE: copy local gregclusfile
    global GTOOLS_GREGABS_FILE:  copy local gregabsfile
    global GTOOLS_GHDFEABS_FILE: copy local ghdfeabsfile
    global GTOOLS_GSTATS_FILE:   copy local gstatsfile
    global GTOOLS_BYVAR_FILE:    copy local gbyvarfile
    global GTOOLS_BYCOL_FILE:    copy local gbycolfile
    global GTOOLS_BYNUM_FILE:    copy local gbynumfile
    global GTOOLS_GTOPNUM_FILE:  copy local gtopnumfile
    global GTOOLS_GTOPMAT_FILE:  copy local gtopmatfile

    global GTOOLS_USER_INTERNAL_VARABBREV `c(varabbrev)'
    * set varabbrev off

    if ( inlist("${GTOOLS_FORCE_PARALLEL}", "17900") ) {
        di as txt "(note: multi-threading is not available on this platform)"
    }

    if ( `c(bit)' != 64 ) {
        di as err "(warning: gtools has not been tested on a `c(bit)'-bit architecture)"
        * di as err "gtools has not been compiled on a `c(bit)'-bit architecture"
        * exit 17801
    }

    local GTOOLS_CALLER $GTOOLS_CALLER
    local GTOOLS_CALLERS gegen        ///
                         gcollapse    ///
                         gisid        /// 2
                         hashsort     /// 3
                         glevelsof    ///
                         gunique      ///
                         gtoplevelsof ///
                         gcontract    /// 8
                         gquantiles   ///
                         gstats       ///
                         greshape     /// 11
                         gregress     ///
                         ghash

    if ( !(`:list GTOOLS_CALLER in GTOOLS_CALLERS') | ("$GTOOLS_CALLER" == "") ) {
        di as err "_gtools_internal is not meant to be called directly." ///
                  " See {help gtools}"
        clean_all 198
        exit 198
    }

    if ( `=_N < 1' ) {
        di as err "no observations"
        clean_all 17001
        exit 17001
    }

    if ( `=_N > 2^31-1' ) {
        local nmax = trim("`: disp %21.0gc 2^31-1'")
        di as err `"too many observations"'
        di as err `""'
        di as err `"A Stata bug prevents gtools from working with more than `nmax' observations."'
        di as err `"See {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1457637"}"'
        di as err `"and {browse "https://github.com/mcaceresb/stata-gtools/issues/43"}"'
        clean_all 17800
        exit 17800
    }

    local 00: copy local 0

    * Time the entire function execution
    FreeTimer
    local t99: copy local FreeTimer
    global GTOOLS_T99: copy local t99
    gtools_timer on `t99'

    FreeTimer
    local t98: copy local FreeTimer
    global GTOOLS_T98: copy local t98
    gtools_timer on `t98'

    ***********************************************************************
    *                           Syntax parsing                            *
    ***********************************************************************

    syntax [anything] [if] [in] , ///
    [                             ///
        DEBUG_level(int 0)        /// debugging
        Verbose                   /// info
        _subtract                 /// (Undocumented) Subtract result from source variabes
        _keepgreshape             /// (Undocumented) Keep greshape scalars
        _CTOLerance(real 0)       /// (Undocumented) Counting sort tolerance; default is radix
        BENCHmark                 /// print function benchmark info
        BENCHmarklevel(int 0)     /// print plugin benchmark info
        HASHmethod(str)           /// hashing method
        oncollision(str)          /// On collision, fall back or throw error
        gfunction(str)            /// Program to handle collision
        replace                   /// Replace variables, if they exist
        noinit                    /// Do not initialize targets with missing values
        compress                  /// Try to compress strL variables
        forcestrl                 /// Force reading strL variables (stata 14 and above only)
                                  ///
                                  /// General options
                                  /// ---------------
                                  ///
                                  /// keeptouse(str) /// generate sample indicator
        seecount                  /// print group info to console
        COUNTonly                 /// report group info and exit
        MISSing                   /// Include missing values
        KEEPMISSing               /// Summary stats are . if all inputs are .
        unsorted                  /// Do not sort hash values; faster
        countmiss                 /// count # missing in output
                                  /// (only w/certain targets)
        NODS DS                   /// Parse - as varlist (ds) or negative (nods)
                                  ///
                                  /// Generic stats options
                                  /// ---------------------
                                  ///
        sources(str)              /// varlist must exist
        targets(str)              /// varlist must exist
        stats(str)                /// stats, 1 per target. w/multiple targets,
                                  /// # targets must = # sources
        freq(str)                 /// also collapse frequencies to variable
        rawstat(str)              /// Ignore weights for these targets
                                  ///
                                  /// Capture options
                                  /// ---------------
                                  ///
        greshape(str)             /// options for greshape (to parse later)
        gregress(str)             /// options for gregress (to parse later)
        gstats(str)               /// options for gstats (to parse later)
        gquantiles(str)           /// options for gquantiles (to parse later)
        gcontract(str)            /// options for gcontract (to parse later)
        gcollapse(str)            /// options for gcollapse (to parse later)
        gtop(str)                 /// options for gtop (to parse later)
        recast(str)               /// bulk recast
        sumcheck(str)             /// absolute sum
        weights(str)              /// weight_type weight_var
                                  ///
                                  /// gegen group options
                                  /// -------------------
                                  ///
        tag(str)                  /// 1 for first obs of group in range, 0 otherwise
        GENerate(str)             /// variable where to store encoded index
        counts(str)               /// variable where to store group counts
        fill(str)                 /// for counts(); group fill order or value
                                  ///
                                  /// gisid options
                                  /// -------------
                                  ///
        EXITMissing               /// Throw error if any missing values (by row).
                                  ///
                                  /// hashsort options
                                  /// ----------------
                                  ///
        invertinmata              /// invert sort index using mata
        sortindex(str)            /// keep sort index in memory
        sortgen                   /// sort by generated variable (hashsort only)
        skipcheck                 /// skip is sorted check
        mlast                     /// sort missing values last, as a group
                                  ///
                                  /// glevelsof options
                                  /// -----------------
                                  ///
        glevelsof(str)            /// extra options for glevelsof (parse later)
        Separate(str)             /// Levels sepparator
        COLSeparate(str)          /// Columns sepparator
        Clean                     /// Clean strings
        numfmt(str)               /// Columns sepparator
    ]

    * Startup!
    * --------

    * if ( ("`replace'" != "") & ("${GTOOLS_USER_INTERNAL_VARABBREV}" == "on") ) {
    *     disp as err "Option {opt replace} not allowed with varabbrev on."
    *     disp as err "Run {stata set varabbrev off} to use this feature."
    *     exit 198
    * }

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local gen `generate'
    mata st_local("ifin", strtrim(st_local("if") + " " + st_local("in")))

    local hashmethod `hashmethod'
    if ( `"`hashmethod'"' == "" ) local hashmethod 0

    local hashmethod_list 0 1 2 default biject spooky
    if ( !`:list hashmethod_list in hashmethod_list' ) {
        di as err `"hash method '`hashmethod'' not known;"' ///
                   " specify 0 (default), 1 (biject), or 2 (spooky)"
        clean_all 198
        exit 198
    }

    if ( `"`hashmethod'"' == "default" ) local hashmethod 0
    if ( `"`hashmethod'"' == "biject"  ) local hashmethod 1
    if ( `"`hashmethod'"' == "spooky"  ) local hashmethod 2

    ***********************************************************************
    *                               debug!                                *
    ***********************************************************************

    if ( `debug_level' ) {
        local gopts1 tag(`tag')
        local gopts1 `gopts1' generate(`generate')
        local gopts1 `gopts1' counts(`counts')
        local gopts1 `gopts1' fill(`fill')

        local gopts2 `exitmissing'

        local gopts3 `invertinmata'
        local gopts3 `gopts3' sortindex(`sortindex')
        local gopts3 `gopts3' `sortgen'
        local gopts3 `gopts3' `skipcheck'
        local gopts3 `gopts3' `mlast'

        local gopts4 glevelsof(`glevelsof')
        local gopts4 `gopts4' separate(`separate')
        local gopts4 `gopts4' colseparate(`colseparate')
        local gopts4 `gopts4' clean
        local gopts4 `gopts4' numfmt(`numfmt')

        disp as txt `""'
        disp as txt "{cmd:_gtools_internal} (debug level `debug_level')"
        disp as txt "{hline 72}"
        disp as txt `""'
        disp as txt `"    anything:         `anything'"'
        disp as txt `"    [if] [in]:        `if' `in'"'
        disp as txt `"    weights:          `weights'"'
        disp as txt `"    gfunction:        `gfunction'"'
        disp as txt `"    GTOOLS_CALLER:    $GTOOLS_CALLER"'
        disp as txt `""'
        disp as txt `"    compress:         `compress'"'
        disp as txt `"    forcestrl:        `forcestrl'"'
        disp as txt `"    verbose:          `verbose'"'
        disp as txt `"    benchmark:        `benchmark'"'
        disp as txt `"    hashmethod:       `hashmethod'"'
        disp as txt `"    oncollision:      `oncollision'"'
        disp as txt `"    replace:          `replace'"'
        disp as txt `""'
        disp as txt `"    seecount:         `seecount'"'
        disp as txt `"    countonly:        `countonly'"'
        disp as txt `"    missing:          `missing'"'
        disp as txt `"    keepmissing:      `keepmissing'"'
        disp as txt `"    unsorted:         `unsorted'"'
        disp as txt `"    countmiss:        `countmiss'"'
        disp as txt `""'
        disp as txt `"    sources:          `sources'"'
        disp as txt `"    targets:          `targets'"'
        disp as txt `"    stats:            `stats'"'
        disp as txt `"    freq:             `freq'"'
        disp as txt `"    rawstat:          `rawstat'"'
        disp as txt `""'
        disp as txt "{hline 72}"
        disp as txt `""'
        disp as txt `"    gegen:            `gopts1'"'
        disp as txt `"    gisid:            `gopts2'"'
        disp as txt `"    hashsort:         `gopts3'"'
        disp as txt `"    glevelsof:        `gopts4'"'
        disp as txt `"    gquantiles:       `gquantiles'"'
        disp as txt `"    gcontract:        `gcontract'"'
        disp as txt `"    gstats:           `gstats'"'
        disp as txt `"    gregress:         `gregress'"'
        disp as txt `"    greshape:         `greshape'"'
        disp as txt `"    gcollapse:        `gcollapse'"'
        disp as txt `"    gtop:             `gtop'"'
        disp as txt `"    recast:           `recast'"'
        disp as txt `"    sumcheck:         `sumcheck'"'
        disp as txt `""'
        disp as txt "{hline 72}"
        disp as txt `""'
    }

    ***********************************************************************
    *                       Sum of absolute values                        *
    ***********************************************************************

    if ( "`sumcheck'" != "" ) {
        gettoken wtype wvar: weights
        local wtype `wtype'
        local wvar `wvar'
        local 0  , checkvars(`sumcheck')
        syntax, checkvars(varlist)

        if ( `debug_level' ) {
            disp as txt `""'
            disp as txt "{cmd:_gtools_internal/sumcheck} (debug level `debug_level')"
            disp as txt "{hline 72}"
            disp as txt `""'
            disp as txt `"    checkvars:      `checkvars'"'
            disp as txt `"    __gtools_sum_k: `:list sizeof checkvars'"'
        }

        scalar __gtools_sum_k    = `:list sizeof checkvars'
        scalar __gtools_sum_w    = "`wvar'" != ""
        matrix __gtools_sumcheck = J(1, `:list sizeof checkvars', .)
        if ( inlist(`"`wtype'"', "fweight", "") ) {
            cap noi plugin call gtools_plugin `checkvars' `wvar', sumcheck
            local rc = _rc
        }
        else rc = 0
        return matrix sumcheck = __gtools_sumcheck
        cap scalar drop __gtools_sum_k
        cap matrix drop __gtools_sumcheck
        clean_all `rc'
        exit `rc'
    }

    ***********************************************************************
    *                             Bulk recast                             *
    ***********************************************************************

    if ( "`recast'" != "" ) {
        local 0  , `recast'
        syntax, sources(varlist) targets(varlist)

        if ( `:list sizeof sources' != `:list sizeof targets' ) {
            di as err "Must specify the same number of sources and targets"
            clean_all 198
            exit 198
        }

        if ( `debug_level' ) {
            disp as txt `""'
            disp as txt "{cmd:_gtools_internal/recast} (debug level `debug_level')"
            disp as txt "{hline 72}"
            disp as txt `""'
            disp as txt `"    sources:              `sources'"'
            disp as txt `"    targets:              `targets'"'
            disp as txt `"    __gtools_k_recast:    `:list sizeof sources'"'
        }

        scalar __gtools_k_recast = `:list sizeof sources'
        cap noi plugin call gtools_plugin `targets' `sources', recast
        local rc = _rc
        cap scalar drop __gtools_k_recast
        clean_all `rc'
        exit `rc'
    }

    ***********************************************************************
    *                    Execute the function normally                    *
    ***********************************************************************

    * What to do
    * ----------

    local gfunction_list hash     ///
                         egen     ///
                         levelsof ///
                         isid     ///
                         sort     ///
                         unique   ///
                         collapse ///
                         top      ///
                         contract ///
                         stats    ///
                         regress  ///
                         reshape  ///
                         quantiles

    if ( "`gfunction'" == "" ) local gfunction hash
    if ( !(`:list gfunction in gfunction_list') ) {
        di as err "{opt gfunction()} was '`gfunction''; expected one of:" ///
                  " `gfunction_list'"
        clean_all 198
        exit 198
    }

    * Switches, options
    * -----------------

    local website_url  https://github.com/mcaceresb/stata-gtools/issues
    local website_disp github.com/mcaceresb/stata-gtools

    if ( "`oncollision'" == "" ) local oncollision fallback
    if ( !inlist("`oncollision'", "fallback", "error") ) {
        di as err "option {opt oncollision()} must be 'fallback' or 'error'"
        clean_all 198
        exit 198
    }

    * Check options compatibility
    * ---------------------------

    * Unsorted is passed automagically for isid and unique, where we
    * don't care about sort order.

    if ( inlist("`gfunction'", "isid", "unique") ) {
        if ( "`unsorted'" == "" ) {
            di as txt "({opt gfunction(`gfunction')} sets option" ///
                      " {opt unsorted} automatically)"
            local unsorted unsorted
        }
    }

    * isid exits with error if any variables have a missing value; the
    * function needs to know whether to obey this rule or skip it (i.e.
    * -missok- option in the caller)

    if ( inlist("`gfunction'", "isid") ) {
        if ( "`exitmissing'`missing'" == "" ) {
            di as err "{opt gfunction(`gfunction')} must set either" ///
                      " {opt exitmissing} or {opt missing}"
            clean_all 198
            exit 198
        }
    }

    * If the caller is sort, then
    *     - It must be applied to the entire data set (no partial sorts)
    *     - It does not exit if any observations are missing
    *     - It also sorts rows with any missing observations
    *     - The output cannot be unsorted!

    if ( inlist("`gfunction'", "sort") ) {
        if ( `"`if'"' != "" ) {
            di as err "Cannot sort data with if condition"
            clean_all 198
            exit 198
        }
        if ( "`exitmissing'" != "" ) {
            di as err "Cannot specify {opt exitmissing} with" ///
                      " {opt gfunction(sort)}"
            clean_all 198
            exit 198
        }
        if ( "`missing'" == "" ) {
            di as txt "({opt gfunction(`gfunction')} sets option" ///
                      " {opt missing} automatically)"
            local missing missing
        }
        if ( "`unsorted'" != "" ) {
            di as err "Cannot specify {opt unsorted} with {opt gfunction(sort)}"
            clean_all 198
            exit 198
        }
    }

    * You cannot both exit if any observation is missing and not exit
    * if any observation is missing. For several group functions, stata
    * ignores a row if the by variable has a missing observation. This
    * controls whether to exclude the row/throw an error or whether to
    * include it as a new group.

    if ( ("`exitmissing'" != "") & ("`missing'" != "") ) {
        di as err "Cannot specify {opt exitmissing} with option {opt missing}"
        clean_all 198
        exit 198
    }

    * If the caller is sort, you can request a sort index.
    if ( "`sortindex'" != "" ) {
        if ( !inlist("`gfunction'", "sort") ) {
            di as err "sort index only allowed with {opt gfunction(sort)}"
            clean_all 198
            exit 198
        }
    }

    * Counts, gen, and tag are generic options that were specially
    * coded to work with egen count, group, and tag, espectively. Hence
    * they are handled sepparately. However, we only allow them to be
    * requested with egen, unique, sort, levelsof, or quantiles as the
    * caller.

    if ( "`counts'`gen'`tag'" != "" ) {
        if ( "`countonly'" != "" ) {
            di as err "cannot generate targets with option {opt countonly}"
            clean_all 198
            exit 198
        }

        local gen_list hash egen unique sort levelsof quantiles
        if ( !`:list gfunction in gen_list' ) {
            di as err "cannot generate targets with" ///
                      " {opt gfunction(`gfunction')}"
            clean_all 198
            exit 198
        }

        if ( ("`gen'" == "") & !inlist("`gfunction'", "sort", "levelsof") ) {
            if ( "`unsorted'" == "" ) {
                di as txt "({opt tag} and {opt counts} without {opt gen}" ///
                           " sets option {opt unsorted} automatically)"
                local unsorted unsorted
            }
        }
    }

    * Sources, targets, and stats are coded as generic options but they
    * are basically only allowed with egen and collapse as callers. The
    * generic "hash" caller will also accept it but it will not run any
    * of the optimization checks that gegen and gcollapse do (specially
    * gcollapse).

    if ( "`sources'`targets'`stats'" != "" ) {
        if ( !inlist("`gfunction'", "hash", "egen", "collapse", "unique") ) {
            di as err "cannot generate targets with {opt gfunction(`gfunction')}"
            clean_all 198
            exit 198
        }
    }

    * -fill()- is an option that was included at Sergio Correia's
    * request. It allows the user to specify how certain output is to
    * be filled (group: merge back to the data; missing: only the first
    * observation of each group; adata: sequentially without merging
    * back to the data). I believe he uses this internally in reghdfe.

    if ( "`fill'" != "" ) {
        if ( "`counts'`targets'" == "" ) {
            di as err "{opt fill()} only allowed with {opth counts(newvarname)}"
            clean_all 198
            exit 198
        }
    }

    * The levelsof caller's options were implemented before I got the
    * idea of capturing each caller's options. Hence they are parsed
    * here! Yay for legacy support.
    *     - separate is the character that delimits each group
    *     - colseparate is the char that delimits each column within a group
    *     - clean is whether the strings should be left unquoted
    *     - numfmt is how to print the numbers

    if ( "`separate'`colseparate'`clean'`numfmt'" != "" ) {
        local errmsg ""
        if ( "`separate'"    != "" ) local errmsg "`errmsg' separate(),"
        if ( "`colseparate'" != "" ) local errmsg "`errmsg' colseparate(), "
        if ( "`clean'"       != "" ) local errmsg "`errmsg' -clean-, "
        if ( "`numfmt'"      != "" ) local errmsg "`errmsg' -numfmt()-, "
        if ( !inlist("`gfunction'", "levelsof", "top") ) {
            di as err "`errmsg' only allowed with {opt gfunction(levelsof)}"
            clean_all 198
            exit 198
        }
    }

    * Parse weights
    * -------------

    * Some functions allow weights, which are parsed here.

    gettoken wtype wvar: weights

    if ( `"`wtype'"' == "" ) {
        local wcode 0
    }
    else {
        if ( `"`wvar'"' == "" ) {
            di as err "Passed option {opt weights(`wtype')} without a weighting variable"
            clean_all 198
            exit 198
        }

             if ( `"`wtype'"' == "aweight" ) local wcode 1
        else if ( `"`wtype'"' == "fweight" ) local wcode 2
        else if ( `"`wtype'"' == "iweight" ) local wcode 3
        else if ( `"`wtype'"' == "pweight" ) local wcode 4
        else {
            di as err "unknown weight type {opt `wtype'}"
            clean_all 198
            exit 198
        }
    }

    * Interestingly, stata allows for rawsum, but someone gave me the
    * idea of implementing a generic -rawstat()- option, so weights are
    * selectively applied to each individual target, if the user so
    * chooses to specify it.

    local wstats: copy local stats
    local wselective 0
    local skipstats percent

    if ( "`rawstat'" != "" ) {
        cap matrix drop wselmat
        foreach var in `targets' {
            gettoken wstat wstats: wstats
            local inraw:    list posof `"`var'"'   in rawstat
            local statskip: list posof `"`wstat'"' in skipstats
            if ( (`inraw' > 0) & (`statskip' == 0) ) {
                local ++wselective
                matrix wselmat = nullmat(wselmat), 1
            }
            else if ( (`inraw' > 0) & (`statskip' > 0) ) {
                disp as err "{opt rawstat} cannot be requested for {opt percent}"
                exit 198
            }
            else {
                matrix wselmat = nullmat(wselmat), 0
            }
        }

        if ( `wselective' == 0 ) {
            disp as err "{bf:Warning:} {opt rawstat} requested but none of the variables are targets"
        }
        else {
            if ( `"`wtype'"' != "" ) {
                disp "{bf:Warning:} 0 or missing weights are dropped for {bf:all} variables."
            }
        }
    }
    else {
        matrix wselmat = J(1, 1, 0)
    }

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "{cmd:_gtools_internal/weights} (debug level `debug_level')"
        disp as txt "{hline 72}"
        disp as txt `""'
        disp as txt `"    wtype:         `wtype'"'
        disp as txt `"    wcode:         `wcode'"'
        disp as txt `"    wstats:        `wstats'"'
        disp as txt `"    wselective:    `wselective'"'
        disp as txt `"    skipstats:     `skipstats'"'
        disp as txt `"    rawstat:       `rawstat'"'
        matrix list wselmat
    }

    * Parse options into scalars, etc. for C
    * --------------------------------------

    * C is great! It's fast, it's...well, it's fast. The compiler is
    * cool too, but it's not the friendliest language to write stuff in.
    * And Stata's C API is limited. It's awesome and amazing that it
    * even exists, to be honest, but the functionality is wanting.
    *
    * Anyway, the easiest way to pass info to and from C is to use
    * scalars and matrices. Moreover, it's easier to define EVERY
    * variable that we could possibly set and read it from C every
    * time vs going through the hassle of writing 16 pairs of if-else
    * statements.
    *
    * Here I initialize all the relevant scalars and such to empty or
    * dummy values as applicable.

    local any_if    = ( "if'"         != "" )
    local verbose   = ( "`verbose'"   != "" )
    local benchmark = ( "`benchmark'" != "" )

    mata: st_numscalar("__gtools_gfile_byvar",  strlen(st_local("gbyvarfile")) + 1)
    mata: st_numscalar("__gtools_gfile_bycol",  strlen(st_local("gbycolfile")) + 1)
    mata: st_numscalar("__gtools_gfile_bynum",  strlen(st_local("gbynumfile")) + 1)

    mata: st_numscalar("__gtools_gfile_topnum", strlen(st_local("gtopnumfile")) + 1)
    mata: st_numscalar("__gtools_gfile_topmat", strlen(st_local("gtopmatfile")) + 1)

    mata: st_numscalar("__gtools_gfile_gregb",    strlen(st_local("gregbfile"))    + 1)
    mata: st_numscalar("__gtools_gfile_gregse",   strlen(st_local("gregsefile"))   + 1)
    mata: st_numscalar("__gtools_gfile_gregvcov", strlen(st_local("gregvcovfile")) + 1)
    mata: st_numscalar("__gtools_gfile_gregclus", strlen(st_local("gregclusfile")) + 1)
    mata: st_numscalar("__gtools_gfile_gregabs",  strlen(st_local("gregabsfile"))  + 1)
    mata: st_numscalar("__gtools_gfile_ghdfeabs", strlen(st_local("ghdfeabsfile")) + 1)

    scalar __gtools_init_targ   = 0
    scalar __gtools_any_if      = `any_if'
    scalar __gtools_verbose     = `verbose'
    scalar __gtools_debug       = `debug_level'
    scalar __gtools_benchmark   = cond(`benchmarklevel' > 0, `benchmarklevel', 0)
    scalar __gtools_keepmiss    = ( "`keepmissing'"  != "" )
    scalar __gtools_missing     = ( "`missing'"      != "" )
    scalar __gtools_unsorted    = ( "`unsorted'"     != "" )
    scalar __gtools_countonly   = ( "`countonly'"    != "" )
    scalar __gtools_seecount    = ( "`seecount'"     != "" )
    scalar __gtools_nomiss      = ( "`exitmissing'"  != "" )
    scalar __gtools_replace     = ( "`replace'"      != "" )
    scalar __gtools_countmiss   = ( "`countmiss'"    != "" )
    scalar __gtools_invertix    = ( "`invertinmata'" == "" )
    scalar __gtools_skipcheck   = ( "`skipcheck'"    != "" )
    scalar __gtools_mlast       = ( "`mlast'"        != "" )
    scalar __gtools_subtract    = ( "`_subtract'"    != "" )
    scalar __gtools_ctolerance  = `_ctolerance'
    scalar __gtools_hash_method = `hashmethod'
    scalar __gtools_weight_code = `wcode'
    scalar __gtools_weight_pos  = 0
    scalar __gtools_weight_sel  = `wselective'
    scalar __gtools_nunique     = ( `:list posof "nunique" in stats' > 0 )

    scalar __gtools_top_nrows       = 0
    scalar __gtools_top_ntop        = 0
    scalar __gtools_top_pct         = 0
    scalar __gtools_top_freq        = 0
    scalar __gtools_top_mataname    = ""
    scalar __gtools_top_matasave    = 0
    scalar __gtools_top_silent      = 0
    scalar __gtools_top_vlab        = 1
    scalar __gtools_top_invert      = 0
    scalar __gtools_top_alpha       = 0
    scalar __gtools_top_miss        = 0
    scalar __gtools_top_groupmiss   = 0
    scalar __gtools_top_other       = 0
    scalar __gtools_top_lmiss       = 0
    scalar __gtools_top_lother      = 0
    scalar __gtools_top_Jmiss       = 0
    scalar __gtools_top_Jother      = 0
    matrix __gtools_contract_which  = J(1, 4, 0)
    matrix __gtools_invert          = 0
    matrix __gtools_weight_smat     = wselmat
    cap matrix drop wselmat

    scalar __gtools_levels_mataname = `""'
    scalar __gtools_levels_matasave = 0
    scalar __gtools_levels_silent   = 0
    scalar __gtools_levels_return   = 1
    scalar __gtools_levels_gen      = 0
    scalar __gtools_levels_replace  = 0

    scalar __gtools_xtile_xvars     = 0
    scalar __gtools_xtile_nq        = 0
    scalar __gtools_xtile_nq2       = 0
    scalar __gtools_xtile_cutvars   = 0
    scalar __gtools_xtile_ncuts     = 0
    scalar __gtools_xtile_qvars     = 0
    scalar __gtools_xtile_gen       = 0
    scalar __gtools_xtile_pctile    = 0
    scalar __gtools_xtile_genpct    = 0
    scalar __gtools_xtile_pctpct    = 0
    scalar __gtools_xtile_altdef    = 0
    scalar __gtools_xtile_missing   = 0
    scalar __gtools_xtile_strict    = 0
    scalar __gtools_xtile_min       = 0
    scalar __gtools_xtile_max       = 0
    scalar __gtools_xtile_method    = 0
    scalar __gtools_xtile_bincount  = 0
    scalar __gtools_xtile__pctile   = 0
    scalar __gtools_xtile_dedup     = 0
    scalar __gtools_xtile_cutifin   = 0
    scalar __gtools_xtile_cutby     = 0
    scalar __gtools_xtile_imprecise = 0
    matrix __gtools_xtile_quantiles = J(1, 1, .)
    matrix __gtools_xtile_cutoffs   = J(1, 1, .)
    matrix __gtools_xtile_quantbin  = J(1, 1, .)
    matrix __gtools_xtile_cutbin    = J(1, 1, .)

    gregress_scalars init
    gstats_scalars   init
    greshape_scalars init

    * Parse glevelsof options
    * -----------------------

    * Again, glevelsof is parsed in the open since I defined the options
    * before moving to capturing each caller's options.

    if ( `"`separate'"' == "" ) local sep `" "'
    else local sep: copy local separate

    if ( `"`colseparate'"' == "" ) local colsep `" | "'
    else local colsep: copy local colseparate

    local numfmt_empty = 0
    if ( `"`numfmt'"' == "" ) {
        local numfmt_empty = 1
        local numfmt `"%.16g"'
    }

    if regexm(`"`numfmt'"', "%([0-9]+)\.([0-9]+)([gf])") {
        local numlen = max(`:di regexs(1)', `:di regexs(2)' + 5) + cond(regexs(3) == "f", 23, 0)
    }
    else if regexm(`"`numfmt'"', "%\.([0-9]+)([gf])") {
        local numlen = `:di regexs(1)' + 5 + cond(regexs(2) == "f", 23, 0)
    }
    else {
        di as err "Number format must be %(width).(digits)(f|g);" ///
                  " e.g. %.16g (default), %20.5f"
        clean_all 198
        exit 198
    }

    scalar __gtools_numfmt_max = `numlen'
    scalar __gtools_numfmt_len = length(`"`numfmt'"')
    scalar __gtools_cleanstr   = ( "`clean'" != "" )
    scalar __gtools_sep_len    = length(`"`sep'"')
    scalar __gtools_colsep_len = length(`"`colsep'"')

    * Parse target names and group fill
    * ---------------------------------

    * tag, gen, and counts are set up as generic options. Here we figure
    * out whether to generate each of them as empty variables or whether
    * to over-write existing variables (if -replace- was specified by
    * the user).

    * confirm new variable `gen_name'
    * local 0 `gen_name'
    * syntax newvarname

    if ( "`tag'" != "" ) {
        gettoken tag_type tag_name: tag
        local tag_name `tag_name'
        local tag_type `tag_type'
        if ( "`tag_name'" == "" ) {
            local tag_name `tag_type'
            local tag_type byte
        }
        cap noi confirm_var `tag_name', `replace'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
        local new_tag = `r(newvar)'
    }

    if ( "`gen'" != "" ) {
        gettoken gen_type gen_name: gen
        local gen_name `gen_name'
        local gen_type `gen_type'
        if ( "`gen_name'" == "" ) {
            local gen_name `gen_type'
            if ( `=_N < maxlong()' ) {
                local gen_type long
            }
            else {
                local gen_type double
            }
        }
        cap noi confirm_var `gen_name', `replace'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
        local new_gen = `r(newvar)'
    }

    * counts is a bit convoluted because it must obey the fill() option.
    * Depending on the set up, we specify whether counts will be filled
    * sequentially 1 / number of groups, whether they will be merged
    * back to the data, or whether only the first entry within a group
    * will be filled.

    scalar __gtools_group_data = 0
    scalar __gtools_group_fill = 0
    scalar __gtools_group_val  = .
    if ( "`counts'" != "" ) {
        {
            gettoken counts_type counts_name: counts
            local counts_name `counts_name'
            local counts_type `counts_type'
            if ( "`counts_name'" == "" ) {
                local counts_name `counts_type'
                if ( `=_N < maxlong()' ) {
                    local counts_type long
                }
                else {
                    local counts_type double
                }
            }
            cap noi confirm_var `counts_name', `replace'
            if ( _rc ) {
                local rc = _rc
                clean_all
                exit `rc'
            }
            local new_counts = `r(newvar)'
        }
        if ( "`fill'" != "" ) {
            if ( "`fill'" == "group" ) {
                scalar __gtools_group_fill = 0
                scalar __gtools_group_val  = .
            }
            else if ( "`fill'" == "data" ) {
                scalar __gtools_group_data = 1
                scalar __gtools_group_fill = 0
                scalar __gtools_group_val  = .
            }
            else {
                cap confirm number `fill'
                cap local fill_value = `fill'
                if ( _rc ) {
                    di as error "'`fill'' found where number expected"
                    clean_all 7
                    exit 7
                }
                * local 0 , fill(`fill')
                * syntax , [fill(real 0)]
                scalar __gtools_group_fill = 1
                scalar __gtools_group_val  = `fill'
            }
        }
    }
    else if ( "`targets'" != "" ) {
        if ( "`fill'" != "" ) {
            if ( "`fill'" == "missing" ) {
                scalar __gtools_group_fill = 1
                scalar __gtools_group_val  = .
            }
            else if ( "`fill'" == "data" ) {
                scalar __gtools_group_data = 1
                scalar __gtools_group_fill = 0
                scalar __gtools_group_val  = .
            }
        }
    }
    else if ( "`fill'" != "" ) {
        di as err "{opt fill} only allowed with option {opt count()} or {opt targets()}"
        clean_all 198
        exit 198
    }

    * Generate new variables
    * ----------------------

    * Here is where we actually generate the variables. If the target
    * already exists we skip it; otherwise we add an empty variable.

    local kvars_group = 0
    scalar __gtools_encode  = 1
    mata:  __gtools_group_targets = J(1, 3, 0)
    mata:  __gtools_group_init    = J(1, 3, 0)
    mata:  __gtools_togen_k = 0

    if ( "`counts'`gen'`tag'" != "" ) {
        local topos 1
        local etargets `gen_name' `counts_name' `tag_name'
        mata: __gtools_togen_types = J(1, `:list sizeof etargets', "")
        mata: __gtools_togen_names = J(1, `:list sizeof etargets', "")

        * 111 = 8
        * 101 = 6
        * 011 = 7
        * 001 = 5
        * 110 = 4
        * 010 = 3
        * 100 = 2
        * 000 = 1

        if ( "`gen'" != "" ) {
            local ++kvars_group
            scalar __gtools_encode = __gtools_encode + 1
            if ( `new_gen' ) {
                mata: __gtools_togen_types[`topos'] = "`gen_type'"
                mata: __gtools_togen_names[`topos'] = "`gen_name'"
                local ++topos
            }
            else {
                mata:  __gtools_group_init[1] = 1
            }
            mata: __gtools_group_targets = J(1, 3, 1)
        }

        if ( "`counts'" != "" ) {
            local ++kvars_group
            scalar __gtools_encode = __gtools_encode + 2
            if ( `new_counts' ) {
                mata: __gtools_togen_types[`topos'] = "`counts_type'"
                mata: __gtools_togen_names[`topos'] = "`counts_name'"
                local ++topos
            }
            else {
                mata:  __gtools_group_init[2] = 1
            }
            mata: __gtools_group_targets[2] = __gtools_group_targets[2] + 1
            mata: __gtools_group_targets[3] = __gtools_group_targets[3] + 1
        }
        else {
            mata: __gtools_group_targets[2] = 0
        }

        if ( "`tag'" != "" ) {
            local ++kvars_group
            scalar __gtools_encode = __gtools_encode + 4
            if ( `new_tag' ) {
                mata: __gtools_togen_types[`topos'] = "`tag_type'"
                mata: __gtools_togen_names[`topos'] = "`tag_name'"
                local ++topos
            }
            else {
                mata:  __gtools_group_init[3] = 1
            }
            mata: __gtools_group_targets[3] = __gtools_group_targets[3] + 1
        }
        else {
            mata: __gtools_group_targets[3] = 0
        }

        qui mata: __gtools_togen_k = sum(__gtools_togen_names :!= missingof(__gtools_togen_names))
        qui mata: __gtools_togen_s = 1::((__gtools_togen_k > 0)? __gtools_togen_k: 1)
        qui mata: (__gtools_togen_k > 0)? st_addvar(__gtools_togen_types[__gtools_togen_s], __gtools_togen_names[__gtools_togen_s]): ""

        local msg "Generated targets"
        gtools_timer info `t98' `"`msg'"', prints(`benchmark')
    }
    else local etargets ""

    scalar __gtools_k_group = `kvars_group'
    mata: st_matrix("__gtools_group_targets", __gtools_group_targets)
    mata: st_matrix("__gtools_group_init",    __gtools_group_init)
    mata: mata drop __gtools_group_targets
    mata: mata drop __gtools_group_init

    * Parse by types
    * --------------

    * Finally parse the by variables We process the set of by variables.
    * differently depending on their type. If any are strings, then we
    * use the spooky hash regardless. If all are numbers, we may use a
    * bijection, which is faster, instead.
    *
    * Here we obtain the number of string variables, the number of
    * numeric variables, and the length of each string variables (to
    * adequately allocate memory internally). For numeric variables
    * we also need the min and the max, but we will find that out
    * internally later on.
    *
    * Last, we parse whether or not to invert the sort orner of a given
    * by variable ("-" preceding it). If option -ds- is passed, then "-"
    * is interpret as the "to" operator in Stata's varlist notation.

    if ( `"`anything'"' != "" ) {
        local clean_anything: copy local anything
        local clean_anything: subinstr local clean_anything "+" " ", all
        if ( strpos(`"`clean_anything'"', "-") & ("`ds'`nods'" == "") ) {
            disp as txt "'-' interpreted as negative; use option -ds- to interpret as varlist"
            disp as txt "(to suppress this warning, use option -nods-)"
        }
        if ( "`ds'" != "" ) {
            local clean_anything `clean_anything'
            if ( "`clean_anything'" == "" ) {
                di as err "Invalid varlist: `anything'"
                clean_all 198
                exit 198
            }
            cap ds `clean_anything'
            if ( _rc ) {
                cap noi ds `clean_anything'
                local rc = _rc
                clean_all `rc'
                exit `rc'
            }
            local clean_anything `r(varlist)'
        }
        else {
            local clean_anything: subinstr local clean_anything "-" " ", all
            local clean_anything `clean_anything'
            if ( "`clean_anything'" == "" ) {
                di as err "Invalid list: '`anything''"
                di as err "Syntax: [+|-]varname [[+|-]varname ...]"
                clean_all 198
                exit 198
            }
            cap ds `clean_anything'
            if ( _rc ) {
                local notfound
                foreach var of local clean_anything {
                    cap ds `var'
                    if ( _rc  ) {
                        local notfound `notfound' `var'
                    }
                }
                if ( `:list sizeof notfound' > 0 ) {
                    if ( `:list sizeof notfound' > 1 ) {
                        di as err "Variables not found: `notfound'"
                    }
                    else {
                        di as err "Variable `notfound' not found"
                    }
                }
                clean_all 111
                exit 111
            }
            qui ds `clean_anything'
            local clean_anything `r(varlist)'
        }
        cap noi check_matsize `clean_anything'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
    }
    if ( "`ds'" == "" ) local nods nods

    local opts `compress' `forcestrl' glevelsof(`glevelsof') `ds'
    cap noi parse_by_types `anything' `ifin', clean_anything(`clean_anything') `opts'
    if ( _rc ) {
        local rc = _rc
        clean_all `rc'
        exit `rc'
    }

    local invert = `r(invert)'
    local byvars = "`r(varlist)'"
    local bynum  = "`r(varnum)'"
    local bystr  = "`r(varstr)'"
    local bystrL = "`r(varstrL)'"
    global GTOOLS_BYNAMES: copy local byvars

    * Unfortunately, the number of by variables we can process is
    * limited by the number of entries we can store in a Stata matrix.
    * We _could_ hack our way around this, but it would be very
    * cumbersome for very little payoff. (Is it that common to request
    * more than 800p by variables, sources, or targets? Or 11,000 in the
    * case of MP?)
    *
    * Anyway, we check whether the largest allowed number of entries
    * in a matrix is at least as large as the number of variables. If
    * it's not, we try to set matsize to that number so we don't get any
    * errors. If we reach Stata's limit then we throw an error and let
    * the user know about this limitation.

    if ( "`byvars'" != "" ) {
        cap noi check_matsize `byvars'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
    }

    if ( "`targets'" != "" ) {
        cap noi check_matsize `targets'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
    }

    if ( "`sources'" != "" ) {
        cap noi check_matsize `sources'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
    }

    if ( inlist("`gfunction'", "levelsof") & ("`byvars'" == "") ) {
        di as err "gfunction(`gfunction') requires at least one variable."
        clean_all 198
        exit 198
    }

    * Parse position of by variables
    * ------------------------------

    if ( "`byvars'" != "" ) {
        cap matrix drop __gtools_strpos
        cap matrix drop __gtools_numpos

        foreach var of local bystr {
            matrix __gtools_strpos = nullmat(__gtools_strpos), ///
                                    `:list posof `"`var'"' in byvars'
        }

        foreach var of local bynum {
            matrix __gtools_numpos = nullmat(__gtools_numpos), ///
                                     `:list posof `"`var'"' in byvars'
        }
    }
    else {
        matrix __gtools_strpos = 0
        matrix __gtools_numpos = 0
    }

    * Parse sources, targets, stats (sources and targets MUST exist!)
    * ---------------------------------------------------------------

    * Here we code the position of each source and each target relative
    * to each source. A single source can be the base of multiple
    * targets. That is, consider:
    *
    *     source1 source2 source3 source4
    *     target1 target2 target3 target4
    *
    * It coult be the case that, for example,
    *
    *     source1 = source3
    *     source2 = source4
    *
    * Hence we pass the variable list as
    *
    *     source1 source3 target1 target2 target3 target4
    *
    * And the source of each target is (1, 2, 1, 2).
    *
    * We also need to encode the stat requested. It's inconsequential
    * for a few groups, but if there are a large number of groups
    * then it's much more efficient to use numbers to determine which
    * statistic to compute than strings.

    matrix __gtools_stats        = 0
    matrix __gtools_pos_targets  = 0
    scalar __gtools_k_vars       = 0
    scalar __gtools_k_targets    = 0
    scalar __gtools_k_stats      = 0

    if ( "`sources'`targets'`stats'" != "" ) {
        if ( "`gfunction'" == "collapse" ) {
            if regexm("`gcollapse'", "^(forceio|switch)") {
                local k_exist k_exist(sources)
            }
            if regexm("`gcollapse'", "^read") {
                local k_exist k_exist(targets)
            }
        }

        parse_targets, sources(`sources') ///
                       targets(`targets') ///
                       stats(`stats')     ///
                       `k_exist' `replace' `keepmissing'

        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }

        if ( "`freq'" != "" ) {
            cap confirm variable `freq'
            if ( _rc ) {
                di as err "Target `freq' has to exist."
                clean_all 198
                exit 198
            }

            cap confirm numeric variable `freq'
            if ( _rc ) {
                di as err "Target `freq' must be numeric."
                clean_all 198
                exit 198
            }

            scalar __gtools_k_targets    = __gtools_k_targets + 1
            scalar __gtools_k_stats      = __gtools_k_stats   + 1
            matrix __gtools_stats        = __gtools_stats,    -14
            matrix __gtools_pos_targets  = __gtools_pos_targets,  0
        }

        local intersection: list __gtools_targets & byvars
        if ( "`intersection'" != "" ) {
            if ( "`replace'" == "" ) {
                di as error "targets in are also in by(): `intersection'"
                error 110
            }
        }

        local extravars `__gtools_sources' `__gtools_targets' `freq'
    }
    else local extravars ""

    local msg "Parsed by variables"
    gtools_timer info `t98' `"`msg'"', prints(`benchmark')

    ***********************************************************************
    *                               Debug!                                *
    ***********************************************************************

    if ( `debug_level' ) {
        disp as txt `""'
        disp as txt "{cmd:_gtools_internal/setup} (debug level `debug_level')"
        disp as txt "{hline 72}"
        disp as txt `""'
        disp as txt `"    sep:                 `sep'        "'
        disp as txt `"    colsep:              `colsep'     "'
        disp as txt `"    numfmt:              `numfmt'     "'
        disp as txt `"    numlen:              `numlen'     "'
        disp as txt `""'
        disp as txt `"    tag_name:            `tag_name'   "'
        disp as txt `"    tag_type:            `tag_type'   "'
        disp as txt `"    gen_name:            `gen_name'   "'
        disp as txt `"    gen_type:            `gen_type'   "'
        disp as txt `"    counts_name:         `counts_name'"'
        disp as txt `"    counts_type:         `counts_type'"'
        disp as txt `""'
        disp as txt `"    clean_anything:      `clean_anything'"'
        disp as txt `"    invert:              `invert'"'
        disp as txt `"    byvars:              `byvars'"'
        disp as txt `"    bynum:               `bynum'"'
        disp as txt `"    bystr:               `bystr'"'
        disp as txt `""'
        disp as txt `"    __gtools_sources:    `__gtools_sources'"'
        disp as txt `"    __gtools_targets:    `__gtools_targets'"'
        disp as txt `"    extravars:           `extravars'"'

        scalar list
        matrix dir
    }

    ***********************************************************************
    *                           Call the plugin                           *
    ***********************************************************************

    local rset = 1
    local opts oncollision(`oncollision')
    if ( "`gfunction'" == "sort" ) {

        * Sorting using plugins internally involves several steps:
        *
        *     1) Make a copy of the data in memory
        *     2) Sort the copy of the data in place
        *     3) Copy the sorted copy back into Stata
        *
        * While step 2, the sort itself, is much faster in C, steps
        * 1 and 3 make it so such an implementation is actually much
        * slower than sorting in Stata. This involves only one step:
        * Sort the copy of the data in place.
        *
        * Hence we use a trick!
        *
        *    1) Generate an index
        *    2) Make a copy of the indexed sort variables
        *    3) Sort the indexed copy
        *    4) Copy the index to Stata
        *    5) Re-arrange the data in place using the index
        *
        * This is still a multi-step process that is not particularly
        * fast. Hence Stata, specially Stata/MP, can often still sort
        * faster (since it's only one step).

        * Andrew Mauer's trick? From ftools
        * ---------------------------------

        local contained 0
        local sortvar : sortedby
        forvalues k = 1 / `:list sizeof byvars' {
            if ( "`:word `k' of `byvars''" == "`:word `k' of `sortvar''" ) {
                local ++contained
            }
        }
        * di "`contained'"

        * Check if already sorted
        if ( "`skipcheck'" == "" ) {
            if ( !`invert' & ("`sortvar'" == "`byvars'") ) {
                if ( "`verbose'" != "" ) di as txt "(already sorted)"
                clean_all 0
                exit 0
            }
            else if ( !`invert' & (`contained' == `:list sizeof byvars') ) {
                * If the first k sorted variables equal byvars, just call sort
                if ( "`verbose'" != "" ) di as txt "(already sorted)"
                sort `byvars', `:disp cond("`bystrL'" == "", "", "stable")'
                clean_all 0
                exit 0
            }
            else if ( "`sortvar'" != "" ) {
                * Andrew Maurer's trick to clear `: sortedby'
                qui set obs `=_N + 1'
                loc sortvar : word 1 of `sortvar'
                loc sortvar_type : type `sortvar'
                loc sortvar_is_str = strpos("`sortvar_type'", "str") == 1

                if ( `sortvar_is_str' ) {
                    qui replace `sortvar' = `"."' in `=_N'
                }
                else {
                    qui replace `sortvar' = 0 in `=_N'
                }
                qui drop in `=_N'
            }
        }
        else {
            if ( "`sortvar'" != "" ) {
                * Andrew Maurer's trick to clear `: sortedby'
                qui set obs `=_N + 1'
                loc sortvar : word 1 of `sortvar'
                loc sortvar_type : type `sortvar'
                loc sortvar_is_str = strpos("`sortvar_type'", "str") == 1

                if ( `sortvar_is_str' ) {
                    qui replace `sortvar' = `"."' in `=_N'
                }
                else {
                    qui replace `sortvar' = 0 in `=_N'
                }
                qui drop in `=_N'
            }
        }

        * Use sortindex for the shuffle
        * -----------------------------

        if ( "`bystrL'" != "" ) {
            disp as txt "({bf:warning}: hashsort with strL variables is {bf:slow})"
        }

        local hopts benchmark(`benchmark') `invertinmata'
        cap noi hashsort_inner `byvars' `etargets', `hopts'
        cap noi rc_dispatch `byvars', rc(`=_rc') `opts'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }

        if ( ("`gen_name'" == "") | ("`sortgen'" == "") ) {
            if ( `invert' ) {
                mata: st_numscalar("__gtools_first_inverted", ///
                                   selectindex(st_matrix("__gtools_invert"))[1])
                if ( `=scalar(__gtools_first_inverted)' > 1 ) {
                    local sortvars ""
                    forvalues i = 1 / `=scalar(__gtools_first_inverted) - 1' {
                        local sortvars `sortvars' `:word `i' of `byvars''
                    }
                    scalar drop __gtools_first_inverted
                    sort `sortvars', `:disp cond("`bystrL'" == "", "", "stable")'
                }
            }
            else {
                sort `byvars', `:disp cond("`bystrL'" == "", "", "stable")'
            }
        }
        else if ( ("`gen_name'" != "") & ("`sortgen'" != "") ) {
            sort `gen_name', `:disp cond("`bystrL'" == "", "", "stable")'
        }

        local msg "Stata reshuffle"
        gtools_timer info `t98' `"`msg'"', prints(`benchmark') off

        if ( `=_N < maxlong()' ) {
            local stype long
        }
        else {
            stype double
        }
        if ( "`sortindex'" != "" ) gen `stype' `sortindex' = _n

        if ( `debug_level' ) {
            disp as txt `""'
            disp as txt "{cmd:_gtools_internal/sort} (debug level `debug_level')"
            disp as txt "{hline 72}"
            disp as txt `""'
            disp as txt `"    contained:         `contained'"'
            disp as txt `"    skipcheck:         `skipcheck'"'
            disp as txt `"    sortvar:           `sortvar'"'
            disp as txt `"    sortvar_type:      `sortvar_type'"'
            disp as txt `"    sortvar_is_str:    `sortvar_is_str'"'
            disp as txt `"    gen_name:          `gen_name'"'
            disp as txt `"    sortgen:           `sortgen'"'
            disp as txt `"    sortindex:         `sortindex'"'
            disp as txt `""'
            disp as txt `"    byvars:            `byvars'"'
            disp as txt `"    etargets:          `etargets'"'
            disp as txt `"    hopts:             `hopts'"'
            disp as txt `""'
        }
    }
    else if ( "`gfunction'" == "collapse" ) {

        * Collapse is a convoluted function. It would be simpler if
        * Stata's C API was nicer, but due to the way it's written,
        * we require a number of workarounds. See gcollapse.ado for
        * details.

        local 0 `gcollapse'
        syntax anything, [st_time(real 0) fname(str) ixinfo(str) merge]
        scalar __gtools_st_time   = `st_time'
        scalar __gtools_used_io   = 0
        scalar __gtools_ixfinish  = 0
        scalar __gtools_J         = _N
        scalar __gtools_init_targ = (`"`ifin'"' != "") & ("`merge'" != "") & ("`init'" == "")
            if ( (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" != "") ) NoInitWarning

        if inlist("`anything'", "forceio", "switch") {
            local extravars `__gtools_sources' `__gtools_sources' `freq'
        }
        if inlist("`anything'", "read") {
            local extravars `: list __gtools_targets - __gtools_sources' `freq'
        }

        local plugvars `byvars' `etargets' `extravars' `ixinfo'
        scalar __gtools_weight_pos  = `:list sizeof plugvars' + 1

        cap noi plugin call gtools_plugin `plugvars' `wvar' `ifin', ///
            collapse `anything' `"`fname'"'

        cap noi rc_dispatch `byvars', rc(`=_rc') `opts'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }

        if ( "`anything'" != "read" ) {
            scalar __gtools_J  = `r_J'
            return scalar N    = `r_N'
            return scalar J    = `r_J'
            return scalar minJ = `r_minJ'
            return scalar maxJ = `r_maxJ'
            local rset = 0
        }

        if ( `=scalar(__gtools_ixfinish)' ) {
            local msg "Switch code runtime"
            gtools_timer info `t98' `"`msg'"', prints(`benchmark')

            qui mata: st_addvar(__gtools_gc_addtypes, __gtools_gc_addvars, 1)
            local msg "Added targets"
            gtools_timer info `t98' `"`msg'"', prints(`benchmark')

            local extravars `__gtools_sources' `__gtools_targets' `freq'
            local plugvars `byvars' `etargets' `extravars' `ixinfo'
            scalar __gtools_weight_pos  = `:list sizeof plugvars' + 1

            cap noi plugin call gtools_plugin `plugvars' `wvar' `ifin', ///
                collapse ixfinish `"`fname'"'
            if ( _rc ) {
                local rc = _rc
                clean_all `rc'
                exit `rc'
            }

            local msg "Finished collapse"
            gtools_timer info `t98' `"`msg'"', prints(`benchmark') off
        }
        else {
            local msg "C plugin runtime"
            gtools_timer info `t98' `"`msg'"', prints(`benchmark') off
        }

        return scalar used_io = `=scalar(__gtools_used_io)'
        local runtxt " (internals)"

        if ( `debug_level' ) {
            disp as txt `""'
            disp as txt "{cmd:_gtools_internal/collapse} (debug level `debug_level')"
            disp as txt "{hline 72}"
            disp as txt `""'
            disp as txt `"    byvars:       `byvars'"'
            disp as txt `"    etargets:     `etargets'"'
            disp as txt `"    extravars:    `extravars'"'
            disp as txt `"    ixinfo:       `ixinfo'"'
            disp as txt `""'
            disp as txt `"    [if] [in]:    `if' `in'"'
            disp as txt `"    wvar:         `wvar'"'
            disp as txt `"    fname:        `fname'"'
            disp as txt `"    anything:     `anything'"'
            disp as txt `""'

            scalar list __gtools_st_time
            scalar list __gtools_used_io
            scalar list __gtools_ixfinish
            scalar list __gtools_J
            scalar list __gtools_init_targ
            scalar list __gtools_weight_pos
            scalar list __gtools_J
        }
    }
    else {

        * The rest of the functions can be easily dispatched using
        * a similar set of steps. Internally:
        *
        *     1. Hash, index
        *     2. Sort indexed hash
        *     3. Determine group sizes and cut points
        *     4. Use index and group info to compute the function
        *
        * NOTE: If there are targets (as with egen, collapse, or generic
        * hash), they are replaced with missing values internally right
        * before writing the output. Special functions tag, group,
        * and count are initialized as well, should they have been
        * requested.

        if ( inlist("`gfunction'", "unique", "egen", "hash") ) {
            local gcall hash
            scalar __gtools_init_targ = (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" == "")
            if ( (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" != "") ) NoInitWarning
        }
        else if ( inlist("`gfunction'",  "reshape") ) {
            local 0: copy local greshape
            syntax anything, xij(str) [j(str) xi(str) File(str) STRing(int 0) DROPMISSing]

            gettoken shape readwrite: anything
            local readwrite `readwrite'
            if !inlist(`"`shape'"', "long", "wide") {
                disp "`shape' unknown: only long and wide are supported"
                exit 198
            }
            if !inlist(`"`readwrite'"', "fwrite", "write", "read") {
                disp "`readwrite' unknown: only fwrite, write, and read are supported"
                exit 198
            }

            if ( inlist(`"`readwrite'"', "fwrite", "write") ) {
                if ( `"`shape'"' == "long" ) {
                    local reshapevars `xi' `xij'
                }
                else {
                    local reshapevars `xij' `xi'
                }
            }
            else {
                local reshapevars `xij' `xi'
            }

            local gcall `gfunction' `readwrite' `"`file'"'

            scalar __gtools_greshape_code = cond(`"`shape'"' == "wide", 2, 1)
            if ( (`"`shape'"' == "wide") | ("`readwrite'" == "read") ) {
                local reshapevars `j' `reshapevars'
            }
            scalar __gtools_greshape_str      = `string'
            scalar __gtools_greshape_kxi      = `:list sizeof xi'
            scalar __gtools_greshape_dropmiss = ( `"`dropmissing'"' != "" )
        }
        else if ( inlist("`gfunction'",  "regress") ) {
            local gcall `gfunction' `"${GTOOLS_GREG_FILE}"'
            local 0: copy local gregress
            // syntax varlist(numeric ts fv), [ /// TODO: ts fv not yet supported!
            syntax varlist(numeric), [       /// TODO: ts fv not yet supported!
                Robust                       /// Robust SE
                cluster(str)                 /// Cluster by varlist
                absorb(varlist)              /// Absorb each var in varlist as FE
                interval(str)                /// Interval for rolling regressions
                window(str)                  /// Window for moving regressions
                hdfetol(real 1e-8)           /// Tolerance for hdfe convergence
                STANdardize                  /// standardize before applying transform
                TRACEiter                    /// trace iteration progress (internal hdfe)
                maxiter(real 100000)         /// maximum number of hdfe iterations
                algorithm(str)               /// alias for method
                method(str)                  /// projection method for hdfe
                                             /// map (method of alternating projections)
                                             /// squarem
                                             /// conjugate gradient|cg (default)
                                             /// it|irons tuck
                noConstant                   /// Whether to add a constant
                                             ///
                ivkendog(int 0)              /// IV endogenous
                ivkexog(int 0)               /// IV exogenous
                ivkz(int 0)                  /// IV instruments
                                             ///
                glmtol(real 1e-8)            /// Tolerance for GLM (IRLS) convergence
                glmiter(int 1000)            /// Max iterations for GLM convergence
                glmfam(str)                  /// GLM family
                glmlink(str)                 /// GLM link function
                                             ///
                mata(str)                    /// save in mata (default)
                GENerate(str)                /// save in varlist
                prefix(str)                  /// save prepending prefix
                PREDict(str)                 /// save fit in `predict'
                resid                        /// save residuals in _resid_`yvarlist'
                RESIDuals(str)               /// save residuals in `residuals'
                replace                      /// Replace targets, if they exist
                noinit                       /// Do not initialize targets with missing values
            ]

            if ( ("`algorithm'" != "") & ("`method'" != "") ) {
                disp as err "gregress: method() is an alias for algorithm(); specify only one"
                clean_all 198
                exit 198
            }
            if ( `"`algorithm'"' == "" ) local algorithm  cg
            if ( `"`method'"'    != "" ) local algorithm: copy local method
            local method: copy local algorithm

            if ( `maxiter' < 1 ) {
                disp as err "gregress: maxiter() must be >= 1"
                clean_all 198
                exit 198
            }

            if ( missing(`maxiter') ) local maxiter 0
            local maxiter = floor(`maxiter')

            if ( lower(`"`method'"') == "map" ) {
                local method_code 1
                local method map
            }
            else if ( lower(`"`method'"') == "squarem" ) {
                local method_code 2
                local method squarem
            }
            else if ( inlist(lower(`"`method'"'), "conjugate gradient", "conjugate_gradient", "cg") ) {
                local method_code 3
                local method cg
            }
            else if ( inlist(lower(`"`method'"'), "irons and tuck", "irons tuck", "irons_tuck", "it") ) {
                local method_code 5
                local method it
            }
            else if ( inlist(lower(`"`method'"'), "bit", "berge_it", "berge it") ) {
                * TODO: gives segfault on some runs last I checked; debug someday.
                * Option is undocumented but I leave it here for myself.
                local method_code 6
                local method bit
            }
            else {
                disp as err "gstats_hdfe: method() must be one of: map, squarem, cg, it"
                clean_all 198
                exit 198
            }

            local ivregress
            if ( `ivkendog' > 0 ) {
                if ( `ivkz' >= `ivkendog' ) {
                    local ivregress ivregress
                }
                else {
                    disp as error "Need at least as many instruments as endogenous variables (received `ivkz' < `ivkendog')"
                    local rc = 198
                    clean_all `rc'
                    exit `rc'
                }
            }
            else if ( `ivkz' > 0 ) {
                disp as error "Detected instruments but no endogenous variables for IV regresssion"
                local rc = 198
                clean_all `rc'
                exit `rc'
            }

            if ( (`"`window'"' != "") & (`"`interval'"' != "") ) {
                disp as err "moving() and window() are mutually exclusive options"
                local rc = 198
                clean_all `rc'
                exit `rc'
            }

            if ( (`"`window'"' != "") | (`"`interval'"' != "") ) {
                if ( `"`window'"'   != "" ) local what window
                if ( `"`interval'"' != "" ) local what interval

                disp as err "option `what'() is planned for the next release"
                local rc = 198
                clean_all `rc'
                exit `rc'

                if ( `"`cluster'"' != "" ) {
                    disp as err "cluster() cannot yet be combined with `what'(); this is planned for the next release"
                    local rc = 198
                    clean_all `rc'
                    exit `rc'
                }

                if ( `"`absorb'"' != "" ) {
                    disp as err "absorb() cannot yet be combined with `what'(); this is planned for the next release"
                    local rc = 198
                    clean_all `rc'
                    exit `rc'
                }
            }

            if ( `"`window'"' != "" ) {
                encode_moving moving regress `interval'
                if ( `r(warn)' ) {
                    disp as txt "{bf:note:} requested window() without a window; will ignore"
                }
                else if ( `r(match)' ) {
                    scalar __gtools_gregress_moving   = `r(scode)'
                    scalar __gtools_gregress_moving_l = `r(lower)'
                    scalar __gtools_gregress_moving_u = `r(upper)'
                }
                else {
                    disp as err "window() incorrectly specified"
                    local rc = 198
                    clean_all `rc'
                    exit `rc'
                }
            }

            local intervalvar
            if ( `"`interval'"' != "" ) {
                encode_range range regress `interval'
                if ( `r(warn)' ) {
                    disp as txt "{bf:note:} requested interval() without an interval; will ignore"
                }
                else if ( `r(match)' & (`"`r(var)'"' == "") ) {
                    disp as err "interval() requires a variable; interval(lower upper varname)"
                    local rc = 198
                    clean_all `rc'
                    exit `rc'
                }
                else if ( `r(match)' ) {
                    scalar __gtools_gregress_range    = 1
                    scalar __gtools_gregress_range_l  = `r(lower)'
                    scalar __gtools_gregress_range_u  = `r(upper)'
                    scalar __gtools_gregress_range_ls = `r(lcode)'
                    scalar __gtools_gregress_range_us = `r(ucode)'
                    local intervalvar `r(var)'
                }
                else {
                    disp as err "interval() incorrectly specified"
                    local rc = 198
                    clean_all `rc'
                    exit `rc'
                }
            }

            * TODO: strL support
            if ( `"`cluster'"' != "" ) {
                GenericParseTypes `cluster', mat(__gtools_gregress_clustyp)
            }

            if ( (`"`cluster'"' == "") & (`"`robust'"' == "") & (`wcode' == 4) ) {
                disp as txt "{bf:note:} robust SE will be computed with pweights"
            }

            if ( (`"`cluster'"' == "") & (`"`robust'"' == "") & (`"`glmfam'"' != "") ) {
                disp as txt "{bf:note:} robust SE will be computed with GLM (`glmfam')"
            }

            if ( (`wcode' == 4) | (`"`glmfam'"' != "") ) {
                local robust robust
            }

            if ( `:list sizeof residuals' > 1 ) {
                disp as err "resid() must specify a single variable name"
                local rc = 198
                clean_all `rc'
                exit `rc'
            }

            if ( `:list sizeof predict' > 1 ) {
                disp as err "predict() must specify a single variable name"
                local rc = 198
                clean_all `rc'
                exit `rc'
            }

            local regressvars `varlist' `cluster' `absorb' `intervalvar'

            scalar __gtools_gregress_hdfemethnm    = cond(`:list sizeof absorb' > 1, "`method'", "direct")
            scalar __gtools_gregress_hdfemethod    = `method_code'
            scalar __gtools_gregress_kvars         = `:list sizeof varlist'
            scalar __gtools_gregress_cons          = `"`constant'"' != "noconstant"
            scalar __gtools_gregress_robust        = `"`robust'"'   != ""
            scalar __gtools_gregress_cluster       = `:list sizeof cluster'
            scalar __gtools_gregress_absorb        = `:list sizeof absorb'
            scalar __gtools_gregress_hdfetol       = `hdfetol'
            scalar __gtools_gregress_hdfemaxiter   = `maxiter'
            scalar __gtools_gregress_hdfetraceiter = "`traceiter'" != ""
            scalar __gtools_gregress_hdfestandard  = "`standardize'" != ""
            scalar __gtools_gregress_glmfam        = `"`glmfam'"' != ""
            scalar __gtools_gregress_glmlogit      = (`"`glmfam'"' == "binomial") & (`"`glmlink'"' == "logit")
            scalar __gtools_gregress_glmpoisson    = (`"`glmfam'"' == "poisson")  & (`"`glmlink'"' == "log")
            scalar __gtools_gregress_glmiter       = `glmiter'
            scalar __gtools_gregress_glmtol        = `glmtol'
            scalar __gtools_gregress_ivreg         = `"`ivregress'"' != ""
            scalar __gtools_gregress_ivkendog      = `ivkendog'
            scalar __gtools_gregress_ivkexog       = `ivkexog'
            scalar __gtools_gregress_ivkz          = `ivkz'

            if ( scalar(__gtools_gregress_glmlogit) ) {
                local Caller Logit
                local caller glogit
            }
            else if ( scalar(__gtools_gregress_glmpoisson) ) {
                local Caller Poisson
                local caller gpoisson
            }
            else if ( scalar(__gtools_gregress_ivreg) ) {
                local Caller IV
                local caller givregress
            }
            else {
                local Caller Regress
                local caller gregress
            }

            if ( scalar(__gtools_gregress_glmfam) & scalar(__gtools_gregress_ivreg) ) {
                disp as err "Parsing error: GLM (`caller') and givregress cannot be run at the same time"
                local rc = 198
                clean_all `rc'
                exit `rc'
            }

            if ( scalar(__gtools_gregress_cluster) > 1 ) {
                disp as txt "({bf:warning}: cluster() with multiple variables is assumed to be nested)"
            }

            if ( scalar(__gtools_gregress_kvars) < 2 ) {
                disp as err "2 or more variables required: depvar indepvar [indepvar ...]"
                local rc = 198
                clean_all `rc'
                exit `rc'
            }

            local zvarlist
            local yxvarlist: copy local varlist
            gettoken yvarlist xvarlist: yxvarlist
            scalar __gtools_gregress_kv = __gtools_gregress_kvars - 1 - __gtools_gregress_ivkz
            if ( scalar(__gtools_gregress_ivreg) ) {
                 local _xvarlist
                 forvalues i = 1 / `=scalar(__gtools_gregress_kv)' {
                     local _xvarlist `_xvarlist' `:word `i' of `xvarlist''
                 }
                 local zvarlist
                 forvalues i = `=scalar(__gtools_gregress_kv) + 1' / `=scalar(__gtools_gregress_kvars) - 1' {
                     local zvarlist `zvarlist' `:word `i' of `xvarlist''
                 }
                 local xvarlist: copy local _xvarlist
            }
            scalar __gtools_gregress_kv = __gtools_gregress_kv + __gtools_gregress_cons * (__gtools_gregress_absorb == 0)

            if ( `"`mata'`generate'`prefix'"' == "" ) {
                scalar __gtools_gregress_savemata = 1
                scalar __gtools_gregress_savemb   = 1
                scalar __gtools_gregress_savemse  = 1
                local saveGregressMata Gtools`Caller'
                mata: `saveGregressMata' = GtoolsRegressOutput()
                mata: `saveGregressMata'.whoami = `"`saveGregressMata'"'
            }
            else {
                if ( `"`mata'"' != "" ) {
                    local 0 `mata'
                    cap noi syntax [namelist(max = 1)], [noB noSE]
                    if ( `"`namelist'"' == "" ) local namelist Gtools`Caller'

                    scalar __gtools_gregress_savemata = 1
                    scalar __gtools_gregress_savemb   = `"`b'"'  != "nob"
                    scalar __gtools_gregress_savemse  = `"`se'"' != "nose"

                    local saveGregressMata `namelist'
                    mata: `saveGregressMata' = GtoolsRegressOutput()
                    mata: `saveGregressMata'.whoami = `"`saveGregressMata'"'
                }

                if ( (`"`generate'"' != "") & (`"`prefix'"' != "") ) {
                    local 0, `generate' `prefix'
                    cap syntax, [b(str) se(str) hdfe(str)]
                    if ( _rc ) {
                        disp as err "cannot specify multiple saves across gen() and prefix()"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }
                }

                if ( `"`generate'"' != "" ) {
                    local 0, `generate'
                    cap noi syntax, [b(str) se(str) hdfe(str)]
                    if ( _rc ) {
                        disp as err "error parsing gen()"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`:list sizeof b' != scalar(__gtools_gregress_kv)) & (`"`b'"' != "") ) {
                        disp as err "number of output variables in gen(b()) does not match number of inputs"
                        if ( scalar(__gtools_gregress_cons) ) {
                            if ( `:list sizeof b' == (scalar(__gtools_gregress_kv) - 1) ) {
                                disp as err "Did you forget the constant?"
                            }
                        }
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`:list sizeof se' != scalar(__gtools_gregress_kv)) & (`"`se'"' != "") ) {
                        disp as err "number of output variables in gen(se()) does not match number of inputs"
                        if ( scalar(__gtools_gregress_cons) ) {
                            if ( `:list sizeof se' == (scalar(__gtools_gregress_kv) - 1) ) {
                                disp as err "Did you forget the constant?"
                            }
                        }
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`"`hdfe'"' != "") & (scalar(__gtools_gregress_absorb) == 0) ) {
                        disp as err "gen(hdfe()) without absorb() just makes a copy of the variables"
                    }
                    else if ( (`:list sizeof hdfe' != scalar(__gtools_gregress_kvars)) & (`"`hdfe'"' != "") ) {
                        disp as err "number of output variables in gen(hdfe()) does not match number of inputs"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( "`replace'" == "" ) {
                        cap noi confirm new var `b' `se' `hdfe'
                        if ( _rc ) {
                            local rc = _rc
                            clean_all `rc'
                            exit `rc'
                        }
                    }

                    local nvar = 0
                    local togen
                    foreach var in `b' `se' `hdfe' {
                        cap confirm new var `var'
                        if ( _rc == 0 ) {
                            local togen `togen' `var'
                            local ++nvar
                        }
                    }

                    scalar __gtools_gregress_savegb    = `"`b'"'    != ""
                    scalar __gtools_gregress_savegse   = `"`se'"'   != ""
                    scalar __gtools_gregress_saveghdfe = `"`hdfe'"' != ""

                    if ( `nvar' > 0 ) {
                        qui mata: (void) st_addvar(J(1, `nvar', `"`:set type'"'), tokens(`"`togen'"'))
                    }
                    local regressvars `regressvars' `b' `se' `hdfe'
                }

                if ( `"`prefix'"' != "" ) {
                    local 0, `prefix'
                    cap noi syntax, [b(str) se(str) hdfe(str)]
                    if ( _rc ) {
                        disp as err "error parsing prefix()"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`:list sizeof b' != 1) & (`"`b'"' != "") ) {
                        disp as err "specify a single prefix in prefix(b())"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`:list sizeof se' != 1) & (`"`se'"' != "") ) {
                        disp as err "specify a single prefix in prefix(se())"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`:list sizeof hdfe' != 1) & (`"`hdfe'"' != "") ) {
                        disp as err "specify a single prefix in prefix(hdfe())"
                        local rc = 198
                        clean_all `rc'
                        exit `rc'
                    }

                    if ( (`"`hdfe'"' != "") & (scalar(__gtools_gregress_absorb) == 0) ) {
                        disp as err "prefix(hdfe()) without absorb() just makes a copy of the variables"
                    }

                    local bvars
                    local sevars
                    if ( `"`hdfe'"' != "" ) {
                        local hdfevars `hdfe'`yvarlist'
                        cap confirm name `hdfe'`yvarlist'
                        if ( _rc ) {
                            disp as err "prefix(hdfe()) results in invalid variable name, `hdfe'`yvarlist'"
                            local rc = 198
                            clean_all `rc'
                            exit `rc'
                        }
                    }

                    if ( scalar(__gtools_gregress_cons) * (scalar(__gtools_gregress_absorb) == 0) ) {
                        local cons cons
                    }
                    else local cons

                    foreach xvar in `xvarlist' `cons' {
                        if ( `"`b'"' != "" ) {
                            local bvars  `bvars' `b'`xvar'
                            cap confirm name `b'`xvar'
                            if ( _rc ) {
                                disp as err "prefix(b()) results in invalid variable name, `b'`xvar'"
                                local rc = 198
                                clean_all `rc'
                                exit `rc'
                            }
                        }
                        if ( `"`se'"' != "" ) {
                            local sevars  `sevars' `se'`xvar'
                            cap confirm name `se'`xvar'
                            if ( _rc ) {
                                disp as err "prefix(se()) results in invalid variable name, `se'`xvar'"
                                local rc = 198
                                clean_all `rc'
                                exit `rc'
                            }
                        }
                        if ( `"`hdfe'"' != "" ) {
                            local hdfevars  `hdfevars' `hdfe'`xvar'
                            cap confirm name `hdfe'`xvar'
                            if ( _rc ) {
                                disp as err "prefix(hdfe()) results in invalid variable name, `hdfe'`xvar'"
                                local rc = 198
                                clean_all `rc'
                                exit `rc'
                            }
                        }
                    }

                    foreach zvar in `zvarlist' {
                        if ( `"`hdfe'"' != "" ) {
                            local hdfevars  `hdfevars' `hdfe'`zvar'
                            cap confirm name `hdfe'`zvar'
                            if ( _rc ) {
                                disp as err "prefix(hdfe()) results in invalid variable name, `hdfe'`zvar'"
                                local rc = 198
                                clean_all `rc'
                                exit `rc'
                            }
                        }
                    }

                    if ( "`replace'" == "" ) {
                        cap noi confirm new var `bvars' `sevars' `hdfevars'
                        if ( _rc ) {
                            local rc = _rc
                            clean_all `rc'
                            exit `rc'
                        }
                    }

                    local nvar = 0
                    local togen
                    foreach var in `bvars' `sevars' `hdfevars' {
                        cap confirm new var `var'
                        if ( _rc == 0 ) {
                            local togen `togen' `var'
                            local ++nvar
                        }
                    }

                    scalar __gtools_gregress_savegb    = `"`b'"'    != ""
                    scalar __gtools_gregress_savegse   = `"`se'"'   != ""
                    scalar __gtools_gregress_saveghdfe = `"`hdfe'"' != ""

                    if ( `nvar' > 0 ) {
                        qui mata: (void) st_addvar(J(1, `nvar', `"`:set type'"'), tokens(`"`togen'"'))
                    }

                    local regressvars `regressvars' `bvars' `sevars' `hdfevars'
                }
            }

            scalar __gtools_gregress_savegresid = `"`resid'`residuals'"' != ""
            if ( scalar(__gtools_gregress_savegresid) ) {
                if ( ("`resid'" != "") & ("`residuals'" != "") ) {
                    disp as txt "warning: option -resid- ignored with option resid()"
                }
                if ( "`residuals'" == "" ) {
                    local residuals _resid_`yvarlist'
                }
                if ( "`replace'" == "" ) {
                    cap noi confirm new var `residuals'
                    if ( _rc ) {
                        local rc = _rc
                        clean_all `rc'
                        exit `rc'
                    }
                }
                else {
                    cap confirm new var `residuals'
                }
                if ( _rc == 0 ) {
                    qui mata: (void) st_addvar(`"`:set type'"', `"`residuals'"')
                }
                local regressvars `regressvars' `residuals'
            }

            scalar __gtools_gregress_savegpred = `"`predict'"' != ""
            if ( scalar(__gtools_gregress_savegpred) ) {
                disp as txt "{bf:Warning}: The behavior of predict() is different cross functions."
                disp as txt "Do not use unless you understand the code and know what it does."
                if ( "`replace'" == "" ) {
                    cap noi confirm new var `predict'
                    if ( _rc ) {
                        local rc = _rc
                        clean_all `rc'
                        exit `rc'
                    }
                }
                else {
                    cap confirm new var `predict'
                }
                if ( _rc == 0 ) {
                    qui mata: (void) st_addvar(`"`:set type'"', `"`predict'"')
                }
                local regressvars `regressvars' `predict'
            }

            * TODO: strL support
            if ( `"`absorb'"' != "" ) {
                local 0: copy local absorb
                syntax varlist, [save(str)]
                local absorb: copy local varlist
                GenericParseTypes `absorb', mat(__gtools_gregress_abstyp)
                scalar __gtools_gregress_savegabs = `"`save'"' != ""
            }

            * ---------------------------
            * TODO: xx What was this for?
            * ---------------------------
            * if ( scalar(__gtools_gregress_savegabs) ) {
            *     if ( "`replace'" == "" ) {
            *         cap noi confirm new var `save'
            *         if ( _rc ) {
            *             local rc = _rc
            *             clean_all `rc'
            *             exit `rc'
            *         }
            *     }
            *     else {
            *         cap confirm new var `save'
            *     }
            *     if ( _rc == 0 ) {
            *         qui mata: (void) st_addvar(`"`:set type'"', `"`save'"')
            *     }
            *     local regressvars `regressvars' `save'
            * }

            if ( `"`saveGregressMata'"' != "" ) {
                mata: `saveGregressMata'.init()
            }

            if ( `wcode' == 3 ) {
                disp as txt "{bf:note:} iweights mimic the behavior of aweights"
            }

            scalar __gtools_init_targ = (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" == "")
            if ( (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" != "") ) NoInitWarning
        }
        else if ( inlist("`gfunction'",  "stats") ) {
            local gcall `gfunction' `"${GTOOLS_GSTATS_FILE}"'
            gettoken gstat gstats: gstats
            cap noi gstats_`gstat' `gstats'
            if ( _rc ) {
                local rc = _rc
                clean_all `rc'
                exit `rc'
            }
            local statvars `varlist'

            * Note: This seems inefficient; if in ought to be done one
            * level above in gstats... not to mention that it will force
            * initializing the targets every time.
            if ( "`gstat'" == "hdfe" ) {
                tempvar touse
                mark `touse' `ifin'
                markout `touse' `__gtools_hdfe_markvars', strok
                local if if `touse'
                mata st_local("ifin", st_local("if") + " " + st_local("in"))
            }

            scalar __gtools_init_targ = (`"`ifin'"' != "") & ("`gstats_replace'" != "") & ("`gstats_init'" == "")
            if ( ("`gstat'" == "winsor") & `:list sizeof gstats_replace_anysrc' & `=scalar(__gtools_init_targ)' ) {
                disp as err "gstats winsor: -replace- with source as target not allowed with if/in"
                clean_all 198
                exit 198
            }

            if ( ("`gstat'" == "transform") & ("`gstats_greedy'" != "") & `:list sizeof gstats_replace_anysrc' & `=scalar(__gtools_init_targ)' ) {
                disp as err "gstats transform: -replace- source as target not allowed with if/in and -nogreedy-"
                clean_all 198
                exit 198
            }

            if ( (`"`ifin'"' != "") & ("`gstats_replace'" != "") & ("`gstats_init'" != "") ) NoInitWarning
        }
        else if ( inlist("`gfunction'",  "contract") ) {
            local 0 `gcontract'
            syntax varlist, contractwhich(numlist)
            local gcall `gfunction'
            local contractvars `varlist'
            mata: st_matrix("__gtools_contract_which", ///
                            strtoreal(tokens(`"`contractwhich'"')))
            local runtxt " (internals)"
        }
        else if ( inlist("`gfunction'",  "levelsof") ) {
            local 0, `glevelsof'
            syntax, [             ///
                noLOCALvar        ///
                freq(str)         ///
                store(str)        ///
                gen(str)          ///
                silent            ///
                MATAsave          ///
                MATAsavename(str) ///
            ]
            local gcall `gfunction'
            scalar __gtools_levels_return = ( `"`localvar'"' == "" )

            if ( "`store'" != "" ) {
                di as err "store() is planned for a future release."
                clean_all 198
                exit 198
            }

            if ( "`freq'" != "" ) {
                di as err "freq() is planned for a future release."
                clean_all 198
                exit 198
            }

            local replace_ `replace'
            local 0 `gen'
            syntax [anything], [replace]

            scalar __gtools_levels_mataname = `"`matasavename'"'
            scalar __gtools_levels_matasave = ( `"`matasave'"' != "" )
            scalar __gtools_levels_silent   = ( `"`silent'"'   != "" )
            scalar __gtools_levels_gen      = ( `"`gen'"'      != "" )
            scalar __gtools_levels_replace  = ( `"`replace'"'  != "" )

            local k1: list sizeof anything
            local k2: list sizeof byvars

            // 1. gen(, replace)  -> replaces existing varlist
            // 2. gen(prefix)     -> generates prefix*
            // 4. gen(newvarlist) -> generates newvarlist

            if ( "`gen'" != "" ) {
                if ( ("`replace'" == "") & (`k1' == 0) ) {
                        disp as err "{opt gen()} requires a prefix, target names, or {opt gen(, replace)}."
                        clean_all 198
                        exit 198
                }

                if ( ("`replace'" != "") & (`k1' > 0) ) {
                    disp as err "{opt gen(, replace)} can only replace the source variables, not arbitrary targets."
                    clean_all 198
                    exit 198
                }

                local level_targets
                if ( `k1' > 0 ) {
                    cap confirm name `anything'
                    if ( _rc ) {
                        disp as err "{opt gen()} must specify a variable name or prefix"
                        clean_all 198
                        exit 198
                    }

                    if ( `k1' > 1 ) {
                        cap assert (`k1') == (`k2')
                        if ( _rc ) {
                            disp as err "{opt gen()} must specify a single prefix or one name per target."
                            clean_all 198
                            exit 198
                        }

                        cap confirm new var `anything'
                        if ( _rc ) {
                            disp as err "{opt gen()} must specify new variable names."
                            clean_all 198
                            exit 198
                        }
                        local level_targets `anything'
                    }
                    else {
                        local level_targets
                        foreach var of varlist `byvars' {
                            local level_targets `level_targets' `anything'`var'
                        }

                        cap confirm new var `level_targets'
                        if ( _rc ) {
                            disp as err "{opt gen()} must specify new variable names."
                            clean_all 198
                            exit 198
                        }
                    }

                    local level_types
                    foreach var of varlist `byvars' {
                        local level_types `level_types' `:type `var''
                    }

                    qui mata: st_addvar(tokens(`"`level_types'"'), tokens(`"`level_targets'"'))
                    qui mata: __gtools_level_targets = tokens(`"`level_targets'"')

                    local plugvars `byvars' `etargets' `extravars'
                    scalar __gtools_levels_gen = `:list sizeof plugvars' + 1
                }
            }

            local 0, `store'
            syntax, [GENerate(str) genpre(str) MATrix(str) replace(str)]

            local 0, `freq'
            syntax, [GENerate(str) MATrix(str) replace(str)]

            * Check which exist (w/replace) and create empty vars
            * Pass to plugin call

            * store(matrix(name)) <- only numeric
            * store(data(varlist)) <- any type; must be same length as by vars
            * store(data prefix(prefix) [truncate]) <- prefix; must be valid stata names
            * freq(matrix(name))
            * freq(mata(name))

            local replace `replace_'
        }
        else if ( inlist("`gfunction'",  "top") ) {
            local 0, `gtop'
            syntax, ntop(real)        ///
                    pct(real)         ///
                    freq(real)        ///
                [                     ///
                    misslab(str)      ///
                    otherlab(str)     ///
                    groupmiss         ///
                    MATAsave          ///
                    MATAsavename(str) ///
                    alpha             ///
                    invert            ///
                    silent            ///
                    noVALUELABels     ///
                ]
            local gcall `gfunction'

            scalar __gtools_top_ntop      = `ntop'
            scalar __gtools_top_pct       = `pct'
            scalar __gtools_top_freq      = `freq'
            scalar __gtools_top_mataname  = `"`matasavename'"'
            scalar __gtools_top_matasave  = ( `"`matasave'"'    != "" )
            scalar __gtools_top_silent    = ( `"`silent'"'      != "" )
            scalar __gtools_top_vlab      = ( `"`valuelabels'"' == "" )
            scalar __gtools_top_invert    = ( `"`invert'"'      != "" )
            scalar __gtools_top_alpha     = ( `"`alpha'"'       != "" )
            scalar __gtools_top_miss      = ( `"`misslab'"'     != "" )
            scalar __gtools_top_groupmiss = ( `"`groupmiss'"'   != "" )
            scalar __gtools_top_other     = ( `"`otherlab'"'    != "" )
            scalar __gtools_top_Jmiss     = 0
            scalar __gtools_top_Jother    = 0
            scalar __gtools_top_lmiss     = length(`"`misslab'"')
            scalar __gtools_top_lother    = length(`"`otherlab'"')
            scalar __gtools_top_nrows     = abs(__gtools_top_ntop) /*
                                          */ + __gtools_top_miss   /*
                                          */ + __gtools_top_other

            cap noi check_matsize, nvars(`=scalar(__gtools_kvars_num)')
            if ( _rc ) {
                local rc = _rc
                clean_all `rc'
                exit `rc'
            }

            local nrows = scalar(__gtools_top_nrows)
        }
        else if ( inlist("`gfunction'",  "quantiles") ) {

            * gquantiles is the only complex function in this portion
            * of the program. While it involves the same initial steps,
            * it also requires additional work. In particular we need
            * run a selection algorithm on the sources to compute the
            * percentiles or xtile.
            *
            * The function does a number of other things, which I will
            * not repeat here. For details see the documentation online:
            *
            *     https://gtools.readthedocs.io/en/latest/usage/gquantiles/index.html
            *
            * In particular, the "examples" section.

            local 0 `gquantiles'
            syntax [name],                    ///
            [                                 ///
                xsources(varlist numeric)     ///
                                              ///
                Nquantiles(real 0)            ///
                                              ///
                Quantiles(numlist)            ///
                cutoffs(numlist)              ///
                                              ///
                quantmatrix(str)              ///
                cutmatrix(str)                ///
                                              ///
                Cutpoints(varname numeric)    ///
                cutquantiles(varname numeric) ///
                                              ///
                pctile(name)                  ///
                GENp(name)                    ///
                BINFREQvar(name)              ///
                replace                       ///
                                              ///
                returnlimit(real 1001)        ///
                dedup                         ///
                cutifin                       ///
                cutby                         ///
                _pctile                       ///
                binfreq                       ///
                method(int 0)                 ///
                XMISSing                      ///
                ALTdef                        ///
                strict                        ///
                minmax                        ///
            ]

            local gcall `gfunction'
            local xvars `namelist'     ///
                        `pctile'       ///
                        `binfreqvar'   ///
                        `genp'         ///
                        `cutpoints'    ///
                        `cutquantiles' ///
                        `xsources'

            ***************************
            *  quantiles and cutoffs  *
            ***************************

            * First we need to parse quantmatrix and cutmatrix to find
            * out how many quantiles or cutoffs we may have.

            if ( "`quantmatrix'" != "" ) {
                if ( "`quantiles'" != "" ) {
                    disp as err "Specify only one of quantiles() or quantmatrix()"
                    clean_all 198
                    exit 198
                }

                tempname m c r
                mata: `m' = st_matrix("`quantmatrix'")
                mata: `c' = cols(`m')
                mata: `r' = rows(`m')
                cap mata: assert(min((`c', `r')) == 1)
                if ( _rc ) {
                    disp as err "quantmatrix() must be a N by 1 or 1 by N matrix."
                    clean_all 198
                    exit 198
                }

                cap mata: assert(all(`m' :> 0) & all(`m' :< 100))
                if ( _rc ) {
                    disp as err "quantmatrix() must contain all values" ///
                                " strictly between 0 and 100"
                    clean_all 198
                    exit 198
                }
                mata: st_local("xhow_nq2", strofreal(max((`c', `r')) > 0))
                mata: st_matrix("__gtools_xtile_quantiles", rowshape(`m', 1))
                mata: st_numscalar("__gtools_xtile_nq2", max((`c', `r')))
            }
            else {
                local xhow_nq2 = ( `:list sizeof quantiles' > 0 )
                scalar __gtools_xtile_nq2 = `:list sizeof quantiles'
            }

            if ( "`cutmatrix'" != "" ) {
                if ( "`cutoffs'" != "" ) {
                    disp as err "Specify only one of cutoffs() or cutmatrix()"
                    clean_all 198
                    exit 198
                }

                tempname m c r
                mata: `m' = st_matrix("`cutmatrix'")
                mata: `c' = cols(`m')
                mata: `r' = rows(`m')
                cap mata: assert(min((`c', `r')) == 1)
                if ( _rc ) {
                    disp as err "cutmatrix() must be a N by 1 or 1 by N matrix."
                    clean_all 198
                    exit 198
                }
                mata: st_local("xhow_cuts", strofreal(max((`c', `r')) > 0))
                mata: st_matrix("__gtools_xtile_cutoffs", rowshape(`m', 1))
                mata: st_numscalar("__gtools_xtile_ncuts", max((`c', `r')))
            }
            else {
                local xhow_cuts = ( `:list sizeof cutoffs' > 0 )
                scalar __gtools_xtile_ncuts = `:list sizeof cutoffs'
            }

            ******************************
            *  Rest of quantile parsing  *
            ******************************

            * Make sure cutoffs/quantiles are correctly requested (can
            * only specify 1 method!)

            local xhow_nq      = ( `nquantiles' > 0 )
            local xhow_cutvars = ( `:list sizeof cutpoints'    > 0 )
            local xhow_qvars   = ( `:list sizeof cutquantiles' > 0 )
            local xhow_total   = `xhow_nq'      ///
                               + `xhow_nq2'     ///
                               + `xhow_cuts'    ///
                               + `xhow_cutvars' ///
                               + `xhow_qvars'

            local early_rc = 0
            if ( "`_pctile'" != "" ) {
                if ( `nquantiles' > `returnlimit' ) {
                    di as txt "Warning: {opt nquantiles()} > returnlimit"     ///
                              " (`nquantiles' > `returnlimit')."              ///
                        _n(1) "Will not store return values beyond"           ///
                              " `returnlimit'. Try {opt pctile()}"            ///
                        _n(1) "(Note: you can also pass {opt returnlimit(.)}" ///
                              " but that is very slow.)"
                }

                if ( `:list sizeof quantiles' > `returnlimit' ) {
                    di as txt "Warning: # quantiles in"                       ///
                              " {opt quantiles()} > returnlimit"              ///
                              " (`:list sizeof quantiles' > `returnlimit')."  ///
                        _n(1) "Will not store return values beyond"           ///
                              " `returnlimit'. Try {opt pctile()}"            ///
                        _n(1) "(Note: you can also pass {opt returnlimit(.)}" ///
                              " but that is very slow.)"
                }

                if ( `:list sizeof cutoffs' > `returnlimit' ) {
                    di as txt "Warning: # of cutoffs in"                      ///
                              " {opt cutoffs()} > returnlimit"                ///
                              " (`:list sizeof cutoffs' > `returnlimit')."    ///
                        _n(1) "Will not store return values beyond"           ///
                              " `returnlimit'. Try {opt pctile()}"            ///
                        _n(1) "(Note: you can also pass {opt returnlimit(.)}" ///
                              " but that is very slow.)"
                }
            }

            if ( `xhow_total' == 0 ) {
                local nquantiles = 2
            }
            else if (`xhow_total' > 1) {
                if (  `nquantiles'    >  0  ) local olist "`olist' nquantiles()"
                if ( "`quantiles'"    != "" ) local olist "`olist', quantiles()"
                if ( "`quantmatrix'"  != "" ) local olist "`olist', quantmatrix()"
                if ( "`cutpoints'"    != "" ) local olist "`olist', cutpoints()"
                if ( "`cutmatrix'"    != "" ) local olist "`olist', cutmatrix()"
                if ( "`cutquantiles'" != "" ) local olist "`olist', cutquantiles()"
                if ( "`cutoffs'"      != "" ) local olist "`olist', cutoffs()"
                di as err "Specify only one of: `olist'"
                local early_rc = 198
            }

            if ( `xhow_nq' & (`nquantiles' < 2) ) {
                di as err "{opt nquantiles()} must be greater than or equal to 2"
                local early_rc = 198
            }

            foreach quant of local quantiles {
                if ( `quant' < 0 ) | ( `quant' > 100 ) {
                    di as err "{opt quantiles()} must all be strictly" ///
                              " between 0 and 100"
                    local early_rc = 198
                }
                if ( `quant' == 0 ) | ( `quant' == 100 ) {
                    di as err "{opt quantiles()} cannot be 0 or 100" ///
                              " (note: try passing option {opt minmax})"
                    local early_rc = 198
                }
            }

            local xgen_ix  = ( "`namelist'"   != "" )
            local xgen_p   = ( "`pctile'"     != "" )
            local xgen_gp  = ( "`genp'"       != "" )
            local xgen_bf  = ( "`binfreqvar'" != "" )
            local xgen_tot = `xgen_p' + `xgen_gp' + `xgen_bf'

            local xgen_required = `xhow_cutvars' + `xhow_qvars'
            local xgen_any      = `xgen_ix' | `xgen_p' | `xgen_gp' | `xgen_bf'
            if ( (`xgen_required' > 0) & !(`xgen_any') ) {
                if ( "`cutpoints'"    != "" ) local olist "cutpoints()"
                if ( "`cutquantiles'" != "" ) local olist "cutquantiles()"
                di as err "Option {opt `olist'} requires xtile or pctile"
                local early_rc = 198
            }

            local xbin_any = ("`binfreq'" != "") & ("`binfreqvar'" == "")
            if ( (`xgen_required' > 0) & `xbin_any' ) {
                if ( "`cutpoints'"    != "" ) local olist "cutpoints()"
                if ( "`cutquantiles'" != "" ) local olist "cutquantiles()"
                di as err "{opt binfreq} not allowed with {opt `olist'};" ///
                          " try {opth binfreq(newvarname)}"
                local early_rc = 198
            }

            if ( ("`cutoffs'" != "") & ("`binfreq'" == "") & !(`xgen_any') ) {
                di as err "Nothing to do: Option {opt cutoffs()} requires" ///
                          " {opt binfreq}, {opt xtile}, or {opt pctile}"
                local early_rc = 198
            }

            local xgen_maxdata = `xgen_p' | `xgen_gp' | `xgen_bf'
            if ( (`nquantiles' > `=_N + 1') & `xgen_maxdata' ) {
                di as err "{opt nquantiles()} must be less than or equal to" ///
                          " `=_N +1' (# obs + 1) with {opt pctile()} or {opt binfreq()}"
                local early_rc = 198
            }

            if ( (`=scalar(__gtools_xtile_nq2)' > `=_N') & `xgen_maxdata' ) {
                di as err "Number of {opt quantiles()} must be"  ///
                          " less than or equal to `=_N' (# obs)" ///
                          " with options {opt pctile()} or {opt binfreq()}"
                local early_rc = 198
            }

            if ( (`=scalar(__gtools_xtile_ncuts)' > `=_N') & `xgen_maxdata' ) {
                di as err "Number of {opt cutoffs()} must be "   ///
                          " less than or equal to `=_N' (# obs)" ///
                          " with options {opt pctile()} or {opt binfreq()}"
                local early_rc = 198
            }

            if ( `early_rc' ) {
                clean_all `early_rc'
                exit `early_rc'
            }

            scalar __gtools_xtile_xvars    = `:list sizeof xsources'

            scalar __gtools_xtile_nq       = `nquantiles'
            scalar __gtools_xtile_cutvars  = `:list sizeof cutpoints'
            scalar __gtools_xtile_qvars    = `:list sizeof cutquantiles'

            scalar __gtools_xtile_gen      = `xgen_ix'
            scalar __gtools_xtile_pctile   = `xgen_p'
            scalar __gtools_xtile_genpct   = `xgen_gp'
            scalar __gtools_xtile_pctpct   = `xgen_bf'

            scalar __gtools_xtile_altdef   = ( "`altdef'"   != "" )
            scalar __gtools_xtile_missing  = ( "`xmissing'" != "" )
            scalar __gtools_xtile_strict   = ( "`strict'"   != "" )
            scalar __gtools_xtile_min      = ( "`minmax'"   != "" )
            scalar __gtools_xtile_max      = ( "`minmax'"   != "" )
            scalar __gtools_xtile_method   = `method'
            scalar __gtools_xtile_bincount = ( "`binfreq'" != "" )
            scalar __gtools_xtile__pctile  = ( "`_pctile'" != "" )
            scalar __gtools_xtile_dedup    = ( "`dedup'"   != "" )
            scalar __gtools_xtile_cutifin  = ( "`cutifin'" != "" )
            scalar __gtools_xtile_cutby    = ( "`cutby'"   != "" )

            cap noi check_matsize, nvars(`=scalar(__gtools_xtile_nq2)')
            if ( _rc ) {
                local rc = _rc
                di as err _n(1) "Note: bypass matsize and specify quantiles" ///
                                " using a variable via {opt cutquantiles()}"
                clean_all `rc'
                exit `rc'
            }

            cap noi check_matsize, nvars(`=scalar(__gtools_xtile_ncuts)')
            if ( _rc ) {
                local rc = _rc
                di as err _n(1) "Note: bypass matsize and specify cutoffs" ///
                                " using a variable via {opt cutpoints()}"
                clean_all `rc'
                exit `rc'
            }

            * I don't think it's possible to preserve numerical precision
            * with numlist. And I asked...
            *
            * https://stackoverflow.com/questions/47336278
            * https://www.statalist.org/forums/forum/general-stata-discussion/general/1418513
            *
            * Hance I should have added other ways to request quantiles:
            *
            *     - cutquantiles
            *     - quantmatrix
            *
            * and other ways to request cut points:
            *
            *     - cutoffs
            *     - cutmatrix

            scalar __gtools_xtile_imprecise = 0
            matrix __gtools_xtile_quantbin  = ///
                J(1, cond(`xhow_nq2',  `=scalar(__gtools_xtile_nq2)',   1), 0)
            matrix __gtools_xtile_cutbin    = ///
                J(1, cond(`xhow_cuts', `=scalar(__gtools_xtile_ncuts)', 1), 0)

            if ( `xhow_nq2' & ("`quantiles'" != "") & ("`quantmatrix'" == "") ) {
                matrix __gtools_xtile_quantiles = ///
                    J(1, cond(`xhow_nq2',  `=scalar(__gtools_xtile_nq2)',   1), 0)

                local k = 0
                foreach quant of numlist `quantiles' {
                    local ++k
                    matrix __gtools_xtile_quantiles[1, `k'] = `quant'
                    if ( strpos("`quant'", ".") & (length("`quant'") >= 13) & ("`altdef'" == "") ) {
                        scalar __gtools_xtile_imprecise = 1
                    }
                }
                if ( `=scalar(__gtools_xtile_imprecise)' ) {
                    disp as err "Warning: Loss of numerical precision"    ///
                                " with option {opth quantiles(numlist)}." ///
                          _n(1) "Stata's numlist truncates decimals with" ///
                                " more than 13 significant digits."       ///
                          _n(1) "Consider using {cmd:altdef} or "         ///
                                " {opth quantmatrix(name)}."
                }
            }

            if ( `xhow_cuts'  & ("`cutoffs'" != "") & ("`cutmatrix'" == "") ) {
                matrix __gtools_xtile_cutoffs = ///
                    J(1, cond(`xhow_cuts', `=scalar(__gtools_xtile_ncuts)', 1), 0)

                local k = 0
                foreach cut of numlist `cutoffs' {
                    local ++k
                    matrix __gtools_xtile_cutoffs[1, `k'] = `cut'
                    if ( strpos("`cut'", ".") & (length("`cut'") >= 13) ) {
                        scalar __gtools_xtile_imprecise = 1
                    }
                }
                if ( `=scalar(__gtools_xtile_imprecise)' ) {
                    disp as err "Warning: Loss of numerical precision"    ///
                                " with option {opth cutoffs(numlist)}."   ///
                          _n(1) "Stata's numlist truncates decimals with" ///
                                " more than 13 significant digits."       ///
                          _n(1) "Consider using {cmd:altdef} or "         ///
                                " {opth cutmatrix(name)}."
                }
            }

            * So, I don't really know why I imposed this restriction or
            * why I thought it was a good idea. If you request binfreq
            * you should get the matrix, and you should only not get it
            * if the number of quantiles is not allowed by matsize...
            * But throughout the code I consistently only allow either
            * binfreq OR binfreqvar!

            local xbin_any = ("`binfreq'" != "") & ("`binfreqvar'" == "")
            if ( (`nquantiles' > 0) & `xbin_any' ) {
                cap noi check_matsize, nvars(`=`nquantiles' - 1')
                if ( _rc ) {
                    local rc = _rc
                    di as err _n(1) "Note: You can bypass matsize and" ///
                                    " save binfreq to a variable via binfreq()"
                    clean_all `rc'
                    exit `rc'
                }
                matrix __gtools_xtile_quantbin = ///
                    J(1, max(`=scalar(__gtools_xtile_nq2)', `nquantiles' - 1), 0)
                local __gtools_xtile_nq_extra bin
            }
            else if ( "`binfreq'" != "" ) {
                disp as txt "(option binfreq ignored)"
            }

            if ( (`nquantiles' > 0) & ("`_pctile'" != "") ) {
                cap noi check_matsize, nvars(`=`nquantiles' - 1')
                if ( _rc ) {
                    local rc = _rc
                    di as err _n(1) "Note: You can bypass matsize and" ///
                                    " save quantiles to a variable via pctile()"
                    clean_all `rc'
                    exit `rc'
                }
                matrix __gtools_xtile_quantiles = ///
                    J(1, max(`=scalar(__gtools_xtile_nq2)', `nquantiles' - 1), 0)
                local __gtools_xtile_nq_extra `__gtools_xtile_nq_extra' quantiles
            }
            else if ( (`=scalar(__gtools_xtile_nq2)' > 0) & ("`_pctile'" != "") ) {
                * matsize for nq2 was already checked
            }
            else if ( "`_pctile'" != "" ) {
                disp as txt "(option _pctile ignored)"
            }

            scalar __gtools_xtile_size = `nquantiles'
            scalar __gtools_xtile_size = ///
                max(__gtools_xtile_size, __gtools_xtile_nq2 + 1)
            scalar __gtools_xtile_size = ///
                max(__gtools_xtile_size, __gtools_xtile_ncuts + 1)
            scalar __gtools_xtile_size = ///
                max(__gtools_xtile_size, cond(__gtools_xtile_cutvars, `=_N+1', 1))
            scalar __gtools_xtile_size = ///
                max(__gtools_xtile_size, cond(__gtools_xtile_qvars,   `=_N+1', 1))

            local toadd 0
            qui mata: __gtools_xtile_addlab = J(1, 0, "")
            qui mata: __gtools_xtile_addnam = J(1, 0, "")
            foreach xgen in xgen_ix xgen_p xgen_gp xgen_bf {
                if ( ``xgen'' > 0 ) {
                    if ( "`xgen'" == "xgen_ix" ) {
                        if ( `=scalar(__gtools_xtile_size)' < maxbyte() ) {
                            local qtype byte
                        }
                        else if ( `=scalar(__gtools_xtile_size)' < maxint() ) {
                            local qtype int
                        }
                        else if ( `=scalar(__gtools_xtile_size)' < maxlong() ) {
                            local qtype long
                        }
                        else local qtype double
                        local qvar `namelist'
                    }
                    else {
                        if ( "`:type `xsources''" == "double" ) local qtype double
                        else local qtype: set type

                        if ( "`xgen'" == "xgen_p"  ) local qvar `pctile'
                        if ( "`xgen'" == "xgen_gp" ) local qvar `genp'
                        if ( "`xgen'" == "xgen_bf" ) {
                            if ( "`wvar'" == "" ) {
                                if ( `=_N' < maxbyte() ) {
                                    local qtype byte
                                }
                                else if ( `=_N' < maxint() ) {
                                    local qtype int
                                }
                                else if ( `=_N' < maxlong() ) {
                                    local qtype long
                                }
                                else local qtype double
                            }
                            else local qtype double
                            local qvar `binfreqvar'
                        }
                    }
                    cap confirm new var `qvar'
                    if ( _rc & ("`replace'" == "") ) {
                        di as err "Variable `qvar' exists with no replace."
                        clean_all 198
                        exit 198
                    }
                    else if ( _rc & ("`replace'" != "") & ("`init'" == "") ) {
                        qui replace `qvar' = .
                    }
                    else if ( _rc == 0 ) {
                        local ++toadd
                        mata: __gtools_xtile_addlab = __gtools_xtile_addlab, "`qtype'"
                        mata: __gtools_xtile_addnam = __gtools_xtile_addnam, "`qvar'"
                    }
                }
            }

            if ( `toadd' > 0 ) {
                qui mata: st_addvar(__gtools_xtile_addlab, __gtools_xtile_addnam)
            }

            * This is superseded by the replace qvar above:
            * scalar __gtools_init_targ = (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" == "")
            if ( (`"`ifin'"' != "") & ("`replace'" != "") & ("`init'" != "") ) NoInitWarning

            local msg "Parsed quantiles and added targets"
            gtools_timer info `t98' `"`msg'"', prints(`benchmark')
        }
        else local gcall `gfunction'

        local plugvars `byvars' `etargets' `extravars' `level_targets'
        local plugvars `plugvars' `statvars' `contractvars' `xvars'
        local plugvars `plugvars' `reshapevars' `regressvars'

        scalar __gtools_weight_pos = `:list sizeof plugvars' + 1
        cap noi plugin call gtools_plugin `plugvars' `wvar' `ifin', `gcall'
        local rc = _rc
        cap noi rc_dispatch `byvars', rc(`=_rc') `opts'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }

        local msg "C plugin runtime"
        gtools_timer info `t98' `"`msg'"', prints(`benchmark') off

        if ( `debug_level' ) {
            disp as txt `""'
            disp as txt "{cmd:_gtools_internal/`gfunction'} (debug level `debug_level')"
            disp as txt "{hline 72}"
            disp as txt `""'
            disp as txt `"    gcall:            `gcall'"'
            disp as txt `""'
            disp as txt `"    contractvars:     `contractvars'"'
            disp as txt `"    statvars:         `statvars'"'
            disp as txt `""'
            disp as txt `"    nolocalvar:       `nolocalvar'"'
            disp as txt `"    freq:             `freq'"'
            disp as txt `"    store:            `store'"'
            disp as txt `""'
            disp as txt `"    ntop:             `ntop'"'
            disp as txt `"    pct:              `pct'"'
            disp as txt `"    freq:             `freq'"'
            disp as txt `"    misslab:          `misslab'"'
            disp as txt `"    otherlab:         `otherlab'"'
            disp as txt `"    groupmiss:        `groupmiss'"'
            disp as txt `"    nrows:            `nrows'"'
            disp as txt `""'
            disp as txt `"    xvars:            `xvars'"'
            disp as txt `"    xsources:         `xsources'"'
            disp as txt `"    nquantiles:       `nquantiles'"'
            disp as txt `"    quantiles:        `quantiles'"'
            disp as txt `"    cutoffs:          `cutoffs'"'
            disp as txt `"    quantmatrix:      `quantmatrix'"'
            disp as txt `"    cutmatrix:        `cutmatrix'"'
            disp as txt `"    cutpoints:        `cutpoints'"'
            disp as txt `"    cutquantiles:     `cutquantiles'"'
            disp as txt `"    pctile:           `pctile'"'
            disp as txt `"    genp:             `genp'"'
            disp as txt `"    binfreqvar:       `binfreqvar'"'
            disp as txt `"    replace:          `replace'"'
            disp as txt `"    returnlimit:      `returnlimit'"'
            disp as txt `"    dedup:            `dedup'"'
            disp as txt `"    cutifin:          `cutifin'"'
            disp as txt `"    cutby:            `cutby'"'
            disp as txt `"    _pctile:          `_pctile'"'
            disp as txt `"    binfreq:          `binfreq'"'
            disp as txt `"    method:           `method'"'
            disp as txt `"    xmissing:         `xmissing'"'
            disp as txt `"    altdef:           `altdef'"'
            disp as txt `"    strict:           `strict'"'
            disp as txt `"    minmax:           `minmax'"'
            disp as txt `""'
            disp as txt `"    xhow_nq:          `xhow_nq'"'
            disp as txt `"    xhow_cutvars:     `xhow_cutvars'"'
            disp as txt `"    xhow_qvars:       `xhow_qvars'"'
            disp as txt `"    xhow_total:       `xhow_total'"'
            disp as txt `"    xhow_cuts:        `xhow_cuts'"'
            disp as txt `"    xhow_nq2:         `xhow_nq2'"'
            disp as txt `"    xgen_ix:          `xgen_ix'"'
            disp as txt `"    xgen_p:           `xgen_p'"'
            disp as txt `"    xgen_gp:          `xgen_gp'"'
            disp as txt `"    xgen_bf:          `xgen_bf'"'
            disp as txt `"    xgen_tot:         `xgen_tot'"'
            disp as txt `"    xgen_required:    `xgen_required'"'
            disp as txt `"    xgen_any:         `xgen_any'"'
            disp as txt `"    xbin_any:         `xbin_any'"'
            disp as txt `"    xgen_maxdata:     `xgen_maxdata'"'
            disp as txt `""'

            cap matrix list __gtools_contract_which
            cap matrix list __gtools_xtile_cutoffs
            cap matrix list __gtools_xtile_quantbin
            cap matrix list __gtools_xtile_cutbin
            cap matrix list __gtools_xtile_quantiles

            cap scalar list __gtools_top_nrows
            cap scalar list __gtools_top_ntop
            cap scalar list __gtools_top_pct
            cap scalar list __gtools_top_freq
            cap scalar list __gtools_top_mataname
            cap scalar list __gtools_top_matasave
            cap scalar list __gtools_top_silent
            cap scalar list __gtools_top_vlab
            cap scalar list __gtools_top_invert
            cap scalar list __gtools_top_alpha
            cap scalar list __gtools_top_miss
            cap scalar list __gtools_top_groupmiss
            cap scalar list __gtools_top_other
            cap scalar list __gtools_top_lmiss
            cap scalar list __gtools_top_lother
            cap scalar list __gtools_top_Jmiss
            cap scalar list __gtools_top_Jother

            cap scalar list __gtools_xtile_xvars
            cap scalar list __gtools_xtile_nq
            cap scalar list __gtools_xtile_nq2
            cap scalar list __gtools_xtile_cutvars
            cap scalar list __gtools_xtile_qvars
            cap scalar list __gtools_xtile_gen
            cap scalar list __gtools_xtile_ncuts
            cap scalar list __gtools_xtile_pctile
            cap scalar list __gtools_xtile_genpct
            cap scalar list __gtools_xtile_pctpct
            cap scalar list __gtools_xtile_altdef
            cap scalar list __gtools_xtile_missing
            cap scalar list __gtools_xtile_strict
            cap scalar list __gtools_xtile_min
            cap scalar list __gtools_xtile_max
            cap scalar list __gtools_xtile_method
            cap scalar list __gtools_xtile_bincount
            cap scalar list __gtools_xtile__pctile
            cap scalar list __gtools_xtile_dedup
            cap scalar list __gtools_xtile_cutifin
            cap scalar list __gtools_xtile_cutby
            cap scalar list __gtools_xtile_imprecise
            cap scalar list __gtools_xtile_size
            cap scalar list __gtools_weight_pos
        }
    }

    local msg "Internal gtools runtime`runtxt'"
    gtools_timer info `t99' `"`msg'"', prints(`benchmark') off

    * Return values
    * -------------

    * generic
    if ( `rset' ) {
        return scalar N     = `r_N'
        return scalar J     = `r_J'
        return scalar minJ  = `r_minJ'
        return scalar maxJ  = `r_maxJ'
    }

    return scalar kvar  = `=scalar(__gtools_kvars)'
    return scalar knum  = `=scalar(__gtools_kvars_num)'
    return scalar kint  = `=scalar(__gtools_kvars_int)'
    return scalar kstr  = `=scalar(__gtools_kvars_str)'
    return scalar kstrL = `=scalar(__gtools_kvars_strL)'

    return local byvars = "`byvars'"
    return local bynum  = "`bynum'"
    return local bystr  = "`bystr'"

    * gstats
    if ( inlist("`gfunction'",  "stats") ) {
        return scalar gstats_winsor_cutlow  = __gtools_winsor_cutl
        return scalar gstats_winsor_cuthigh = __gtools_winsor_cuth

        if ( `=scalar(__gtools_gstats_code)' == 2 ) {
            if ( `=scalar(__gtools_summarize_matasave)' ) {
                mata: `GstatsMataSave' = __gstats_summarize_results()
                disp as txt _n "(note: raw results saved in `GstatsMataSave';" /*
                            */ " see {stata mata `GstatsMataSave'.desc()})"
            }
            else {
                mata: (void) __gstats_summarize_results()
                cap mata: mata drop `GstatsMataSave'
            }
        }

        tempname ghdfeabsmatrix
        if ( `=scalar(__gtools_gstats_code)' == 4 ) {
            return scalar hdfe_nonmiss = `=scalar(__gtools_hdfe_nonmiss)'
            if ( ("`byvars'" != "") & `=scalar(__gtools_hdfe_matasave)' ) {

                mata: `=scalar(__gtools_hdfe_mataname)' = GtoolsByLevels()
                mata: `=scalar(__gtools_hdfe_mataname)'.whoami = st_strscalar("__gtools_hdfe_mataname")
                mata: `=scalar(__gtools_hdfe_mataname)'.caller = "gstats hdfe"
                mata: `=scalar(__gtools_hdfe_mataname)'.read(`""', 0)

                mata: `ghdfeabsmatrix' = GtoolsReadMatrix(st_local("ghdfeabsfile"), /*
                    */ 1 + st_numscalar("__gtools_hdfe_absorb"), `=scalar(__gtools_hdfe_mataname)'.J)
                mata: `=scalar(__gtools_hdfe_mataname)'.nj = `ghdfeabsmatrix'[1, .]'
                mata: `=scalar(__gtools_hdfe_mataname)'.njabsorb = colshape( /*
                    */ `ghdfeabsmatrix'[2::rows(`ghdfeabsmatrix'), .], st_numscalar("__gtools_hdfe_absorb"))

                disp as txt "(note: by() info saved in `=scalar(__gtools_hdfe_mataname)';" /*
                    */ " see {stata mata `=scalar(__gtools_hdfe_mataname)'.desc()})"
            }
            else if ( ("`byvars'" == "") & `=scalar(__gtools_hdfe_matasave)' ) {
                disp as txt "(warning: matasave() without by() is ignored)"
            }

            return local  hdfe_method   = "`=scalar(__gtools_hdfe_methodname)'"
            return scalar hdfe_saveinfo = 0
            return scalar hdfe_saveabs  = 0
            if ( "`byvars'" == "" ) {
                return scalar hdfe_saveabs = 1
                return matrix hdfe_nabsorb = __gtools_hdfe_nabsorb

                return scalar hdfe_saveinfo = 1
                if ( "`=scalar(__gtools_hdfe_methodname)'" == "direct" ) {
                    return scalar hdfe_iter  = 1
                    return scalar hdfe_feval = 1
                }
                else {
                    return scalar hdfe_iter  = __gtools_hdfe_iter
                    return scalar hdfe_feval = __gtools_hdfe_feval
                }
            }
        }

        if ( `=scalar(__gtools_summarize_pooled)' ) {
            return local statvars: copy local statvars
        }

        return scalar gstats_summarize_pooled    = __gtools_summarize_pooled
        return scalar gstats_summarize_normal    = __gtools_summarize_normal
        return scalar gstats_summarize_detail    = __gtools_summarize_detail
        return scalar gstats_summarize_tabstat   = __gtools_summarize_tabstat

        return scalar gstats_summarize_N         = __gtools_summarize_N
        return scalar gstats_summarize_sum_w     = __gtools_summarize_sum_w
        return scalar gstats_summarize_sum       = __gtools_summarize_sum
        return scalar gstats_summarize_mean      = __gtools_summarize_mean
        return scalar gstats_summarize_min       = __gtools_summarize_min
        return scalar gstats_summarize_max       = __gtools_summarize_max
        return scalar gstats_summarize_Var       = __gtools_summarize_Var
        return scalar gstats_summarize_sd        = __gtools_summarize_sd
        return scalar gstats_summarize_p1        = __gtools_summarize_p1
        return scalar gstats_summarize_p5        = __gtools_summarize_p5
        return scalar gstats_summarize_p10       = __gtools_summarize_p10
        return scalar gstats_summarize_p25       = __gtools_summarize_p25
        return scalar gstats_summarize_p50       = __gtools_summarize_p50
        return scalar gstats_summarize_p75       = __gtools_summarize_p75
        return scalar gstats_summarize_p90       = __gtools_summarize_p90
        return scalar gstats_summarize_p95       = __gtools_summarize_p95
        return scalar gstats_summarize_p99       = __gtools_summarize_p99
        return scalar gstats_summarize_skewness  = __gtools_summarize_skewness
        return scalar gstats_summarize_kurtosis  = __gtools_summarize_kurtosis
        return scalar gstats_summarize_smallest1 = __gtools_summarize_smallest1
        return scalar gstats_summarize_smallest2 = __gtools_summarize_smallest2
        return scalar gstats_summarize_smallest3 = __gtools_summarize_smallest3
        return scalar gstats_summarize_smallest4 = __gtools_summarize_smallest4
        return scalar gstats_summarize_largest4  = __gtools_summarize_largest4
        return scalar gstats_summarize_largest3  = __gtools_summarize_largest3
        return scalar gstats_summarize_largest2  = __gtools_summarize_largest2
        return scalar gstats_summarize_largest1  = __gtools_summarize_largest1
    }

    * levelsof
    if ( inlist("`gfunction'", "levelsof", "top") & `=scalar(__gtools_levels_return)' ) {
        cap disp `"`vals'"'
        if ( _rc ) {
            error _rc
        }
        return local levels: copy local vals
        return local sep:    copy local sep
        return local colsep: copy local colsep
    }

    if ( inlist("`gfunction'", "levelsof") ) {
        if ( `=scalar(__gtools_levels_matasave)' ) {
            mata: `=scalar(__gtools_levels_mataname)' = GtoolsByLevels()
            mata: `=scalar(__gtools_levels_mataname)'.whoami = st_strscalar("__gtools_levels_mataname")
            mata: `=scalar(__gtools_levels_mataname)'.caller = "glevelsof"
            mata: `=scalar(__gtools_levels_mataname)'.read( /*
                */ st_numscalar("__gtools_levels_silent")? `""': (`numfmt_empty'? "%16.0g": `"`numfmt'"'), 1)

            disp as txt "(note: raw levels saved in `=scalar(__gtools_levels_mataname)';" /*
                */ " see {stata mata `=scalar(__gtools_levels_mataname)'.desc()})"
        }
    }

    * top matrix
    if ( inlist("`gfunction'", "top") ) {
        if ( `=scalar(__gtools_top_matasave)' ) {
            mata: `=scalar(__gtools_top_mataname)' = GtoolsByLevels()
            mata: `=scalar(__gtools_top_mataname)'.whoami = st_strscalar("__gtools_top_mataname")
            mata: `=scalar(__gtools_top_mataname)'.caller = "gtop"

            mata: `=scalar(__gtools_top_mataname)'.read( /*
                */ st_numscalar("__gtools_top_silent")? `""': `"`numfmt'"', /*
                */ st_numscalar("__gtools_top_vlab"))

            c_local _post_msg_gtop_matanote /*
                */ (note: raw levels saved in `=scalar(__gtools_top_mataname)'; /*
                */  see {stata mata `=scalar(__gtools_top_mataname)'.desc()})

            mata `=scalar(__gtools_top_mataname)'.toplevels = GtoolsReadMatrix( /*
                */ st_local("gtopmatfile"),              /*
                */ st_numscalar("__gtools_top_nrows"), 5)
        }
        else {
            if ( `=scalar(__gtools_top_ntop)' > `c(matsize)' ) {
                c_local _post_msg_gtop_matawarn /*
                    */ {bf:performance warning:} # levels > matsize /*
                    */  (`=scalar(__gtools_top_ntop)' > `c(matsize)'); try option -mata-
            }

            mata __gtools_top_matrix = GtoolsReadMatrix( /*
                */ st_local("gtopmatfile"),              /*
                */ st_numscalar("__gtools_top_nrows"), 5)

            mata __gtools_top_num = GtoolsReadMatrix(  /*
                */ st_local("gtopnumfile"),            /*
                */ st_numscalar("__gtools_top_ntop"), /*
                */ st_numscalar("__gtools_kvars_num"))
        }

        return scalar alpha  = __gtools_top_alpha
        return scalar ntop   = __gtools_top_ntop
        return scalar nrows  = __gtools_top_nrows
        return scalar Jmiss  = __gtools_top_Jmiss
        return scalar Jother = __gtools_top_Jother

        * return matrix toplevels = __gtools_top_matrix
        * return matrix numlevels = __gtools_top_num
    }

    * regress results
    if ( inlist("`gfunction'", "regress") ) {
        if ( scalar(__gtools_gregress_savemata) ) {
            mata: `saveGregressMata'.readMatrices()
            mata: `saveGregressMata'.ByLevels = GtoolsByLevels()
            mata: `saveGregressMata'.ByLevels.whoami = "ByLevels"
            mata: `saveGregressMata'.ByLevels.caller = `"`caller'"'
            mata: `saveGregressMata'.ByLevels.read("%16.0g", 1)
            c_local saveGregressMata: copy local saveGregressMata
            disp as txt "Results in `saveGregressMata'; see {stata mata `saveGregressMata'.desc()}"
        }
    }

    * quantile info
    if ( inlist("`gfunction'", "quantiles") ) {
        return local  quantiles    = "`quantiles'"
        return local  cutoffs      = "`cutoffs'"
        return local  nqextra      = "`__gtools_xtile_nq_extra'"
        return local  Nxvars       = scalar(__gtools_xtile_xvars)

        return scalar min          = scalar(__gtools_xtile_min)
        return scalar max          = scalar(__gtools_xtile_max)
        return scalar method_ratio = scalar(__gtools_xtile_method)
        return scalar imprecise    = scalar(__gtools_xtile_imprecise)

        return scalar nquantiles   = scalar(__gtools_xtile_nq)
        return scalar nquantiles2  = scalar(__gtools_xtile_nq2)
        return scalar ncutpoints   = scalar(__gtools_xtile_cutvars)
        return scalar ncutoffs     = scalar(__gtools_xtile_ncuts)
        return scalar nquantpoints = scalar(__gtools_xtile_qvars)

        return matrix quantiles_used     = __gtools_xtile_quantiles
        return matrix quantiles_bincount = __gtools_xtile_quantbin
        return matrix cutoffs_used       = __gtools_xtile_cutoffs
        return matrix cutoffs_bincount   = __gtools_xtile_cutbin
    }

    return matrix invert = __gtools_invert
    clean_all 0
    exit 0
end

***********************************************************************
*                              hashsort                               *
***********************************************************************

capture program drop hashsort_inner
program hashsort_inner, sortpreserve
    syntax varlist [in], benchmark(int) [invertinmata]
    cap noi plugin call gtools_plugin `varlist' `_sortindex' `in', hashsort
    if ( _rc ) exit _rc
    if ( "`invertinmata'" != "" ) {
        mata: st_store(., "`_sortindex'", invorder(st_data(., "`_sortindex'")))
    }
    * else {
    *     mata: st_store(., "`_sortindex'", st_data(., "`_sortindex'"))
    * }

    c_local r_N    = `r_N'
    c_local r_J    = `r_J'
    c_local r_minJ = `r_minJ'
    c_local r_maxJ = `r_maxJ'

    local msg "C plugin runtime"
    gtools_timer info ${GTOOLS_T98} `"`msg'"', prints(`benchmark')
end

***********************************************************************
*                               Cleanup                               *
***********************************************************************

capture program drop clean_all
program clean_all
    args rc
    if ( `"`rc'"' == "" ) local rc = 0

    foreach f of global GTOOLS_TEMPFILES_INTERNAL {
        cap erase `"${GTOOLS_TEMPDIR}/`f'"'
    }
    global GTOOLS_TEMPFILES_INTERNAL
    global GTOOLS_TEMPFILES_INTERNAL_I

    set varabbrev ${GTOOLS_USER_INTERNAL_VARABBREV}
    global GTOOLS_USER_INTERNAL_VARABBREV
    global GTOOLS_GREG_FILE
    global GTOOLS_GREGB_FILE
    global GTOOLS_GREGSE_FILE
    global GTOOLS_GREGVCOV_FILE
    global GTOOLS_GREGCLUS_FILE
    global GTOOLS_GREGABS_FILE
    global GTOOLS_GHDFEABS_FILE
    global GTOOLS_GSTATS_FILE
    global GTOOLS_BYVAR_FILE
    global GTOOLS_BYCOL_FILE
    global GTOOLS_BYNUM_FILE
    global GTOOLS_GTOPNUM_FILE
    global GTOOLS_GTOPMAT_FILE
    global GTOOLS_BYNAMES

    cap scalar drop __gtools_gfile_byvar
    cap scalar drop __gtools_gfile_bycol
    cap scalar drop __gtools_gfile_bynum
    cap scalar drop __gtools_gfile_topnum
    cap scalar drop __gtools_gfile_topmat
    cap scalar drop __gtools_gfile_gregb
    cap scalar drop __gtools_gfile_gregse
    cap scalar drop __gtools_gfile_gregclus
    cap scalar drop __gtools_gfile_gregabs
    cap scalar drop __gtools_gfile_hdfeabs
    cap scalar drop __gtools_init_targ
    cap scalar drop __gtools_any_if
    cap scalar drop __gtools_verbose
    cap scalar drop __gtools_debug
    cap scalar drop __gtools_benchmark
    cap scalar drop __gtools_countonly
    cap scalar drop __gtools_seecount
    cap scalar drop __gtools_unsorted
    cap scalar drop __gtools_invertix
    cap scalar drop __gtools_nomiss
    cap scalar drop __gtools_keepmiss
    cap scalar drop __gtools_missing
    cap scalar drop __gtools_hash
    cap scalar drop __gtools_encode
    cap scalar drop __gtools_replace
    cap scalar drop __gtools_countmiss
    cap scalar drop __gtools_skipcheck
    cap scalar drop __gtools_mlast
    cap scalar drop __gtools_subtract
    cap scalar drop __gtools_ctolerance
    cap scalar drop __gtools_hash_method
    cap scalar drop __gtools_weight_code
    cap scalar drop __gtools_weight_pos
    cap scalar drop __gtools_weight_sel
    cap scalar drop __gtools_nunique

    cap scalar drop __gtools_top_nrows
    cap scalar drop __gtools_top_ntop
    cap scalar drop __gtools_top_pct
    cap scalar drop __gtools_top_freq
    cap scalar drop __gtools_top_mataname
    cap scalar drop __gtools_top_matasave
    cap scalar drop __gtools_top_silent
    cap scalar drop __gtools_top_vlab
    cap scalar drop __gtools_top_invert
    cap scalar drop __gtools_top_alpha
    cap scalar drop __gtools_top_miss
    cap scalar drop __gtools_top_groupmiss
    cap scalar drop __gtools_top_other
    cap scalar drop __gtools_top_lmiss
    cap scalar drop __gtools_top_lother
    cap scalar drop __gtools_top_Jmiss
    cap scalar drop __gtools_top_Jother
    cap matrix drop __gtools_contract_which

    cap scalar drop __gtools_levels_mataname
    cap scalar drop __gtools_levels_matasave
    cap scalar drop __gtools_levels_silent
    cap scalar drop __gtools_levels_return
    cap scalar drop __gtools_levels_gen
    cap scalar drop __gtools_levels_replace

    cap scalar drop __gtools_xtile_xvars
    cap scalar drop __gtools_xtile_nq
    cap scalar drop __gtools_xtile_nq2
    cap scalar drop __gtools_xtile_cutvars
    cap scalar drop __gtools_xtile_ncuts
    cap scalar drop __gtools_xtile_qvars
    cap scalar drop __gtools_xtile_gen
    cap scalar drop __gtools_xtile_pctile
    cap scalar drop __gtools_xtile_genpct
    cap scalar drop __gtools_xtile_pctpct
    cap scalar drop __gtools_xtile_altdef
    cap scalar drop __gtools_xtile_missing
    cap scalar drop __gtools_xtile_strict
    cap scalar drop __gtools_xtile_min
    cap scalar drop __gtools_xtile_max
    cap scalar drop __gtools_xtile_method
    cap scalar drop __gtools_xtile_bincount
    cap scalar drop __gtools_xtile__pctile
    cap scalar drop __gtools_xtile_dedup
    cap scalar drop __gtools_xtile_cutifin
    cap scalar drop __gtools_xtile_cutby
    cap scalar drop __gtools_xtile_imprecise
    cap matrix drop __gtools_xtile_quantiles
    cap matrix drop __gtools_xtile_cutoffs
    cap matrix drop __gtools_xtile_quantbin
    cap matrix drop __gtools_xtile_cutbin
    cap scalar drop __gtools_xtile_size

    cap scalar drop __gtools_kvars
    cap scalar drop __gtools_kvars_num
    cap scalar drop __gtools_kvars_int
    cap scalar drop __gtools_kvars_str
    cap scalar drop __gtools_kvars_strL

    cap scalar drop __gtools_group_data
    cap scalar drop __gtools_group_fill
    cap scalar drop __gtools_group_val

    cap scalar drop __gtools_cleanstr
    cap scalar drop __gtools_sep_len
    cap scalar drop __gtools_colsep_len
    cap scalar drop __gtools_numfmt_len
    cap scalar drop __gtools_numfmt_max

    cap scalar drop __gtools_k_vars
    cap scalar drop __gtools_k_targets
    cap scalar drop __gtools_k_stats
    cap scalar drop __gtools_k_group

    cap scalar drop __gtools_st_time
    cap scalar drop __gtools_used_io
    cap scalar drop __gtools_ixfinish
    cap scalar drop __gtools_J

    cap matrix drop __gtools_weight_smat
    cap matrix drop __gtools_invert
    cap matrix drop __gtools_bylens
    cap matrix drop __gtools_strL
    cap matrix drop __gtools_numpos
    cap matrix drop __gtools_strpos

    cap matrix drop __gtools_group_targets
    cap matrix drop __gtools_group_init

    cap matrix drop __gtools_stats
    cap matrix drop __gtools_pos_targets

    gregress_scalars drop
    gstats_scalars   drop
    greshape_scalars drop `_keepgreshape'

    * NOTE(mauricio): You had the urge to make sure you were dropping
    * variables at one point. Don't. This is fine for gquantiles but not so
    * with gegen or gcollapse.  In the case of gcollapse, if the user ran w/o
    * fast then they were willing to leave the data in a bad stata in case
    * there was an error. In the casae of gegen, the main variable is a dummy
    * that is renamed later on.

    if ( `rc' ) {
        cap mata: st_dropvar(__gtools_xtile_addnam)
        cap mata: st_dropvar(__gtools_level_targets)
        * cap mata: st_dropvar(__gtools_togen_names[__gtools_togen_s])
        * cap mata: st_dropvar(__gtools_gc_addvars)
    }

    cap mata: mata drop __gtools_togen_k
    cap mata: mata drop __gtools_togen_s

    cap mata: mata drop __gtools_togen_types
    cap mata: mata drop __gtools_togen_names

    cap mata: mata drop __gtools_xtile_addlab
    cap mata: mata drop __gtools_xtile_addnam

    cap mata: mata drop __gtools_level_targets

    cap timer off   $GTOOLS_T99
    cap timer clear $GTOOLS_T99

    cap timer off   $GTOOLS_T98
    cap timer clear $GTOOLS_T98

    global GTOOLS_T99
    global GTOOLS_T98
end

***********************************************************************
*                           Parse by types                            *
***********************************************************************

capture program drop parse_by_types
program parse_by_types, rclass
    syntax [anything] [if] [in], [clean_anything(str) compress forcestrl glevelsof(str) ds]

    mata st_local("ifin", st_local("if") + " " + st_local("in"))
    if ( "`anything'" == "" ) {
        matrix __gtools_invert = 0
        matrix __gtools_bylens = 0
        matrix __gtools_strL   = 0

        return local invert  = 0
        return local varlist = ""
        return local varnum  = ""
        return local varstr  = ""
        return local varstrL = ""

        scalar __gtools_kvars      = 0
        scalar __gtools_kvars_int  = 0
        scalar __gtools_kvars_num  = 0
        scalar __gtools_kvars_str  = 0
        scalar __gtools_kvars_strL = 0

        exit 0
    }

    cap matrix drop __gtools_invert
    cap matrix drop __gtools_bylens
    cap matrix drop __gtools_strL

    * Parse whether to invert sort order
    * ----------------------------------

    local parse    `anything'
    local varlist  ""
    local skip   = 0
    local invert = 0
    if ( strpos("`anything'", "-") & ("`ds'" == "") ) {
        while ( trim("`parse'") != "" ) {
            gettoken var parse: parse, p(" -+")
            if inlist("`var'", "-", "+") {
                local skip   = 1
                local invert = ( "`var'" == "-" )
            }
            else {
                cap ds `var'
                if ( _rc ) {
                    local rc = _rc
                    di as err "Variable '`var'' does not exist."
                    di as err "Syntax: [+|-]varname [[+|-]varname ...]"
                    clean_all `rc'
                    exit `rc'
                }
                if ( `skip' ) {
                    local skip = 0
                    foreach var in `r(varlist)' {
                        matrix __gtools_invert = nullmat(__gtools_invert), ///
                                                 `invert'
                    }
                }
                else {
                    foreach var in `r(varlist)' {
                        matrix __gtools_invert = nullmat(__gtools_invert), 0
                    }
                }
                local varlist `varlist' `r(varlist)'
            }
        }
    }
    else {
        local varlist `clean_anything'
        matrix __gtools_invert = J(1, max(`:list sizeof varlist', 1), 0)
    }

    * Compress strL variables if requested
    * ------------------------------------

    * gcollapse, gcontract, greshape, need to write to variables,
    * and so cannot support strL variables

    local GTOOLS_CALLER $GTOOLS_CALLER
    local GTOOLS_STRL   gcollapse gcontract greshape hashsort
    local GTOOLS_STRL_FAIL: list GTOOLS_CALLER in GTOOLS_STRL

    * glevelsof, gen() needs to write to variables, and so cannot
    * support strL variables

    local varlist_  `varlist'
    local anything_ `anything'
    local 0, `glevelsof'
    syntax, [             ///
        noLOCALvar        ///
        freq(str)         ///
        store(str)        ///
        gen(str)          ///
        silent            ///
        MATAsave          ///
        MATAsavename(str) ///
    ]
    local varlist  `varlist_'
    local anything `anything_'

    if ( `"`gen'"' != "" ) {
        local GTOOLS_CALLER "`GTOOLS_CALLER', gen()"
        local GTOOLS_STRL_FAIL = 1
    }

    * Any strL?
    local varstrL ""
    if ( "`varlist'" != "" ) {
        cap confirm variable `varlist'
        if ( _rc ) {
            di as err "{opt varlist} requried but received: `varlist'"
            exit 198
        }

        foreach byvar of varlist `varlist' {
            if regexm("`:type `byvar''", "str([1-9][0-9]*|L)") {
                if (regexs(1) == "L") {
                    local varstrL `varstrL' `byvar'
                }
            }
        }
    }

    local need_compress = `GTOOLS_STRL_FAIL' | (`c(stata_version)' < 14.1)
    if ( ("`varstrL'" != "") & `need_compress' & ("`compress'" != "") ) {
        qui compress `varstrL', nocoalesce
    }

    local varstrL ""
    if ( "`varlist'" != "" ) {
        cap confirm variable `varlist'
        if ( _rc ) {
            di as err "{opt varlist} requried but received: `varlist'"
            exit 198
        }

        foreach byvar of varlist `varlist' {
            if regexm("`:type `byvar''", "str([1-9][0-9]*|L)") {
                if (regexs(1) == "L") {
                    local varstrL `varstrL' `byvar'
                }
            }
        }
    }

    local cpass = cond("`GTOOLS_CALLER'" == "gduplicates", "gtools(compress)", "compress")
    if ( ("`varstrL'" != "") & `need_compress' & ("`compress'" != "") ) {
        if ( `GTOOLS_STRL_FAIL' ) {
            disp as err _n(1) "{cmd:`GTOOLS_CALLER'} does not support strL variables. I tried"         ///
                        _n(1) ""                                                                       ///
                        _n(1) "    {stata compress `varstrL'}"                                         ///
                        _n(1) ""                                                                       ///
                        _n(1) "But these variables could not be recast as str#. This limitation comes" ///
                        _n(1) "from the Stata Plugin Interface, which does not allow writing to strL"  ///
                        _n(1) "variables from a plugin."
        }
        else if ( `c(stata_version)' < 14.1 ) {
            disp as err _n(1) "gtools for Stata 13 and earlier does not support strL variables. I tried"            ///
                        _n(1) ""                                                                                    ///
                        _n(1) "    {stata compress `varstrL'}"                                                      ///
                        _n(1) ""                                                                                    ///
                        _n(1) "But these variables could not be compressed as str#. Please note {cmd:gcollapse},"   ///
                        _n(1) " {cmd:gcontract}, {cmd:greshape}, and {cmd:hashsort} do not support strL variables." ///
                        _n(1) "Further, binary strL variables are not yet supported in any Stata version."          ///
                        _n(1) ""                                                                                    ///
                        _n(1) "However, if your strL variables do not contain binary data, gtools 0.14"             ///
                        _n(1) "and above can read strL variables in Stata 14 or later."
        }
        exit 17004
    }
    else if ( ("`varstrL'" != "") & `need_compress' ) {
        if ( `GTOOLS_STRL_FAIL' ) {
            disp as err _n(1) "{cmd:`GTOOLS_CALLER'} does not support strL variables. If your strL variables are str#, try" ///
                        _n(1) ""                                                                                            ///
                        _n(1) "    {stata compress `varstrL'}"                                                              ///
                        _n(1) ""                                                                                            ///
                        _n(1) "or passing {opt `cpass'} to {opt `GTOOLS_CALLER'}. If this does not work or if you have"     ///
                        _n(1) "have binary data, you will not be able to use {opt `GTOOLS_CALLER'}. This limitation"        ///
                        _n(1) "comes from the Stata Plugin Interface, which does not allow writing to"                      ///
                        _n(1) "strL variables from a plugin."
        }
        else if ( `c(stata_version)' < 14.1 ) {
            disp as err _n(1) "gtools for Stata 13 and earlier does not support strL variables. If your"                          ///
                        _n(1) "strL variables are string-only, try"                                                               ///
                        _n(1) ""                                                                                                  ///
                        _n(1) "    {stata compress `varstrL'}"                                                                    ///
                        _n(1) ""                                                                                                  ///
                        _n(1) "or passing {opt `cpass'} to {opt `GTOOLS_CALLER'}. Please note {cmd:gcollapse}, {cmd:gcontract}, " ///
                        _n(1) "{cmd:greshape}, and {cmd:hashsort} do not support strL variables in any version. Further, binary"  ///
                        _n(1) "strL variables are not yet supported in any Stata version."                                        ///
                        _n(1) ""                                                                                                  ///
                        _n(1) "However, if your strL variables do not contain binary data, gtools"                                ///
                        _n(1) "0.14 and above can read strL variables in Stata 14 or later."
        }
        exit 17002
    }
    else if ( ("`varstrL'" != "") & (`c(stata_version)' >= 14.1) & ("`forcestrl'" == "") ) {
        scalar __gtools_k_strL = `:list sizeof varstrL'
        cap noi plugin call gtools_plugin `varstrL', checkstrL
        if ( _rc ) {
            cap scalar drop __gtools_k_strL
            disp as err _n(1) "gtools does not yet support binary data in strL variables."
            if ( strpos(lower("`c(os)'"), "windows") ) {
                disp as txt                                                                                    ///
                      _n(1) "On some Windows systems Stata detects binary data in strL variables even"         ///
                      _n(1) "when there is none. You can try the experimental option {opt forcestrl} to skip"  ///
                      _n(1) "the binary data check. {opt Forcing gtools to work with binary data gives wrong}" ///
                      _n(1) "results, so only use this option if you are certain your strL variables"          ///
                      _n(1) "do no contain binary data."
            }
            exit 17005
        }
        cap scalar drop __gtools_k_strL
        * disp as txt "(note: performance with strL variables is not optimized)"
    }
    else if ( ("`varstrL'" != "") & ("`forcestrl'" == "") ) {
        disp as err _n(1) "gtools failed to parse strL variables."
        exit 17006
    }

    tempvar strlen
    if ( "`varstrL'" != "" ) qui gen long `strlen' = .

    * Check how many of each variable type we have
    * --------------------------------------------

    local kint  = 0
    local knum  = 0
    local kstr  = 0
    local kstrL = 0
    local kvars = 0

    local varint  ""
    local varnum  ""
    local varstr  ""
    local varstrL ""

    if ( "`varlist'" != "" ) {
        cap confirm variable `varlist'
        if ( _rc ) {
            di as err "{opt varlist} requried but received: `varlist'"
            exit 198
        }

        foreach byvar of varlist `varlist' {
            local ++kvars
            if inlist("`:type `byvar''", "byte", "int", "long") {
                local ++kint
                local ++knum
                local varint `varint' `byvar'
                local varnum `varnum' `byvar'
                matrix __gtools_strL   = nullmat(__gtools_strL),   0
                matrix __gtools_bylens = nullmat(__gtools_bylens), 0
            }
            else if inlist("`:type `byvar''", "float", "double") {
                local ++knum
                local varnum `varnum' `byvar'
                matrix __gtools_strL   = nullmat(__gtools_strL),   0
                matrix __gtools_bylens = nullmat(__gtools_bylens), 0
            }
            else {
                local ++kstr
                local varstr `varstr' `byvar'
                if regexm("`:type `byvar''", "str([1-9][0-9]*|L)") {
                    if (regexs(1) == "L") {
                        local ++kstrL
                        local varstrL `varstrL' `byvar'
                        qui replace `strlen' = length(`byvar')
                        qui sum `strlen', meanonly
                        matrix __gtools_strL   = nullmat(__gtools_strL), 1
                        matrix __gtools_bylens = nullmat(__gtools_bylens), ///
                                                 `=r(max) + 1'
                    }
                    else {
                        matrix __gtools_strL   = nullmat(__gtools_strL), 0
                        matrix __gtools_bylens = nullmat(__gtools_bylens), ///
                                                 `:di regexs(1)'
                    }
                }
                else {
                    di as err "variable `byvar' has unknown type" ///
                              " '`:type `byvar'''"
                    exit 198
                }
            }
        }

        cap assert `kvars' == `:list sizeof varlist'
        if ( _rc ) {
            di as err "Error parsing syntax call; variable list was:" ///
                _n(1) "`anything'"
            exit 198
        }
    }

    * Parse which hashing strategy to use
    * -----------------------------------

    scalar __gtools_kvars      = `kvars'
    scalar __gtools_kvars_int  = `kint'
    scalar __gtools_kvars_num  = `knum'
    scalar __gtools_kvars_str  = `kstr'
    scalar __gtools_kvars_strL = `kstrL'

    * Return hash info
    * ----------------

    return local invert  = `invert'
    return local varlist = "`varlist'"
    return local varnum  = "`varnum'"
    return local varstr  = "`varstr'"
    return local varstrL = "`varstrL'"
end

***********************************************************************
*                        Generic hash helpers                         *
***********************************************************************

capture program drop confirm_var
program confirm_var, rclass
    syntax anything, [replace]
    local newvar = 1
    if ( "`replace'" != "" ) {
        cap confirm new variable `anything'
        if ( _rc ) {
            local newvar = 0
        }
        else {
            cap noi confirm name `anything'
            if ( _rc ) {
                local rc = _rc
                clean_all
                exit `rc'
            }
        }
    }
    else {
        cap confirm new variable `anything'
        if ( _rc ) {
            local rc = _rc
            clean_all
            cap noi confirm name `anything'
            if ( _rc ) {
                exit `rc'
            }
            else {
                di as err "Variable `anything' exists;" ///
                          " try a different name or run with -replace-"
                exit `rc'
            }
        }
    }
    return scalar newvar = `newvar'
    exit 0
end

capture program drop rc_dispatch
program rc_dispatch
    syntax [varlist], rc(int) oncollision(str)

    local website_url  https://github.com/mcaceresb/stata-gtools/issues
    local website_disp github.com/mcaceresb/stata-gtools

    if ( `rc' == 17000 ) {
        di as err "There may be 128-bit hash collisions!"
        di as err `"This is a bug. Please report to"' ///
                  `" {browse "`website_url'":`website_disp'}"'
        if ( "`oncollision'" == "fallback" ) {
            exit 17999
        }
        else {
            exit 17000
        }
    }
    else if ( `rc' == 17001 ) {
        exit 17001
    }
    else if ( `rc' == 459 ) {
        local kvars : word count `varlist'
        local s = cond(`kvars' == 1, "", "s")
        di as err "variable`s' `varlist' should never be missing"
        exit 459
    }
    else if ( `rc' == 17459 ) {
        local kvars : word count `varlist'
        local var  = cond(`kvars'==1, "variable", "variables")
        local does = cond(`kvars'==1, "does", "do")
        di as err "`var' `varlist' `does' not uniquely" ///
                  " identify the observations"
        exit 459
    }
    else {
        * error `rc'
        exit `rc'
    }
end

capture program drop gtools_timer
program gtools_timer, rclass
    syntax anything, [prints(int 0) end off]
    tokenize `"`anything'"'
    local what  `1'
    local timer `2'
    local msg   `"`3'; "'

    * If timer is 0, then there were no free timers; skip this benchmark
    if ( `timer' == 0 ) exit 0

    if ( inlist("`what'", "start", "on") ) {
        cap timer off `timer'
        cap timer clear `timer'
        timer on `timer'
    }
    else if ( inlist("`what'", "info") ) {
        timer off `timer'
        qui timer list
        return scalar t`timer' = `r(t`timer')'
        return local pretty`timer' = trim("`:di %21.4gc r(t`timer')'")
        if ( `prints' ) di `"`msg'`:di trim("`:di %21.4gc r(t`timer')'")' seconds"'
        timer off `timer'
        timer clear `timer'
        timer on `timer'
    }

    if ( "`end'`off'" != "" ) {
        timer off `timer'
        timer clear `timer'
    }
end

capture program drop check_matsize
program check_matsize
    syntax [anything], [nvars(int 0)]
    if ( `nvars' == 0 ) local nvars `:list sizeof anything'
    if ( `nvars' > `c(matsize)' ) {
        cap set matsize `=`nvars''
        if ( _rc ) {
            di as err                                                        ///
                _n(1) "{bf:# variables > matsize (`nvars' > `c(matsize)').}" ///
                _n(2) "    {stata set matsize `=`nvars''}"                   ///
                _n(2) "{bf:failed. Try setting matsize manually.}"
            exit 908
        }
    }
end

* NOTE(mauricio): Replace does nothing here atm; it shouldn't because
* _gtools_internal expects everything to exist already!
capture program drop parse_targets
program parse_targets
    syntax, sources(str) targets(str) stats(str) [replace k_exist(str) KEEPMISSing]
    local k_vars    = `:list sizeof sources'
    local k_targets = `:list sizeof targets'
    local k_stats   = `:list sizeof stats'

    local uniq_sources: list uniq sources
    local uniq_targets: list uniq targets

    cap assert `k_targets' == `k_stats'
    if ( _rc ) {
        di as err " `k_targets' target(s) require(s) `k_targets' stat(s)," ///
                  " but user passed `k_stats'"
        exit 198
    }

    if ( `k_targets' > 1 ) {
        cap assert `k_targets' == `k_vars'
        if ( _rc ) {
            di as err " `k_targets' targets require `k_targets' sources," ///
                      " but user passed `k_vars'"
            exit 198
        }
    }
    else if ( `k_targets' == 1 ) {
        cap assert `k_vars' > 0
        if ( _rc ) {
            di as err "Specify at least one source variable"
            exit 198
        }
        cap assert `:list sizeof uniq_sources' == `k_vars'
        if ( _rc ) {
            di as txt "(warning: repeat sources ignored with 1 target)"
        }
    }
    else {
        di as err "Specify at least one target"
        exit 198
    }

    local stats: subinstr local stats "total" "sum", all
    cap assert `:list sizeof uniq_targets' == `k_targets'
    if ( _rc ) {
        di as err "Cannot specify multiple targets with the same name."
        exit 198
    }

    if ( "`k_exist'" != "targets" ) {
        foreach var of local uniq_sources {
            cap confirm variable `var'
            if ( _rc ) {
                di as err "Source `var' has to exist."
                exit 198
            }

            cap confirm numeric variable `var'
            if ( _rc ) {
                di as err "Source `var' must be numeric."
                exit 198
            }
        }
    }

    mata: __gtools_stats       = J(1, `k_stats',   .)
    mata: __gtools_pos_targets = J(1, `k_targets', 0)

    cap noi check_matsize `targets'
    if ( _rc ) exit _rc

    local keepadd = cond("`keepmissing'" == "", 0, 100)
    forvalues k = 1 / `k_targets' {
        local src: word `k' of `sources'
        local trg: word `k' of `targets'
        local st:  word `k' of `stats'

        encode_stat_allowed `st' `keepadd'
        mata: __gtools_stats[`k'] = `r(statcode)'

        if ( "`k_exist'" != "sources" ) {
            cap confirm variable `trg'
            if ( _rc ) {
                di as err "Target `trg' has to exist."
                exit 198
            }

            cap confirm numeric variable `trg'
            if ( _rc ) {
                di as err "Target `trg' must be numeric."
                exit 198
            }
        }

        mata: __gtools_pos_targets[`k'] = `:list posof `"`src'"' in uniq_sources' - 1
    }

    scalar __gtools_k_vars    = `:list sizeof uniq_sources'
    scalar __gtools_k_targets = `k_targets'
    scalar __gtools_k_stats   = `k_stats'

    c_local __gtools_sources `uniq_sources'
    c_local __gtools_targets `targets'

    mata: st_matrix("__gtools_stats",       __gtools_stats)
    mata: st_matrix("__gtools_pos_targets", __gtools_pos_targets)

    cap mata: mata drop __gtools_stats
    cap mata: mata drop __gtools_pos_targets
end

capture program drop encode_stat_allowed
program encode_stat_allowed, rclass
    args st keepadd
    local allowed sum          ///
                  nansum       ///
                  mean         ///
                  geomean      ///
                  sd           ///
                  variance     ///
                  cv           ///
                  max          ///
                  min          ///
                  range        ///
                  count        ///
                  median       ///
                  iqr          ///
                  percent      ///
                  first        ///
                  last         ///
                  firstnm      ///
                  lastnm       ///
                  freq         ///
                  semean       ///
                  sebinomial   ///
                  sepoisson    ///
                  nunique      ///
                  nmissing     ///
                  skewness     ///
                  kurtosis     ///
                  gini         ///
                  gini|dropneg ///
                  gini|keepneg ///
                  rawsum       ///
                  rawnansum

    encode_aliases `st'
    local st `r(stat)'

    if ( `:list st in allowed' ) {
        encode_stat `st' `keepadd'
        local statcode `r(statcode)'
    }
    else {
        cap noi encode_regex `st'
        if ( `r(statcode)' == 0 ) {
            disp as err "_gtools_internal/encode_stat_allowed: unknown stat `st'"
            error 110
        }
        else local statcode `r(statcode)'
        local st `r(stat)'
    }

    return local  statname = `"`st'"'
    return scalar statcode = `statcode'
end

capture program drop encode_stat
program encode_stat, rclass
    args stat keepadd
    local statcode 0
    if ( "`stat'" == "sum"          ) local statcode = -1 - `keepadd'
    if ( "`stat'" == "nansum"       ) local statcode = -101
    if ( "`stat'" == "mean"         ) local statcode = -2
    if ( "`stat'" == "geomean"      ) local statcode = -26
    if ( "`stat'" == "sd"           ) local statcode = -3
    if ( "`stat'" == "variance"     ) local statcode = -23
    if ( "`stat'" == "cv"           ) local statcode = -24
    if ( "`stat'" == "max"          ) local statcode = -4
    if ( "`stat'" == "min"          ) local statcode = -5
    if ( "`stat'" == "range"        ) local statcode = -25
    if ( "`stat'" == "count"        ) local statcode = -6
    if ( "`stat'" == "percent"      ) local statcode = -7
    if ( "`stat'" == "median"       ) local statcode = 50
    if ( "`stat'" == "iqr"          ) local statcode = -9
    if ( "`stat'" == "first"        ) local statcode = -10
    if ( "`stat'" == "firstnm"      ) local statcode = -11
    if ( "`stat'" == "last"         ) local statcode = -12
    if ( "`stat'" == "lastnm"       ) local statcode = -13
    if ( "`stat'" == "freq"         ) local statcode = -14
    if ( "`stat'" == "semean"       ) local statcode = -15
    if ( "`stat'" == "sebinomial"   ) local statcode = -16
    if ( "`stat'" == "sepoisson"    ) local statcode = -17
    if ( "`stat'" == "nunique"      ) local statcode = -18
    if ( "`stat'" == "nmissing"     ) local statcode = -22
    if ( "`stat'" == "skewness"     ) local statcode = -19
    if ( "`stat'" == "kurtosis"     ) local statcode = -20
    if ( "`stat'" == "gini"         ) local statcode = -27
    if ( "`stat'" == "gini|dropneg" ) local statcode = -27.1
    if ( "`stat'" == "gini|keepneg" ) local statcode = -27.2
    if ( "`stat'" == "rawsum"       ) local statcode = -21 - `keepadd'
    if ( "`stat'" == "rawnansum"    ) local statcode = -121
    return scalar statcode = `statcode'
end

capture program drop encode_regex
program encode_regex, rclass
    args st
    local rc = 0
    local statcode = 0
    local stat: copy local st
    if regexm("`st'", "rawselect") {
        local stat rawselect
        local select = regexm("`st'", "^rawselect(-|)([0-9]+)$")
        if ( `select' == 0 ) {
            di as error "Invalid stat: (`st'; did you mean rawselect# or rawselect-#?)"
            local rc = 110
        }
        else if ( `=regexs(2)' == 0 ) {
            di as error "Invalid stat: (`st' not allowed; selection must be 1 or larger)"
            local rc = 110
        }
        else {
            local statcode = `:di regexs(1)' (1000.5 + `=regexs(2)')
        }
    }
    else if regexm("`st'", "select") {
        local stat select
        local select = regexm("`st'", "^select(-|)([0-9]+)$")
        if ( `select' == 0 ) {
            di as error "Invalid stat: (`st'; did you mean select# or select-#?)"
            local rc = 110
        }
        else if ( `=regexs(2)' == 0 ) {
            di as error "Invalid stat: (`st' not allowed; selection must be 1 or larger)"
            local rc = 110
        }
        else {
            local statcode = `:di regexs(1)' (1000 + `=regexs(2)')
        }
    }
    else if regexm("`st'", "^p([0-9][0-9]?(\.[0-9]+)?)$") {
        local stat pctile
        if ( `:di regexs(1)' == 0 ) {
            di as error "Invalid stat: (`st'; maybe you meant 'min'?)"
            local rc = 110
        }
        else {
            local statcode = `:di regexs(1)'
        }
    }
    else if ( "`st'" == "p100" ) {
        di as error "Invalid stat: (`st'; maybe you meant 'max'?)"
        local rc = 110
    }
    else {
        di as error "Invalid stat: `st'"
        local rc = 110
    }
    return local  stat     = `"`stat'"'
    return scalar statcode = `statcode'
    exit `rc'
end

capture program drop encode_aliases
program encode_aliases, rclass
    args st
    local allowed sum          ///
                  nansum       ///
                  mean         ///
                  geomean      ///
                  sd           ///
                  variance     ///
                  cv           ///
                  max          ///
                  min          ///
                  range        ///
                  count        ///
                  median       ///
                  iqr          ///
                  percent      ///
                  first        ///
                  last         ///
                  firstnm      ///
                  lastnm       ///
                  freq         ///
                  semean       ///
                  sebinomial   ///
                  sepoisson    ///
                  nunique      ///
                  nmissing     ///
                  skewness     ///
                  kurtosis     ///
                  gini         ///
                  gini|dropneg ///
                  gini|keepneg ///
                  rawsum       ///
                  rawnansum

    local alias_sum          su
    local alias_nansum       nansu
    local alias_mean         me         mea
    local alias_geomean
    local alias_gini
    local alias_gini_dropneg
    local alias_gini_keepneg
    local alias_sd
    local alias_variance     var        vari       varia      varian     varianc
    local alias_cv
    local alias_max          ma         max
    local alias_min          mi         min
    local alias_range        r          ra         ran        rang       range
    local alias_count        co         cou        coun
    local alias_median       med        medi       media
    local alias_iqr
    local alias_percent      perc       perce      percen
    local alias_first
    local alias_last
    local alias_firstnm
    local alias_lastnm
    local alias_freq
    local alias_semean       sem        seme       semea
    local alias_sebinomial   seb        sebi       sebin      sebino     sebinom    sebinomi   sebinomia
    local alias_sepoisson    sep        sepo       sepoi      sepois     sepoiss    sepoisso
    local alias_nunique      nuniq      nuniqu
    local alias_nmissing     nmiss      nmissi     nmissin
    local alias_skewness     sk         ske        skew       skewn      skewne     skewnes
    local alias_kurtosis     k          ku         kur        kurt       kurto      kurtos     kurtosi
    local alias_rawsum       rawsu
    local alias_rawnansum    rawnansu

    if ( !`:list st in allowed' ) {
        foreach stat of local allowed {
            if ( `:list st in alias_`:subinstr local stat "|" "_", all'' ) {
                local st: copy local stat
            }
        }
    }

    return local stat: copy local st
end

capture program drop encode_stat_types
program encode_stat_types, rclass
    args stat stype ttype

    * default type for summary stats
    if ( inlist("`stype'", "double", "long") ) {
        local deftype double
    }
    else {
        local deftype: set type
    }

    * next-biggest type
    if ( `"`stype'"' == "byte" ) {
        local nexttype int
    }
    else if ( `"`stype'"' == "int" ) {
        local nexttype long
    }
    else if ( `"`stype'"' == "long" ) {
        local nexttype double
    }
    else if ( `"`stype'"' == "float" ) {
        local nexttype double
    }
    else if ( `"`stype'"' == "double" ) {
        local nexttype double
    }

    * minimum OK type for counts
    if ( `=_N' < maxbyte() ) {
        local mintype_count byte
    }
    else if ( `=_N' < maxint() ) {
        local mintype_count int
    }
    else if ( `=_N' < maxlong() ) {
        local mintype_count long
    }
    else {
        local mintype_count double
    }

    encode_stat_allowed `stat' 0
    local stat `r(statname)'

    if ( "`stat'" == "sum"          ) local type double
    if ( "`stat'" == "nansum"       ) local type double
    if ( "`stat'" == "mean"         ) local type `deftype'
    if ( "`stat'" == "geomean"      ) local type `deftype'
    if ( "`stat'" == "sd"           ) local type `deftype'
    if ( "`stat'" == "variance"     ) local type `deftype'
    if ( "`stat'" == "cv"           ) local type `deftype'
    if ( "`stat'" == "max"          ) local type `stype'
    if ( "`stat'" == "min"          ) local type `stype'
    if ( "`stat'" == "range"        ) local type `nexttype'
    if ( "`stat'" == "count"        ) local type `mintype_count'
    if ( "`stat'" == "percent"      ) local type `deftype'
    if ( "`stat'" == "median"       ) local type `deftype'
    if ( "`stat'" == "iqr"          ) local type `deftype'
    if ( "`stat'" == "first"        ) local type `stype'
    if ( "`stat'" == "firstnm"      ) local type `stype'
    if ( "`stat'" == "last"         ) local type `stype'
    if ( "`stat'" == "lastnm"       ) local type `stype'
    if ( "`stat'" == "freq"         ) local type `mintype_count'
    if ( "`stat'" == "semean"       ) local type `deftype'
    if ( "`stat'" == "sebinomial"   ) local type `deftype'
    if ( "`stat'" == "sepoisson"    ) local type `deftype'
    if ( "`stat'" == "nunique"      ) local type `mintype_count'
    if ( "`stat'" == "nmissing"     ) local type `mintype_count'
    if ( "`stat'" == "skewness"     ) local type `deftype'
    if ( "`stat'" == "kurtosis"     ) local type `deftype'
    if ( "`stat'" == "rawsum"       ) local type double
    if ( "`stat'" == "rawnansum"    ) local type double
    if ( "`stat'" == "pctile"       ) local type `deftype'
    if ( "`stat'" == "select"       ) local type `stype'
    if ( "`stat'" == "rawselect"    ) local type `stype'
    if ( "`stat'" == "gini"         ) local type `deftype'
    if ( "`stat'" == "gini|dropneg" ) local type `deftype'
    if ( "`stat'" == "gini|keepneg" ) local type `deftype'

    if ( `"`ttype'"' == "double" ) {
        local retype = 0
    }
    else if ( `"`ttype'"' == "byte" ) {
        local retype = !inlist(`"`type'"', "byte")
    }
    else if ( `"`ttype'"' == "int" ) {
        local retype = !inlist(`"`type'"', "byte", "int")
    }
    else if ( `"`ttype'"' == "long" ) {
        local retype = !inlist(`"`type'"', "byte", "int", "long")
        if ( (`retype') & (`"`type'"' == "float") ) local type double
    }
    else if ( `"`ttype'"' == "float" ) {
        local retype = !inlist(`"`type'"', "byte", "int", "float")
        if ( (`retype') & (`"`type'"' == "long")  ) local type double
    }
    else local retype = 1

    return local type:   copy local type
    return local retype: copy local retype
end

capture program drop FreeTimer
program FreeTimer
    qui {
        timer list
        local i = 99
        while ( (`i' > 0) & ("`r(t`i')'" != "") ) {
            local --i
        }
    }
    c_local FreeTimer `i'
end

capture program drop GenericParseTypes
program GenericParseTypes
    syntax varlist, mat(name) [matstrl(name)]

    cap disp ustrregexm("a", "a")
    if ( _rc ) local regex regex
    else local regex ustrregex

    tempvar strlen
    local types
    local strl
    foreach var of varlist `varlist' {
        if ( `regex'm("`:type `var''", "str([1-9][0-9]*|L)") ) {
            if ( (`regex's(1) == "L") & (`"`matstrl'"' == "") ) {
                disp as err "ParseTypes(`mat'): Unsupported type `:type `var''"
                exit 198
            }
            else if ( `regex's(1) == "L" ) {
                cap confirm var `strlen'
                if ( _rc ) {
                    qui gen `strlen' = length(`var')
                }
                else {
                    qui replace `strlen' = length(`var')
                }
                qui sum `strlen', meanonly

                local strl  `strl'  1
                local types `types' `r(max)'
            }
            else {
                local strl  `strl'  0
                local types `types' `=`regex's(1)'
            }
        }
        else if inlist("`:type `var''", "byte", "int", "long") {
            local strl  `strl'  0
            local types `types' -1
        }
        else if inlist("`:type `var''", "float", "double") {
            local strl  `strl'  0
            local types `types' 0
        }
        else {
            disp as err "ParseTypes(`mat'): Unknown type `:type `var''"
            exit 198
        }
    }
    mata: st_matrix(st_local("mat"),  strtoreal(tokens(st_local("types"))))
    if ( `"`matstrl'"' != "" ) {
        mata: st_matrix(st_local("matstrl"), strtoreal(tokens(st_local("strlen"))))
    }
end

capture program drop encode_moving
program encode_moving, rclass
    syntax anything, [window(str)]

    gettoken lwindow uwindow: window
    if ( `"`window'"' != "" ) {
        if ( (`"`lwindow'"' == "") | (`"`uwindow'"' == "") ) {
            disp as err "moving: option window() requires a lower and upper bound"
            exit 198
        }
        cap confirm integer number `lwindow'
        if ( _rc & (`lwindow' != .) ) {
            disp as err "moving: option window() requires integer inputs"
            exit 7
        }
        cap confirm integer number `uwindow'
        if ( _rc & (`uwindow' != .) ) {
            disp as err "moving: option window() requires integer inputs"
            exit 7
        }
    }
    else {
        local lwindow .
        local uwindow .
    }

    local rwarn = 0
    if ( regexm(`"`anything'"', "^moving[ |]+([^ |]+)[ |]*([^ |]+)?[ |]*([^ |]+)?$") ) {
        local rmatch = 1
        local rstat  = regexs(1)
        cap local rlower = regexs(2)
        cap local rupper = regexs(3)

        if ( `"`rlower'"' == "" ) local rlower `lwindow'
        if ( `"`rupper'"' == "" ) local rupper `uwindow'

        cap confirm integer number `rlower'
        if ( _rc & (`rlower' != .) ) {
            disp as err "moving: option window requires integer inputs"
            exit 7
        }

        cap confirm integer number `rupper'
        if ( _rc & (`rupper' != .) ) {
            disp as err "moving: option window requires integer inputs"
            exit 7
        }

        local rwarn = `rwarn' | ((`rupper' == .) & (`rlower' == .))

        encode_aliases `rstat'
        local rstat `r(stat)'
        local stat moving|`rstat'|`rlower'|`rupper'

        cap encode_stat_allowed `rstat' 0
        local scode = `r(statcode)'
        if ( _rc ) {
            disp as err "moving: unknown sub-statistic `rstat'"
            exit 198
        }

        if inlist("`rstat'", "percent", "nunique") {
            disp as err "moving: `rstat' not implemented"
            exit 198
        }
    }
    else {
        local rwarn  = 0
        local rmatch = 0
        local scode  = 0
        local stat:   copy local anything
        local rstat:  copy local anything
        local rlower: copy local lwindow
        local rupper: copy local uwindow
    }

    c_local stat: copy local stat
    return local  stat: copy local rstat
    return local  name  = strtoname(`"`stat'"')
    return scalar warn  = `rwarn'
    return scalar scode = `scode'
    return scalar match = `rmatch'
    return scalar lower = `rlower'
    return scalar upper = `rupper'
end

capture program drop encode_range
program encode_range, rclass
    syntax anything, [interval(str) var(str)]

    encode_range_parse `interval'

    local linterval `r(linterval)'
    local uinterval `r(uinterval)'
    local variable  `r(variable)'
    local lstat     `r(lstat)'
    local ustat     `r(ustat)'

    if ( `"`linterval'"' == ""  ) local linterval .
    if ( `"`uinterval'"' == ""  ) local uinterval .
    if ( `"`r(lsign)'"'  == "-" ) local linterval -`linterval'
    if ( `"`r(usign)'"'  == "-" ) local uinterval -`uinterval'
    if ( `"`variable'"'  == ""  ) local variable  `var'

    local iwarn = 0
    if ( regexm(`"`anything'"', "^range[ |]+([^ |]+)[ |]*([^ |]+)?[ |]*([^ |]+)?[ |]*([^ ]+)?$") ) {
        local imatch = 1
        local istat  = regexs(1)
        cap local ilower = regexs(2)
        cap local iupper = regexs(3)
        cap local ivar   = regexs(4)

        if ( `"`ilower'"' == "" ) local ilower `linterval'`lstat'
        if ( `"`iupper'"' == "" ) local iupper `uinterval'`ustat'
        if ( `"`ivar'"'   == "" ) local ivar   `variable'

        encode_range_parse `ilower' `iupper' `ivar'

        local ilower `r(linterval)'
        local iupper `r(uinterval)'
        local ivar   `r(variable)'
        local ilstat `r(lstat)'
        local iustat `r(ustat)'
        local ilsign `r(lsign)'
        local iusign `r(usign)'

        local iwarn = `iwarn' | ((`iupper' == .) & (`ilower' == .))

        local checkcodes scode lcode ucode
        foreach checkstat in istat ilstat iustat {
            gettoken checkcode checkcodes: checkcodes
            if ( `"``checkstat''"' != "" ) {
                encode_aliases ``checkstat''
                local `checkstat' `r(stat)'

                cap encode_stat_allowed ``checkstat'' 0
                local `checkcode' = `r(statcode)'
                if ( _rc ) {
                    disp as err "range: unknown sub-statistic ``checkstat''"
                    exit 198
                }

                if inlist("``checkstat''", "percent", "nunique") {
                    disp as err "range: ``checkstat'' not implemented"
                    exit 198
                }
            }
            else {
                local `checkcode' = 0
            }
        }

        local irangestr `ivar' within `ivar'[i] `ilsign' `ilower'`ilstat' to `ivar'[i] `iusign' `iupper'`iustat'

        if ( `"`ilsign'"' == "-" ) local ilower -`ilower'
        if ( `"`iusign'"' == "-" ) local iupper -`iupper'

        local stat range|`istat'|`ilower'`ilstat'|`iupper'`iustat'|`ivar'
    }
    else {
        local irangestr
        local scode  = 0
        local lcode  = 0
        local ucode  = 0
        local iwarn  = 0
        local imatch = 0
        local stat:   copy local anything
        local istat:  copy local anything
        local ilower
        local ilstat
        local iupper
        local iustat
        local ivar
    }

    c_local stat: copy local stat

    return local stat:     copy local istat
    return local lower:    copy local ilower
    return local lstat:    copy local ilstat
    return local upper:    copy local iupper
    return local ustat:    copy local iustat
    return local var:      copy local ivar
    return local rangestr: copy local irangestr

    return local name   = strtoname(`"`stat'"')
    return scalar scode = `scode'
    return scalar lcode = `lcode'
    return scalar ucode = `ucode'
    return scalar warn  = `iwarn'
    return scalar match = `imatch'
end

capture program drop encode_range_parse
program encode_range_parse, rclass

    gettoken linterval uinterval: 0
    gettoken uinterval variable:  uinterval

    local linterval `linterval'
    local uinterval `uinterval'
    local variable  `variable'
    local lstat
    local ustat

    if ( `"`0'"' != "" ) {
        if ( (`"`linterval'"' == "") | (`"`uinterval'"' == "") ) {
            disp as err "range: option interval() requires a lower and upper bound"
            exit 198
        }

        cap confirm integer number `linterval'
        if ( _rc & (`"`linterval'"' != ".") ) {
            encode_range_stat `linterval'
            if ( `r(imatch)' == 0 ) {
                disp as err "range: option interval() incorrectly specified"
                exit 7
            }
            local linterval `r(iscalar)'
            local lstat     `r(istat)'
            local lsign     `r(isign)'
        }
        else if ( _rc == 0 ) {
            * negative numbers would have a '-' sign prepended already
            local lsign = cond(`linterval' < 0, "", "+")
        }

        cap confirm integer number `uinterval'
        if ( _rc & (`"`uinterval'"' != ".") ) {
            encode_range_stat `uinterval'
            if ( `r(imatch)' == 0 ) {
                disp as err "range: option interval() incorrectly specified"
                exit 7
            }
            local uinterval `r(iscalar)'
            local ustat     `r(istat)'
            local usign     `r(isign)'
        }
        else if ( _rc == 0 ) {
            * negative numbers would have a '-' sign prepended already
            local usign = cond(`uinterval' < 0, "", "+")
        }
    }

    return local linterval: copy local linterval
    return local uinterval: copy local uinterval
    return local variable:  copy local variable
    return local lstat:     copy local lstat
    return local ustat:     copy local ustat
    return local lsign:     copy local lsign
    return local usign:     copy local usign
end

capture program drop encode_range_stat
program encode_range_stat, rclass
    if ( regexm(`"`0'"', "^(\+|-)?([0-9]+\.[0-9]+|\.[0-9]+|[0-9]+)?(.*)$") ) {
        local imatch      = 1
        cap local isign   = regexs(1)
        cap local iscalar = regexs(2)
        cap local istat   = regexs(3)
        if ( `"`isign'"' != "-" ) {
            local isign +
        }
        else {
            local isign -
        }
        if ( `"`iscalar'"' == "" ) local iscalar 1
    }
    else {
        local imatch    = 0
    }
    return scalar imatch = `imatch'
    return local isign   : copy local isign
    return local iscalar : copy local iscalar
    return local istat   : copy local istat
end

capture program drop encode_cumsum
program encode_cumsum, rclass
    syntax anything, [cumby(str) var(str)]

    local var `var'
    local anything `anything'
    local stat: copy local anything
    local match 0
    local cumsign 0
    local cumvars

    if ( (`"`anything'"' == "cumsum") & (`"`cumby'"' == "") ) {
        local match 1
    }
    else {
        local anything: subinstr local anything "|" " ", all
        local anything `anything'
        if ( regexm(`"`anything'"', "^cumsum(.*)$") ) {
            local _cumby = regexs(1)
            local _cumby `_cumby'
            if ( `"`_cumby'"' == "" ) local _cumby: copy local cumby

            gettoken cumsign cumvars: _cumby
            local cumvars `cumvars'
            local cumsign `cumsign'

            if inlist(`"`cumsign'"', "+", "-") {
                * if ( `"`cumvars'"' == "" ) local cumvars: copy local var

                local match 1
                local stat cumsum|`cumsign'|`:subinstr local cumvars " " "|", all'
                local cumsign = cond(`"`cumsign'"' == "+", 1, 2)
            }
            else {
                disp as err "cumsum: cumby() misspecified; expected '+/- [varlist]' but got '`_cumby''"
                exit 7
            }
        }

        c_local stat: copy local stat
    }

    return local stat:     copy local stat
    return local match:    copy local match
    return local cumsign:  copy local cumsign
    return local cumvars:  copy local cumvars
    return local cumother = `"`cumvars'"' != ""
end

capture program drop encode_shift
program encode_shift, rclass
    syntax anything, [shiftby(str)]

    local anything `anything'
    local stat: copy local anything
    local match 0
    local shift 0

    if regexm(`"`anything'"', "^shift[ |]*([+-]?[0-9]+)[ |]*$") {
        local shift = `=regexs(1)'
        local match 1
        local stat shift|`shift'
    }
    else if regexm(`"`anything'"', "^shift[ |]*$") {
        if ( `"`shiftby'"' == "" ) {
            disp as err "shift: shiftby() required if no individual shift is specified"
            exit 198
        }
        else {
            cap confirm integer number `shiftby'
            if ( _rc ) {
                disp as err "shift: shiftby() misspecified; expected integer but got '`shiftby''"
                exit 7
            }
            local shift = `=`shiftby''
            local match 1
            local stat shift|`shift'
        }
    }

    c_local stat: copy local stat
    return local stat:  copy local stat
    return local match: copy local match
    return local shift: copy local shift
end

***********************************************************************
*                              greshape                               *
***********************************************************************

capture program drop greshape_scalars
program greshape_scalars
    * 1 = long, 2 = wide
    if ( inlist(`"`1'"', "gen", "init", "alloc") ) {
        scalar __gtools_greshape_code     = 0
        scalar __gtools_greshape_kxi      = 0
        scalar __gtools_greshape_str      = 0
        scalar __gtools_greshape_dropmiss = 0

        cap matrix list __gtools_greshape_xitypes
        if ( _rc ) matrix __gtools_greshape_xitypes = 0
        cap matrix list __gtools_greshape_types
        if ( _rc ) matrix __gtools_greshape_types = 0
        cap matrix list __gtools_greshape_maplevel
        if ( _rc ) matrix __gtools_greshape_maplevel = 0

        cap scalar dir __gtools_greshape_jfile
        if ( _rc ) scalar __gtools_greshape_jfile = 0
        cap scalar dir __gtools_greshape_kxij
        if ( _rc ) scalar __gtools_greshape_kxij = 0
        cap scalar dir __gtools_greshape_kout
        if ( _rc ) scalar __gtools_greshape_kout = 0
        cap scalar dir __gtools_greshape_klvls
        if ( _rc ) scalar __gtools_greshape_klvls = 0
    }
    else if ( `"`2'"' != "_keepgreshape" ) {
        cap scalar drop __gtools_greshape_code
        cap scalar drop __gtools_greshape_kxi
        cap scalar drop __gtools_greshape_str
        cap scalar drop __gtools_greshape_dropmiss

        if ( `"${GTOOLS_CALLER}"' != "greshape" ) {
            cap matrix drop __gtools_greshape_xitypes
            cap matrix drop __gtools_greshape_types
            cap matrix drop __gtools_greshape_maplevel

            cap scalar drop __gtools_greshape_jfile
            cap scalar drop __gtools_greshape_kxij
            cap scalar drop __gtools_greshape_kout
            cap scalar drop __gtools_greshape_klvls
        }
    }
end

***********************************************************************
*                              gregress                               *
***********************************************************************

capture program drop gregress_scalars
program gregress_scalars
    if ( inlist(`"`0'"', "gen", "init", "alloc") ) {
        scalar __gtools_gregress_kv            = 0
        scalar __gtools_gregress_kvars         = 0
        scalar __gtools_gregress_cons          = 0
        scalar __gtools_gregress_robust        = 0
        scalar __gtools_gregress_cluster       = 0
        scalar __gtools_gregress_absorb        = 0
        scalar __gtools_gregress_hdfetol       = 0
        scalar __gtools_gregress_hdfemaxiter   = 0
        scalar __gtools_gregress_hdfetraceiter = 0
        scalar __gtools_gregress_hdfestandard  = 0
        scalar __gtools_gregress_hdfemethnm    = ""
        scalar __gtools_gregress_hdfemethod    = 0
        scalar __gtools_gregress_glmlogit      = 0
        scalar __gtools_gregress_glmpoisson    = 0
        scalar __gtools_gregress_glmfam        = 0
        scalar __gtools_gregress_glmiter       = 0
        scalar __gtools_gregress_glmtol        = 0
        scalar __gtools_gregress_ivreg         = 0
        scalar __gtools_gregress_ivkendog      = 0
        scalar __gtools_gregress_ivkexog       = 0
        scalar __gtools_gregress_ivkz          = 0
        scalar __gtools_gregress_savemata      = 0
        scalar __gtools_gregress_savemb        = 0
        scalar __gtools_gregress_savemse       = 0
        scalar __gtools_gregress_savegb        = 0
        scalar __gtools_gregress_savegse       = 0
        scalar __gtools_gregress_saveghdfe     = 0
        scalar __gtools_gregress_savegresid    = 0
        scalar __gtools_gregress_savegpred     = 0
        scalar __gtools_gregress_savegabs      = 0
        scalar __gtools_gregress_moving        = 0
        scalar __gtools_gregress_moving_l      = 0
        scalar __gtools_gregress_moving_u      = 0
        scalar __gtools_gregress_range         = 0
        scalar __gtools_gregress_range_l       = 0
        scalar __gtools_gregress_range_u       = 0
        scalar __gtools_gregress_range_ls      = 0
        scalar __gtools_gregress_range_us      = 0
        matrix __gtools_gregress_clustyp       = .
        matrix __gtools_gregress_abstyp        = .
    }
    else {
        cap scalar drop __gtools_gregress_kv
        cap scalar drop __gtools_gregress_kvars
        cap scalar drop __gtools_gregress_cons
        cap scalar drop __gtools_gregress_robust
        cap scalar drop __gtools_gregress_cluster
        cap scalar drop __gtools_gregress_absorb
        cap scalar drop __gtools_gregress_hdfetol
        cap scalar drop __gtools_gregress_hdfemaxiter
        cap scalar drop __gtools_gregress_hdfetraceiter
        cap scalar drop __gtools_gregress_hdfestandard
        cap scalar drop __gtools_gregress_hdfemethnm
        cap scalar drop __gtools_gregress_hdfemethod
        cap scalar drop __gtools_gregress_ivreg
        cap scalar drop __gtools_gregress_ivkendog
        cap scalar drop __gtools_gregress_ivkexog
        cap scalar drop __gtools_gregress_ivkz
        cap scalar drop __gtools_gregress_glmlogit
        cap scalar drop __gtools_gregress_glmpoisson
        cap scalar drop __gtools_gregress_glmfam
        cap scalar drop __gtools_gregress_glmiter
        cap scalar drop __gtools_gregress_glmtol
        cap scalar drop __gtools_gregress_savemata
        cap scalar drop __gtools_gregress_savemb
        cap scalar drop __gtools_gregress_savemse
        cap scalar drop __gtools_gregress_savegb
        cap scalar drop __gtools_gregress_savegse
        cap scalar drop __gtools_gregress_saveghdfe
        cap scalar drop __gtools_gregress_savegresid
        cap scalar drop __gtools_gregress_savegpred
        cap scalar drop __gtools_gregress_savegabs
        cap scalar drop __gtools_gregress_moving
        cap scalar drop __gtools_gregress_moving_l
        cap scalar drop __gtools_gregress_moving_u
        cap scalar drop __gtools_gregress_range
        cap scalar drop __gtools_gregress_range_l
        cap scalar drop __gtools_gregress_range_u
        cap scalar drop __gtools_gregress_range_ls
        cap scalar drop __gtools_gregress_range_us
        cap matrix drop __gtools_gregress_clustyp
        cap matrix drop __gtools_gregress_abstyp
    }
end

***********************************************************************
*                               gstats                                *
***********************************************************************

capture program drop gstats_scalars
program gstats_scalars
    scalar __gtools_gstats_code = .
    if ( inlist(`"`0'"', "gen", "init", "alloc") ) {
        scalar __gtools_winsor_trim            = .
        scalar __gtools_winsor_cutl            = .
        scalar __gtools_winsor_cuth            = .
        scalar __gtools_winsor_kvars           = .

        scalar __gtools_hdfe_nonmiss           = 0
        scalar __gtools_hdfe_kvars             = 0
        scalar __gtools_hdfe_absorb            = 0
        scalar __gtools_hdfe_method            = 1
        scalar __gtools_hdfe_maxiter           = 0
        scalar __gtools_hdfe_traceiter         = 0
        scalar __gtools_hdfe_standard          = 0
        scalar __gtools_hdfe_hdfetol           = 0
        scalar __gtools_hdfe_matasave          = 0
        scalar __gtools_hdfe_mataname          = ""
        scalar __gtools_hdfe_iter              = 0
        scalar __gtools_hdfe_feval             = 0
        scalar __gtools_hdfe_methodname        = ""

        scalar __gtools_summarize_matasave     = 0
        scalar __gtools_summarize_pretty       = 0
        scalar __gtools_summarize_colvar       = 0
        scalar __gtools_summarize_noprint      = 0
        scalar __gtools_summarize_nosep        = 0
        scalar __gtools_summarize_pooled       = 0
        scalar __gtools_summarize_normal       = 0
        scalar __gtools_summarize_detail       = 0
        scalar __gtools_summarize_kvars        = 0
        scalar __gtools_summarize_kstats       = 0
        scalar __gtools_summarize_tabstat      = 0
        scalar __gtools_summarize_lwidth       = 16
        scalar __gtools_summarize_separator    = 0
        scalar __gtools_summarize_format       = 0
        scalar __gtools_summarize_dfmt         = "%9.0g"

        scalar __gtools_summarize_N            = .
        scalar __gtools_summarize_sum_w        = .
        scalar __gtools_summarize_sum          = .
        scalar __gtools_summarize_mean         = .
        scalar __gtools_summarize_min          = .
        scalar __gtools_summarize_max          = .
        scalar __gtools_summarize_Var          = .
        scalar __gtools_summarize_sd           = .
        scalar __gtools_summarize_p1           = .
        scalar __gtools_summarize_p5           = .
        scalar __gtools_summarize_p10          = .
        scalar __gtools_summarize_p25          = .
        scalar __gtools_summarize_p50          = .
        scalar __gtools_summarize_p75          = .
        scalar __gtools_summarize_p90          = .
        scalar __gtools_summarize_p95          = .
        scalar __gtools_summarize_p99          = .
        scalar __gtools_summarize_skewness     = .
        scalar __gtools_summarize_kurtosis     = .
        scalar __gtools_summarize_smallest1    = .
        scalar __gtools_summarize_smallest2    = .
        scalar __gtools_summarize_smallest3    = .
        scalar __gtools_summarize_smallest4    = .
        scalar __gtools_summarize_largest4     = .
        scalar __gtools_summarize_largest3     = .
        scalar __gtools_summarize_largest2     = .
        scalar __gtools_summarize_largest1     = .

        scalar __gtools_transform_greedy       = 0
        scalar __gtools_transform_kvars        = 1
        scalar __gtools_transform_ktargets     = 1
        scalar __gtools_transform_kgstats      = 1
        scalar __gtools_transform_cumsum_k     = 0
        scalar __gtools_transform_range_k      = 0
        scalar __gtools_transform_range_xs     = 0
        scalar __gtools_transform_range_xb     = 0

        matrix __gtools_transform_rank_ties    = 1
        matrix __gtools_summarize_codes        = .
        matrix __gtools_transform_varfuns      = .
        matrix __gtools_transform_statcode     = .
        matrix __gtools_transform_statmap      = .
        matrix __gtools_hdfe_abstyp            = .
        matrix __gtools_hdfe_nabsorb           = .

        matrix __gtools_transform_moving       = 0
        matrix __gtools_transform_moving_l     = .
        matrix __gtools_transform_moving_u     = .

        matrix __gtools_transform_range        = 0
        matrix __gtools_transform_range_pos    = 0
        matrix __gtools_transform_range_l      = .
        matrix __gtools_transform_range_u      = .
        matrix __gtools_transform_range_ls     = 0
        matrix __gtools_transform_range_us     = 0

        matrix __gtools_transform_cumtypes     = 0
        matrix __gtools_transform_cumsum       = 0
        matrix __gtools_transform_cumsign      = 0
        matrix __gtools_transform_cumvars      = 0
        matrix __gtools_transform_aux8_shift   = 0

        mata: __gtools_transform_cumsum        = .
        mata: __gtools_transform_cumsign       = .
        mata: __gtools_transform_cumvars       = .
        mata: __gtools_transform_aux8_shift    = .
        mata: __gtools_summarize_codes         = .
    }
    else {
        cap scalar drop __gtools_gstats_code
        cap scalar drop __gtools_winsor_trim
        cap scalar drop __gtools_winsor_cutl
        cap scalar drop __gtools_winsor_cuth
        cap scalar drop __gtools_winsor_kvars

        cap scalar drop __gtools_hdfe_nonmiss
        cap scalar drop __gtools_hdfe_kvars
        cap scalar drop __gtools_hdfe_absorb
        cap scalar drop __gtools_hdfe_method
        cap scalar drop __gtools_hdfe_maxiter
        cap scalar drop __gtools_hdfe_traceiter
        cap scalar drop __gtools_hdfe_standard
        cap scalar drop __gtools_hdfe_hdfetol
        cap scalar drop __gtools_hdfe_matasave
        cap scalar drop __gtools_hdfe_mataname
        cap scalar drop __gtools_hdfe_iter
        cap scalar drop __gtools_hdfe_feval
        cap scalar drop __gtools_hdfe_methodname

        cap scalar drop __gtools_summarize_matasave
        cap scalar drop __gtools_summarize_pretty
        cap scalar drop __gtools_summarize_colvar
        cap scalar drop __gtools_summarize_noprint
        cap scalar drop __gtools_summarize_nosep
        cap scalar drop __gtools_summarize_pooled
        cap scalar drop __gtools_summarize_normal
        cap scalar drop __gtools_summarize_detail
        cap scalar drop __gtools_summarize_kvars
        cap scalar drop __gtools_summarize_kstats
        cap scalar drop __gtools_summarize_tabstat
        cap scalar drop __gtools_summarize_lwidth
        cap scalar drop __gtools_summarize_separator
        cap scalar drop __gtools_summarize_format
        cap scalar drop __gtools_summarize_dfmt

        cap scalar drop __gtools_summarize_N
        cap scalar drop __gtools_summarize_sum_w
        cap scalar drop __gtools_summarize_sum
        cap scalar drop __gtools_summarize_mean
        cap scalar drop __gtools_summarize_min
        cap scalar drop __gtools_summarize_max
        cap scalar drop __gtools_summarize_Var
        cap scalar drop __gtools_summarize_sd
        cap scalar drop __gtools_summarize_p1
        cap scalar drop __gtools_summarize_p5
        cap scalar drop __gtools_summarize_p10
        cap scalar drop __gtools_summarize_p25
        cap scalar drop __gtools_summarize_p50
        cap scalar drop __gtools_summarize_p75
        cap scalar drop __gtools_summarize_p90
        cap scalar drop __gtools_summarize_p95
        cap scalar drop __gtools_summarize_p99
        cap scalar drop __gtools_summarize_skewness
        cap scalar drop __gtools_summarize_kurtosis
        cap scalar drop __gtools_summarize_smallest1
        cap scalar drop __gtools_summarize_smallest2
        cap scalar drop __gtools_summarize_smallest3
        cap scalar drop __gtools_summarize_smallest4
        cap scalar drop __gtools_summarize_largest4
        cap scalar drop __gtools_summarize_largest3
        cap scalar drop __gtools_summarize_largest2
        cap scalar drop __gtools_summarize_largest1

        cap scalar drop __gtools_transform_greedy
        cap scalar drop __gtools_transform_kvars
        cap scalar drop __gtools_transform_ktargets
        cap scalar drop __gtools_transform_kgstats
        cap scalar drop __gtools_transform_cumsum_k
        cap scalar drop __gtools_transform_range_k
        cap scalar drop __gtools_transform_range_xs
        cap scalar drop __gtools_transform_range_xb

        cap mata st_dropvar(__gtools_gst_dropvars)

        cap matrix drop __gtools_transform_rank_ties
        cap matrix drop __gtools_summarize_codes
        cap matrix drop __gtools_transform_varfuns
        cap matrix drop __gtools_transform_statcode
        cap matrix drop __gtools_transform_statmap
        cap matrix drop __gtools_hdfe_abstyp
        cap matrix drop __gtools_hdfe_nabsorb

        cap matrix drop __gtools_transform_moving
        cap matrix drop __gtools_transform_moving_l
        cap matrix drop __gtools_transform_moving_u

        cap matrix drop __gtools_transform_range
        cap matrix drop __gtools_transform_range_pos
        cap matrix drop __gtools_transform_range_l
        cap matrix drop __gtools_transform_range_u
        cap matrix drop __gtools_transform_range_ls
        cap matrix drop __gtools_transform_range_us

        cap matrix drop __gtools_transform_cumtypes
        cap matrix drop __gtools_transform_cumsum
        cap matrix drop __gtools_transform_cumsign
        cap matrix drop __gtools_transform_cumvars
        cap matrix drop __gtools_transform_aux8_shift

        cap mata: mata drop __gtools_transform_cumsum
        cap mata: mata drop __gtools_transform_cumsign
        cap mata: mata drop __gtools_transform_cumvars
        cap mata: mata drop __gtools_transform_aux8_shift

        cap mata: mata drop __gtools_transform_rank_ties
        cap mata: mata drop __gtools_summarize_codes
        cap mata: mata drop __gtools_gst_labels
        cap mata: mata drop __gtools_gst_formats
        cap mata: mata drop __gtools_gst_dropvars

        cap mata: mata drop __gtools_transform_varfuns
        cap mata: mata drop __gtools_transform_statcode
        cap mata: mata drop __gtools_transform_statmap

        cap mata: mata drop __gtools_transform_moving
        cap mata: mata drop __gtools_transform_moving_l
        cap mata: mata drop __gtools_transform_moving_u

        cap mata: mata drop __gtools_transform_range
        cap mata: mata drop __gtools_transform_range_pos
        cap mata: mata drop __gtools_transform_range_l
        cap mata: mata drop __gtools_transform_range_u
        cap mata: mata drop __gtools_transform_range_ls
        cap mata: mata drop __gtools_transform_range_us
    }
end

capture program drop gstats_transform
program gstats_transform
    syntax anything(equalok),       ///
    [                               ///
                                    /// TODO: Maybe add rawstat at some point...
        replace                     /// replace variables, if they exist
        noinit                      /// do not initialize targets with missing values
        nogreedy                    /// use memory-heavy algorithm
        TYPEs(str)                  /// override automatic types
                                    ///
        WILDparse                   /// parse assuming wildcard renaming
        AUTOrename                  /// automagically name targets if no target is specified
        AUTOrenameformat(passthru)  ///
        LABELFormat(passthru)       /// Custom label engine: (#stat#) #sourcelabel# is the default
        LABELProgram(passthru)      /// Program to parse labelformat (see examples)
        statprefix(passthru)        /// add prefix to every stat
                                    ///
        ties(str)                   /// how to resolve ties (one per target; use . for non-rank targets)
        window(passthru)            /// moving window if not specified in the stat
        interval(passthru)          /// interval if not specified in the stat
        cumby(passthru)             /// Cummulative sum by +/- and varlst
        shiftby(passthru)           /// Shift by +/-#
        excludeself                 /// exclude current obs from statistic
        excludebounds               /// interval is strict (do not include bounds)
    ]

    * Parse transforms and variables
    * ------------------------------

    gstats_transform_parse `anything', ///
        `wildparse'                    ///
        `labelformat'                  ///
        `labelprogram'                 ///
        `autorename'                   ///
        `autorenameformat'             ///
        `window' `interval' `cumby' `shiftby' `statprefix'

    local transforms rank        ///
                     standardize ///
                     normalize   ///
                     demean      ///
                     demedian     //

    local unknown
    foreach stat of local __gtools_gst_stats {
        if ( !`:list stat in transforms' ) {
            encode_moving `stat'
            local rmatch = `r(match)'
            encode_range `stat'
            local rmatch = `r(match)' | `rmatch'
            encode_cumsum `stat'
            local rmatch = `r(match)' | `rmatch'
            encode_shift  `stat'
            local rmatch = `r(match)' | `rmatch'
            if ( `rmatch' == 0 ) {
                local unknown `unknown' `stat'
            }
        }
    }

    if ( `"`unknown'"' != "" ) {
        disp as err `"Unknown transformations: `unknown'"'
        exit 198
    }

    * if ( !`:list __gtools_gst_uniq_vars === __gtools_gst_vars' ) {
    *     if ( `"`greedy'"' == "nogreedy" ) {
    *         disp as err "gstats_transform: nogreedy not allowed with repeat sources"
    *         exit 198
    *     }
    * }

    gstats_transform_types,             ///
        vars(`__gtools_gst_vars')       ///
        targets(`__gtools_gst_targets') ///
        stats(`__gtools_gst_stats')     ///
        types(`types')                  ///
        ties(`ties')                    ///
        prefix(__gtools_gst)

    local kvars:    list sizeof __gtools_gst_vars
    local ktargets: list sizeof __gtools_gst_targets
    local kstat:    list sizeof __gtools_gst_stats
    local ktype:    list sizeof __gtools_gst_types
    local kretype:  list sizeof __gtools_gst_retype
    local ktcodes:  list sizeof __gtools_gst_tcodes

    local kbad = 0
    local kbad = `kbad' | (`kvars' != `ktargets')
    local kbad = `kbad' | (`kvars' != `kstat')
    local kbad = `kbad' | (`kvars' != `ktype')
    local kbad = `kbad' | (`kvars' != `kretype')
    local kbad = `kbad' | (`kvars' != `ktcodes')

    if ( `kbad' ) {
        disp as err "gstats_transform: parsing error (inconsistent number of inputs)"
        exit 198
    }

    * Parse variables to add
    * ----------------------

    * A variable needs to be "retyped" only if a target exists already
    * and it has an unsuitable type. One of two things happens:
    *
    *     a) The target is also a source. Source gets renamed, used as
    *        input, dropped.
    *
    *     b) The target is not a source. Target is renamed, dropped.

    local __gtools_gst_i = 0
    local __gtools_gst_dropvars
    local __gtools_gst_vars: subinstr local __gtools_gst_vars " "  "  ", all

    local krecast = 0
    local recast_sources
    local recast_targets

    forvalues k = 1 / `ktargets' {
        local retype: word `k' of `__gtools_gst_retype'
        local target: word `k' of `__gtools_gst_targets'

        cap confirm new variable `target'
        if ( _rc ) {
            if ( `"`replace'"' == "" ) {
                disp as err "gstats_transform: target `target' exists without replace"
                exit 198
            }

            if ( `retype' ) {
                cap confirm new variable __gtools_gst`__gtools_gst_i'
                while ( _rc ) {
                    local ++__gtools_gst_i
                    cap confirm new variable __gtools_gst`__gtools_gst_i'
                }
                rename `target' __gtools_gst`__gtools_gst_i'
                local __gtools_gst_dropvars `__gtools_gst_dropvars' __gtools_gst`__gtools_gst_i'

                if ( `:list target in __gtools_gst_vars' ) {
                    local __gtools_gst_vars: subinstr local __gtools_gst_vars " `target' " " __gtools_gst`__gtools_gst_i' ", all
                    local recast_sources `recast_sources' __gtools_gst`__gtools_gst_i'
                    local recast_targets `recast_targets' `target'
                    local ++krecast
                }
            }

            local __gtools_gst_vars: subinstr local __gtools_gst_vars "  " " ", all
        }
    }

    local kadd = 0
    local __gtools_gst_addvars
    local __gtools_gst_addtypes
    forvalues k = 1 / `ktargets' {
        local target: word `k' of `__gtools_gst_targets'
        local type:   word `k' of `__gtools_gst_types'
        cap confirm new variable `target'
        if ( _rc == 0 ) {
            local ++kadd
            local __gtools_gst_addvars  `__gtools_gst_addvars'  `target'
            local __gtools_gst_addtypes `__gtools_gst_addtypes' `type'
        }
    }

    * Group stat codes
    * ----------------

    * -1          // sum
    * -2          // mean
    * -3          // sd
    * -4          // max
    * -5          // min
    * -6          // count, n
    * -7          // percent
    * 50          // median
    * -9          // iqr
    * -10         // first
    * -11         // firstnm
    * -12         // last
    * -13         // lastnm
    * -14         // freq
    * -15         // semean
    * -16         // sebinomial
    * -17         // sepoisson
    * -18         // nunique
    * -19         // skewness
    * -20         // kurtosis
    * -21         // rawsum
    * -22         // nmissing
    * -23         // variance
    * -24         // cv
    * -25         // range
    * -26         // geomean
    * -27         // gini
    * -27.1       // gini|dropneg
    * -27.2       // gini|keepneg
    * -101        // nansum
    * -121        // rawnansum
    * -206        // sum weight
    * -203        // variance
    * 1000 + #    // #th smallest
    * -1000 - #   // #th largest
    * 1000.5 + #  // raw #th smallest
    * -1000.5 - # // raw #th largest

    * Transform codes
    * ---------------

    * -1          // standardize normalize
    * -2          // demean
    * -3          // demedian
    * -4          // moving
    *             //     syntax via stat call
    *             //
    *             //         (moving stat lower upper)
    *             //
    *             //     and/or via window() option
    *             //
    *             //         window(lower upper)
    *             //
    *             //     window() fills stat calls w/o lower/upper.
    *             //
    * -5          // range
    *             //     syntax via stat call
    *             //
    *             //         (range stat lower upper [reference])
    *             //
    *             //     and/or via interval() option
    *             //
    *             //         interval(lower upper [reference])
    *             //
    *             //     interval() fills stat calls w/o lower/upper.
    *             //     reference is the reference variable; if empty
    *             //     the source is taken as its own reference. lower
    *             //     an upper can be statistical transformations:
    *             //
    *             //         (range mean -2sd  0.5sd)
    *             //         (range skew -2    1.5cv)
    *             //         interval(-sd sd varname)
    *             //
    *             //     if either lower or upper are not numbers then
    *             //     they will try to be parsed in the format above.
    *             //     the number in front of the stat is multipled by
    *             //     the stat requested. so (range mean -2sd 0.5sd)
    *             //     will compute for x[i] the average over j s.t.
    *             //     x[i] - 2 * sd(x) <= x[j] <= x[i] + 0.5 * sd(x)
    * -6          // rank
    * -7          // cummsum
    *             //     syntax via stata call
    *             //
    *             //         (cumsum)
    *             //         (cumsum +/-)
    *             //         (cumsum +/- varlist)
    *             //
    *             //     and/or via cumby() option
    *             //
    *             //         cumby(+/-)
    *             //         cumby(+/- varlist)
    *             //
    *             //     cumsum happens in the order th data appears or
    *             //     in ascending/descending order. if varlist then
    *             //     cumsum happens in ascending or descending order
    *             //     or varlist.
    * -8          // shift
    *             //     syntax via stata call
    *             //
    *             //         (shift) for use with shift()
    *             //         (shift -#)  for lags
    *             //         (shift #) for leads
    *             //
    *             //     where shiftby() is an integer
    *             //
    *             //         shiftby(-#) for lags
    *             //         shiftby(#) for leads

    * moving stats
    * ------------

    * __gtools_transform_moving
    *     stat code with the statistic to compute in the moving window.
    *     e.g. (-2, 0, -3, 0, 75) means moving mean, non-moving stat,
    *     moving sd, non-moving stat, and moving 75th percentile.
    *
    * __gtools_transform_moving_l
    *     lower window bound. -1 means from the prior obs, . means all
    *     obs before, 0 means start at current obs, etc.
    *
    * __gtools_transform_moving_u
    *     upper window bound. 1 means up to the next obs, . means all
    *     obs after, 0 means end at current obs, etc.

    * Range stats
    * -----------

    * __gtools_transform_range
    *     stat code with the statistic to compute in the interval window.
    *     e.g. (-2, 0, -3, 0, 75) means range mean, non-range stat,
    *     range sd, non-range stat, and range 75th percentile.
    *
    * __gtools_transform_range_xs
    *
    * __gtools_transform_range_xb
    *
    * __gtools_transform_range_k
    *     number of reference range variables
    *
    * __gtools_transform_range_pos
    *     position of reference range variable. i.e. the input is
    *
    *         [byvars] sources targets [rangevars] [weightvar]
    *
    *     the kth entry of this matrix maps the kth source with the
    *     corresponding reference range variable. if the reference
    *     variable is the source, this is 0.
    *
    * __gtools_transform_range_l
    * __gtools_transform_range_u
    *
    *     lower and upper range windows for the kth statistic, if it is
    *     an range statistic. The ith observation is computed over
    *     sources[j, k] s.t.
    *
    *         lower <= sources[j, k] <= upper
    *
    *     where
    *
    *         l     = __gtools_transform_range_pos[k]
    *         lower = rangevars[i, l] + __gtools_transform_range_l[k]
    *         upper = rangevars[i, l] + __gtools_transform_range_u[k]
    *
    *     If l is 0 then this is computed with
    *
    *         lower = sources[i, k] + __gtools_transform_range_l[k]
    *         upper = sources[i, k] + __gtools_transform_range_u[k]
    *
    *     Note that both lower and upper are ADDED, so lower must be
    *     npassed as a negative umber if you want to subtract it.
    *
    *     Last, if the range has a reference statistic attached to
    *     it, then lower/upper are the scalar it multiplies:
    *
    *         lscalar = __gtools_transform_range_l[k]
    *         uscalar = __gtools_transform_range_u[k]
    *         lower   = rangevars[i, l] + lscalar * lstat[k]
    *         upper   = rangevars[i, l] + uscalar * ustat[k]
    *
    *     or
    *
    *         lower   = sources[i, k] + lscalar * lstat[k]
    *         upper   = sources[i, k] + uscalar * ustat[k]
    *
    *     as applicable. For details on lstat and ustat see below.
    *
    * __gtools_transform_range_ls
    * __gtools_transform_range_us
    *
    *     lower and upper range statistics for the kth statistic,
    *     if it is an range statistic and if a statistical
    *     transformation was requested. Lower and upper bounds
    *     lstat[k] and ustat[k] referenced above are obtained from
    *     rangevars[i, l] or sources[i, k], as applicable. The
    *     requested statistic is computed over all i.
    *
    *     these vectors contain the code's statistic. if there is
    *     no reference statistic, the entry is just 0. For example,
    *     this computes the mean price within a standard deviation:
    *
    *         (range mean -sd sd) price
    *
    *         l       = __gtools_transform_range_pos[k] <- 0
    *         lscalar = __gtools_transform_range_l[k]   <- -1
    *         uscalar = __gtools_transform_range_u[k]   <- 1
    *
    *         lcode   = __gtools_transform_range_ls[k]  <- -3
    *         ucode   = __gtools_transform_range_us[k]  <- -3
    *         lstat   = sd(sources[i, k]) over all i
    *         ustat   = sd(sources[i, k]) over all i
    *
    *         lower   = sources[i, k] + lscalar * lstat
    *         upper   = sources[i, k] + uscalar * ustat
    *
    *         ith output obs = mean(sources[j, k]) s.t. lower <= sources[j, k] <= upper

    * Cummulative Sum
    * ---------------

    * __gtools_transform_cumsum_k
    *
    *     number of aux variables for cumsum
    *
    * __gtools_transform_cumtypes
    *
    *     types for cumvars
    *
    * __gtools_transform_cumsum
    *
    *     0/1 for whther kth target stat is cumsum
    *
    * __gtools_transform_cumsign
    *
    *     whether cumsum should be in data (0), ascending (1), or
    *     descending (2) order
    *
    * __gtools_transform_cumvars
    *
    *     start and end position of cumvars for each target

    * Shift (lads and leads)
    * ----------------------

    * __gtools_transform_aux8_shift
    *
    *     number (positive or negative) to shift kth target by

    * Transform mappings
    * ------------------

    * There are two sets of stats: The transformations and the group
    * stats that the transformations use. For example, normalizing a
    * variable uses the mean and standard deviation. Each transform has
    * an internal code for its group stats. normalize has codes 1 and 2
    * for the mean and standard deviation, demedian has code 1 for the
    * median, and so on. Hence we create a matrix with mappings from
    * each stat to their stat's position on the array of group stats. If
    * we have stats(demedian demean normalize) we get
    *
    *     __gtools_transform_varfuns  // code for variable transforms
    *     demedian demean normalize
    *     -3       -2     -1
    *
    *     __gtools_transform_statcode // code for group stats
    *     50     -2   -3
    *     median mean sd
    *
    *     __gtools_transform_statmap  // mapping from transforms to the group stats
    *     1 0 0
    *     2 0 0
    *     2 3 0
    *
    * The group stat array will have first the median, then the mean,
    * then the standard deviation. Hence demedian will use the first
    * stat, demean the second, and normalize the second and third.

    * Generate matrices for plugin internals
    * --------------------------------------

    local gs_nostats_codes -4 -5 -6 -7 -8

    local gs_standardize mean sd
    local gs_normalize   mean sd
    local gs_demean      mean
    local gs_demedian    median
    local gs_moving
    local gs_range
    local gs_rank
    local gs_cumsum
    local gs_shift

    local gs
    local rangevars

    foreach stat of local __gtools_gst_stats {
        local gs `gs' `gs_`stat''
        encode_range `stat'
        local rangevars `rangevars' `r(var)'
    }

    local gs: list uniq gs
    local rangevars: list uniq rangevars

    mata: __gtools_transform_varfuns    = J(1, `:list sizeof __gtools_gst_stats', .)
    mata: __gtools_transform_statcode   = J(1, max((`:list sizeof gs', 1)), 0)
    mata: __gtools_transform_statmap    = J(`:list sizeof __gtools_gst_stats', max((`:list sizeof gs', 1)), 0)

    mata: __gtools_transform_moving     = J(1, `:list sizeof __gtools_gst_stats', 0)
    mata: __gtools_transform_moving_l   = J(1, `:list sizeof __gtools_gst_stats', .)
    mata: __gtools_transform_moving_u   = J(1, `:list sizeof __gtools_gst_stats', .)

    mata: __gtools_transform_range      = J(1, `:list sizeof __gtools_gst_stats', 0)
    mata: __gtools_transform_range_pos  = J(1, `:list sizeof __gtools_gst_stats', 0)
    mata: __gtools_transform_range_l    = J(1, `:list sizeof __gtools_gst_stats', .)
    mata: __gtools_transform_range_u    = J(1, `:list sizeof __gtools_gst_stats', .)
    mata: __gtools_transform_range_ls   = J(1, `:list sizeof __gtools_gst_stats', 0)
    mata: __gtools_transform_range_us   = J(1, `:list sizeof __gtools_gst_stats', 0)

    mata: __gtools_transform_cumsum     = J(1, `:list sizeof __gtools_gst_stats',     0)
    mata: __gtools_transform_cumsign    = J(1, `:list sizeof __gtools_gst_stats',     0)
    mata: __gtools_transform_cumvars    = J(1, `:list sizeof __gtools_gst_stats' + 1, 0)

    mata: __gtools_transform_aux8_shift = J(1, `:list sizeof __gtools_gst_stats', 0)

    forvalues l = 1 / `:list sizeof gs' {
        local gstat: word `l' of `gs'
        encode_stat_allowed `gstat' 0
        mata: __gtools_transform_statcode[`l'] = `r(statcode)'
    }

    local bwarn4 = 0
    local bwarn5 = 0

    local rwarn = 0
    local iwarn = 0

    local cumvars
    forvalues k = 1 / `:list sizeof __gtools_gst_stats' {
        local stat:  word `k' of `__gtools_gst_stats'

             if ( "`stat'" == "standardize" ) local statcode -1
        else if ( "`stat'" == "normalize"   ) local statcode -1
        else if ( "`stat'" == "demean"      ) local statcode -2
        else if ( "`stat'" == "demedian"    ) local statcode -3
        else if ( "`stat'" == "rank"        ) local statcode -6
        else                                  local statcode 0

        * moving matrices
        encode_moving `stat'
        local rwarn = `rwarn' | `r(warn)'
        if ( `r(match)' ) {
            if ( `r(scode)' == 0 ) {
                disp as err "gstats_transform: moving parsing error; unknown substat"
                exit 198
            }
            local statcode -4
            local bwarn4 = 1
            mata: __gtools_transform_moving[`k']   = `r(scode)'
            mata: __gtools_transform_moving_l[`k'] = `r(lower)'
            mata: __gtools_transform_moving_u[`k'] = `r(upper)'
        }

        * interval matrices
        encode_range `stat'
        local iwarn = `iwarn' | `r(warn)'
        if ( `r(match)' ) {
            if ( `r(scode)' == 0 ) {
                disp as err "gstats_transform: range parsing error; unknown substat"
                exit 198
            }
            local statcode -5
            local bwarn5 = 1
            mata: __gtools_transform_range[`k']     = `r(scode)'
            mata: __gtools_transform_range_l[`k']   = `r(lower)'
            mata: __gtools_transform_range_u[`k']   = `r(upper)'
            mata: __gtools_transform_range_ls[`k']  = `r(lcode)'
            mata: __gtools_transform_range_us[`k']  = `r(ucode)'
            mata: __gtools_transform_range_pos[`k'] = `:list posof "`r(var)'" in rangevars'
        }

        * cumsum matrices
        encode_cumsum `stat'
        if ( `r(match)' ) {
            local statcode -7
            local cumvars `cumvars' `r(cumvars)'
            if ( !inlist(`:word count `r(cumvars)'', 0, 1) ) {
                disp as err "gstats_transform: cumby for multiple variables not implemented"
                exit 198
            }
            mata: __gtools_transform_cumsum[`k']  = 1
            mata: __gtools_transform_cumsign[`k'] = `r(cumsign)'
            mata: __gtools_transform_cumvars[`=`k'+1'] = `:list sizeof cumvars'
        }

        * shift matrices
        encode_shift `stat'
        if ( `r(match)' ) {
            local statcode -8
            mata: __gtools_transform_aux8_shift[`k'] = `r(shift)'
        }

        * other matrices
        if ( `statcode' == 0 ) {
            disp as err "gstats_transform: unknown stat `stat'"
            exit 198
        }

        mata: __gtools_transform_varfuns[`k'] = `statcode'
        if ( !`:list statcode in gs_nostats_codes' ) {
            forvalues l = 1 / `:list sizeof gs' {
                local gstat: word `l' of `gs'
                forvalues m = 1 / `:list sizeof gs_`stat'' {
                    mata: __gtools_transform_statmap[`k', `m'] = `:list posof "`:word `m' of `gs_`stat'''" in gs'
                }
            }

            cap mata: assert(all(rowsum(__gtools_transform_statmap[`k', .] :> 0) :> 0))
            if ( _rc ) {
                disp as err "gstats_transform: error parsing transform mappings"
                exit 198
            }
        }
    }

    * if ( `bwarn4' ) {
    *     disp as txt "{bf:warning}: requested transform {bf:'moving'} is in beta"
    * }
    *
    * if ( `bwarn5' ) {
    *     disp as txt "{bf:warning}: requested transform {bf:'range'} is in beta"
    * }

    if ( `rwarn' ) {
        disp as txt "{bf:note:} requested moving statistic without a window"
    }

    if ( `iwarn' ) {
        disp as txt "{bf:note:} requested range statistic without an interval"
    }

    * NOTE(mauricio): Unlike gcollapse, here we can't really have a set
    * of unique sources that get mapped to multiple targets because each
    * source gets transformed! So you will need to read each source in
    * unmodified for as many targets as you have.

    * TODO: strL support
    local cumvars `cumvars'
    if ( `"`cumvars'"' != "" ) {
        GenericParseTypes `cumvars', mat(__gtools_transform_cumtypes)
        forvalues i = 1 / `:list sizeof cumvars' {
            cap mata assert(st_matrix("__gtools_transform_cumtypes")[`i'] :<= 0)
            if ( _rc ) {
                disp as err "gstats_transform: cumby for string types not implemented"
                exit 198
            }
        }
    }

    mata {
        if ( (`"`excludeself'"'   != "") &  any(__gtools_transform_varfuns :!= -5) ) {
            if ( all(__gtools_transform_varfuns :!= -5) ) {
                printf("gstats_transform: option -excludeself- not allowed (only with transform range)\n")
                _error(198)
            }
            else {
                printf("gstats_transform: excludeself ignored for stats other than range\n")
            }
        }
    }

    * Return varlist for plugin internals
    * -----------------------------------
    scalar __gtools_transform_greedy    = (`"`greedy'"' != "nogreedy")
    scalar __gtools_transform_kvars     = `:list sizeof __gtools_gst_vars'
    scalar __gtools_transform_ktargets  = `:list sizeof __gtools_gst_targets'
    scalar __gtools_transform_kgstats   = `:list sizeof gs'
    scalar __gtools_gstats_code         = 3
    scalar __gtools_transform_cumsum_k  = `:list sizeof cumvars'
    scalar __gtools_transform_range_k   = `:list sizeof rangevars'
    scalar __gtools_transform_range_xs  = (`"`excludeself'"'   != "")
    scalar __gtools_transform_range_xb  = (`"`excludebounds'"' != "")

    mata: st_matrix("__gtools_transform_rank_ties", strtoreal(tokens(st_local("__gtools_gst_tcodes"))))
    mata: st_matrix("__gtools_transform_varfuns",    __gtools_transform_varfuns)
    mata: st_matrix("__gtools_transform_statmap",    __gtools_transform_statmap)
    mata: st_matrix("__gtools_transform_statcode",   __gtools_transform_statcode)

    mata: st_matrix("__gtools_transform_moving",     __gtools_transform_moving)
    mata: st_matrix("__gtools_transform_moving_l",   __gtools_transform_moving_l)
    mata: st_matrix("__gtools_transform_moving_u",   __gtools_transform_moving_u)

    mata: st_matrix("__gtools_transform_range",      __gtools_transform_range)
    mata: st_matrix("__gtools_transform_range_pos",  __gtools_transform_range_pos)
    mata: st_matrix("__gtools_transform_range_l",    __gtools_transform_range_l)
    mata: st_matrix("__gtools_transform_range_u",    __gtools_transform_range_u)
    mata: st_matrix("__gtools_transform_range_ls",   __gtools_transform_range_ls)
    mata: st_matrix("__gtools_transform_range_us",   __gtools_transform_range_us)

    mata: st_matrix("__gtools_transform_cumsum",     __gtools_transform_cumsum)
    mata: st_matrix("__gtools_transform_cumsign",    __gtools_transform_cumsign)
    mata: st_matrix("__gtools_transform_cumvars",    __gtools_transform_cumvars)

    mata: st_matrix("__gtools_transform_aux8_shift", __gtools_transform_aux8_shift)

    c_local varlist `__gtools_gst_vars' `__gtools_gst_targets' `rangevars' `cumvars'

    * Check if any of the target is any type of source
    local common: list cumvars | rangevars
    local common: list common  | __gtools_gst_vars
    c_local gstats_replace_anysrc: list common & __gtools_gst_targets

    * Potential intensive operations: Add, recast targets
    * ---------------------------------------------------

    if ( `kadd' ) {
        mata: (void) st_addvar(tokens(`"`__gtools_gst_addtypes'"'), tokens(`"`__gtools_gst_addvars'"'))
    }

    if ( `krecast' ) {
        scalar __gtools_k_recast = `krecast'
        cap noi plugin call gtools_plugin `recast_targets' `recast_sources', recast
        local rc = _rc
        cap scalar drop __gtools_k_recast
        if ( `rc' ) {
            exit `rc'
        }
    }

    mata __gtools_gst_dropvars = tokens(`"`__gtools_gst_dropvars'"')
    forvalues k = 1 / `ktargets' {
        mata: st_varlabel( `"`:word `k' of `__gtools_gst_targets''"', __gtools_gst_labels[`k'])
        mata: st_varformat(`"`:word `k' of `__gtools_gst_targets''"', __gtools_gst_formats[`k'])
    }

    c_local gstats_replace: copy local replace
    c_local gstats_init:    copy local init
    c_local gstats_greedy:  copy local greedy
end

* NOTE: Copy/paste from gcollapse.ado/parse_vars

capture program drop gstats_transform_parse
program gstats_transform_parse
    syntax anything(equalok), ///
    [                         ///
        WILDparse             /// parse assuming wildcard renaming
        autorename            /// automagically name targets if no target is specified
        autorenameformat(str) ///
        window(passthru)      /// moving window if not specified in the stat
        interval(passthru)    /// interval if not specified in the stat
        cumby(passthru)       /// cummulative sum by +/- and varlst if not specified in the stat
        shiftby(passthru)     /// Shift by +/-#
        statprefix(passthru)  /// add prefix to every stat
        labelformat(str)      /// label prefix
        labelprogram(str)     /// label program
    ]

    * Parse call into list of sources, targets, stats
    * -----------------------------------------------

    local opts     prefix(__gtools_gst) default(demean)
    local passthru `window' `interval' `cumby' `shiftby' `statprefix'
    if ( "`wildparse'" != "" ) {
        local rc = 0

        ParseListWild `anything', loc(__gtools_gst_call) `opts' `passthru'

        local __gtools_bak_stats      : copy local __gtools_gst_stats
        local __gtools_bak_vars       : copy local __gtools_gst_vars
        local __gtools_bak_targets    : copy local __gtools_gst_targets
        local __gtools_bak_uniq_stats : copy local __gtools_gst_uniq_stats
        local __gtools_bak_uniq_vars  : copy local __gtools_gst_uniq_vars

        ParseList `__gtools_gst_call',  `opts' `passthru'

        cap assert ("`__gtools_gst_stats'"      == "`__gtools_bak_stats'")
        local rc = max(_rc, `rc')

        cap assert ("`__gtools_gst_vars'"       == "`__gtools_bak_vars'")
        local rc = max(_rc, `rc')

        cap assert ("`__gtools_gst_targets'"    == "`__gtools_bak_targets'")
        local rc = max(_rc, `rc')

        cap assert ("`__gtools_gst_uniq_stats'" == "`__gtools_bak_uniq_stats'")
        local rc = max(_rc, `rc')

        cap assert ("`__gtools_gst_uniq_vars'"  == "`__gtools_bak_uniq_vars'")
        local rc = max(_rc, `rc')

        if ( `rc' ) {
            disp as error "gstats_transform_parse: Wild parsing inconsistent with standard parsing."
            exit 198
        }
    }
    else {
        ParseList `anything', `opts' `passthru'
    }

    if ( `"`autorenameformat'"' != "" ) local autorename       autorename
    if ( `"`autorenameformat'"' == "" ) local autorenameformat #source#_#stat#

    if ( `"`autorename'"' != "" ) {
        local targets
        forvalues k = 1 / `:list sizeof __gtools_gst_vars' {
            local stat:   word `k' of `__gtools_gst_stats'
            local var:    word `k' of `__gtools_gst_vars'
            local target: word `k' of `__gtools_gst_targets'
            if ( `"`var'"' == `"`target'"' ) {
                local sname = strtoname(`"`stat'"')
                local autoname: subinstr local autorenameformat "#source#" "`var'",   all
                local autoname: subinstr local autoname         "#stat#"   "`sname'", all
                local targets `targets' `autoname'
            }
            else {
                local targets `targets' `target'
            }
        }
        local __gtools_gst_targets: copy local targets
    }

    unab  __gtools_gst_vars:         `__gtools_gst_vars'
    unab  __gtools_gst_uniq_vars:    `__gtools_gst_uniq_vars'
    local __gtools_gst_uniq_targets: list uniq __gtools_gst_targets

    if ( !`:list __gtools_gst_uniq_targets === __gtools_gst_targets' ) {
        disp as err "gstats_transform_parse: repeat targets found in function call"
        exit 198
    }

    * Get format and labels from sources
    * ----------------------------------

    if ( "`labelformat'" == "") local labelformat "(#stat#) #sourcelabel#"

    local lnice_regex "(.*)(#stat:pretty#)(.*)"
    local lpre_regex  "(.*)(#stat#)(.*)"
    local lPre_regex  "(.*)(#Stat#)(.*)"
    local lPRE_regex  "(.*)(#STAT#)(.*)"
    local ltxt_regex  "(.*)(#sourcelabel#)(.*)"
    local lsub_regex  "(.*)#sourcelabel:([0-9]+):([.0-9]+)#(.*)"

    mata: __gtools_gst_labels  = J(1, `:list sizeof __gtools_gst_targets', "")
    mata: __gtools_gst_formats = J(1, `:list sizeof __gtools_gst_targets', "")
    forvalues k = 1 / `:list sizeof __gtools_gst_targets' {
        local vl = `"`:variable label `:word `k' of `__gtools_gst_vars'''"'
        local vl = cond(`"`vl'"' == "", `"`:word `k' of `__gtools_gst_vars''"', `"`vl'"')
        local vp = `"`:word `k' of `__gtools_gst_stats''"'

        if ( "`labelprogram'" == "" ) GtoolsPrettyStat `vp'
        else `labelprogram' `vp'
        local vpretty = `"`r(prettystat)'"'

        if ( `"`vpretty'"' == "#default#" ) {
            GtoolsPrettyStat `vp'
            local vpretty = `"`r(prettystat)'"'
        }

        local lfmt_k = `"`labelformat'"'

        if ( "`vp'" == "freq" ) {
            if !regexm(`"`vl'"', "`ltxt_regex'") {
                while regexm(`"`lfmt_k'"', "`ltxt_regex'") {
                    local lfmt_k = regexs(1) + `""' + regexs(3)
                }
            }
            if !regexm(`"`vl'"', "`lsub_regex'") {
                while regexm(`"`lfmt_k'"', "`lsub_regex'") {
                    local lfmt_k = regexs(1) + `""' + regexs(4)
                }
            }
        }
        else {
            if !regexm(`"`vl'"', "`ltxt_regex'") {
                while regexm(`"`lfmt_k'"', "`ltxt_regex'") {
                    local lfmt_k = regexs(1) + `"`vl'"' + regexs(3)
                }
            }
            if !regexm(`"`vl'"', "`lsub_regex'") {
                while regexm(`"`lfmt_k'"', "`lsub_regex'") {
                    local lfmt_k = regexs(1) + substr(`"`vl'"', `:di regexs(2)', `:di regexs(3)') + regexs(4)
                }
            }
        }

        if !regexm(`"`vpretty'"', "`lnice_regex'") {
            while regexm(`"`lfmt_k'"', "`lnice_regex'") {
                local lfmt_k = regexs(1) + `"`vpretty'"' + regexs(3)
            }
        }
        if !regexm(`"`vp'"', "`lpre_regex'") {
            while regexm(`"`lfmt_k'"', "`lpre_regex'") {
                local lfmt_k = regexs(1) + `"`vp'"' + regexs(3)
            }
        }
        if !regexm(`"`vp'"', "`lPre_regex'") {
            while regexm(`"`lfmt_k'"', "`lPre_regex'") {
                local lfmt_k = regexs(1) + proper(`"`vp'"') + regexs(3)
            }
        }
        if !regexm(`"`vp'"', "`lPRE_regex'") {
            while regexm(`"`lfmt_k'"', "`lPRE_regex'") {
                local lfmt_k = regexs(1) + upper(`"`vp'"') + regexs(3)
            }
        }
        mata: __gtools_gst_labels[`k'] = `"`lfmt_k'"'

        local vf = "`:format `:word `k' of `__gtools_gst_vars'''"
        local vf = cond(inlist(`"`:word `k' of `__gtools_gst_stats''"', "count", "freq", "nunique", "nmissing"), "%8.0g", "`vf'")
        mata: __gtools_gst_formats[`k'] = "`vf'"
    }

    * Locals one level up
    * -------------------

    c_local __gtools_gst_targets    : copy local __gtools_gst_targets
    c_local __gtools_gst_vars       : copy local __gtools_gst_vars
    c_local __gtools_gst_stats      : copy local __gtools_gst_stats
    c_local __gtools_gst_uniq_vars  : copy local __gtools_gst_uniq_vars
    c_local __gtools_gst_uniq_stats : copy local __gtools_gst_uniq_stats
end

capture program drop gstats_transform_types
program gstats_transform_types
    syntax, vars(str) targets(str) stats(str) prefix(str) [types(str) ties(str)]

    * Check all inputs are numeric
    * ----------------------------

    cap confirm var `vars'
    if ( _rc ) {
        disp as err "gstats_transform_types: sources must exit"
        exit 198
    }

    cap confirm numeric var `vars'
    if ( _rc ) {
        disp as err "gstats_transform_types: numeric sources required"
        exit 198
    }

    local sametype standardize ///
                   normalize   ///
                   demean      ///
                   demedian    ///

    local upgrade
    local types
    local retype

    * Special parsing for rank type
    * -----------------------------

    if ( (`:list sizeof ties' > 1) & (`:list sizeof ties' != `:list sizeof targets') ) {
        disp as err "gstats_transform_types: only one tie-break or one tie-break per target in ties()"
        exit 198
    }

    if ( scalar(__gtools_weight_code) > 0 ) {
        local mintype_rank double
    }
    else if ( `=_N' < maxbyte() ) {
        local mintype_rank byte
    }
    else if ( `=_N' < maxint() ) {
        local mintype_rank int
    }
    else if ( `=_N' < maxlong() ) {
        local mintype_rank long
    }
    else {
        local mintype_rank double
    }

    local tcodes
    local rtypes
    local default       d de def defa defau defaul default .
    local field         f fi fie fiel field
    local track         t tr tra trac track
    local unique        u un uni uniq uniqu unique
    local stableunique  s st sta stab stabl stable stableu stableun stableuni stableuniq stableuniqu stableunique

    if ( `:list sizeof ties' > 1 ) {
        foreach t of local ties {
            if ( `:list t in default' | (`"`t'"' == "") ) {
                local ties_code = 1
                local rtype = cond(`"`mintype_rank'"' != "double", "`:set type'", "double")
            }
            else if ( `:list t in field' ) {
                local ties_code = 2
                local rtype `mintype_rank'
            }
            else if ( `:list t in track' ) {
                local ties_code = 3
                local rtype `mintype_rank'
            }
            else if ( `:list t in unique' ) {
                local ties_code = 4
                local rtype `mintype_rank'
            }
            else if ( `:list ties in stableunique' ) {
                local ties_code = 5
                local rtype `mintype_rank'
            }
            else {
                disp as err "ties(`t') not allowed"
                exit 198
            }
            local tcodes `tcodes' `ties_code'
            local rtypes `rtypes' `rtype'
        }
    }
    else {
        if ( `:list ties in default' | (`"`ties'"' == "") ) {
            local ties_code = 1
            local rtype = cond(inlist(`"`mintype_rank'"', "long", "double"), "double", "`:set type'")
        }
        else if ( `:list ties in field' ) {
            local ties_code = 2
            local rtype `mintype_rank'
        }
        else if ( `:list ties in track' ) {
            local ties_code = 3
            local rtype `mintype_rank'
        }
        else if ( `:list ties in unique' ) {
            local ties_code = 4
            local rtype `mintype_rank'
        }
        else if ( `:list ties in stableunique' ) {
            local ties_code = 5
            local rtype `mintype_rank'
        }
        else {
            disp as err "gstats_transform_types: ties(`ties') not allowed"
            exit 198
        }

        forvalues k = 1 / `:list sizeof targets' {
            local tcodes `tcodes' `ties_code'
            local rtypes `rtypes' `rtype'
        }
    }

    * If types are empty, autoretype; else use user input
    * ---------------------------------------------------

    * NOTE(mauricio): retype is 1 if the target exists and the type is
    * unsuitable or if the target does not exist (since "" will not
    * equal any named type). In the former case retype is necessary,
    * in the latter retype will get ignored and a new variable will be
    * created.

    if ( `"`types'"' == "" ) {
        forvalues k = 1 / `:list sizeof vars' {
            gettoken var    vars:    vars
            gettoken target targets: targets
            gettoken stat   stats:   stats
            gettoken rtype  rtypes:  rtypes

            local var    `var'
            local target `target'
            local stat   `stat'
            local rtype  `rtype'
            local type:  type `var'

            cap confirm var `target'
            if ( _rc ) local ttype
            else local ttype: type `target'

            encode_moving `stat'
            local rmatch = `r(match)'
            if ( `r(match)' ) {
                encode_stat_types `r(stat)' `type' `ttype'
                local types  `types'  `r(type)'
                local retype `retype' `r(retype)'
            }

            encode_range `stat'
            local rmatch = `r(match)' | `rmatch'
            if ( `r(match)' ) {
                encode_stat_types `r(stat)' `type' `ttype'
                local types  `types'  `r(type)'
                local retype `retype' `r(retype)'
            }

            encode_cumsum `stat'
            local rmatch = `r(match)' | `rmatch'
            if ( `r(match)' ) {
                local types  `types'  double
                local retype `retype' `=!inlist("`ttype'", "double")'
            }

            * shift follows the same retype logic as min, max, first, last, etc.
            encode_shift `stat'
            local rmatch = `r(match)' | `rmatch'
            if ( `r(match)' ) {
                encode_stat_types first `type' `ttype'
                local types  `types'  `type'
                local retype `retype' `r(retype)'
            }

            if ( `"`stat'"' == "rank" ) {
                local types `types' `rtype'
                if ( inlist("`ttype'", "`rtype'", "double") ) {
                    local retype `retype' 0
                }
                else if ( "`ttype'" == "float" ) {
                    local retype `retype' `=inlist("`rtype'", "long", "double")'
                }
                else if ( "`ttype'" == "long" ) {
                    local retype `retype' `=inlist("`rtype'", "double")'
                }
                else if ( "`ttype'" == "int" ) {
                    local retype `retype' `=!inlist("`rtype'", "int", "byte")'
                }
                else if ( "`ttype'" == "byte" ) {
                    local retype `retype' `=!inlist("`rtype'", "byte")'
                }
                else if ( "`ttype'" == "" ) {
                    local retype `retype' 1
                }
                else {
                    disp as err "gstats_transform_types: Unable to parse type '`ttype''"
                    exit 198
                }
                local rmatch = 1
            }

            if ( `rmatch' == 0 ) {
                if inlist(`"`type'"', "long") {
                    local types   `types'  double
                    local retype  `retype' `=!inlist("`ttype'", "double")'
                }
                else if inlist(`"`type'"', "int", "byte") {
                    local types   `types'  `:set type'
                    local retype  `retype' `=!inlist("`ttype'", "`:set type'", "double")'
                }
                else {
                    if ( `:list stat in sametype' ) {
                        local types  `types'  `type'
                        local retype `retype' `=!inlist("`ttype'", "`type'", "double")'
                    }
                    else if ( `:list stat in upgrade' ) {
                        local types  `types'  double
                        local retype `retype' `=!inlist("`ttype'", "double")'
                    }
                    else {
                        disp as err "gstats_transform_types: Uknown stat found in function call"
                        exit 198
                    }
                }
            }
        }
    }
    else if ( `:list sizeof types' == 1 ) {
        forvalues k = 1 / `:list sizeof targets' {
            local target: word `k' of `targets'
            cap confirm var `target'
            if ( _rc ) local ttype
            else local ttype: type `target'

            local types  `types'  `types'
            local retype `retype' `=("`ttype'" != "`types'")'
        }
    }
    else if ( `:list sizeof types' != `:list sizeof targets' ) {
        disp as err "gstats_transform_types: types() must be a single input or one input per target"
        exit 198
    }
    else {
        forvalues k = 1 / `:list sizeof targets' {
            local tcmp:   word `k' of `types'
            local target: word `k' of `targets'
            cap confirm var `target'
            if ( _rc ) local ttype
            else local ttype: type `target'

            local retype `retype' `=("`ttype'" != "`tcmp'")'
        }
    }

    c_local `prefix'_tcodes: copy local tcodes
    c_local `prefix'_types:  copy local types
    c_local `prefix'_retype: copy local retype
end

capture program drop gstats_hdfe
program gstats_hdfe
    syntax anything(equalok), ///
        absorb(varlist)       ///
    [                         ///
        PREfix(str)           /// generate variables with specified prefix
        GENerate(str)         /// generate specified variables
        replace               /// replace variables, if they exist
        noinit                /// do not initialize targets with missing values
        WILDparse             /// parse assuming wildcard renaming
                              ///
        ABSORBMISSing         /// absorb missing levels
        algorithm(str)        /// alias for method
        method(str)           /// projection method
                              /// map (method of alternating projections)
                              /// squarem
                              /// conjugate gradient|cg
                              /// it|irons tuck
        STANdardize           /// standardize before applying transform
        TRACEiter             /// trace iteration progress
        maxiter(real 100000)  /// maximum number of iterations
        TOLerance(real 1e-8)  /// tolerance for hdfe convergence
        MATAsave              /// save by vars/levels in mata
        MATAsavename(str)     /// name of mata object
                              ///
        individual            /// do not drop missing rows case-wise
    ]

    if ( ("`algorithm'" != "") & ("`method'" != "") ) {
        disp as err "gstats_hdfe: method() is an alias for algorithm(); specify only one"
        exit 198
    }
    if ( `"`algorithm'"' == "" ) local algorithm  cg
    if ( `"`method'"'    != "" ) local algorithm: copy local method
    local method: copy local algorithm

    if ( "`individual'" != "" ) {
        disp as err "gstats_hdfe: option -individual- not implemented; values dropped row-wise"
        exit 198
    }

    if ( `maxiter' < 1 ) {
        disp as err "gstats_hdfe: maxiter() must be >= 1"
        exit 198
    }

    if ( missing(`maxiter') ) local maxiter 0
    local maxiter = floor(`maxiter')

    local __gtools_byvars: copy global GTOOLS_BYNAMES
    * NB: This is tested internally against gregress; should be OK?
    * if ( "${GTOOLS_HDFEBY}" != "1" ) {
    *     if ( "`__gtools_byvars'" != "" ) {
    *         disp as err "gstats hdfe with by() has {bf:NOT} been tested. Try it at your own risk via"
    *         disp as err ""
    *         disp as err "    global GTOOLS_HDFEBY = 1"
    *         exit 198
    *     }
    * }

    if ( `"`matasavename'"' != "" ) local matasave     matasave
    if ( `"`matasavename'"' == "" ) local matasavename GtoolsByLevels

    if ( lower(`"`method'"') == "map" ) {
        local method_code 1
        local method map
    }
    else if ( lower(`"`method'"') == "squarem" ) {
        local method_code 2
        local method squarem
    }
    else if ( inlist(lower(`"`method'"'), "conjugate gradient", "conjugate_gradient", "cg") ) {
        local method_code 3
        local method cg
    }
    else if ( inlist(lower(`"`method'"'), "irons and tuck", "irons tuck", "irons_tuck", "it") ) {
        local method_code 5
        local method it
    }
    else if ( inlist(lower(`"`method'"'), "bit", "berge_it", "berge it") ) {
        * TODO: gives segfault on some runs last I checked; debug someday.
        * Option is undocumented but I leave it here for myself.
        local method_code 6
        local method bit
    }
    else {
        disp as err "gstats_hdfe: method() must be one of: map, squarem, cg, it"
        exit 198
    }

    * ---------------------------------------------------------------------
    * Parse absorb
    * ---------------------------------------------------------------------

    local absorb_uniq: list uniq absorb
    if ( `:list sizeof absorb_uniq' < `:list sizeof absorb' ) {
        disp as txt "warning: duplicate variables in absorb()"
    }

    * TODO: strL support
    GenericParseTypes `absorb', mat(__gtools_hdfe_abstyp)
    matrix __gtools_hdfe_nabsorb = J(1, `:list sizeof absorb', .)

    * ---------------------------------------------------------------------
    * Parse variable targets
    * ---------------------------------------------------------------------

    local gen_clist   = strpos(`"`anything'"', "=") > 0
    local gen_prefix  = ("`prefix'"   != "")
    local gen_direct  = ("`generate'" != "")
    local gen_replace = ("`replace'"  != "")

    if ( !`gen_clist' & !`gen_direct' & !`gen_prefix' & !`gen_replace' ) {
        disp as err "gstats_hdfe: No targets specified and no replace."
        exit 198
    }

    if ( `gen_clist' & `gen_direct' ) {
        disp as err "gstats_hdfe: Cannot specify both generate() and target=source syntax"
        exit 198
    }


    if ( `gen_replace' & ((`gen_clist' + `gen_direct' + `gen_prefix') == 0) ) {
        confirm numeric var `anything'
        unab __gtools_hdfe_vars: `anything'
        local __gtools_hdfe_targets: copy local __gtools_hdfe_vars
    }

    if ( `gen_direct' ) {
        confirm numeric var `anything'
        unab __gtools_hdfe_vars: `anything'
        local __gtools_hdfe_targets: copy local generate
    }

    local opts prefix(__gtools_hdfe) default(hdfe)
    if ( `gen_clist' ) {
        if ( "`wildparse'" != "" ) {
            local rc = 0

            ParseListWild `anything', loc(__gtools_hdfe_call) `opts'

            local __gtools_bak_stats      : copy local __gtools_hdfe_stats
            local __gtools_bak_vars       : copy local __gtools_hdfe_vars
            local __gtools_bak_targets    : copy local __gtools_hdfe_targets
            local __gtools_bak_uniq_stats : copy local __gtools_hdfe_uniq_stats
            local __gtools_bak_uniq_vars  : copy local __gtools_hdfe_uniq_vars

            ParseList `__gtools_hdfe_call',  `opts'

            cap assert ("`__gtools_hdfe_stats'"      == "`__gtools_bak_stats'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_hdfe_vars'"       == "`__gtools_bak_vars'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_hdfe_targets'"    == "`__gtools_bak_targets'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_hdfe_uniq_stats'" == "`__gtools_bak_uniq_stats'")
            local rc = max(_rc, `rc')

            cap assert ("`__gtools_hdfe_uniq_vars'"  == "`__gtools_bak_uniq_vars'")
            local rc = max(_rc, `rc')

            if ( `rc' ) {
                disp as error "gstats_hdfe: Wild parsing inconsistent with standard parsing."
                exit 198
            }
        }
        else {
            ParseList `anything', `opts'
        }
    }

    if ( `gen_clist' & `gen_prefix' ) {
        local _targets
        forvalues k = 1 / `:list sizeof __gtools_hdfe_vars' {
            local target: word `k' of `__gtools_hdfe_targets'
            local source: word `k' of `__gtools_hdfe_vars'
            if ( "`target'" == "`source'" ) {
                local _targets `_targets' `prefix'`target'
            }
            else {
                local _targets `_targets' `target'
            }
        }
        local __gtools_hdfe_targets: copy local _targets
    }
    else if ( `gen_prefix' ) {
        confirm numeric var `anything'
        unab __gtools_hdfe_vars: `anything'
        local __gtools_hdfe_targets
        foreach var of local __gtools_hdfe_vars {
            local __gtools_hdfe_targets `__gtools_hdfe_targets' `prefix'`var'
        }
    }

    foreach var of local __gtools_hdfe_targets {
        cap confirm new var `var'
        if ( _rc & !`gen_replace' ) {
            di as err "Variable `var' exists with no replace."
            exit 198
        }
    }

    * ---------------------------------------------------------------------
    * Parse variable types
    * ---------------------------------------------------------------------

    local __gtools_hdfe_types
    foreach var of local __gtools_hdfe_vars {
        if inlist("`:type `var''", "float", "double") {
            local __gtools_hdfe_types `__gtools_hdfe_types' `:type `var''
        }
        else {
            local __gtools_hdfe_types `__gtools_hdfe_types' `:set type'
        }
    }

    local kvars:    list sizeof __gtools_hdfe_vars
    local ktargets: list sizeof __gtools_hdfe_targets
    local ktype:    list sizeof __gtools_hdfe_types

    local kbad = 0
    local kbad = `kbad' | (`kvars' != `ktargets')
    local kbad = `kbad' | (`kvars' != `ktype')

    if ( `kbad' ) {
        disp as err "gstats_hdfe: parsing error (inconsistent number of inputs)"
        exit 198
    }

    local __gtools_hdfe_uniq: list uniq __gtools_hdfe_vars
    if ( `:list sizeof __gtools_hdfe_uniq' != `kvars' ) {
        disp as err "gstats_hdfe: Repeat sources not allowed"
        exit 198
    }

    * ---------------------------------------------------------------------
    * Recast or drop
    * ---------------------------------------------------------------------

    local krecast = 0
    local recast_sources
    local recast_targets

    local __gtools_hdfe_i = 0
    local __gtools_hdfe_dropvars

    forvalues k = 1 / `ktargets' {
        local typek:   word `k' of `__gtools_hdfe_types'
        local targetk: word `k' of `__gtools_hdfe_targets'
        local sourcek: word `k' of `__gtools_hdfe_vars'

        cap confirm new variable `targetk'
        if ( _rc ) {
            if !inlist("`:type `targetk''", "float", "double") {
                cap confirm new variable __gtools_hdfe`__gtools_hdfe_i'
                while ( _rc ) {
                    local ++__gtools_hdfe_i
                    cap confirm new variable __gtools_hdfe`__gtools_hdfe_i'
                }
                rename `targetk' __gtools_hdfe`__gtools_hdfe_i'
                local __gtools_hdfe_dropvars `__gtools_hdfe_dropvars' __gtools_hdfe`__gtools_hdfe_i'

                if ( "`targetk'" == "`sourcek'" ) {
                    local recast_sources `recast_sources' __gtools_hdfe`__gtools_hdfe_i'
                    local recast_targets `recast_targets' `targetk'
                    local ++krecast
                }
            }
        }
    }

    * ---------------------------------------------------------------------
    * Add target variables
    * ---------------------------------------------------------------------

    local kadd = 0
    local __gtools_hdfe_addvars
    local __gtools_hdfe_addtypes
    forvalues k = 1 / `ktargets' {
        local target: word `k' of `__gtools_hdfe_targets'
        local type:   word `k' of `__gtools_hdfe_types'
        cap confirm new variable `target'
        if ( _rc == 0 ) {
            local ++kadd
            local __gtools_hdfe_addvars  `__gtools_hdfe_addvars'  `target'
            local __gtools_hdfe_addtypes `__gtools_hdfe_addtypes' `type'
        }
    }

    if ( `kadd' ) {
        mata: (void) st_addvar(tokens(`"`__gtools_hdfe_addtypes'"'), tokens(`"`__gtools_hdfe_addvars'"'))
    }

    if ( `krecast' ) {
        scalar __gtools_k_recast = `krecast'
        cap noi plugin call gtools_plugin `recast_targets' `recast_sources', recast
        local rc = _rc
        cap scalar drop __gtools_k_recast
        if ( `rc' ) {
            exit `rc'
        }
    }

    mata st_dropvar(tokens(`"`__gtools_hdfe_dropvars'"'))

    * ---------------------------------------------------------------------
    * Scalars and locals for C internals
    * ---------------------------------------------------------------------

    scalar __gtools_hdfe_methodname = cond(`:list sizeof absorb' > 1, "`method'", "direct")
    scalar __gtools_hdfe_method     = `method_code'
    scalar __gtools_hdfe_mataname   = `"`matasavename'"'
    scalar __gtools_hdfe_matasave   = `"`matasave'"' != ""
    scalar __gtools_hdfe_kvars      = `kvars'
    scalar __gtools_hdfe_absorb     = `:list sizeof absorb'
    scalar __gtools_hdfe_hdfetol    = `tolerance'
    scalar __gtools_hdfe_maxiter    = `maxiter'
    scalar __gtools_hdfe_traceiter  = "`traceiter'" != ""
    scalar __gtools_hdfe_standard   = "`standardize'" != ""
    scalar __gtools_gstats_code     = 4
    scalar __gtools_hdfe_iter       = cond(`:list sizeof absorb' > 1, 1, 0)
    scalar __gtools_hdfe_feval      = cond(`:list sizeof absorb' > 1, 1, 0)

    if "`absorbmissing'" != "" c_local __gtools_hdfe_markvars `__gtools_hdfe_vars'
    else c_local __gtools_hdfe_markvars `__gtools_hdfe_vars' `absorb'

    c_local varlist `__gtools_hdfe_vars' `__gtools_hdfe_targets' `absorb'

    c_local gstats_replace: copy local replace
    c_local gstats_init:    copy local init

* TODO: xx formats and labels for targets?
* forvalues k = 1 / `ktargets' {
*     mata: st_varlabel( `"`:word `k' of `__gtools_hdfe_targets''"', __gtools_hdfe_labels[`k'])
*     mata: st_varformat(`"`:word `k' of `__gtools_hdfe_targets''"', __gtools_hdfe_formats[`k'])
* }

end

capture program drop gstats_winsor
program gstats_winsor
    syntax varlist(numeric), [ ///
        Suffix(str)            ///
        Prefix(str)            ///
        GENerate(str)          ///
        Trim                   ///
        Cuts(str)              ///
        Label                  ///
        replace                ///
        noinit                 ///
    ]

    * Default is winsorize or trim 1st or 99th pctile
    local trim = ( `"`trim'"' != "" )
    if ( `"`cuts'"' == "" ) {
        local cutl = 1
        local cuth = 99
    }
    else {
        gettoken cutl cuth: cuts
        cap noi confirm number `cutl'
        if ( _rc ) {
            disp "you must pass two percentiles to option -cuts()-"
            exit _rc
        }

        cap noi confirm number `cuth'
        if ( _rc ) {
            disp "you must pass two percentiles to option -cuts()-"
            exit _rc
        }

        if ( (`cutl' < 0) | (`cutl' > 100) | (`cuth' < 0) | (`cuth' > 100) ) {
            disp as err "percentiles in -cuts()- must be between 0 and 100"
            exit 198
        }

        if ( `cutl' > `cuth' ) {
            disp as err "specify the lower cutpoint first in -cuts()-"
            exit 198
        }
    }
    local kvars: list sizeof varlist

    scalar __gtools_winsor_trim    = `trim'
    scalar __gtools_winsor_cutl    = `cutl'
    scalar __gtools_winsor_cuth    = `cuth'
    scalar __gtools_winsor_kvars   = `kvars'
    scalar __gtools_gstats_code    = 1

    * Default is to generate vars with suffix (_w or _tr)
    if ( `"`prefix'`suffix'`generate'"' == "" ) {
        local ngen = 0
        if ( `trim' ) {
            local suffix _tr
        }
        else {
            local suffix _w
        }
    }
    else local ngen = (`"`prefix'`suffix'"' != "") + (`"`generate'"' != "")

    * Can only generate variables in one way
    if ( `ngen' > 1 ) {
        disp as err "Specify only one of prefix()/suffix() or generate."
        exit 198
    }

    * Generate same targets as sources
    if ( (`"`replace'"' != "") & (`ngen' == 0) ) {
        local targetvars: copy local varlist
    }
    else {
        if ( `"`replace'"' == "" ) local noi noi
        if ( `"`prefix'`suffix'"' != "" ) {
            local genvars
            local gentypes
            local targetvars
            foreach var of varlist `varlist' {
                local targetvars `targetvars' `prefix'`var'`suffix'
                cap `noi' confirm new var `prefix'`var'`suffix'
                if ( _rc & (`"`replace'"' == "") ) {
                    exit _rc
                }
                else if ( _rc == 0 ) {
                    local genvars  `genvars' `prefix'`var'`suffix'
                    local gentypes `gentypes' `:type `var''
                }
            }
        }
        else if ( `"`generate'"' != "" ) {
            local kgen: list sizeof generate
            if ( `kgen' != `kvars' ) {
                disp as err "Specify the same number of targets as sources with -generate()-"
                exit 198
            }

            local targetvars: copy local generate
            local genvars
            local gentypes
            forvalues i = 1 / `kvars' {
                local var:  word `i' of `varlist'
                local gvar: word `i' of `generate'
                cap `noi' confirm new var `gvar'
                if ( _rc & (`"`replace'"' == "") ) {
                    exit _rc
                }
                else if ( _rc == 0 ) {
                    local genvars  `genvars'  `gvar'
                    local gentypes `gentypes' `:type `var''
                }
            }
        }
        else {
            disp as err "Invalid call in gtools/gstats/winsor"
            exit 198
        }

        mata: (void) st_addvar(tokens(`"`gentypes'"'), tokens(`"`genvars'"'))
    }

    * Add to label if applicable
    if ( substr("`cutl'", 1, 1) == "." ) local cutl 0`cutl'
    if ( substr("`cuth'", 1, 1) == "." ) local cuth 0`cuth'
    if ( "`label'" != "" ) {
        local cuth `cuth'
        local cutl `cutl'
        if ( `trim' ) {
            local glab `" - Trimmed (p`cutl', p`cuth')"'
        }
        else {
            local glab `" - Winsor (p`cutl', p`cuth')"'
        }
    }
    else local glab `""'

    * Label and copy formats
    forvalues i = 1 / `kvars' {
        local var:  word `i' of `varlist'
        local gvar: word `i' of `targetvars'
        local vlab: var label `var'
        if ( `"`vlab'"' == "" ) local vlab `var'
        label var `gvar' `"`=`"`vlab'"' + `"`glab'"''"'
        format `:format `var'' `gvar'
    }

    c_local varlist `varlist' `targetvars'
    c_local gstats_replace: copy local replace
    c_local gstats_init:    copy local init
    c_local gstats_replace_anysrc: list varlist & targetvars
end

capture program drop gstats_summarize
program gstats_summarize
    syntax [varlist], [   ///
        noDetail          ///
        Meanonly          ///
        TABstat           ///
                          ///
        SEParator(int 5)  ///
                          ///
        COLumns(str)      ///
        Format            ///
        POOLed            ///
        PRETTYstats       ///
        noPRINT           ///
        MATAsave          ///
        MATAsavename(str) ///
        save              ///
        *                 ///
    ]

    if ( `"`matasavename'"' != "" ) local matasave     matasave
    if ( `"`matasavename'"' == "" ) local matasavename GstatsOutput

    if ( `"`options'"' != "" ) {
        disp as err "Unknown options (note not all display options are not allowed):"
        disp as err "    `options'"
        exit 198
    }

    if ( `"`pooled'"' == "pooled" & (`=scalar(__gtools_weight_code)' > 0) ) {
        disp as err "Option -pooled- not allowed with weights"
        exit 198
    }

    scalar __gtools_summarize_separator = `separator'
    scalar __gtools_summarize_noprint   = (`"`print'"'    == "noprint")
    scalar __gtools_summarize_format    = (`"`format'"'   == "format")
    scalar __gtools_summarize_matasave  = (`"`matasave'"' == "matasave")

    if ( "`save'" != "" ) {
        disp as err "{bf:Warning}: Option save not implemented; try -matasave-"
    }

    * Number of stats to compute
    * --------------------------

    local kstats = 25
    if ( `"`meanonly'"' != "") {
        local kstats = 6
        local detail nodetail
    }
    else if ( `"`detail'"' == "nodetail" ) {
        local kstats = 8
    }

    * Switch to tabstat
    * -----------------

    if ( "`tabstat'" != "" ) {
        scalar __gtools_summarize_tabstat = 1
    }

    * Ignore string vars
    * ------------------

    local ignorelist
    local statlist
    foreach var of varlist `varlist' {
        cap confirm numeric variable `var'
        if ( _rc ) {
            local ignorelist `ignorelist' `var'
        }
        else {
            local statlist `statlist' `var'
        }
    }

    if ( `:list sizeof statlist' == 0 ) {
        disp as err "No numeric variables; nothing to do."
        exit 18201
    }

    if ( `:list sizeof ignorelist' > 0 ) {
        disp "Ignoring non-numeric variables:"
        foreach var of varlist `ignorelist' {
            disp _skip(4) `"`var'"'
        }
    }

    * Stats to compute
    * ----------------

    c_local GstatsMataSave: copy local matasavename
    c_local varlist: copy local statlist

    scalar __gtools_gstats_code = 2
    scalar __gtools_summarize_pretty = (`"`prettystats'"' == "prettystats")
    scalar __gtools_summarize_pooled = (`"`pooled'"' == "pooled")
    scalar __gtools_summarize_normal = (`"`meanonly'"' == "")
    scalar __gtools_summarize_detail = (`"`detail'"' != "nodetail")
    scalar __gtools_summarize_kvars  = `:list sizeof statlist'
    scalar __gtools_summarize_kstats = `kstats'

    * -1          // sum
    * -2          // mean
    * -3          // sd
    * -4          // max
    * -5          // min
    * -6          // count, n
    * -7          // percent
    * 50          // median
    * -9          // iqr
    * -10         // first
    * -11         // firstnm
    * -12         // last
    * -13         // lastnm
    * -14         // freq
    * -15         // semean
    * -16         // sebinomial
    * -17         // sepoisson
    * -18         // nunique
    * -19         // skewness
    * -20         // kurtosis
    * -21         // rawsum
    * -22         // nmissing
    * -23         // variance
    * -24         // cv
    * -25         // range
    * -26         // geomean
    * -27         // gini
    * -27.1       // gini|dropneg
    * -27.2       // gini|keepneg
    * -101        // nansum
    * -121        // rawnansum
    * -206        // sum weight
    * -203        // variance
    * 1000 + #    // #th smallest
    * -1000 - #   // #th largest
    * 1000.5 + #  // raw #th smallest
    * -1000.5 - # // raw #th largest

    * N sum sum_w mean min max,        -299
    * N sum sum_w mean min max sd var, -298
    * N sum mean min max sd,           -297 (mainly for defailt tabstat)

    mata: __gtools_summarize_codes = J(1, `kstats', .)
    // mata: __gtools_summarize_codes[1] = -299
    mata: __gtools_summarize_codes[1] = -6   // N
    mata: __gtools_summarize_codes[2] = -206 // sum_w
    mata: __gtools_summarize_codes[3] = -1   // sum
    mata: __gtools_summarize_codes[4] = -2   // mean
    mata: __gtools_summarize_codes[5] = -5   // min
    mata: __gtools_summarize_codes[6] = -4   // max

    if ( `kstats'> 6 ) {
        // mata: __gtools_summarize_codes[1] = -298
        mata: __gtools_summarize_codes[7] = -3   // sd
        mata: __gtools_summarize_codes[8] = -203 // var, copy previous entry^2
    }

    if ( `kstats' > 8 ) {
        mata: __gtools_summarize_codes[9] = 1      // 1st percentile
        mata: __gtools_summarize_codes[10] = 5     // 5th percentile
        mata: __gtools_summarize_codes[11] = 10    // 10th percentile
        mata: __gtools_summarize_codes[12] = 25    // 25th percentile
        mata: __gtools_summarize_codes[13] = 50    // 50th percentile
        mata: __gtools_summarize_codes[14] = 75    // 75th percentile
        mata: __gtools_summarize_codes[15] = 90    // 90th percentile
        mata: __gtools_summarize_codes[16] = 95    // 95th percentile
        mata: __gtools_summarize_codes[17] = 99    // 99th percentile
        mata: __gtools_summarize_codes[18] = -19   // skewness
        mata: __gtools_summarize_codes[19] = -20   // kurtosis
        mata: __gtools_summarize_codes[20] = 1002  // 2nd smallest
        mata: __gtools_summarize_codes[21] = 1003  // 3rd smallest
        mata: __gtools_summarize_codes[22] = 1004  // 4th smallest
        mata: __gtools_summarize_codes[23] = -1004 // 4th largest
        mata: __gtools_summarize_codes[24] = -1003 // 3rd largest
        mata: __gtools_summarize_codes[25] = -1002 // 2nd largest
    }

    mata: st_matrix("__gtools_summarize_codes", __gtools_summarize_codes)

    * Auto-columns for tab
    * --------------------

    if ( (`kstats' > 8) & (`"`tabstat'"' != "") ) {
        disp as txt "({bf:note}: making table with 25 statistics from {cmd:summarize, detail})"
        local coldef variables
    }
    else {
        local coldef statistics
    }

    if ( `"`columns'"' == ""     ) local columns `coldef'
    if ( `"`columns'"' == "var"  ) local columns variables
    if ( `"`columns'"' == "stat" ) local columns statistics
    if ( !inlist(`"`columns'"', "variables", "statistics") ) {
        disp as err `"columns(`columns') not allowed. Available: variables, statistics"'
        exit 198
    }
    scalar __gtools_summarize_colvar = (`"`columns'"' == "variables")
end

capture program drop gstats_tabstat
program gstats_tabstat
    syntax [varlist], [    ///
        noDetail           ///
        Meanonly           ///
        TABstat            ///
                           ///
        _sum               ///
        Statistics(str)    ///
        stats(str)         ///
        LABELWidth(int 16) ///
                           ///
        COLumns(str)       ///
        Formatvar          ///
        Format(str)        ///
        POOLed             ///
        PRETTYstats        ///
        noSEParator        ///
        noPRINT            ///
        MATAsave           ///
        MATAsavename(str)  ///
        save               ///
        *                  ///
    ]

    if ( `"`matasavename'"' != "" ) local matasave     matasave
    if ( `"`matasavename'"' == "" ) local matasavename GstatsOutput
    if ( `"`format'"'       == "" ) local format %9.0g

    scalar __gtools_summarize_tabstat   = 1
    scalar __gtools_summarize_lwidth    = `labelwidth'
    scalar __gtools_summarize_nosep     = (`"`separator'"' == "noseparator")
    scalar __gtools_summarize_noprint   = (`"`print'"'     == "noprint")
    scalar __gtools_summarize_format    = (`"`formatvar'"' == "formatvar")
    scalar __gtools_summarize_dfmt      = `"`format'"'
    scalar __gtools_summarize_matasave  = (`"`matasave'"'  == "matasave")

    if ( `"`options'"' != "" ) {
        disp as err "Unknown options (note not all display options are not allowed):"
        disp as err "    `options'"
        exit 198
    }

    if ( `"`pooled'"' == "pooled" & (`=scalar(__gtools_weight_code)' > 0) ) {
        disp as err "Option -pooled- not allowed with weights"
        exit 198
    }

    if ( "`save'" != "" ) {
        disp as err "{bf:Warning}: Option save not implemented; try -matasave-"
    }

    * Ignore string vars
    * ------------------

    if ( `"`_sum'"' == "" ) {
        confirm numeric var `varlist'
        local statlist: copy local varlist
    }
    else {
        local ignorelist
        local statlist
        foreach var of varlist `varlist' {
            cap confirm numeric variable `var'
            if ( _rc ) {
                local ignorelist `ignorelist' `var'
            }
            else {
                local statlist `statlist' `var'
            }
        }

        if ( `:list sizeof statlist' == 0 ) {
            disp as err "No numeric variables; nothing to do."
            exit 18201
        }

        if ( `:list sizeof ignorelist' > 0 ) {
            disp "Ignoring non-numeric variables:"
            foreach var of varlist `ignorelist' {
                disp _skip(4) `"`var'"'
            }
        }
    }

    * Stats to compute
    * ----------------

    if ( (`"`_sum'"' == "") & (`"`detail'`meanonly'"' != "") ) {
        disp as err "Options -nodetail- and -meanonly- only allowed with {cmd:gstats_summarize}"
        exit 198
    }

    scalar __gtools_gstats_code = 2
    scalar __gtools_summarize_pretty = (`"`prettystats'"' == "prettystats")
    scalar __gtools_summarize_pooled = (`"`pooled'"' == "pooled")
    scalar __gtools_summarize_normal = (`"`meanonly'"' == "")
    scalar __gtools_summarize_detail = (`"`detail'"' != "nodetail")
    scalar __gtools_summarize_kvars  = `:list sizeof statlist'

    if ( `"`statistics'`stats'"' == "" ) {
        if ( `"`_sum'"' == "" ) {
            if ( `"`detail'"' == "nodetail" ) {
                disp as txt "({bf:warning}:option -nodetail- ignored)"
            }
            if ( `"`meanonly'"' != "" ) {
                disp as txt "({bf:warning}:option -meanonly- ignored)"
            }
            // local scode -297
            local scode -6 -1 -2 -5 -4 -3
            local kstats = 6
        }
        else if ( `"`meanonly'"' != "" ) {
            // local scode -299
            local scode -6 -206 -1 -2 -5 -4
            local kstats = 6
        }
        else if ( `"`detail'"' == "nodetail" ) {
            // local scode -298
            local scode -6 -206 -1 -2 -5 -4 -3 -203
            local kstats = 8
        }
        else {
            disp as err "parsing error: _gtools_internal failed to parse input"
            exit 198
        }
    }
    else {
        if ( `"`detail'"' == "nodetail" ) {
            disp as txt "({bf:warning}:option -nodetail- ignored)"
        }
        if ( `"`meanonly'"' != "" ) {
            disp as txt "({bf:warning}:option -meanonly- ignored)"
        }
        if ( (`"`statistics'"' != "") & (`"`stats'"' != "") ) {
            disp as err "statistics() and stats() are aliases; use only one"
            exit 198
        }
        else if ( `"`stats'"' != "" ) {
            local statistics: copy local stats
        }
        local scode
        local kstats = `:list sizeof statistics'
        foreach st of local statistics {
            if ( "`st'" == "n" ) {
                local scode `scode' -6
            }
            else if ( "`st'" == "q" ) {
                local kstats = `kstats' + 2
                local scode `scode' 25 50 75
            }
            else {
                encode_aliases `st'
                local st `r(stat)'
                encode_stat `st' 0
                if ( `r(statcode)' == 0 ) {
                    cap noi encode_regex `st'
                    if ( `r(statcode)' == 0 ) {
                        error 110
                    }
                    else {
                        local scode `scode' `r(statcode)'
                        if ( `r(statcode)' == -18 ) scalar __gtools_nunique = 1
                    }
                }
                else {
                    local scode `scode' `r(statcode)'
                    if ( `r(statcode)' == -18 ) scalar __gtools_nunique = 1
                }
            }
        }
    }

    mata: __gtools_summarize_codes = strtoreal(tokens(st_local("scode")))
    mata: st_matrix("__gtools_summarize_codes", __gtools_summarize_codes)
    scalar __gtools_summarize_kstats = `kstats'

    c_local GstatsMataSave: copy local matasavename
    c_local varlist: copy local statlist

    * Auto-columns for _sum
    * ---------------------

    if ( (`kstats' > 8) & (`"`_sum'"' != "") ) {
        local coldef variables
    }
    else {
        local coldef statistics
    }

    if ( `"`columns'"' == ""     ) local columns `coldef'
    if ( `"`columns'"' == "var"  ) local columns variables
    if ( `"`columns'"' == "stat" ) local columns statistics
    if ( !inlist(`"`columns'"', "variables", "statistics") ) {
        disp as err `"columns(`columns') not allowed. Available: variables, statistics"'
        exit 198
    }
    scalar __gtools_summarize_colvar = (`"`columns'"' == "variables")
end

* findfile "_gtools_internal.mata"
* include `"`r(fn)'"'

cap mata: mata drop __gstats_summarize_results()
cap mata: mata drop __gstats_summarize_sprintf()
cap mata: mata drop __gstats_summarize_prettysplit()
cap mata: mata drop __gstats_tabstat_results()

mata:
class GtoolsResults scalar function __gstats_summarize_results()
{
    class GtoolsResults GtoolsByLevels
    string scalar fname, var, varlabel, fmt, vfmt, dfmt
    string colvector varlabelsplit
    string matrix printstr, statvars
    real scalar k, l, J, tabstat, sep, usevfmt, maxl, pool, wcode
    real scalar kvars
    real scalar nrow
    real scalar ncol
    real matrix output

    GtoolsByLevels = GtoolsResults()
    GtoolsByLevels.readScalars()
    pool    = GtoolsByLevels.pool
    usevfmt = GtoolsByLevels.usevfmt
    maxl    = GtoolsByLevels.maxl
    dfmt    = GtoolsByLevels.dfmt

    wcode = (st_numscalar("__gtools_weight_code") > 0)? 2: 0
    sep   = st_numscalar("__gtools_summarize_separator")
    if ( sep <= 0 ) {
        sep = 0
    }

    tabstat = st_numscalar("__gtools_summarize_tabstat")
    if ( tabstat ) {
        return(__gstats_tabstat_results())
    }

    fname   = st_global("GTOOLS_GSTATS_FILE")
    J       = strtoreal(st_local("r_J"))
    kvars   = pool? 1: st_numscalar("__gtools_summarize_kvars");
    nrow    = kvars * J
    ncol    = st_numscalar("__gtools_summarize_kstats")
    output  = GtoolsReadMatrix(fname, nrow, ncol)

    if ( ncol >= 6 ) {
        st_numscalar("__gtools_summarize_N",     output[nrow, 1])
        st_numscalar("__gtools_summarize_sum_w", output[nrow, 2])
        st_numscalar("__gtools_summarize_sum",   output[nrow, 3])
        st_numscalar("__gtools_summarize_mean",  output[nrow, 4])
        st_numscalar("__gtools_summarize_min",   output[nrow, 5])
        st_numscalar("__gtools_summarize_max",   output[nrow, 6])
    }

    if ( ncol >= 8 ) {
        st_numscalar("__gtools_summarize_sd",  output[nrow, 7])
        st_numscalar("__gtools_summarize_Var", output[nrow, 8])
    }

    if ( ncol >= 25 ) {
        st_numscalar("__gtools_summarize_p1",        output[nrow, 9])
        st_numscalar("__gtools_summarize_p5",        output[nrow, 10])
        st_numscalar("__gtools_summarize_p10",       output[nrow, 11])
        st_numscalar("__gtools_summarize_p25",       output[nrow, 12])
        st_numscalar("__gtools_summarize_p50",       output[nrow, 13])
        st_numscalar("__gtools_summarize_p75",       output[nrow, 14])
        st_numscalar("__gtools_summarize_p90",       output[nrow, 15])
        st_numscalar("__gtools_summarize_p95",       output[nrow, 16])
        st_numscalar("__gtools_summarize_p99",       output[nrow, 17])
        st_numscalar("__gtools_summarize_skewness",  output[nrow, 18])
        st_numscalar("__gtools_summarize_kurtosis",  output[nrow, 19])
        st_numscalar("__gtools_summarize_smallest1", output[nrow, 5])
        st_numscalar("__gtools_summarize_smallest2", output[nrow, 20])
        st_numscalar("__gtools_summarize_smallest3", output[nrow, 21])
        st_numscalar("__gtools_summarize_smallest4", output[nrow, 22])
        st_numscalar("__gtools_summarize_largest4",  output[nrow, 23])
        st_numscalar("__gtools_summarize_largest3",  output[nrow, 24])
        st_numscalar("__gtools_summarize_largest2",  output[nrow, 25])
        st_numscalar("__gtools_summarize_largest1",  output[nrow, 6])
    }

    // do sum non-detail style summaries
    statvars = tokens(st_local("statvars"))
    if ( J == 1 & st_numscalar("__gtools_summarize_detail") ) {
        if ( st_numscalar("__gtools_summarize_noprint") == 0 ) {
            for (k = 1; k <= kvars; k++) {
                var = pool? "[Pooled Variables]": statvars[k]
                vfmt = pool? dfmt: (usevfmt? st_varformat(var): dfmt)

                printstr = J(wcode? 14: 12, 5, " ")

                printstr[1                , 2] = "Percentiles"
                printstr[1                , 3] = "Smallest"
                printstr[8  + (wcode > 0) , 3] = "Largest"
                printstr[4  + (wcode > 0) , 4] = "Obs"
                printstr[5  + (wcode > 0) , 4] = "Sum of Wgt."
                printstr[7  + (wcode > 0) , 4] = "Mean"
                printstr[8  + (wcode > 0) , 4] = "Std. Dev."
                printstr[10 + wcode       , 4] = "Variance"
                printstr[11 + wcode       , 4] = "Skewness"
                printstr[12 + wcode       , 4] = "Kurtosis"
                printstr[2  + (wcode > 0) , 1] = "1%"
                printstr[3  + (wcode > 0) , 1] = "5%"
                printstr[4  + (wcode > 0) , 1] = "10%"
                printstr[5  + (wcode > 0) , 1] = "25%"
                printstr[7  + (wcode > 0) , 1] = "50%"
                printstr[9  + wcode       , 1] = "75%"
                printstr[10 + wcode       , 1] = "90%"
                printstr[11 + wcode       , 1] = "95%"
                printstr[12 + wcode       , 1] = "99%"
                if ( wcode ) {
                    printstr[2,  3] = "(weighted)"
                    printstr[10, 3] = "(weighted)"
                }

                for(l = 1; l <= 4; l++) {
                    printstr[1 + l + (wcode > 0), 2] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 8 + l])
                }
                    printstr[7 + (wcode > 0), 2] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 13])
                for(l = 1; l <= 4; l++) {
                    printstr[8 + l + wcode, 2] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 13 + l])
                }
                    printstr[2 + (wcode > 0), 3] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 5])
                    printstr[12 + wcode,      3] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 6])
                for(l = 1; l <= 3; l++) {
                    printstr[2 + l + (wcode > 0), 3] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 19 + l])
                }
                for(l = 1; l <= 3; l++) {
                    printstr[8 + l + wcode, 3] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 22 + l])
                }
                    printstr[4 + (wcode > 0),  5] = strtrim((output[k, 1] == round(output[k, 1]))? /*
                        */ sprintf("%15.0gc", output[k, 1]): /*
                        */ sprintf("      " + dfmt, output[k, 1]))
                    printstr[5 + (wcode > 0),  5] = strtrim((output[k, 2] == round(output[k, 2]))? /*
                        */ sprintf("%15.0gc", output[k, 2]): /*
                        */ sprintf("      " + dfmt, output[k, 2]))
                    printstr[7 + (wcode > 0),  5] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 4])
                    printstr[8 + (wcode > 0),  5] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 7])
                    printstr[10 + wcode, 5] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 8])
                    printstr[11 + wcode, 5] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 18])
                    printstr[12 + wcode, 5] = __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 19])

                varlabel = pool? "": st_varlabel(var)
                printf("\n");
                if ( varlabel == "" ) {
                    printf("%~61s\n", var);
                }
                else {
                    varlabelsplit = __gstats_summarize_prettysplit(varlabel, 50)
                    for(l = 1; l <= rows(varlabelsplit); l++) {
                        printf("%~61s\n", varlabelsplit[l]);
                    }
                }
                printf( "{hline %g}\n", 61);
                for(l = 1; l <= (12 + wcode); l++) {
                    printf("%4s",   printstr[l, 1]);
                    printf(" ");
                    printf("%12s",  printstr[l, 2]);
                    printf("  ");
                    printf("%12s",  printstr[l, 3]);
                    printf("      ");
                    printf("%-12s", printstr[l, 4]);
                    printf("%12s",  printstr[l, 5]);
                    printf("\n");
                }
            }
        }
        GtoolsByLevels.read()
    }
    else if ( J == 1 & (st_numscalar("__gtools_summarize_normal") == 1) ) {
        l = max((strlen(statvars), 12))
        fmt = sprintf("%%%gs", l)

        if ( st_numscalar("__gtools_summarize_noprint") == 0 ) {
            printf("\n")
            printf(fmt, "Variable")
            printf(" | ")
            printf("%12s", "Obs")
            printf(" ")
            printf("%11s", "Mean")
            printf("%11s", " Std. Dev.")
            printf("%11s", "Min")
            printf("%11s", "Max")
            printf("\n")

            printf(sprintf("{hline %g}", l + 1))
            printf("+")
            printf("{hline 58}")
            printf("\n")

            for (k = 1; k <= kvars; k++) {
                var = pool? "[Pooled Var]": statvars[k]
                vfmt = pool? dfmt: (usevfmt? st_varformat(var): dfmt)
                printf(fmt, var)
                printf(" | ")
                printf((output[k, 1] == round(output[k, 1]))? "%12.0gc": "   " + dfmt, output[k, 1])
                printf(" ")
                printf("%11s", __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 4]))
                printf("%11s", __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 7]))
                printf("%11s", __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 5]))
                printf("%11s", __gstats_summarize_sprintf(vfmt, dfmt, maxl, output[k, 6]))
                printf("\n")
                if ( mod(k, sep) == 0 ) {
                    printf(sprintf("{hline %g}\n", 58 + 1 + l + 1))
                }
            }
        }
        GtoolsByLevels.read()
    }
    else if ( J > 1 ) {
        return(__gstats_tabstat_results())
    }

    GtoolsByLevels.tabstat  = 0
    GtoolsByLevels.output   = output
    GtoolsByLevels.colvar   = st_numscalar("__gtools_summarize_colvar")
    GtoolsByLevels.ksources = kvars
    GtoolsByLevels.kstats   = ncol
    GtoolsByLevels.statvars = statvars
    GtoolsByLevels.scodes   = st_matrix("__gtools_summarize_codes")
    GtoolsByLevels.whoami   = st_local("GstatsMataSave")
    GtoolsByLevels.readStatnames()

    return (GtoolsByLevels)
}

string scalar function __gstats_summarize_sprintf(
    string scalar vfmt,
    string scalar dfmt,
    real scalar maxl,
    real scalar x)
{
    string scalar s
    s = sprintf(vfmt, x)
    if ( strlen(s) > maxl ) {
        s = sprintf(dfmt, x)
    }
    return(s)
}

string colvector function __gstats_summarize_prettysplit(
    string scalar txt,
    real scalar maxl)
{
    real scalar len, lenmax, lenbuf, badsplit
    string colvector splitxt
    string scalar bufleft, bufright

    if ( maxl < 1 ) {
        return(txt)
    }

    lenmax = floor(maxl)
    len    = strlen(txt)
    if ( len <= maxl ) {
        return(txt)
    }

    splitxt  = J(0, 1, "")
    bufright = txt
    while ( bufright != "" ) {
        if ( strlen(bufright) > lenmax ) {
            lenbuf = lenmax + 1
            do {
                badsplit = substr(bufright, lenbuf--, 1) != " "
            } while ( badsplit & lenbuf > 0 )
        }
        else {
            lenbuf = 0
        }
        if ( lenbuf > 0 ) {
            bufleft  = substr(bufright, 1, lenbuf)
            bufright = substr(bufright, lenbuf + 2, .)
        }
        else {
            bufleft  = substr(bufright, 1, lenmax)
            bufright = substr(bufright, lenmax + 1, .)
        }
        splitxt = splitxt \ bufleft
    }

    return(splitxt)
}

class GtoolsResults scalar function __gstats_tabstat_results()
{
    class GtoolsResults scalar GtoolsByLevels

    GtoolsByLevels = GtoolsResults()
    GtoolsByLevels.readScalars()
    GtoolsByLevels.read()

    GtoolsByLevels.tabstat  = 1
    GtoolsByLevels.colvar   = st_numscalar("__gtools_summarize_colvar")
    GtoolsByLevels.ksources = GtoolsByLevels.pool? 1: st_numscalar("__gtools_summarize_kvars")
    GtoolsByLevels.kstats   = st_numscalar("__gtools_summarize_kstats")
    GtoolsByLevels.statvars = tokens(st_local("statvars"))
    GtoolsByLevels.scodes   = st_matrix("__gtools_summarize_codes")
    GtoolsByLevels.whoami   = st_local("GstatsMataSave")

    GtoolsByLevels.readStatnames()
    GtoolsByLevels.readOutput(st_global("GTOOLS_GSTATS_FILE"))
    if ( st_numscalar("__gtools_summarize_noprint") == 0 ) {
        GtoolsByLevels.printOutput()
    }

    return (GtoolsByLevels)
}
end

capture program drop GtoolsTempFile
program GtoolsTempFile
    if ( `"${GTOOLS_TEMPFILES_INTERNAL_I}"' == "" ) {
        local  GTOOLS_TEMPFILES_INTERNAL_I = 1
        global GTOOLS_TEMPFILES_INTERNAL_I = 1
    }
    else {
        local  GTOOLS_TEMPFILES_INTERNAL_I = ${GTOOLS_TEMPFILES_INTERNAL_I} + 1
        global GTOOLS_TEMPFILES_INTERNAL_I = ${GTOOLS_TEMPFILES_INTERNAL_I} + 1
    }
    local f ${GTOOLS_TEMPDIR}/__gtools_tmpfile_internal_`GTOOLS_TEMPFILES_INTERNAL_I'
    global GTOOLS_TEMPFILES_INTERNAL ${GTOOLS_TEMPFILES_INTERNAL} __gtools_tmpfile_internal_`GTOOLS_TEMPFILES_INTERNAL_I'
    c_local `0': copy local f
end

***********************************************************************
*            Input parsing (copy/paste from gcollapse.ado             *
***********************************************************************

capture program drop GtoolsPrettyStat
program GtoolsPrettyStat, rclass

    * Group stats
    * -----------

    if ( `"`0'"' == "sum"          ) local prettystat "Sum"
    if ( `"`0'"' == "nansum"       ) local prettystat "Sum"
    if ( `"`0'"' == "mean"         ) local prettystat "Mean"
    if ( `"`0'"' == "geomean"      ) local prettystat "Geometric mean"
    if ( `"`0'"' == "sd"           ) local prettystat "St Dev."
    if ( `"`0'"' == "variance"     ) local prettystat "Variance"
    if ( `"`0'"' == "cv"           ) local prettystat "Coef. of variation"
    if ( `"`0'"' == "max"          ) local prettystat "Max"
    if ( `"`0'"' == "min"          ) local prettystat "Min"
    if ( `"`0'"' == "range"        ) local prettystat "Range"
    if ( `"`0'"' == "count"        ) local prettystat "Count"
    if ( `"`0'"' == "freq"         ) local prettystat "Group size"
    if ( `"`0'"' == "percent"      ) local prettystat "Percent"
    if ( `"`0'"' == "median"       ) local prettystat "Median"
    if ( `"`0'"' == "iqr"          ) local prettystat "IQR"
    if ( `"`0'"' == "first"        ) local prettystat "First"
    if ( `"`0'"' == "firstnm"      ) local prettystat "First Non-Miss."
    if ( `"`0'"' == "last"         ) local prettystat "Last"
    if ( `"`0'"' == "lastnm"       ) local prettystat "Last Non-Miss."
    if ( `"`0'"' == "semean"       ) local prettystat "SE Mean"
    if ( `"`0'"' == "sebinomial"   ) local prettystat "SE Mean (Binom)"
    if ( `"`0'"' == "sepoisson"    ) local prettystat "SE Mean (Pois)"
    if ( `"`0'"' == "nunique"      ) local prettystat "N Unique"
    if ( `"`0'"' == "nmissing"     ) local prettystat "N Missing"
    if ( `"`0'"' == "skewness"     ) local prettystat "Skewness"
    if ( `"`0'"' == "kurtosis"     ) local prettystat "Kurtosis"
    if ( `"`0'"' == "rawsum"       ) local prettystat "Unweighted sum"
    if ( `"`0'"' == "rawnansum"    ) local prettystat "Unweighted sum"
    if ( `"`0'"' == "gini"         ) local prettystat "Gini Coefficient"
    if ( `"`0'"' == "gini|dropneg" ) local prettystat "Gini Coefficient (drop neg)"
    if ( `"`0'"' == "gini|keepneg" ) local prettystat "Gini Coefficient (keep neg)"

    local match = 0
    if regexm(`"`0'"', "^rawselect(-|)([0-9]+)$") {
        if ( `"`:di regexs(1)'"' == "-" ) {
            local Pretty Largest (Unweighted)
        }
        else {
            local Pretty Smallest (Unweighted)
        }
        local p = `=regexs(2)'
        local match = 1
    }
    else if regexm(`"`0'"', "^select(-|)([0-9]+)$") {
        if ( `"`:di regexs(1)'"' == "-" ) {
            local Pretty Largest
        }
        else {
            local Pretty Smallest
        }
        local p = `=regexs(2)'
        local match = 1
    }
    else if regexm(`"`0'"', "^p([0-9][0-9]?(\.[0-9]+)?)$") {
        local p = `:di regexs(1)'
        local Pretty Pctile
        local match = 1
    }

    if ( `match' ) {
        if ( inlist(substr(`"`p'"', -2, 2), "11", "12", "13") ) {
            local prettystat "`s'th `Pretty'"
        }
        else {
                 if ( mod(`p', 10) == 1 ) local prettystat "`p'st `Pretty'"
            else if ( mod(`p', 10) == 2 ) local prettystat "`p'nd `Pretty'"
            else if ( mod(`p', 10) == 3 ) local prettystat "`p'rd `Pretty'"
            else                          local prettystat "`p'th `Pretty'"
        }
    }

    * Transforms
    * ----------

    if ( `"`0'"' == "standardize" ) local prettystat "Standardized"
    if ( `"`0'"' == "normalize"   ) local prettystat "Normalized"
    if ( `"`0'"' == "demean"      ) local prettystat "De-meaned"
    if ( `"`0'"' == "demedian"    ) local prettystat "De-medianed"

    encode_moving `0'
    if ( `r(match)' ) {
        local range `r(lower)' to `r(upper)'
        GtoolsPrettyStat `r(stat)'
        local prettystat "Moving `r(prettystat)' (`range')"
    }

    encode_range `0'
    if ( `r(match)' ) {
        local rangestr `r(rangestr)'
        GtoolsPrettyStat `r(stat)'
        local prettystat "`r(prettystat)' for `rangestr'"
    }

    encode_cumsum `0'
    if ( `r(match)' ) {
        if ( `r(cumsign)' == 0 ) {
            local prettystat "Cummulative sum"
        }
        else if ( `r(cumsign)' == 1 ) {
            if ( `r(cumother)' ) {
                local prettystat "Cummulative sum (ascending by `r(cumvars)')"
            }
            else {
                local prettystat "Cummulative sum (ascending)"
            }
        }
        else if ( `r(cumsign)' == 2 ) {
            if ( `r(cumother)' ) {
                local prettystat "Cummulative sum (descending by `r(cumvars)')"
            }
            else {
                local prettystat "Cummulative sum (descending)"
            }
        }
    }

    encode_shift `0'
    if ( `r(match)' ) {
        if ( `r(shift)' == 0 ) {
            local prettystat ""
        }
        else if ( `r(shift)' > 0 ) {
            local prettystat "Lead (`r(shift)')"
        }
        else if ( `r(shift)' < 0 ) {
            local prettystat "Lag (`=abs(`r(shift)')')"
        }
    }

    return local prettystat = `"`prettystat'"'
end

capture program drop ParseListWild
program ParseListWild
    local opts window(passthru) interval(passthru) cumby(passthru) shiftby(passthru) statprefix(str)
    syntax anything(equalok), LOCal(str) PREfix(str) default(str) [`opts']
    local stat `default'

    * Trim spaces
    local 0: copy local anything
    while strpos("`0'", "  ") {
        local 0: subinstr local 0 "  " " ", all
    }
    local 0 `0'

    * Parse each portion of the collapse call
    while (trim("`0'") != "") {
        GetStat   stat   0 : `0'
        GetTarget target 0 : `0'
        gettoken  vars   0 : 0

        * Must specify stat (if blank, we do the mean)
        if ( "`stat'" == "" ) {
            disp as err "option stat() requried"
            exit 198
        }

        if ( `"`stat'"' == "var"  ) local stat variance
        if ( `"`stat'"' == "sem"  ) local stat semean
        if ( `"`stat'"' == "seb"  ) local stat sebinomial
        if ( `"`stat'"' == "sep"  ) local stat sepoisson
        if ( `"`stat'"' == "skew" ) local stat skewness
        if ( `"`stat'"' == "kurt" ) local stat kurtosis
        if ( regexm(`"`stat'"', " ") ) local stat: subinstr local stat " " "|", all

        if ( substr(`"`stat'"', 1, length(`"`statprefix'"')) != `"`statprefix'"' ) {
            local stat `statprefix'`stat'
        }
        encode_moving `stat', `window'

        * Parse bulk rename if applicable
        unab usources : `vars'
        if ( "`eqsign'" == "=" ) {
            cap noi rename `vars' `target'
            if ( _rc ) {
                disp as err "Targets cannot exist with option {opt wildparse}."
                exit `=_rc'
            }
            unab utargets : `target'
            rename (`utargets') (`usources')

            local full_vars    `full_vars'    `usources'
            local full_targets `full_targets' `utargets'

            foreach svar of varlist `usources' {
                gettoken tvar utargets: utargets

                * Parsed here because each interval call can specify a
                * different reference variable. If no reference variable
                * is specified then it is assumed to be the source.

                encode_range  `stat', `interval' var(`svar')
                encode_cumsum `stat', `cumby'    var(`svar')
                encode_shift  `stat', `shiftby'

                local call `call' (`stat') `tvar' = `svar'
                local full_stats  `full_stats' `stat'
            }
        }
        else {
            local full_vars    `full_vars'    `usources'
            local full_targets `full_targets' `usources'

            foreach svar of varlist `usources' {
                encode_range  `stat', `interval' var(`svar')
                encode_cumsum `stat', `cumby'    var(`svar')
                encode_shift  `stat', `shiftby'

                local call `call' (`stat') `svar'
                local full_stats `full_stats' `stat'
            }
        }

        local target
    }

    * Check that targets don't repeat
    local dups : list dups targets
    if ("`dups'" != "") {
        di as error "repeated targets in collapse: `dups'"
        error 110
    }

    c_local `local'             : copy local call
    c_local `prefix'_targets    `full_targets'
    c_local `prefix'_stats      `full_stats'
    c_local `prefix'_vars       `full_vars'
    c_local `prefix'_uniq_stats : list uniq full_stats
    c_local `prefix'_uniq_vars  : list uniq full_vars
end

* NOTE: Regular parsing is adapted from Sergio Correia's fcollapse.ado

capture program drop ParseList
program define ParseList
    local opts window(passthru) interval(passthru) cumby(passthru) shiftby(passthru) statprefix(str)
    syntax anything(equalok), PREfix(str) default(str) [`opts']
    local stat `default'

    * Trim spaces
    local 0: copy local anything
    while strpos("`0'", "  ") {
        local 0: subinstr local 0 "  " " "
    }
    local 0 `0'

    while (trim("`0'") != "") {
        GetStat stat 0 : `0'
        GetTarget target 0 : `0'
        gettoken vars 0 : 0
        unab vars : `vars'

        * Must specify stat (if blank, we do the mean)
        if ( "`stat'" == "" ) {
            disp as err "option stat() requried"
            exit 198
        }

        if ( `"`stat'"' == "var"  ) local stat variance
        if ( `"`stat'"' == "sem"  ) local stat semean
        if ( `"`stat'"' == "seb"  ) local stat sebinomial
        if ( `"`stat'"' == "sep"  ) local stat sepoisson
        if ( `"`stat'"' == "skew" ) local stat skewness
        if ( `"`stat'"' == "kurt" ) local stat kurtosis
        if ( regexm(`"`stat'"', " ") ) local stat: subinstr local stat " " "|", all

        if ( substr(`"`stat'"', 1, length(`"`statprefix'"')) != `"`statprefix'"' ) {
            local stat `statprefix'`stat'
        }
        encode_moving `stat', `window'

        foreach var of local vars {
            if ("`target'" == "") local target `var'

            encode_range  `stat', `interval' var(`var')
            encode_cumsum `stat', `cumby'    var(`var')
            encode_shift  `stat', `shiftby'

            local full_vars    `full_vars'    `var'
            local full_targets `full_targets' `target'
            local full_stats   `full_stats'   `stat'

            local target
        }
    }

    * Check that targets don't repeat
    local dups : list dups targets
    if ("`dups'" != "") {
        di as error "repeated targets in collapse: `dups'"
        error 110
    }

    c_local `prefix'_targets    `full_targets'
    c_local `prefix'_stats      `full_stats'
    c_local `prefix'_vars       `full_vars'
    c_local `prefix'_uniq_stats : list uniq full_stats
    c_local `prefix'_uniq_vars  : list uniq full_vars
end

capture program drop GetStat
program define GetStat
    _on_colon_parse `0'
    local before `s(before)'
    gettoken lhs rhs : before
    local rest `s(after)'

    gettoken stat rest : rest , match(parens)
    if ("`parens'" != "") {
        c_local `lhs' `stat'
        c_local `rhs' `rest'
    }
end

capture program drop GetTarget
program define GetTarget
    _on_colon_parse `0'
    local before `s(before)'
    gettoken lhs rhs : before
    local rest `s(after)'

    local rest : subinstr local rest "=" "= ", all
    gettoken target rest : rest, parse("= ")
    gettoken eqsign rest : rest
    if ("`eqsign'" == "=") {
        c_local `lhs': copy local target
        c_local `rhs': copy local rest
        c_local eqsign "="
    }
    else {
        c_local eqsign
    }
end

capture program drop NoInitWarning
program NoInitWarning
    if !inlist(`"${GTOOLS_NOINIT_WARNING}"', "0") {
        disp as txt "WARNING: You have chosen to use the undocumented option -noinit-"
        disp as txt "with -replace- and if/in. Variables that exist and will be replaced"
        disp as txt "WITHOUT modifying any observations not tagged by if/in. Please make"
        disp as txt "sure you understand the implications of doing this. To supress this"
        disp as txt "warning, set"
        disp as txt ""
        disp as txt "    global GTOOLS_NOINIT_WARNING = 0"
        disp as txt ""
    }
end

***********************************************************************
*                             Load plugin                             *
***********************************************************************

if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) local c_os_ macosx
else local c_os_: di lower("`c(os)'")

if ( `c(stata_version)' < 14.1 ) local spiver v2
else local spiver v3

cap program drop gtools_plugin
if ( inlist("${GTOOLS_FORCE_PARALLEL}", "1") ) {
    cap program gtools_plugin, plugin using("gtools_`c_os_'_multi_`spiver'.plugin")
    if ( _rc ) {
        global GTOOLS_FORCE_PARALLEL 17900
        program gtools_plugin, plugin using("gtools_`c_os_'_`spiver'.plugin")
    }
}
else program gtools_plugin, plugin using("gtools_`c_os_'_`spiver'.plugin")
