/*********************************************************************
 * Program: gtools.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Tue Sep 26 12:05:32 EDT 2017
 * Purpose: Stata plugin to compute a faster -collapse- and -egen-
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.7.5
 *********************************************************************/

/**
 * @file gtools.c
 * @author Mauricio Caceres Bravo
 * @date 17 Jul 2017
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
#include "tools/gtools_utils.c"
#include "hash/gtools_sort.c"
#include "tools/gtools_math.c"
#include "tools/quicksortMultiLevel.c"
#include "tools/radixSort.c"
#include "hash/gtools_hash.c"
#include "extra/common.c"
#include "extra/gisid.c"
#include "extra/glevelsof.c"
#include "extra/hashsort.c"

// -DGMUTI=1 flag compiles multi-threaded version of the plugin
#if GMULTI
/* #include "hash/gtools_hash_multi.c" */
#include "collapse/gcollapse_multi.c"
#include "egen/gegen_multi.c"
#include "tools/gtools_misc_multi.c"
#else
/* #include "hash/gtools_hash.c" */
#include "collapse/gcollapse.c"
#include "egen/gegen.c"
#include "tools/gtools_misc.c"
#endif

int main()
{
    return(0);
}

int WinMain()
{
    return(0);
}

/* TODO: implement clean_exit(rc, level, ...) instead of return(rc) where you free
 * objects in memory and print an error message based on 'level' // 2017-05-20 14:09 EDT
 */
