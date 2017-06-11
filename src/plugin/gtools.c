/*********************************************************************
 * Program: gtools.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Sat Jun 10 20:09:36 EDT 2017
 * Purpose: Stata plugin to compute a faster -collapse- and -egen-
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.5.0
 *********************************************************************/

/**
 * @file gtools.c
 * @author Mauricio Caceres Bravo
 * @date 16 May 2017
 * @brief Stata plugin for a faster -collapse- and -egen- implementation
 *
 * This file should only ever be called from gcollapse.ado or gegen.ado
 *
 * @see help gcollapse, help egen, gcollapse.c, gegen.c
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include "gtools.h"
#include "spi/stplugin.h"
#include "spt/st_gentools.c"
#include "gtools_utils.c"
#include "gtools_hash.c"
#include "gtools_sort.c"
#include "gtools_math.c"

// -DGMUTI=1 flag compiles multi-threaded version of the plugin
#if GMULTI
#include "gcollapse_multi.c"
#include "gegen_multi.c"
#include "gtools_misc_multi.c"
#else
#include "gcollapse.c"
#include "gegen.c"
#include "gtools_misc.c"
#endif

/* TODO: implement clean_exit(rc, level, ...) instead of return(rc) where you free
 * objects in memory and print an error message based on 'level' // 2017-05-20 14:09 EDT
 */

STDLL stata_call(int argc, char *argv[])
{
    if (argc < 1) {
        sf_errprintf ("Nothing to do. Available: -collapse- and -egen-\n");
        return (198);
    }

    ST_retcode rc ;
    setlocale (LC_ALL, "");
    struct StataInfo st_info;
    char todo[8], tostat[8];
    strcpy (todo, argv[0]);

    // Note: These are set in sf_parse_info from Stata
    // st_info.read_method       = 1; // Sequentially
    // st_info.read_method_multi = 1; // Sequentially
    // st_info.read_method       = 2; // Out of order
    // st_info.read_method_multi = 3; // Out of order in parallel

    if ( strcmp(todo, "collapse") == 0 ) {
        if ( (rc = sf_parse_info  (&st_info, 0)) ) return (rc);
        if ( (rc = sf_hash_byvars (&st_info))    ) return (rc);
        if ( st_info.checkhash ) {
            if ( (rc = sf_check_hash_index (&st_info)) ) return (rc);
        }

        if ( (rc = sf_collapse    (&st_info))    ) return (rc);
        if ( (rc = SF_scal_save   ("__gtools_J", st_info.J)) ) return (rc);

        sf_free (&st_info);
        return (0);
    }
    else if ( strcmp(todo, "egen") == 0 ) {
        if (argc < 2) {
            sf_errprintf ("No stats requested. See: -help egen-\n");
            return (198);
        }
        if ( (rc = sf_parse_info  (&st_info, 1)) ) return (rc);
        if ( (rc = sf_hash_byvars (&st_info))    ) return (rc);
        if ( st_info.checkhash ) {
            if ( (rc = sf_check_hash_index (&st_info)) ) return (rc);
        }

        strcpy (tostat, argv[1]);
        if ( strcmp(tostat, "group") == 0 ) {
            if ( (rc = sf_egen_group (&st_info)) ) return (rc);
        }
        else if ( strcmp(tostat, "tag") == 0 ) {
            if ( (rc = sf_egen_tag (&st_info)) ) return (rc);
        }
        else {
            if ( (rc = sf_egen (&st_info)) ) return (rc);
        }

        sf_free (&st_info);
        return (0);
    }
    else if ( strcmp(todo, "setup") == 0 ) {
        if ( (rc = sf_numsetup()) ) return (rc);
        return (0);
    }
    else if ( strcmp(todo, "check") == 0 ) {
        sf_printf ("(plugin -gtools- was loaded correctly)\n");
        return (0);
    }

    sf_printf ("Nothing to do; pugin should be called from -gcollapse- or -gegen-\n");
    return(0);
}

