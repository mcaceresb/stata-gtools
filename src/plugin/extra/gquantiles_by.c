/*
 * UNTESTED! Planned for 0.11.0 or 1.0.0
 */
ST_retcode sf_xtile_by (struct StataInfo *st_info, int level);

ST_retcode sf_xtile_by (struct StataInfo *st_info, int level)
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

    nout  = GTOOLS_PWMAX(nq,     nq2);
    nout  = GTOOLS_PWMAX(nout,   ncuts);
    nout  = GTOOLS_PWMAX(nout,   1);
    nout += 1;

    /*********************************************************************
     *                         Memory Allocation                         *
     *********************************************************************/

    GT_size *index_st       = calloc(Nread, sizeof *index_st);
    GT_size *offsets_buffer = calloc(J,     sizeof *offsets_buffer);
    GT_size *all_nonmiss    = calloc(J,     sizeof *all_nonmiss);
    GT_size *points_nonmiss = calloc(J,     sizeof *points_nonmiss);

    if ( index_st       == NULL ) return(sf_oom_error("sf_quantiles_by", "index_st"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_quantiles_by", "offsets_buffer"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_quantiles_by", "all_nonmiss"));
    if ( points_nonmiss == NULL ) return(sf_oom_error("sf_quantiles_by", "points_nonmiss"));

    ST_double *xsources = calloc(2 * Nread, sizeof *xsources);
    ST_double *xquant   = calloc(nout,      sizeof *xquant);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles_by", "xsources"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles_by", "xquant"));

    // No cut if in allowed with by; always read if in
    GT_size kx = kgen? 2: 1;
    GT_size xmem_sources = kx * J * Nread;
    GT_size xmem_quant   = nout;
    GT_size xmem_points  = cutvars? (N + 1): 1;
    GT_size xmem_quants  = qvars? (N + 1): 1;

    ST_double *xsources = calloc(xmem_sources, sizeof *xsources);
    ST_double *xquant   = calloc(xmem_quant,   sizeof *xquant);
    ST_double *xpoints  = calloc(xmem_points,  sizeof *xpoints);
    ST_double *xquants  = calloc(xmem_quants,  sizeof *xquants);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles", "xsources"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles", "xquant"));
    if ( xpoints  == NULL ) return(sf_oom_error("sf_quantiles", "xpoints"));
    if ( xquants  == NULL ) return(sf_oom_error("sf_quantiles", "xquants"));

    // If cutifin (cutby), read cut var by all
    // If not, then read cut var normally and use the same cut vals on all groups

    /*********************************************************************
     *                          Read in sources                          *
     *********************************************************************/

    for (i = 0; i < Nread; i++)
        index_st[i] = 0;

    for (j = 0; j < J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];

        points_nonmiss[j] = 0;
        all_nonmiss[j]    = 0;
        offsets_buffer[j] = 2 * start;

        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = l + 1;
    }

    i = 0;
    if ( kgen ) {
        for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
            if ( *stptr ) {
                j     = *stptr - 1;
                start = st_info->info[j];
                if ( (rc = SF_vdata(start_xsources, i + st_info->in1, &z)) ) goto exit;
                if ( SF_is_missing(z) ) continue;
                sel = kx * start + kx * all_nonmiss[j]++;
                xsources[sel] = z;
                xsources[sel + 1] = i;
            }
        }
    }
    else {
        for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
            if ( *stptr ) {
                j     = *stptr - 1;
                start = st_info->info[j];
                if ( (rc = SF_vdata(start_xsources, i + st_info->in1, &z)) ) goto exit;
                if ( SF_is_missing(z) ) continue;
                sel = start + all_nonmiss[j]++;
                xsources[sel] = z;
            }
        }
    }

    /*********************************************************************
     *           Adjust percentiles or curoffs, if applicable            *
     *********************************************************************/


    /*********************************************************************
     *                         Compute quantiles                         *
     *********************************************************************/

    if ( nq2 > 0 ) {
        for (j = 0; j < J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];
            xptr  = xsources + start;
            quicksort_bsd (
                xptr,
                end,
                2 * sizeof(xsources),
                xtileCompare,
                NULL
            );

            for (i = 0; i < nq2; i++) {
                q = ceil(st_info->xtile_quantiles[i] * end / 100) - 1;
                xquant[i] = xptr[2 * q];
            }
            xquant[nq2] = xptr[2 * end - 2];

            q = 0;
            for (i = 0; i < end; i++, xptr += 2) {
                while ( xptr[0] > xquant[q] ) q++;
                l = (GT_size) xptr[1];
                if ( (rc = SF_vstore(start_xtile, l + st_info->in1, q + 1)) ) goto exit;
            }
        }
    }
    else if ( nq > 0 ) {
        nqdbl  = (ST_double) nq;
        for (j = 0; j < J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];
            xptr  = xsources + start;
            quicksort_bsd (
                xptr,
                end,
                2 * sizeof(xsources),
                xtileCompare,
                NULL
            );

            for (i = 0; i < nq; i++) {
                q = ceil((i + 1) * end / nqdbl) - 1;
                xquant[i] = xptr[2 * q];
            }
            xquant[nq] = xptr[2 * end - 2];

            q = 0;
            for (i = 0; i < end; i++, xptr += 2) {
                while ( xptr[0] > xquant[q] ) q++;
                l = (GT_size) xptr[1];
                if ( (rc = SF_vstore(start_xtile, l + st_info->in1, q + 1)) ) goto exit;
            }
        }
    }
    else if ( ncuts > 0 ) {
        for (j = 0; j < J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];
            xptr  = xsources + start;
            quicksort_bsd (
                xptr,
                end,
                2 * sizeof(xsources),
                xtileCompare,
                NULL
            );

            st_info->xtile_cutoffs[ncuts] = xptr[2 * end - 2];
            q = 0;
            for (i = 0; i < end; i++, xptr += 2) {
                while ( xptr[0] > st_info->xtile_cutoffs[q] ) q++;
                l = (GT_size) xptr[1];
                if ( (rc = SF_vstore(start_xtile, l + st_info->in1, q + 1)) ) goto exit;
            }
        }
    }

    /*********************************************************************
     *                           Back to Stata                           *
     *********************************************************************/

    for (i = 0; i < st_info->N; i++) {
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
    free (xquant);

    return (rc);
}


