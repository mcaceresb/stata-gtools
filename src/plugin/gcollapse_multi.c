/*********************************************************************
 * Program: gcollapse_multi.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Sat May 20 14:06:52 EDT 2017
 * Purpose: Stata plugin to compute a faster -collapse- (multi-threaded version)
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.3.3
 *********************************************************************/

#include <omp.h>
#include "gcollapse.h"

/**
 * @brief Collapse stata variables (multi-threaded version)
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores collapsed data in Stata
 */
int sf_collapse (struct StataInfo *st_info)
{
    ST_double  z;
    ST_retcode rc ;
    int i, j, k;
    char s[st_info->strmax];
    clock_t timer = clock();

    size_t nj, start, end, sel, out;
    size_t offset_output,
           offset_bynum,
           offset_source,
           offset_buffer;

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

    // Initialize variables for use in read, collapse, and write loops
    // ---------------------------------------------------------------

    double *bynum   = calloc(st_info->kvars_by_num  * st_info->J, sizeof *bynum);
    short  *bymiss  = calloc(st_info->kvars_by_num  * st_info->J, sizeof *bymiss);
    double *output  = calloc(st_info->kvars_targets * st_info->J, sizeof *output);
    short  *outmiss = calloc(st_info->kvars_targets * st_info->J, sizeof *outmiss);

    double *all_buffer     = calloc(st_info->kvars_source * st_info->N, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(st_info->kvars_source * st_info->J, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(st_info->kvars_source * st_info->J, sizeof *all_lastmiss );
    size_t *all_nonmiss    = calloc(st_info->kvars_source * st_info->J, sizeof *all_nonmiss);
    size_t *offsets_buffer = calloc(st_info->J, sizeof *offsets_buffer);

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

    for (i = 0; i < st_info->kvars_by_num * st_info->J; i++)
        bymiss[i] = 0;

    for (i = 0; i < st_info->kvars_targets * st_info->J; i++)
        outmiss[i] = 0;

    for (k = 0; k < st_info->kvars_source; k++)
        nmfreq[k] = nonmiss[k] = firstmiss[k] = lastmiss[k] = 0;

    for (j = 0; j < st_info->J * st_info->kvars_source; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = 0;

    // Read in variables from Stata
    // ----------------------------

    int rcp = 0;
    int nloops, rct;

    /*********************************************************************
     *                 Method 1: Continuously from Stata                 *
     *********************************************************************/

    /*
     * The following maps the C group index to Stata so we can read
     * observations from Stata in order; this seems slower than the
     * multi-threaded out of order version some of the time, and faster
     * other times... I pick it to be the default for now.
     *
    size_t *index_st = calloc(st_info->N, sizeof *index_st);
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
                if (i == start)   all_firstmiss[offset_source + k] = 1;
                if (i == end - 1) all_lastmiss[offset_source + k]  = 1;
            }
            else {
                // Read into C in order as well, via index_st, so
                // non-missing entries of given variable for each group
                // occupy a contiguous segment in memory.
                all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
            }
        }
    }
    free (index_st);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables");
    if ( rct ) return (rct);
     *
     */

    /*********************************************************************
     *                      Method 2: Out of order                       *
     *********************************************************************/

    /* For debugging
     *
    for (j = 0; j < st_info->J * st_info->kvars_source; j++)
        all_nonmiss[j] = 0;
     *
     */

    /*
     * The following reads the variables out of order. It consumes ever
     * so slighly less memory and was easier to code. However, reading
     * variables in order is somewhat faster.
     *
    offset_buffer = offset_source = 0;
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        nj     = end - start;
        offset_buffer = start * st_info->kvars_source;
        offset_source = j * st_info->kvars_source;

        // Loop through group in sequence
        for (i = start; i < end; i++) {
            sel = st_info->index[i] + st_info->in1;
            for (k = 0; k < st_info->kvars_source; k++) {
                // Read Stata out of order
                if ( (rc = SF_vdata(k + st_info->start_collapse_vars, sel, &z)) ) return(rc);
                if ( SF_is_missing(z) ) {
                    if (i == start)   all_firstmiss[offset_source + k] = 1;
                    if (i == end - 1) all_lastmiss[offset_source + k]  = 1;
                }
                else {
                    // Read into C in order, so non-missing entries of
                    // given variable for each group occupy a contiguous
                    // segment in memory.
                    all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
                }
            }
        }
        offsets_buffer[j] = offset_buffer;
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read in source variables");
     *
     */

    /*********************************************************************
     *              Method 3: In parallel and out of order               *
     *********************************************************************/

    /* For debugging
     *
    for (j = 0; j < st_info->J * st_info->kvars_source; j++)
        all_nonmiss[j] = 0;
     *
     */

    /*
     * The following reads the data in parallel by group. Sometimes it
     * is faster than method 1, but sometimes it is slower... Hard to
     * say when. For now method 1 is default
     */
    #pragma omp parallel        \
            private (           \
                k,              \
                i,              \
                z,              \
                sel,            \
                nloops,         \
                start,          \
                end,            \
                nj,             \
                offset_source,  \
                offset_buffer,  \
                rc,             \
                rct             \
            )                   \
            shared (            \
                st_info,        \
                offsets_buffer, \
                all_nonmiss,    \
                all_firstmiss,  \
                all_lastmiss,   \
                all_buffer,     \
                rcp             \
            )
    {
        // Initialize private variables
        z      = 0;
        rc     = 0;
        rct    = 0;
        sel    = 0;
        nloops = 0;
        start  = 0;
        end    = 0;
        nj     = 0;
        offset_source = 0;
        offset_buffer = 0;

        #pragma omp for
        for (j = 0; j < st_info->J; j++) {
            ++nloops;
            start  = st_info->info[j];
            end    = st_info->info[j + 1];
            nj     = end - start;
            offset_buffer = start * st_info->kvars_source;
            offset_source = j * st_info->kvars_source;

            // Loop through group in sequence
            for (i = start; i < end; i++) {
                sel = st_info->index[i] + st_info->in1;
                for (k = 0; k < st_info->kvars_source; k++) {
                    // Read Stata out of order
                    if ( (rc = SF_vdata(k + st_info->start_collapse_vars, sel, &z)) ) {
                        rct = rc;
                        continue;
                    }
                    if ( SF_is_missing(z) ) {
                        if (i == start)   all_firstmiss[offset_source + k] = 1;
                        if (i == end - 1) all_lastmiss[offset_source + k]  = 1;
                    }
                    else {
                        // Read into C in order, so non-missing entries of
                        // given variable for each group occupy a contiguous
                        // segment in memory.
                        all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
                    }
                }
            }
            offsets_buffer[j] = offset_buffer;
        }

        #pragma omp critical
        {
            if ( rct ) rcp = rct;
            if ( st_info->verbose ) sf_printf("\t\tThread %d processed %d groups.\n", omp_get_thread_num(), nloops);
        }
    }
    if ( rcp ) return (rcp);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables");
    /*
     */

    /*********************************************************************
     *            Method 4: Read into temporary buffer first             *
     *********************************************************************/

    /* For debugging
     *
    for (j = 0; j < st_info->J * st_info->kvars_source; j++)
        all_nonmiss[j] = 0;
     *
     */

    /*
     * The following reads the data in parallel and in order
     * into a temporary buffer and then orders that in C
     *
    double *buffer_st = calloc(st_info->kvars_source * st_info->N, sizeof *buffer_st);
    size_t *index_st  = calloc(st_info->N, sizeof *index_st);
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        offsets_buffer[j] = start * st_info->kvars_source;
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = j;
    }

    #pragma omp parallel        \
            private (           \
                k,              \
                z,              \
                nloops,         \
                rc,             \
                rct             \
            )                   \
            shared (            \
                st_info,        \
                buffer_st,      \
                rcp             \
            )
    {
        // Initialize private variables
        z      = 0;
        rc     = 0;
        rct    = 0;
        nloops = 0;

        #pragma omp for
        for (i = 0; i < st_info->N; i++) {
            ++nloops;
            for (k = 0; k < st_info->kvars_source; k++) {
                if ( (rc = SF_vdata(k + st_info->start_collapse_vars, i + st_info->in1, &z)) ) {
                    rct = rc;
                    continue;
                }
                buffer_st [i * st_info->kvars_source + k] = z;
            }
        }

        #pragma omp critical
        {
            if ( rct ) rcp = rct;
            if ( st_info->verbose ) sf_printf("\t\tThread %d processed %d observations.\n",
                                              omp_get_thread_num(), nloops);
        }
    }
    if ( rcp ) return (rcp);

    offset_buffer = offset_source = 0;
    for (i = 0; i < st_info->N; i++) {
        j     = index_st[i];
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        nj    = end - start;
        offset_buffer = start * st_info->kvars_source;
        offset_source = j * st_info->kvars_source;
        for (k = 0; k < st_info->kvars_source; k++) {
            // Read Stata's buffer in order
            z = buffer_st[i * st_info->kvars_source + k];
            if ( SF_is_missing(z) ) {
                if (i == start)   all_firstmiss[offset_source + k] = 1;
                if (i == end - 1) all_lastmiss[offset_source + k]  = 1;
            }
            else {
                // Read into C in order as well, via index_st, so
                // non-missing entries of given variable for each group
                // occupy a contiguous segment in memory.
                all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
            }
        }
    }
    free (index_st);
    free (buffer_st);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read source variables");
     *
     */

    // Collapse variables by group
    // ---------------------------

    for (j = 0; j < st_info->J; j++)
        for (k = 0; k < st_info->kvars_source; k++)
            nmfreq[k] += all_nonmiss[j * st_info->kvars_source + k];


    #pragma omp parallel        \
            private (           \
                k,              \
                sel,            \
                nloops,         \
                start,          \
                end,            \
                nj,             \
                firstobs,       \
                lastobs,        \
                offset_output,  \
                offset_source,  \
                offset_buffer   \
            )                   \
            shared (            \
                st_info,        \
                statcode,       \
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
        sel    = 0;
        nloops = 0;
        start  = 0;
        end    = 0;
        nj     = 0;
        offset_output = 0;
        offset_source = 0;
        offset_buffer = 0;

        for (k = 0; k < st_info->kvars_source; k++)
            firstobs[k] = lastobs[k] = 0;

        // We encoded stat strings; see mf_code_fun in gtools_math.c
        #pragma omp for
        for (j = 0; j < st_info->J; j++) {
            ++nloops;
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
                // missing then we note it in outmiss. We will later write
                // to Stata the contents of output if outmiss is 0 or a
                // missing value if outmiss is 1.
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
                    output[offset_output + k] = 100 * end;
                }
                else if ( all_firstmiss[sel] & (statcode[k] == -10) ) { // first
                    // If first observation is missing, will write missing value
                    outmiss[offset_output + k] = 1;
                }
                else if ( all_lastmiss[sel] & (statcode[k] == -12) ) { // last
                    // If last observation is missing, will write missing value
                    outmiss[offset_output + k] = 1;
                }
                else if ( (statcode[k] == -10) | (statcode[k] == -11) ) { // first|firstnm
                    // First obs/first non-missing is the first entry in the inputs buffer
                    output[offset_output + k] = firstobs[st_info->pos_targets[k]];
                }
                else if ( (statcode[k] == -12) | (statcode[k] == -13) ) { // last|lastnm
                    // Last obs/last non-missing is the last entry in the inputs buffer
                    output[offset_output + k] = lastobs[st_info->pos_targets[k]];
                }
                else if ( (statcode[k] == -3) &  (end < 2) ) { // sd
                    // Standard deviation requires at least 2 observations
                    outmiss[offset_output + k] = 1;
                }
                else if ( end == 0 ) {
                    // If everything is missing, write a missing value
                    outmiss[offset_output + k] = 1;
                }
                else {
                    // Otherwise compute the requested summary stat
                    output[offset_output + k] = mf_switch_fun_code (statcode[k], all_buffer, start, start + end);
                }
            }
        }

        #pragma omp critical
        {
            if ( st_info->verbose ) sf_printf("\t\tThread %d processed %d groups.\n", omp_get_thread_num(), nloops);
        }
    }

    free (all_buffer);
    free (all_firstmiss);
    free (all_lastmiss);
    free (all_nonmiss);
    free (offsets_buffer);

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Collapsed source variables");

    // Copy output back into Stata
    // ---------------------------

    if ( st_info->merge ) {
        // If merge is requested, leave source by variables unmodified
        double output_buffer[st_info->kvars_targets];

        offset_output = 0;
        for (j = 0; j < st_info->J; j++) {
            start  = st_info->info[j];
            end    = st_info->info[j + 1];

            for (k = 0; k < st_info->kvars_targets; k++) {
                sel = offset_output + k;
                if ( statcode[k] == -7 ) output[sel] /= nmfreq[st_info->pos_targets[k]];
                output_buffer[k] = outmiss[sel]? SV_missval: output[sel];
            }

            // Write the same value from start to end; we won't sort or
            // modify the input data, so the position of each value of
            // the jth group is index[i] for i = start to i < end.
            for (i = start; i < end; i++) {
                for (k = 0; k < st_info->kvars_targets; k++) {
                    out = st_info->index[i] + st_info->in1;
                    // sel = offset_output + k;
                    // if ( statcode[k] == -7 ) output[sel] /= nmfreq[st_info->pos_targets[k]];
                    // if ( (rc = SF_vstore(k + st_info->start_target_vars, out, outmiss[sel]? SV_missval: output[sel])) ) return (rc);
                    if ( (rc = SF_vstore(k + st_info->start_target_vars, out, output_buffer[k])) ) return (rc);
                }
            }
            offset_output += st_info->kvars_targets;
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Merged collapsed variables back to stata");
    }
    else {
        offset_bynum = 0;

        // Read in first entry of each group variable
        for (j = 0; j < st_info->J; j++) {
            start = st_info->info[j];
            // For string variables, read into first J entries of temporary string variables
            for (k = 0; k < st_info->kvars_by_str; k++) {
                if ( (rc = SF_sdata(st_info->pos_str_byvars[k], st_info->index[start] + st_info->in1, s)) ) return(rc);
                if ( (rc = SF_sstore(k + st_info->start_str_byvars, j + 1, s)) ) return(rc);
            }
            // For numeric variables, read into numeric array
            for (k = 0; k < st_info->kvars_by_num; k++) {
                if ( (rc = SF_vdata(st_info->pos_num_byvars[k], st_info->index[start] + st_info->in1, &z)) ) return(rc);
                if ( SF_is_missing(z) ) {
                    bymiss[offset_bynum + k] = 1;
                }
                else {
                    bynum[offset_bynum + k] = z;
                }
            }
            offset_bynum += st_info->kvars_by_num;
        }

        // Write output to match the correct by variable group
        offset_output = offset_bynum = 0;
        for (j = 0; j < st_info->J; j++) {
            // Copy output, writing  missing values as appropriate
            for (k = 0; k < st_info->kvars_targets; k++) {
                sel = offset_output + k;
                if ( statcode[k] == -7 ) output[sel] /= nmfreq[st_info->pos_targets[k]];
                if ( (rc = SF_vstore(k + st_info->start_target_vars, j + 1, outmiss[sel]? SV_missval: output[sel])) ) return (rc);
            }
            // Copy back string variables to replace them in the data
            for (k = 0; k < st_info->kvars_by_str; k++) {
                if ( (rc = SF_sdata(k + st_info->start_str_byvars, j + 1, s)) ) return(rc);
                if ( (rc = SF_sstore(st_info->pos_str_byvars[k], j + 1, s)) ) return(rc);
            }
            // Copy numeric by variables from temporary array
            for (k = 0; k < st_info->kvars_by_num; k++) {
                sel = offset_bynum + k;
                if ( (rc = SF_vstore(st_info->pos_num_byvars[k], j + 1, bymiss[sel]? SV_missval: bynum[sel])) ) return(rc);
            }
            offset_output += st_info->kvars_targets;
            offset_bynum += st_info->kvars_by_num;
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied collapsed variables back to stata");
    }

    // Free memory
    // -----------

    free (output);
    free (bynum);
    free (bymiss);
    free (outmiss);

    return(0);
}
