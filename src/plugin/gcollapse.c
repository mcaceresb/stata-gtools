/*********************************************************************
 * Program: gcollapse.c
 * Author:  Mauricio Caceres Bravo <caceres@nber.org>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Tue May 16 08:54:24 EDT 2017
 * Purpose: Stata plugin to compute a faster -collapse-
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.1.1
 *********************************************************************/

/**
 * @file gcollapse.c
 * @author Mauricio Caceres Bravo
 * @date 16 May 2017
 * @brief Stata plugin for a faster -collapse- implementation
 *
 * This file should only ever be called from gcollapse.ado
 *
 * @see help gcollapse
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include <omp.h>
#include <math.h>
#include <time.h>
#include <regex.h>
#include <stdio.h>
#include <locale.h>
#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/types.h>

#include "spi/stplugin.h"
#include "spt/st_gentools.c"

#include "gtools_utils.c"
#include "gtools_hash.c"
#include "gtools_sort.c"
#include "gtools_math.c"

#define RADIX_SHIFT 16

struct StataInfo {
    size_t *index;
    size_t *info;
    size_t J;
    size_t nj_min;
    size_t nj_max;
    size_t in1;
    size_t in2;
    size_t N;
    size_t start_collapse_vars;
    size_t start_target_vars;
    size_t start_str_byvars;
    int *pos_targets;
    int *pos_num_byvars;
    int *pos_str_byvars;
    int kvars_targets;
    int kvars_source;
    int kvars_by;
    int kvars_by_num;
    int kvars_by_str;
    int verbose;
    int benchmark;
    int integers_ok;
    int *byvars_lens;
    int *byvars_mins;
    int *byvars_maxs;
    int byvars_minlen;
    int byvars_maxlen;
    int strlen;
    char *statstr;
};

int  sf_parse_info  (struct StataInfo *st_info);
int  sf_hash_byvars (struct StataInfo *st_info);
int  sf_collapse    (struct StataInfo *st_info);
void sf_free        (struct StataInfo *st_info);

STDLL stata_call(int argc, char *argv[])
{
    ST_retcode rc ;
    setlocale (LC_ALL, "");
    struct StataInfo st_info;

    if ( (rc = sf_parse_info  (&st_info)) ) return (rc);
    if ( (rc = sf_hash_byvars (&st_info)) ) return (rc);
    if ( (rc = sf_collapse    (&st_info)) ) return (rc);
    if ( (rc = SF_scal_save ("__gtools_J", st_info.J)) ) return (rc);

    sf_free (&st_info);
    return(0);
}

int sf_parse_info (struct StataInfo *st_info)
{
    ST_retcode rc ;
    int i, k;
    clock_t timer = clock();

    size_t in1 = SF_in1();
    size_t in2 = SF_in2();
    size_t N   = in2 - in1 + 1;

    // Number of by vars
    int kvars_by = sf_get_vector_length("__gtools_byk");
    if (kvars_by < 0) {
        sf_errprintf("Failed to parse __gtools_byk\n");
        return(198);
    }

    // Starting position of collapse variables
    int start_collapse_vars = kvars_by + 1;

    // Verbose printing
    int verbose;
    ST_double verb_double ;
    if ( (rc = SF_scal_use("__gtools_verbose", &verb_double)) ) {
        return(rc) ;
    }
    else {
        verbose = (int) verb_double;
    }

    // Benchmark printing
    int benchmark;
    ST_double bench_double ;
    if ( (rc = SF_scal_use("__gtools_benchmark", &bench_double)) ) {
        return(rc) ;
    }
    else {
        benchmark = (int) bench_double;
    }

    /*********************************************************************
     *                    Parse by vars info vectors                     *
     *********************************************************************/

    st_info->byvars_lens = calloc(kvars_by, sizeof st_info->byvars_lens);
    st_info->byvars_mins = calloc(kvars_by, sizeof st_info->byvars_mins);
    st_info->byvars_maxs = calloc(kvars_by, sizeof st_info->byvars_maxs);

    double byvars_lens_double[kvars_by],
           byvars_mins_double[kvars_by],
           byvars_maxs_double[kvars_by];

    if ( (rc = sf_get_vector("__gtools_byk",     byvars_lens_double))   ) return(rc);
    if ( (rc = sf_get_vector("__gtools_bymin",   byvars_mins_double))   ) return(rc);
    if ( (rc = sf_get_vector("__gtools_bymax",   byvars_maxs_double))   ) return(rc);

    for (i = 0; i < kvars_by; i++) {
        st_info->byvars_lens[i]   = (int) byvars_lens_double[i];
        st_info->byvars_mins[i]   = (int) byvars_mins_double[i];
        st_info->byvars_maxs[i]   = (int) byvars_maxs_double[i];
    }

    // Get count of numeric and string by variables
    size_t kvars_by_str = 0;
    for (i = 0; i < kvars_by; i++) {
        kvars_by_str += (st_info->byvars_lens[i] > 0);
    }
    size_t kvars_by_num = kvars_by - kvars_by_str;

    // If only integers, check worst case of the bijection would not overflow
    int integers_ok;
    int byvars_minlen = mf_min_signed(st_info->byvars_lens, kvars_by);
    int byvars_maxlen = mf_max_signed(st_info->byvars_lens, kvars_by);
    if ( byvars_maxlen < 0 ) {
        if (kvars_by > 1) {
            integers_ok = 1;
            size_t worst = st_info->byvars_maxs[0] - st_info->byvars_mins[0] + 1;
            size_t range = st_info->byvars_maxs[1] - st_info->byvars_mins[1] + (1 < (kvars_by - 1));
            for (k = 1; k < kvars_by; k++) {
                if ( worst > (ULONG_MAX / range)  ) {
                    if ( verbose ) sf_printf("By variables all intergers but bijection could fail! Won't risk it.\n");
                    integers_ok  = 0;
                    break;
                }
                else {
                    worst *= range;
                    range  = st_info->byvars_maxs[k] - st_info->byvars_mins[k] + (k < (kvars_by - 1));
                }
            }
        }
        else {
            integers_ok = 1;
        }
    }
    else integers_ok = 0;

    /*********************************************************************
     *                     Parse by vars info macros                     *
     *********************************************************************/

    ST_double __gtools_k_targets,
              __gtools_k_vars,
              __gtools_k_stats,
              __gtools_k_uniq_vars,
              __gtools_k_uniq_stats,
              __gtools_l_targets,
              __gtools_l_vars,
              __gtools_l_stats,
              __gtools_l_uniq_vars,
              __gtools_l_uniq_stats;

    if ( (rc = SF_scal_use ("__gtools_k_targets",    &__gtools_k_targets))    ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_k_vars",       &__gtools_k_vars))       ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_k_stats",      &__gtools_k_stats))      ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_k_uniq_vars",  &__gtools_k_uniq_vars))  ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_k_uniq_stats", &__gtools_k_uniq_stats)) ) return(rc);

    if ( (rc = SF_scal_use ("__gtools_l_targets",    &__gtools_l_targets))    ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_l_vars",       &__gtools_l_vars))       ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_l_stats",      &__gtools_l_stats))      ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_l_uniq_vars",  &__gtools_l_uniq_vars))  ) return(rc);
    if ( (rc = SF_scal_use ("__gtools_l_uniq_stats", &__gtools_l_uniq_stats)) ) return(rc);

    // Number of variables, targets, stats
    size_t l_targets    = (size_t) __gtools_l_targets + 1;
    size_t l_vars       = (size_t) __gtools_l_vars + 1;
    size_t l_stats      = (size_t) __gtools_l_stats + 1;
    size_t l_uniq_vars  = (size_t) __gtools_l_uniq_vars + 1;
    size_t l_uniq_stats = (size_t) __gtools_l_uniq_stats + 1;

    size_t kvars_targets = (size_t) __gtools_k_targets;
    size_t kvars_source  = (size_t) __gtools_k_uniq_vars;

    // Names of variables, targets, stats
    char targets    [l_targets];
    char vars       [l_vars];
    char stats      [l_stats];
    char uniq_vars  [l_uniq_vars];
    char uniq_stats [l_uniq_stats];

    // <rant>
    // Have you ever wondered why Stata globals can be up to 32
    // characters in length but locals can only be up to 31? No? Well,
    // when you are trying to copy local macros into C you run into
    // this problem: Local macros in Stata are actually global macros
    // preceded with an underscore.
    //
    // I know; mind = blown. Try this in stata
    //
    //     local a = 12
    //     di $_a, `a'
    //
    // Where is this documented? How does this make sense? Why is this
    // implemented like this? Who knows!
    //
    // </rant>

    // Read in macros with space-delimited variable, target, and statistic names
    if ( (rc = SF_macro_use ("_gtools_targets",    targets,    l_targets))    ) return(rc);
    if ( (rc = SF_macro_use ("_gtools_vars",       vars,       l_vars))       ) return(rc);
    if ( (rc = SF_macro_use ("_gtools_stats",      stats,      l_stats))      ) return(rc);
    if ( (rc = SF_macro_use ("_gtools_uniq_vars",  uniq_vars,  l_uniq_vars))  ) return(rc);
    if ( (rc = SF_macro_use ("_gtools_uniq_stats", uniq_stats, l_uniq_stats)) ) return(rc);

    st_info->statstr = malloc (sizeof(char*) * l_stats);
    memcpy (st_info->statstr, stats, l_stats);
    // NOTE: I can't do this here bc C complains about pointers I don't.
    // need this until collapse anyway, so I do it there               .
    // char *stat[kvars_targets], *strstat, *ptr;
    // strstat = strtok_r (stats, " ", &ptr);
    // for (k = 0; k < kvars_targets; k++) {
    //     stat[k] = strstat;
    //     strstat = strtok_r (NULL, " ", &ptr);
    // }

    /*********************************************************************
     *                   Which hashing strategy to use                   *
     *********************************************************************/

    size_t strlen = byvars_maxlen > 0? byvars_maxlen + 1: 1;

    // size_t start_target_vars = start_collapse_vars;
    size_t start_target_vars = start_collapse_vars + kvars_source;
    size_t start_str_byvars  = start_target_vars + kvars_targets;

    st_info->pos_targets    = calloc(kvars_targets, sizeof st_info->pos_targets);
    st_info->pos_num_byvars = calloc(kvars_by_num,  sizeof st_info->pos_num_byvars);
    st_info->pos_str_byvars = calloc(kvars_by_str,  sizeof st_info->pos_str_byvars);

    double pos_targets_double[kvars_targets];
    double pos_str_byvars_double[kvars_by_str];
    double pos_num_byvars_double[kvars_by_num];

    if ( (rc = sf_get_vector("__gtools_outpos", pos_targets_double)) ) return(rc);
    for (k = 0; k < kvars_targets; k++)
        st_info->pos_targets[k] = (int) pos_targets_double[k];

    if ( kvars_by_str > 0 ) {
        if ( (rc = sf_get_vector("__gtools_strpos", pos_str_byvars_double)) ) return(rc);
        for (k = 0; k < kvars_by_str; k++)
            st_info->pos_str_byvars[k] = (int) pos_str_byvars_double[k];
    }

    if ( kvars_by_num > 0 ) {
        if ( (rc = sf_get_vector("__gtools_numpos", pos_num_byvars_double)) ) return(rc);
        for (k = 0; k < kvars_by_num; k++)
            st_info->pos_num_byvars[k] = (int) pos_num_byvars_double[k];
    }

    st_info->in1                 = in1;
    st_info->in2                 = in2;
    st_info->N                   = N;
    st_info->kvars_targets       = kvars_targets;
    st_info->kvars_source        = kvars_source;
    st_info->kvars_by            = kvars_by;
    st_info->kvars_by_num        = kvars_by_num;
    st_info->kvars_by_str        = kvars_by_str;
    st_info->start_collapse_vars = start_collapse_vars;
    st_info->start_target_vars   = start_target_vars;
    st_info->start_str_byvars    = start_str_byvars;
    st_info->verbose             = verbose;
    st_info->benchmark           = benchmark;
    st_info->integers_ok         = integers_ok;
    st_info->byvars_minlen       = byvars_minlen;
    st_info->byvars_maxlen       = byvars_maxlen;
    st_info->strlen              = strlen;

    if ( benchmark ) sf_running_timer (&timer, "\tPlugin step 1: stata parsing done");
    return (0);
}