/**
 * @brief Parse variable info from Stata
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores in @st_info various info from Stata for the pugin run
 */
int sf_parse_info (struct StataInfo *st_info, int level)
{
    ST_retcode rc ;
    int i, k;
    clock_t timer = clock();

    // Get start and end position; number of variables
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

    // Check for hash collisions
    int checkhash;
    ST_double checkhash_double ;
    if ( (rc = SF_scal_use("__gtools_checkhash", &checkhash_double)) ) {
        return(rc) ;
    }
    else {
        checkhash = (int) checkhash_double;
    }

    // read_method
    int read_method, read_method_multi;
    ST_double read_method_double ;
    if ( (rc = SF_scal_use("__gtools_read_method", &read_method_double)) ) {
        return(rc) ;
    }
    else {
        read_method = (int) read_method_double;
    }

    if ( read_method == 0 ) {
        read_method = 1;
        read_method_multi = 0;
    }
    else {
        read_method_multi = read_method;
    }

    // Collapse method
    int collapse_method;
    ST_double coll_method_double ;
    if ( (rc = SF_scal_use("__gtools_collapse_method", &coll_method_double)) ) {
        return(rc) ;
    }
    else {
        collapse_method = (int) coll_method_double;
    }

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

    // Merge back to original data
    int merge;
    ST_double merge_double ;
    if ( (rc = SF_scal_use("__gtools_merge", &merge_double)) ) {
        return(rc) ;
    }
    else {
        merge = (int) merge_double;
    }

    // Data set for indexing
    int indexed;
    ST_double ix_double ;
    if ( (rc = SF_scal_use("__gtools_indexed", &ix_double)) ) {
        return(rc) ;
    }
    else {
        indexed = (int) ix_double;
    }

    /*********************************************************************
     *                    Parse by vars info vectors                     *
     *********************************************************************/

    // byvars_lens:
    //     - For strings, the variable length
    //     - We store floats and doubles as double; we code "length" as 0
    //     - We store integers as uint64_t; we code "length" as -1
    // byvars_mins:
    //     - Smallest string length. If 0 or -1 we can figure out
    //       whether we have doubles or integers in the by variables.
    // byvars_maxs:
    //     - Largest string length. If 0 or -1 we can figure out
    //       whether we only have numbers for by variables.
    st_info->byvars_lens = calloc(kvars_by, sizeof st_info->byvars_lens);
    st_info->byvars_mins = calloc(kvars_by, sizeof st_info->byvars_mins);
    st_info->byvars_maxs = calloc(kvars_by, sizeof st_info->byvars_maxs);

    double byvars_lens_double[kvars_by],
           byvars_mins_double[kvars_by],
           byvars_maxs_double[kvars_by];

    if ( (rc = sf_get_vector("__gtools_byk",   byvars_lens_double)) ) return(rc);
    if ( (rc = sf_get_vector("__gtools_bymin", byvars_mins_double)) ) return(rc);
    if ( (rc = sf_get_vector("__gtools_bymax", byvars_maxs_double)) ) return(rc);

    for (i = 0; i < kvars_by; i++) {
        st_info->byvars_lens[i] = (int) byvars_lens_double[i];
        st_info->byvars_mins[i] = (int) byvars_mins_double[i];
        st_info->byvars_maxs[i] = (int) byvars_maxs_double[i];
    }

    // Get count of numeric and string by variables
    size_t kvars_by_str = 0;
    for (i = 0; i < kvars_by; i++) {
        kvars_by_str += (st_info->byvars_lens[i] > 0);
    }
    size_t kvars_by_num = kvars_by - kvars_by_str;

    // If only integers, check worst case of the bijection would not
    // overflow. Given K by variables, by_1 to by_K, where by_k belongs
    // to the set B_k, the general problem we face is devising a
    // function f such that f: B_1 x ... x B_K -> N, where N are the
    // natural (whole) numbers. For integers, we don't need to hash
    // the data:
    //
    //     1. The first variable: z[i, 1] = f(1)(x[i, 1]) = x[i, 1] - min(x[, 1]) + 1
    //     2. The kth variable: z[i, k] = f(k)(x[i, k]) = i * range(z[, k - 1]) + (x[i, k - 1] - min(x[, 2]))
    //
    // If we have too many by variables, it is possible our integers
    // will overflow. We check whether this may happen below.

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

    size_t kvars_targets = 1;
    size_t kvars_source  = 1;
    if ( level == 0 ) {
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

        kvars_targets = (size_t) __gtools_k_targets;
        kvars_source  = (size_t) __gtools_k_uniq_vars;

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
        // Right? Where is this documented? How does this make sense? Why is
        // this implemented like this? Who knows!
        //
        // </rant>

        // Read in macros with space-delimited variable, target, and statistic names
        if ( (rc = SF_macro_use ("_gtools_targets",    targets,    l_targets))    ) return(rc);
        if ( (rc = SF_macro_use ("_gtools_vars",       vars,       l_vars))       ) return(rc);
        if ( (rc = SF_macro_use ("_gtools_stats",      stats,      l_stats))      ) return(rc);
        if ( (rc = SF_macro_use ("_gtools_uniq_vars",  uniq_vars,  l_uniq_vars))  ) return(rc);
        if ( (rc = SF_macro_use ("_gtools_uniq_stats", uniq_stats, l_uniq_stats)) ) return(rc);

        // Save summary statistics to be computed
        st_info->statstr = malloc (sizeof(char*) * l_stats);
        memcpy (st_info->statstr, stats, l_stats);

        st_info->kvars_targets = kvars_targets;
        st_info->kvars_source  = kvars_source;
    }
    else if ( level == 1 ) {
        ST_double __gtools_k_vars, __gtools_l_stats;

        if ( (rc = SF_scal_use ("__gtools_k_vars",  &__gtools_k_vars))  ) return(rc);
        if ( (rc = SF_scal_use ("__gtools_l_stats", &__gtools_l_stats)) ) return(rc);

        kvars_targets  = 1;
        kvars_source   = (size_t) __gtools_k_vars;
        size_t l_stats = (size_t) __gtools_l_stats + 1;

        char stats [l_stats];
        if ( (rc = SF_macro_use ("_gtools_stats", stats, l_stats)) ) return(rc);

        st_info->statstr = malloc (sizeof(char*) * l_stats);
        memcpy (st_info->statstr, stats, l_stats);

        st_info->kvars_targets = kvars_targets;
        st_info->kvars_source  = kvars_source;
    }

    /*********************************************************************
     *           Relative position of targets and by variables           *
     *********************************************************************/

    size_t strmax = byvars_maxlen > 0? byvars_maxlen + 1: 1;

    size_t start_target_vars = start_collapse_vars + kvars_source;
    size_t start_str_byvars  = start_target_vars + kvars_targets;

    st_info->pos_targets    = calloc(kvars_targets, sizeof st_info->pos_targets);
    st_info->pos_num_byvars = calloc(kvars_by_num,  sizeof st_info->pos_num_byvars);
    st_info->pos_str_byvars = calloc(kvars_by_str,  sizeof st_info->pos_str_byvars);

    double pos_str_byvars_double[kvars_by_str];
    double pos_num_byvars_double[kvars_by_num];

    // pos_targets[k] gives the source variable for the kth target
    if  ( level == 0 ) {
        double pos_targets_double[kvars_targets];
        if ( (rc = sf_get_vector("__gtools_outpos", pos_targets_double)) ) return(rc);
        for (k = 0; k < kvars_targets; k++)
            st_info->pos_targets[k] = (int) pos_targets_double[k];
    }
    else if ( level == 1 ) {
        st_info->pos_targets[0] = start_target_vars;
    }

    // pos_str_byvars[k] gives the position in the by variables of the kth string variable
    if ( kvars_by_str > 0 ) {
        if ( (rc = sf_get_vector("__gtools_strpos", pos_str_byvars_double)) ) return(rc);
        for (k = 0; k < kvars_by_str; k++)
            st_info->pos_str_byvars[k] = (int) pos_str_byvars_double[k];
    }

    // pos_num_byvars[k] gives the position in the by variables of the kth numeric variable
    if ( kvars_by_num > 0 ) {
        if ( (rc = sf_get_vector("__gtools_numpos", pos_num_byvars_double)) ) return(rc);
        for (k = 0; k < kvars_by_num; k++)
            st_info->pos_num_byvars[k] = (int) pos_num_byvars_double[k];
    }

    // Save into st_info structure
    st_info->in1                 = in1;
    st_info->in2                 = in2;
    st_info->N                   = N;
    st_info->kvars_by            = kvars_by;
    st_info->kvars_by_num        = kvars_by_num;
    st_info->kvars_by_str        = kvars_by_str;
    st_info->start_collapse_vars = start_collapse_vars;
    st_info->start_target_vars   = start_target_vars;
    st_info->start_str_byvars    = start_str_byvars;
    st_info->checkhash           = checkhash;
    st_info->verbose             = verbose;
    st_info->benchmark           = benchmark;
    st_info->merge               = merge;
    st_info->indexed             = indexed;
    st_info->integers_ok         = integers_ok;
    st_info->byvars_minlen       = byvars_minlen;
    st_info->byvars_maxlen       = byvars_maxlen;
    st_info->strmax              = strmax;
    st_info->read_method         = read_method;
    st_info->read_method_multi   = read_method_multi;
    st_info->collapse_method     = collapse_method;

    if ( benchmark ) sf_running_timer (&timer, "\tPlugin step 1: stata parsing done");
    return (0);
}

