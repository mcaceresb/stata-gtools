cap mata: mata drop GtoolsReadMatrix()
cap mata: mata drop GtoolsResults()
cap mata: mata drop GtoolsDecodeStat()
cap mata: mata drop GtoolsDecodePth()
cap mata: mata drop GtoolsSmartLevels()
cap mata: mata drop GtoolsPrintfSwitch()

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
    real colvector j,
    real scalar l)
{
    real scalar ix
    if ( anyvars == 0 | kby == 0 ) {
        errprintf("no by variables stored\n")
        return(.);
    }
    else {
        if ( l > knum ) {
            errprintf("requested %gth nuemric variable but only found %g\n", l, knum)
            return(.)
        }
        return(numx[j, l])
    }
}

string matrix function GtoolsResults::getchar(
    real colvector j,
    real scalar l,
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
            if ( l > kchar ) {
                errprintf("requested %gth string variable but only found %g\n", l, kchar)
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

void function GtoolsResults::printOutput()
{
    string scalar vfmt, fmt, var
    real scalar nrow, j, k, l, sel, width, widthrow
    string matrix printstr
    real colvector extrasep

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
                        */ vfmt, dfmt, maxl, scodes[k], output[sel, l])
                }
            }
        }
        width    = colmax(strlen(printstr)) :+ 1
        widthrow = sum(width) + 3 + 2
        // * (kby == 0)

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
                fmt = sprintf("%%%gs", width[kby + 1 + k])
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
                        */ vfmt, dfmt, maxl, scodes[k], output[sel, k])
                }
            }
        }
        width    = colmax(strlen(printstr)) :+ 1
        widthrow = sum(width) + 3 + 2

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
                fmt = sprintf("%%%gs", width[kby + 1 + k])
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
    printf("GstatsOutput is a class object with group levels and summary statistics\n")
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
    real scalar nr, nc, or, i, j
    real rowvector printlens
    string rowvector printfmts

    nr = rows(output)
    nc = cols(output)
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
    printf("    GstatsOutput is a class object with group levels and summary statistics\n")
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

real matrix function GtoolsReadMatrix(
    string scalar fname,
    real scalar nrow,
    real scalar ncol)
{
    real scalar fh
    real matrix X
    colvector C
    fh = fopen(fname, "r")
    C = bufio()
    X = fbufget(C, fh, "%8z", nrow, ncol)
    fclose(fh)
    return (X)
}

string scalar function GtoolsDecodeStat(real scalar scode, real scalar pretty)
{
    real scalar sth
    if ( pretty ) {
        if ( scode ==  -1   )  return("Sum")                  // sum
        if ( scode ==  -2   )  return("Mean")                 // mean
        if ( scode ==  -3   )  return("St Dev.")              // sd
        if ( scode ==  -4   )  return("Max")                  // max
        if ( scode ==  -5   )  return("Min")                  // min
        if ( scode ==  -6   )  return("Count")                // n
        if ( scode ==  -7   )  return("Percent")              // percent
        if ( scode ==  50   )  return("Median")               // median
        if ( scode ==  -9   )  return("IQR")                  // iqr
        if ( scode ==  -10  )  return("First")                // first
        if ( scode ==  -11  )  return("First Non-Miss.")      // firstnm
        if ( scode ==  -12  )  return("Last")                 // last
        if ( scode ==  -13  )  return("Last Non-Miss.")       // lastnm
        if ( scode ==  -14  )  return("Group size")           // freq
        if ( scode ==  -15  )  return("SE Mean")              // semean
        if ( scode ==  -16  )  return("SE Mean (Binom)")      // sebinomial
        if ( scode ==  -17  )  return("SE Mean (Pois)")       // sepoisson
        if ( scode ==  -18  )  return("N Unique")             // nunique
        if ( scode ==  -19  )  return("Skewness")             // skewness
        if ( scode ==  -20  )  return("Kurtosis")             // kurtosis
        if ( scode ==  -21  )  return("Unweighted sum")       // rawsum
        if ( scode ==  -22  )  return("N Missing")            // nmissing
        if ( scode ==  -23  )  return("Variance")             // variance
        if ( scode ==  -24  )  return("Coef. of variation")   // cv
        if ( scode ==  -25  )  return("Range")                // range
        if ( scode ==  -101 )  return("Sum")                  // nansum
        if ( scode ==  -121 )  return("Unweighted sum")       // rawnansum
        if ( scode ==  -206 )  return("Sum Wgt.")             // sum_w
        if ( scode ==  -203 )  return("Variance")             // variance

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
        if ( scode ==  -1   ) return("sum")
        if ( scode ==  -2   ) return("mean")
        if ( scode ==  -3   ) return("sd")
        if ( scode ==  -4   ) return("max")
        if ( scode ==  -5   ) return("min")
        if ( scode ==  -6   ) return("n")
        if ( scode ==  -7   ) return("percent")
        if ( scode ==  50   ) return("median")
        if ( scode ==  -9   ) return("iqr")
        if ( scode ==  -10  ) return("first")
        if ( scode ==  -11  ) return("firstnm")
        if ( scode ==  -12  ) return("last")
        if ( scode ==  -13  ) return("lastnm")
        if ( scode ==  -14  ) return("freq")
        if ( scode ==  -15  ) return("semean")
        if ( scode ==  -16  ) return("sebinomial")
        if ( scode ==  -17  ) return("sepoisson")
        if ( scode ==  -18  ) return("nunique")
        if ( scode ==  -19  ) return("skewness")
        if ( scode ==  -20  ) return("kurtosis")
        if ( scode ==  -21  ) return("rawsum")
        if ( scode ==  -22  ) return("nmissing")
        if ( scode ==  -23  ) return("variance")
        if ( scode ==  -24  ) return("cv")
        if ( scode ==  -25  ) return("range")
        if ( scode ==  -101 ) return("nansum")
        if ( scode ==  -121 ) return("rawnansum")
        if ( scode ==  -206 ) return("sum_w")
        if ( scode ==  -203 ) return("variance")
        if ( scode > 1000 ) {
            sth = floor(scode) - 1000
            if ( floor(scode) == ceil(scode) ) {
                return(sprintf("select-%g", sth))
            }
            else {
                return(sprintf("rawselect-%g", sth))
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
    real scalar x)
{
    string scalar s
    if (scode == -6 | scode == -22 | scode == -206) {
        if (x == round(x)) {
            s = sprintf(vfmt, x)
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
