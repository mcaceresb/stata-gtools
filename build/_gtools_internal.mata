cap mata: mata drop GtoolsResults()
cap mata: mata drop GtoolsByLevels()
cap mata: mata drop GtoolsRegressOutput()

cap mata: mata drop GtoolsReadMatrix()
cap mata: mata drop GtoolsDecodeStat()
cap mata: mata drop GtoolsDecodePth()
cap mata: mata drop GtoolsSmartLevels()
cap mata: mata drop GtoolsPrintfSwitch()
cap mata: mata drop GtoolsFormatDefaultFallback()

cap mata: mata drop GtoolsGtopPrintTop()
cap mata: mata drop GtoolsGtopUnquote()

***********************************************************************
*                     Gtools by levels (generic)                      *
***********************************************************************

mata:
class GtoolsByLevels
{
    real     scalar      anyvars
    real     scalar      anychar
    real     scalar      anynum
    string   rowvector   byvars
    real     scalar      kby
    real     scalar      rowbytes
    real     scalar      J
    real     matrix      numx
    string   matrix      charx
    real     scalar      knum
    real     scalar      kchar
    real     rowvector   lens
    real     rowvector   map
    real     rowvector   charpos
    string   scalar      whoami
    string   matrix      printed
    real     matrix      toplevels
    real     colvector   nj
    real     matrix      njabsorb
    string   scalar      caller

    void read()
    void desc()
    void getPrinted()
}

void function GtoolsByLevels::read(string scalar numfmt, real scalar valuelabels)
{
    real scalar fbyvar, fbycol
    real scalar j, k, ixchar
    real rowvector novlab
    real scalar ncol
    string scalar s
    real scalar z
    colvector C

    byvars  = tokens(st_global("GTOOLS_BYNAMES"))
    kby     = cols(byvars)
    if ( kby > 0 ) {
        anyvars = 1
        fbycol  = fopen(st_global("GTOOLS_BYCOL_FILE"), "r")
        C       = bufio()
        anychar = fbufget(C, fbycol, "%8z", 1, 1)
        anynum  = fbufget(C, fbycol, "%8z", 1, 1)
        J       = fbufget(C, fbycol, "%8z", 1, 1)
        printed = numfmt == ""? "": J(J, kby, "")
        ncol    = fbufget(C, fbycol, "%8z", 1, 1)
        if ( anychar ) {
            rowbytes = fbufget(C, fbycol, "%8z", 1, 1)
            knum     = fbufget(C, fbycol, "%8z", 1, 1)
            kchar    = fbufget(C, fbycol, "%8z", 1, 1)
            lens     = J(1, ncol - 1, .)
            map      = J(1, ncol - 1, .)
            charpos  = J(1, kchar, .)
            for (k = 1; k < ncol; k++) {
                lens[k] = fbufget(C, fbycol, "%8z", 1, 1)
            }
            for (k = 1; k < ncol; k++) {
                map[k]  = fbufget(C, fbycol, "%8z", 1, 1)
            }
            ixchar = 0;
            for (k = 1; k < ncol; k++) {
                if ( lens[k] > 0 ) {
                    ixchar++
                    charpos[ixchar] = k
                }
            }
        }
        else {
            rowbytes = 0
            knum     = ncol - 1
            kchar    = 0
            lens     = .
            map      = .
            charpos  = .
        }
        fclose(fbycol)

        fbyvar = fopen(st_global("GTOOLS_BYVAR_FILE"), "r")
        if ( anychar ) {
            numx  = J(J, knum,  .)
            charx = J(J, kchar, "")
            if ( numfmt == "" ) {
                for(j = 1; j <= J; j++) {
                    for (k = 1; k < ncol; k++) {
                        if ( lens[k] > 0 ) {
                            charx[j, map[k]] = fbufget(C, fbyvar, sprintf("%%%gS", lens[k] + 1), 1)
                        }
                        else {
                            numx[j, map[k]] = fbufget(C, fbyvar, "%8z", 1, 1)
                        }
                    }
                    // ): note this assume sizeof(GT_size) = sizeof(ST_double)
                    (void) fbufget(C, fbyvar, "%8z", 1, 1)
                }
                charx = subinstr(charx, char(0), "", .)
            }
            else {
                novlab = J(1, ncol - 1, 1)
                for (k = 1; k < ncol; k++) {
                    if ( st_varvaluelabel(byvars[k]) != "" ) {
                        novlab[k] = 0
                    }
                }
                for(j = 1; j <= J; j++) {
                    for (k = 1; k < ncol; k++) {
                        if ( lens[k] > 0 ) {
                            s = subinstr(fbufget(C, fbyvar, sprintf("%%%gS", lens[k] + 1), 1), char(0), "", .)
                            printed[j, k]    = s
                            charx[j, map[k]] = s
                        }
                        else {
                            z = fbufget(C, fbyvar, "%8z", 1, 1)
                            numx[j, map[k]] = z
                            if ( novlab[k] ) {
                                printed[j, k] = strtrim(sprintf(numfmt, z))
                            }
                            else {
                                printed[j, k] = st_vlmap(st_varvaluelabel(byvars[k]), z)
                            }
                        }
                    }
                    // ): note this assume sizeof(GT_size) = sizeof(ST_double)
                    (void) fbufget(C, fbyvar, "%8z", 1, 1)
                }
            }

            // if ( anynum ) {
            //     fbyvar = fopen(st_global("GTOOLS_BYVAR_FILE"), "r")
            //     fbynum = fopen(st_global("GTOOLS_BYNUM_FILE"), "r")
            //     numx   = fbufget(C, fbynum, "%8z", J, knum)
            //     charx  = J(J, kchar, "")
            //     for(j = 1; j <= J; j++) {
            //         for (k = 1; k <= kchar; k++) {
            //             charx[j, k] = fbufget(C, fbyvar, sprintf("%%%gS", lens[charpos[k]] + 1), 1)
            //         }
            //     }
            //     charx = subinstr(charx, char(0), "", .)
            //     fclose(fbyvar)
            //     fclose(fbynum)
            // }
            // else {
            //     fbyvar = fopen(st_global("GTOOLS_BYVAR_FILE"), "r")
            //     charx  = J(J, ncol - 1, "")
            //     for(j = 1; j <= J; j++) {
            //         for (k = 1; k < ncol; k++) {
            //             charx[j, k] = fbufget(C, fbyvar, sprintf("%%%gS", lens[k] + 1), 1)
            //         }
            //         (void) fbufget(C, fbyvar, "%8z", 1, 1)
            //     }
            //     charx = subinstr(charx, char(0), "", .)
            //     fclose(fbyvar)
            // }

        }
        else {
            numx  = fbufget(C, fbyvar, "%8z", J, ncol)[., 1::(ncol - 1)]
            charx = ""
            if ( numfmt != "" ) {
                if ( valuelabels ) {
                    novlab = J(1, ncol - 1, 1)
                    for (k = 1; k < ncol; k++) {
                        if ( st_varvaluelabel(byvars[k]) != "" ) {
                            printed[., k] = st_vlmap(st_varvaluelabel(byvars[k]), numx[., k])
                            novlab[k] = 0
                        }
                    }
                    for(j = 1; j <= J; j++) {
                        for (k = 1; k < ncol; k++) {
                            if ( novlab[k] ) {
                                printed[j, k] = strtrim(sprintf(numfmt, numx[j, k]))
                            }
                        }
                    }
                }
                else {
                    for(j = 1; j <= J; j++) {
                        for (k = 1; k < ncol; k++) {
                            printed[j, k] = strtrim(sprintf(numfmt, numx[j, k]))
                        }
                    }
                }
            }
        }
        fclose(fbyvar)
    }
    else {
        anyvars   = 0
        anychar   = .
        anynum    = .
        rowbytes  = 0
        J         = 1
        numx      = .
        charx     = ""
        knum      = .
        kchar     = .
        lens      = .
        map       = .
        charpos   = .
        printed   = ""
        toplevels = .
        nj        = .
        njabsorb  = .
    }
}

