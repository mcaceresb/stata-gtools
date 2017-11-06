#include "xtile.c"

ST_retcode sf_xtile    (struct StataInfo *st_info, int level);
GT_size gf_xtile_clean (ST_double *x, GT_size lsize, GT_bool dropmiss, GT_bool dedup);

ST_retcode sf_xtile (struct StataInfo *st_info, int level)
{

    ST_double z, nqdbl, *xptr, *qptr, *optr, *gptr, qdbl, qdiff, xmin, xmax, Ndbl;
    GT_bool failmiss;
    GT_size i, q, sel, obs, N, qtot;
    ST_retcode rc = 0;
    clock_t  timer = clock();
    clock_t stimer = clock();

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    // GT_bool method   = st_info->method;
    // method = 0; // expected optimal
    // method = 1; // qsort, current
    // method = 2; // qselect

    GT_size nq      = st_info->xtile_nq;
    GT_size nq2     = st_info->xtile_nq2;
    GT_size ncuts   = st_info->xtile_ncuts;
    GT_size cutvars = st_info->xtile_cutvars;
    GT_size qvars   = st_info->xtile_qvars;
    GT_size npoints = 0;
    GT_size nquants = 0;

    GT_size kgen    = st_info->xtile_gen;
    GT_bool pctile  = st_info->xtile_pctile;
    GT_bool genpct  = st_info->xtile_genpct;
    GT_bool pctpct  = st_info->xtile_pctpct;
    GT_size kpctile = pctile + pctpct + genpct;
    GT_size xstart  = kgen + kpctile;

    GT_bool altdef   = st_info->xtile_altdef;
    GT_bool minmax   = st_info->xtile_minmax;
    GT_bool bincount = st_info->xtile_bincount;
    GT_bool _pctile  = st_info->xtile__pctile;

    GT_size kvars          = st_info->kvars_by;
    GT_size ksources       = st_info->kvars_sources;
    GT_size ktargets       = st_info->kvars_targets;
    GT_size start_sources  = kvars + st_info->kvars_group + 1;
    GT_size start_targets  = start_sources + ksources;
    GT_size start_xtile    = start_targets + ktargets;
    GT_size start_genpct   = start_xtile   + kgen + pctile + pctpct;
    GT_size start_cutvars  = start_xtile   + xstart;
    GT_size start_qvars    = start_cutvars + cutvars;
    GT_size start_xsources = start_qvars   + qvars;

    GT_size in1   = st_info->in1;
    GT_size Nread = st_info->Nread;

    GT_size nout;
    nout = GTOOLS_PWMAX(nq,   (nq2 + 1));
    nout = GTOOLS_PWMAX(nout, (ncuts + 1));
    nout = GTOOLS_PWMAX(nout, 1);

    /*********************************************************************
     *                         Memory Allocation                         *
     *********************************************************************/

    GT_size kx = kgen? 3: 1;
    GT_size xmem_sources = kx * Nread;
    GT_size xmem_quant   = nout;
    GT_size xmem_points  = cutvars? SF_nobs() + 1: 1;
    GT_size xmem_quants  = qvars? SF_nobs() + 1: 1;
    GT_size xmem_count   = (pctpct | bincount)? ((cutvars | qvars)? SF_nobs() + 1: nout): 1;
    GT_size xmem_output  = kgen? Nread: 1;

    ST_double *xsources = calloc(xmem_sources, sizeof *xsources);
    ST_double *xquant   = calloc(xmem_quant,   sizeof *xquant);
    ST_double *xpoints  = calloc(xmem_points,  sizeof *xpoints);
    ST_double *xquants  = calloc(xmem_quants,  sizeof *xquants);
    GT_size   *xcount   = calloc(xmem_count,   sizeof *xcount);
    ST_double *xoutput  = calloc(xmem_output,  sizeof *xoutput);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles", "xsources"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles", "xquant"));
    if ( xpoints  == NULL ) return(sf_oom_error("sf_quantiles", "xpoints"));
    if ( xquants  == NULL ) return(sf_oom_error("sf_quantiles", "xquants"));
    if ( xcount   == NULL ) return(sf_oom_error("sf_quantiles", "xcount"));
    if ( xoutput  == NULL ) return(sf_oom_error("sf_quantiles", "xoutput"));

    /*********************************************************************
     *                   Read in the source variables                    *
     *********************************************************************/

    for (i = 0; i < xmem_count; i++)
        xcount[i] = 0;

    // TODO: Benchmark vs 16 special cases // 2017-11-04 13:44 EDT
    // NOTE: Very similar; need more info // 2017-11-04 13:44 EDT
    obs = 0;
    if ( st_info->any_if ) {
        for (i = 0; i < Nread; i++) {
            if ( SF_ifobs(i + in1) ) {
                if ( (rc = SF_vdata(start_xsources,
                                    i + in1,
                                    &z)) ) goto exit;
                if ( SF_is_missing(z) ) continue;
                sel = kx * obs++;
                xsources[sel] = z;
                if ( kx > 1 ) {
                    xsources[sel + 1] = i;
                    if ( kx > 2 ) {
                        xsources[sel + 2] = obs - 1;
                    }
                }
            }
        }
    }
    else {
        for (i = 0; i < Nread; i++) {
            if ( (rc = SF_vdata(start_xsources,
                                i + in1,
                                &z)) ) goto exit;
            if ( SF_is_missing(z) ) continue;
            sel = kx * obs++;
            xsources[sel] = z;
            if ( kx > 1 ) {
                xsources[sel + 1] = i;
                if ( kx > 2 ) {
                    xsources[sel + 2] = obs - 1;
                }
            }
        }
    }
    N = obs;

    if ( cutvars ) {
        for (i = 0; i < SF_nobs(); i++) {
            if ( (rc = SF_vdata(start_cutvars,
                                i + 1,
                                xpoints + i)) ) goto exit;
        }
        npoints = SF_nobs();
    }

    if ( qvars ) {
        for (i = 0; i < SF_nobs(); i++) {
            if ( (rc = SF_vdata(start_qvars,
                                i + 1,
                                xquants + i)) ) goto exit;
        }
        nquants = SF_nobs();
    }

    if ( N == 0 ) {
        sf_errprintf("no observations\n");
        rc = 17001;
        goto exit;
    }
    Ndbl = (ST_double) N;

    // This limitation seems to have been misunderstood by fastxtile.  It seem
    // that it exists because the number of rows in the data is the limit to
    // how many quantiles Stata can save via pctile, not because you cannot
    // compute percentiles when # non-missing > # quantiles.

    if ( nq > (N + 1) ) {
        if ( st_info->xtile_strict ) {
            sf_errprintf("nquantiles() must be less than or equal to # non-missing ["GT_size_cfmt"] plus one\n", N);
            rc = 198;
            goto exit;
        }
    }

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\txtile step 1: Read in source variable");

    stimer = clock();

    /*********************************************************************
     *           Adjust percentiles or curoffs, if applicable            *
     *********************************************************************/

    failmiss = (ncuts > 0) | (npoints > 0) | (nquants > 0);
    nq2      = (nq2     == 0)? 0: gf_xtile_clean(st_info->xtile_quantiles, nq2,   1, st_info->xtile_dedup);
    ncuts    = (ncuts   == 0)? 0: gf_xtile_clean(st_info->xtile_cutoffs,   ncuts, 1, st_info->xtile_dedup);
    npoints  = (npoints == 0)? 0: gf_xtile_clean(xpoints, npoints, 1, st_info->xtile_dedup);
    nquants  = (nquants == 0)? 0: gf_xtile_clean(xquants, nquants, 1, st_info->xtile_dedup);

    if ( failmiss & (ncuts == 0) & (npoints == 0) & (nquants == 0) ) {
        if ( (ncuts == 0) & (npoints == 0) ) {
            sf_errprintf("all cutoff values are missing\n");
            rc = 198;
            goto exit;
        }
        else if ( nquants == 0 ) {
            sf_errprintf("all quantile values are missing\n");
            rc = 198;
            goto exit;
        }
    }

    if ( nquants > 0 ) {
        for (gptr = xquants; gptr < xquants + nquants; gptr += 1) {
            if ( (*gptr <= 0) || (*gptr >= 100) ) {
                sf_errprintf("cutquantiles() requires a variable with values strictly between 0 and 100\n");
                rc = 198;
                goto exit;
            }
        }
    }

    if ( st_info->benchmark ) {
        if ( (ncuts > 0) || (npoints > 0) ) {
            sf_running_timer (&timer, "\txtile step 2: De-duplicated cutoff list");
        }
        else if ( (nq2 > 0) || (nquants > 0) ) {
            sf_running_timer (&timer, "\txtile step 2: De-duplicated quantile list");
        }
    }
    stimer = clock();

    /*********************************************************************
     *                               Sort!                               *
     *********************************************************************/

    // TODO: Optimize to be straight up selection if nq is small // 2017-11-04 14:14 EDT
    // That is, if I do
    //     for (i = 0; i < N; i++, xptr += kx) {
    //         q = 0;
    //         while ( xptr[0] > qptr[q] ) q++;
    //         xcount[q]++;
    //         xptr[0] = q + 1;
    //     }
    // Without sorting, after a selection.

    // Check if already sorted
    xptr = xsources;
    for (i = 0; i < (N - 1); i++, xptr += kx) {
        if ( *xptr > *(xptr + kx) ) break;
    }

    // Sort if not sorted
    if ( i < N ) {
        quicksort_bsd (
            xsources,
            N,
            kx * sizeof(xsources),
            xtileCompare,
            NULL
        );
    }

    // Grab min and max from sorted list
    xmin = xsources[0];
    xmax = xsources[kx * N - kx];

    /*********************************************************************
     *      Turn quantiles into cutoffs (or point qptr to cutoffs)       *
     *********************************************************************/

    if ( genpct ) {
        if ( nquants > 0 ) {
            for (i = 0; i < nquants; i++) {
                if ( (rc = SF_vstore(start_genpct, i + 1, xquants[i]) )) goto exit;
            }
        }
        else if ( nq2 > 0 ) {
            for (i = 0; i < nq2; i++) {
                if ( (rc = SF_vstore(start_genpct, i + 1, st_info->xtile_quantiles[i]) )) goto exit;
            }
        }
        else if ( nq > 0 ) {
            nqdbl = (ST_double) nq;
            for (i = 0; i < (nq - 1); i++) {
                if ( (rc = SF_vstore(start_genpct, i + 1, (100 * (i + 1) / nqdbl)) )) goto exit;
            }
        }
    }

    qptr = NULL;
    if ( ncuts > 0 ) {
        qptr = st_info->xtile_cutoffs;
        qptr[ncuts] = xsources[kx * N - kx];
    }
    else if ( npoints > 0 ) {
        qptr = xpoints;
        qptr[npoints] = xsources[kx * N - kx];
    }
    else if ( altdef ) {
        if ( nquants > 0 ) {
            for (i = 0; i < nquants; i++) {
                q  = floor(qdbl = (xquants[i] * ((Ndbl + 1) / 100)));
                if ( q > 0 ) {
                    if ( q < N ) {
                        q--;
                        xquants[i] = xsources[kx * q];
                        if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                            xquants[i] *= (1 - qdiff);
                            xquants[i] += qdiff * xsources[kx * q + kx];
                        }
                    }
                    else {
                        xquants[i] = xsources[kx * N - kx];
                    }
                }
                else {
                    xquants[i] = xsources[0];
                }
            }
            xquants[nquants] = xsources[kx * N - kx];
            qptr = xquants;
        }
        else if ( nq2 > 0 ) {
            for (i = 0; i < nq2; i++) {
                q  = floor(qdbl = (st_info->xtile_quantiles[i] * ((Ndbl + 1) / 100)));
                if ( q > 0 ) {
                    if ( q < N ) {
                        q--;
                        xquant[i] = xsources[kx * q];
                        if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                            xquant[i] *= (1 - qdiff);
                            xquant[i] += qdiff * xsources[kx * q + kx];
                        }
                    }
                    else {
                        xquant[i] = xsources[kx * N - kx];
                    }
                }
                else {
                    xquant[i] = xsources[0];
                }
            }
            xquant[nq2] = xsources[kx * N - kx];
            qptr = xquant;
        }
        else if ( nq > 0 ) {
            nqdbl = (ST_double) nq;
            for (i = 0; i < (nq - 1); i++) {
                q = floor(qdbl = ((i + 1) * (Ndbl + 1) / nqdbl));
                if ( q > 0 ) {
                    if ( q < N ) {
                        q--;
                        xquant[i] = xsources[kx * q];
                        if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                            xquant[i] *= (1 - qdiff);
                            xquant[i] += qdiff * xsources[kx * q + kx];
                        }
                    }
                    else {
                        xquant[i] = xsources[kx * N - kx];
                    }
                }
                else {
                    xquant[i] = xsources[0];
                }
            }
            xquant[nq - 1] = xsources[kx * N - kx];
            qptr = xquant;
        }
    }
    else {
        if ( nquants > 0 ) {
            for (i = 0; i < nquants; i++) {
                q = ceil(qdbl = (xquants[i] * (Ndbl / 100)) - 1);
                xquants[i] = xsources[kx * q];
                if ( (ST_double) q == qdbl ) {
                    xquants[i] += xsources[kx * q + kx];
                    xquants[i] /= 2;
                }
            }
            xquants[nquants] = xsources[kx * N - kx];
            qptr = xquants;
        }
        else if ( nq2 > 0 ) {
            for (i = 0; i < nq2; i++) {
                q = ceil(qdbl = st_info->xtile_quantiles[i] * (Ndbl / 100) - 1);
                xquant[i] = xsources[kx * q];
                if ( (ST_double) q == qdbl ) {
                    xquant[i] += xsources[kx * q + kx];
                    xquant[i] /= 2;
                }
            }
            xquant[nq2] = xsources[kx * N - kx];
            qptr = xquant;
        }
        else if ( nq > 0 ) {
            nqdbl = (ST_double) nq;
            for (i = 0; i < (nq - 1); i++) {
                q = ceil(qdbl = ((i + 1) * Ndbl / nqdbl) - 1);
                xquant[i] = xsources[kx * q];
                if ( (ST_double) q == qdbl ) {
                    xquant[i] += xsources[kx * q + kx];
                    xquant[i] /= 2;
                }
            }
            xquant[nq - 1] = xsources[kx * N - kx];
            qptr = xquant;
        }
    }

    if ( st_info->benchmark ) {
        if ( (nq2 > 0) | (nq > 0) ) {
            sf_running_timer (&timer, "\txtile step 3: Sorted source and computed quantiles");
        }
        else {
            sf_running_timer (&timer, "\txtile step 3: Sorted source variable");
        }
    }
    stimer = clock();

    /*********************************************************************
     *    Compute xtile, if requested; else just count bin frequency     *
     *********************************************************************/

    q = 0;
    if ( kgen ) {
        if ( bincount | pctpct ) {
            for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                while ( *xptr > qptr[q] ) q++;
                xcount[q]++;
                xptr[0] = q + 1;
            }
        }
        else {
            for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                while ( *xptr > qptr[q] ) q++;
                xptr[0] = q + 1;
            }
        }

        if ( st_info->benchmark )
            sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile");

        // It is faster, though it uses more memory, to re-arrange the output
        // in memory and then copy to stata sequentially

        for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
            xoutput[(GT_size) *(xptr + kx - 1)] = *xptr;
        }

        if ( N < Nread ) {
            for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                xsources[kx * ((GT_size) *(xptr + kx - 1))] = *(xptr + 1);
            }
        }

        if ( st_info->benchmark )
            sf_running_timer (&stimer, "\t\txtile step 4.2: Arranged xtile in memory");

        optr = xoutput;
        xptr = xsources;
        if ( N < Nread ) {
            for (optr = xoutput; optr < xoutput + N; optr += 1, xptr += kx) {
                if ( (rc = SF_vstore(start_xtile, ((GT_size) *xptr) + in1, *optr)) ) goto exit;
            }
        }
        else {
            for (i = 0; i < N; i++, optr += 1) {
                if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
            }
        }

        if ( st_info->benchmark )
            sf_running_timer (&stimer, "\t\txtile step 4.3: Copied xtile to Stata sequentially");

        if ( st_info->benchmark )
            sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");
    }
    else if ( pctpct | bincount ) {
        for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
            while ( *xptr > qptr[q] ) q++;
            xcount[q]++;
        }
    }

    /*********************************************************************
     *         Return percentiles and frequencies, if requested          *
     *********************************************************************/

    // qtot = q + 1;
    qtot = GTOOLS_PWMAX((nout - 1), npoints);
    qtot = GTOOLS_PWMAX(qtot, nquants);
    qtot = GTOOLS_PWMIN(qtot, SF_nobs());

    if ( pctile ) {
        if ( pctpct ) {
            for (q = 0; q < qtot; q++) {
                if ( (rc = SF_vstore(start_xtile + kgen,     q + 1, qptr[q])) ) goto exit;
                if ( (rc = SF_vstore(start_xtile + kgen + 1, q + 1, xcount[q])) ) goto exit;
            }
        }
        else {
            for (q = 0; q < qtot; q++) {
                if ( (rc = SF_vstore(start_xtile + kgen, q + 1, qptr[q])) ) goto exit;
            }
        }
    }
    else if ( pctpct ) {
        for (q = 0; q < qtot; q++) {
            if ( (rc = SF_vstore(start_xtile + kgen, q + 1, xcount[q])) ) goto exit;
        }
    }

    if ( ncuts > 0 ) {
        if ( bincount ) {
            for (q = 0; q < ncuts; q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_cutoffs", 1, q + 1, qptr[q])   )) goto exit;
                if ( (rc = SF_mat_store("__gtools_xtile_cutbin",  1, q + 1, xcount[q]) )) goto exit;
            }
        }
        else {
            for (q = 0; q < ncuts; q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_cutoffs", 1, q + 1, qptr[q]) )) goto exit;
            }
        }
    }

    if ( nq2 > 0 ) {
        if ( bincount ) {
            for (q = 0; q < nq2; q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
                if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, xcount[q]) )) goto exit;
            }
        }
        else {
            for (q = 0; q < nq2; q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q]) )) goto exit;
            }
        }
    }
    else if ( (nq > 0) & bincount & (pctpct == 0) ) {
        if ( _pctile ) {
            for (q = 0; q < (nq - 1); q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
                if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, xcount[q]) )) goto exit;
            }
        }
        else {
            for (q = 0; q < (nq - 1); q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, xcount[q]) )) goto exit;
            }
        }
    }
    else if ( (nq > 0) & _pctile ) {
        for (q = 0; q < (nq - 1); q++) {
            if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
        }
    }

    if ( (rc = SF_scal_save ("__gtools_xtile_nq",      (ST_double) nq       )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_nq2",     (ST_double) nq2      )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_cutvars", (ST_double) npoints  )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_ncuts",   (ST_double) ncuts    )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_qvars",   (ST_double) nquants  )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_xvars",   (ST_double) N        )) ) goto exit;

    if ( minmax ) {
        if ( (rc = SF_scal_save ("__gtools_xtile_min", xmin )) ) goto exit;
        if ( (rc = SF_scal_save ("__gtools_xtile_max", xmax )) ) goto exit;
    }

    if ( st_info->benchmark ) {
        if ( kgen ) {
            if ( pctile | (nq2 > 0) ) {
                sf_running_timer (&timer, "\txtile step 5: Copied quantiles to Stata");
            }
            else if ( pctpct | (ncuts > 0) ) {
                sf_running_timer (&timer, "\txtile step 5: Copied bin counts to Stata");
            }
        }
        else if ( pctile | (nq2 > 0) ) {
            sf_running_timer (&timer, "\txtile step 4: Copied quantiles to Stata");
        }
        else if ( pctpct | (ncuts > 0) ) {
            sf_running_timer (&timer, "\txtile step 4: Copied bin counts to Stata");
        }
    }

