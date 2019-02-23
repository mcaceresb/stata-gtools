ST_retcode sf_stats_summarize (struct StataInfo *st_info, int level, char *fname)
{

    // NOTE: These will largely follow the egen_bulk* functions, with
    // the exception that no output _variables_ are generated. Hence
    // they are more sparsely commented.

    // if ( st_info->wcode ) {
    //     return (sf_stats_summarize_w (st_info, level, fname));
    // }

    // if ( st_info->summarize_pooled ) {
    //     return (sf_stats_summarize_p(st_info, level, fname));
    // }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    FILE *fhandle;
    ST_retcode rc = 0;
    ST_double z, scode;

    GT_size i, j, k, l, sth;
    GT_size nj, nj_max, start, end, sel;
    GT_size offset_output, offset_source, offset_buffer;

    clock_t  timer = clock();
    clock_t stimer = clock();

    GT_size N = st_info->N;
    GT_size J = st_info->J;

    GT_size kvars         = st_info->kvars_by;
    GT_size ksources      = st_info->summarize_kvars;
    GT_size ktargets      = st_info->summarize_kstats;
    GT_size krow          = ktargets;
    GT_size start_sources = kvars + st_info->kvars_group + 1;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    GT_size *pos_sources = calloc(ksources, sizeof *pos_sources);
    ST_double *statcode  = calloc(ktargets, sizeof *statcode);
    ST_double **sdbl     = calloc(ksources, sizeof **sdbl);
    ST_double **edbl     = calloc(ksources, sizeof **edbl);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_stats_summarize", "pos_sources"));
    if ( statcode    == NULL ) return(sf_oom_error("sf_stats_summarize", "statcode"));
    if ( sdbl        == NULL ) return(sf_oom_error("sf_stats_summarize", "sdbl"));
    if ( edbl        == NULL ) return(sf_oom_error("sf_stats_summarize", "edbl"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < ktargets; k++) {
        statcode[k] = st_info->summarize_codes[k];
    }

    st_info->output = calloc(J * krow * ksources, sizeof st_info->output);
    if ( st_info->output == NULL )
        return(sf_oom_error("sf_stats_summarize", "st_info->output"));

    GTOOLS_GC_ALLOCATED("st_info->output")
    ST_double *output = st_info->output;
    st_info->free = 9;

    nj_max = st_info->info[1] - st_info->info[0];
    for (j = 1; j < st_info->J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    GT_size  *nuniq_ix;
    uint64_t *nuniq_h1;
    uint64_t *nuniq_h2;
    uint64_t *nuniq_h3;
    uint64_t *nuniq_xcopy;

    if ( st_info->nunique ) {
        nuniq_ix    = calloc(nj_max, sizeof *nuniq_ix);
        nuniq_h1    = calloc(nj_max, sizeof *nuniq_h1);
        nuniq_h2    = calloc(nj_max, sizeof *nuniq_h2);
        nuniq_h3    = calloc(nj_max, sizeof *nuniq_h3);
        nuniq_xcopy = calloc(nj_max, sizeof *nuniq_xcopy);
    }
    else {
        nuniq_ix    = malloc(sizeof(nuniq_ix));
        nuniq_h1    = malloc(sizeof(nuniq_h1));
        nuniq_h2    = malloc(sizeof(nuniq_h2));
        nuniq_h3    = malloc(sizeof(nuniq_h3));
        nuniq_xcopy = malloc(sizeof(nuniq_xcopy));
    }

    if ( nuniq_ix    == NULL ) return(sf_oom_error("sf_stats_summarize", "nuniq_ix"));
    if ( nuniq_h1    == NULL ) return(sf_oom_error("sf_stats_summarize", "nuniq_h1"));
    if ( nuniq_h2    == NULL ) return(sf_oom_error("sf_stats_summarize", "nuniq_h2"));
    if ( nuniq_h3    == NULL ) return(sf_oom_error("sf_stats_summarize", "nuniq_h3"));
    if ( nuniq_xcopy == NULL ) return(sf_oom_error("sf_stats_summarize", "nuniq_xcopy"));

    ST_double *all_buffer     = calloc(N * ksources, sizeof *all_buffer);
    GT_bool   *all_firstmiss  = calloc(J * ksources, sizeof *all_firstmiss);
    GT_bool   *all_lastmiss   = calloc(J * ksources, sizeof *all_lastmiss);
    GT_size   *all_nonmiss    = calloc(J * ksources, sizeof *all_nonmiss);
    GT_size   *all_yesmiss    = calloc(J * ksources, sizeof *all_yesmiss);
    GT_size   *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    GT_size   *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_stats_summarize", "output"));
    if ( all_firstmiss  == NULL ) return(sf_oom_error("sf_stats_summarize", "all_firstmiss"));
    if ( all_lastmiss   == NULL ) return(sf_oom_error("sf_stats_summarize", "all_lastmiss"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_stats_summarize", "all_nonmiss"));
    if ( all_yesmiss    == NULL ) return(sf_oom_error("sf_stats_summarize", "all_yesmiss"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_stats_summarize", "offsets_buffer"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_stats_summarize", "nj_buffer"));

    for (j = 0; j < J * ksources; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = all_yesmiss[j] = 0;

    GT_size *nmfreq = calloc(ksources, sizeof *nmfreq);
    if ( nmfreq == NULL )
        return(sf_oom_error("sf_stats_summarize", "nmfreq"));

    for (k = 0; k < ksources; k++)
        nmfreq[k] = 0;

    ST_double *firstmiss = calloc(ksources, sizeof *firstmiss);
    ST_double *lastmiss  = calloc(ksources, sizeof *lastmiss);
    ST_double *firstnm   = calloc(ksources, sizeof *firstnm);
    ST_double *lastnm    = calloc(ksources, sizeof *lastnm);

    if ( firstmiss == NULL ) return(sf_oom_error("sf_stats_summarize", "firstmiss"));
    if ( lastmiss  == NULL ) return(sf_oom_error("sf_stats_summarize", "lastmiss"));
    if ( firstnm   == NULL ) return(sf_oom_error("sf_stats_summarize", "firstnm"));
    if ( lastnm    == NULL ) return(sf_oom_error("sf_stats_summarize", "lastnm"));

    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL )
        return(sf_oom_error("sf_stats_summarize", "index_st"));

    for (i = 0; i < st_info->Nread; i++) {
        index_st[i] = 0;
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

    offset_buffer = offset_source = 0;
    for (i = 0; i < st_info->Nread; i++) {
        if ( index_st[i] == 0 ) continue;
        j     = index_st[i] - 1;
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        nj    = end - start;

        offset_buffer = start * ksources;
        offset_source = j * ksources;

        for (k = 0; k < ksources; k++) {
            if ( (rc = SF_vdata(pos_sources[k], i + st_info->in1, &z)) ) goto exit;
            if ( SF_is_missing(z) ) {
                if ( i == st_info->index[start]   ) all_firstmiss[offset_source + k] = 1;
                if ( i == st_info->index[end - 1] ) all_lastmiss[offset_source + k]  = 1;
                all_buffer [offset_buffer + nj * k + (nj - all_yesmiss[offset_source + k]++ - 1)] = z;
            }
            else {
                all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.1: Read source variables sequentially");

    /*********************************************************************
     *                Step 4: Collapse variables by gorup                *
     *********************************************************************/

    for (j = 0; j < J; j++)
        for (k = 0; k < ksources; k++)
            nmfreq[k] += all_nonmiss[j * ksources + k];

    {
        for (j = 0; j < J; j++) {

            // Remember we read things in group sort order but info and index
            // are in hash sort order, so the jth output corresponds to the
            // st_info->ix[j]th source

            offset_source = st_info->ix[j] * ksources;
            offset_buffer = offsets_buffer[j];
            nj            = nj_buffer[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            for (k = 0; k < ksources; k++) {
                sel   = offset_source + k;
                start = offset_buffer + nj * k;
                end   = all_nonmiss[sel];
                if ( end == 0 ) { // all are missing; invert first/last bc missings were read in reverse
                    firstmiss[k] = firstnm[k] = all_buffer[start + nj - 1];
                    lastmiss[k]  = lastnm[k]  = all_buffer[start];
                }
                else if ( end < nj ) { // some are missing; invert first/last bc missings were read in reverse
                    firstnm[k]   = all_buffer[start];
                    lastnm[k]    = all_buffer[start + end - 1];
                    firstmiss[k] = all_buffer[start + nj - 1];
                    lastmiss[k]  = all_buffer[start + end];
                }
                else { // none are missing; first/last are same
                    firstmiss[k] = firstnm[k] = all_buffer[start];
                    lastmiss[k]  = lastnm[k]  = all_buffer[start + end - 1];
                }

                // for (i = start; i < start + end; i++) {
                //     printf("%ld: %.1f\n", i, all_buffer[i]);
                // }
                //     printf("\n");
                // quicksort_bsd(
                //     all_buffer + start,
                //     end,
                //     sizeof(all_buffer),
                //     xtileCompare,
                //     NULL
                // );
                // for (i = start; i < start + end; i++) {
                //     printf("%ld: %.1f\n", i, all_buffer[i]);
                // }
                //     printf("\n");

// printf("\n\n");
                offset_output = j * krow * ksources + k * krow;
                for (l = 0; l < ktargets; l++) {

                    // Compute the stats
                    // -----------------

                    scode = statcode[l];
// printf("debug %ld, %ld: %ld to %ld, %.1f\n", k, l, start, end, scode);
                    if ( scode == -6 ) { // count
                        output[offset_output + l] = end;
                    }
                    else if ( scode == -14 ) { // freq
                        output[offset_output + l] = nj;
                    }
                    else if ( scode == -22 ) { // nmissing
                        output[offset_output + l] = nj - end;
                    }
                    else if ( scode == -7  ) { // percent
                        output[offset_output + l] = 100 * ((ST_double) end / nmfreq[st_info->pos_targets[l]]);
                    }
                    else if ( scode == -10 ) { // first
                        output[offset_output + l] = all_firstmiss[sel]? firstmiss[st_info->pos_targets[l]]: firstnm[st_info->pos_targets[l]];
                    }
                    else if ( scode == -11 ) { // firstnm
                        output[offset_output + l] = firstnm[st_info->pos_targets[l]];
                    }
                    else if (scode == -12 ) { // last
                        output[offset_output + l] = all_lastmiss[sel]? lastmiss[st_info->pos_targets[l]]: lastnm[st_info->pos_targets[l]];
                    }
                    else if ( scode == -13 ) { // lastnm
                        output[offset_output + l] = lastnm[st_info->pos_targets[l]];
                    }
                    else if ( scode == -18 ) { // nunique
                        if ( (rc = gf_array_nunique_range (
                                output + offset_output + l,
                                all_buffer + start,
                                nj,
                                (end == 0),
                                nuniq_h1,
                                nuniq_h2,
                                nuniq_h3,
                                nuniq_ix,
                                nuniq_xcopy
                            )
                        ) ) return (rc);
                    }
                    else if ( end == 0 ) { // no obs
                        if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                            output[offset_output + l] = 0;
                        }
                        else if ( (scode == -4) || (scode == -5) ) { // min/max
                            output[offset_output + l] = gf_switch_fun_code (scode, all_buffer, start, start + nj);
                        }
                        else {
                            output[offset_output + l] = SV_missval;
                        }
                    }
                    else if ( (scode == -3) &  (end < 2) ) { // sd
// printf("debug %ld, %ld: why here?\n", k, l);
                        output[offset_output + l] = SV_missval;
                    }
                    else if ( (scode == -15) &  (end < 2) ) { // semean
                        output[offset_output + l] = SV_missval;
                    }
                    else if ( scode == -206 ) { // sum_w is ust N in the unweighted version
                        output[offset_output + l] = end;
                    }
                    else if ( scode == -203 ) { // Var (assumes prior stat was sd
                        output[offset_output + l] = (output[offset_output + l - 1]) * (output[offset_output + l - 1]);
                    }
                    else if ( scode > 1000 ) { // #th smallest
                        sth = (GT_size) (scode - 1001);
                        if ( sth < end ) {
                            output[offset_output + l] = gf_qselect_range(all_buffer, start, start + end, sth);
                        }
                        else {
                            output[offset_output + l] = SV_missval;
                        }
                    }
                    else if ( scode < -1000 ) { // #th largest
                        sth = (GT_size) end + 1000 + scode;
                        if ( sth < end ) {
                            output[offset_output + l] = gf_qselect_range(all_buffer, start, start + end, sth);
                        }
                        else {
                            output[offset_output + l] = SV_missval;
                        }
                    }
                    else { // etc
// printf("debug %ld, %ld: %ld to %ld, %.1f\n", k, l, start, end, scode);
                        output[offset_output + l] = gf_switch_fun_code (scode, all_buffer, start, start + end);
                    }
// printf("\t%.1f\n", output[offset_output + l]);
                }

                // set rmsg on
                // use /tmp/tmp, clear
                // gstats sum rvar
                // gstats sum *

                // TODO: Before fiddling here; make sure the opts are being parsed correctly!!! debug the things
                // TODO: select # broken with some N (maybe N < 1k?)
                // TODO: Add select# and select-# to collapse
                // TODO: Add cv here and to collapse
                // TODO: Add Var as a sepparate stat!
                // TODO: Add _meanonly stat to compute N, sum_w, sum, mean, min, max in one fun vs 6 passes, code -900?
                //       Have 901 and 903 be the same func; have 902 be a diff func that uses 901/903?
                // TODO: Option -selectoverflow(missing|closest)-
                // TODO: document in gegen
                // TODO: columns(variables|stats|auto)

            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.2: Computed summary stats");

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Generated output array");

    fhandle = fopen(fname, "wb");
    rc = (fwrite(output, sizeof(output), J * krow * ksources, fhandle) != (J * krow * ksources));
    fclose (fhandle);

    if ( rc ) {
        sf_errprintf("unable to write output to disk\n");
        rc = 198;
        goto exit;
    }

exit:

    free (pos_sources);
    free (statcode);
    free (index_st);
    free (sdbl);
    free (edbl);

    free (nuniq_h1);
    free (nuniq_h2);
    free (nuniq_h3);
    free (nuniq_ix);
    free (nuniq_xcopy);

    free (all_buffer);
    free (all_firstmiss);
    free (all_lastmiss);
    free (all_nonmiss);
    free (all_yesmiss);
    free (offsets_buffer);
    free (nj_buffer);

    free (nmfreq);
    free (firstmiss);
    free (lastmiss);
    free (firstnm);
    free (lastnm);

    return (rc);
}

ST_retcode sf_stats_summarize_w (struct StataInfo *st_info, int level, char *fname)
{
    return(17901);
}

ST_retcode sf_stats_summarize_p (struct StataInfo *st_info, int level, char *fname)
{
    return(17901);
}
