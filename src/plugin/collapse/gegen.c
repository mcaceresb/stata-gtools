int sf_egen_bulk             (struct StataInfo *st_info, int level);
int sf_write_output          (struct StataInfo *st_info, int level, size_t wtargets, char *fname);
int sf_write_collapsed       (struct StataInfo *st_info, int level, size_t wtargets, char *fname);
int sf_read_collapsed        (size_t J, size_t kextra, char *fname);
int sf_egen_multiple_sources (struct StataInfo *st_info, int level);
int sf_write_byvars          (struct StataInfo *st_info, int level);

/**
 * @brief egen stata variables in bulk
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores egen data in Stata
 */
int sf_egen_bulk (struct StataInfo *st_info, int level)
{

    if ( st_info->kvars_targets < 1 ) {
        return (0);
    }

    short multiple_sources = (st_info->kvars_sources > 1);
    short one_target = (st_info->kvars_targets == 1)
                  || ( (st_info->kvars_targets == 2) & (st_info->statcode[1] == -14) );

    if ( multiple_sources & one_target ) {
        return (sf_egen_multiple_sources (st_info, level));
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    int i, j, k, l;
    size_t nj, start, end, sel;
    size_t offset_output,
           offset_source,
           offset_buffer;

    clock_t timer = clock();

    size_t N = st_info->N;
    size_t J = st_info->J;

    size_t kvars         = st_info->kvars_by;
    size_t ksources      = st_info->kvars_sources;
    size_t ktargets      = st_info->kvars_targets;
    size_t start_sources = kvars + st_info->kvars_group + 1;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    size_t *pos_sources = calloc(ksources, sizeof *pos_sources);
    double *statcode    = calloc(ktargets, sizeof *statcode);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_egen_bulk", "pos_sources"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < st_info->kvars_stats; k++)
        statcode[k] = st_info->statcode[k];

    st_info->output = calloc(J * ktargets, sizeof st_info->output);
    if ( st_info->output == NULL ) return(sf_oom_error("sf_egen_bulk", "st_info->output"));

    ST_GC_ALLOCATED("st_info->output")
    double *output  = st_info->output;
    st_info->free = 9;

    double *all_buffer     = calloc(N * ksources, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(J * ksources, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(J * ksources, sizeof *all_lastmiss);
    size_t *all_nonmiss    = calloc(J * ksources, sizeof *all_nonmiss);
    size_t *all_yesmiss    = calloc(J * ksources, sizeof *all_yesmiss);
    size_t *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    size_t *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_egen_bulk", "output"));
    if ( all_firstmiss  == NULL ) return(sf_oom_error("sf_egen_bulk", "all_firstmiss"));
    if ( all_lastmiss   == NULL ) return(sf_oom_error("sf_egen_bulk", "all_lastmiss"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_egen_bulk", "all_nonmiss"));
    if ( all_yesmiss    == NULL ) return(sf_oom_error("sf_egen_bulk", "all_yesmiss"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_egen_bulk", "offsets_buffer"));

    for (j = 0; j < J * ksources; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = all_yesmiss[j] = 0;

    size_t *nmfreq = calloc(ksources, sizeof *nmfreq);
    if ( nmfreq == NULL ) return(sf_oom_error("sf_egen_bulk", "nmfreq"));

    for (k = 0; k < ksources; k++)
        nmfreq[k] = 0;

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.0: Allocated memory");

    double *firstmiss = calloc(ksources, sizeof *firstmiss);
    double *lastmiss  = calloc(ksources, sizeof *lastmiss);
    double *firstnm   = calloc(ksources, sizeof *firstnm);
    double *lastnm    = calloc(ksources, sizeof *lastnm);

    if ( firstmiss == NULL ) return(sf_oom_error("sf_egen_bulk", "firstmiss"));
    if ( lastmiss  == NULL ) return(sf_oom_error("sf_egen_bulk", "lastmiss"));
    if ( firstnm   == NULL ) return(sf_oom_error("sf_egen_bulk", "firstnm"));
    if ( lastnm    == NULL ) return(sf_oom_error("sf_egen_bulk", "lastnm"));

    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    // Method 1: Continuously from Stata
    // ---------------------------------

    /*
     * The following maps the C group index to Stata so we can read
     * observations from Stata in order; this is only sometimes faster,
     */

    size_t *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_collapse", "index_st"));

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
            // Read Stata in order
            if ( (rc = SF_vdata(pos_sources[k], i + st_info->in1, &z)) ) goto exit;
            if ( SF_is_missing(z) ) {
                if ( i == st_info->index[start]   ) all_firstmiss[offset_source + k] = 1;
                if ( i == st_info->index[end - 1] ) all_lastmiss[offset_source + k]  = 1;
                all_buffer [offset_buffer + nj * k + (nj - all_yesmiss[offset_source + k]++ - 1)] = z;
            }
            else {
                // Read into C in order as well, via index_st, so non-missing
                // entries of given variable for each group occupy a contiguous
                // segment in memory.
                all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables sequentially");

    /*********************************************************************
     *                Step 4: Collapse variables by gorup                *
     *********************************************************************/

    // short multiple_sources = (ktargets == 1) || ( (ktargets == 2) & (statcode[1] == -14) );

    for (j = 0; j < J; j++)
        for (k = 0; k < ksources; k++)
            nmfreq[k] += all_nonmiss[j * ksources + k];

    {
        for (j = 0; j < J; j++) {

            // Remember we read things in group sort order but info and index
            // are in hash sort order, so the jth output corresponds to the
            // st_info->ix[j]th source
            offset_output = j * ktargets;
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
                    firstnm[k]  = all_buffer[start];
                    lastnm[k]   = all_buffer[start + end - 1];
                    firstmiss[k] = all_buffer[start + nj - 1];
                    lastmiss[k]  = all_buffer[start + end];
                }
                else { // none are missing; first/last are same
                    firstmiss[k] = firstnm[k] = all_buffer[start];
                    lastmiss[k]  = lastnm[k]  = all_buffer[start + end - 1];
                }
            }

            for (k = 0; k < ktargets; k++) {
                // For each target, grab start and end position of source variable
                sel   = offset_source + st_info->pos_targets[k];
                start = offset_buffer + nj * st_info->pos_targets[k];
                end   = all_nonmiss[sel];

                // If there is at least one non-missing observation, we store
                // the result in output. If all observations are missing then
                // we store Stata's special SV_missval
                if ( statcode[k] == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    output[offset_output + k] = end;
                }
                else if ( statcode[k] == -14 ) { // freq
                    output[offset_output + k] = nj;
                }
                else if ( statcode[k] == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we divide
                    // by this when writing to Stata.
                    output[offset_output + k] = 100 * ((double) end / nmfreq[st_info->pos_targets[k]]);
                }
                else if ( statcode[k] == -10 ) { // first
                    // If first obs is missing, get first missing value that
                    // appeared; otherwise get first non-missing value
                    output[offset_output + k] = all_firstmiss[sel]? firstmiss[st_info->pos_targets[k]]: firstnm[st_info->pos_targets[k]];
                }
                else if ( statcode[k] == -11 ) { // firstnm
                    // First non-missing is the first entry in the inputs buffer;
                    // this is only missing if all are missing.
                    output[offset_output + k] = firstnm[st_info->pos_targets[k]];
                }
                else if (statcode[k] == -12 ) { // last
                    // If last obs is missing, get last missing value that
                    // appeared; otherwise get last non-missing value
                    output[offset_output + k] = all_lastmiss[sel]? lastmiss[st_info->pos_targets[k]]: lastnm[st_info->pos_targets[k]];
                }
                else if ( statcode[k] == -13 ) { // lastnm
                    // Last non-missing is the last entry in the inputs buffer;
                    // this is only missing is all are missing.
                    output[offset_output + k] = lastnm[st_info->pos_targets[k]];
                }
                else if ( end == 0 ) { // no obs
                    // If everything is missing, write a missing value, Except
                    // for sums, which go to 0 for some reason (this is the
                    // behavior of collapse), and min/max (which pick out the
                    // min/max missing value).
                    if ( statcode[k] == -1 ) { // sum
                        output[offset_output + k] = 0;
                    }
                    else if ( (statcode[k] == -4) || (statcode[k] == -5) ) { // min/max
                        // min/max handle missings b/c they only do comparisons
                        output[offset_output + k] = mf_switch_fun_code (statcode[k], all_buffer, start, start + nj);
                    }
                    else {
                        output[offset_output + k] = SV_missval;
                    }
                }
                else if ( (statcode[k] == -3) &  (end < 2) ) { // sd
                    // Standard deviation requires at least 2 observations
                    output[offset_output + k] = SV_missval;
                }
                else { // etc
                    // Otherwise compute the requested summary stat
                    output[offset_output + k] = mf_switch_fun_code (statcode[k], all_buffer, start, start + end);
                }
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Computed summary stats");

exit:

    free (pos_sources);
    free (statcode);

    free (index_st);

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

int sf_egen_multiple_sources (struct StataInfo *st_info, int level)
{

    if ( st_info->kvars_targets < 1 ) {
        return (0);
    }

    // if ( st_info->kvars_targets > 1 ) {
    //     sf_egen_bulk (st_info, level);
    // }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    int i, j, k, l;
    size_t nj, start, end;
    size_t offset_output,
           offset_buffer;

    clock_t timer = clock();

    size_t N = st_info->N;
    size_t J = st_info->J;

    size_t kvars         = st_info->kvars_by;
    size_t ksources      = st_info->kvars_sources;
    size_t ktargets      = st_info->kvars_targets;
    size_t start_sources = kvars + st_info->kvars_group + 1;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    size_t *pos_sources = calloc(ksources, sizeof *pos_sources);
    double *statcode    = calloc(ktargets, sizeof *statcode);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_egen_bulk", "pos_sources"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < st_info->kvars_stats; k++)
        statcode[k] = st_info->statcode[k];

    st_info->output = calloc(J * ktargets, sizeof st_info->output);
    if ( st_info->output == NULL ) return(sf_oom_error("sf_egen_bulk", "st_info->output"));

    ST_GC_ALLOCATED("st_info->output")
    double *output  = st_info->output;
    st_info->free = 9;

    double *all_buffer     = calloc(N * ksources, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(J, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(J, sizeof *all_lastmiss);
    size_t *all_nonmiss    = calloc(J, sizeof *all_nonmiss);
    size_t *all_yesmiss    = calloc(J, sizeof *all_yesmiss);
    size_t *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    size_t *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_egen_bulk", "output"));
    if ( all_firstmiss  == NULL ) return(sf_oom_error("sf_egen_bulk", "all_firstmiss"));
    if ( all_lastmiss   == NULL ) return(sf_oom_error("sf_egen_bulk", "all_lastmiss"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_egen_bulk", "all_nonmiss"));
    if ( all_yesmiss    == NULL ) return(sf_oom_error("sf_egen_bulk", "all_yesmiss"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_egen_bulk", "offsets_buffer"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_egen_bulk", "nj_buffer"));

    for (j = 0; j < J; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = all_yesmiss[j] = 0;

    size_t *nmfreq    = calloc(1, sizeof *nmfreq);
    if ( nmfreq    == NULL ) return(sf_oom_error("sf_egen_bulk", "nmfreq"));

    nmfreq[0] = 0;

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.0: Allocated memory");

    double *firstmiss = calloc(1, sizeof *firstmiss);
    double *lastmiss  = calloc(1, sizeof *lastmiss);
    double *firstnm   = calloc(1, sizeof *firstnm);
    double *lastnm    = calloc(1, sizeof *lastnm);

    if ( firstmiss == NULL ) return(sf_oom_error("sf_egen_bulk", "firstmiss"));
    if ( lastmiss  == NULL ) return(sf_oom_error("sf_egen_bulk", "lastmiss"));
    if ( firstnm   == NULL ) return(sf_oom_error("sf_egen_bulk", "firstnm"));
    if ( lastnm    == NULL ) return(sf_oom_error("sf_egen_bulk", "lastnm"));

    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    // Method 1: Continuously from Stata
    // ---------------------------------

    /*
     * The following maps the C group index to Stata so we can read
     * observations from Stata in order; this is only sometimes faster,
     */

    size_t *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_collapse", "index_st"));

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
                // Read into C in order as well, via index_st, so non-missing
                // entries of given variable for each group occupy a contiguous
                // segment in memory.
                all_buffer [start * ksources + all_nonmiss[j]++] = z;
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables sequentially");

    /*********************************************************************
     *                Step 4: Collapse variables by gorup                *
     *********************************************************************/

    // short multiple_sources = (ktargets == 1) || ( (ktargets == 2) & (statcode[1] == -14) );

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

            for (k = 0; k < ktargets; k++) {
                // If there is at least one non-missing observation, we store
                // the result in output. If all observations are missing then
                // we store Stata's special SV_missval
                if ( statcode[k] == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    output[offset_output + k] = end;
                }
                else if ( statcode[k] == -14 ) { // freq
                    output[offset_output + k] = nj * ksources;
                }
                else if ( statcode[k] == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we divide
                    // by this when writing to Stata.
                    output[offset_output + k] = 100 * ((double) end / nmfreq[0]);
                }
                else if ( statcode[k] == -10 ) { // first
                    // If first obs is missing, get first missing value that
                    // appeared; otherwise get first non-missing value
                    output[offset_output + k] = all_firstmiss[j]? firstmiss[0]: firstnm[0];
                }
                else if ( statcode[k] == -11 ) { // firstnm
                    // First non-missing is the first entry in the inputs buffer;
                    // this is only missing if all are missing.
                    output[offset_output + k] = firstnm[0];
                }

                else if (statcode[k] == -12 ) { // last
                    // If last obs is missing, get last missing value that
                    // appeared; otherwise get last non-missing value
                    output[offset_output + k] = all_lastmiss[j]? lastmiss[0]: lastnm[0];
                }
                else if ( statcode[k] == -13 ) { // lastnm
                    // Last non-missing is the last entry in the inputs buffer;
                    // this is only missing is all are missing.
                    output[offset_output + k] = lastnm[0];
                }
                else if ( end == 0 ) { // no obs
                    // If everything is missing, write a missing value, Except
                    // for sums, which go to 0 for some reason (this is the
                    // behavior of collapse), and min/max (which pick out the
                    // min/max missing value).
                    if ( statcode[k] == -1 ) { // sum
                        output[offset_output + k] = 0;
                    }
                    else if ( (statcode[k] == -4) || (statcode[k] == -5) ) { // min/max
                        // min/max handle missings b/c they only do comparisons
                        output[offset_output + k] = mf_switch_fun_code (statcode[k], all_buffer, start, start + nj * ksources);
                    }
                    else {
                        output[offset_output + k] = SV_missval;
                    }
                }
                else if ( (statcode[k] == -3) &  (end < 2) ) { // sd
                    // Standard deviation requires at least 2 observations
                    output[offset_output + k] = SV_missval;
                }
                else { // etc
                    // Otherwise compute the requested summary stat
                    output[offset_output + k] = mf_switch_fun_code (statcode[k], all_buffer, start, start + end);
                }
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Computed summary stats");

exit:

    free (pos_sources);
    free (statcode);

    free (index_st);

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

int sf_write_output (struct StataInfo *st_info, int level, size_t wtargets, char *fname)
{

    if ( st_info->kvars_targets < 1 ) {
        return (0);
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    int i, j, k, l;
    size_t start, end, out, within, missval;
    clock_t timer = clock();

    size_t kvars         = st_info->kvars_by;
    size_t ksources      = st_info->kvars_sources;
    size_t ktargets      = st_info->kvars_targets;
    size_t start_sources = kvars + st_info->kvars_group + 1;
    size_t start_targets = start_sources + ksources;

    size_t *pos_targets = calloc(ktargets, sizeof *pos_targets);
    if ( pos_targets == NULL ) return(sf_oom_error("sf_egen_bulk", "pos_targets"));

    for (k = 0; k < ktargets; k++)
        pos_targets[k] = start_targets + k;

    if ( st_info->init_targ ) {
        for (i = 1; i <= SF_nobs(); i++) {
            for (k = 0; k < wtargets; k++) {
                if ( (rc = SF_vstore(pos_targets[k], i, SV_missval)) ) goto exit;
            }
        }
    }

    within   = (st_info->group_data == 0);
    missval  = (st_info->group_fill == 1);
    if ( within ) {
        for (j = 0; j < st_info->J; j++) {
            l     = st_info->ix[j];
            start = st_info->info[l];
            end   = st_info->info[l + 1];
            for (i = start; i < (missval? (start + 1): end); i++) {
                out = st_info->index[i] + st_info->in1;
                for (k = 0; k < ktargets; k++) {
                    z = st_info->output[j * ktargets + k];
                    if ( (rc = SF_vstore(pos_targets[k], out, z)) ) goto exit;
                }
            }
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < wtargets; k++) {
                if ( (rc = SF_vstore(pos_targets[k],
                                     j + 1,
                                     st_info->output[j * ktargets + k])) ) goto exit;
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied summary stats to stata");

    if ( (wtargets < ktargets) & (level == 2) & (within == 0) ) {
        size_t kextra = ktargets - wtargets;
        FILE *fhandle = fopen(fname, "wb");

        for (j = 0; j < st_info->J; j++) {
            fwrite (st_info->output + j * ktargets + wtargets,
                    sizeof(st_info->output), kextra, fhandle);
        }

        fclose (fhandle);

        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 7: Copied some targets to disk");
    }

exit:
    free (pos_targets);
    return (rc);
}

int sf_write_collapsed (struct StataInfo *st_info, int level, size_t wtargets, char *fname)
{

    if ( st_info->kvars_targets < 1 ) {
        return (0);
    }

    if ( st_info->kvars_by == 0 ) {
        return (sf_write_output (st_info, level, wtargets, fname));
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    int j, k;
    size_t sel, rowbytes;
    clock_t timer = clock();

    size_t kvars         = st_info->kvars_by;
    size_t ksources      = st_info->kvars_sources;
    size_t ktargets      = st_info->kvars_targets;
    size_t start_sources = kvars + st_info->kvars_group + 1;
    size_t start_targets = start_sources + ksources;

    size_t *pos_targets = calloc(ktargets, sizeof *pos_targets);
    if ( pos_targets == NULL ) return(sf_oom_error("sf_egen_bulk", "pos_targets"));

    for (k = 0; k < ktargets; k++)
        pos_targets[k] = start_targets + k;

    /*********************************************************************
     *                        Collapse to memory                         *
     *********************************************************************/

    rowbytes = (st_info->rowbytes + sizeof(int));
    if ( st_info->kvars_by_str > 0 ) {
        for (j = 0; j < st_info->J; j++) {
            if ( level != 11 ) {
                for (k = 0; k < kvars; k++) {
                    sel = j * rowbytes + st_info->positions[k];
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sstore(k + 1, j + 1, st_info->st_by_charx + sel)) ) goto exit;
                    }
                    else {
                        z = *((double *) (st_info->st_by_charx + sel));
                        if ( (rc = SF_vstore(k + 1, j + 1, z)) ) goto exit;
                    }
                }
            }

            for (k = 0; k < wtargets; k++) {
                if ( (rc = SF_vstore(pos_targets[k],
                                     j + 1,
                                     st_info->output[j * ktargets + k])) ) goto exit;
            }
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            if ( level != 11 ) {
                for (k = 0; k < kvars; k++) {
                    if ( (rc = SF_vstore(k + 1,
                                         j + 1,
                                         st_info->st_by_numx[j * (kvars + 1) + k])) ) goto exit;
                }
            }

            for (k = 0; k < wtargets; k++) {
                if ( (rc = SF_vstore(pos_targets[k],
                                     j + 1,
                                     st_info->output[j * ktargets + k])) ) goto exit;
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied collapsed data to stata");

    /*********************************************************************
     *                         Collapse to disk                          *
     *********************************************************************/

    if ( (wtargets < ktargets) & (level == 2) ) {
        size_t kextra = ktargets - wtargets;
        FILE *fhandle = fopen(fname, "wb");

        for (j = 0; j < st_info->J; j++) {
            fwrite (st_info->output + j * ktargets + wtargets,
                    sizeof(st_info->output), kextra, fhandle);
        }

        fclose (fhandle);

        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 7: Copied some targets to disk");
    }


exit:
    free (pos_targets);
    return (rc);
}

int sf_write_byvars (struct StataInfo *st_info, int level)
{

    if ( st_info->kvars_by == 0 ) {
        return (0);
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    int j, k;
    size_t sel, rowbytes;
    clock_t timer = clock();
    size_t kvars  = st_info->kvars_by;

    /*********************************************************************
     *                        Collapse to memory                         *
     *********************************************************************/

    rowbytes = (st_info->rowbytes + sizeof(int));
    if ( (st_info->kvars_by_str > 0) & (level != 11) ) {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < kvars; k++) {
                sel = j * rowbytes + st_info->positions[k];
                if ( st_info->byvars_lens[k] > 0 ) {
                    if ( (rc = SF_sstore(k + 1, j + 1, st_info->st_by_charx + sel)) ) goto exit;
                }
                else {
                    z = *((double *) (st_info->st_by_charx + sel));
                    if ( (rc = SF_vstore(k + 1, j + 1, z)) ) goto exit;
                }
            }
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < kvars; k++) {
                if ( (rc = SF_vstore(k + 1,
                                     j + 1,
                                     st_info->st_by_numx[j * (kvars + 1) + k])) ) goto exit;
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied by variables back to stata");

exit:
    return (rc);
}

int sf_read_collapsed (size_t J, size_t kextra, char *fname)
{
    if ( kextra < 1 ) {
        return (0);
    }

    int j, k;
    ST_retcode rc = 0;

    double *output = calloc(J * kextra, sizeof *output);
    if ( output == NULL ) return(sf_oom_error("stata_call", "output"));

    mf_read_collapsed (fname, output, kextra, J);

    for (j = 0; j < J; j++) {
        for (k = 0; k < kextra; k++) {
            if ( (rc = SF_vstore(k + 1, j + 1, output[j * kextra + k])) ) goto exit;
        }
    }

exit:
    free (output);
    return (rc);
}