int sf_hash_byvars (struct StataInfo *st_info)
{
    ST_retcode rc ;
    int i, j;
    clock_t timer = clock();
    size_t J, nj_min, nj_max;
    size_t *info;

    // Hash the data
    // -------------

    // Hashing: Throughout the code we allocate to heap bc C may run out
    // of memory in the stack
    //
    size_t *index    = calloc(st_info->N, sizeof *index);
    uint64_t *ghash1 = calloc(st_info->N, sizeof *ghash1);
    uint64_t *ghash, *ghash2;

    if ( st_info->integers_ok ) {

        // Construct the hash using whole numbers
        // --------------------------------------

        // If al integers are passed, try to use them as the hash by doing
        // a bijection to the whole numbers.

        if ( st_info->kvars_by > 1 ) {
            if ( st_info->verbose )
                sf_printf("Hashing %d integer by variables to whole-nubmer index.\n", st_info->kvars_by);
            if ( (rc = sf_get_varlist_bijection (ghash1, 1,
                                                 st_info->kvars_by,
                                                 st_info->in1,
                                                 st_info->in2,
                                                 st_info->byvars_mins,
                                                 st_info->byvars_maxs)) ) return(rc);
        }
        else {
            if ( st_info->verbose )
                sf_printf("Using sole integer by variable as hash.\n", st_info->kvars_by);
            if ( (rc = sf_get_variable_ashash (ghash1, 1,
                                               st_info->in1,
                                               st_info->in2,
                                               st_info->byvars_mins[0])) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        // Index the hash using a radix sort
        // ---------------------------------

        // index[i] gives the position in Stata of the ith entry
        mf_radix_sort_index (ghash1, index, st_info->N, RADIX_SHIFT, 0, st_info->verbose);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Sorted on integer-only hash index");

        // info[j], info[j + 1] give the starting and ending position of the
        // jth group in index. So the jth group can be called by looping
        // through index[i] for i = info[j] to i < info[j + 1]
        info = mf_panelsetup (ghash1, st_info->N, &J);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Set up variables for main collapse loop");
    }
    else {

        // If non-integers, mix of numbers and strings, or if the bijection could fail,
        // hash the data using Jenkin's 128-bit spooky hash.
        //
        // References
        //     en.wikipedia.org/wiki/Jenkins_hash_function
        //     burtleburtle.net/bob/hash/spooky.html
        //     github.com/centaurean/spookyhash

        ghash2 = calloc(st_info->N, sizeof *ghash2);
        if ( st_info->kvars_by > 1 ) {
            if ( st_info->verbose ) {
                if ( st_info->byvars_maxlen > 0 ) {
                    if ( st_info->byvars_minlen > 0 ) {
                        sf_printf("Using 128-bit hash to index %d string-only by variables.\n", st_info->kvars_by);
                    }
                    else {
                        sf_printf("Using 128-bit hash to index %d by variables (string and numeric).\n", st_info->kvars_by);
                    }
                }
                else {
                    sf_printf("Using 128-bit hash to index %d numeric-only by variables", st_info->kvars_by);
                }
            }
            if ( (rc = sf_get_varlist_hash (ghash1, ghash2, 1,
                                            st_info->kvars_by,
                                            st_info->in1,
                                            st_info->in2,
                                            st_info->byvars_lens)) ) return(rc);
        }
        else {
            if ( (st_info->byvars_lens[0] > 0) & st_info->verbose ) {
                sf_printf("Using 128-bit hash to index string by variable.\n", st_info->kvars_by);
            }
            else if ( st_info->verbose ) {
                sf_printf("Using 128-bit hash to index numeric by variable.\n", st_info->kvars_by);
            }
            if ( (rc = sf_get_variable_hash (ghash1, ghash2, 1,
                                             st_info->in1,
                                             st_info->in2,
                                             st_info->byvars_lens[0])) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        // Index the hash using a radix sort
        // ---------------------------------

        // index[i] gives the position in Stata of the ith entry
        mf_radix_sort_index (ghash1, index, st_info->N, RADIX_SHIFT, 0, st_info->verbose);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Sorted on integer-only hash index");

        // Copy ghash2 in case you will need it
        ghash = calloc(st_info->N, sizeof *ghash);
        for (i = 0; i < st_info->N; i++) {
            ghash[i] = ghash2[index[i]];
        }
        free (ghash2);

        // info[j], info[j + 1] give the starting and ending position of the
        // jth group in index. So the jth group can be called by looping
        // through index[i] for i = info[j] to i < info[j + 1]
        info = mf_panelsetup128 (ghash1, ghash, index, st_info->N, &J);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Set up variables for main collapse loop");
        free (ghash);
    }
    free (ghash1);

    // Group size info
    // ---------------

    nj_min = info[1] - info[0];
    nj_max = info[1] - info[0];
    for (j = 1; j < J; j++) {
        if (nj_min > (info[j + 1] - info[j])) nj_min = (info[j + 1] - info[j]);
        if (nj_max < (info[j + 1] - info[j])) nj_max = (info[j + 1] - info[j]);
    }

    if ( st_info->verbose ) {
        if ( nj_min == nj_max )
            sf_printf ("N = %'lu; %'lu balanced groups of size %'lu\n", st_info->N, J, nj_min);
        else
            sf_printf ("N = %'lu; %'lu unbalanced groups of sizes %'lu to %'lu\n", st_info->N, J, nj_min, nj_max);
    }

    st_info->J      = J;
    st_info->nj_min = nj_min;
    st_info->nj_max = nj_max;

    st_info->info   = calloc(J + 1, sizeof *info);
    for (j = 0; j < J + 1; j++)
        st_info->info[j] = info[j];
    free (info);

    st_info->index  = calloc(st_info->N, sizeof *index);
    for (i = 0; i < st_info->N + 1; i++)
        st_info->index[i] = index[i];
    free (index);

    return (0);
}

int sf_collapse (struct StataInfo *st_info)
{
    ST_double  z;
    ST_retcode rc ;
    int i, j, k;
    char s[st_info->strlen];
    clock_t timer = clock();

    size_t nj, start, end, sel;
    size_t offset_output,
           offset_bynum,
           offset_source,
           offset_buffer;

    size_t nmfreq[st_info->kvars_source],
           nonmiss[st_info->kvars_source],
           firstmiss[st_info->kvars_source],
           lastmiss[st_info->kvars_source];

    double *bynum   = calloc(st_info->kvars_by_num  * st_info->J, sizeof *bynum);
    short  *bymiss  = calloc(st_info->kvars_by_num  * st_info->J, sizeof *bymiss);
    double *output  = calloc(st_info->kvars_targets * st_info->J, sizeof *output);
    short  *outmiss = calloc(st_info->kvars_targets * st_info->J, sizeof *outmiss);
    double *buffer  = calloc(st_info->kvars_source  * st_info->nj_max, sizeof *output);

    double *all_buffer     = calloc(st_info->kvars_source * st_info->N, sizeof *all_buffer);
    short  *all_firstmiss  = calloc(st_info->kvars_source * st_info->J, sizeof *all_firstmiss);
    short  *all_lastmiss   = calloc(st_info->kvars_source * st_info->J, sizeof *all_lastmiss );
    size_t *all_nonmiss    = calloc(st_info->kvars_source * st_info->J, sizeof *all_nonmiss);
    size_t *offsets_buffer = calloc(st_info->J, sizeof *offsets_buffer);

    char *stat[st_info->kvars_targets], *strstat, *ptr;
    strstat = strtok_r (st_info->statstr, " ", &ptr);
    for (k = 0; k < st_info->kvars_targets; k++) {
        stat[k] = strstat;
        strstat = strtok_r (NULL, " ", &ptr);
    }

    for (i = 0; i < st_info->kvars_by_num * st_info->J; i++)
        bymiss[i] = 0;

    for (i = 0; i < st_info->kvars_targets * st_info->J; i++)
        outmiss[i] = 0;

    for (k = 0; k < st_info->kvars_source; k++)
        nmfreq[k] = nonmiss[k] = firstmiss[k] = lastmiss[k] = 0;

    for (j = 0; j < st_info->J * st_info->kvars_source; j++)
        all_firstmiss[j] = all_lastmiss[j] = all_nonmiss[j] = 0;

    offset_buffer = offset_source = 0;
    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        nj     = end - start;
        for (i = start; i < end; i++) {
            sel = st_info->index[i] + st_info->in1;
            for (k = 0; k < st_info->kvars_source; k++) {
                if ( (rc = SF_vdata(k + st_info->start_collapse_vars, sel, &z)) ) return(rc);
                if ( SF_is_missing(z) ) {
                    if (i == start)   all_firstmiss[offset_source + k] = 1;
                    if (i == end - 1) all_lastmiss[offset_source + k]  = 1;
                }
                else {
                    all_buffer [offset_buffer + nj * k + all_nonmiss[offset_source + k]++] = z;
                }
            }
        }
        offsets_buffer[j] = offset_buffer;
        offset_buffer    += nj * st_info->kvars_source;
        offset_source    += st_info->kvars_source;
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read in source variables");

    for (j = 0; j < st_info->J; j++)
        for (k = 0; k < st_info->kvars_source; k++)
            nmfreq[k] += all_nonmiss[j * st_info->kvars_source + k];

    for (j = 0; j < st_info->J; j++) {
        offset_output = j * st_info->kvars_targets;
        offset_source = j * st_info->kvars_source;
        offset_buffer = offsets_buffer[j];
        nj = st_info->info[j + 1] - st_info->info[j];
        for (k = 0; k < st_info->kvars_targets; k++) {
            sel   = offset_source + st_info->pos_targets[k];
            start = offset_buffer + nj * st_info->pos_targets[k];
            end   = all_nonmiss[sel];

            if ( mf_strcmp_wrapper (stat[k], "count") ) {
                output[offset_output + k] = end;
            }
            else if ( mf_strcmp_wrapper (stat[k], "percent")  ) {
                output[offset_output + k] = 100 * end;
            }
            else if ( all_firstmiss[sel] & (mf_strcmp_wrapper (stat[k], "first") ) ) {
                outmiss[offset_output + k] = 1;
            }
            else if ( all_lastmiss[sel] & (mf_strcmp_wrapper (stat[k], "last") ) ) {
                outmiss[offset_output + k] = 1;
            }
            else if ( mf_strcmp_wrapper (stat[k], "first") | (mf_strcmp_wrapper (stat[k], "firstnm") ) ) {
                output[offset_output + k] = all_buffer[start];
            }
            else if ( mf_strcmp_wrapper (stat[k], "last") | (mf_strcmp_wrapper (stat[k], "lastnm") ) ) {
                output[offset_output + k] = all_buffer[start + end - 1];
            }
            else if ( mf_strcmp_wrapper (stat[k], "sd") &  (end < 2) ) {
                outmiss[offset_output + k] = 1;
            }
            else if ( end == 0 ) {
                outmiss[offset_output + k] = 1;
            }
            else {
                output[offset_output + k] = mf_switch_fun (stat[k], all_buffer, start, start + end);
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Collapsed source variables");

    free (all_buffer);
    free (all_firstmiss);
    free (all_lastmiss);
    free (all_nonmiss);
    free (offsets_buffer);

    offset_bynum = 0;
    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[j];
        for (k = 0; k < st_info->kvars_by_str; k++) {
            if ( (rc = SF_sdata(st_info->pos_str_byvars[k], st_info->index[start] + st_info->in1, s)) ) return(rc);
            if ( (rc = SF_sstore(k + st_info->start_str_byvars, j + 1, s)) ) return(rc);
        }
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
    free (buffer);

    // Copy output back into Stata
    // ---------------------------

    offset_output = offset_bynum = 0;
    for (j = 0; j < st_info->J; j++) {
        for (k = 0; k < st_info->kvars_targets; k++) {
            sel = offset_output + k;
            if ( mf_strcmp_wrapper (stat[k], "percent") ) output[sel] /= nmfreq[st_info->pos_targets[k]];
            if ( (rc = SF_vstore(k + st_info->start_target_vars, j + 1, outmiss[sel]? SV_missval: output[sel])) ) return (rc);
        }
        for (k = 0; k < st_info->kvars_by_str; k++) {
            if ( (rc = SF_sdata(k + st_info->start_str_byvars, j + 1, s)) ) return(rc);
            if ( (rc = SF_sstore(st_info->pos_str_byvars[k], j + 1, s)) ) return(rc);
        }
        for (k = 0; k < st_info->kvars_by_num; k++) {
            sel = offset_bynum + k;
            if ( (rc = SF_vstore(st_info->pos_num_byvars[k], j + 1, bymiss[sel]? SV_missval: bynum[sel])) ) return(rc);
        }
        offset_output += st_info->kvars_targets;
        offset_bynum += st_info->kvars_by_num;
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 6: Copied collapsed variables back to stata");

    free (output);
    free (bynum);
    free (bymiss);
    free (outmiss);

    return(0);
}

void sf_free (struct StataInfo *st_info)
{
    free (st_info->info);
    free (st_info->index);
    free (st_info->byvars_lens);
    free (st_info->byvars_mins);
    free (st_info->byvars_maxs);
    free (st_info->pos_targets);
    free (st_info->pos_num_byvars);
    free (st_info->pos_str_byvars);
}
