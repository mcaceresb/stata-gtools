/*********************************************************************
 * Program: gegen_multi.c
 * Author:  Mauricio Caceres Bravo <caceres@nber.org>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Fri May 19 17:34:35 EDT 2017
 * Purpose: Stata plugin to compute a faster -egen- (multi-threaded version)
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.2.0
 *********************************************************************/

#include <omp.h>
#include "gegen.h"

/**
 * @brief egen stata variables (multi-threaded version)
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores egen data in Stata
 */
int sf_egen (struct StataInfo *st_info)
{
    ST_double  z;
    ST_retcode rc ;
    int i, j, k;
    // char s[st_info->strlen];
    clock_t timer = clock();

    size_t nj, start, end, sel, out, offset_buffer;
    size_t nmfreq = 0;

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

    int nloops;
    #pragma omp parallel        \
            private (           \
                nloops,         \
                start,          \
                end,            \
                nj              \
            )                   \
            shared (            \
                st_info,        \
                offsets_buffer, \
                all_nonmiss,    \
                all_firstmiss,  \
                all_lastmiss,   \
                all_buffer,     \
                output,         \
                outmiss         \
            )
    {
        // Initialize private variables
        nloops = 0;
        start  = 0;
        end    = 0;
        nj     = 0;

        #pragma omp for
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
                if ( mf_strcmp_wrapper (st_info->statstr, "count") ) {
                    // If count, you just need to know how many non-missing obs there are
                    output[j] = end;
                }
                else if ( mf_strcmp_wrapper (st_info->statstr, "percent")  ) {
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we
                    // divide by this when writing to Stata.
                    output[j] = 100 * end;
                }
                else if ( all_firstmiss[j] & (mf_strcmp_wrapper (st_info->statstr, "first") ) ) {
                    // If first observation is missing, will write missing value
                    outmiss[j] = 1;
                }
                else if ( all_lastmiss[j] & (mf_strcmp_wrapper (st_info->statstr, "last") ) ) {
                    // If last observation is missing, will write missing value
                    outmiss[j] = 1;
                }
                else if ( mf_strcmp_wrapper (st_info->statstr, "first") | (mf_strcmp_wrapper (st_info->statstr, "firstnm") ) ) {
                    // First obs/first non-missing is the first entry in the inputs buffer
                    output[j] = all_buffer[start];
                }
                else if ( mf_strcmp_wrapper (st_info->statstr, "last") | (mf_strcmp_wrapper (st_info->statstr, "lastnm") ) ) {
                    // Last obs/last non-missing is the last entry in the inputs buffer
                    output[j] = all_buffer[start + end - 1];
                }
                else if ( mf_strcmp_wrapper (st_info->statstr, "sd") &  (end < 2) ) {
                    // Standard deviation requires at least 2 observations
                    outmiss[j] = 1;
                }
                else if ( end == 0 ) {
                    // If everything is missing, write a missing value
                    outmiss[j] = 1;
                }
                else {
                    // Otherwise compute the requested summary stat
                    output[j] = mf_switch_fun (st_info->statstr, all_buffer, start, start + end);
                }
            }
        }

        #pragma omp critical
        {
            if ( st_info->verbose ) sf_printf("\t\tThread %d processed %d groups.\n", omp_get_thread_num(), nloops);
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
        if ( mf_strcmp_wrapper (st_info->statstr, "percent") ) output[j] /= nmfreq;
        output_buffer = outmiss[j]? SV_missval: output[j];

        // Write the same value from start to end; we won't sort or
        // modify the input data, so the position of each value of the
        // jth group is index[i] for i = start to i < end.
        for (i = start; i < end; i++) {
            if ( SF_ifobs(st_info->in1 + st_info->index[i]) ) {
                out = st_info->index[i] + st_info->in1;
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
    ST_retcode rc ;
    int i, j, out;
    size_t start, end, minj;
    clock_t timer = clock();

    size_t *indexj = calloc(st_info->J, sizeof *indexj);
    size_t *firstj = calloc(st_info->J, sizeof *firstj);

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

    size_t max = mf_max(firstj, st_info->J);
    size_t min = mf_min(firstj, st_info->J);
    mf_counting_sort_index (firstj, indexj, st_info->J, min, max);

    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[indexj[j]];
        end   = st_info->info[indexj[j] + 1];
        while ( !SF_ifobs(st_info->in1 + st_info->index[start]) & (start < end) ) {
            start++;
        }
        out = st_info->index[start] + st_info->in1;
        if ( start < end ) {
            if ( (rc = SF_vstore(st_info->start_target_vars, out, 1)) ) return (rc);
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5: Tagged groups in Stata");

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

    size_t max = mf_max(firstj, st_info->J);
    size_t min = mf_min(firstj, st_info->J);
    mf_counting_sort_index (firstj, indexj, st_info->J, min, max);

    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[indexj[j]];
        end    = st_info->info[indexj[j] + 1];
        for (i = start; i < end; i++) {
            if ( SF_ifobs(st_info->in1 + st_info->index[i]) ) {
                out = st_info->index[i] + st_info->in1;
                if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
            }
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5: Indexed groups in Stata");

    free (indexj);
    free (firstj);

    return(0);
}
