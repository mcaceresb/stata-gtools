ST_retcode sf_stats_winsor (struct StataInfo *st_info, int level)
{

    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 1 (sf_stats_winsor): Starting gstats winsor.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z, w, zl, zh;
    GT_size i, j, k, l;
    GT_size out, nj, nj_max, start, end, *stptr;
    GT_size offset_weight, offset_buffer, offset_source, offset_output;

    GT_size wpos     = st_info->wpos;
    GT_bool weights  = st_info->wcode > 0;
    GT_size kvars    = st_info->kvars_by;
    GT_size ksources = st_info->winsor_kvars;
    GT_size kstart   = kvars + ksources + 1;
    GT_size ktargets = ksources;
    GT_size Nread    = st_info->Nread;
    GT_size J        = st_info->J;
    clock_t timer    = clock();

    st_info->output = calloc(J * ktargets * 2, sizeof st_info->output);
    if ( st_info->output == NULL ) return(sf_oom_error("sf_stats_winsor", "st_info->output"));

    GTOOLS_GC_ALLOCATED("st_info->output")
    ST_double *output = st_info->output;
    st_info->free = 9;

    nj_max = st_info->info[1] - st_info->info[0];
    for (j = 1; j < st_info->J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    ST_double *gsrc_bycol   = calloc(ksources * Nread,  sizeof *gsrc_bycol);
    ST_double *gsrc_weight  = calloc(weights? Nread: 1, sizeof *gsrc_weight);
    ST_double *gsrc_buffer  = calloc(weights? 2 * nj_max: 1,   sizeof *gsrc_buffer);
    ST_double *gsrc_wsum    = calloc(weights? J * ksources: 1, sizeof *gsrc_wsum);
    GT_size   *gsrc_xcount  = calloc(weights? J * ksources: 1, sizeof *gsrc_xcount);

    GT_size *all_nonmiss    = calloc(J * ksources, sizeof *all_nonmiss);
    GT_size *index_st       = calloc(Nread, sizeof *index_st);
    GT_size *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    GT_size *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( gsrc_bycol  == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_bycol");
    if ( gsrc_weight == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_weight");
    if ( gsrc_buffer == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_buffer");
    if ( gsrc_wsum   == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_wsum");
    if ( gsrc_xcount == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_xcount");

    if ( index_st       == NULL ) return(sf_oom_error("sf_stats_winsor", "index_st"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_stats_winsor", "offsets_buffer"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_stats_winsor", "all_nonmiss"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_stats_winsor", "nj_buffer"));

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_stats_winsor): Index Stata order.\n");
    }

    for (i = 0; i < Nread; i++) {
        index_st[i] = 0;
    }

    for (j = 0; j < J * ksources; j++) {
        all_nonmiss[j] = 0;
    }

    for (j = 0; j < J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];

        offsets_buffer[j] = start * ksources;
        nj_buffer[j]      = end - start;
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = l + 1;
    }

    if ( debug ) {
        sf_printf_debug("debug 3 (sf_stats_winsor): Read from Stata in order.\n");
    }

    i = 0;
    if ( weights ) {
        for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
            if ( *stptr ) {
                j     = *stptr - 1;
                start = st_info->info[j];
                end   = st_info->info[j + 1];
                nj    = end - start;

                offset_buffer = start * ksources;
                offset_source = j * ksources;

                for (k = 0; k < ksources; k++) {
                    // Read Stata in order and place into gsrc_bycol in order as well
                    if ( (rc = SF_vdata(kvars + k + 1, i + st_info->in1, &z)) ) goto exit;
                    gsrc_bycol[offset_buffer + nj * k + all_nonmiss[j]] = z;
                }

                if ( (rc = SF_vdata(wpos, i + st_info->in1, &z)) ) goto exit;
                gsrc_weight[start + all_nonmiss[j]] = z;
                all_nonmiss[j]++;
            }
        }
    }
    else {
        for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
            if ( *stptr ) {
                j     = *stptr - 1;
                start = st_info->info[j];
                end   = st_info->info[j + 1];
                nj    = end - start;

                offset_buffer = start * ksources;
                offset_source = j * ksources;
                for (k = 0; k < ksources; k++) {
                    // Read Stata in order
                    if ( (rc = SF_vdata(kvars + k + 1, i + st_info->in1, &z)) ) goto exit;
                    if ( !SF_is_missing(z) ) {
                        // Read into C both in order and out of order, via
                        // index_st. In order so non-missing entries of given
                        // variable for each group occupy a contiguous segment
                        // in memory. Out of order so winsorizing is faster.
                        gsrc_bycol [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\twinsor step 1: Copied sources into memory.");

    /*********************************************************************
     *                     Step 3: Compute cutpoints                     *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 4 (sf_stats_winsor): Compute cutpoints for each source and group.\n");
    }

    if ( weights ) {
        for (j = 0; j < J; j++) {
            offset_output = j * ktargets * 2;
            offset_buffer = offsets_buffer[j];
            offset_weight = st_info->info[st_info->ix[j]];

            nj = nj_buffer[j];
            for (k = 0; k < ksources; k++) {
                start = j * ksources + k;
                gf_array_dsum_dcount_weighted (
                    gsrc_bycol + offset_buffer + nj * k,
                    nj,
                    gsrc_weight + offset_weight,
                    gsrc_buffer, // dummy
                    gsrc_wsum   + start,
                    gsrc_xcount + start
                );

                output[offset_output + 2 * k + 0] = gf_array_dquantile_weighted(
                    gsrc_bycol + offset_buffer + nj * k,
                    nj,
                    gsrc_weight + offset_weight,
                    st_info->winsor_cutl,
                    gsrc_wsum[start],
                    gsrc_xcount[start],
                    gsrc_buffer
                );

                output[offset_output + 2 * k + 1] = gf_array_dquantile_weighted(
                    gsrc_bycol + offset_buffer + nj * k,
                    nj,
                    gsrc_weight + offset_weight,
                    st_info->winsor_cuth,
                    gsrc_wsum[start],
                    gsrc_xcount[start],
                    gsrc_buffer
                );
            }
        }
    }
    else {
        for (j = 0; j < J; j++) {
            offset_output = j * ktargets * 2;
            offset_buffer = offsets_buffer[j];
            offset_source = st_info->ix[j] * ksources;
            nj = nj_buffer[j];

            // Get the position of the first and last obs of each source

            for (k = 0; k < ktargets; k++) {
                start = offset_buffer + nj * k;
                end   = all_nonmiss[offset_source + k];
                output[offset_output + 2 * k + 0] = gf_array_dquantile_range(
                    gsrc_bycol,
                    start,
                    start + end,
                    st_info->winsor_cutl
                );

                output[offset_output + 2 * k + 1] = gf_array_dquantile_range(
                    gsrc_bycol,
                    start,
                    start + end,
                    st_info->winsor_cuth
                );

                // sf_printf_debug("%ld (%ld, %ld): [%9.4f, %9.4f]\n",
                //                 offset_output + 2 * k + 1,
                //                 j, k,
                //                 output[offset_output + 2 * k + 0],
                //                 output[offset_output + 2 * k + 1]);
            }
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\twinsor step 2: Computed cutpoints.");

    /*********************************************************************
     *                     Step 4: Winsorize or trim                     *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 5 (sf_stats_winsor): Replace variable, Winsorized or trimmed.\n");
    }

    if ( st_info->winsor_trim ) {
        for (j = 0; j < st_info->J; j++) {
            l     = st_info->ix[j];
            start = st_info->info[l];
            end   = st_info->info[l + 1];
            offset_output = j * ktargets * 2;
            for (i = start; i < end; i++) {
                out = st_info->index[i] + st_info->in1;
                for (k = 0; k < ktargets; k++) {
                    zl = st_info->output[offset_output + 2 * k + 0];
                    zh = st_info->output[offset_output + 2 * k + 1];
                    if ( (rc = SF_vdata(kvars + k + 1, out, &w)) ) goto exit;
                    if ( (w < SV_missval) && (w < zl || w > zh) ) {
                        if ( (rc = SF_vstore(kstart + k, out, SV_missval)) ) goto exit;
                    }
                    else {
                        if ( (rc = SF_vstore(kstart + k, out, w)) ) goto exit;
                    }
                }
            }
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            l     = st_info->ix[j];
            start = st_info->info[l];
            end   = st_info->info[l + 1];
            offset_output = j * ktargets * 2;
            for (i = start; i < end; i++) {
                out = st_info->index[i] + st_info->in1;
                for (k = 0; k < ktargets; k++) {
                    zl = st_info->output[offset_output + 2 * k + 0];
                    zh = st_info->output[offset_output + 2 * k + 1];
                    if ( (rc = SF_vdata(kvars + k + 1, out, &w)) ) goto exit;
                    // sf_printf_debug("%9.4f (%ld, %ld): [%9.4f, %9.4f]\n", w, i, k, zl, zh);
                    if ( (w < SV_missval) && (w > zh) ) {
                        if ( (rc = SF_vstore(kstart + k, out, zh)) ) goto exit;
                    }
                    else if ( (w < SV_missval) && (w < zl) ) {
                        if ( (rc = SF_vstore(kstart + k, out, zl)) ) goto exit;
                    }
                    else {
                        if ( (rc = SF_vstore(kstart + k, out, w)) ) goto exit;
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 1 ) {
        if ( st_info->winsor_trim ) {
            sf_running_timer (&timer, "\twinsor step 3: Trimmed variable(s).");
        }
        else {
            sf_running_timer (&timer, "\twinsor step 3: Winsorized variable(s).");
        }
    }

exit:
    free(gsrc_bycol);
    free(gsrc_weight);
    free(gsrc_buffer);
    free(gsrc_wsum);
    free(gsrc_xcount);

    free(index_st);
    free(offsets_buffer);
    free(all_nonmiss);
    free(nj_buffer);

    return (rc);
}
