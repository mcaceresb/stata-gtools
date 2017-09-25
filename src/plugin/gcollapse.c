/*+******************************************************************
 * Program: gcollapse.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Thu Jun 15 15:54:37 EDT 2017
 * Purpose: Stata plugin to compute a faster -collapse-
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.6.17
 *********************************************************************/

#include "gcollapse.h"
#include "quicksortMultiLevel.c"

/**
 * @brief Collapse stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores collapsed data in Stata
 */
int sf_collapse (struct StataInfo *st_info, int action, char *fname)
{
    ST_double  z;
    ST_retcode rc ;
    int i, j, k;
    clock_t timer = clock();
    // char *s; s = malloc(st_info->strmax * sizeof(char));

    size_t kvars, nj, start, end, sel, out;
    size_t offset_output,
           offset_source,
           offset_buffer,
           offset_bystr;

    size_t nmfreq[st_info->kvars_source],
           nonmiss[st_info->kvars_source],
           firstmiss[st_info->kvars_source],
           lastmiss[st_info->kvars_source];

    // qselect modifies the input array, meaning if it is invoked before
    // first, last, firstnm, or lastnm, the first observation that
    // appeared for that gorup will not be the first observation in the
    // corresponding segment of the input buffer. The fix is to simply
    // read the frist and last entries to a temporary variable before
    // applying any of the summary stats
    double firstobs[st_info->kvars_source],
           lastobs[st_info->kvars_source];

    // Initialize by variables
    // -----------------------

    // bynum, bystr, output
    MixedUnion *st_dtax;
    double *output;
    double *st_numx;

    kvars = (st_info->kvars_by + st_info->kvars_targets);
    if ( st_info->merge ) {
        st_dtax = malloc(sizeof(MixedUnion));
        st_numx = malloc(sizeof(double));
        output  = calloc(st_info->kvars_targets * st_info->J, sizeof *output);
        if ( output  == NULL ) return(sf_oom_error("sf_collapse", "output"));
    }
    else if ( st_info->kvars_by_str > 0 ) {
        st_dtax = calloc(kvars * st_info->J, sizeof *st_dtax);
        if ( st_dtax == NULL ) return (sf_oom_error("sf_collapse", "st_dtax"));
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < st_info->kvars_by_str; k++) {
                sel = j * kvars + (st_info->pos_str_byvars[k] - 1);
                offset_bystr = st_info->byvars_lens[st_info->pos_str_byvars[k] - 1];
                if ( offset_bystr > 0 ) {
                    st_dtax[sel].cval = malloc((offset_bystr + 1) * sizeof(char));
                    if ( st_dtax[sel].cval == NULL ) return (sf_oom_error("sf_collapse", "st_dtax[sel].cval"));
                    memset (st_dtax[sel].cval, '\0', offset_bystr + 1);
                }
                else {
                    sf_errprintf ("Unable to parse string lengths from Stata.\n");
                    return (198);
                }
            }
        }
        st_numx = malloc(sizeof(double));
        output  = malloc(sizeof(double));
    }
    else {
        st_dtax = malloc(sizeof(MixedUnion));
        output  = malloc(sizeof(double));
        st_numx = calloc(kvars * st_info->J, sizeof *st_numx);
        if ( st_numx  == NULL ) return(sf_oom_error("sf_collapse", "st_numx"));
    }

    // Initialize variables for use in read, collapse, and write loops
    // ---------------------------------------------------------------

    double *all_buffer     = calloc(st_info->kvars_source * st_info->N, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(st_info->kvars_source * st_info->J, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(st_info->kvars_source * st_info->J, sizeof *all_lastmiss );
    size_t *all_nonmiss    = calloc(st_info->kvars_source * st_info->J, sizeof *all_nonmiss);
    size_t *offsets_buffer = calloc(st_info->J, sizeof *offsets_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_collapse", "all_buffer"));
    if ( all_firstmiss  == NULL ) return(sf_oom_error("sf_collapse", "all_firstmiss"));
    if ( all_lastmiss   == NULL ) return(sf_oom_error("sf_collapse", "all_lastmiss"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_collapse", "all_nonmiss"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_collapse", "offsets_buffer"));

    double statcode[st_info->kvars_targets], dblstat;
    // char *stat[st_info->kvars_targets];
    char *strstat, *ptr;
    strstat = strtok_r (st_info->statstr, " ", &ptr);
    for (k = 0; k < st_info->kvars_targets; k++) {
        dblstat = mf_code_fun (strstat);
        if ( dblstat == 0 ) {
            sf_errprintf ("C doesn't know stat ");
            sf_errprintf (strstat);
            sf_errprintf ("; Stata parsing failed!\n");
            return (198);
        }
        statcode[k] = dblstat;
        // stat[k]  = strstat;
        strstat     = strtok_r (NULL, " ", &ptr);
    }

    for (k = 0; k < st_info->kvars_source; k++)
        nmfreq[k] = nonmiss[k] = firstmiss[k] = lastmiss[k] = 0;

    for (j = 0; j < st_info->J * st_info->kvars_source; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = 0;

    // Read in variables from Stata
    // ----------------------------

    int rct = 0;

    // Method 1: Continuously from Stata
    // ---------------------------------

    /*
     * The following maps the C group index to Stata so we can read
     * observations from Stata in order; this is only sometimes faster,
     */
    size_t *index_st = calloc(st_info->N, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_collapse", "index_st"));
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        offsets_buffer[j] = start * st_info->kvars_source;
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = j;
    }

    rct = offset_buffer = offset_source = 0;
    for (i = 0; i < st_info->N; i++) {
        j     = index_st[i];
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        nj    = end - start;
        offset_buffer = start * st_info->kvars_source;
        offset_source = j * st_info->kvars_source;
        for (k = 0; k < st_info->kvars_source; k++) {
            // Read Stata in order
            if ( (rc = SF_vdata(k + st_info->start_collapse_vars, i + st_info->in1, &z)) ) {
                rct = rc;
                continue;
            }
            if ( SF_is_missing(z) ) {
                if ( i == st_info->index[start] )   all_firstmiss[offset_source + k] = 1;
                if ( i == st_info->index[end - 1] ) all_lastmiss[offset_source + k]  = 1;
            }
            else {
                // Read into C in order as well, via index_st, so
                // non-missing entries of given variable for each group
                // occupy a contiguous segment in memory.
                all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
            }
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables sequentially");
    if ( rct ) return (rct);
    free (index_st);

    // Collapse variables by group
    // ---------------------------

    for (j = 0; j < st_info->J; j++)
        for (k = 0; k < st_info->kvars_source; k++)
            nmfreq[k] += all_nonmiss[j * st_info->kvars_source + k];

    if ( st_info->merge ) {
        // We encoded stat string; see mf_code_fun in gtools_math.c
        for (j = 0; j < st_info->J; j++) {
            offset_output = j * st_info->kvars_targets;
            offset_source = j * st_info->kvars_source;
            offset_buffer = offsets_buffer[j];
            nj = st_info->info[j + 1] - st_info->info[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            for (k = 0; k < st_info->kvars_source; k++) {
                sel   = offset_source + k;
                start = offset_buffer + nj * k;
                end   = all_nonmiss[sel];
                firstobs[k] = all_buffer[start];
                lastobs[k]  = all_buffer[start + end - 1];
            }

            for (k = 0; k < st_info->kvars_targets; k++) {
                // For each target, grab start and end position of source variable
                sel   = offset_source + st_info->pos_targets[k];
                start = offset_buffer + nj * st_info->pos_targets[k];
                end   = all_nonmiss[sel];

                // If there is at least one non-missing observation, we
                // store the result in output. If all observations are
                // missing then we store Stata's special SV_missval
                if ( statcode[k] == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    output[offset_output + k] = end;
                }
                else if ( statcode[k] == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we
                    // divide by this when writing to Stata.
                    output[offset_output + k] = 100 * ((double) end / nmfreq[st_info->pos_targets[k]]);
                }
                else if ( end == 0 ) { // no obs
                    // If everything is missing, write a missing value,
                    // Except for sums, which go to 0 for some reason (this
                    // is the behavior of collapse).
                    if ( statcode[k] == -1 ) {
                        output[offset_output + k] = 0;
                    }
                    else {
                        output[offset_output + k] = SV_missval;
                    }
                }
                else if ( all_firstmiss[sel] & (statcode[k] == -10) ) { // first
                    // If first observation is missing, will write missing value
                    output[offset_output + k] = SV_missval;
                }
                else if ( (statcode[k] == -10) | (statcode[k] == -11) ) { // first|firstnm
                    // First obs/first non-missing is the first entry in the inputs buffer
                    output[offset_output + k] = firstobs[st_info->pos_targets[k]];
                }
                else if ( all_lastmiss[sel] & (statcode[k] == -12) ) { // last
                    // If last observation is missing, will write missing value
                    output[offset_output + k] = SV_missval;
                }
                else if ( (statcode[k] == -12) | (statcode[k] == -13) ) { // last|lastnm
                    // Last obs/last non-missing is the last entry in the inputs buffer
                    output[offset_output + k] = lastobs[st_info->pos_targets[k]];
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
    else if ( st_info->kvars_by_str > 0 ) {
        // We encoded stat string; see mf_code_fun in gtools_math.c
        for (j = 0; j < st_info->J; j++) {
            // offset_output = j * st_info->kvars_targets;
            offset_output = j * kvars + st_info->kvars_by;
            offset_source = j * st_info->kvars_source;
            offset_buffer = offsets_buffer[j];
            nj = st_info->info[j + 1] - st_info->info[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            for (k = 0; k < st_info->kvars_source; k++) {
                sel   = offset_source + k;
                start = offset_buffer + nj * k;
                end   = all_nonmiss[sel];
                firstobs[k] = all_buffer[start];
                lastobs[k]  = all_buffer[start + end - 1];
            }

            for (k = 0; k < st_info->kvars_targets; k++) {
                // For each target, grab start and end position of source variable
                sel   = offset_source + st_info->pos_targets[k];
                start = offset_buffer + nj * st_info->pos_targets[k];
                end   = all_nonmiss[sel];

                // If there is at least one non-missing observation, we
                // store the result in output. If all observations are
                // missing then we store Stata's special SV_missval
                if ( statcode[k] == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    st_dtax[offset_output + k].dval = end;
                }
                else if ( statcode[k] == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we
                    // divide by this when writing to Stata.
                    st_dtax[offset_output + k].dval = 100 * ((double) end / nmfreq[st_info->pos_targets[k]]);
                }
                else if ( end == 0 ) { // no obs
                    // If everything is missing, write a missing value,
                    // Except for sums, which go to 0 for some reason (this
                    // is the behavior of collapse).
                    if ( statcode[k] == -1 ) {
                        st_dtax[offset_output + k].dval = 0;
                    }
                    else {
                        st_dtax[offset_output + k].dval = SV_missval;
                    }
                }
                else if ( all_firstmiss[sel] & (statcode[k] == -10) ) { // first
                    // If first observation is missing, will write missing value
                    st_dtax[offset_output + k].dval = SV_missval;
                }
                else if ( (statcode[k] == -10) | (statcode[k] == -11) ) { // first|firstnm
                    // First obs/first non-missing is the first entry in the inputs buffer
                    st_dtax[offset_output + k].dval = firstobs[st_info->pos_targets[k]];
                }
                else if ( all_lastmiss[sel] & (statcode[k] == -12) ) { // last
                    // If last observation is missing, will write missing value
                    st_dtax[offset_output + k].dval = SV_missval;
                }
                else if ( (statcode[k] == -12) | (statcode[k] == -13) ) { // last|lastnm
                    // Last obs/last non-missing is the last entry in the inputs buffer
                    st_dtax[offset_output + k].dval = lastobs[st_info->pos_targets[k]];
                }
                else if ( (statcode[k] == -3) &  (end < 2) ) { // sd
                    // Standard deviation requires at least 2 observations
                    st_dtax[offset_output + k].dval = SV_missval;
                }
                else { // etc
                    // Otherwise compute the requested summary stat
                    st_dtax[offset_output + k].dval = mf_switch_fun_code (statcode[k], all_buffer, start, start + end);
                }
            }
        }
    }
    else {
        // We encoded stat string; see mf_code_fun in gtools_math.c
        for (j = 0; j < st_info->J; j++) {
            // offset_output = j * st_info->kvars_targets;
            offset_output = j * kvars + st_info->kvars_by;
            offset_source = j * st_info->kvars_source;
            offset_buffer = offsets_buffer[j];
            nj = st_info->info[j + 1] - st_info->info[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            for (k = 0; k < st_info->kvars_source; k++) {
                sel   = offset_source + k;
                start = offset_buffer + nj * k;
                end   = all_nonmiss[sel];
                firstobs[k] = all_buffer[start];
                lastobs[k]  = all_buffer[start + end - 1];
            }

            for (k = 0; k < st_info->kvars_targets; k++) {
                // For each target, grab start and end position of source variable
                sel   = offset_source + st_info->pos_targets[k];
                start = offset_buffer + nj * st_info->pos_targets[k];
                end   = all_nonmiss[sel];

                // If there is at least one non-missing observation, we
                // store the result in output. If all observations are
                // missing then we store Stata's special SV_missval
                if ( statcode[k] == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    st_numx[offset_output + k] = end;
                }
                else if ( statcode[k] == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we
                    // divide by this when writing to Stata.
                    st_numx[offset_output + k] = 100 * ((double) end / nmfreq[st_info->pos_targets[k]]);
                }
                else if ( end == 0 ) { // no obs
                    // If everything is missing, write a missing value,
                    // Except for sums, which go to 0 for some reason (this
                    // is the behavior of collapse).
                    if ( statcode[k] == -1 ) {
                        st_numx[offset_output + k] = 0;
                    }
                    else {
                        st_numx[offset_output + k] = SV_missval;
                    }
                }
                else if ( all_firstmiss[sel] & (statcode[k] == -10) ) { // first
                    // If first observation is missing, will write missing value
                    st_numx[offset_output + k] = SV_missval;
                }
                else if ( (statcode[k] == -10) | (statcode[k] == -11) ) { // first|firstnm
                    // First obs/first non-missing is the first entry in the inputs buffer
                    st_numx[offset_output + k] = firstobs[st_info->pos_targets[k]];
                }
                else if ( all_lastmiss[sel] & (statcode[k] == -12) ) { // last
                    // If last observation is missing, will write missing value
                    st_numx[offset_output + k] = SV_missval;
                }
                else if ( (statcode[k] == -12) | (statcode[k] == -13) ) { // last|lastnm
                    // Last obs/last non-missing is the last entry in the inputs buffer
                    st_numx[offset_output + k] = lastobs[st_info->pos_targets[k]];
                }
                else if ( (statcode[k] == -3) &  (end < 2) ) { // sd
                    // Standard deviation requires at least 2 observations
                    st_numx[offset_output + k] = SV_missval;
                }
                else { // etc
                    // Otherwise compute the requested summary stat
                    st_numx[offset_output + k] = mf_switch_fun_code (statcode[k], all_buffer, start, start + end);
                }
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Collapsed source variables");

    free (all_buffer);
    free (all_firstmiss);
    free (all_lastmiss);
    free (all_nonmiss);
    free (offsets_buffer);

    // Copy output back into Stata
    // ---------------------------

    if ( st_info->merge ) {
        // If merge is requested, leave source by variables unmodified
        // double output_buffer[st_info->kvars_targets];

        offset_output = 0;
        for (j = 0; j < st_info->J; j++) {
            start  = st_info->info[j];
            end    = st_info->info[j + 1];

            // for (k = 0; k < st_info->kvars_targets; k++) {
            //     sel = offset_output + k;
            //     if ( statcode[k] == -7 ) output[sel] /= nmfreq[st_info->pos_targets[k]];
            //     output_buffer[k] = output[sel];
            // }

            // Write the same value from start to end; we won't sort or
            // modify the input data, so the position of each value of
            // the jth group is index[i] for i = start to i < end.
            for (i = start; i < end; i++) {
                for (k = 0; k < st_info->kvars_targets; k++) {
                    out = st_info->index[i] + st_info->in1;
                    sel = offset_output + k;
                    // if ( statcode[k] == -7 ) output[sel] /= nmfreq[st_info->pos_targets[k]];
                    // if ( (rc = SF_vstore(k + st_info->start_target_vars, out, output_buffer[k])) ) return (rc);
                    if ( (rc = SF_vstore(k + st_info->start_target_vars, out, output[sel])) ) return (rc);
                }
            }
            offset_output += st_info->kvars_targets;
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Merged collapsed variables back to stata");
    }
    else {
        // Read in first entry of each group variable
        if ( st_info->kvars_by_str > 0 ) {
            // For mixed group variables, read into mixed array
            for (j = 0; j < st_info->J; j++) {
                start = st_info->info[j];
                for (k = 0; k < st_info->kvars_by; k++) {
                    sel = j * kvars + k;
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + 1, st_info->index[start] + st_info->in1, st_dtax[sel].cval)) ) return(rc);
                    }
                    else {
                        if ( (rc = SF_vdata(k + 1, st_info->index[start] + st_info->in1, &(st_dtax[sel].dval))) ) return(rc);
                    }
                }
            }
        }
        else {
            // For numeric variables, read into numeric array
            for (j = 0; j < st_info->J; j++) {
                start = st_info->info[j];
                for (k = 0; k < st_info->kvars_by; k++) {
                    if ( (rc = SF_vdata(k + 1, st_info->index[start] + st_info->in1, &(st_numx[j * kvars + k]))) ) return(rc);
                }
            }
        }

        // Sort in memory
        // --------------

        st_info->sort_memory = !st_info->integers_ok;
        if ( st_info->sort_memory ) {
            st_info->invert = calloc(st_info->kvars_by, sizeof st_info->invert);
            if ( st_info->invert == NULL ) return(sf_oom_error("sf_parse_info", "st_info->invert"));
            for (k = 0; k < st_info->kvars_by; k++)
                st_info->invert[k] = 0;

            if ( st_info->kvars_by_str > 0 ) {
                MultiQuicksort (st_dtax, st_info->J, 0, st_info->kvars_by - 1, kvars * sizeof(*st_dtax), st_info->byvars_lens, st_info->invert);
            }
            else {
                MultiQuicksort2 (st_numx, st_info->J, 0, st_info->kvars_by - 1, kvars * sizeof(*st_numx), st_info->byvars_lens, st_info->invert);
            }

            free(st_info->invert);
            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.3: Read by variables and sorted");
        }

        // Collapse back to memory or write to disk
        // ----------------------------------------

        if ( action == 0 ) {
            if ( st_info->kvars_by_str > 0 ) {
                for (j = 0; j < st_info->J; j++) {
                    // Write output to match the correct by variable group
                    for (k = 0; k < st_info->kvars_by; k++) {
                        sel = j * kvars + k;
                        if ( st_info->byvars_lens[k] > 0 ) {
                            if ( (rc = SF_sstore(k + 1, j + 1, st_dtax[sel].cval)) ) return(rc);
                        }
                        else {
                            if ( (rc = SF_vstore(k + 1, j + 1, st_dtax[sel].dval)) ) return(rc);
                        }
                    }

                    // Copy output
                    for (k = st_info->kvars_by; k < kvars; k++) {
                        if ( (rc = SF_vstore(k + st_info->kvars_source + 1, j + 1, st_dtax[j * kvars + k].dval)) ) return (rc);
                    }
                }
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    for (k = 0; k < st_info->kvars_by; k++) {
                        if ( (rc = SF_vstore(k + 1, j + 1, st_numx[j * kvars + k])) ) return (rc);
                    }
                    for (k = st_info->kvars_by; k < kvars; k++) {
                        if ( (rc = SF_vstore(k + st_info->kvars_source + 1, j + 1, st_numx[j * kvars + k])) ) return (rc);
                    }
                }
            }
        }
        else if ( action == 1 ) {

            // Write output values as appropriate
            size_t ksource = st_info->kvars_by + st_info->kvars_source;
            size_t knum    = kvars - ksource;

            // Write only by vars and source vars
            if ( st_info->kvars_by_str > 0 ) {
                for (j = 0; j < st_info->J; j++) {
                    // Write output to match the correct by variable group
                    for (k = 0; k < st_info->kvars_by; k++) {
                        sel = j * kvars + k;
                        if ( st_info->byvars_lens[k] > 0 ) {
                            if ( (rc = SF_sstore(k + 1, j + 1, st_dtax[sel].cval)) ) return(rc);
                        }
                        else {
                            if ( (rc = SF_vstore(k + 1, j + 1, st_dtax[sel].dval)) ) return(rc);
                        }
                    }

                    // Copy output
                    for (k = st_info->kvars_by; k < ksource; k++) {
                        if ( (rc = SF_vstore(k + st_info->kvars_source + 1, j + 1, st_dtax[j * kvars + k].dval)) ) return (rc);
                    }
                }
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    for (k = 0; k < ksource; k++) {
                        if ( (rc = SF_vstore(k + 1, j + 1, st_numx[j * kvars + k])) ) return (rc);
                    }
                    for (k = st_info->kvars_by; k < ksource; k++) {
                        if ( (rc = SF_vstore(k + st_info->kvars_source + 1, j + 1, st_numx[j * kvars + k])) ) return (rc);
                    }
                }
            }

            FILE *fhandle = fopen(fname, "wb");
            if ( st_info->kvars_by_str > 0 ) {
                for (j = 0; j < st_info->J; j++)
                    fwrite (st_dtax + j * kvars + ksource, sizeof(st_dtax), knum, fhandle);
            }
            else {
                for (j = 0; j < st_info->J; j++)
                    fwrite (st_numx + j * kvars + ksource, sizeof(st_numx), knum, fhandle);
            }

            fclose (fhandle);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied collapsed variables back to stata");
    }

    // Free memory
    // -----------

    if ( st_info->merge ) {
    }
    else if ( st_info->kvars_by_str > 0 ) {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < st_info->kvars_by_str; k++) {
                sel = j * kvars + (st_info->pos_str_byvars[k] - 1);
                free(st_dtax[sel].cval);
            }
        }
    }

    free (output);
    free (st_dtax);
    free (st_numx);

    return(0);
}