void function GtoolsByLevels::desc()
{
    string matrix printstr
    real scalar i, j
    real rowvector printlens
    string rowvector printfmts

    printstr = J((anyvars? (12 + (caller == "gtop") + 2 * (caller == "gstats hdfe")): 1), 3, " ")
    printstr[1, 1] = "object"
    printstr[1, 2] = "value"
    printstr[1, 3] = "description"

    if ( anyvars ) {
        printstr[3,  1] = "byvars"
        printstr[4,  1] = "J"
        printstr[5,  1] = "knum"
        printstr[6,  1] = "numx"
        printstr[7,  1] = "kchar"
        printstr[8,  1] = "charx"
        printstr[9,  1] = "map"
        printstr[10, 1] = "lens"
        printstr[11, 1] = "charpos"
        printstr[12, 1] = "printed"
        if ( caller == "gtop" ) {
            printstr[13, 1] = "toplevels"
        }
        if ( caller == "gstats hdfe" ) {
            printstr[13, 1] = "nj"
            printstr[14, 1] = "njabsorb"
        }

        printstr[3,  2] = sprintf("1 x %g", cols(byvars))
        printstr[4,  2] = sprintf("%g", J)
        printstr[5,  2] = sprintf("%g", knum)
        printstr[6,  2] = knum? sprintf("%g x %g matrix", rows(numx), cols(numx)): "[empty]"
        printstr[7,  2] = sprintf("%g", kchar)
        printstr[8,  2] = kchar? sprintf("%g x %g matrix", rows(charx), cols(charx)): "[empty]"
        printstr[9,  2] = sprintf("1 x %g vector",  cols(map))
        printstr[10, 2] = sprintf("1 x %g vector",  cols(lens))
        printstr[11, 2] = sprintf("1 x %g vector",  cols(charpos))
        printstr[12, 2] = printed == ""? "[empty]": sprintf("%g x %g vector", rows(printed), cols(printed))
        if ( caller == "gtop" ) {
            printstr[13, 2] = sprintf("%g x 5 vector",  rows(toplevels))
        }
        if ( caller == "gstats hdfe" ) {
            printstr[13, 2] = sprintf("%g x 1 vector",  rows(nj))
            printstr[14, 2] = sprintf("%g x %g matrix", rows(njabsorb), cols(njabsorb))
        }

        printstr[3,  3] = "by variable names"
        printstr[4,  3] = "number of levels"
        printstr[5,  3] = "# numeric by variables"
        printstr[6,  3] = "numeric by var levels"
        printstr[7,  3] = "# of string by variables"
        printstr[8,  3] = "character by var levels"
        printstr[9,  3] = "map by vars index to numx and charx"
        printstr[10, 3] = "if string, > 0; if numeric, <= 0"
        printstr[11, 3] = "position of kth character variable"
        printstr[12, 3] = "formatted (printf-ed) variable levels"
        if ( caller == "gtop" ) {
            printstr[13, 3] = "frequencies of top levels"
        }
        if ( caller == "gstats hdfe" ) {
            printstr[13, 3] = "non-missing obs (row-wise) for each by group"
            printstr[14, 3] = "# FE each absorb variable had for each by group"
        }

        printlens      = colmax(strlen(printstr))
        printfmts      = J(1, 3, "")
        printstr[2, 1] = sprintf("{hline %g}", printlens[1])
        printstr[2, 2] = sprintf("{hline %g}", printlens[2])
        printstr[2, 3] = sprintf("{hline %g}", printlens[3])
        printfmts[1]   = sprintf("%%-%gs", printlens[1])
        printfmts[2]   = sprintf("%%%gs",  printlens[2])
        printfmts[3]   = sprintf("%%-%gs", printlens[3])

        printf("\n")
        printf("    %s is a class object with group levels\n", whoami)
        printf("\n")
        for(i = 1; i <= rows(printstr); i++) {
            printf("        | ")
            if ( i == 2 ) {
                for(j = 1; j <= cols(printstr); j++) {
                    printf(printstr[i, j])
                    printf(" | ")
                }
            }
            else {
                for(j = 1; j <= cols(printstr); j++) {
                    printf(printfmts[j], printstr[i, j])
                    printf(" | ")
                }
            }
                printf("\n")
        }
        printf("\n")

        if ( (rows(toplevels) > J) & (caller == "gtop") ) {
            printf("    toplevels value key (column 1):\n")
            printf("\n")
            printf("        1 = top level(s) frequency\n")
            printf("        2 = missing level(s) frequency\n")
            printf("        3 = frequency for all other levels\n")
            printf("\n")
        }
    }
    else {
        printf("\n")
        printf("    %s is a class object to store group levels; it is currently empty.\n", whoami)
        printf("\n")
    }
}

void function GtoolsByLevels::getPrinted(string scalar numfmt, real scalar valuelabels)
{
    real rowvector novlab
    real scalar j, k

    if ( numfmt == "" ) {
        printf("nothing to do\n")
    }
    else if ( kby > 0 ) {
        printed = J(J, kby, "")
        if ( anychar ) {
            novlab = J(1, kby, 1)
            for (k = 1; k <= kby; k++) {
                if ( st_varvaluelabel(byvars[k]) != "" ) {
                    novlab[k] = 0
                }
            }
            for(j = 1; j <= J; j++) {
                for (k = 1; k <= kby; k++) {
                    if ( lens[k] > 0 ) {
                        printed[j, k] = charx[j, map[k]]
                    }
                    else {
                        if ( novlab[k] ) {
                            printed[j, k] = strtrim(sprintf(numfmt, numx[j, map[k]]))
                        }
                        else {
                            printed[j, k] = st_vlmap(st_varvaluelabel(byvars[k]), numx[j, map[k]])
                        }
                    }
                }
            }
        }
        else {
            if ( valuelabels ) {
                novlab = J(1, kby, 1)
                for (k = 1; k <= kby; k++) {
                    if ( st_varvaluelabel(byvars[k]) != "" ) {
                        printed[., k] = st_vlmap(st_varvaluelabel(byvars[k]), numx[., k])
                        novlab[k] = 0
                    }
                }
                for(j = 1; j <= J; j++) {
                    for (k = 1; k <= kby; k++) {
                        if ( novlab[k] ) {
                            printed[j, k] = strtrim(sprintf(numfmt, numx[j, k]))
                        }
                    }
                }
            }
            else {
                for(j = 1; j <= J; j++) {
                    for (k = 1; k <= kby; k++) {
                        printed[j, k] = strtrim(sprintf(numfmt, numx[j, k]))
                    }
                }
            }
        }
        printf("note: printed levels stored in %s.printed\n", whoami)
    }
}
end

***********************************************************************
*                   Gtools results (for gstats tab)                   *
***********************************************************************

mata:
class GtoolsResults
{
    real     scalar      colvar
    real     scalar      ksources
    real     scalar      kstats
    real     matrix      output
    real     matrix      tabstat

    real     scalar      anyvars
    real     scalar      anychar
    string   rowvector   byvars
    real     scalar      kby
    real     scalar      rowbytes
    real     scalar      J
    real     matrix      numx
    string   matrix      charx
    real     scalar      knum
    real     scalar      kchar
    real     rowvector   lens
    real     rowvector   map

    string   rowvector   statvars
    string   rowvector   statnames
    real     rowvector   scodes
    real     scalar      pool
    real     scalar      maxlbl
    real     scalar      pretty
    real     scalar      usevfmt
    string   scalar      dfmt
    real     scalar      maxl
    real     scalar      nosep
    string   scalar      whoami

    void                 help()
    void                 desc()
    void                 read()
    void                 readOutput()
    void                 readScalars()
    void                 readDefaults()
    void                 readStatnames()
    void                 printOutput()

    string   scalar      getf()
    real     matrix      getnum()
    string   matrix      getchar()
    real     rowvector   getOutputRow()
    real     colvector   getOutputCol()
    real     matrix      getOutputVar()
    real     matrix      getOutputGroup()
}

