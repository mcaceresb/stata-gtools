#include "gquantiles_math.c"
#include "gquantiles_by.c"

ST_retcode sf_xtile (struct StataInfo *st_info, int level);

// ST_retcode sf_xtile_by (struct StataInfo *st_info, int level);
// ST_retcode sf_xtile_by (struct StataInfo *st_info, int level)
// {
//     return (0);
// }

ST_retcode sf_xtile (struct StataInfo *st_info, int level)
{

    ST_double z, nqdbl, xmin, xmax;
    ST_double *xptr, *qptr, *optr, *gptr, *ixptr, *xptr2;
    GT_bool failmiss = 0, sorted = 0;
    GT_size i, q, sel, obs, N, qtot;
    ST_retcode rc = 0;
    clock_t  timer = clock();
    clock_t stimer = clock();

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    GT_bool method = st_info->xtile_method;
    ST_double m1_etime, m2_etime, m_ratio;

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
    GT_size xmem_points  = cutvars? (st_info->xtile_cutifin? Nread + 1: SF_nobs() + 1): 1;
    GT_size xmem_quants  = qvars? (st_info->xtile_cutifin? Nread + 1: SF_nobs() + 1): 1;

    ST_double *xsources = calloc(xmem_sources, sizeof *xsources);
    ST_double *xquant   = calloc(xmem_quant,   sizeof *xquant);
    ST_double *xpoints  = calloc(xmem_points,  sizeof *xpoints);
    ST_double *xquants  = calloc(xmem_quants,  sizeof *xquants);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles", "xsources"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles", "xquant"));
    if ( xpoints  == NULL ) return(sf_oom_error("sf_quantiles", "xpoints"));
    if ( xquants  == NULL ) return(sf_oom_error("sf_quantiles", "xquants"));

    /*********************************************************************
     *                     Cutvars and cutquantiles                      *
     *********************************************************************/

    if ( st_info->xtile_cutifin ) {
        if ( st_info->any_if ) {
            if ( cutvars ) {
                obs = 0;
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_cutvars,
                                            i + in1,
                                            xpoints + obs++)) ) goto error;
                    }
                }
                npoints = obs;
            }

            if ( qvars ) {
                obs = 0;
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_qvars,
                                            i + in1,
                                            xquants + obs++)) ) goto error;
                    }
                }
                nquants = obs;
            }
        }
        else {
            if ( cutvars ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_cutvars,
                                        i + in1,
                                        xpoints + i)) ) goto error;
                }
                npoints = Nread;
            }

            if ( qvars ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_qvars,
                                        i + in1,
                                        xquants + i)) ) goto error;
                }
                nquants = Nread;
            }
        }
    }
    else {
        if ( cutvars ) {
            for (i = 0; i < SF_nobs(); i++) {
                if ( (rc = SF_vdata(start_cutvars,
                                    i + 1,
                                    xpoints + i)) ) goto error;
            }
            npoints = SF_nobs();
        }

        if ( qvars ) {
            for (i = 0; i < SF_nobs(); i++) {
                if ( (rc = SF_vdata(start_qvars,
                                    i + 1,
                                    xquants + i)) ) goto error;
            }
            nquants = SF_nobs();
        }
    }

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
            goto error;
        }
        else if ( nquants == 0 ) {
            sf_errprintf("all quantile values are missing\n");
            rc = 198;
            goto error;
        }
    }

    if ( nquants > 0 ) {
        for (gptr = xquants; gptr < xquants + nquants; gptr += 1) {
            if ( (*gptr <= 0) || (*gptr >= 100) ) {
                sf_errprintf("cutquantiles() requires a variable with values strictly between 0 and 100\n");
                rc = 198;
                goto error;
            }
        }
    }

    if ( nq2 > 0 ) {
        for (gptr = st_info->xtile_quantiles; gptr < st_info->xtile_quantiles + nq2; gptr += 1) {
            if ( (*gptr <= 0) || (*gptr >= 100) ) {
                sf_errprintf("quantiles() requires a numlist with values strictly between 0 and 100\n");
                rc = 198;
                goto error;
            }
        }
    }

    if ( st_info->benchmark > 1 ) {
        if ( (ncuts > 0) || (npoints > 0) ) {
            sf_running_timer (&timer, "\txtile step 1: De-duplicated cutoff list");
        }
        else if ( (nq2 > 0) || (nquants > 0) ) {
            sf_running_timer (&timer, "\txtile step 1: De-duplicated quantile list");
        }
    }
    stimer = clock();

    /*********************************************************************
     *                      Select execution method                      *
     *********************************************************************/

    nout = GTOOLS_PWMAX(nout, (npoints + 1));
    nout = GTOOLS_PWMAX(nout, (nquants + 1));

    m_ratio = m1_etime = m2_etime = 0;
    if ( (nq > 0) | (nq2 > 0) | (nquants > 0) ) {
        // Expected operations (in 'N' units):
        // - Method 1 (qsort): sort (log(N)) + 1 for xtile + 1 to rearrange + 1 counts
        // - Method 2 (qselect): # of selections + time to compute xtile + 1 counts
        if ( kgen ) {
            m1_etime = 2 * log(Nread) + 3;
            m2_etime = nout + 2;
        }
        else if ( pctpct | bincount ) {
            // No xtile
            m1_etime = log(Nread) + 2;
            m2_etime = nout + 1;
        }
        else {
            // No xtile, no counts
            m1_etime = log(Nread) + 1;
            m2_etime = nout;
        }
    }
    else if ( (ncuts > 0) | (npoints > 0) ) {
        if ( kgen ) {
            // Expected operations (in 'N' units):
            // - Method 1 (qsort): Ibid.
            // - Method 2 (qselect): No selections, but no reason to expect
            //                       cutoffs will define evenly spaced bins,
            //                       so time to count is higher; however, those
            //                       are just comparisons, not swaps!
            m1_etime = 2 * log(Nread) + 3;
            m2_etime = 0.1 * ((ST_double) nout) + 1;
        }
        else if ( pctpct | bincount ) {
            // No xtile
            m1_etime = log(Nread) + 2;
            m2_etime = 0.1 * ((ST_double) nout) + 1;
        }
        else {
            // No xtile, no counts. Here method 2 wins
            // m1_etime = log(Nread) + 1;
            // m2_etime = 0.05 * ((ST_double) nout);
            m1_etime = log(Nread) + 1;
            m2_etime = 1;
        }
    }

    if ( (m1_etime > 0) & (m1_etime > 0) ) {
        m_ratio = m1_etime / m2_etime;
    }

    if ( method == 0 ) {
        if ( m_ratio > 0 ) {
            method  = (m_ratio > 1)? 2: 1;
            if ( st_info->verbose ) {
                if ( (nq > 0) | (nq2 > 0) | (nquants > 0) ) {
                    sf_printf("E(Method 1) ~ %.2f vs E(Method 2) ~ %.2f operations. ",
                              m1_etime, m2_etime);
                }
                else if ( (ncuts > 0) | (npoints > 0) ) {
                    sf_printf("Empirical decision rule (10 * Method 1 / Method 2): %.2f. ",
                              m_ratio);
                }
                if ( m2_etime < m1_etime ) {
                    sf_printf("Will use method 2\n");
                }
                else {
                    sf_printf("Will use method 1\n");
                }
            }
        }
        else {
            method = 1;
        }
    }
    else if ( (method != 1) & (method != 2) ) {
        method = 1;
    }

    // method = 0; // expected optimal
    // method = 1; // qsort, default
    // method = 2; // qselect

    /*********************************************************************
     *                   Read in the source variables                    *
     *********************************************************************/

    // Special cases! Should be faster.

    obs   = 0;
    xptr2 = xsources;
    ixptr = xsources;
    if ( method == 2 ) {
        xptr2 = kgen? xsources + 1 * Nread: xsources;
        ixptr = kgen? xsources + 2 * Nread: xsources;
        if ( st_info->any_if ) {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        xptr2[obs] = xsources[obs] = z;
                        ixptr[obs] = i;
                        obs++;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        xsources[obs] = z;
                        obs++;
                    }
                }
            }
        }
        else {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    xptr2[obs] = xsources[obs] = z;
                    ixptr[obs] = i;
                    obs++;
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    xsources[obs] = z;
                    obs++;
                }
            }
        }
    }
    else {
        if ( st_info->any_if ) {
            if ( kgen ) { 
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        sel = kx * obs++;
                        xsources[sel] = z;
                        xsources[sel + 1] = i;
                        xsources[sel + 2] = obs - 1;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        sel = kx * obs++;
                        xsources[sel] = z;
                    }
                }
            }
        }
        else {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    sel = kx * obs++;
                    xsources[sel] = z;
                    xsources[sel + 1] = i;
                    xsources[sel + 2] = obs - 1;
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    sel = kx * obs++;
                    xsources[sel] = z;
                }
            }
        }
    }
    N = obs;

    if ( N == 0 ) {
        sf_errprintf("no observations\n");
        rc = 17001;
        goto error;
    }

    // This limitation seems to have more to do with the number of rows in the
    // data being the limit to how many quantiles Stata can save via pctile.

    if ( nq > (N + 1) ) {
        if ( st_info->xtile_strict ) {
            sf_errprintf("nquantiles() must be less than or equal to # non-missing ["
                         GT_size_cfmt"] plus one\n", N);
            rc = 198;
            goto error;
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\txtile step 2: Read in source variable");

    stimer = clock();

    /*********************************************************************
     *                         Memory allocation                         *
     *********************************************************************/

    GT_size xmem_count  = (pctpct | bincount)? nout: 1;
    GT_size xmem_output = (kgen & (method != 2))? N: 1;

    GT_size   *xcount   = calloc(xmem_count,   sizeof *xcount);
    ST_double *xoutput  = calloc(xmem_output,  sizeof *xoutput);

    if ( xcount   == NULL ) return(sf_oom_error("sf_quantiles", "xcount"));
    if ( xoutput  == NULL ) return(sf_oom_error("sf_quantiles", "xoutput"));

    for (i = 0; i < xmem_count; i++)
        xcount[i] = 0;

    /*********************************************************************
     *                               Sort!                               *
     *********************************************************************/

    if ( method == 2 ) kx = 1;

    // Check if already sorted
    i = 0;
    for (xptr = xsources;
         xptr < xsources + kx * (N - 1);
         xptr += kx, i++) {
        if ( *xptr > *(xptr + kx) ) break;
    }
    i++;

    if ( method == 2 ) {
        if ( i >= N ) {
            sorted = 2;
        }
    }
    else {
        if ( i < N ) {
            quicksort_bsd (
                xsources,
                N,
                kx * sizeof(xsources),
                xtileCompare,
                NULL
            );
            sorted = 1;
        }
        else {
            sorted = 2;
        }
    }

    /*********************************************************************
     *                         Copy pct to data                          *
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

    /*********************************************************************
     *      Turn quantiles into cutoffs (or point qptr to cutoffs)       *
     *********************************************************************/

    qptr = NULL;
    if ( ncuts > 0 ) {
        qptr = st_info->xtile_cutoffs;
        qptr[ncuts] = (method == 1)? xsources[kx * N - kx]: gf_array_dmax_range(xptr2, 0, N);
    }
    else if ( npoints > 0 ) {
        qptr = xpoints;
        qptr[npoints] = (method == 1)? xsources[kx * N - kx]: gf_array_dmax_range(xptr2, 0, N);
    }
    else if ( altdef ) {
        if ( (method == 2) & (sorted < 2) ) {
            if ( nquants > 0 ) {
                gf_quantiles_qselect_altdef (xquants, xptr2, xquants, nquants, N);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_qselect_altdef (xquant, xptr2, st_info->xtile_quantiles, nq2, N);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_qselect_altdef (xquant, xptr2, nq, N);
                qptr = xquant;
            }
        }
        else {
            if ( nquants > 0 ) {
                gf_quantiles_altdef (xquants, xsources, xquants, nquants, N, kx);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_altdef (xquant, xsources, st_info->xtile_quantiles, nq2, N, kx);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_altdef (xquant, xsources, nq, N, kx);
                qptr = xquant;
            }
        }
    }
    else {
        if ( (method == 2) & (sorted < 2) ) {
            if ( nquants > 0 ) {
                gf_quantiles_qselect (xquants, xptr2, xquants, nquants, N);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_qselect (xquant, xptr2, st_info->xtile_quantiles, nq2, N);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_qselect (xquant, xptr2, nq, N);
                qptr = xquant;
            }
        }
        else {
            if ( nquants > 0 ) {
                gf_quantiles (xquants, xsources, xquants, nquants, N, kx);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles (xquant, xsources, st_info->xtile_quantiles, nq2, N, kx);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq (xquant, xsources, nq, N, kx);
                qptr = xquant;
            }
        }
    }

    if ( method == 2 ) {
        xmin = gf_array_dmin_range(xptr2, 0, N);
        xmax = qptr[nout - 1];
    }
    else {
        xmin = xsources[0];
        xmax = qptr[nout - 1];
    }

    if ( st_info->benchmark > 1 ) {
        if ( method == 2 ) {
            if ( (nq2 > 0) | (nq > 0) | (nquants > 0) ) {
                sf_running_timer (&timer, "\txtile step 3: Computed quantiles");
            }
        }
        else {
            if ( (nq2 > 0) | (nq > 0) | (nquants > 0) ) {
                sf_running_timer (&timer, "\txtile step 3: Sorted source and computed quantiles");
            }
            else {
                sf_running_timer (&timer, "\txtile step 3: Sorted source variable");
            }
        }
    }
    stimer = clock();

    /*********************************************************************
     *    Compute xtile, if requested; else just count bin frequency     *
     *********************************************************************/

    q = 0;
    if ( kgen ) {
        if ( method == 2 ) {
            if ( sorted ) {
                if ( bincount | pctpct ) {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        while ( *xptr > qptr[q] ) q++;
                        xcount[q]++;
                        xptr[0] = q + 1;
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        while ( *xptr > qptr[q] ) q++;
                        xptr[0] = q + 1;
                    }
                }
            }
            else {
                if ( bincount | pctpct ) {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        q = 0;
                        while ( *xptr > qptr[q] ) q++;
                        xcount[q]++;
                        xptr[0] = q + 1;
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        q = 0;
                        while ( *xptr > qptr[q] ) q++;
                        xptr[0] = q + 1;
                    }
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile");

            optr  = xsources;
            ixptr = xsources + 2 * Nread;
            if ( N < Nread ) {
                for (optr = xsources; optr < xsources + N; optr += 1, ixptr += 1) {
                    if ( (rc = SF_vstore(start_xtile, ((GT_size) *ixptr) + in1, *optr)) ) goto exit;
                }
            }
            else {
                for (i = 0; i < N; i++, optr += 1) {
                    if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.2: Copied xtile to Stata sequentially");

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");

        }
        else {
            if ( bincount | pctpct ) {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    while ( *xptr > qptr[q] ) q++;
                    xcount[q]++;
                    xoutput[(GT_size) *(xptr + kx - 1)] = q + 1;
                    // xptr[0] = q + 1;
                }
            }
            else {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    while ( *xptr > qptr[q] ) q++;
                    xoutput[(GT_size) *(xptr + kx - 1)] = q + 1;
                    // xptr[0] = q + 1;
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile");

            // for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
            //     xoutput[(GT_size) *(xptr + kx - 1)] = *xptr;
            // }

            if ( N < Nread ) {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    xsources[kx * ((GT_size) *(xptr + kx - 1))] = *(xptr + 1);
                }

                if ( st_info->benchmark > 2 )
                    sf_running_timer (&stimer, "\t\txtile step 4.2: Arranged xtile in memory");
            }

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

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.3: Copied xtile to Stata sequentially");

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");
        }
    }
    else if ( pctpct | bincount ) {
        if ( sorted ) {
            for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                while ( *xptr > qptr[q] ) q++;
                xcount[q]++;
            }
        }
        else {
            for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                q = 0;
                while ( *xptr > qptr[q] ) q++;
                xcount[q]++;
            }
        }
    }

    /*********************************************************************
     *         Return percentiles and frequencies, if requested          *
     *********************************************************************/

    // qtot = q + 1;
    qtot = GTOOLS_PWMIN((nout - 1), SF_nobs());

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
    if ( (rc = SF_scal_save ("__gtools_xtile_method", m_ratio)) ) goto exit;

    if ( st_info->benchmark > 1 ) {
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
    free (xcount);
    free (xoutput);

error:
    free (xsources);
    free (xquant);
    free (xpoints);
    free (xquants);

    return (rc);
}

/*********************************************************************
 *                              Scratch                              *
 *********************************************************************/

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
