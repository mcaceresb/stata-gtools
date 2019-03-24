ST_retcode sf_stats_summarize (struct StataInfo *st_info, int level, char *fname)
{
    ST_retcode rc = 0;

    if ( (rc = sf_byx_save(st_info)) ) {
        return(rc);
    }

    if ( st_info->wcode ) {
        return (sf_stats_summarize_w (st_info, level, fname));
    }

    if ( st_info->summarize_pooled ) {
        return (sf_stats_summarize_p(st_info, level, fname));
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    FILE *fhandle;
    ST_double z, scode;

    GT_int sth, snj;
    GT_size i, j, k, l;
    GT_size nj, nj_max, start, end, sel;
    GT_size offset_output, offset_source, offset_buffer;

    clock_t  timer = clock();
    clock_t stimer = clock();

    GT_size N = st_info->N;
    GT_size J = st_info->J;

    GT_size kvars         = st_info->kvars_by;
    GT_size ksources      = st_info->summarize_kvars;
    GT_size ktargets      = st_info->summarize_kstats;
    GT_size start_sources = kvars + st_info->kvars_group + 1;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    GT_size *pos_sources = calloc(ksources, sizeof *pos_sources);
    ST_double *statcode  = calloc(ktargets, sizeof *statcode);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_stats_summarize", "pos_sources"));
    if ( statcode    == NULL ) return(sf_oom_error("sf_stats_summarize", "statcode"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < ktargets; k++)
        statcode[k] = st_info->summarize_codes[k];

    st_info->output = calloc(J * ktargets * ksources, sizeof *st_info->output);
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
        nuniq_ix    = malloc(sizeof *nuniq_ix);
        nuniq_h1    = malloc(sizeof *nuniq_h1);
        nuniq_h2    = malloc(sizeof *nuniq_h2);
        nuniq_h3    = malloc(sizeof *nuniq_h3);
        nuniq_xcopy = malloc(sizeof *nuniq_xcopy);
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
                //     sizeof *all_buffer,
                //     xtileCompare,
                //     NULL
                // );
                // for (i = start; i < start + end; i++) {
                //     printf("%ld: %.1f\n", i, all_buffer[i]);
                // }
                //     printf("\n");

                // Compute the stats
                // -----------------

                offset_output = j * ktargets * ksources + k * ktargets;
                for (l = 0; l < ktargets; l++) {

                    scode = statcode[l];
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
                        output[offset_output + l] = 100 * ((ST_double) end / nmfreq[k]);
                    }
                    else if ( scode == -10 ) { // first
                        output[offset_output + l] = all_firstmiss[sel]? firstmiss[k]: firstnm[k];
                    }
                    else if ( scode == -11 ) { // firstnm
                        output[offset_output + l] = firstnm[k];
                    }
                    else if (scode == -12 ) { // last
                        output[offset_output + l] = all_lastmiss[sel]? lastmiss[k]: lastnm[k];
                    }
                    else if ( scode == -13 ) { // lastnm
                        output[offset_output + l] = lastnm[k];
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
                    else if ( scode > 1000 ) { // #th smallest (all-missing selects among missing)
                        snj = (GT_int) (end > 0? end: nj);
                        sth = (GT_int) (ceil(scode) - 1001);
                        if ( sth < 0 || sth >= snj ) {
                            output[offset_output + l] = SV_missval;
                        }
                        else {
                            output[offset_output + l] = gf_qselect_range(all_buffer, start, start + snj, sth);
                        }
                    }
                    else if ( scode < -1000 ) { // #th largest (all-missing selects among missing)
                        snj = (GT_int) (end > 0? end: nj);
                        sth = (GT_int) (snj + 1000 + floor(scode));
                        if ( sth < 0 || sth >= snj ) {
                            output[offset_output + l] = SV_missval;
                        }
                        else {
                            output[offset_output + l] = gf_qselect_range(all_buffer, start, start + snj, sth);
                        }
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
                    else if ( (scode == -3 || scode == -23 || scode == -24) &  (end < 2) ) { // sd, variance, cv
                        output[offset_output + l] = SV_missval;
                    }
                    else if ( (scode == -15) &  (end < 2) ) { // semean
                        output[offset_output + l] = SV_missval;
                    }
                    else if ( scode == -206 ) { // sum_w is just N in the unweighted version
                        output[offset_output + l] = end;
                    }
                    else if ( scode == -203 ) { // Var (assumes prior stat was sd
                        output[offset_output + l] = (output[offset_output + l - 1]) * (output[offset_output + l - 1]);
                    }
                    else { // etc
                        output[offset_output + l] = gf_switch_fun_code (scode, all_buffer, start, start + end);
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.2: Computed summary stats");

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Generated output array");

    if ( st_info->summarize_colvar ) {
        ST_double *transpose = calloc(J * ktargets * ksources, sizeof *transpose);
        if ( transpose == NULL ) return(sf_oom_error("sf_stats_summarize", "transpose"));

        for (j = 0; j < J; j++) {
            for (k = 0; k < ktargets; k++) {
                offset_buffer = j * ktargets * ksources + k * ksources;
                for (l = 0; l < ksources; l++) {
                    offset_output = j * ktargets * ksources + l * ktargets;
                    transpose[offset_buffer + l] = output[offset_output + k];
                }
            }
        }

        fhandle = fopen(fname, "wb");
        rc = (fwrite(transpose, sizeof *transpose, J * ktargets * ksources, fhandle) != (J * ktargets * ksources));
        fclose (fhandle);

        free(transpose);
    }
    else {
        fhandle = fopen(fname, "wb");
        rc = (fwrite(output, sizeof *output, J * ktargets * ksources, fhandle) != (J * ktargets * ksources));
        fclose (fhandle);
    }

    if ( rc ) {
        sf_errprintf("unable to write output to disk\n");
        rc = 198;
        goto exit;
    }

exit:

    free (pos_sources);
    free (statcode);
    free (index_st);

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

ST_retcode sf_stats_summarize_p (struct StataInfo *st_info, int level, char *fname)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    FILE *fhandle;
    ST_retcode rc = 0;
    ST_double z, scode;

    GT_int sth, snj;
    GT_size i, j, k, l;
    GT_size nj, nj_max, start, end;
    GT_size offset_output, offset_buffer;

    clock_t  timer = clock();
    clock_t stimer = clock();

    GT_size N = st_info->N;
    GT_size J = st_info->J;

    GT_size kvars         = st_info->kvars_by;
    GT_size ksources      = st_info->summarize_kvars;
    GT_size ktargets      = st_info->summarize_kstats;
    GT_size start_sources = kvars + st_info->kvars_group + 1;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    GT_size *pos_sources = calloc(ksources, sizeof *pos_sources);
    ST_double *statcode  = calloc(ktargets, sizeof *statcode);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_stats_summarize_p", "pos_sources"));
    if ( statcode    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "statcode"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < ktargets; k++)
        statcode[k] = st_info->summarize_codes[k];

    st_info->output = calloc(J * ktargets, sizeof st_info->output);
    if ( st_info->output == NULL )
        return(sf_oom_error("sf_stats_summarize_p", "st_info->output"));

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
        nuniq_ix    = calloc(nj_max * ksources, sizeof *nuniq_ix);
        nuniq_h1    = calloc(nj_max * ksources, sizeof *nuniq_h1);
        nuniq_h2    = calloc(nj_max * ksources, sizeof *nuniq_h2);
        nuniq_h3    = calloc(nj_max * ksources, sizeof *nuniq_h3);
        nuniq_xcopy = calloc(nj_max * ksources, sizeof *nuniq_xcopy);
    }
    else {
        nuniq_ix    = malloc(sizeof(nuniq_ix));
        nuniq_h1    = malloc(sizeof(nuniq_h1));
        nuniq_h2    = malloc(sizeof(nuniq_h2));
        nuniq_h3    = malloc(sizeof(nuniq_h3));
        nuniq_xcopy = malloc(sizeof(nuniq_xcopy));
    }

    if ( nuniq_ix    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "nuniq_ix"));
    if ( nuniq_h1    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "nuniq_h1"));
    if ( nuniq_h2    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "nuniq_h2"));
    if ( nuniq_h3    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "nuniq_h3"));
    if ( nuniq_xcopy == NULL ) return(sf_oom_error("sf_stats_summarize_p", "nuniq_xcopy"));

    ST_double *all_buffer     = calloc(N * ksources, sizeof *all_buffer);
    GT_bool   *all_firstmiss  = calloc(J, sizeof *all_firstmiss);
    GT_bool   *all_lastmiss   = calloc(J, sizeof *all_lastmiss);
    GT_size   *all_nonmiss    = calloc(J, sizeof *all_nonmiss);
    GT_size   *all_yesmiss    = calloc(J, sizeof *all_yesmiss);
    GT_size   *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    GT_size   *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_stats_summarize_p", "output"));
    if ( all_firstmiss  == NULL ) return(sf_oom_error("sf_stats_summarize_p", "all_firstmiss"));
    if ( all_lastmiss   == NULL ) return(sf_oom_error("sf_stats_summarize_p", "all_lastmiss"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "all_nonmiss"));
    if ( all_yesmiss    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "all_yesmiss"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_stats_summarize_p", "offsets_buffer"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_stats_summarize_p", "nj_buffer"));

    for (j = 0; j < J; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = all_yesmiss[j] = 0;

    GT_size *nmfreq = calloc(1, sizeof *nmfreq);
    if ( nmfreq == NULL )
        return(sf_oom_error("sf_stats_summarize_p", "nmfreq"));

    nmfreq[0] = 0;

    ST_double *firstmiss = calloc(1, sizeof *firstmiss);
    ST_double *lastmiss  = calloc(1, sizeof *lastmiss);
    ST_double *firstnm   = calloc(1, sizeof *firstnm);
    ST_double *lastnm    = calloc(1, sizeof *lastnm);

    if ( firstmiss == NULL ) return(sf_oom_error("sf_stats_summarize_p", "firstmiss"));
    if ( lastmiss  == NULL ) return(sf_oom_error("sf_stats_summarize_p", "lastmiss"));
    if ( firstnm   == NULL ) return(sf_oom_error("sf_stats_summarize_p", "firstnm"));
    if ( lastnm    == NULL ) return(sf_oom_error("sf_stats_summarize_p", "lastnm"));

    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL )
        return(sf_oom_error("sf_stats_summarize_p", "index_st"));

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

    for (i = 0; i < st_info->Nread; i++) {
        if ( index_st[i] == 0 ) continue;
        j     = index_st[i] - 1;
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        nj    = end - start;

        for (k = 0; k < ksources; k++) {
            // Read Stata in order
            if ( (rc = SF_vdata(pos_sources[k], i + st_info->in1, &z)) ) goto exit;
            if ( SF_is_missing(z) ) {
                if ( (i == st_info->index[start])   && (k == 0) )              all_firstmiss[j] = 1;
                if ( (i == st_info->index[end - 1]) && (k == (ksources - 1)) ) all_lastmiss[j]  = 1;
                all_buffer [start * ksources + (nj * ksources - all_yesmiss[j]++ - 1)] = z;
            }
            else {
                all_buffer [start * ksources + all_nonmiss[j]++] = z;
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.1: Read source variables sequentially");

    /*********************************************************************
     *                Step 4: Collapse variables by gorup                *
     *********************************************************************/

    for (j = 0; j < J; j++)
        nmfreq[0] += all_nonmiss[j];

    {
        for (j = 0; j < J; j++) {
            offset_output = j * ktargets;
            offset_buffer = offsets_buffer[j];
            nj            = nj_buffer[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            start = offset_buffer;
            end   = all_nonmiss[j];

            if ( end == 0 ) { // all are missing; invert first/last bc missings were read in reverse
                firstmiss[0] = firstnm[0] = all_buffer[start + nj * ksources - 1];
                lastmiss[0]  = lastnm[0]  = all_buffer[start];
            }
            else if ( end < (nj * ksources) ) { // some are missing; invert first/last bc missings were read in reverse
                firstnm[0]  = all_buffer[start];
                lastnm[0]   = all_buffer[start + end - 1];
                firstmiss[0] = all_buffer[start + nj * ksources - 1];
                lastmiss[0]  = all_buffer[start + end];
            }
            else { // none are missing; first/last are same
                firstmiss[0] = firstnm[0] = all_buffer[start];
                lastmiss[0]  = lastnm[0]  = all_buffer[start + end - 1];
            }

            // Compute the stats
            // -----------------

            for (k = 0; k < ktargets; k++) {

                scode = statcode[k];
                if ( scode == -6 ) { // count
                    output[offset_output + k] = end;
                }
                else if ( scode == -14 ) { // freq
                    output[offset_output + k] = nj * ksources;
                }
                else if ( scode == -22 ) { // nmissing
                    output[offset_output + k] = nj * ksources - end;
                }
                else if ( scode == -7  ) { // percent
                    output[offset_output + k] = 100 * ((ST_double) end / nmfreq[0]);
                }
                else if ( scode == -10 ) { // first
                    output[offset_output + k] = all_firstmiss[j]? firstmiss[0]: firstnm[0];
                }
                else if ( scode == -11 ) { // firstnm
                    output[offset_output + k] = firstnm[0];
                }
                else if (scode == -12 ) { // last
                    output[offset_output + k] = all_lastmiss[j]? lastmiss[0]: lastnm[0];
                }
                else if ( scode == -13 ) { // lastnm
                    output[offset_output + k] = lastnm[0];
                }
                else if ( scode == -18 ) { // nunique
                    if ( (rc = gf_array_nunique_range (
                            output + offset_output + k,
                            all_buffer + start,
                            nj * ksources,
                            (end == 0),
                            nuniq_h1,
                            nuniq_h2,
                            nuniq_h3,
                            nuniq_ix,
                            nuniq_xcopy
                        )
                    ) ) return (rc);
                }
                else if ( scode > 1000 ) { // #th smallest (all-missing selects among missing)
                    snj = (GT_int) (end > 0? end: nj);
                    sth = (GT_int) (ceil(scode) - 1001);
                    if ( sth < 0 || sth >= snj ) {
                        output[offset_output + k] = SV_missval;
                    }
                    else {
                        output[offset_output + k] = gf_qselect_range(all_buffer, start, start + snj, sth);
                    }
                }
                else if ( scode < -1000 ) { // #th largest (all-missing selects among missing)
                    snj = (GT_int) (end > 0? end: nj);
                    sth = (GT_int) (snj + 1000 + floor(scode));
                    if ( sth < 0 || sth >= snj ) {
                        output[offset_output + k] = SV_missval;
                    }
                    else {
                        output[offset_output + k] = gf_qselect_range(all_buffer, start, start + snj, sth);
                    }
                }
                else if ( end == 0 ) { // no obs
                    if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                        output[offset_output + k] = 0;
                    }
                    else if ( (scode == -4) || (scode == -5) ) { // min/max
                        output[offset_output + k] = gf_switch_fun_code (scode, all_buffer, start, start + nj * ksources);
                    }
                    else {
                        output[offset_output + k] = SV_missval;
                    }
                }
                else if ( (scode == -3 || scode == -23 || scode == -24) &  (end < 2) ) { // sd, variance, cv
                    output[offset_output + k] = SV_missval;
                }
                else if ( (scode == -15) &  (end < 2) ) { // semean
                    output[offset_output + k] = SV_missval;
                }
                else if ( scode == -206 ) { // sum_w is ust N in the unweighted version
                    output[offset_output + k] = end;
                }
                else if ( scode == -203 ) { // Var (assumes prior stat was sd
                    output[offset_output + k] = (output[offset_output + k - 1]) * (output[offset_output + k - 1]);
                }
                else { // etc
                    output[offset_output + k] = gf_switch_fun_code (scode, all_buffer, start, start + end);
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.2: Computed summary stats");

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Generated output array");

    fhandle = fopen(fname, "wb");
    rc = (fwrite(output, sizeof(output), J * ktargets, fhandle) != (J * ktargets));
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

    return (rc);
}

ST_retcode sf_stats_summarize_w (struct StataInfo *st_info, int level, char *fname)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    FILE *fhandle;
    ST_retcode rc = 0;
    ST_double z, scode;

    GT_int sth, rawsth, snj;
    GT_bool aweights = (st_info->wcode == 1);
    GT_size i, j, k, l;
    GT_size nj, nj_max, start, startw, end;
    ST_double endw, endwraw;
    GT_size offset_output,
           offset_source,
           offset_buffer,
           offset_weight;

    clock_t  timer = clock();
    clock_t stimer = clock();

    GT_size N = st_info->N;
    GT_size J = st_info->J;

    GT_size kvars         = st_info->kvars_by;
    GT_size ksources      = st_info->summarize_kvars;
    GT_size ktargets      = st_info->summarize_kstats;
    GT_size start_sources = kvars + st_info->kvars_group + 1;
    GT_size wpos          = st_info->wpos;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    GT_size *pos_sources = calloc(ksources, sizeof *pos_sources);
    ST_double *statcode  = calloc(ktargets, sizeof *statcode);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_stats_summarize_w", "pos_sources"));
    if ( statcode    == NULL ) return(sf_oom_error("sf_stats_summarize_w", "statcode"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < ktargets; k++)
        statcode[k] = st_info->summarize_codes[k];

    st_info->output = calloc(J * ktargets * ksources, sizeof st_info->output);
    if ( st_info->output == NULL )
        return(sf_oom_error("sf_stats_summarize_w", "st_info->output"));

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

    if ( nuniq_ix    == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nuniq_ix"));
    if ( nuniq_h1    == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nuniq_h1"));
    if ( nuniq_h2    == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nuniq_h2"));
    if ( nuniq_h3    == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nuniq_h3"));
    if ( nuniq_xcopy == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nuniq_xcopy"));

    ST_double *p_buffer = calloc(2 * nj_max, sizeof *p_buffer);
    ST_double *weights  = calloc(N, sizeof *weights);
    GT_size   *nbuffer  = calloc(J, sizeof *nbuffer);

    if ( p_buffer == NULL ) return(sf_oom_error("sf_stats_summarize_w", "p_buffer"));
    if ( weights  == NULL ) return(sf_oom_error("sf_stats_summarize_w", "weights"));
    if ( nbuffer  == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nbuffer"));

    ST_double *all_buffer     = calloc(N * ksources, sizeof *all_buffer);
    ST_double *all_wsum       = calloc(J * ksources, sizeof *all_wsum);
    ST_double *all_xwsum      = calloc(J * ksources, sizeof *all_xwsum);
    GT_size   *all_xcount     = calloc(J * ksources, sizeof *all_xcount);
    GT_size   *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    GT_size   *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_stats_summarize_w", "all_buffer"));
    if ( all_wsum       == NULL ) return(sf_oom_error("sf_stats_summarize_w", "all_wsum"));
    if ( all_xwsum      == NULL ) return(sf_oom_error("sf_stats_summarize_w", "all_xwsum"));
    if ( all_xcount     == NULL ) return(sf_oom_error("sf_stats_summarize_w", "all_xcount"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_stats_summarize_w", "offsets_buffer"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_stats_summarize_w", "nj_buffer"));

    for (j = 0; j < J; j++)
        nbuffer[j] = 0;

    ST_double *nmfreq = calloc(ksources, sizeof *nmfreq);
    if ( nmfreq == NULL )
        return(sf_oom_error("sf_stats_summarize_w", "nmfreq"));

    for (k = 0; k < ksources; k++)
        nmfreq[k] = 0;

    ST_double *firstmiss = calloc(ksources, sizeof *firstmiss);
    ST_double *lastmiss  = calloc(ksources, sizeof *lastmiss);
    ST_double *firstnm   = calloc(ksources, sizeof *firstnm);
    ST_double *lastnm    = calloc(ksources, sizeof *lastnm);

    if ( firstmiss == NULL ) return(sf_oom_error("sf_stats_summarize_w", "firstmiss"));
    if ( lastmiss  == NULL ) return(sf_oom_error("sf_stats_summarize_w", "lastmiss"));
    if ( firstnm   == NULL ) return(sf_oom_error("sf_stats_summarize_w", "firstnm"));
    if ( lastnm    == NULL ) return(sf_oom_error("sf_stats_summarize_w", "lastnm"));


    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL )
        return(sf_oom_error("sf_stats_summarize_w", "index_st"));

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
            all_buffer[offset_buffer + nj * k + nbuffer[j]] = z;
        }

        if ( (rc = SF_vdata(wpos, i + st_info->in1, &z)) ) goto exit;
        weights[start + nbuffer[j]] = z;
        nbuffer[j]++;
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.1: Read source variables sequentially");

    /*********************************************************************
     *                     Step 4: Pre-compute sums                      *
     *********************************************************************/

    for (j = 0; j < J; j++) {
        nj = nj_buffer[j];
        offset_buffer = offsets_buffer[j];
        offset_weight = st_info->info[st_info->ix[j]];
        for (k = 0; k < ksources; k++) {
            gf_array_dsum_dcount_weighted (
                all_buffer + offset_buffer + nj * k,
                nj,
                weights + offset_weight,
                all_xwsum  + j * ksources + k,
                all_wsum   + j * ksources + k,
                all_xcount + j * ksources + k
            );
        }
    }

    for (j = 0; j < J; j++) {
        for (k = 0; k < ksources; k++) {
            endwraw    = all_wsum[j * ksources + k];
            nmfreq[k] += endwraw == SV_missval? 0: endwraw;
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.2: Pre-computed weighted sums");

    /*********************************************************************
     *                Step 5: Collapse variables by gorup                *
     *********************************************************************/

    {
        for (j = 0; j < J; j++) {

            offset_source = st_info->ix[j] * ksources;
            offset_buffer = offsets_buffer[j];
            offset_weight = st_info->info[st_info->ix[j]];
            nj            = nj_buffer[j];

            for (l = 0; l < ksources; l++) {

                start         = offset_buffer + nj * l;
                firstmiss[l]  = all_buffer[start];
                lastmiss[l]   = all_buffer[start + nj - 1];
                firstnm[l]    = gf_array_dfirstnm(all_buffer + offset_buffer + nj * l, nj);
                lastnm[l]     = gf_array_dlastnm (all_buffer + offset_buffer + nj * l, nj);
                offset_output = j * ktargets * ksources + l * ktargets;

                for (k = 0; k < ktargets; k++) {

                    start    = offset_buffer + nj * l;
                    startw   = j * ksources + l;
                    endwraw  = all_wsum[startw];
                    endw     = endwraw == SV_missval? 0: endwraw;
                    scode    = statcode[k];

                    if ( scode == -6 ) { // count
                        output[offset_output + k] = aweights? all_xcount[startw]: endw;
                    }
                    else if ( scode == -14 ) { // freq
                        output[offset_output + k] = nj;
                    }
                    else if ( scode == -22 ) { // nmissing
                        if ( aweights )  {
                            output[offset_output + k] = nj - all_xcount[startw];
                        }
                        else {
                            output[offset_output + k] = gf_array_dnmissing_weighted(
                                all_buffer + start,
                                nj,
                                weights + offset_weight
                            );
                        }
                    }
                    else if ( scode == -7  ) { // percent
                        output[offset_output + k] = 100 * (endw / nmfreq[l]);
                    }
                    else if ( scode == -10 ) { // first
                        output[offset_output + k] = firstmiss[l];
                    }
                    else if ( scode == -11 ) { // firstnm
                        output[offset_output + k] = firstnm[l];
                    }
                    else if (scode == -12 ) { // last
                        output[offset_output + k] = lastmiss[l];
                    }
                    else if ( scode == -13 ) { // lastnm
                        output[offset_output + k] = lastnm[l];
                    }
                    else if ( scode == -18 ) { // nunique
                        if ( (rc = gf_array_nunique_range (
                                output + offset_output + k,
                                all_buffer + start,
                                nj,
                                (endwraw == SV_missval),
                                nuniq_h1,
                                nuniq_h2,
                                nuniq_h3,
                                nuniq_ix,
                                nuniq_xcopy
                            )
                        ) ) return (rc);
                    }
                    else if ( scode > 1000 ) { // #th smallest
                        sth = (GT_int) (floor(scode) - 1000);
                        rawsth = (GT_int) (ceil(scode) - 1000);
                        if ( rawsth == sth ) {
                            output[offset_output + k] = gf_array_dselect_weighted(
                                all_buffer + start,
                                nj,
                                weights + offset_weight,
                                (ST_double) sth,
                                all_wsum[startw],
                                all_xcount[startw],
                                p_buffer
                            );
                        }
                        else {
                            output[offset_output + k] = gf_array_dselect_unweighted(
                                all_buffer + start,
                                nj,
                                sth - 1,
                                all_xcount[startw],
                                p_buffer
                            );
                        }
                    }
                    else if ( scode < -1000 ) { // #th largest
                        sth = (GT_int) (ceil(scode) + 1000);
                        rawsth = (GT_int) (floor(scode) + 1000);
                        if ( rawsth == sth ) {
                            output[offset_output + k] = gf_array_dselect_weighted(
                                all_buffer + start,
                                nj,
                                weights + offset_weight,
                                (ST_double) sth,
                                all_wsum[startw],
                                all_xcount[startw],
                                p_buffer
                            );
                        }
                        else {
                            snj = (GT_int) (all_xcount[startw] > 0? all_xcount[startw]: nj);
                            sth = (GT_int) (snj + 1000 + ceil(scode));
                            output[offset_output + k] = gf_array_dselect_unweighted(
                                all_buffer + start,
                                nj,
                                sth,
                                all_xcount[startw],
                                p_buffer
                            );
                        }
                    }
                    else if ( endwraw == SV_missval ) { // all missing values
                        if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                            output[offset_output + k] = 0;
                        }
                        else if ( scode == -4 ) { // max
                            output[offset_output + k] = gf_array_dmax_range (all_buffer + start, 0, nj);
                        }
                        else if ( scode == -5 ) { // min
                            output[offset_output + k] = gf_array_dmin_range (all_buffer + start, 0, nj);
                        }
                        else {
                            output[offset_output + k] = SV_missval;
                        }
                    }
                    else if ( scode == -206 ) { // sum_w
                        output[offset_output + k] = endwraw;
                    }
                    else if ( scode == -203 ) { // Var (assumes prior stat was sd)
                        output[offset_output + k] = (output[offset_output + k - 1]) * (output[offset_output + k - 1]);
                    }
                    else {
                        output[offset_output + k] = gf_switch_fun_code_w (
                            scode,
                            all_buffer + start,
                            nj,
                            weights + offset_weight,
                            all_xwsum[startw],
                            all_wsum[startw],
                            all_xcount[startw],
                            aweights,
                            p_buffer
                        );
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.3: Computed summary stats");

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Generated output array");

    if ( st_info->summarize_colvar ) {
        ST_double *transpose = calloc(J * ktargets * ksources, sizeof *transpose);
        if ( transpose == NULL ) return(sf_oom_error("sf_stats_summarize", "transpose"));

        for (j = 0; j < J; j++) {
            for (k = 0; k < ktargets; k++) {
                offset_buffer = j * ktargets * ksources + k * ksources;
                for (l = 0; l < ksources; l++) {
                    offset_output = j * ktargets * ksources + l * ktargets;
                    transpose[offset_buffer + l] = output[offset_output + k];
                }
            }
        }
        fhandle = fopen(fname, "wb");
        rc = (fwrite(transpose, sizeof(transpose), J * ktargets * ksources, fhandle) != (J * ktargets * ksources));
        fclose (fhandle);

        free(transpose);
    }
    else {
        fhandle = fopen(fname, "wb");
        rc = (fwrite(output, sizeof(output), J * ktargets * ksources, fhandle) != (J * ktargets * ksources));
        fclose (fhandle);
    }

    if ( rc ) {
        sf_errprintf("unable to write output to disk\n");
        rc = 198;
        goto exit;
    }

exit:

    free (pos_sources);
    free (statcode);
    free (index_st);

    free (nuniq_h1);
    free (nuniq_h2);
    free (nuniq_h3);
    free (nuniq_ix);
    free (nuniq_xcopy);

    free (p_buffer);
    free (weights);
    free (nbuffer);

    free (all_buffer);
    free (all_wsum);
    free (all_xwsum);
    free (all_xcount);
    free (offsets_buffer);
    free (nj_buffer);

    free (nmfreq);
    free (firstmiss);
    free (lastmiss);
    free (firstnm);
    free (lastnm);

    return (rc);
}
