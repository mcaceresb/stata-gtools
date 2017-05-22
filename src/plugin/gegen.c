/*********************************************************************
 * Program: gegen.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Sat May 20 14:06:34 EDT 2017
 * Purpose: Stata plugin to compute a faster -egen-
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.3.3
 *********************************************************************/

#include "gegen.h"

/**
 * @brief egen stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores egen data in Stata
 */
int sf_egen (struct StataInfo *st_info)
{
    ST_double  z;
    ST_retcode rc ;
    int i, j, k;
    // char s[st_info->strmax];
    clock_t timer = clock();

    size_t nj, start, end, sel, out, offset_buffer;
    size_t nmfreq  = 0;
    double statdbl = mf_code_fun (st_info->statstr);

    // Initialize variables for use in read, collapse, and write loops
    // ---------------------------------------------------------------

    double *output  = calloc(st_info->J, sizeof *output);
    short  *outmiss = calloc(st_info->J, sizeof *outmiss);

    double *all_buffer     = calloc(st_info->kvars_source * st_info->N, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(st_info->J, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(st_info->J, sizeof *all_lastmiss );
    size_t *all_nonmiss    = calloc(st_info->J, sizeof *all_nonmiss);
    size_t *offsets_buffer = calloc(st_info->J, sizeof *offsets_buffer);

    for (i = 0; i < st_info->J; i++)
        outmiss[i] = 0;

    for (j = 0; j < st_info->J; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = 0;

    // Read in variables from Stata
    // ----------------------------

    /* TODO: It is faster to read in variables from Stata sequentially.
     * Figure out if this is feasible and use index on all_buffer for
     * a possible speed gain. // 2017-05-18 22:01 EDT
     */

    offset_buffer = 0;
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        nj     = end - start;
        // Loop through group in sequence
        for (i = start; i < end; i++) {
            sel = st_info->index[i] + st_info->in1;
            for (k = 0; k < st_info->kvars_source; k++) {
                // Read Stata out of order
                if ( (rc = SF_vdata(k + st_info->start_collapse_vars, sel, &z)) ) return(rc);
                /* TODO: Follow the do start++ while seen in ... // 2017-05-20 00:36 EDT */
                if ( SF_is_missing(z) | !SF_ifobs(st_info->in1 + st_info->index[i]) ) {
                    if (i == start)   all_firstmiss[j] = 1;
                    if (i == end - 1) all_lastmiss[j]  = 1;
                }
                else {
                    // Read into C in order, so non-missing entries of
                    // given variable for each group occupy a contiguous
                    // segment in memory.
                    all_buffer [offset_buffer + all_nonmiss[j]++] = z;
                }
            }
        }
        offsets_buffer[j] = offset_buffer;
        offset_buffer    += nj * st_info->kvars_source;
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read in source variables");

    for (j = 0; j < st_info->J; j++)
        nmfreq += all_nonmiss[j];

    // Collapse variables by group
    // ---------------------------

    for (j = 0; j < st_info->J; j++) {
        nj    = st_info->info[j + 1] - st_info->info[j];
        start = offsets_buffer[j];
        end   = all_nonmiss[j];
        {
            // If there is at least one non-missing observation, we
            // store the result in output. If all observations are
            // missing then we note it in outmiss. We will later write
            // to Stata the contents of output if outmiss is 0 or a
            // missing value if outmiss is 1.
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
                output[j] = 100 * end;
            }
            else if ( all_firstmiss[j] & (statdbl == -10) ) { // first
                // If first observation is missing, will write missing value
                outmiss[j] = 1;
            }
            else if ( all_lastmiss[j] & (statdbl == -12) ) { // last
                // If last observation is missing, will write missing value
                outmiss[j] = 1;
            }
            else if ( (statdbl == -10) | (statdbl == -11) ) { // first|firstnm
                // First obs/first non-missing is the first entry in the inputs buffer
                output[j] = all_buffer[start];
            }
            else if ( (statdbl == -12) | (statdbl == -13) ) { // last|lastnm
                // Last obs/last non-missing is the last entry in the inputs buffer
                output[j] = all_buffer[start + end - 1];
            }
            else if ( (statdbl == -3) &  (end < 2) ) { // sd
                // Standard deviation requires at least 2 observations
                outmiss[j] = 1;
            }
            else if ( end == 0 ) {
                // If everything is missing, write a missing value
                outmiss[j] = 1;
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

    // Copy output back into Stata
    // ---------------------------

    // If merge is requested, leave source by variables unmodified
    double output_buffer;

    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        if ( statdbl == -7 ) output[j] /= nmfreq;
        output_buffer = outmiss[j]? SV_missval: output[j];

        // Write the same value from start to end; we won't sort or
        // modify the input data, so the position of each value of the
        // jth group is index[i] for i = start to i < end.
        for (i = start; i < end; i++) {
            out = st_info->index[i] + st_info->in1;
            if ( SF_ifobs(out) ) {
                if ( (rc = SF_vstore(st_info->start_target_vars, out, output_buffer)) ) return (rc);
            }
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied output back to stata");

    // Free memory
    // -----------

    free (output);
    free (outmiss);

    return(0);
}

/**
 * @brief tag stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Tags first obs of gorup in Stata
 */
int sf_egen_tag (struct StataInfo *st_info)
{
    ST_double z ;
    ST_retcode rc ;
    int i, j, k, out;
    size_t start, end, minj;
    clock_t timer = clock();

    size_t *indexj = calloc(st_info->J, sizeof *indexj);
    size_t *firstj = calloc(st_info->J, sizeof *firstj);

    // Since we hash the data, the order in C has to be mapped to the
    // order in Stata via info and index. First figure out the order in
    // which the groups appear in Stata, and then write by looping over
    // groups in that order
    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        while ( !SF_ifobs(st_info->in1 + st_info->index[start]) & (start < end) ) {
            start++;
        }
        minj = st_info->index[start];
        for (i = start + 1; i < end; i++) {
            if ( SF_ifobs(st_info->in1 + st_info->index[i]) ) {
                if ( minj > st_info->index[i] ) minj = st_info->index[i];
            }
        }
        firstj[j] = minj;
        indexj[j] = j;
    }

    // indexj[j] will contain the order in which the jth C group
    // inappeared Stata
    mf_radix_sort_index (firstj, indexj, st_info->J, RADIX_SHIFT, 0, st_info->verbose);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Tagged groups in memory");

    // We loop in C using indexj and write to Stata based on index
    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[indexj[j]];
        end   = st_info->info[indexj[j] + 1];
        while ( !SF_ifobs(st_info->in1 + st_info->index[start]) & (start < end) ) {
            start++;
        }
        if ( start < end ) {
            out = st_info->index[start] + st_info->in1;
            if ( (rc = SF_vstore(st_info->start_target_vars, out, 1)) ) return (rc);
        }
    }

    // Tag ignores if/in for missing values (all non-tagged are 0)
    k = st_info->start_target_vars;
    for (i = 1; i <= SF_nobs(); i++) {
        if ( (rc = SF_vdata(k, i, &z)) ) return(rc);
        if ( SF_is_missing(z) ) {
            if ( (rc = SF_vstore(k, i, 0)) ) return (rc);
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Copied tag to Stata");

    free (indexj);
    free (firstj);

    return(0);
}

/**
 * @brief index stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return indexes by variables in Stata
 */
int sf_egen_group (struct StataInfo *st_info)
{
    ST_retcode rc ;
    int i, j, out;
    size_t start, end, minj;
    clock_t timer = clock();

    size_t *indexj = calloc(st_info->J, sizeof *indexj);
    size_t *firstj = calloc(st_info->J, sizeof *firstj);

    // Since we hash the data, the order in C has to be mapped to the
    // order in Stata via info and index. First figure out the order in
    // which the groups appear in Stata, and then write by looping over
    // groups in that order
    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        while ( !SF_ifobs(st_info->in1 + st_info->index[start]) & (start < end) ) {
            start++;
        }
        minj = st_info->index[start];
        for (i = start + 1; i < end; i++) {
            if ( SF_ifobs(st_info->in1 + st_info->index[i]) ) {
                if ( minj > st_info->index[i] ) minj = st_info->index[i];
            }
        }
        firstj[j] = minj;
        indexj[j] = j;
    }

    // indexj[j] will contain the order in which the jth C group
    // inappeared Stata
    mf_radix_sort_index (firstj, indexj, st_info->J, RADIX_SHIFT, 0, st_info->verbose);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Indexed groups in memory");

    // We loop in C using indexj and write to Stata based on index
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[indexj[j]];
        end    = st_info->info[indexj[j] + 1];
        for (i = start; i < end; i++) {
            out = st_info->index[i] + st_info->in1;
            if ( SF_ifobs(out) ) {
                if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
            }
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Copied index to Stata");

    free (indexj);
    free (firstj);

    return(0);
}