/**
 * @brief Hash by variables using 64-bit or 128-bit hash, as applicable
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores in @st_info the resulting hash index and by group info
 */
int sf_hash_byvars (struct StataInfo *st_info)
{
    ST_retcode rc ;
    ST_double z ;
    int i, j;
    clock_t timer = clock();
    size_t J, nj_min, nj_max;
    size_t *info;

    // Hash the data
    // -------------

    // Hashing: Throughout the code we allocate to heap bc C may run out
    // of memory in the stack.
    size_t *index    = calloc(st_info->N, sizeof *index);
    uint64_t *ghash1 = calloc(st_info->N, sizeof *ghash1);
    uint64_t *ghash, *ghash2;

    if ( st_info->indexed > 0 ) {
        if ( st_info->verbose )
            sf_printf("Using index provided by stata (data was already soreted).\n");

        for (i = 0; i < st_info->N; i++) {
            if ( (rc = SF_vdata(st_info->indexed, i + st_info->in1, &z)) ) return(rc);
            ghash1[i] = (size_t) z;
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Read in index helper");

        index[0] = 0;
        for (i = 1; i < st_info->N; i++) {
            index[i]   = i;
            ghash1[i] += ghash1[i - 1];
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Set up index from Stata");

        info = mf_panelsetup (ghash1, st_info->N, &J);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Set up variables for main group loop");
    }
    else if ( st_info->integers_ok ) {

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
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Set up variables for main group loop");
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
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Set up variables for main group loop");
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

    // Copy info and index; since we don't know how many groups or
    // observations there will be and we want to pass info and index
    // across functions, we initialize them as pointers within the
    // st_info structure. Assignning elements to them as if they were
    // arrays after they were initialized as pointers was a bit tricky
    // because I have to allocate space in memory for the arrays. Hence
    // we copy elements back like this:

    st_info->info = calloc(J + 1, sizeof *info);
    for (j = 0; j < J + 1; j++)
        st_info->info[j] = info[j];
    free (info);

    st_info->index = calloc(st_info->N, sizeof *index);
    for (i = 0; i < st_info->N; i++)
        st_info->index[i] = index[i];
    free (index);

    return (0);
}

/**
 * @brief Clean up st_info
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Frees memory allocated to st_info objects
 */
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
