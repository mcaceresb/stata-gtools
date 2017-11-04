#include "xtile.c"

ST_retcode sf_xtile    (struct StataInfo *st_info, int level);
GT_size sf_xtile_dedup (ST_double *x, GT_size lsize, GT_bool dropmiss);

ST_retcode sf_xtile (struct StataInfo *st_info, int level)
{
    ST_double z, nqdbl, *xptr, *qptr, qdbl;
    GT_bool failmiss;
    GT_size i, l, q, sel, obs, N;
    ST_retcode rc = 0;
    clock_t timer = clock();

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    GT_size nq      = st_info->xtile_nq;
    GT_size nq2     = st_info->xtile_nq2;
    GT_size ncuts   = st_info->xtile_ncuts;
    GT_size cutvars = st_info->xtile_cutvars;
    GT_size npoints = 0;

    GT_size kgen    = st_info->xtile_gen;
    GT_bool pctile  = st_info->xtile_pctile;
    GT_bool pctpct  = st_info->xtile_pctpct;
    GT_size kpctile = pctile + pctpct;

    // GT_bool altdef  = st_info->xtile_altdef;
    GT_bool missing = st_info->xtile_missing;

    GT_size xvars   = st_info->xtile_xvars;
    GT_size xstart  = kgen + kpctile;

    GT_size kvars          = st_info->kvars_by;
    GT_size ksources       = st_info->kvars_sources;
    GT_size ktargets       = st_info->kvars_targets;
    GT_size start_sources  = kvars + st_info->kvars_group + 1;
    GT_size start_targets  = start_sources + ksources;
    GT_size start_xtile    = start_targets + ktargets;
    GT_size start_cutvars  = start_xtile   + xstart;
    GT_size start_xsources = start_cutvars + cutvars;

    GT_size in1   = st_info->in1;
    GT_size Nread = st_info->Nread;

    GT_size nout;
    nout  = GTOOLS_PWMAX(nq,     nq2);
    nout  = GTOOLS_PWMAX(nout,   ncuts);
    nout  = GTOOLS_PWMAX(nout,   1);
    nout += 1;

    /*********************************************************************
     *                         Memory Allocation                         *
     *********************************************************************/

    ST_double *xsources = calloc(2 * Nread,         sizeof *xsources);
    ST_double *xquant   = calloc(nout,              sizeof *xquant);
    ST_double *xpoints  = calloc(cutvars? Nread: 1, sizeof *xsources);
    GT_size   *xcount   = calloc(pctpct? nout: 1,   sizeof *xcount);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles", "xsources"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles", "xquant"));
    if ( xpoints  == NULL ) return(sf_oom_error("sf_quantiles", "xpoints"));
    if ( xcount   == NULL ) return(sf_oom_error("sf_quantiles", "xcount"));

    /*********************************************************************
     *                   Read in the source variables                    *
     *********************************************************************/

    if ( pctpct ) {
        for (i = 0; i < nout; i++)
            xcount[i] = 0;
    }
    else {
        xcount[0] = 0;
    }

    if ( cutvars ) {
        npoints = Nread;
        if ( st_info->any_if ) {
            obs = 0;
            if ( missing ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_cutvars,
                                        i + in1,
                                        xpoints + i)) ) goto exit;
                    if ( SF_ifobs(i + in1) ) {
                        sel = 2 * obs++;
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            xsources + sel)) ) goto exit;
                        xsources[sel + xvars] = i;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_cutvars,
                                        i + in1,
                                        xpoints + i)) ) goto exit;
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto exit;
                        if ( !SF_is_missing(z) ) {
                            sel = 2 * obs++;
                            xsources[sel] = z;
                            xsources[sel + xvars] = i;
                        }
                    }
                }
            }
            N = obs;
        }
        else {
            if ( missing ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_cutvars,
                                        i + in1,
                                        xpoints + i)) ) goto exit;
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        xsources + 2 * i)) ) goto exit;
                    xsources[2 * i + xvars] = i;
                }
                N = Nread;
            }
            else {
                obs = 0;
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_cutvars,
                                        i + in1,
                                        xpoints + i)) ) goto exit;
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto exit;
                    if ( !SF_is_missing(z) ) {
                        sel = 2 * obs++;
                        xsources[sel] = z;
                        xsources[sel + xvars] = i;
                    }
                }
                N = obs;
            }
        }
    }
    else {
        if ( st_info->any_if ) {
            obs = 0;
            if ( missing ) {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        sel = 2 * obs++;
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            xsources + sel)) ) goto exit;
                        xsources[sel + xvars] = i;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto exit;
                        if ( !SF_is_missing(z) ) {
                            sel = 2 * obs++;
                            xsources[sel] = z;
                            xsources[sel + xvars] = i;
                        }
                    }
                }
            }
            N = obs;
        }
        else {
            if ( missing ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        xsources + 2 * i)) ) goto exit;
                    xsources[2 * i + xvars] = i;
                }
                N = Nread;
            }
            else {
                obs = 0;
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto exit;
                    if ( !SF_is_missing(z) ) {
                        sel = 2 * obs++;
                        xsources[sel] = z;
                        xsources[sel + xvars] = i;
                    }
                }
                N = obs;
            }
        }
    }

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\txtile step 1: Read in source variable");

    /*********************************************************************
     *           Adjust percentiles or curoffs, if applicable            *
     *********************************************************************/

    failmiss = (!missing) & ( (ncuts > 0) | (npoints > 0) );
    nq2      = (nq2     == 0)? 0: sf_xtile_dedup(st_info->xtile_quantiles, nq2,   0);
    ncuts    = (ncuts   == 0)? 0: sf_xtile_dedup(st_info->xtile_cutoffs,   ncuts, !missing);
    npoints  = (npoints == 0)? 0: sf_xtile_dedup(xpoints, npoints, !missing);

    if ( failmiss & (ncuts == 0) & (npoints == 0) ) {
        sf_errprintf("(all cutoff values are missing)\n");
        rc = 198;
        goto exit;
    }

    if ( st_info->benchmark ) {
        if ( (ncuts > 0) || (npoints > 0) ) {
            sf_running_timer (&timer, "\txtile step 2: De-duplicated cutoff list");
        }
        else if ( nq2 > 0 ) {
            sf_running_timer (&timer, "\txtile step 2: De-duplicated quantile list");
        }
    }

    xptr = xsources;
    quicksort_bsd (
        xptr,
        N,
        2 * sizeof(xsources),
        xtileCompare,
        NULL
    );

    qptr = xquant;
    if ( ncuts > 0 ) {
        qptr = st_info->xtile_cutoffs;
        qptr[ncuts] = xptr[2 * N - 2];
    }
    else if ( cutvars > 0 ) {
        qptr = xpoints;
        qptr[npoints] = xptr[2 * N - 2];
    }
    else if ( nq2 > 0 ) {
        for (i = 0; i < nq2; i++) {
            q = ceil(qdbl = (st_info->xtile_quantiles[i] * N / 100) - 1);
            xquant[i] = xptr[2 * q];
            if ( (ST_double) q == qdbl ) {
                xquant[i] += xptr[2 * q + 2];
                xquant[i] /= 2;
            }
        }
        xquant[nq2] = xptr[2 * N - 2];
        qptr = xquant;
    }
    else if ( nq > 0 ) {
        nqdbl = (ST_double) nq;
        for (i = 0; i < (nq - 1); i++) {
            q = ceil(qdbl = ((i + 1) * N / nqdbl) - 1);
            xquant[i] = xptr[2 * q];
            if ( (ST_double) q == qdbl ) {
                xquant[i] += xptr[2 * q + 2];
                xquant[i] /= 2;
            }
        }
        xquant[nq - 1] = xptr[2 * N - 2];
        qptr = xquant;
    }

    if ( st_info->benchmark ) {
        if ( (nq2 > 0) | (nq > 0) ) {
            sf_running_timer (&timer, "\txtile step 3: Computed quantiles");
        }
        else {
            sf_running_timer (&timer, "\txtile step 3: Sorted source variable");
        }
    }

    q = 0;
    if ( kgen ) {
        if ( pctpct ) {
            for (i = 0; i < N; i++, xptr += 2) {
                while ( xptr[0] > qptr[q] ) q++;
                xcount[q]++;
                l = (GT_size) xptr[1];
                if ( (rc = SF_vstore(start_xtile, l + in1, q + 1)) ) goto exit;
            }
        }
        else {
            for (i = 0; i < N; i++, xptr += 2) {
                while ( xptr[0] > qptr[q] ) q++;
                // xptr[0] = q + 1;
                l = (GT_size) xptr[1];
                if ( (rc = SF_vstore(start_xtile, l + in1, q + 1)) ) goto exit;
            }
        }

        // xptr = xsources;
        // quicksort_bsd (
        //     xsources,
        //     N,
        //     2 * sizeof(xsources),
        //     xtileCompareIndex,
        //     NULL
        // );
        //
        // if ( st_info->benchmark ) {
        //     sf_running_timer (&timer, "\txtile step 4.1: Computed xtile");
        // }
        //
        // for (i = 0; i < N; i++, xptr += 2) {
        //     l = (GT_size) xptr[1];
        //     if ( (rc = SF_vstore(start_xtile, l + in1, xptr[0])) ) goto exit;
        // }
        //
        // if ( st_info->benchmark ) {
        //     sf_running_timer (&timer, "\txtile step 4.2: Copied to Stata");
        // }
    }
    else if ( pctpct ) {
        for (i = 0; i < N; i++, xptr += 2) {
            while ( xptr[0] > qptr[q] ) q++;
            xcount[q]++;
        }
    }

    q++;
    if ( pctile ) {
        if ( pctpct ) {
            for (i = 0; i < q; i++) {
                if ( (rc = SF_vstore(start_xtile + kgen, i + in1, qptr[q])) ) goto exit;
                if ( (rc = SF_vstore(start_xtile + kgen + 1, i + in1, xcount[q])) ) goto exit;
            }
        }
        else {
            for (i = 0; i < q; i++) {
                if ( (rc = SF_vstore(start_xtile + kgen, i + in1, qptr[q])) ) goto exit;
            }
        }
    }
    else if ( pctpct ) {
        for (i = 0; i < q; i++) {
            if ( (rc = SF_vstore(start_xtile + kgen, i + in1, xcount[q])) ) goto exit;
        }
    }

    if ( nq2 > 0 ) {
        for (q = 0; q < nq2; q++) {
            if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, xquant[q])) ) goto exit;
        }
    }

    if ( st_info->benchmark ) {
        if ( kgen & (pctile | pctpct | (nq2 > 0)) ) {
            sf_running_timer (&timer, "\txtile step 5: Copied quantiles to Stata");
        }
        else if ( pctile | pctpct | (nq2 > 0) ) {
            sf_running_timer (&timer, "\txtile step 4: Copied quantiles to Stata");
        }
    }