void function GtoolsResults::read()
{
    real scalar fbyvar, fbycol
    real scalar j, k, ixnum, ixchar
    real scalar ncol
    colvector C

    byvars = tokens(st_global("GTOOLS_BYNAMES"))
    kby    = cols(byvars)
    if ( kby > 0 ) {
        anyvars = 1
        fbycol  = fopen(st_global("GTOOLS_BYCOL_FILE"), "r")
        C       = bufio()
        anychar = fbufget(C, fbycol, "%8z", 1, 1)
        J       = fbufget(C, fbycol, "%8z", 1, 1)
        ncol    = fbufget(C, fbycol, "%8z", 1, 1)
        if ( anychar ) {
            rowbytes = fbufget(C, fbycol, "%8z", 1, 1)
            knum     = fbufget(C, fbycol, "%8z", 1, 1)
            kchar    = fbufget(C, fbycol, "%8z", 1, 1)
            lens     = J(1, ncol - 1, .)
            map      = J(1, ncol - 1, .)
            for (k = 1; k < ncol; k++) {
                lens[k] = fbufget(C, fbycol, "%8z", 1, 1)
            }
            ixnum  = 1;
            ixchar = 1;
            for (k = 1; k < ncol; k++) {
                if ( lens[k] > 0 ) {
                    map[k] = ixchar
                    ixchar++
                }
                else {
                    map[k] = ixnum
                    ixnum++
                }
            }
        }
        else {
            rowbytes = 0
            knum     = ncol - 1
            kchar    = 0
            lens     = .
            map      = .
        }
        fclose(fbycol)

        fbyvar = fopen(st_global("GTOOLS_BYVAR_FILE"), "r")
        if ( anychar ) {
            numx  = J(J, knum,  .)
            charx = J(J, kchar, "")
            for(j = 1; j <= J; j++) {
                for (k = 1; k < ncol; k++) {
                    if ( lens[k] > 0 ) {
                        charx[j, map[k]] = fbufget(C, fbyvar, sprintf("%%%gS", lens[k] + 1), 1)
                    }
                    else {
                        numx[j, map[k]] = fbufget(C, fbyvar, "%8z", 1, 1)
                    }
                }
                // ): note this assume sizeof(GT_size) = sizeof(ST_double)
                (void) fbufget(C, fbyvar, "%8z", 1, 1)
            }
        }
        else {
            numx  = fbufget(C, fbyvar, "%8z", J, ncol)[., 1::(ncol - 1)]
            charx = ""
        }
        fclose(fbyvar)
    }
    else {
        anyvars  = 0
        anychar  = .
        rowbytes = 0
        J        = 1
        numx     = .
        charx    = ""
        knum     = .
        kchar    = .
        lens     = .
        map      = .
    }
}

void function GtoolsResults::readScalars()
{
    usevfmt  = st_numscalar("__gtools_summarize_format")
    pretty   = st_numscalar("__gtools_summarize_pretty")
    pool     = st_numscalar("__gtools_summarize_pooled")
    maxlbl   = st_numscalar("__gtools_summarize_lwidth")
    nosep    = st_numscalar("__gtools_summarize_nosep")
    dfmt     = st_strscalar("__gtools_summarize_dfmt")
    maxl     = 11
}

void function GtoolsResults::readDefaults()
{
    usevfmt  = 0
    pretty   = 0
    pool     = 0
    maxlbl   = 16
    dfmt     = "%9.0g"
    maxl     = 11
    nosep    = 0
}

void function GtoolsResults::readStatnames()
{
    real scalar k
    statnames = J(1, kstats, "")
    for (k = 1; k <= kstats; k++) {
        statnames[k] = GtoolsDecodeStat(scodes[k], 0)
    }
}

void function GtoolsResults::readOutput(string scalar fname)
{
    if ( colvar ) {
        output = GtoolsReadMatrix(fname, kstats * J, ksources)
    }
    else {
        output = GtoolsReadMatrix(fname, ksources * J, kstats)
    }
}

string scalar function GtoolsResults::getf(
    real scalar j,
    real scalar l,
    real scalar maxlbl)
{
    string scalar var, vfmt, vlbl
    string scalar S
    real scalar X, dochar, mapsel

    if ( anyvars == 0 ) {
        return ("");
    }
    else {
        dochar = anychar
        var    = byvars[l]
        mapsel = l
        vfmt   = st_varformat(var)
        if ( dochar ) {
            mapsel = map[l]
            if ( lens[l] > 0 ) {
                dochar = 1
            }
            else {
                dochar = 0
            }
        }

        if ( dochar ) {
            S = sprintf("%s", charx[j, mapsel])
            if ( strlen(S) > maxlbl ) {
                return(substr(S, 1, maxlbl - 3) + "...")
            }
            else {
                return(S)
            }
        }
        else {
            vlbl = st_varvaluelabel(var)
            X    = numx[j, mapsel]
            if ( vlbl != "" ) {
                S = st_vlmap(vlbl, X)
                if ( strlen(S) > maxlbl ) {
                    return(substr(S, 1, maxlbl - 3) + "...")
                }
                else {
                    return(S)
                }
            }
            else {
                return(sprintf(vfmt, X))
            }
        }
    }
}

real matrix function GtoolsResults::getnum(
    real vector j,
    real vector l)
{
    if ( anyvars == 0 | kby == 0 ) {
        errprintf("no by variables stored\n")
        return(.);
    }
    else {
        if ( max(l) > knum & max(l) < . ) {
            errprintf("requested %gth nuemric variable but only found %g\n", max(l), knum)
            return(.)
        }
        return(numx[j, l])
    }
}

string matrix function GtoolsResults::getchar(
    real vector j,
    real vector l,
    | real scalar raw)
{
    if ( args() == 2 ) {
        raw = 0
    }
    if ( anyvars == 0 | kby == 0 ) {
        errprintf("no by variables stored\n")
        return("");
    }
    else {
        if ( anychar ) {
            if ( max(l) > kchar & max(l) < . ) {
                errprintf("requested %gth string variable but only found %g\n", max(l), kchar)
                return("")
            }
            else {
                return(raw? charx[j, l]: subinstr(charx[j, l], char(0), "", .))
            }
        }
        else {
            errprintf("no string variables stored\n")
            return("");
        }
    }
}

real rowvector function GtoolsResults::getOutputRow(real scalar i)
{
    if ( tabstat == 0 ) {
        errprintf("Helpers only available with tabstat\n")
        return(J(1, 0, .))
    }
    return(output[i, .])
}

real colvector function GtoolsResults::getOutputCol(real scalar k)
{
    if ( tabstat == 0 ) {
        errprintf("Helpers only available with tabstat\n")
        return(J(1, 0, .))
    }
    return(output[., k])
}

real matrix function GtoolsResults::getOutputGroup(real scalar j)
{
    real scalar from, to
    if ( tabstat == 0 ) {
        errprintf("Helpers only available with tabstat\n")
        return(J(1, 0, .))
    }
    if ( colvar ) {
        from = (j - 1) * kstats + 1
        to   = j * kstats
    }
    else {
        from = (j - 1) * ksources + 1
        to   = j * ksources
    }
    return(output[|from, 1 \ to, . |])
}

real matrix function GtoolsResults::getOutputVar(string scalar var)
{
    real scalar ix, j
    real colvector sel
    if ( tabstat == 0 ) {
        errprintf("Helpers only available with tabstat\n")
        return(J(1, 0, .))
    }
    if ( pool ) {
        errprintf("Variable selection not available pooled\n")
        return(J(1, 0, .))
    }
    else {
        ix = selectindex(statvars :== var)
        if ( cols(ix) == 0 ) {
            errprintf("Variable not found: %s\n", var)
            return(J(1, 0, .))
        }
        else if ( colvar ) {
            return(output[., ix])
        }
        else {
            sel = J(J, 1, .)
            for(j = 1; j <= J; j++) {
                sel[j] = (j - 1) * ksources + ix
            }
            return(output[sel, .])
        }
    }
}