exit:
    free (xsources);
    free (xquant);
    free (xpoints);
    free (xquants);
    free (xcount);

    return (rc);
}


GT_size gf_xtile_clean (ST_double *x, GT_size lsize, GT_bool dropmiss, GT_bool dedup)
{
    GT_size i, _lsize;
    GT_bool sortme, dedupcheck;

    if ( lsize > 1 ) {
        _lsize = lsize;
        sortme = 0;

        for (i = 1; i < lsize; i++) {
            if ( x[i] < x[i - 1] ) {
                sortme = 1;
                break;
            }
            else if ( x[i] == x[i - 1] ) {
                dedupcheck = 1;
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
            dedupcheck = 1;
            sortme     = 0;
        }

        if ( dedup & dedupcheck ) {
            _lsize = 0;
            if ( dropmiss ) {
                if ( SF_is_missing(x[0]) ) return (0);
                for (i = 1; i < lsize; i++) {
                    if ( SF_is_missing(x[i]) ) break;
                    else if ( x[_lsize] == x[i] ) continue;
                    x[++_lsize] = x[i];
                }
            }
            else {
                for (i = 1; i < lsize; i++) {
                    if ( x[_lsize] == x[i] ) continue;
                    x[++_lsize] = x[i];
                }
            }
            _lsize++;
        }
        else if ( dropmiss ) {
            for (i = 0; i < lsize; i++) {
                if ( SF_is_missing(x[i]) ) return (i);
            }
        }

        return (_lsize);
    }
    else if ( (lsize == 1) & dropmiss ) {
        if ( SF_is_missing(x[0]) ) return (0);
        return (lsize);
    }
    else {
        return (lsize);
    }
}

// A. with gen
//     1. Read cutvars
//         1.1 if
//             1.1.1 missing
//                 index + stata index
//             1.1.2 no missing
//                 index + stata index
//         1.2 no if
//             1.2.1 missing
//                 index
//             1.2.2 no missing
//                 index + stata index
//     2. no cutvars
//         2.1 if
//             2.1.1 missing
//                 index + stata index
//             2.1.2 no missing
//                 index + stata index
//         2.2 no if
//             2.2.1 missing
//                 index
//             2.2.2 no missing
//                 index + stata index
// B. no gen
//     1. read cutvars
//         1.1 if
//             1.1.1 missing
//             1.1.2 no missing
//         1.2 no if
//             1.2.1 missing
//             1.2.2 no missing
//     2. no cutvars
//         2.1 if
//             2.1.1 missing
//             2.1.2 no missing
//         2.2 no if
//             2.2.1 missing
//             2.2.2 no missing

// if ( kgen ) {                     // A. With gen
//     if ( cutvars ) {              // 1. Read cutvars
//         npoints = Nread;
//         if ( st_info->any_if ) {  // 1.1 if
//             obs = 0;
//             if ( missing ) {      // 1.1.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         sel = kx * obs++;
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + sel)) ) goto exit;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//             }
//             else {                // 1.1.2 no missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             sel = kx * obs++;
//                             xsources[sel] = z;
//                             xsources[sel + 1] = i;
//                             xsources[sel + 2] = obs - 1;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {                    // 1.2 no if
//             if ( missing ) {      // 1.2.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + kx * i)) ) goto exit;
//                     xsources[kx * i + 1] = i;
//                 }
//                 N = Nread;
//             }
//             else {                // 1.2.2 no missing
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         sel = kx * obs++;
//                         xsources[sel] = z;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
//     else {                        // 2. no cutvars
//         if ( st_info->any_if ) {  // 2.1 if
//             obs = 0;
//             if ( missing ) {      // 2.1.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         sel = kx * obs++;
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + sel)) ) goto exit;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//             }
//             else {                // 2.1.2 no missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             sel = kx * obs++;
//                             xsources[sel] = z;
//                             xsources[sel + 1] = i;
//                             xsources[sel + 2] = obs - 1;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {                    // 2.2 no if
//             if ( missing ) {      // 2.2.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + kx * i)) ) goto exit;
//                     xsources[kx * i + 1] = i;
//                 }
//                 N = Nread;
//             }
//             else {                // 2.2.2 no missing
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         sel = kx * obs++;
//                         xsources[sel] = z;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
// }
// else {
//     if ( cutvars ) {
//         npoints = Nread;
//         if ( st_info->any_if ) {
//             obs = 0;
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + obs++)) ) goto exit;
//                     }
//                 }
//             }
//             else {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             xsources[obs++] = z;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + i)) ) goto exit;
//                 }
//                 N = Nread;
//             }
//             else {
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         xsources[obs++] = z;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
//     else {
//         if ( st_info->any_if ) {
//             obs = 0;
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + obs++)) ) goto exit;
//                     }
//                 }
//             }
//             else {
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             xsources[obs++] = z;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + i)) ) goto exit;
//                 }
//                 N = Nread;
//             }
//             else {
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         xsources[obs++] = z;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
// }
