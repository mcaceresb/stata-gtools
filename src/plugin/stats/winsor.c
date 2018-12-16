ST_retcode sf_stats_winsor (struct StataInfo *st_info, int level)
{

    // if ( st_info->wcode ) {
    //     return (sf_stats_winsor_w (st_info, level));
    // }

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
    GT_size out, nj, start, end, *stptr;
    GT_size offset_buffer, offset_source, offset_output;

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

    // ST_double *gsrc_byrow = calloc(ksources * Nread,  sizeof *gsrc_byrow);
    ST_double *gsrc_bycol = calloc(ksources * Nread,  sizeof *gsrc_bycol);

    GT_size *index_st       = calloc(Nread, sizeof *index_st);
    GT_size *offsets_buffer = calloc(J,     sizeof *offsets_buffer);
    GT_size *all_nonmiss    = calloc(J,     sizeof *all_nonmiss);
    GT_size *nj_buffer      = calloc(J,     sizeof *nj_buffer);

    if ( gsrc_bycol == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_bycol");
    if ( gsrc_bycol == NULL ) sf_oom_error("sf_stats_winsor", "gsrc_bycol");

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

    for (j = 0; j < J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];

        offsets_buffer[j] = start * ksources;
        nj_buffer[j]      = end - start;
        all_nonmiss[j]    = 0;
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = l + 1;
    }

    if ( debug ) {
        sf_printf_debug("debug 3 (sf_stats_winsor): Read from Stata in order.\n");
    }

    i = 0;
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

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\twinsor step 1: Copied sources into memory.");

    // if ( weights ) {
    //     for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
    //         if ( *stptr ) {
    //             j     = *stptr - 1;
    //             start = st_info->info[j];
    //             if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
    //             if ( SF_is_missing(w) ) continue;
    //         }
    //     }
    // }

    /*********************************************************************
     *                     Step 3: Compute cutpoints                     *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 4 (sf_stats_winsor): Compute cutpoints for each source and group.\n");
    }

    for (j = 0; j < J; j++) {
        offset_output = j * ktargets * 2;
        offset_buffer = offsets_buffer[j];
        nj            = nj_buffer[j];

        // Get the position of the first and last obs of each source
        start = offset_buffer;
        end   = all_nonmiss[j];

        for (k = 0; k < ktargets; k++) {
            output[offset_output + 2 * k + 0] = gf_switch_fun_code(
                st_info->winsor_cutl,
                gsrc_bycol,
                start,
                start + end
            );
            output[offset_output + 2 * k + 1] = gf_switch_fun_code(
                st_info->winsor_cuth,
                gsrc_bycol,
                start,
                start + end
            );
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
                    if ( w < zl || w > zh ) {
                        if ( (rc = SF_vstore(kstart + k, out, SV_missval)) ) goto exit;
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
                    if ( w > zh ) {
                        if ( (rc = SF_vstore(kstart + k, out, zh)) ) goto exit;
                    }
                    else if ( w < zl ) {
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
    // free(gsrc_byrow);
    free(gsrc_bycol);

    free(index_st);
    free(offsets_buffer);
    free(all_nonmiss);
    free(nj_buffer);

    return (rc);
}