void function GtoolsResults::printOutput(| real scalar commas)
{
    string scalar vfmt, fmt, var
    real scalar nrow, j, k, l, sel, width, widthrow
    string matrix printstr
    real colvector extrasep

    if ( args() == 0 ) {
        commas = 1
    }

    if ( tabstat == 0 ) {
        errprintf("Helpers only available with tabstat\n")
        return
    }

    if ( colvar ) {
        nrow     = kstats * J
        printstr = J(nrow + 1, ksources + 1 + kby, " ")
        extrasep = J(nrow + 1, 1, 0)

        // First get column widths, format
        for(l = 1; l <= kby; l++) {
            printstr[1, l] = byvars[l]
        }
            printstr[1, kby + 1] = "statistic"
        for(l = 1; l <= ksources; l++) {
            var = pool? "[Pooled Var]": statvars[l]
            printstr[1, kby + 1 + l] = var
        }

        for(j = 1; j <= J; j++) {
            for(l = 1; l <= kby; l++) {
                printstr[(j - 1) * kstats + 2, l] = getf(j, l, maxlbl)
            }
            for(k = 1; k <= kstats; k++) {
                sel = (j - 1) * kstats + k
                printstr[sel + 1, kby + 1] = GtoolsDecodeStat(scodes[k], pretty)
                for(l = 1; l <= ksources; l++) {
                    vfmt = pool? dfmt: (usevfmt? st_varformat(statvars[l]): dfmt)
                    printstr[sel + 1, kby + 1 + l] = GtoolsPrintfSwitch( /*
                        */ vfmt, dfmt, maxl, scodes[k], output[sel, l], commas)
                }
            }
        }
        width    = colmax(strlen(printstr)) :+ 1
        // widthrow = sum(width) + 3 + 2
        widthrow = sum(width) + 3 + 2 * ((kstats > 1) | (J == 1)) + ksources

        // Now print!
        if ( (kby > 1) & (kstats == 1) & (nosep == 0) ) {
            GtoolsSmartLevels(printstr, 2, nrow + 1, 1, kby, extrasep)
        }
        printf("\n")
        for(sel = 1; sel <= nrow + 1; sel++) {
            if ( extrasep[sel] & (nosep == 0) ) {
                printf("{hline %g}\n", widthrow - width[kby + 1])
            }
            for(l = 1; l <= kby; l++) {
                fmt = sprintf("%%%gs", width[l])
                printf(fmt, printstr[sel, l])
            }
            if ( (kstats > 1) | (J == 1) ) {
                printf("  ")
                fmt = sprintf("%%%gs", width[kby + 1])
                printf(fmt, printstr[sel, kby + 1])
            }
            printf(" | ")
            for(k = 1; k <= ksources; k++) {
                fmt = sprintf(" %%%gs", width[kby + 1 + k])
                printf(fmt, printstr[sel, kby + 1 + k])
            }
            printf("\n")
            if ( ((kstats > 1) | (J == 1) | (kby == 0)) & (nosep == 0) ) {
                if ( (mod(sel - 1, kstats) == 0) ) {
                    printf("{hline %g}\n", widthrow)
                }
            }
            else if ( ((sel == 1) | (sel == (nrow + 1))) & (nosep == 0) ) {
                printf("{hline %g}\n", widthrow - width[kby + 1])
            }
        }
    }
    else {
        nrow     = ksources * J
        printstr = J(nrow + 1, kstats + 1 + kby, " ")
        extrasep = J(nrow + 1, 1, 0)

        // First get column widths, format
        for(l = 1; l <= kby; l++) {
            printstr[1, l] = byvars[l]
        }
            printstr[1, kby + 1] = "variable"
        for(k = 1; k <= kstats; k++) {
            printstr[1, kby + 1 + k] = GtoolsDecodeStat(scodes[k], pretty)
        }

        for(j = 1; j <= J; j++) {
            for(l = 1; l <= kby; l++) {
                printstr[(j - 1) * ksources + 2, l] = getf(j, l, maxlbl)
            }
            for(l = 1; l <= ksources; l++) {
                var  = pool? "[Pooled Var]": statvars[l]
                vfmt = pool? dfmt: (usevfmt? st_varformat(var): dfmt)
                sel  = (j - 1) * ksources + l
                printstr[sel + 1, kby + 1] = var
                for(k = 1; k <= kstats; k++) {
                    printstr[sel + 1, kby + 1 + k] = GtoolsPrintfSwitch( /*
                        */ vfmt, dfmt, maxl, scodes[k], output[sel, k], commas)
                }
            }
        }
        width    = colmax(strlen(printstr)) :+ 1
        // widthrow = sum(width) + 3 + 2 * (1 - ((kby > 0) & (ksources == 1)))
        widthrow = sum(width) + 3 + 2 * ((ksources > 1) | (J == 1)) + kstats

        // Now print!
        if ( (kby > 1) & (ksources == 1) & (nosep == 0) ) {
            GtoolsSmartLevels(printstr, 2, nrow + 1, 1, kby, extrasep)
        }
        printf("\n")
        for(sel = 1; sel <= nrow + 1; sel++) {
            if ( extrasep[sel] & (nosep == 0) ) {
                printf("{hline %g}\n", widthrow - width[kby + 1])
            }
            for(l = 1; l <= kby; l++) {
                fmt = sprintf("%%%gs", width[l])
                printf(fmt, printstr[sel, l])
            }
            if ( (ksources > 1) | (J == 1) ) {
                printf("  ")
                fmt = sprintf("%%%gs", width[kby + 1])
                printf(fmt, printstr[sel, kby + 1])
            }
            printf(" | ")
            for(k = 1; k <= kstats; k++) {
                fmt = sprintf(" %%%gs", width[kby + 1 + k])
                printf(fmt, printstr[sel, kby + 1 + k])
            }
            printf("\n")
            if ( ((ksources > 1) | (J == 1) | (kby == 0)) & (nosep == 0) ) {
                if ( mod(sel - 1, ksources) == 0 ) {
                    printf("{hline %g}\n", widthrow)
                }
            }
            else if ( ((sel == 1) | (sel == (nrow + 1))) & (nosep == 0) ) {
                printf("{hline %g}\n", widthrow - width[kby + 1])
            }
        }
    }
}

