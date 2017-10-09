/*********************************************************************
 * Program: gegen.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Thu Sep 28 18:40:21 EDT 2017
 * Purpose: Stata plugin to compute a faster -egen-
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.7.5
 *********************************************************************/

#include "gegen.h"
#include "gegen_common.c"

/**
 * @brief egen stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores egen data in Stata
 */
int sf_egen (struct StataInfo *st_info)
{
    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_double  z;
    ST_retcode rc ;
    int i, j, k;
    clock_t timer = clock();

    size_t start, end, sel, out, offset_buffer;
    size_t nmfreq  = 0;
    double statdbl = mf_code_fun (st_info->statstr);

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    double *output         = calloc(st_info->J, sizeof *output);
    double *all_buffer     = calloc(st_info->kvars_source * st_info->N, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(st_info->J, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(st_info->J, sizeof *all_lastmiss );
    size_t *all_nonmiss    = calloc(st_info->J, sizeof *all_nonmiss);
    size_t *offsets_buffer = calloc(st_info->J, sizeof *offsets_buffer);

    if ( output         == NULL ) return(sf_oom_error("sf_egen", "output"));
    if ( all_buffer     == NULL ) return(sf_oom_error("sf_egen", "all_buffer"));
    if ( all_firstmiss  == NULL ) return(sf_oom_error("sf_egen", "all_firstmiss"));
    if ( all_lastmiss   == NULL ) return(sf_oom_error("sf_egen", "all_lastmiss"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_egen", "all_nonmiss"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_egen", "offsets_buffer"));

    for (j = 0; j < st_info->J; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = 0;

    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    int rct = 0;
    size_t *pos_firstmiss = calloc(st_info->J, sizeof *pos_firstmiss);
    size_t *pos_lastmiss  = calloc(st_info->J, sizeof *pos_lastmiss);

    if ( pos_firstmiss == NULL ) return(sf_oom_error("sf_egen", "pos_firstmiss"));
    if ( pos_lastmiss  == NULL ) return(sf_oom_error("sf_egen", "pos_lastmiss"));

    // Method 1: Continuously from Stata
    // ---------------------------------

    /*
     *
    size_t *index_st = calloc(st_info->N, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_collapse", "index_st"));

    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        offsets_buffer[j] = start * st_info->kvars_source;
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = j;

        do {
            sel = st_info->in1 + st_info->index[start];
            ++start;
        } while ( !SF_ifobs(sel) & (start < end) );
        pos_firstmiss[j] = sel;
        --start;

        do {
            sel = st_info->in1 + st_info->index[end - 1];
            --end;
        } while ( !SF_ifobs(sel) & (start < end) );
        pos_lastmiss[j] = sel;
    }

    offset_buffer = 0;
    for (i = 0; i < st_info->N; i++) {
        sel   = i + st_info->in1;
        j     = index_st[i];
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        offset_buffer = start * st_info->kvars_source;

        // Loop through variables in sequence
        for (k = 0; k < st_info->kvars_source; k++) {
            // Read Stata in order
            if ( (rc = SF_vdata(k + st_info->start_collapse_vars, sel, &z)) ) {
                rct = rc;
                continue;
            }
            if ( SF_ifobs(sel) ) {
                if ( SF_is_missing(z) ) {
                    if ( sel == pos_firstmiss[j] ) all_firstmiss[j] = 1;
                    if ( sel == pos_lastmiss[j] )  all_lastmiss[j]  = 1;
                }
                else {
                    // Read into C in order as well, via index_st, so
                    // non-missing entries of given variable for each group
                    // occupy a contiguous segment in memory.
                    all_buffer [offset_buffer + all_nonmiss[j]++] = z;
                }
            }
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables sequentially");
    if ( rct ) return (rct);
    free (index_st);
     *
     */

    // Method 2: Out of order
    // ----------------------

    /*
     */
    offset_buffer = 0;
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        do {
            sel = st_info->in1 + st_info->index[start];
            ++start;
        } while ( !SF_ifobs(sel) & (start < end) );
        pos_firstmiss[j] = sel;
        --start;

        do {
            sel = st_info->in1 + st_info->index[end - 1];
            --end;
        } while ( !SF_ifobs(sel) & (start < end) );
        pos_lastmiss[j] = sel;

        start = st_info->info[j];
        end   = st_info->info[j + 1];
        offset_buffer = start * st_info->kvars_source;

        // Loop through group in sequence
        for (i = start; i < end; i++) {
            sel = st_info->index[i] + st_info->in1;
            for (k = 0; k < st_info->kvars_source; k++) {
                // Read Stata out of order
                if ( (rc = SF_vdata(k + st_info->start_collapse_vars, sel, &z)) ) {
                    rct = rc;
                    continue;
                }
                if ( SF_ifobs(sel) ) {
                    if ( SF_is_missing(z) ) {
                        if ( sel == pos_firstmiss[j] ) all_firstmiss[j] = 1;
                        if ( sel == pos_lastmiss[j] )  all_lastmiss[j]  = 1;
                    }
                    else {
                        // Read into C in order, so non-missing entries of
                        // given variable for each group occupy a contiguous
                        // segment in memory.
                        all_buffer [offset_buffer + all_nonmiss[j]++] = z;
                    }
                }
            }
        }
        offsets_buffer[j] = offset_buffer;
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables by group");
    if ( rct ) return (rct);
    /*
     */

    free (pos_firstmiss);
    free (pos_lastmiss);

    /*********************************************************************
     *               Step 4: Compute the summary statistic               *
     *********************************************************************/

    for (j = 0; j < st_info->J; j++)
        nmfreq += all_nonmiss[j];

    {
        for (j = 0; j < st_info->J; j++) {
            start = offsets_buffer[j];
            end   = all_nonmiss[j];

            // If there is at least one non-missing observation, we store the
            // result in output. If all observations are missing then we note
            // write a missing value.

            if ( statdbl == -6 ) { // count
                // If count, you just need to know how many non-missing obs there are
                output[j] = end;
            }
            else if ( statdbl == -7  ) { // percent
                // Percent outputs the % of all non-missing values of
                // that variable in that group relative to the number
                // of non-missing values of that variable in the entire
                // data. This latter count is stored in nmfreq; we
                // divide by this when writing to Stata.
                output[j] = 100 * ((double) end / nmfreq);
            }
            else if ( end == 0 ) {
                // If everything is missing, write a missing value,
                // except for sums, which go to 0 for some reason (this
                // is the behavior of collapse).
                if ( statdbl == -1 ) {
                    if ( st_info->missing ) {
                        output[j] = SV_missval;
                    }
                    else {
                        output[j] = 0;
                    }
                }
                else {
                    output[j] = SV_missval;
                }
            }
            else if ( all_firstmiss[j] & (statdbl == -10) ) { // first
                // If first observation is missing, will write missing value
                output[j] = SV_missval;
            }
            else if ( (statdbl == -10) | (statdbl == -11) ) { // first|firstnm
                // First obs/first non-missing is the first entry in the inputs buffer
                output[j] = all_buffer[start];
            }
            else if ( all_lastmiss[j] & (statdbl == -12) ) { // last
                // If last observation is missing, will write missing value
                output[j] = SV_missval;
            }
            else if ( (statdbl == -12) | (statdbl == -13) ) { // last|lastnm
                // Last obs/last non-missing is the last entry in the inputs buffer
                output[j] = all_buffer[start + end - 1];
            }
            else if ( (statdbl == -3) &  (end < 2) ) { // sd
                // Standard deviation requires at least 2 observations
                output[j] = SV_missval;
            }
            else {
                // Otherwise compute the requested summary stat
                output[j] = mf_switch_fun_code (statdbl, all_buffer, start, start + end);
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: By vars summary stats");

    free (all_buffer);
    free (all_firstmiss);
    free (all_lastmiss);
    free (all_nonmiss);
    free (offsets_buffer);

    /*********************************************************************
     *                Step 5: Copy output back into Stata                *
     *********************************************************************/
    
    // if and in are important; values outside that range should be missing
    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[j];
        end   = st_info->info[j + 1];

        // Write the same value from start to end; we won't sort or modify
        // the input data, so the position of each value of the jth group is
        // index[i] for i = start to i < end.
        for (i = start; i < end; i++) {
            out = st_info->index[i] + st_info->in1;
            if ( SF_ifobs(out) ) {
                if ( (rc = SF_vstore(st_info->start_target_vars, out, output[j])) ) return (rc);
            }
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied output back to stata");

    // Free memory
    // -----------

    free (output);
    return(0);
}
