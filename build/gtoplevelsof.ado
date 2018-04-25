*! version 0.5.8 23Apr2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Calculate the top groups by count of a varlist (jointly).

* TODO: do not replace value if it does not have a label // 2017-11-09 21:43 EST

cap program drop gtoplevelsof
program gtoplevelsof, rclass
    global GTOP_RC 0
    version 13

    if ( `=_N < 1' ) {
        di as txt "no observations"
        exit 0
    }

    global GTOOLS_CALLER gtoplevelsof
    syntax anything [if] [in],   ///
    [                            ///
        ntop(int 10)             /// Number of levels to display
        freqabove(real 0)        /// Only include above this count
        pctabove(real 0)         /// Only include above this pct
                                 ///
        noOTHer                  /// Do not add summary row with "other" group to table
        missrow                  /// Incldue missings as a sepparate row
        GROUPMISSing             /// Count as missing if any variable is missing
        noMISSing                /// Exclude missing values
                                 ///
        OTHerlabel(str)          /// Label for "other" row
        MISSROWlabel(str)        /// Count as missing if any variable is missing
        pctfmt(str)              /// How to format percentages
                                 ///
        noVALUELABels            /// Do (not) map value labels
        HIDECONTlevels           /// Hide level name previous level is the same
        VARABBrev(int -1)        /// Abbrev print of var names
        colmax(numlist)          /// Maximum number of characters to print per column
        colstrmax(numlist)       /// Maximum number of characters to print per column (strings)
        numfmt(passthru)         /// How to format numbers
                                 ///
        Separate(passthru)       /// Levels sepparator
        COLSeparate(passthru)    /// Columns sepparator (only with 2+ vars)
        LOCal(str)               /// Store variable levels in local
        MATrix(str)              /// Store result in matrix
                                 ///
        Verbose                  /// debugging
        BENCHmark                /// Benchmark function
        BENCHmarklevel(int 0)    /// Benchmark various steps of the plugin
        HASHmethod(passthru)     /// Hashing method: 0 (default), 1 (biject), 2 (spooky)
        hashlib(passthru)        /// path to hash library (Windows)
        oncollision(passthru)    /// On collision, fall back or error
                                 ///
        group(str)               ///
        tag(passthru)            ///
        counts(passthru)         ///
        replace                  ///
    ]

    if ( `benchmarklevel' > 0 ) local benchmark benchmark
    local benchmarklevel benchmarklevel(`benchmarklevel')

    if ( `"`colseparate'"' == "" ) local colseparate colseparate(`"  "')
    if ( `"`numfmt'"'      == "" ) local numfmt      numfmt(`"%.8g"')
    if ( `"`pctfmt'"'      == "" ) local pctfmt      `"%5.1f"'

    if !regexm(`"`pctfmt'"', "%[0-9]+\.[0-9]+(gc?|fc?|e)") {
        di as err "Percent format must be %(width).(digits)(f|g); e.g. %.16g (default), %20.5f"
        exit 198
    }

    * Get varlist
    * -----------

    if ( "`anything'" != "" ) {
        local varlist `anything'
        local varlist: subinstr local varlist "+" "", all
        local varlist: subinstr local varlist "-" "", all
        cap ds `varlist'
        if ( _rc | ("`varlist'" == "") ) {
            local rc = _rc
            di as err "Malformed call: '`anything''"
            di as err "Syntax: [+|-]varname [[+|-]varname ...]"
            exit 111
        }
        local varlist `r(varlist)'
    }

    * Parse options
    * -------------

    if ( "`missing'" == "nomissing" ) {
         if ( ("`missrow'" != "") | ("`groupmissing'" != "") ) {
            di as err "-nomissing- not allowed with -groupmissing- or -missrow[()]-"
            exit 198
         }
    }
    local missing  = cond("`missing'" == "", "missing",  "")

    if ( (`pctabove' < 0) | (`pctabove' > 100) ) {
        di as err "-pctabove()- must be between 0 and 100"
        exit 198
    }

    local ntop ntop(`ntop')
    local pct  pct(`pctabove')
    local freq freq(`freqabove')

    if ( ("`missrow'" != "") | ("`missrowlabel'" != "") ) {
        if ( "`groupmissing'" != "" ) {
            if ( "`missrowlabel'" != "" ) {
                local groupmiss misslab(`"`missrowlabel'"') groupmiss
            }
            else {
                local missrowlabel Missing (any)
                local groupmiss    misslab(Missing (any)) groupmiss
            }
        }
        else {
            if ( "`missrowlabel'" != "" ) {
                local groupmiss misslab(`"`missrowlabel'"')
            }
            else {
                local missrowlabel Missing
                local groupmiss    misslab(Missing)
            }
        }
    }

    if ( ("`other'" == "") | ("`otherlabel'" != "") ) {
        if ( "`otherlabel'" != "" ) {
            local otherlab otherlab(`"`otherlabel'"')
        }
        else {
            local otherlabel Other
            local otherlab   otherlab(Other)
        }
    }

    local gtop gtop(`ntop' `pct' `groupmiss' `otherlab' `freq')

    * Call the internals
    * ------------------

    local opts  `separate' `colseparate' `missing' `gtop' `numfmt'
    local sopts `verbose' `benchmark' `benchmarklevel' `hashlib' `oncollision' `hashmethod'
    local gopts gen(`group') `tag' `counts' `replace'
    cap noi _gtools_internal `anything' `if' `in', `opts' `sopts' `gopts' gfunction(top)

    local rc = _rc
    global GTOOLS_CALLER ""
    if ( `rc' == 17999 ) {
        exit 17000
    }
    else if ( `rc' == 17001 ) {
        global GTOP_RC 17001
        di as txt "(no observations)"
        exit 0
    }
    else if ( `rc' ) {
        exit `rc'
    }

    local byvars = `"`r(byvars)'"'
    local bynum  = `"`r(bynum)'"'
    local bystr  = `"`r(bystr)'"'

    tempname invertmat
    mata: `invertmat' = st_matrix("r(invert)")

    local abbrev = `varabbrev'
    if ( `abbrev' == -1 ) {
        foreach v of local varlist {
            local abbrev = max(`abbrev', length("`v'"))
        }
    }

    local k = 0
    local abbrevlist ""
    foreach v of local varlist {
        local ++k
        local abbrev = max(`abbrev', 5)
        mata: st_local("invert", strofreal(`invertmat'[`k']))
        if ( `invert' ) {
            local avar       `:di %`abbrev's abbrev("`v'", `abbrev')'
            local abbrevlist `abbrevlist' -`avar'
        }
        else {
            local abbrevlist `abbrevlist' `:di %`abbrev's abbrev("`v'", `abbrev')'
        }
    }

    tempname gmat
    mata: __gtools_parse_topmat(`:list sizeof varlist', ///
                                tokens("`abbrevlist'"), ///
                                "`gmat'",               ///
                                `"`r(levels)'"',        ///
                                `"`r(sep)'"',           ///
                                `"`r(colsep)'"')

    matrix colnames `gmat' = ID N Cum Pct PctCum
    if ( "`local'"  != "" ) c_local `local' `"`r(levels)'"'
    if ( "`matrix'" != "" ) matrix `matrix' = `gmat'

    return local levels    `"`r(levels)'"'
    return scalar N         = `r(N)'
    return scalar J         = `r(J)'
    return scalar minJ      = `r(minJ)'
    return scalar maxJ      = `r(maxJ)'
    return matrix toplevels = `gmat'
end

capture mata: mata drop __gtools_parse_topmat()
capture mata: mata drop __gtools_unquote()

mata:
// kvars      = `:list sizeof varlist'
// abbrevlist = tokens("`abbrevlist'")
// outmat     = "`gmat'"
// levels     = `"`r(levels)'"'
// sep        = `"`r(sep)'"'
// colsep     = `"`r(colsep)'"'

void function __gtools_parse_topmat(real scalar kvars,
                                   string rowvector abbrevlist,
                                   string scalar outmat,
                                   string scalar levels,
                                   string scalar sep,
                                   string scalar colsep)
{
    real scalar i, k, l, len, ntop, nrows, gallcomp, minstrlen, nmap, knum, kstr, valabbrev
    real scalar pctlen, wlen, dlen
    real matrix gmat, nmat
    real colvector si, si_miss, si_other, fmtix
    real rowvector gstrmax, gnummax, colstrmax, colnummax, colmax
    string matrix grows, gparse
    string colvector _grows, gprint, fmtbak
    string rowvector gcomp, gstrfmt, gnumfmt, byvars, bynum, bystr
    string scalar sepfmt, ghead, headfmt, mlab, olab, pctfmt, ppctfmt, cpctfmt, numvar, strvar
    transmorphic t

    pctfmt = st_local("pctfmt")
    if ( regexm(pctfmt, "%([0-9]+)\.([0-9]+)") ) {
        wlen   = strtoreal(regexs(1))
        dlen   = strtoreal(regexs(2)) + 4
        pctlen = wlen > dlen? wlen: dlen;
    }
    else {
        pctlen = 5
    }

    ppctfmt = pctlen > 8?  " %" + strofreal(pctlen) + "s ": " %8s "
    cpctfmt = pctlen > 12? " %" + strofreal(pctlen) + "s ": " %12s "

    if (    sep == "" )    sep = " "
    if ( colsep == "" ) colsep = " "

    gmat   = st_matrix("r(toplevels)")
    nmat   = st_matrix("r(numlevels)")
    nmap   = st_local("valuelabels") == ""
    byvars = tokens(st_local("byvars"))
    bynum  = tokens(st_local("bynum"))
    bystr  = tokens(st_local("bystr"))
    knum   = cols(bynum)
    kstr   = cols(bystr)
    ntop   = sum(gmat[., 1] :== 1)
    nrows  = sum(gmat[., 1] :!= 0)

    if ( nrows > 0 ) {
        gmat   = gmat[selectindex(gmat[., 1] :!= 0), .]
        grows  = J(rows(gmat), kvars, "")
        gcomp  = J(1, kvars, "")
        gparse = J(rows(gmat), 2, "")
        gprint = J(rows(gmat) + 1, 1, "")

        t = tokeninit(sep, (""), (`""""', `"`""'"'), 1)
        tokenset(t, levels)

        if ( ntop > 0 ) {
            _grows = tokengetall(t)
            for (i = 1; i <= cols(_grows); i++) {
                _grows[i] = __gtools_unquote(_grows[i]);
            }

            if ( kvars > 1 ) {
                t = tokeninit(colsep, (""), (`""""', `"`""'"'), 1)
                for (i = 1; i <= cols(_grows); i++) {
                    tokenset(t, _grows[i])
                    grows[i, .] = tokengetall(t)
                    for (k = 1; k <= kvars; k++) {
                        grows[i, k] = __gtools_unquote(grows[i, k])
                    }
                }
            }
            else {
                grows[1::cols(_grows)] = _grows'
            }

            if ( (knum > 0) & (nmap) ) {
                nmat = nmat[1::ntop, .]
                for (k = 1; k <= knum; k++) {
                    numvar = bynum[k]
                    l = selectindex(byvars :== numvar)
                    if ( st_varvaluelabel(numvar) != "" ) {
                        fmtbak = grows[1::ntop, l]
                        grows[1::ntop, l] = st_vlmap(st_varvaluelabel(numvar), nmat[., k])
                        fmtix  = selectindex(grows[1::ntop, l] :== "")
                        if ( rows(fmtix) > 0 ) {
                            grows[fmtix, l] = fmtbak[fmtix]
                        }
                    }
                }
            }
        }

        si       = gmat[., 1] :== 1
        si_miss  = gmat[., 1] :== 2
        si_other = gmat[., 1] :== 3

        if ( st_local("hidecontlevels") != "" ) {
            gallcomp = 0
            for (k = 1; k <= kvars; k++) {
                gcomp[k] = grows[1, k]
            }

            for (i = 2; i <= ntop; i++) {
                if ( grows[i, 1] == gcomp[1] ) {
                    grows[i, 1] = ""
                    gallcomp    = 1
                }
                else {
                    gcomp[1]    = grows[i, 1]
                    gallcomp    = 0
                }
                for (k = 2; k <= kvars; k++) {
                    if ( (grows[i, k] == gcomp[k]) & gallcomp ) {
                        grows[i, k] = ""
                    }
                    else {
                        gcomp[k] = grows[i, k]
                        gallcomp = 0
                    }
                }
                gcallcomp = 0
            }
        }

        valabbrev = 0
        if ( st_local("colmax") != "" ) {
            colnummax = strtoreal(tokens(st_local("colmax")))
            while ( cols(colnummax) < kvars ) {
                colnummax = colnummax, colnummax[cols(colnummax)]
            }
            colmax    = colnummax
            valabbrev = 1
        }
        else {
            colmax    = J(1, kvars, .)
            valabbrev = 0
        }

        if ( st_local("colstrmax") != "" ) {
            colstrmax = strtoreal(tokens(st_local("colstrmax")))
            while ( cols(colstrmax) < kstr ) {
                colstrmax = colstrmax, colstrmax[cols(colstrmax)]
            }
            valabbrev = 1

            for (k = 1; k <= kstr; k++) {
                strvar    = bystr[k]
                l         = selectindex(byvars :== strvar)
                colmax[l] = colstrmax[k]
            }
        }

        if ( valabbrev ) {
            for (i = 1; i <= ntop; i++) {
                for (k = 1; k <= kvars; k++) {
                    if ( strlen(grows[i, k]) > colmax[k] ) {
                        if ( colmax[k] > 0 ) {
                            grows[i, k] = substr(grows[i, k], 1, colmax[k]) + "..."
                        }
                        else {
                            grows[i, k] = ""
                        }
                    }
                }
            }
        }

        for (i = 1; i <= rows(gmat); i++) {
            gparse[i, 1] = strtrim(sprintf("%21.0gc", gmat[i, 2]))
            gparse[i, 2] = strtrim(sprintf("%21.0gc", gmat[i, 3]))
        }

        gnummax = (colmax(strlen(gparse)))
        if ( any(gnummax :< 3) ) {
            gnummax[selectindex(gnummax :< 3)] = J(1, sum(gnummax :< 3), 3)
        }

        gstrmax = (colmax(strlen(grows)))
        for (k = 1; k <= kvars; k++) {
            gstrmax[k] = max((gstrmax[k], strlen(abbrevlist[k])))
        }

        minstrlen = sum(gstrmax) + (kvars - 1) + (kvars - 1) * strlen(colsep);
        if ( minstrlen < 6 ) {
            gstrmax[1] = 6 - (sum(gstrmax) + kvars - 1) + gstrmax[1]
        }

        mlab = st_local("missrowlabel")
        olab = st_local("otherlabel")
        if ( any(si_miss) ) {
            minstrlen = sum(gstrmax) + (kvars - 1) + (kvars - 1) * strlen(colsep);
            if ( minstrlen < strlen(mlab) ) {
                gstrmax[1] = strlen(mlab) - minstrlen + gstrmax[1]
            }
        }
        if ( any(si_other) ) {
            minstrlen = sum(gstrmax) + (kvars - 1) + (kvars - 1) * strlen(colsep);
            if ( minstrlen < strlen(olab) ) {
                gstrmax[1] = strlen(olab) - minstrlen + gstrmax[1]
            }
        }

        gstrfmt = " %" :+ strofreal(gstrmax) :+ "s"
        gnumfmt = " %" :+ strofreal(gnummax) :+ "s "
        sepfmt  = "%"  + strofreal(strlen(colsep)) + "s"

        for (i = 1; i <= ntop; i++) {
            gprint[i] = sprintf(gstrfmt[1], grows[i, 1])
            for (k = 2; k <= kvars; k++) {
                if ( (grows[i, k - 1] == "") | (i > ntop) ) {
                    gprint[i] = gprint[i] + sprintf(sepfmt + gstrfmt[k], "", grows[i, k])
                }
                else {
                    gprint[i] = gprint[i] + sprintf(sepfmt + gstrfmt[k], colsep, grows[i, k])
                }
            }
            gprint[i] = gprint[i] + " | "
            gprint[i] = gprint[i] + sprintf(gnumfmt[1], gparse[i, 1])
            gprint[i] = gprint[i] + sprintf(gnumfmt[2], gparse[i, 2])
            gprint[i] = gprint[i] + sprintf(ppctfmt, sprintf(pctfmt, gmat[i, 4]))
            gprint[i] = gprint[i] + sprintf(cpctfmt, sprintf(pctfmt, gmat[i, 5]))
        }

        i = ntop + 1;
        minstrlen = sum(gstrmax) + (kvars - 1) + (kvars - 1) * strlen(colsep);
        headfmt   = " %" + strofreal(minstrlen) + "s"
        if ( any(si_miss) ) {
            gprint[i] = sprintf(headfmt, mlab)
            gprint[i] = gprint[i] + " | "
            gprint[i] = gprint[i] + sprintf(gnumfmt[1], gparse[i, 1])
            gprint[i] = gprint[i] + sprintf(gnumfmt[2], gparse[i, 2])
            gprint[i] = gprint[i] + sprintf(ppctfmt, sprintf(pctfmt, gmat[i, 4]))
            gprint[i] = gprint[i] + sprintf(cpctfmt, sprintf(pctfmt, gmat[i, 5]))
            ++i;
        }

        if ( any(si_other) ) {
            gprint[i] = sprintf(headfmt, olab)
            gprint[i] = gprint[i] + " | "
            gprint[i] = gprint[i] + sprintf(gnumfmt[1], gparse[i, 1])
            gprint[i] = gprint[i] + sprintf(gnumfmt[2], gparse[i, 2])
            gprint[i] = gprint[i] + sprintf(ppctfmt, sprintf(pctfmt, gmat[i, 4]))
            gprint[i] = gprint[i] + sprintf(cpctfmt, sprintf(pctfmt, gmat[i, 5]))
        }

        ghead = sprintf(gstrfmt[1], abbrevlist[1])
        for (k = 2; k <= kvars; k++) {
            ghead = ghead + sprintf(sepfmt + gstrfmt[k], colsep, abbrevlist[k])
        }
        ghead   = ghead + " | "
        ghead   = ghead + sprintf(gnumfmt[1], "N")
        ghead   = ghead + sprintf(gnumfmt[2], "Cum")
        ghead   = ghead + sprintf(ppctfmt,    "Pct (%)")
        ghead   = ghead + sprintf(cpctfmt,    "Cum Pct (%)")

        len = sum(gstrmax) +
              sum(gnummax) + 2 +
              kvars + 9 +
              (kvars - 1) * strlen(colsep) +
              20
        headfmt = " %" + strofreal(len) + "s\n"

        printf("\n")
        printf(headfmt, ghead)
        printf(sprintf(" {hline %g}\n", len + max((0, 2 * pctlen - 20))))
        for (i = 1; i <= ntop; i++) {
            printf(headfmt, gprint[i])
        }

        if ( any(si_miss) | any(si_other) ) {
            printf(sprintf(" {hline %g}\n", len + max((0, 2 * pctlen - 20))))
            for (i = (ntop + 1); i <= rows(gprint); i++) {
                printf(headfmt, gprint[i])
            }
        }

        printf("\n")
    }
    else {
        printf("(no groups)\n")
    }
    st_matrix(outmat, gmat)
}

string scalar function __gtools_unquote(string scalar quoted_str)
{
    if ( substr(quoted_str, 1, 1) == `"""' ) {
        quoted_str = substr(quoted_str, 2, strlen(quoted_str) - 2)
    }
    else if (substr(quoted_str, 1, 2) == "`" + `"""') {
        quoted_str = substr(quoted_str, 3, strlen(quoted_str) - 4)
    }
    return (quoted_str);
}
end