void function GtoolsResults::help(|real scalar level)
{
    string scalar spacing
    if ( args() == 0 ) {
        level = 0
    }

    if ( (level == 1) | (level == 2) ) {
        spacing = "\n"
    }
    else {
        spacing = ""
    }

    if ( level != 2 ) {
    printf("%s is a class object with group levels and summary statistics\n", whoami)
    printf("\n")
    }

    printf("    helper functions:\n")
    printf(spacing)
    printf("        string scalar getf(j, l, maxlbl)\n")
    printf("            get formatted (j, l) entry from by variables up to maxlbl characters\n")
    printf(spacing)
    printf("        real matrix getnum(j, l)\n")
    printf("            get (j, l) numeric entry from by variables\n")
    printf(spacing)
    printf("        string matrix getchar(j, l, |raw)\n")
    printf("            get (j, l) numeric entry from by variables; raw controls whether to null-pad entries\n")
    printf(spacing)
    printf("        real rowvector getOutputRow(j)\n")
    printf("            get jth output row\n")
    printf(spacing)
    printf("        real colvector getOutputCol(j)\n")
    printf("            get jth output column by position\n")
    printf(spacing)
    printf("        real matrix getOutputVar(var)\n")
    printf("            get jth output var by name\n")
    printf(spacing)
    printf("        real matrix getOutputGroup(j)\n")
    printf("            get jth output group\n")
    printf(spacing)
    printf("\n")

    if ( level == 2 ) {
        return
    }

    printf("    summary statistics\n")
    printf(spacing)
    printf("        real matrix output \n")
    printf("            matrix with output statistics; J x kstats x kvars\n")
    printf(spacing)
    printf("        real scalar colvar \n")
    printf("            1: columns are variables, rows are statistics; 0: the converse\n")
    printf(spacing)
    printf("        real scalar ksources\n")
    printf("            number of variable sources (0 if pool is true)\n")
    printf(spacing)
    printf("        real scalar kstats \n")
    printf("            number of statistics\n")
    printf(spacing)
    printf("        real matrix tabstat \n")
    printf("            1: used tabstat; 0: used summarize\n")
    printf(spacing)
    printf("        string rowvector statvars\n")
    printf("            variables summarized\n")
    printf(spacing)
    printf("        string rowvector statnames\n")
    printf("            statistics computed\n")
    printf(spacing)
    printf("        real rowvector scodes\n")
    printf("            internal code for summary statistics\n")
    printf(spacing)
    printf("        real scalar pool\n")
    printf("            pooled source variables\n")
    printf(spacing)
    printf("\n")

    printf("    variable levels (empty if without -by()-)\n")
    printf(spacing)
    printf("        real scalar anyvars\n")
    printf("            1: any by variables; 0: no by variables\n")
    printf(spacing)
    printf("        real scalar anychar\n")
    printf("            1: any string by variables; 0: all numeric by variables\n")
    printf(spacing)
    printf("        string rowvector byvars\n")
    printf("            by variable names\n")
    printf(spacing)
    printf("        real scalar kby\n")
    printf("            number of by variables\n")
    printf(spacing)
    printf("        real scalar rowbytes\n")
    printf("            number of bytes in one row of the internal by variable matrix\n")
    printf(spacing)
    printf("        real scalar J\n")
    printf("            number of levels\n")
    printf(spacing)
    printf("        real matrix numx\n")
    printf("            numeric by variables\n")
    printf(spacing)
    printf("        string matrix charx\n")
    printf("            string by variables\n")
    printf(spacing)
    printf("        real scalar knum\n")
    printf("            number of numeric by variables\n")
    printf(spacing)
    printf("        real scalar kchar\n")
    printf("            number of string by variables\n")
    printf(spacing)
    printf("        real rowvector lens\n")
    printf("            > 0: length of string by variables; <= 0: internal code for numeric variables\n")
    printf(spacing)
    printf("        real rowvector map\n")
    printf("            map from index to numx and charx\n")
    printf(spacing)
    printf("\n")

    printf("    printing options:\n")
    printf(spacing)
    printf("        void printOutput()\n")
    printf("            print summary table\n")
    printf(spacing)
    printf("        real scalar maxlbl\n")
    printf("            max by variable label/value width\n")
    printf(spacing)
    printf("        real scalar pretty\n")
    printf("            print pretty statistic names\n")
    printf(spacing)
    printf("        real scalar usevfmt\n")
    printf("            use variable format for printing\n")
    printf(spacing)
    printf("        string scalar dfmt\n")
    printf("            fallback printing format\n")
    printf(spacing)
    printf("        real scalar maxl\n")
    printf("            maximum column length\n")
    printf(spacing)
    printf("        void readDefaults()\n")
    printf("            reset printing defaults\n")
    printf(spacing)
    printf("\n")

    // printf("    helper functions:\n")
    // printf("        string   scalar      getf(j, l, maxlbl)\n")
    // printf("            get formatted (j, l) entry from by variables up to maxlbl characters\n\n")
    // printf("        real     matrix      getnum(j, l)\n")
    // printf("            get (j, l) numeric entry from by variables\n\n")
    // printf("        string   matrix      getchar(j, l)\n")
    // printf("            get (j, l) numeric entry from by variables\n\n")
    // printf("        real     rowvector   getOutputRow(j)\n")
    // printf("            get jth output row\n\n")
    // printf("        real     colvector   getOutputCol(j)\n")
    // printf("            get jth output column by position\n\n")
    // printf("        real     matrix      getOutputVar(var)\n")
    // printf("            get jth output var by name\n\n")
    // printf("        real     matrix      getOutputGroup(j)\n")
    // printf("            get jth output group\n\n")
    // printf("\n")

    // printf("    summary statistics\n")
    // printf("        real     matrix      output  \n")
    // printf("            matrix with output statistics; J x kstats x kvars\n\n")
    // printf("        real     scalar      colvar  \n")
    // printf("            1: columns are variables, rows are statistics; 0: the converse\n\n")
    // printf("        real     scalar      ksources\n")
    // printf("            number of variable sources (0 if pool is true)\n\n")
    // printf("        real     scalar      kstats  \n")
    // printf("            number of statistics\n\n")
    // printf("        real     matrix      tabstat \n")
    // printf("            1: used tabstat; 0: used summarize\n\n")
    // printf("        string   rowvector   statvars\n")
    // printf("            variables summarized\n\n")
    // printf("        string   rowvector   statnames\n")
    // printf("            statistics computed\n\n")
    // printf("        real     rowvector   scodes\n")
    // printf("            internal code for summary statistics\n\n")
    // printf("        real     scalar      pool\n")
    // printf("            pooled source variables\n\n")
    // printf("\n")

    // printf("    variable levels (empty if without -by()-)\n")
    // printf("        real     scalar      anyvars\n")
    // printf("            1: any by variables; 0: no by variables\n\n")
    // printf("        real     scalar      anychar\n")
    // printf("            1: any string by variables; 0: all numeric by variables\n\n")
    // printf("        string   rowvector   byvars\n")
    // printf("            by variable names\n\n")
    // printf("        real     scalar      kby\n")
    // printf("            number of by variables\n\n")
    // printf("        real     scalar      rowbytes\n")
    // printf("            number of bytes in one row of the internal by variable matrix\n\n")
    // printf("        real     scalar      J\n")
    // printf("            number of levels\n\n")
    // printf("        real     matrix      numx\n")
    // printf("            numeric by variables\n\n")
    // printf("        string   matrix      charx\n")
    // printf("            string by variables\n\n")
    // printf("        real     scalar      knum\n")
    // printf("            number of numeric by variables\n\n")
    // printf("        real     scalar      kchar\n")
    // printf("            number of string by variables\n\n")
    // printf("        real     rowvector   lens\n")
    // printf("            > 0: length of string by variables; <= 0: internal code for numeric variables\n\n")
    // printf("        real     rowvector   map\n")
    // printf("            map from index to numx and charx\n\n")
    // printf("\n")

    // printf("    printing options:\n")
    // printf("        void                 printOutput()\n")
    // printf("            print summary table\n\n")
    // printf("        real     scalar      maxlbl\n")
    // printf("            max summarized variable name/label width\n\n")
    // printf("        real     scalar      pretty\n")
    // printf("            print pretty statistic names\n\n")
    // printf("        real     scalar      usevfmt\n")
    // printf("            use variable format for printing\n\n")
    // printf("        string   scalar      dfmt\n")
    // printf("            fallback printing format\n\n")
    // printf("        real     scalar      maxl\n")
    // printf("            maximum column length\n\n")
    // printf("        void                 readDefaults()\n")
    // printf("            reset printing defaults\n\n")
    // printf("\n")
}

void function GtoolsResults::desc()
{
    string matrix printstr
    real scalar or, i, j
    real rowvector printlens
    string rowvector printfmts

    or = 8 + (tabstat > 0) + (pool > 0)

    printstr = J(or + (anyvars? 8: 0), 3, " ")
    printstr[1, 1] = "object"
    printstr[1, 2] = "value"
    printstr[1, 3] = "description"

    printstr[3, 1] = "output"
    printstr[4, 1] = "ksources"
    printstr[5, 1] = "statvars"
    printstr[6, 1] = "kstats"
    printstr[7, 1] = "statnames"
    printstr[8, 1] = "colvar"

    printstr[3, 2] = sprintf("%g x %g matrix", rows(output), cols(output))
    printstr[4, 2] = sprintf("%g", ksources)
    printstr[5, 2] = sprintf("1 x %g vector", cols(statvars))
    printstr[6, 2] = sprintf("%g", kstats)
    printstr[7, 2] = sprintf("1 x %g vector", cols(statnames))

    printstr[3, 3] = "values of summary stats"
    printstr[4, 3] = "# of source variables"
    printstr[5, 3] = "source variable names"
    printstr[6, 3] = "# of stats computed"
    printstr[7, 3] = "names of stats computed"

    if ( colvar ) {
        printstr[8, 2] = "1"
        printstr[8, 3] = "stats by row, columns are variables"
    }
    else {
        printstr[8, 2] = "0"
        printstr[8, 3] = "stats by col, rows are variables"
    }

    if ( tabstat ) {
        printstr[9, 1] = "tabstat"
        printstr[9, 2] = "1"
        printstr[9, 3] = "computed in the style of tabstat"
    }

    if ( pool ) {
        printstr[10, 1] = "pool"
        printstr[10, 2] = "1"
        printstr[10, 3] = "source variables are pooled"
    }

    if ( anyvars ) {
        printstr[or + 1, 1] = "byvars"
        printstr[or + 2, 1] = "J"
        printstr[or + 3, 1] = "knum"
        printstr[or + 4, 1] = "numx"
        printstr[or + 5, 1] = "kchar"
        printstr[or + 6, 1] = "charx"
        printstr[or + 7, 1] = "map"
        printstr[or + 8, 1] = "lens"

        printstr[or + 1, 2] = sprintf("1 x %g", cols(byvars))
        printstr[or + 2, 2] = sprintf("%g", J)
        printstr[or + 3, 2] = sprintf("%g", knum)
        printstr[or + 4, 2] = knum? sprintf("%g x %g matrix", rows(numx), cols(numx)): "[empty]"
        printstr[or + 5, 2] = sprintf("%g", kchar)
        printstr[or + 6, 2] = kchar? sprintf("%g x %g matrix", rows(charx), cols(charx)): "[empty]"
        printstr[or + 7, 2] = sprintf("1 x %g vector", cols(map))
        printstr[or + 8, 2] = sprintf("1 x %g vector", cols(lens))

        printstr[or + 1, 3] = "by variable names"
        printstr[or + 2, 3] = "number of levels"
        printstr[or + 3, 3] = "# numeric by variables"
        printstr[or + 4, 3] = "numeric by var levels"
        printstr[or + 5, 3] = "# of string by variables"
        printstr[or + 6, 3] = "character by var levels"
        printstr[or + 7, 3] = "map by vars index to numx and charx"
        printstr[or + 8, 3] = "if string, > 0; if numeric, <= 0"
    }

    printlens      = colmax(strlen(printstr))
    printfmts      = J(1, 3, "")
    printstr[2, 1] = sprintf("{hline %g}", printlens[1])
    printstr[2, 2] = sprintf("{hline %g}", printlens[2])
    printstr[2, 3] = sprintf("{hline %g}", printlens[3])
    printfmts[1]   = sprintf("%%-%gs", printlens[1])
    printfmts[2]   = sprintf("%%%gs",  printlens[2])
    printfmts[3]   = sprintf("%%-%gs", printlens[3])

    printf("\n")
    printf("    %s is a class object with group levels and summary statistics\n", whoami)
    printf("\n")
    for(i = 1; i <= rows(printstr); i++) {
        printf("        | ")
        if ( i == 2 ) {
            for(j = 1; j <= cols(printstr); j++) {
                printf(printstr[i, j])
                printf(" | ")
            }
        }
        else {
            for(j = 1; j <= cols(printstr); j++) {
                printf(printfmts[j], printstr[i, j])
                printf(" | ")
            }
        }
            printf("\n")
    }
    printf("\n")

    help(2)
}
end