/*********************************************************************
 *                           Counting sort                           *
 *********************************************************************/

void gf_xtile_csort_ix (
    ST_double *x,
    ST_double *ix,
    GT_size N,
    GT_size xrange,
    ST_double xmin
);

void gf_xtile_csort (
    ST_double *x,
    GT_size N,
    GT_size xrange,
    ST_double xmin
);

void gf_xtile_csort_ix (
    ST_double *x,
    ST_double *ix,
    GT_size N,
    GT_size xrange,
    ST_double xmin)
{
    GT_size   *count = calloc(xrange + 1, sizeof *count);
    GT_size   *xcopy = calloc(N, sizeof *xcopy);
    ST_double *icopy = calloc(N, sizeof *icopy);

    GT_size   *xc_ptr = xcopy;
    ST_double *ic_ptr = icopy;
    ST_double *x_ptr  = x;
    ST_double *i_ptr  = ix;

    GT_size s, i;

    for (i = 0; i < xrange + 1; i++)
        count[i] = 0;

    for (x_ptr = x;
         x_ptr < x + N;
         x_ptr  += 1,
         i_ptr  += 1,
         xc_ptr += 1,
         ic_ptr += 1) {
        count[ *xc_ptr = (GT_size) (*x_ptr + 1 - xmin) ]++;
        *ic_ptr = *i_ptr;
    }

    for (i = 1; i < xrange; i++)
        count[i] += count[i - 1];

    for (i = 0; i < N; i++) {
        ix[ s = count[xcopy[i] - 1]++ ] = icopy[i];
        x[s] = xcopy[i] - 1 + xmin;
    }

    free (count);
    free (xcopy);
    free (icopy);
}

void gf_xtile_csort (
    ST_double *x,
    GT_size N,
    GT_size xrange,
    ST_double xmin)
{
    GT_size *xcopy  = calloc(N, sizeof *xcopy);
    GT_size *count  = calloc(xrange + 1, sizeof *count);
    GT_size *xc_ptr = xcopy;
    ST_double *x_ptr  = x;
    GT_size i;

    for (i = 0; i < xrange + 1; i++)
        count[i] = 0;

    for (x_ptr = x;
         x_ptr < x + N;
         x_ptr  += 1,
         xc_ptr += 1) {
        count[ *xc_ptr = (GT_size) (*x_ptr + 1 - xmin) ]++;
    }

    for (i = 1; i < xrange; i++)
        count[i] += count[i - 1];

    for (i = 0; i < N; i++)
        x[ count[xcopy[i] - 1]++ ] = xcopy[i] - 1 + xmin;

    free (count);
    free (xcopy);
}