exit:
    free (xsources);
    free (xquant);
    free (xpoints);
    free (xcount);

    return (rc);
}


GT_size sf_xtile_dedup (ST_double *x, GT_size lsize, GT_bool dropmiss)
{
    GT_size i, _lsize;
    GT_bool sortme;

    if ( lsize > 1 ) {
        sortme = 0;
        for (i = 1; i < lsize; i++) {
            if ( x[i] <= x[i - 1] ) {
                sortme = 1;
                break;
            }
        }

        if ( sortme ) {
            quicksort_bsd (
                x,
                lsize,
                sizeof(x),
                xtileCompare,
                NULL
            );

            _lsize = 1;
            if ( dropmiss ) {
                if ( SF_is_missing(x[0]) ) return (0);
                for (i = 1; i < lsize; i++) {
                    if ( SF_is_missing(x[i]) ) break;
                    else if ( x[_lsize] == x[i] ) continue;
                    x[_lsize++] = x[i];
                }
            }
            else {
                for (i = 1; i < lsize; i++) {
                    if ( x[_lsize] == x[i] ) continue;
                    x[_lsize++] = x[i];
                }
            }

            return (_lsize);
        }
        else if ( dropmiss ) {
            _lsize = 1;
            if ( SF_is_missing(x[0]) ) return (0);
            for (i = 1; i < lsize; i++) {
                if ( SF_is_missing(x[i]) ) break;
                x[_lsize++] = x[i];
            }
            return (_lsize);
        }
        else {
            return (lsize);
        }
    }
    else if ( dropmiss ) {
        if ( SF_is_missing(x[0]) ) return (0);
        return (lsize);
    }
    else {
        return (lsize);
    }
}