***********************************************************************
*                        Semi-Generic Helpers                         *
***********************************************************************

mata:
void function GtoolsFormatDefaultFallback(string scalar var,| string scalar fmt)
{
    string scalar v, l, f
    v = st_vartype(var)
    f = args() >= 2? fmt: ""
    if ( f == "" ) {
        if ( regexm(v, "str([1-9][0-9]*|L)") ) {
            l = regexs(1)
            if ( l == "L" ) {
                f = "%9s"
            }
            else {
                f = "%" + regexs(1) + "s"
            }
        }
        else if ( v == "byte" ) {
            f = "%8.0g"
        }
        else if ( v == "int" ) {
            f = "%8.0g"
        }
        else if ( v == "long" ) {
            f = "%12.0g"
        }
        else if ( v == "float" ) {
            f = "%9.0g"
        }
        else if ( v == "double" ) {
            f = "%10.0g"
        }
    }
    if ( f != "" ) {
        st_varformat(var, f)
    }
}

real matrix function GtoolsReadMatrix(
    string scalar fname,
    real scalar nrow,
    real scalar ncol)
{
    real scalar fh
    real matrix X
    colvector C
    fh = fopen(fname, "r")
    C  = bufio()
    X  = fbufget(C, fh, "%8z", nrow, ncol)
    fclose(fh)
    return (X)
}

string scalar function GtoolsDecodeStat(real scalar scode, real scalar pretty)
{
    real scalar sth
    if ( pretty ) {
        if ( scode ==  -1    ) return("Sum")                         // sum
        if ( scode ==  -2    ) return("Mean")                        // mean
        if ( scode ==  -26   ) return("Geometric mean")              // geomean
        if ( scode ==  -3    ) return("St Dev.")                     // sd
        if ( scode ==  -4    ) return("Max")                         // max
        if ( scode ==  -5    ) return("Min")                         // min
        if ( scode ==  -6    ) return("Count")                       // n
        if ( scode ==  -7    ) return("Percent")                     // percent
        if ( scode ==  50    ) return("Median")                      // median
        if ( scode ==  -9    ) return("IQR")                         // iqr
        if ( scode ==  -10   ) return("First")                       // first
        if ( scode ==  -11   ) return("First Non-Miss.")             // firstnm
        if ( scode ==  -12   ) return("Last")                        // last
        if ( scode ==  -13   ) return("Last Non-Miss.")              // lastnm
        if ( scode ==  -14   ) return("Group size")                  // freq
        if ( scode ==  -15   ) return("SE Mean")                     // semean
        if ( scode ==  -16   ) return("SE Mean (Binom)")             // sebinomial
        if ( scode ==  -17   ) return("SE Mean (Pois)")              // sepoisson
        if ( scode ==  -18   ) return("N Unique")                    // nunique
        if ( scode ==  -19   ) return("Skewness")                    // skewness
        if ( scode ==  -20   ) return("Kurtosis")                    // kurtosis
        if ( scode ==  -21   ) return("Unweighted sum")              // rawsum
        if ( scode ==  -22   ) return("N Missing")                   // nmissing
        if ( scode ==  -23   ) return("Variance")                    // variance
        if ( scode ==  -24   ) return("Coef. of variation")          // cv
        if ( scode ==  -25   ) return("Range")                       // range
        if ( scode ==  -101  ) return("Sum")                         // nansum
        if ( scode ==  -121  ) return("Unweighted sum")              // rawnansum
        if ( scode ==  -206  ) return("Sum Wgt.")                    // sum_w
        if ( scode ==  -203  ) return("Variance")                    // variance
        if ( scode ==  -27   ) return("Gini Coefficient")            // gini
        if ( scode ==  -27.1 ) return("Gini Coefficient (drop neg)") // gini|dropneg
        if ( scode ==  -27.2 ) return("Gini Coefficient (keep neg)") // gini|keepneg

        if ( scode > 1000 ) {
            sth = floor(scode) - 1000
            if ( floor(scode) == ceil(scode) ) {
                return(sprintf("%g%s Smallest", sth, GtoolsDecodePth(sth)))
            }
            else {
                return(sprintf("%g%s Smallest (Unw)", sth, GtoolsDecodePth(sth)))
            }
        }
        else if ( scode < -1000 ) {
            sth = abs(ceil(scode) + 1000)
            if ( floor(scode) == ceil(scode) ) {
                return(sprintf("%g%s Largest", sth, GtoolsDecodePth(sth)))
            }
            else {
                return(sprintf("%g%s Largest (Unw)", sth, GtoolsDecodePth(sth)))
            }
        }
        else if ( (scode > 0) & (scode < 100) ) {
            return(sprintf("%g%s Pctile", scode, GtoolsDecodePth(scode)))
        }
        else {
            return(sprintf("[unknown: %.1f]", scode))
        }
    }
    else {
        if ( scode ==  -1    ) return("sum")
        if ( scode ==  -2    ) return("mean")
        if ( scode ==  -26   ) return("geomean")
        if ( scode ==  -3    ) return("sd")
        if ( scode ==  -4    ) return("max")
        if ( scode ==  -5    ) return("min")
        if ( scode ==  -6    ) return("n")
        if ( scode ==  -7    ) return("percent")
        if ( scode ==  50    ) return("median")
        if ( scode ==  -9    ) return("iqr")
        if ( scode ==  -10   ) return("first")
        if ( scode ==  -11   ) return("firstnm")
        if ( scode ==  -12   ) return("last")
        if ( scode ==  -13   ) return("lastnm")
        if ( scode ==  -14   ) return("freq")
        if ( scode ==  -15   ) return("semean")
        if ( scode ==  -16   ) return("sebinomial")
        if ( scode ==  -17   ) return("sepoisson")
        if ( scode ==  -18   ) return("nunique")
        if ( scode ==  -19   ) return("skewness")
        if ( scode ==  -20   ) return("kurtosis")
        if ( scode ==  -21   ) return("rawsum")
        if ( scode ==  -22   ) return("nmissing")
        if ( scode ==  -23   ) return("variance")
        if ( scode ==  -24   ) return("cv")
        if ( scode ==  -25   ) return("range")
        if ( scode ==  -101  ) return("nansum")
        if ( scode ==  -121  ) return("rawnansum")
        if ( scode ==  -206  ) return("sum_w")
        if ( scode ==  -203  ) return("variance")
        if ( scode ==  -27   ) return("gini")
        if ( scode ==  -27.1 ) return("gini|dropneg")
        if ( scode ==  -27.2 ) return("gini|keepneg")
        if ( scode > 1000 ) {
            sth = floor(scode) - 1000
            if ( floor(scode) == ceil(scode) ) {
                return(sprintf("select%g", sth))
            }
            else {
                return(sprintf("rawselect%g", sth))
            }
        }
        else if ( scode < -1000 ) {
            sth = abs(ceil(scode) + 1000)
            if ( floor(scode) == ceil(scode) ) {
                return(sprintf("select-%g", sth))
            }
            else {
                return(sprintf("rawselect-%g", sth))
            }
        }
        else if ( (scode > 0) & (scode < 100) ) {
            return(sprintf("p%g", scode))
        }
        else {
            return(sprintf("[unknown: %.1f]", scode))
        }
    }
}

string scalar function GtoolsDecodePth(real scalar s)
{
    string scalar pth
    string scalar e2
    e2 = substr(strofreal(s), -2, 2)
    if ( (e2 == "11") | (e2 == "12") | (e2 == "13") ) {
        pth = "th"
    }
    else {
             if ( mod(s, 10) == 1 ) pth = "st"
        else if ( mod(s, 10) == 2 ) pth = "nd"
        else if ( mod(s, 10) == 3 ) pth = "rd"
        else                        pth = "th"
    }
    return(pth)
}