STDLL stata_call(int argc, char *argv[])
{
    if (argc < 1) {
        sf_errprintf ("Nothing to do. Available: -collapse- , -egen-, -isid-, -levelsof-\n");
        return (198);
    }

    ST_double  z;
    ST_retcode rc = 0;
    setlocale(LC_ALL, "");

    int i, j, k;
    struct StataInfo *st_info = malloc(sizeof(*st_info));
    char *todo   = malloc(sizeof(char) * 16); memset(todo,   '\0', sizeof(char) * 16);
    char *tostat = malloc(sizeof(char) * 16); memset(tostat, '\0', sizeof(char) * 16);
    strcpy (todo, argv[0]);

    if ( strcmp(todo, "check") == 0 ) {

        // Exit; if you're here the plugin was loaded fine
        // -----------------------------------------------

        rc = 0; goto exit;
    }
    else if ( strcmp(todo, "collapse") == 0 ) {

        /*********************************************************************
         *                             Collapse                              *
         *********************************************************************/

        if ( argc < 2 ) {

            // Collapse 1: Work in memory (targets already exist in Stata)
            // -----------------------------------------------------------

            if ( (rc = sf_parse_info       (st_info, 0))     ) return (rc); // Various aux data from gcollapse.ado
            if ( (rc = sf_hash_byvars      (st_info))        ) return (rc); // Hash grouping (by) variables
            if ( (rc = sf_check_hash_index (st_info, 1))     ) return (rc); // Check hash index is correctly sorted
            if ( (rc = sf_collapse         (st_info, 0, "")) ) return (rc); // Collapse data by hash index
            if ( (rc = SF_scal_save ("__gtools_J", st_info->J)) ) return (rc); // Save number of groups to Stata

            sf_free (st_info);
            rc = 0; goto exit;
        }
        else if ( argc < 3 ) {
            sf_errprintf ("collapse sub-commands must also specify a file.\n");
            rc = 198; goto exit;
        }
        else {

            // Collapse 2: Work with disk
            // --------------------------

            // Here gtools assumes you want a sub-command. All sub-commands do
            // operations on a file. The call is:
            //
            //     collapse sub-command file

            char *fname = malloc(sizeof(char) * (strlen(argv[2]) + 1));
            memset (fname, '\0', sizeof(char) * (strlen(argv[2]) + 1));
            strcpy (fname,  argv[2]);
            strcpy (tostat, argv[1]);

            if ( strcmp(tostat, "ixwrite") == 0 ) {

                // Collapse to disk right away (for -forceio-)
                // -------------------------------------------

                if ( (rc = sf_parse_info       (st_info, 0))        ) return (rc); // Various aux data from gcollapse.ado
                if ( (rc = sf_hash_byvars      (st_info))           ) return (rc); // Hash grouping (by) variables
                if ( (rc = sf_check_hash_index (st_info, 1))        ) return (rc); // Check hash index is correctly sorted
                if ( (rc = sf_collapse         (st_info, 1, fname)) ) return (rc); // Collapse data by hash index to disk
                if ( (rc = SF_scal_save ("__gtools_J", st_info->J)) ) return (rc); // Save number of groups to Stata

                sf_free (st_info);
                free (fname);
                rc = 0; goto exit;
            }
            else if ( strcmp(tostat, "index") == 0 ) {

                // Estimate disk vs memory collapse
                // --------------------------------

                // The function tries to estimate how much time it would take
                // to add extra targets in memory vs using I/O. It aborts and
                // writes the index and info to Stata if it's estimated that
                // I/O will be slower (and will collapse later to memory).

                double rate_st, mib_base, threshold, k_extra;
                double rate_c   = mf_benchmark(fname);
                double mib_free = mf_query_free_space(fname);

                if ( (rc = SF_scal_use  ("__gtools_bench_st",  &rate_st))   ) return(rc);
                if ( (rc = SF_scal_use  ("__gtools_mib_base",  &mib_base))  ) return(rc);
                if ( (rc = SF_scal_use  ("__gtools_io_thresh", &threshold)) ) return(rc);
                if ( (rc = SF_scal_use  ("__gtools_k_extra",   &k_extra))   ) return(rc);

                // Hash by variables and sort
                if ( (rc = sf_parse_info  (st_info, 0)) ) return (rc);
                if ( (rc = sf_hash_byvars (st_info))    ) return (rc);

                // TODO: Figure out if this makes sense; Stata caps timer at 0.001 // 2017-06-13 20:20 EDT

                // Stata tries to be smart when allocating memory. So sometimes
                // allocating variables will be instant, and other times it will
                // take some time. If it takes < 0.001s, it is possible it will
                // be instant and we should do all in memory, but it is also
                // possible it was trying to be smart.
                //
                // So my current thinking is that when this happens, there is
                // nothing I can do to estimate the times. In this case I assume
                // the rates are 0.001s and 0.001s / threshold for allocating
                // memory before annd after the collapse, respectively. This
                // seems to work OK-ish in practive.

                // Estimate if it will be faster to collapse to disk
                double mib_stata, mib_c, mib_cstata;
                mib_stata  = st_info->N * mib_base * ( (rate_st > 0.001)? rate_st: 0.001 );
                mib_cstata = st_info->J * mib_base * ( (rate_st > 0.001)? rate_st: (0.001 / threshold) );
                mib_c      = st_info->J * mib_base * rate_c;
                if ( (rate_st < 0.001) & st_info->verbose ) {
                    sf_printf("(Stata benchmark inaccurate below 0.001s; assuming benchmark time was 0.001s)\n");
                }
                // mib_c      = st_info->J * mib_base * ( (rate_st > 0.001)? rate_c:  0.001 );
                // mib_cstata = st_info->J * mib_base * rate_st;
                // sf_printf("(Stata benchmark inaccurate below 0.001s; assuming C, Stata times = 0.001)\n");

                // Print some info on the switching criteria to the console
                int used_io;
                if ( QUERY_FREE_SPACE ) {
                    used_io = ( (mib_c < mib_free) & ((mib_c + mib_cstata) < (mib_stata / threshold)) );
                }
                else {
                    used_io = ( (mib_c + mib_cstata) < (mib_stata / threshold) );
                }

                if ( st_info->verbose ) {
                    // I had a cleaner way to do this, but it failed badly on Windows ):
                    sf_printf("Will write "FMT" extra targets to disk (full data = %'.1f MiB; collapsed data = ",
                              (size_t) k_extra, st_info->N * mib_base);
                    sf_printf ((st_info->J * mib_base > 1)? "%.1f": "%.2g", st_info->J * mib_base);
                    sf_printf(" MiB).\n");

                    sf_printf("\tAdding targets before collapse estimated to take ");
                    sf_printf ((mib_stata > 1)? "%.1f": "%.2g", mib_stata);
                    sf_printf(" seconds.\n");

                    sf_printf("\tAdding targets after collapse estimated to take ");
                    sf_printf ((mib_cstata > 1)? "%.1f": "%.2g", mib_cstata);
                    sf_printf(" seconds.\n");

                    sf_printf("\tWriting/reading targets to/from disk estimated to take ");
                    sf_printf ((mib_c > 1)? "%.1f": "%.2g", mib_c);
                    sf_printf(" seconds.\n");
                }

                // Collapse to disk if faster; else abort and save index, info
                // -----------------------------------------------------------

                if ( used_io ) {
                    // Collapse to disk if it will be faster
                    if ( (rc = sf_check_hash_index (st_info, 1)) ) return (rc);
                    if ( (rc = sf_collapse  (st_info, 1, fname)) ) return (rc);
                }
                else {

                    // Otherwise, save index and info to memory (it will be
                    // faster to pick up from here)
                    size_t ipos = st_info->kvars_by + 2 * st_info->kvars_source + 1;
                    for (i = 0; i < st_info->N; i++)
                        if ( (rc = SF_vstore(ipos, i + st_info->in1, st_info->index[i])) ) return (rc);

                    ++ipos;
                    for (j = 0; j <= st_info->J; j++)
                        if ( (rc = SF_vstore(ipos, j + st_info->in1, st_info->info[j])) ) return (rc);
                }

                // Record whether the collapse was already done; if so, Stata
                // will also need to know the nubmer of groups.
                if ( (rc = SF_scal_save ("__gtools_used_io", used_io)) ) return (rc);
                if ( (rc = SF_scal_save ("__gtools_J",    st_info->J)) ) return (rc);

                sf_free (st_info);
                free (fname);
                rc = 0; goto exit;
            }
            else if ( strcmp(tostat, "ixfinish") == 0 ) {

                // If not collapsed to disk, read in index and info and collapse to memory
                // -----------------------------------------------------------------------

                // Pick up from having index and info in memory and collapse
                // to memory, having created the targets in Stata.
                if ( (rc = sf_parse_info (st_info, 0)) ) return (rc);

                ST_double J_double ;
                if ( (rc = SF_scal_use("__gtools_J", &J_double)) ) return(rc);
                st_info->J = (size_t) J_double;

                st_info->index = calloc(st_info->N, sizeof(st_info->index));
                st_info->info  = calloc(st_info->J + 1, sizeof(st_info->info));

                if ( st_info->index == NULL ) return(sf_oom_error("stata_call", "st_info->index"));
                if ( st_info->info  == NULL ) return(sf_oom_error("stata_call", "st_info->info"));

                for (i = 0; i < st_info->N; i++) {
                    if ( (rc = SF_vdata(st_info->indexed, i + st_info->in1, &z)) ) return (rc);
                    st_info->index[i] = (size_t) z;
                }

                for (j = 0; j <= st_info->J; j++) {
                    if ( (rc = SF_vdata(st_info->indexed + 1, j + st_info->in1, &z)) ) return (rc);
                    st_info->info[j] = (size_t) z;
                }

                if ( (rc = sf_check_hash_index (st_info, 1))     ) return (rc);
                if ( (rc = sf_collapse         (st_info, 0, "")) ) return (rc);

                sf_free (st_info);
                free (fname);
                rc = 0; goto exit;
            }
            else if ( strcmp(tostat, "read") == 0 ) {

                // If not collapsed to disk, read collapsed data back into Stata
                // -------------------------------------------------------------

                ST_double J_double, K_double ;
                if ( (rc = SF_scal_use("__gtools_J", &J_double)) ) return(rc);
                size_t J = (size_t) J_double;

                if ( (rc = SF_scal_use("__gtools_k_extra", &K_double)) ) return(rc);
                size_t K = (size_t) K_double;

                double *output = calloc(J * K, sizeof *output);
                if ( output == NULL ) return(sf_oom_error("stata_call", "output"));
                mf_read_collapsed (fname, output, K, J);

                for (j = 0; j < J; j++) {
                    for (k = 0; k < K; k++) {
                        if ( (rc = SF_vstore(k + 1, j + 1, output[j * K + k])) ) return (rc);
                    }
                }

                free (output);
                free (fname);
                rc = 0; goto exit;
            }
            else {
                sf_errprintf ("Invalid -collapse- sub-command '%s'.", tostat);
                rc = 198; goto exit;
            }
        }
    }
    else if ( strcmp(todo, "egen") == 0 ) {

        /*********************************************************************
         *                               Egen                                *
         *********************************************************************/

        // egen call requires second argument, which is the function to compute
        if (argc < 2) {
            sf_errprintf ("No stats requested. See: -help egen-\n");
            rc = 198; goto exit;
        }
        strcpy (tostat, argv[1]);
        short check = strcmp(tostat, "group") == 0;

        // First hash the data and check the index
        if ( (rc = sf_parse_info  (st_info, 1)) ) return (rc);
        if ( (rc = sf_hash_byvars (st_info))    ) return (rc);
        if ( check ) {
            st_info->sort_memory = !(st_info->integers_ok);
            if ( (rc = sf_check_hash_index (st_info, 1)) ) return (rc);
        }
        else {
            if ( (rc = sf_check_hash_index (st_info, 0)) ) return (rc);
        }

        // Now apply the summary stat; group and tag are special
        // operations. Otherwise this follows collapse.

        if ( strcmp(tostat, "group") == 0 ) {
            if ( (rc = sf_egen_group (st_info)) ) return (rc);
        }
        else if ( strcmp(tostat, "tag") == 0 ) {
            if ( (rc = sf_egen_tag (st_info)) ) return (rc);
        }
        else {
            if ( (rc = sf_egen (st_info)) ) return (rc);
        }

        sf_free (st_info);
        rc = 0; goto exit;
    }
    else if ( strcmp(todo, "isid") == 0 ) {
        if ( (rc = sf_parse_info_lean(st_info, 0)) ) return (rc);
        rc = sf_hash_byvars_isid (st_info);
        st_info->info = malloc(sizeof(size_t));
        sf_free_lean (st_info);
        goto exit;
    }
    else if ( strcmp(todo, "levelsof") == 0 ) {
        if ( (rc = sf_parse_info_lean  (st_info, 0)) ) return (rc);
        if ( (rc = sf_hash_byvars      (st_info))    ) return (rc);
        if ( (rc = sf_check_hash_index (st_info, 1)) ) return (rc);
        if ( (rc = sf_levelsof         (st_info))    ) return (rc);
        sf_free_lean (st_info);
        rc = 0; goto exit;
    }
    else if ( strcmp(todo, "hashsort") == 0 ) {
        if ( (rc = sf_parse_info_lean (st_info, 1)) ) return (rc);
        if ( !st_info->integers_ok ) {
            if ( (rc = sf_hash_byvars    (st_info)) ) return (rc);
            if ( (rc = sf_check_hashsort (st_info)) ) return (rc);
        }
        else {
            st_info->info  = malloc(sizeof(size_t));
            st_info->index = malloc(sizeof(size_t));
        }
        if ( (rc = sf_hashsort (st_info)) ) return (rc);
        sf_free_lean (st_info);
        rc = 0; goto exit;
    }
    else {

        /*********************************************************************
         *                          Misc operations                          *
         *********************************************************************/

        if ( strcmp(todo, "setup") == 0 ) {

            // Computes min, max, and rage for all numeric by variables
            // --------------------------------------------------------

            if ( (rc = sf_numsetup()) ) return (rc);
            rc = 0; goto exit;
        }
        else if ( strcmp(todo, "isint") == 0 ) {

            // Figure out if float|double variable is actually all integers
            // ------------------------------------------------------------

            if ( (rc = sf_isint()) ) return (rc);
            rc = 0; goto exit;
        }
        else if ( strcmp(todo, "recast") == 0 ) {

            // Recast sources to be used as targets
            // ------------------------------------

            // The program tries to use source variables as targets to save
            // memory. When the source variable cannot be used because it's
            // type would not allow it (e.g. mean for a byte variable) we
            // generate temporary variables of the correct target type and
            // fill-in the source variable values. For multiple recast
            // variables, doing it in bulk here is faster than multiple
            // replace statements in Stata.

            ST_double K_double, z ;

            if ( (rc = SF_scal_use("__gtools_k_recast", &K_double)) ) return(rc);
            size_t K = (size_t) K_double;

            for (i = SF_in1(); i <= SF_in2(); i++) {
                for (k = 1; k <= K; k++) {
                    if ( (rc = SF_vdata  (k + K, i, &z)) ) return (rc);
                    if ( (rc = SF_vstore (k,     i,  z)) ) return (rc);
                }
            }

            rc = 0; goto exit;
        }
        else if ( strcmp(todo, "bench") == 0 ) {

            // Benchmark writing and reading 1MiB to disk
            // ------------------------------------------

            if (argc < 2) {
                sf_errprintf ("benchmark requires a file.\n");
                rc = 198; goto exit;
            }
            else {
                char *fname = malloc(sizeof(char) * (strlen(argv[1]) + 1));
                memset (fname, '\0', sizeof(char) * (strlen(argv[1]) + 1));
                strcpy (fname, argv[1]);
                double rate_c = mf_benchmark(fname);
                if ( (rc = SF_scal_save ("__gtools_bench_c", rate_c)) ) return (rc);
                free (fname);
                rc = 0; goto exit;
            }
        }
        else if ( strcmp(todo, "query") == 0 ) {

            // Query the amount of free space in the path to fname
            // ---------------------------------------------------

            if (argc < 2) {
                sf_errprintf ("query requires a file.\n");
                rc = 198; goto exit;
            }
            else {
                char *fname = malloc(sizeof(char) * (strlen(argv[1]) + 1));
                memset (fname, '\0', sizeof(char) * (strlen(argv[1]) + 1));
                strcpy (fname, argv[1]);
                double mib_free = mf_query_free_space(fname);
                if ( (rc = SF_scal_save ("__gtools_free_tmp", mib_free)) ) return (rc);
                free (fname);
                rc = 0; goto exit;
            }
        }
    }

    sf_printf ("Nothing to do; pugin should be called from -gcollapse- or -gegen-\n");
    return (0);

exit:
    free (st_info);
    free (tostat);
    free (todo);
    return (rc);
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

    // Check there are observations in the subset provided
    if ( !sf_anyobs_sel() ) return (42001);

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

    // Sums are missing if all elements are missing, insteaad of 0
    int missing;
    ST_double missing_double ;
    if ( (rc = SF_scal_use("__gtools_missing", &missing_double)) ) {
        return(rc) ;
    }
    else {
        missing = (int) missing_double;
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

    // If condition
    int any_if;
    ST_double any_if_double ;
    if ( (rc = SF_scal_use("__gtools_if", &any_if_double)) ) {
        return(rc) ;
    }
    else {
        any_if = (int) any_if_double;
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
    st_info->byvars_int  = calloc(kvars_by, sizeof st_info->byvars_int);
    st_info->byvars_lens = calloc(kvars_by, sizeof st_info->byvars_lens);
    st_info->byvars_mins = calloc(kvars_by, sizeof st_info->byvars_mins);
    st_info->byvars_maxs = calloc(kvars_by, sizeof st_info->byvars_maxs);

    if ( st_info->byvars_int  == NULL ) return(sf_oom_error("sf_parse_info", "st_info->byvars_int"));
    if ( st_info->byvars_lens == NULL ) return(sf_oom_error("sf_parse_info", "st_info->byvars_lens"));
    if ( st_info->byvars_mins == NULL ) return(sf_oom_error("sf_parse_info", "st_info->byvars_mins"));
    if ( st_info->byvars_maxs == NULL ) return(sf_oom_error("sf_parse_info", "st_info->byvars_maxs"));

    double *byvars_int_double  = calloc(kvars_by, sizeof *byvars_int_double);
    double *byvars_lens_double = calloc(kvars_by, sizeof *byvars_lens_double);
    double *byvars_mins_double = calloc(kvars_by, sizeof *byvars_mins_double);
    double *byvars_maxs_double = calloc(kvars_by, sizeof *byvars_maxs_double);

    if ( byvars_int_double  == NULL ) return(sf_oom_error("sf_parse_info", "byvars_int_double"));
    if ( byvars_lens_double == NULL ) return(sf_oom_error("sf_parse_info", "byvars_lens_double"));
    if ( byvars_mins_double == NULL ) return(sf_oom_error("sf_parse_info", "byvars_mins_double"));
    if ( byvars_maxs_double == NULL ) return(sf_oom_error("sf_parse_info", "byvars_maxs_double"));

    if ( (rc = sf_get_vector("__gtools_byint", byvars_int_double))  ) return(rc);
    if ( (rc = sf_get_vector("__gtools_byk",   byvars_lens_double)) ) return(rc);
    if ( (rc = sf_get_vector("__gtools_bymin", byvars_mins_double)) ) return(rc);
    if ( (rc = sf_get_vector("__gtools_bymax", byvars_maxs_double)) ) return(rc);

    for (i = 0; i < kvars_by; i++) {
        st_info->byvars_int[i]  = (int) byvars_int_double[i];
        st_info->byvars_lens[i] = (int) byvars_lens_double[i];
        st_info->byvars_mins[i] = (int) byvars_mins_double[i];
        st_info->byvars_maxs[i] = (int) byvars_maxs_double[i];
    }

    free (byvars_int_double);
    free (byvars_lens_double);
    free (byvars_mins_double);
    free (byvars_maxs_double);

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
            // I cannot quite recall why I was only adding 1 from the
            // third variable onward, but in case you feel the urge to
            // do it again, just remember this causes a nasry crash due
            // to division by 0 when the second variable has only one value.
            // size_t range = st_info->byvars_maxs[1] - st_info->byvars_mins[1] + (1 < (kvars_by - 1));
            size_t range = st_info->byvars_maxs[1] - st_info->byvars_mins[1] + 1;
            for (k = 1; k < kvars_by; k++) {
                if ( worst > (ULONG_MAX / range)  ) {
                    if ( verbose ) sf_printf("By variables all intergers but bijection could fail! Won't risk it.\n");
                    integers_ok = 0;
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
        char *targets    = malloc(sizeof(char) * (1 + l_targets));    memset (targets,    '\0', sizeof(char) * (1 + l_targets));
        char *vars       = malloc(sizeof(char) * (1 + l_vars));       memset (vars,       '\0', sizeof(char) * (1 + l_vars));
        char *stats      = malloc(sizeof(char) * (1 + l_stats));      memset (stats,      '\0', sizeof(char) * (1 + l_stats));
        char *uniq_vars  = malloc(sizeof(char) * (1 + l_uniq_vars));  memset (uniq_vars,  '\0', sizeof(char) * (1 + l_uniq_vars));
        char *uniq_stats = malloc(sizeof(char) * (1 + l_uniq_stats)); memset (uniq_stats, '\0', sizeof(char) * (1 + l_uniq_stats));

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
        st_info->statstr = malloc (sizeof(char) * l_stats);
        memset (st_info->statstr, '\0', sizeof(char) * l_stats);
        memcpy (st_info->statstr, stats, l_stats);

        st_info->kvars_targets = kvars_targets;
        st_info->kvars_source  = kvars_source;
        st_info->sort_memory   = !(integers_ok | merge);

        free (targets);
        free (vars);
        free (stats);
        free (uniq_vars);
        free (uniq_stats);
    }
    else if ( level == 1 ) {
        ST_double __gtools_k_vars,
                  __gtools_l_stats,
                  __gtools_group_count,
                  __gtools_group_data,
                  __gtools_group_fill,
                  __gtools_group_val;

        if ( (rc = SF_scal_use ("__gtools_k_vars",      &__gtools_k_vars))      ) return(rc);
        if ( (rc = SF_scal_use ("__gtools_l_stats",     &__gtools_l_stats))     ) return(rc);
        if ( (rc = SF_scal_use ("__gtools_group_count", &__gtools_group_count)) ) return(rc);
        if ( (rc = SF_scal_use ("__gtools_group_data",  &__gtools_group_data))  ) return(rc);
        if ( (rc = SF_scal_use ("__gtools_group_fill",  &__gtools_group_fill))  ) return(rc);
        if ( (rc = SF_scal_use ("__gtools_group_val",   &__gtools_group_val))   ) return(rc);

        kvars_targets  = 1;
        kvars_source   = (size_t) __gtools_k_vars;
        size_t l_stats = (size_t) __gtools_l_stats + 1;

        st_info->group_val   = __gtools_group_val;
        st_info->group_fill  = (int) __gtools_group_fill;
        st_info->group_data  = (int) __gtools_group_data;
        st_info->group_count = (int) __gtools_group_count;

        st_info->statstr = malloc (sizeof(char) * l_stats);
        memset (st_info->statstr, '\0', sizeof(char) * l_stats);
        if ( (rc = SF_macro_use ("_gtools_stats", st_info->statstr, l_stats)) ) return(rc);

        st_info->kvars_targets = kvars_targets;
        st_info->kvars_source  = kvars_source;
        st_info->sort_memory   = 0;
    }

    st_info->read_dtax = 0;

    // Whether to invert the sort order of group variables post collapse
    st_info->invert = calloc(kvars_by, sizeof st_info->invert);
    if ( st_info->invert == NULL ) return(sf_oom_error("sf_parse_info", "st_info->invert"));

    for (k = 0; k < kvars_by; k++)
        st_info->invert[k] = 0;

    /*********************************************************************
     *           Relative position of targets and by variables           *
     *********************************************************************/

    size_t strmax = byvars_maxlen > 0? byvars_maxlen + 1: 1;
    size_t start_target_vars = start_collapse_vars + kvars_source;

    st_info->pos_targets    = calloc(kvars_targets, sizeof st_info->pos_targets);
    st_info->pos_num_byvars = calloc(kvars_by_num,  sizeof st_info->pos_num_byvars);
    st_info->pos_str_byvars = calloc(kvars_by_str,  sizeof st_info->pos_str_byvars);

    if ( st_info->pos_targets    == NULL ) return(sf_oom_error("sf_parse_info", "st_info->pos_targets"));
    if ( st_info->pos_num_byvars == NULL ) return(sf_oom_error("sf_parse_info", "st_info->pos_num_byvars"));
    if ( st_info->pos_str_byvars == NULL ) return(sf_oom_error("sf_parse_info", "st_info->pos_str_byvars"));

    double *pos_str_byvars_double = calloc(kvars_by_str, sizeof *pos_str_byvars_double);
    double *pos_num_byvars_double = calloc(kvars_by_num, sizeof *pos_num_byvars_double);

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

    free (pos_str_byvars_double);
    free (pos_num_byvars_double);

    /*********************************************************************
     *                    Save into st_info structure                    *
     *********************************************************************/

    st_info->in1                 = in1;
    st_info->in2                 = in2;
    st_info->N                   = N;
    st_info->any_if              = any_if;
    st_info->kvars_by            = kvars_by;
    st_info->kvars_by_num        = kvars_by_num;
    st_info->kvars_by_str        = kvars_by_str;
    st_info->start_collapse_vars = start_collapse_vars;
    st_info->start_target_vars   = start_target_vars;
    st_info->checkhash           = checkhash;
    st_info->missing             = missing;
    st_info->verbose             = verbose;
    st_info->benchmark           = benchmark;
    st_info->merge               = merge;
    st_info->indexed             = indexed;
    st_info->integers_ok         = integers_ok;
    st_info->byvars_minlen       = byvars_minlen;
    st_info->byvars_maxlen       = byvars_maxlen;
    st_info->strmax              = strmax;

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
    size_t J, nj_min, nj_max, N_if;

    // Hash the data
    // -------------

    // Hashing: Throughout the code we allocate to heap bc C may run out
    // of memory in the stack.
    st_info->index   = calloc(st_info->N, sizeof(st_info->index));
    size_t *index    = st_info->index;
    uint64_t *ghash1 = calloc(st_info->N, sizeof *ghash1);
    uint64_t *ghash, *ghash2;

    if ( index  == NULL ) sf_oom_error("sf_hash_byvars", "index");
    if ( ghash1 == NULL ) sf_oom_error("sf_hash_byvars", "ghash1");

    if ( st_info->indexed > 0 ) {
        if ( st_info->verbose )
            sf_printf("Using index provided by stata (data was already soretd).\n");

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

        // Adjust hash to only contain hashes that match [if] condition
        if ( st_info->any_if ) {
            N_if = 0;
            for (i = 0; i < st_info->N; i++) {
                if ( SF_ifobs(index[i] + st_info->in1) ) {
                    ghash1[N_if] = ghash1[i];
                    index[N_if]  = index[i];
                    N_if++;
                }
            }
            st_info->N = N_if;
        }

        st_info->info = mf_panelsetup (ghash1, st_info->N, &J);
        if ( st_info->info == NULL ) return(sf_oom_error("sf_hash_byvars", "st_info->info"));
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
                                                 st_info->byvars_maxs,
                                                 st_info->verbose)) ) return(rc);
        }
        else {
            if ( st_info->verbose )
                sf_printf("Using sole integer by variable as hash.\n", st_info->kvars_by);
            if ( (rc = sf_get_variable_ashash (ghash1, 1,
                                               st_info->in1,
                                               st_info->in2,
                                               st_info->byvars_mins[0],
                                               st_info->byvars_maxs[0],
                                               st_info->verbose)) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        // Index the hash using a radix sort
        // ---------------------------------

        // index[i] gives the position in Stata of the ith entry
        rc = mf_radix_sort_index (ghash1, index, st_info->N, RADIX_SHIFT, 0, st_info->verbose);
        if ( rc ) return(rc);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Sorted on integer-only hash index");

        // Adjust hash to only contain hashes that match [if] condition
        if ( st_info->any_if ) {
            N_if = 0;
            for (i = 0; i < st_info->N; i++) {
                if ( SF_ifobs(index[i] + st_info->in1) ) {
                    ghash1[N_if] = ghash1[i];
                    index[N_if]  = index[i];
                    N_if++;
                }
            }
            st_info->N = N_if;
            if ( st_info->benchmark ) sf_running_timer (&timer, "\t\tPlugin step 3.1: Adjusted index based on if condition");
        }

        // info[j], info[j + 1] give the starting and ending position of the
        // jth group in index. So the jth group can be called by looping
        // through index[i] for i = info[j] to i < info[j + 1]
        st_info->info = mf_panelsetup (ghash1, st_info->N, &J);

        if ( st_info->info == NULL ) return(sf_oom_error("sf_hash_byvars", "st_info->info"));
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
        if ( ghash2  == NULL ) sf_oom_error("sf_hash_byvars", "ghash2");
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
                    sf_printf("Using 128-bit hash to index %d numeric-only by variables\n", st_info->kvars_by);
                }
            }
            if ( (rc = sf_get_varlist_hash (ghash1, ghash2, 1,
                                            st_info->kvars_by,
                                            st_info->in1,
                                            st_info->in2,
                                            st_info->byvars_lens,
                                            st_info->verbose)) ) return(rc);
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
                                             st_info->byvars_lens[0],
                                             st_info->verbose)) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        // Index the hash using a radix sort
        // ---------------------------------

        // index[i] gives the position in Stata of the ith entry
        rc = mf_radix_sort_index (ghash1, index, st_info->N, RADIX_SHIFT, 0, st_info->verbose);
        if ( rc ) return(rc);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Sorted on integer-only hash index");

        // Copy ghash2 in case you will need it
        ghash = calloc(st_info->N, sizeof *ghash);
        if ( ghash  == NULL ) sf_oom_error("sf_hash_byvars", "ghash");
        for (i = 0; i < st_info->N; i++) {
            ghash[i] = ghash2[index[i]];
        }
        free (ghash2);

        // Adjust hash to only contain hashes that match [if] condition
        if ( st_info->any_if ) {
            N_if = 0;
            for (i = 0; i < st_info->N; i++) {
                if ( SF_ifobs(index[i] + st_info->in1) ) {
                    ghash1[N_if] = ghash1[i];
                    ghash[N_if]  = ghash[i];
                    index[N_if]  = index[i];
                    N_if++;
                }
            }
            st_info->N = N_if;
            if ( st_info->benchmark ) sf_running_timer (&timer, "\t\tPlugin step 3.1: Adjusted index based on if condition");
        }

        // info[j], info[j + 1] give the starting and ending position of the
        // jth group in index. So the jth group can be called by looping
        // through index[i] for i = info[j] to i < info[j + 1]
        st_info->info = mf_panelsetup128 (ghash1, ghash, index, st_info->N, &J, st_info->verbose);
        if ( st_info->info == NULL ) return(sf_oom_error("sf_hash_byvars", "st_info->info"));
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Set up variables for main group loop");
        free (ghash);
    }
    free (ghash1);

    // Group size info
    // ---------------

    size_t *info = st_info->info;
    nj_min = info[1] - info[0];
    nj_max = info[1] - info[0];
    for (j = 1; j < J; j++) {
        if (nj_min > (info[j + 1] - info[j])) nj_min = (info[j + 1] - info[j]);
        if (nj_max < (info[j + 1] - info[j])) nj_max = (info[j + 1] - info[j]);
    }

    if ( st_info->verbose ) {
        if ( nj_min == nj_max )
            sf_printf ("N = "FMT"; "FMT" balanced groups of size "FMT"\n", st_info->N, J, nj_min);
        else
            sf_printf ("N = "FMT"; "FMT" unbalanced groups of sizes "FMT" to "FMT"\n", st_info->N, J, nj_min, nj_max);
    }

    st_info->J      = J;
    st_info->nj_min = nj_min;
    st_info->nj_max = nj_max;

    char *results = malloc(24 * sizeof(char));

    memset(results, '\0', 24 * sizeof(char)); sprintf(results, "%.15g", (double) st_info->N);
    if ( (rc = SF_macro_save("_r_N",    results)) ) return (rc);

    memset(results, '\0', 24 * sizeof(char)); sprintf(results, "%.15g", (double) st_info->J);
    if ( (rc = SF_macro_save("_r_J",    results)) ) return (rc);

    memset(results, '\0', 24 * sizeof(char)); sprintf(results, "%.15g", (double) st_info->nj_min);
    if ( (rc = SF_macro_save("_r_minJ", results)) ) return (rc);

    memset(results, '\0', 24 * sizeof(char)); sprintf(results, "%.15g", (double) st_info->nj_max);
    if ( (rc = SF_macro_save("_r_maxJ", results)) ) return (rc);

    free(results);

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
    free (st_info->statstr);
    free (st_info->info);
    free (st_info->index);
    free (st_info->invert);
    free (st_info->byvars_lens);
    free (st_info->byvars_mins);
    free (st_info->byvars_maxs);
    free (st_info->pos_targets);
    free (st_info->pos_num_byvars);
    free (st_info->pos_str_byvars);
}
