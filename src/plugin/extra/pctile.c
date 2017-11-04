ST_retcode sf_xtile (struct StataInfo *st_info, int level);

ST_retcode sf_xtile (struct StataInfo *st_info, int level)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_double z, *xptr;
    GT_size i, j, l, q, sel, start, end;
    ST_retcode rc = 0;
    // clock_t timer = clock();

    GT_size nq      = st_info->xtile_nq;
    GT_size nq2     = st_info->xtile_nq2;
    GT_size ncuts   = st_info->xtile_ncuts;
    // GT_size cutvars = st_info->xtile_cutvars;
    GT_size _nq2    = _nq2;
    GT_size _ncuts  = _ncuts;

    GT_size kgen    = st_info->xtile_gen;
    GT_size kpctile = st_info->xtile_pctile;

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
    GT_size start_xsources = start_xtile + xstart;

    GT_size Nread = st_info->Nread;
    GT_size J     = st_info->J;

    GT_size nout, npctile;
    nout    = GTOOLS_PWMAX(nq,     nq2);
    nout    = GTOOLS_PWMAX(nout,   ncuts);
    nout    = GTOOLS_PWMAX(nout,   1);
    nout   += 1;
    npctile = kpctile > 0? kpctile * (nout - 1): 1;
    kpctile = GTOOLS_PWMAX(kpctile, 1);

    /*********************************************************************
     *                         Memory Allocation                         *
     *********************************************************************/

    GT_size *index_st       = calloc(Nread, sizeof *index_st);
    GT_size *offsets_buffer = calloc(J,     sizeof *offsets_buffer);
    GT_size *all_nonmiss    = calloc(J,     sizeof *all_nonmiss);

    if ( index_st       == NULL ) return(sf_oom_error("sf_quantiles", "index_st"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_quantiles", "offsets_buffer"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_quantiles", "all_nonmiss"));

    ST_double *xsources = calloc(2 * Nread, sizeof *xsources);
    ST_double *pctile   = calloc(npctile,   sizeof *pctile);
    ST_double *xtile    = calloc(nout,      sizeof *xtile);

    if ( xsources == NULL ) sf_oom_error("sf_quantiles", "xsources");
    if ( xtile    == NULL ) sf_oom_error("sf_quantiles", "xtile");
    if ( pctile   == NULL ) sf_oom_error("sf_quantiles", "pctile");

    /*********************************************************************
     *           Adjust percentiles or curoffs, if applicable            *
     *********************************************************************/

    if ( nq2 > 1 ) {
        quicksort_bsd (
            st_info->xtile_quantiles,
            nq2,
            sizeof(st_info->xtile_quantiles),
            xtileCompare,
            NULL
        );

        _nq2 = 0;
        for (i = 1; i < nq2; i++) {
            if ( st_info->xtile_quantiles[_nq2] != st_info->xtile_quantiles[i] ) {
                _nq2++;
                st_info->xtile_quantiles[_nq2] = st_info->xtile_quantiles[i];
            }
        }
        nq2 = _nq2;
    }

    if ( ncuts > 1 ) {
        quicksort_bsd (
            st_info->xtile_cutoffs,
            ncuts,
            sizeof(st_info->xtile_cutoffs),
            xtileCompare,
            NULL
        );
        _ncuts = 0;
        for (i = 1; i < ncuts; i++) {
            if ( st_info->xtile_quantiles[_ncuts] != st_info->xtile_quantiles[i] ) {
                _ncuts++;
                st_info->xtile_quantiles[_ncuts] = st_info->xtile_quantiles[i];
            }
        }
        ncuts = _ncuts;
    }

    /*********************************************************************
     *                          Read in sources                          *
     *********************************************************************/

    for (i = 0; i < Nread; i++)
        index_st[i] = 0;

    for (j = 0; j < J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];

        all_nonmiss[j]    = 0;
        offsets_buffer[j] = start * (xvars + 1);

        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = l + 1;
    }

    if ( missing ) {
        for (i = 0; i < Nread; i++) {
            if ( index_st[i] == 0 ) continue;
            j     = index_st[i] - 1;
            start = st_info->info[j];
            sel   = start * (xvars + 1) + (xvars + 1) * all_nonmiss[j]++;
            if ( (rc = SF_vdata(start_xsources,
                                i + st_info->in1,
                                xsources + sel)) ) goto exit;
            xsources[sel + xvars] = i;
        }
    }
    else {
        for (i = 0; i < Nread; i++) {
            if ( index_st[i] == 0 ) continue;
            j     = index_st[i] - 1;
            start = st_info->info[j];
            if ( (rc = SF_vdata(start_xsources, i + st_info->in1, &z)) ) goto exit;
            if ( !SF_is_missing(z) ) {
                sel = start * (xvars + 1) + (xvars + 1) * all_nonmiss[j]++;
                xsources[sel] = z;
                xsources[sel + xvars] = i;
            }
        }
    }

    /*********************************************************************
     *                         Compute quantiles                         *
     *********************************************************************/

    if ( nq2 > 0 ) {
        for (j = 0; j < J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];
            xptr  = xsources + 2 * start;
            quicksort_bsd (
                xptr,
                2 * end,
                2 * sizeof(xsources),
                xtileCompare,
                NULL
            );

            for (i = 0; i < nq2; i++) {
                xtile[i] = st_info->xtile_quantiles[i] * end / 100;
            }
            xtile[nq2] = end;

            q = 0;
            for (i = 0; i < end; i++) {
                while ( i >= xtile[q] ) q++;
                xptr[2 * i] = q + 1;
            }
        }
    }
    else if ( nq > 0 ) {
        for (j = 0; j < J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];
            xptr  = xsources + 2 * start;
            quicksort_bsd (
                xptr,
                2 * end,
                2 * sizeof(xsources),
                xtileCompare,
                NULL
            );

            for (i = 0; i < nq; i++) {
                xtile[i] = (i + 1) * end / nq;
            }
            xtile[nq] = end;

            q = 0;
            for (i = 0; i < end; i++) {
                while ( i >= xtile[q] ) q++;
                xptr[2 * i] = q + 1;
            }
        }
    }
    else if ( ncuts > 0 ) {
        for (j = 0; j < J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];
            xptr  = xsources + 2 * start;
            quicksort_bsd (
                xptr,
                2 * end,
                2 * sizeof(xsources),
                xtileCompare,
                NULL
            );

            for (i = 0; i < ncuts; i++) {
                xtile[i] = st_info->xtile_cutoffs[i];
            }
            xtile[ncuts] = xptr[2 * end - 2];

            q = 0;
            for (i = 0; i < end; i++) {
                while ( xptr[2 * i] > xtile[q] ) q++;
                xptr[2 * i] = q + 1;
            }
        }
    }

    /*********************************************************************
     *                           Back to Stata                           *
     *********************************************************************/

    for (i = 0; i < Nread; i++) {
        l = (GT_size) xsources[2 * i + 1];
        if ( (rc = SF_vstore(start_xtile, i + st_info->in1, xsources[2 * l])) ) goto exit;
    }

    // 0
    // 100 / 8 = 12.5
    // 200 / 8 = 25.0
    // 300 / 8 = 37.5
    // 400 / 8 = 50.0
    // 500 / 8 = 62.5
    // 600 / 8 = 75.0
    // 700 / 8 = 87.5
    // 100
    //
    // 0
    // 10 / 8 = 1.25
    // 20 / 8 = 2.50
    // 30 / 8 = 3.75
    // 40 / 8 = 5.00
    // 50 / 8 = 6.25
    // 60 / 8 = 7.50
    // 70 / 8 = 8.75
    //
    // 10 / 8 = 1.25
    // 20 / 8 = 2.50
    // 30 / 8 = 3.75
    // 40 / 8 = 5.00
    // 50 / 8 = 6.25
    // 60 / 8 = 7.50
    // 70 / 8 = 8.75
    // 10

exit:

    free (index_st);
    free (offsets_buffer);
    free (all_nonmiss);
    free (xsources);
    free (xtile);
    free (pctile);

    return (rc);
}