void function GtoolsSmartLevels(
    string matrix grows,
    real scalar rstart,
    real scalar rend,
    real scalar jstart,
    real scalar jend,
    real colvector extrasep)
{
    real scalar gallcomp, j, k
    string rowvector gcomp

    gallcomp = 0
    gcomp = J(1, jend - jstart + 1, "")
    for (k = jstart; k <= jend; k++) {
        gcomp[k - jstart + 1] = grows[rstart, k]
    }

    for (j = rstart + 1; j <= rend; j++) {
        if ( grows[j, jstart] == gcomp[1] ) {
            grows[j, jstart] = ""
            gallcomp = 1
        }
        else {
            gcomp[1] = grows[j, jstart]
            gallcomp = 0
            extrasep[j] = 1
        }
        for (k = jstart + 1; k <= jend; k++) {
            if ( (grows[j, k] == gcomp[k - jstart + 1]) & gallcomp ) {
                grows[j, k] = ""
            }
            else {
                gcomp[k - jstart + 1] = grows[j, k]
                gallcomp = 0
            }
        }
    }
}

string scalar function GtoolsPrintfSwitch(
    string scalar vfmt,
    string scalar dfmt,
    real scalar maxl,
    real scalar scode,
    real scalar x,
    | real scalar commas)
{
    if ( args() == 0 ) {
        commas = 0
    }
    string scalar s
    if (scode == -6 | scode == -22 | scode == -206) {
        if (x == round(x)) {
            if ( commas ) {
                s = strtrim(sprintf("%25.0gc", x))
            }
            else {
                s = sprintf(vfmt, x)
            }
        }
        else {
            s = sprintf(dfmt, x)
        }
    }
    else {
        s = sprintf(vfmt, x)
        if ( strlen(s) > maxl ) {
            s = sprintf(dfmt, x)
        }
    }
    return(s)
}
end

***********************************************************************
*                            gtop helpers                             *
***********************************************************************

mata:
void function GtoolsGtopPrintTop(
    real scalar kvars,
    string rowvector abbrevlist,
    real matrix gmat,
    real matrix nmat,
    string matrix printed,
    real scalar matasave)
{
    real scalar i, k, l, len, ntop, nrows, gallcomp, minstrlen, Jmiss, Jother
    real scalar nmap, knum, kstr, valabbrev, weights
    real scalar pctlen, wlen, dlen
    real colvector si_miss, si_other, fmtix
    real rowvector gstrmax, gnummax, colstrmax, colnummax, colmax
    string matrix grows, gparse
    string colvector _grows, gprint, fmtbak
    string rowvector gcomp, gstrfmt, gnumfmt, byvars, bynum, bystr
    string scalar sepfmt, ghead, headfmt, mlab, olab
    string scalar pctfmt, ppctfmt, cpctfmt, numvar, strvar
    string scalar levels, sep, colsep
    transmorphic t

    // Done here because if these have embedded characters the parsing
    // gets tripped up...

    Jmiss   = st_numscalar("r(Jmiss)")
    Jother  = st_numscalar("r(Jother)")
    levels  = st_global("r(levels)")
    sep     = st_global("r(sep)")
    colsep  = st_global("r(colsep)")

    weights = st_local("weights") != ""
    pctfmt  = st_local("pctfmt")
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

    nmap   = (st_local("valuelabels") == "")
    byvars = tokens(st_local("byvars"))
    bynum  = tokens(st_local("bynum"))
    bystr  = tokens(st_local("bystr"))

    knum   = cols(bynum)
    kstr   = cols(bystr)

    ntop   = sum(gmat[., 1] :== 1)
    nrows  = sum(gmat[., 1] :!= 0)

    if ( nrows > 0 ) {
        gmat   = gmat[selectindex(gmat[., 1] :!= 0), .]
        gcomp  = J(1, kvars, "")
        gparse = J(rows(gmat), 2, "")
        gprint = J(rows(gmat) + 1, 1, "")

        if ( matasave == 0 ) {
            grows = J(rows(gmat), kvars, "")
            t = tokeninit(sep, (""), (`""""', `"`""'"'), 1)
            tokenset(t, levels)

            if ( ntop > 0 ) {
                _grows = tokengetall(t)
                for (i = 1; i <= cols(_grows); i++) {
                    _grows[i] = GtoolsGtopUnquote(_grows[i]);
                }

                if ( kvars > 1 ) {
                    t = tokeninit(colsep, (""), (`""""', `"`""'"'), 1)
                    for (i = 1; i <= cols(_grows); i++) {
                        tokenset(t, _grows[i])
                        grows[i, .] = tokengetall(t)
                        for (k = 1; k <= kvars; k++) {
                            grows[i, k] = GtoolsGtopUnquote(grows[i, k])
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
                            if ( length(fmtix) > 0 ) {
                                grows[fmtix, l] = fmtbak[fmtix]
                            }
                        }
                    }
                }
            }
        }
        else {
            grows = printed
        }

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

        if ( weights ) {
            for (i = 1; i <= rows(gmat); i++) {
                gparse[i, 1] = strtrim(sprintf("%21.3gc", gmat[i, 2]))
                gparse[i, 2] = strtrim(sprintf("%21.3gc", gmat[i, 3]))
            }
        }
        else {
            for (i = 1; i <= rows(gmat); i++) {
                gparse[i, 1] = strtrim(sprintf("%21.0gc", gmat[i, 2]))
                gparse[i, 2] = strtrim(sprintf("%21.0gc", gmat[i, 3]))
            }
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
            if ( (st_local("ngroups") == "") & (Jmiss > 1) ) {
                mlab = mlab + sprintf(" (%g groups)", Jmiss)
            }
            if ( minstrlen < strlen(mlab) ) {
                gstrmax[1] = strlen(mlab) - minstrlen + gstrmax[1]
            }
        }
        if ( any(si_other) ) {
            minstrlen = sum(gstrmax) + (kvars - 1) + (kvars - 1) * strlen(colsep);
            if ( (st_local("ngroups") == "") & Jother ) {
                olab = olab + sprintf(" (%s group%s)", strtrim(sprintf("%21.0gc", Jother)), Jother > 1? "s": "")
            }
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
        ghead   = ghead + sprintf(gnumfmt[1], weights? "W": "N")
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

    if ( matasave == 0 ) {
        st_matrix(st_local("gmat"), gmat)
    }
}

string scalar function GtoolsGtopUnquote(string scalar quoted_str)
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

***********************************************************************
*                      Gtools Regression Output                       *
***********************************************************************

mata:
class GtoolsRegressOutput
{
    real   scalar    kx
    real   scalar    cons
    string scalar    setype
    real   matrix    b
    real   scalar    saveb
    real   matrix    se
    real   matrix    Vcov
    real   scalar    savese

    real   scalar    J
    real   scalar    by
    string rowvector byvars
    real   scalar    absorb
    string rowvector absorbvars
    real   matrix    njabsorb
    real   scalar    savenjabsorb
    string rowvector clustervars
    real   colvector njcluster
    real   scalar    savenjcluster
    string rowvector yvarlist
    string rowvector xvarlist
    string rowvector zvarlist

    class GtoolsByLevels ByLevels
    string scalar whoami
    string scalar caller

    void init()
    void print()
    void desc()
    void readMatrices()
}

void function GtoolsRegressOutput::init()
{
    caller = st_local("caller")
    saveb  = st_numscalar("__gtools_gregress_savemb")
    savese = st_numscalar("__gtools_gregress_savemse")
    savenjabsorb  = 0
    savenjcluster = 0

    if ( st_numscalar("__gtools_gregress_cluster") > 0 ) {
        setype = "cluster"
        clustervars = tokens(st_local("cluster"))
    }
    else if ( st_numscalar("__gtools_gregress_robust") ) {
        setype = "robust"
    }
    else {
        setype = "homoskedastic"
    }

    if ( st_numscalar("__gtools_gregress_absorb") > 0 ) {
        cons = 0
        absorb = 1
        absorbvars = tokens(st_local("absorb"))
    }
    else {
        absorb = 0
        if ( st_numscalar("__gtools_gregress_cons") ) {
            cons = 1
        }
        else {
            cons = 0
        }
    }

    kx = st_numscalar("__gtools_gregress_kv")
    if ( st_local("byvars") != "" ) {
        by = 1
        byvars = tokens(st_local("byvars"))
    }
    else {
        by = 0
    }

    if ( st_local("yvarlist") != "" ) {
        yvarlist = tokens(st_local("yvarlist"))
    }

    if ( st_local("xvarlist") != "" ) {
        xvarlist = tokens(st_local("xvarlist"))
    }

    if ( st_local("zvarlist") != "" ) {
        zvarlist = tokens(st_local("zvarlist"))
    }
}

void function GtoolsRegressOutput::readMatrices()
{
    real matrix qc
    real scalar runols, runse, runhdfe
    J = strtoreal(st_local("r_J"))
    if ( st_numscalar("__gtools_gregress_savemb") ) {
        b = editmissing(GtoolsReadMatrix(st_local("gregbfile"),  J, kx), 0)
    }
    if ( st_numscalar("__gtools_gregress_savemse") ) {
        se = GtoolsReadMatrix(st_local("gregsefile"), J, kx)
        if ( by == 0 ) {
            Vcov = GtoolsReadMatrix(st_local("gregvcovfile"), kx, kx)
            qc   = diag((se:^2) :/ rowshape(diagonal(Vcov), 1))
            Vcov = editmissing(makesymmetric(Vcov :* qc), 0)
        }
        else {
            Vcov = .
        }
    }

    runols  = st_numscalar("__gtools_gregress_savemse") | st_numscalar("__gtools_gregress_savegse")
    runols  = st_numscalar("__gtools_gregress_savemse") | st_numscalar("__gtools_gregress_savegse") | runols
    runse   = st_numscalar("__gtools_gregress_savemse") | st_numscalar("__gtools_gregress_savegse")
    runhdfe = st_numscalar("__gtools_gregress_saveghdfe")

    if ( (setype == "cluster") & runols & runse ) {
        njcluster = GtoolsReadMatrix(st_local("gregclusfile"), J, 1)
        savenjcluster = 1
    }

    if ( absorb & (runols | runse | runhdfe) ) {
        njabsorb = GtoolsReadMatrix(st_local("gregabsfile"), J, st_numscalar("__gtools_gregress_absorb"))
        savenjabsorb = 1
    }
}

void function GtoolsRegressOutput::print(|real scalar trans)
{

    real scalar j, k
    if ( args() == 0 ) {
        trans = 0
    }

    if ( trans ) {
        if ( saveb & savese ) {
            for (j = 1; j <= J; j++) {
                for (k = 1; k <= kx; k++) {
                    printf("\t%9.6g (%9.6g)", b[j, k], se[j, k])
                }
                    printf("\n")
            }
        }
        else if ( saveb ) {
            for (j = 1; j <= J; j++) {
                for (k = 1; k <= kx; k++) {
                    printf("\t%9.6g", b[j, k])
                }
                    printf("\n")
            }
        }
        else if ( savese ) {
            for (j = 1; j <= J; j++) {
                for (k = 1; k <= kx; k++) {
                    printf("\t%(9.6g)", se[j, k])
                }
                    printf("\n")
            }
        }
    }
    else {
        if ( saveb & savese ) {
            for (k = 1; k <= kx; k++) {
                for (j = 1; j <= J; j++) {
                    printf("\t%9.6g (%9.6g)", b[j, k], se[j, k])
                }
                    printf("\n")
            }
        }
        else if ( saveb ) {
            for (k = 1; k <= kx; k++) {
                for (j = 1; j <= J; j++) {
                    printf("\t%9.6g", b[j, k])
                }
                    printf("\n")
            }
        }
        else if ( savese ) {
            for (k = 1; k <= kx; k++) {
                for (j = 1; j <= J; j++) {
                    printf("\t(%9.6g)", se[j, k])
                }
                    printf("\n")
            }
        }
    }
}

void function GtoolsRegressOutput::desc()
{
    string matrix printstr
    real scalar i, j, nrows, bpos, sepos, bypos, apos, cpos
    real rowvector printlens
    string rowvector printfmts

    nrows = 4
    if ( saveb ) {
        nrows = nrows + 1
        bpos  = nrows
    }
    if ( savese ) {
        sepos = nrows + 1
        nrows = nrows + 2
    }
    if ( by ) {
        bypos = nrows + 1
        nrows = nrows + 3
    }
    if ( absorb ) {
        apos  = nrows + 1
        nrows = nrows + 1 + savenjabsorb
    }
    if ( setype == "cluster" ) {
        cpos  = nrows + 1
        nrows = nrows + 1 + savenjcluster
    }

    printstr = J(nrows, 3, " ")

    printstr[1, 1] = "object"
    printstr[1, 2] = "value"
    printstr[1, 3] = "description"

    printstr[3, 1] = "kx"
    printstr[3, 2] = sprintf("%g", kx)
    printstr[3, 3] = "number of (non-absorbed) covariates"

    printstr[4, 1] = "cons"
    printstr[4, 2] = sprintf("%g", cons)
    printstr[4, 3] = "whether a constant was added automagically"

    if ( saveb ) {
        printstr[bpos, 1] = "b"
        printstr[bpos, 2] = sprintf("%g x %g matrix", rows(b),  cols(b))
        printstr[bpos, 3] = "regression coefficients"
    }
    if ( savese ) {
        printstr[sepos,     1] = "se"
        printstr[sepos + 1, 1] = "setype"
        printstr[sepos,     2] = sprintf("%g x %g matrix", rows(se), cols(se))
        printstr[sepos + 1, 2] = sprintf("%s", setype)
        printstr[sepos,     3] = "corresponding standard errors"
        printstr[sepos + 1, 3] = "type of SE computed (homoskedastic, robust, or cluster)"
    }
    if ( by ) {
        printstr[bypos,     1] = "byvars"
        printstr[bypos + 1, 1] = "J"
        printstr[bypos + 2, 1] = "ByLevels"
        printstr[bypos,     2] = sprintf("1 x %g row vector", cols(byvars))
        printstr[bypos + 1, 2] = sprintf("%g", J)
        printstr[bypos + 2, 2] = sprintf("GtoolsByLevels class object")
        printstr[bypos,     3] = "grouping variable names"
        printstr[bypos + 1, 3] = "number of levels defined by grouping variables"
        printstr[bypos + 2, 3] = sprintf("grouping variable levels; see %s.ByLevels.desc() for details", whoami)
    }
    if ( absorb ) {
        printstr[apos, 1] = "absorbvars"
        printstr[apos, 2] = sprintf("1 x %g row vector", cols(absorbvars))
        printstr[apos, 3] = "variables absorbed as fixed effects"
        if ( savenjabsorb ) {
            printstr[apos + 1, 1] = "njabsorb"
            printstr[apos + 1, 2] = sprintf("%g x %g row vector", rows(njabsorb), cols(njabsorb))
            printstr[apos + 1, 3] = "number of FE each absorb variable had for each grouping level"
        }
    }
    if ( setype == "cluster" ) {
        printstr[cpos, 1] = "clustervars"
        printstr[cpos, 2] = sprintf("1 x %g row vector", cols(clustervars))
        printstr[cpos, 3] = "cluster variables"
        if ( savenjcluster ) {
            printstr[cpos + 1, 1] = "njcluster"
            printstr[cpos + 1, 2] = sprintf("%g x %g row vector", rows(njcluster), cols(njcluster))
            printstr[cpos + 1, 3] = "number of clusters per grouping level"
        }
    }

    printlens      = colmax(strlen(printstr))
    printfmts      = J(1, 3, "")
    printstr[2, 1] = sprintf("{hline %g}", printlens[1])
    printstr[2, 2] = sprintf("{hline %g}", printlens[2])
    printstr[2, 3] = sprintf("{hline %g}", printlens[3])
    printfmts[1]   = sprintf("%%-%gs", printlens[1])
    printfmts[2]   = sprintf("%%%gs",  printlens[2])
    printfmts[3]   = sprintf("%%-%gs", printlens[3])

    printf("\n")
    printf("    %s is a class object with %s results\n", whoami, caller)
    printf("\n")
    for(i = 1; i <= rows(printstr); i++) {
        printf("        | ")
        if ( i == 2 ) {
            for(j = 1; j <= cols(printstr); j++) {
                printf(printstr[i, j])
                printf(" | ")
            }
        }
        else {
            for(j = 1; j <= cols(printstr); j++) {
                printf(printfmts[j], printstr[i, j])
                printf(" | ")
            }
        }
            printf("\n")
    }
    printf("\n")

    // else {
    //     printf("\n")
    //     printf("    %s is a class object to store regression results; it is currently empty.\n", whoami)
    //     printf("\n")
    // }
}
end

// mata mata set matastrict on
// do _gtools_internal.mata
