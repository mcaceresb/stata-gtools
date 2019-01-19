/*********************************************************************
 * Program: gtools.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Sat Jan 19 17:17:18 EST 2019
 * Purpose: Stata plugin for faster group operations
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 1.2.5
 *********************************************************************/

/**
 * @file gtools.c
 * @author Mauricio Caceres Bravo
 * @date 19 Jan 2019
 * @brief Stata plugin
 *
 * This file should only ever be called from gtools.ado
 *
 * @see help gtools
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include "gtools.h"
#include "spookyhash/src/spookyhash_api.h"

#include "common/sf_wrappers.c"
#include "common/fixes.c"
#include "common/quicksortMultiLevel.c"
#include "common/readWrite.c"

#if GMULTI
#    define GTOOLS_THREADS 4
#    include <pthread.h>
#    include <assert.h>
#    include "parallel/hash/gtools_hash.c"
#else
#    include "hash/gtools_hash.c"
#endif

#include "common/encode.c"

#include "collapse/gtools_math.c"
#include "collapse/gtools_math_w.c"
#include "collapse/gtools_math_unw.c"

#include "collapse/gtools_nunique.c"
#include "collapse/gtools_utils.c"
#include "collapse/gegen_w.c"
#include "collapse/gegen.c"

#include "extra/gisid.c"
#include "extra/glevelsof.c"
#include "extra/hashsort.c"
#include "extra/gcontract.c"
#include "extra/gtop.c"
#include "stats/gstats.c"

#include "quantiles/gquantiles_math.c"
#include "quantiles/gquantiles_math_w.c"
#include "quantiles/gquantiles_utils.c"
#include "quantiles/gquantiles.c"

int main()
{
    return(0);
}

int WinMain()
{
    return(0);
}

STDLL stata_call(int argc, char *argv[])
{
    if (argc < 1) {
        sf_errprintf ("Nothing to do.\n");
        return (198);
    }

    ST_retcode rc = 0;
    setlocale(LC_ALL, "");

    GTOOLS_CHAR(tostat, 16);
    GTOOLS_CHAR(todo,   16);
    strcpy (todo, argv[0]);

    int free_level = 0;
    struct StataInfo *st_info = malloc(sizeof(*st_info));
    st_info->free = 0;
    GTOOLS_GC_INIT

    /**************************************************************************
     * This is the main wrapper. We apply one of:                             *
     *                                                                        *
     *     - check:     Exit with 0 status. This just tests the plugin can be *
     *                  called from Stata without crashing.                   *
     *     - sumcheck:  Sum if integer check will overflow                    *
     *     - checkstrL: Check if strL variables have binary data              *
     *     - recast:    Bulk copy sources into targets.                       *
     *     - hash:      Generic (read, hash, sort, generate, summary stats).  *
     *     - isid:      Do by vars uniquely identify obs?                     *
     *     - levelsof:  Levels of by variables.                               *
     *     - top:       Top levels by frequency.                              *
     *     - contract:  Frequency counts of levels.                           *
     *     - hashsort:  Sort data by variables.                               *
     *     - quantiles: Percentiles, xtile, bin counts, and more.             *
     *     - collapse:  Summary stat by group.                                *
     *     - stats:     Several stat functions and transforms.                *
     *                                                                        *
     **************************************************************************/

    if ( strcmp(todo, "check") == 0 ) {
        goto exit;
    }
    if ( strcmp(todo, "sumcheck") == 0 ) {
        ST_double z, w, v, *sum, *sumptr;
        GT_size sum_k, sum_w, i, k;

        if ( (rc = sf_scalar_size("__gtools_sum_w", &sum_w) )) goto exit;
        if ( (rc = sf_scalar_size("__gtools_sum_k", &sum_k) )) goto exit;
        sum = calloc(sum_k, sizeof sum);

        for (k = 0; k < sum_k; k++)
            sum[k] = 1;

        // This assumes that the weights are either 1 or frequency
        // weights. Missing values are ignored because they are ignored
        // in sums.

        if ( sum_w ) {
            for (i = SF_in1(); i <= SF_in2(); i++) {
                sumptr = sum;
                if ( (rc = SF_vdata(sum_k + 1, i, &w)) ) goto exit;
                for (k = 1; k <= sum_k; k++, sumptr++) {
                    if ( *sumptr > 0 ) {
                        if ( (rc = SF_vdata(k, i, &z)) ) goto exit;
                        v = fabs(z * w);
                        if ( v < SV_missval ) {
                            *sumptr += v;
                        }
                        else if ( !SF_is_missing(z) && !SF_is_missing(w) ) {
                            *sumptr = -1;
                        }
                    }
                }
            }
        }
        else {
            for (i = SF_in1(); i <= SF_in2(); i++) {
                sumptr = sum;
                for (k = 1; k <= sum_k; k++, sumptr++) {
                    if ( *sumptr > 0 ) {
                        if ( (rc = SF_vdata(k, i, &z)) ) goto exit;
                        v = fabs(z);
                        if ( v < SV_missval ) {
                            *sumptr += v;
                        }
                        else if ( !SF_is_missing(z) ) {
                            *sumptr = -1;
                        }
                    }
                }
            }
        }

        for (k = 0; k < sum_k; k++) {
            if ( sum[k] < 0 ) {
                sum[k] = SV_missval;
            }
            else {
                sum[k] -= 1;
            }
            if ( (rc = SF_mat_store("__gtools_sumcheck", 1, k + 1, sum[k]) )) goto exit;
        }

        goto exit;
    }
    else if ( strcmp(todo, "recast") == 0 ) {
        ST_double z ;
        GT_size kvars_recast, i, k;

        if ( (rc = sf_scalar_size("__gtools_k_recast", &kvars_recast) )) goto exit;
        for (i = SF_in1(); i <= SF_in2(); i++) {
            for (k = 1; k <= kvars_recast; k++) {
                if ( (rc = SF_vdata  (k + kvars_recast, i, &z)) ) goto exit;
                if ( (rc = SF_vstore (k, i, z)) ) goto exit;
            }
        }

        goto exit;
    }
    if ( strcmp(todo, "checkstrL") == 0 ) {
        GT_size kvars_strL, i, k;
        if ( (rc = sf_scalar_size("__gtools_k_strL", &kvars_strL) )) goto exit;
        for (i = SF_in1(); i <= SF_in2(); i++) {
            for (k = 1; k <= kvars_strL; k++) {
                if ( SF_var_is_binary(k, i) ) {
                    rc = 17005;
                    goto exit;
                }
            }
        }
    }
    else if ( strcmp(todo, "collapse") == 0 ) { // (Note: keeps by copy; always)

        /***********************************************************************
         * collapse dispatcher                                                 *
         *                                                                     *
         *     - memory:   Targets in memory                                   *
         *     - switch:   Hash only. May generate targets; may write to disk. *
         *     - forceio:  Write to disk.                                      *
         *     - ixfinish: Targets and group info in memory.                   *
         *     - read:     Read targets from disk.                             *
         *                                                                     *
         ***********************************************************************/

        if ( argc < 2 ) {
            sf_errprintf ("collapse requires a subcommand\n");
            rc = 198; goto exit;
        }
        strcpy (tostat, argv[1]);

        if ( argc < 3 ) {
            sf_errprintf ("collapse sub-commands must also specify a file.\n");
            rc = 198; goto exit;
        }
        size_t flength = strlen(argv[2]) + 1;
        GTOOLS_CHAR (fname, flength);
        strcpy (fname, argv[2]);

        if ( (rc = sf_parse_info (st_info, 0)) ) goto exit;

        if ( (strcmp(tostat, "memory") == 0) || (strcmp(tostat, "forceio") == 0) ) {
            if ( (rc = sf_hash_byvars (st_info, 0)) ) goto exit;
            if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit;
            if ( (rc = sf_egen_bulk   (st_info, 0)) ) goto exit;

            if ( strcmp(tostat, "memory") == 0 ) {
                if ( st_info->group_data ) {
                    if ( (rc = sf_write_collapsed (st_info, 0, st_info->kvars_targets, "")) ) goto exit;
                }
                else {
                    if ( (rc = sf_write_output (st_info, 0, st_info->kvars_targets, "")) ) goto exit;
                }
                if ( (rc = SF_scal_save ("__gtools_used_io", (ST_double) 0.0)) ) goto exit;
                // goto exit;
            }
            else if ( strcmp(tostat, "forceio") == 0 ) {
                if ( (rc = sf_write_collapsed (st_info, 2, st_info->kvars_sources, fname)) ) goto exit;
                if ( (rc = SF_scal_save ("__gtools_used_io", (ST_double) 1.0)) ) goto exit;
                // goto read;
            }
        }
        else if ( strcmp(tostat, "switch") == 0 ) {
            if ( (rc = sf_hash_byvars (st_info, 0)) ) goto exit;
            if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit;
            if ( (rc = sf_switch_io   (st_info, 0, fname)) ) goto exit;

            if ( st_info->used_io ) {
                if ( (rc = sf_egen_bulk (st_info, 0)) ) goto exit;
                if ( (rc = sf_write_collapsed (st_info, 2, st_info->kvars_sources, fname)) ) goto exit;
                if ( (rc = SF_scal_save ("__gtools_used_io", (ST_double) 1.0)) ) goto exit;
                // goto read;
            }
            else {
                if ( (rc = sf_write_byvars (st_info, 0)) ) goto exit;
                if ( (rc = SF_scal_save ("__gtools_used_io",  (ST_double) 0.0)) ) goto exit;
                if ( (rc = SF_scal_save ("__gtools_ixfinish", (ST_double) 1.0)) ) goto exit;
                // goto ixfinish;
            }
        }
        else if ( strcmp(tostat, "ixfinish") == 0 ) {
            if ( (rc = sf_scalar_size ("__gtools_J", &(st_info->J))) ) goto exit;
            if ( (rc = sf_switch_mem (st_info, 0)) ) goto exit;
            if ( (rc = sf_egen_bulk  (st_info, 0)) ) goto exit;
            if ( (rc = sf_write_collapsed (st_info, 11, st_info->kvars_targets, "")) ) goto exit;

            if ( (rc = SF_scal_save ("__gtools_used_io",  (ST_double) 0.0)) ) goto exit;
            if ( (rc = SF_scal_save ("__gtools_ixfinish", (ST_double) 0.0)) ) goto exit;

            free_level = 11;
            // goto exit;
        }
        else if ( strcmp(tostat, "read") == 0 ) {
            if ( (rc = sf_scalar_size ("__gtools_J", &(st_info->J))) ) goto exit;
            if ( (rc = sf_read_collapsed (st_info->J, st_info->kvars_extra, fname)) ) goto exit;

            if ( (rc = SF_scal_save ("__gtools_used_io",  (ST_double) 0.0)) ) goto exit;
            if ( (rc = SF_scal_save ("__gtools_ixfinish", (ST_double) 0.0)) ) goto exit;
            // goto exit;
        }
        else {
            sf_errprintf ("Invalid -collapse- sub-command '%s'.", tostat);
            rc = 198; goto exit;
        }
    }
    else if ( strcmp(todo, "hash") == 0 ) {
        if ( (rc = sf_parse_info   (st_info, 0))  ) goto exit;
        if ( (rc = sf_hash_byvars  (st_info, 0))  ) goto exit;
        if ( (rc = sf_check_hash   (st_info, 22)) ) goto exit; // (Note: discards by copy)
        if ( (rc = sf_encode       (st_info, 0))  ) goto exit;
        if ( (rc = sf_egen_bulk    (st_info, 0))  ) goto exit;
        if ( (rc = sf_write_output (st_info, 0, st_info->kvars_targets, "")) ) goto exit;
    }
    else if ( strcmp(todo, "isid") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 2)) ) goto exit;
    }
    else if ( strcmp(todo, "levelsof") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 0)) ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit; // (Note: keeps by copy)
        if ( (rc = sf_levelsof    (st_info, 0)) ) goto exit;
        if ( (rc = sf_encode      (st_info, 0)) ) goto exit;
    }
    else if ( strcmp(todo, "top") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 0)) ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit; // (Note: keeps by copy)
        if ( (rc = sf_encode      (st_info, 0)) ) goto exit;
        if ( (rc = sf_top         (st_info, 0)) ) goto exit;
    }
    else if ( strcmp(todo, "contract") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 0)) ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit; // (Note: keeps by copy)
        if ( (rc = sf_contract    (st_info, 0)) ) goto exit;
        if ( (rc = sf_write_collapsed (st_info, 8, st_info->contract_vars, "")) ) goto exit;
    }
    else if ( strcmp(todo, "hashsort") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0))  ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 3))  ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 22)) ) goto exit; // (Note: discards by copy)
        if ( (rc = sf_encode      (st_info, 0))  ) goto exit;
        if ( (rc = sf_hashsort    (st_info, 0))  ) goto exit;
    }
    else if ( strcmp(todo, "quantiles") == 0 ) {
        if ( (rc = sf_parse_info (st_info, 0)) ) goto exit;
        if ( st_info->kvars_by == 0 ) {
            if ( (rc = sf_xtile  (st_info, 0)) ) goto exit;
        }
        else {
            if ( (rc = sf_hash_byvars (st_info, 0))  ) goto exit;
            if ( (rc = sf_check_hash  (st_info, 22)) ) goto exit; // (Note: discards by copy)
            if ( (rc = sf_encode      (st_info, 0))  ) goto exit;
            if ( (rc = sf_xtile_by    (st_info, 0))  ) goto exit;
        }
    }
    else if ( strcmp(todo, "stats") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0))  ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 0))  ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 22)) ) goto exit; // (Note: discards by copy)
        if ( (rc = sf_stats       (st_info, 0))  ) goto exit;
    }
    else {
        sf_printf ("Nothing to do\n");
        rc = 198; goto exit;
    }

exit:
    if ( rc == 17013 ) rc = 0;

    sf_free (st_info, free_level);
    GTOOLS_GC_END(0)

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
ST_retcode sf_parse_info (struct StataInfo *st_info, int level)
{
    ST_retcode rc = 0;
    GT_size i, start, in1, in2, N;
    GT_size debug,
            verbose,
            benchmark,
            countonly,
            seecount,
            keepmiss,
            missing,
            nomiss,
            unsorted,
            encode,
            cleanstr,
            numfmt_max,
            numfmt_len,
            colsep_len,
            sep_len,
            init_targ,
            invertix,
            skipcheck,
            mlast,
            subtract,
            ctolerance,
            top_miss,
            top_groupmiss,
            top_other,
            top_lmiss,
            top_lother,
            levels_return,
            levels_gen,
            levels_replace,
            xtile_xvars,
            xtile_nq,
            xtile_nq2,
            xtile_cutvars,
            xtile_ncuts,
            xtile_qvars,
            xtile_gen,
            xtile_pctile,
            xtile_genpct,
            xtile_pctpct,
            xtile_altdef,
            xtile_missing,
            xtile_strict,
            xtile_minmax,
            xtile_method,
            xtile_bincount,
            xtile__pctile,
            xtile_dedup,
            xtile_cutifin,
            xtile_cutby,
            gstats_code,
            winsor_trim,
            winsor_cutl,
            winsor_cuth,
            winsor_kvars,
            hash_method,
            wcode,
            wpos,
            wselective,
            nunique,
            any_if,
            countmiss,
            replace,
            group_data,
            group_fill,
            kvars_stats,
            kvars_targets,
            kvars_sources,
            kvars_group,
            kvars_by,
            kvars_by_int,
            kvars_by_num,
            kvars_by_str,
            kvars_by_strL;

    /*********************************************************************
     *       Fallback whenever this is not parsed (set to missing)       *
     *********************************************************************/

    if ( (rc = SF_macro_save("_r_N",    ".")) ) goto exit;
    if ( (rc = SF_macro_save("_r_J",    ".")) ) goto exit;
    if ( (rc = SF_macro_save("_r_minJ", ".")) ) goto exit;
    if ( (rc = SF_macro_save("_r_maxJ", ".")) ) goto exit;

    /*********************************************************************
     *                       Parse missing values                        *
     *********************************************************************/

    st_info->missval = calloc(27, sizeof st_info->missval);
    if ( st_info->missval == NULL ) return (sf_oom_error("sf_parse_info", "st_info->missval"));
    GTOOLS_GC_ALLOCATED("st_info->missval")

    st_info->missval[0]  = SV_missval;
    st_info->missval[1]  = 8.990660123939097e+307;
    st_info->missval[2]  = 8.992854573566614e+307;
    st_info->missval[3]  = 8.995049023194132e+307;
    st_info->missval[4]  = 8.997243472821649e+307;
    st_info->missval[5]  = 8.999437922449167e+307;
    st_info->missval[6]  = 9.001632372076684e+307;
    st_info->missval[7]  = 9.003826821704202e+307;
    st_info->missval[8]  = 9.006021271331719e+307;
    st_info->missval[9]  = 9.008215720959237e+307;
    st_info->missval[10] = 9.010410170586754e+307;
    st_info->missval[11] = 9.012604620214272e+307;
    st_info->missval[12] = 9.014799069841789e+307;
    st_info->missval[13] = 9.016993519469307e+307;
    st_info->missval[14] = 9.019187969096824e+307;
    st_info->missval[15] = 9.021382418724342e+307;
    st_info->missval[16] = 9.023576868351859e+307;
    st_info->missval[17] = 9.025771317979377e+307;
    st_info->missval[18] = 9.027965767606894e+307;
    st_info->missval[19] = 9.030160217234412e+307;
    st_info->missval[20] = 9.032354666861929e+307;
    st_info->missval[21] = 9.034549116489447e+307;
    st_info->missval[22] = 9.036743566116964e+307;
    st_info->missval[23] = 9.038938015744481e+307;
    st_info->missval[24] = 9.041132465371999e+307;
    st_info->missval[25] = 9.043326914999516e+307;
    st_info->missval[26] = 9.045521364627034e+307;

    /*********************************************************************
     *                        Parse Stata options                        *
     *********************************************************************/

    // Check there are observations in the subset provided
    if ( (start = sf_anyobs_sel()) == 0 ) return (17001);

    // Get start and end position; number of variables
    in1 = SF_in1();
    in2 = SF_in2();
    N   = in2 - in1 + 1;
    if ( N < 1 ) return (17001);

    // Parse switches
    if ( (rc = sf_scalar_size("__gtools_debug",          &debug)          )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_verbose",        &verbose)        )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_benchmark",      &benchmark)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_any_if",         &any_if)         )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_init_targ",      &init_targ)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_invertix",       &invertix)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_skipcheck",      &skipcheck)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_mlast",          &mlast)          )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_subtract",       &subtract)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_ctolerance",     &ctolerance)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_hash_method",    &hash_method)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_weight_code",    &wcode)          )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_weight_pos",     &wpos)           )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_weight_sel",     &wselective)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_nunique",        &nunique)        )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_seecount",       &seecount)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_countonly",      &countonly)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_unsorted",       &unsorted)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_keepmiss",       &keepmiss)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_missing",        &missing)        )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_nomiss",         &nomiss)         )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_replace",        &replace)        )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_countmiss",      &countmiss)      )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_numfmt_max",     &numfmt_max)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_numfmt_len",     &numfmt_len)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_cleanstr",       &cleanstr)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_colsep_len",     &colsep_len)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_sep_len",        &sep_len)        )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_top_groupmiss",  &top_groupmiss)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_top_miss",       &top_miss)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_top_other",      &top_other)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_top_lmiss",      &top_lmiss)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_top_lother",     &top_lother)     )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_levels_return",  &levels_return)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_levels_gen",     &levels_gen)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_levels_replace", &levels_replace) )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_xtile_xvars",    &xtile_xvars)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_nq",       &xtile_nq)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_nq2",      &xtile_nq2)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_cutvars",  &xtile_cutvars)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_ncuts",    &xtile_ncuts)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_qvars",    &xtile_qvars)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_gen",      &xtile_gen)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_pctile",   &xtile_pctile)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_genpct",   &xtile_genpct)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_pctpct",   &xtile_pctpct)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_altdef",   &xtile_altdef)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_missing",  &xtile_missing)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_strict",   &xtile_strict)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_min",      &xtile_minmax)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_method",   &xtile_method)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_bincount", &xtile_bincount) )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile__pctile",  &xtile__pctile)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_dedup",    &xtile_dedup)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_cutifin",  &xtile_cutifin)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_xtile_cutby",    &xtile_cutby)    )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_gstats_code",    &gstats_code)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_winsor_trim",    &winsor_trim)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_winsor_cutl",    &winsor_cutl)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_winsor_cuth",    &winsor_cuth)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_winsor_kvars",   &winsor_kvars)   )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_encode",         &encode)         )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_group_data",     &group_data)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_group_fill",     &group_fill)     )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_k_stats",        &kvars_stats)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_k_vars",         &kvars_sources)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_k_targets",      &kvars_targets)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_k_group",        &kvars_group)    )) goto exit;

    if ( debug ) {
        printf("debug 1: Read all integer scalars\n");
    }

    // Value fill for group
    if ( (rc = SF_scal_use("__gtools_group_val", &(st_info->group_val) )) ) return (rc);

    // Vars for top
    if ( (rc = SF_scal_use("__gtools_top_freq",  &(st_info->top_freq)  )) ) return (rc);
    if ( (rc = SF_scal_use("__gtools_top_ntop",  &(st_info->top_ntop)  )) ) return (rc);
    if ( (rc = SF_scal_use("__gtools_top_pct",   &(st_info->top_pct)   )) ) return (rc);

    // Parse number of variables
    if ( (rc = sf_scalar_size("__gtools_kvars",      &kvars_by)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_int",  &kvars_by_int)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_num",  &kvars_by_num)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_str",  &kvars_by_str)  )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_strL", &kvars_by_strL) )) goto exit;

    if ( debug ) {
        printf("debug 2: Read all double scalars\n");
    }

    // Parse variable lengths, positions, and sort order
    st_info->byvars_strL     = calloc(kvars_by,     sizeof st_info->byvars_strL);
    st_info->byvars_lens     = calloc(kvars_by,     sizeof st_info->byvars_lens);
    st_info->invert          = calloc(kvars_by,     sizeof st_info->invert);
    st_info->pos_num_byvars  = calloc(kvars_by_num, sizeof st_info->pos_num_byvars);
    st_info->pos_str_byvars  = calloc(kvars_by_str, sizeof st_info->pos_str_byvars);
    st_info->group_targets   = calloc(3,            sizeof st_info->group_targets);
    st_info->group_init      = calloc(3,            sizeof st_info->group_init);

    st_info->wselmat         = calloc((wselective    > 0)? kvars_targets   : 1, sizeof st_info->wselmat);
    st_info->pos_targets     = calloc((kvars_targets > 1)? kvars_targets   : 1, sizeof st_info->pos_targets);
    st_info->statcode        = calloc((kvars_stats   > 1)? kvars_stats     : 1, sizeof st_info->statcode);
    st_info->xtile_quantiles = calloc((xtile_nq2     > 0)? xtile_nq2       : 1, sizeof st_info->xtile_quantiles);
    st_info->xtile_cutoffs   = calloc((xtile_ncuts   > 0)? xtile_ncuts + 1 : 1, sizeof st_info->xtile_cutoffs);
    st_info->contract_which  = calloc(4, sizeof st_info->contract_which);

    if ( st_info->byvars_strL     == NULL ) return (sf_oom_error("sf_parse_info", "st_info->byvars_strL"));
    if ( st_info->byvars_lens     == NULL ) return (sf_oom_error("sf_parse_info", "st_info->byvars_lens"));
    if ( st_info->invert          == NULL ) return (sf_oom_error("sf_parse_info", "st_info->invert"));
    if ( st_info->wselmat         == NULL ) return (sf_oom_error("sf_parse_info", "st_info->wselmat"));
    if ( st_info->pos_num_byvars  == NULL ) return (sf_oom_error("sf_parse_info", "st_info->pos_num_byvars"));
    if ( st_info->pos_str_byvars  == NULL ) return (sf_oom_error("sf_parse_info", "st_info->pos_str_byvars"));
    if ( st_info->group_targets   == NULL ) return (sf_oom_error("sf_parse_info", "st_info->group_targets"));
    if ( st_info->group_init      == NULL ) return (sf_oom_error("sf_parse_info", "st_info->group_init"));

    if ( st_info->pos_targets     == NULL ) return (sf_oom_error("sf_parse_info", "st_info->pos_targets"));
    if ( st_info->statcode        == NULL ) return (sf_oom_error("sf_parse_info", "st_info->statcode"));
    if ( st_info->contract_which  == NULL ) return (sf_oom_error("sf_parse_info", "st_info->contract_which"));
    if ( st_info->xtile_quantiles == NULL ) return (sf_oom_error("sf_parse_info", "st_info->xtile_quantiles"));
    if ( st_info->xtile_cutoffs   == NULL ) return (sf_oom_error("sf_parse_info", "st_info->xtile_cutoffs"));

    GTOOLS_GC_ALLOCATED("st_info->byvars_strL")
    GTOOLS_GC_ALLOCATED("st_info->byvars_lens")
    GTOOLS_GC_ALLOCATED("st_info->invert")
    GTOOLS_GC_ALLOCATED("st_info->wselmat")
    GTOOLS_GC_ALLOCATED("st_info->pos_num_byvars")
    GTOOLS_GC_ALLOCATED("st_info->pos_str_byvars")
    GTOOLS_GC_ALLOCATED("st_info->group_targets")
    GTOOLS_GC_ALLOCATED("st_info->group_init")
    GTOOLS_GC_ALLOCATED("st_info->pos_targets")
    GTOOLS_GC_ALLOCATED("st_info->statcode")
    GTOOLS_GC_ALLOCATED("st_info->contract_which")
    GTOOLS_GC_ALLOCATED("st_info->xtile_quantiles")
    GTOOLS_GC_ALLOCATED("st_info->xtile_cutoffs")

    if ( debug ) {
        printf("debug 3: Allocated all matrices\n");
    }

    if ( (rc = sf_get_vector_bool ("__gtools_strL",        st_info->byvars_strL) )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_bylens",      st_info->byvars_lens) )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_invert",      st_info->invert)      )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_weight_smat", st_info->wselmat)     )) goto exit;

    if ( (rc = sf_get_vector      ("__gtools_stats",           st_info->statcode)        )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_pos_targets",     st_info->pos_targets)     )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_contract_which",  st_info->contract_which)  )) goto exit;
    if ( xtile_nq2 > 0 ) {
        if ( (rc = sf_get_vector  ("__gtools_xtile_quantiles", st_info->xtile_quantiles) )) goto exit;
    }
    if ( (rc = sf_get_vector      ("__gtools_xtile_cutoffs",   st_info->xtile_cutoffs)   )) goto exit;

    if ( kvars_by_num > 0 ) {
        if ( (rc = sf_get_vector_size ("__gtools_numpos", st_info->pos_num_byvars)) ) goto exit;
    }

    if ( kvars_by_str > 0 ) {
        if ( (rc = sf_get_vector_size ("__gtools_strpos", st_info->pos_str_byvars)) ) goto exit;
    }

    if ( (rc = sf_get_vector_size ("__gtools_group_targets", st_info->group_targets)) ) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_group_init",    st_info->group_init))    ) goto exit;

    if ( debug ) {
        printf("debug 4: Read matrices into arrays\n");
    }

    /*********************************************************************
     *                    Save into st_info structure                    *
     *********************************************************************/

    GTOOLS_MIN (st_info->byvars_lens, kvars_by, strmax, i)
    st_info->contract_vars = 0;
    for (i = 0; i < 4; i++) {
        st_info->contract_vars += st_info->contract_which[i];
    }

    st_info->in1            = in1;
    st_info->in2            = in2;
    st_info->N              = N;
    st_info->Nread          = N;

    st_info->debug          = debug;
    st_info->verbose        = verbose;
    st_info->benchmark      = benchmark;
    st_info->any_if         = any_if;
    st_info->init_targ      = init_targ;
    st_info->strmax         = strmax;
    st_info->invertix       = invertix;
    st_info->skipcheck      = skipcheck;
    st_info->mlast          = mlast;
    st_info->subtract       = subtract;
    st_info->ctolerance     = ctolerance;
    st_info->hash_method    = hash_method;
    st_info->wcode          = wcode;
    st_info->wpos           = wpos;
    st_info->wselective     = wselective;
    st_info->nunique        = nunique;

    st_info->unsorted       = unsorted;
    st_info->countonly      = countonly;
    st_info->seecount       = seecount;
    st_info->keepmiss       = keepmiss;
    st_info->missing        = missing;
    st_info->nomiss         = nomiss;
    st_info->replace        = replace;
    st_info->countmiss      = countmiss;

    st_info->numfmt_max     = numfmt_max;
    st_info->numfmt_len     = numfmt_len;
    st_info->cleanstr       = cleanstr;
    st_info->colsep_len     = colsep_len;
    st_info->sep_len        = sep_len;

    st_info->top_groupmiss  = top_groupmiss;
    st_info->top_miss       = top_miss;
    st_info->top_other      = top_other;
    st_info->top_lmiss      = top_lmiss;
    st_info->top_lother     = top_lother;

    st_info->levels_return  = levels_return;
    st_info->levels_gen     = levels_gen;
    st_info->levels_replace = levels_replace;

    st_info->xtile_xvars    = xtile_xvars;
    st_info->xtile_nq       = xtile_nq;
    st_info->xtile_nq2      = xtile_nq2;
    st_info->xtile_cutvars  = xtile_cutvars;
    st_info->xtile_ncuts    = xtile_ncuts;
    st_info->xtile_qvars    = xtile_qvars;
    st_info->xtile_gen      = xtile_gen;
    st_info->xtile_pctile   = xtile_pctile;
    st_info->xtile_genpct   = xtile_genpct;
    st_info->xtile_pctpct   = xtile_pctpct;
    st_info->xtile_altdef   = xtile_altdef;
    st_info->xtile_missing  = xtile_missing;
    st_info->xtile_strict   = xtile_strict;
    st_info->xtile_minmax   = xtile_minmax;
    st_info->xtile_method   = xtile_method;
    st_info->xtile_bincount = xtile_bincount;
    st_info->xtile__pctile  = xtile__pctile;
    st_info->xtile_dedup    = xtile_dedup;
    st_info->xtile_cutifin  = xtile_cutifin;
    st_info->xtile_cutby    = xtile_cutby;

    st_info->gstats_code    = gstats_code;
    st_info->winsor_trim    = winsor_trim;
    st_info->winsor_cutl    = winsor_cutl;
    st_info->winsor_cuth    = winsor_cuth;
    st_info->winsor_kvars   = winsor_kvars;

    st_info->encode         = encode;
    st_info->group_data     = group_data;
    st_info->group_fill     = group_fill;

    st_info->kvars_by       = kvars_by;
    st_info->kvars_by_int   = kvars_by_int;
    st_info->kvars_by_num   = kvars_by_num;
    st_info->kvars_by_str   = kvars_by_str;
    st_info->kvars_by_strL  = kvars_by_strL;

    st_info->kvars_group    = kvars_group;
    st_info->kvars_sources  = kvars_sources;
    st_info->kvars_targets  = kvars_targets;
    st_info->kvars_extra    = kvars_targets - kvars_sources;
    st_info->kvars_stats    = kvars_stats;

    /*********************************************************************
     *                              Cleanup                              *
     *********************************************************************/

    if ( debug ) {
        printf("debug 5: Stored all internal variables in st_info\n");
        sf_printf_debug("\tin1:            "GT_size_cfmt"\n",  in1           );
        sf_printf_debug("\tin2:            "GT_size_cfmt"\n",  in2           );
        sf_printf_debug("\tN:              "GT_size_cfmt"\n",  N             );
        sf_printf_debug("\n");                                                
        sf_printf_debug("\tdebug:          "GT_size_cfmt"\n",  debug         );
        sf_printf_debug("\tverbose:        "GT_size_cfmt"\n",  verbose       );
        sf_printf_debug("\tbenchmark:      "GT_size_cfmt"\n",  benchmark     );
        sf_printf_debug("\tcountonly:      "GT_size_cfmt"\n",  countonly     );
        sf_printf_debug("\tseecount:       "GT_size_cfmt"\n",  seecount      );
        sf_printf_debug("\tkeepmiss:       "GT_size_cfmt"\n",  keepmiss      );
        sf_printf_debug("\tmissing:        "GT_size_cfmt"\n",  missing       );
        sf_printf_debug("\tnomiss:         "GT_size_cfmt"\n",  nomiss        );
        sf_printf_debug("\tunsorted:       "GT_size_cfmt"\n",  unsorted      );
        sf_printf_debug("\tencode:         "GT_size_cfmt"\n",  encode        );
        sf_printf_debug("\tcleanstr:       "GT_size_cfmt"\n",  cleanstr      );
        sf_printf_debug("\tnumfmt_max:     "GT_size_cfmt"\n",  numfmt_max    );
        sf_printf_debug("\tnumfmt_len:     "GT_size_cfmt"\n",  numfmt_len    );
        sf_printf_debug("\tcolsep_len:     "GT_size_cfmt"\n",  colsep_len    );
        sf_printf_debug("\tsep_len:        "GT_size_cfmt"\n",  sep_len       );
        sf_printf_debug("\tinit_targ:      "GT_size_cfmt"\n",  init_targ     );
        sf_printf_debug("\tinvertix:       "GT_size_cfmt"\n",  invertix      );
        sf_printf_debug("\tskipcheck:      "GT_size_cfmt"\n",  skipcheck     );
        sf_printf_debug("\tmlast:          "GT_size_cfmt"\n",  mlast         );
        sf_printf_debug("\tsubtract:       "GT_size_cfmt"\n",  subtract      );
        sf_printf_debug("\tctolerance:     "GT_size_cfmt"\n",  ctolerance    );
        sf_printf_debug("\n");                                                
        sf_printf_debug("\ttop_miss:       "GT_size_cfmt"\n",  top_miss      );
        sf_printf_debug("\ttop_groupmiss:  "GT_size_cfmt"\n",  top_groupmiss );
        sf_printf_debug("\ttop_other:      "GT_size_cfmt"\n",  top_other     );
        sf_printf_debug("\ttop_lmiss:      "GT_size_cfmt"\n",  top_lmiss     );
        sf_printf_debug("\ttop_lother:     "GT_size_cfmt"\n",  top_lother    );
        sf_printf_debug("\n");                                                
        sf_printf_debug("\tlevels_return:  "GT_size_cfmt"\n",  levels_return );
        sf_printf_debug("\tlevels_gen:     "GT_size_cfmt"\n",  levels_gen    );
        sf_printf_debug("\tlevels_replace: "GT_size_cfmt"\n",  levels_replace);
        sf_printf_debug("\n");                                                
        sf_printf_debug("\txtile_xvars:    "GT_size_cfmt"\n",  xtile_xvars   );
        sf_printf_debug("\txtile_nq:       "GT_size_cfmt"\n",  xtile_nq      );
        sf_printf_debug("\txtile_nq2:      "GT_size_cfmt"\n",  xtile_nq2     );
        sf_printf_debug("\txtile_cutvars:  "GT_size_cfmt"\n",  xtile_cutvars );
        sf_printf_debug("\txtile_ncuts:    "GT_size_cfmt"\n",  xtile_ncuts   );
        sf_printf_debug("\txtile_qvars:    "GT_size_cfmt"\n",  xtile_qvars   );
        sf_printf_debug("\txtile_gen:      "GT_size_cfmt"\n",  xtile_gen     );
        sf_printf_debug("\txtile_pctile:   "GT_size_cfmt"\n",  xtile_pctile  );
        sf_printf_debug("\txtile_genpct:   "GT_size_cfmt"\n",  xtile_genpct  );
        sf_printf_debug("\txtile_pctpct:   "GT_size_cfmt"\n",  xtile_pctpct  );
        sf_printf_debug("\txtile_altdef:   "GT_size_cfmt"\n",  xtile_altdef  );
        sf_printf_debug("\txtile_missing:  "GT_size_cfmt"\n",  xtile_missing );
        sf_printf_debug("\txtile_strict:   "GT_size_cfmt"\n",  xtile_strict  );
        sf_printf_debug("\txtile_minmax:   "GT_size_cfmt"\n",  xtile_minmax  );
        sf_printf_debug("\txtile_method:   "GT_size_cfmt"\n",  xtile_method  );
        sf_printf_debug("\txtile_bincount: "GT_size_cfmt"\n",  xtile_bincount);
        sf_printf_debug("\txtile__pctile:  "GT_size_cfmt"\n",  xtile__pctile );
        sf_printf_debug("\txtile_dedup:    "GT_size_cfmt"\n",  xtile_dedup   );
        sf_printf_debug("\txtile_cutifin:  "GT_size_cfmt"\n",  xtile_cutifin );
        sf_printf_debug("\txtile_cutby:    "GT_size_cfmt"\n",  xtile_cutby   );
        sf_printf_debug("\n");                                                
        sf_printf_debug("\thash_method:    "GT_size_cfmt"\n",  hash_method   );
        sf_printf_debug("\twcode:          "GT_size_cfmt"\n",  wcode         );
        sf_printf_debug("\twpos:           "GT_size_cfmt"\n",  wpos          );
        sf_printf_debug("\twselective:     "GT_size_cfmt"\n",  wselective    );
        sf_printf_debug("\tnunique:        "GT_size_cfmt"\n",  nunique       );
        sf_printf_debug("\tany_if:         "GT_size_cfmt"\n",  any_if        );
        sf_printf_debug("\tcountmiss:      "GT_size_cfmt"\n",  countmiss     );
        sf_printf_debug("\treplace:        "GT_size_cfmt"\n",  replace       );
        sf_printf_debug("\n");                                                
        sf_printf_debug("\tgroup_data:     "GT_size_cfmt"\n",  group_data    );
        sf_printf_debug("\tgroup_fill:     "GT_size_cfmt"\n",  group_fill    );
        sf_printf_debug("\n");                                                
        sf_printf_debug("\tkvars_stats:    "GT_size_cfmt"\n",  kvars_stats   );
        sf_printf_debug("\tkvars_targets:  "GT_size_cfmt"\n",  kvars_targets );
        sf_printf_debug("\tkvars_sources:  "GT_size_cfmt"\n",  kvars_sources );
        sf_printf_debug("\tkvars_group:    "GT_size_cfmt"\n",  kvars_group   );
        sf_printf_debug("\tkvars_by:       "GT_size_cfmt"\n",  kvars_by      );
        sf_printf_debug("\tkvars_by_int:   "GT_size_cfmt"\n",  kvars_by_int  );
        sf_printf_debug("\tkvars_by_num:   "GT_size_cfmt"\n",  kvars_by_num  );
        sf_printf_debug("\tkvars_by_str:   "GT_size_cfmt"\n",  kvars_by_str  );
        sf_printf_debug("\tkvars_by_strL:  "GT_size_cfmt"\n",  kvars_by_strL );
    }

    st_info->free = 1;

exit:

    return (rc);
}

/**
 * @brief Parse variable info from Stata
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores in @st_info various info from Stata for the pugin run
 */
ST_retcode sf_hash_byvars (struct StataInfo *st_info, int level)
{

    ST_retcode rc = 0, rc_isid = 0;
    clock_t timer  = clock();
    clock_t stimer = clock();

    GT_size *info, *index, *ix;
    GT_bool checksorted;
    GT_size i,
            j,
            k,
            obs,
            ilen,
            rowbytes,
            nj_min,
            nj_max;

    GT_size in1   = st_info->in1;
    GT_size N     = st_info->N;
    GT_size Nread = st_info->Nread;
    GT_size kvars = st_info->kvars_by;
    GT_size kstr  = st_info->kvars_by_str;

    // Parse positions in char array
    // -----------------------------

    st_info->positions   = calloc(kvars + 1, sizeof(st_info->positions));
    st_info->bymap_strL  = calloc(kvars,     sizeof(st_info->bymap_strL));
    st_info->byvars_mins = calloc(kvars,     sizeof(st_info->byvars_mins));
    st_info->byvars_maxs = calloc(kvars,     sizeof(st_info->byvars_maxs));

    if ( st_info->positions   == NULL ) return (sf_oom_error("sf_hash_byvars", "positions"));
    if ( st_info->bymap_strL  == NULL ) return (sf_oom_error("sf_hash_byvars", "bymap_strL"));
    if ( st_info->byvars_mins == NULL ) return (sf_oom_error("sf_hash_byvars", "byvars_mins"));
    if ( st_info->byvars_maxs == NULL ) return (sf_oom_error("sf_hash_byvars", "byvars_maxs"));

    GTOOLS_GC_ALLOCATED("st_info->positions")
    GTOOLS_GC_ALLOCATED("st_info->bymap_strL")
    GTOOLS_GC_ALLOCATED("st_info->byvars_mins")
    GTOOLS_GC_ALLOCATED("st_info->byvars_maxs")

    st_info->free = 2;

    // Position on the strL length array of the kth variable, if strL
    j = 0;
    for (k = 0; k < kvars; k++) {
        st_info->bymap_strL[k] = st_info->byvars_strL[k]? j++: -1;
    }

    // The by variables are copied to a custom array. echnically it is a
    // Tcharacter array, but it is structured as follows:
    //
    //     | numeric | string7 | numeric | string32 |
    //     | 8 bytes | 7 bytes | 8 bytes | 32 bytes |
    //
    // string variables. The exception is if the by variables are all
    // That is, we allocate enough bytes to hold all the numeric and
    //
    // numeric, in which case we simply use a numeric array. The
    // positions array stores the position of each entry. We have a
    // sepparate array that tells us the variable type and length of
    // each string (st_info->byvars_lens). So we have, in the example
    // above:
    //
    //     position[0] = 0
    //     position[1] = 8
    //     position[2] = 15
    //     position[3] = 23
    //
    //     st_info->byvars_lens[0] = -1
    //     st_info->byvars_lens[1] = 7
    //     st_info->byvars_lens[2] = -1
    //     st_info->byvars_lens[3] = 32
    //
    // -1 denotes double, so we know to read 8 bytes. Then rowbytes
    // would be 55, the total number of bytes required to store roweach
    // of the by variables.

    st_info->positions[0] = rowbytes = 0;
    for (k = 1; k < kvars + 1; k++) {
        ilen = st_info->byvars_lens[k - 1] * sizeof(char);
        if ( ilen > 0 ) {
            st_info->positions[k] = st_info->positions[k - 1] + (ilen + sizeof(char));
            rowbytes += (ilen + sizeof(char));
        }
        else {
            st_info->positions[k] = st_info->positions[k - 1] + sizeof(ST_double);
            rowbytes += sizeof(ST_double);
        }
    }
    st_info->rowbytes = rowbytes;

    if ( st_info->debug ) {
        printf("debug 6: Read in hash variable position and ranges\n");
    }

    /*********************************************************************
     *              Special processing for no by variables               *
     *********************************************************************/

    if ( st_info->kvars_by == 0 ) {

        // If there is only one group or no groups, it's faster to
        // process this sepparately since we know the answers for all
        // the variables we care about.

        st_info->strL_bytes = malloc(sizeof(st_info->strL_bytes));;
        st_info->st_numx    = malloc(sizeof(st_info->st_numx));
        st_info->st_charx   = malloc(sizeof(st_info->st_charx));

        st_info->index = calloc(st_info->N, sizeof(st_info->index));
        st_info->info  = calloc(2, sizeof(st_info->info));

        if ( st_info->index == NULL ) sf_oom_error("sf_hash_byvars", "st_info->index");

        GTOOLS_GC_ALLOCATED("st_info->info")
        GTOOLS_GC_ALLOCATED("st_info->index")
        GTOOLS_GC_ALLOCATED("st_info->strL_bytes")
        GTOOLS_GC_ALLOCATED("st_info->st_numx")
        GTOOLS_GC_ALLOCATED("st_info->st_charx")

        if ( st_info->any_if ) {
            obs = 0;
            for (i = 0; i < st_info->N; i++) {
                if ( SF_ifobs(i + in1) ) {
                    st_info->index[obs] = i;
                    ++obs;
                }
            }
            st_info->N = N = obs;

            if ( st_info->N < Nread ) {
                if ( st_info->N < 1 ) {
                    return (17001);
                }

                st_info->ix = calloc(N, sizeof(st_info->ix));
                if ( st_info->ix == NULL ) return (sf_oom_error("sf_hash_byvars", "st_info->ix"));
                GTOOLS_GC_ALLOCATED("st_info->ix")

                for (i = 0; i < N; i++)
                    st_info->ix[i] = i;
            }
            else {
                st_info->ix = st_info->index;
            }
        }
        else {
            for (i = 0; i < st_info->N; i++)
                st_info->index[i] = i;

            st_info->ix = st_info->index;
        }

        st_info->info[0]   = 0;
        st_info->info[1]   = st_info->N;
        st_info->free      = 5;
        st_info->biject    = 1;
        st_info->J         = 1;
        st_info->countonly = 1;
        st_info->seecount  = 0;
        st_info->byvars_mins[0] = 0;
        st_info->byvars_maxs[0] = 0;
        st_info->nj_min = st_info->N;
        st_info->nj_max = st_info->N;

        rc = sf_set_rinfo (st_info, level);
        return (rc);
    }

    index = calloc(N, sizeof(index));
    if ( index == NULL ) return (sf_oom_error("sf_read_byvars", "index"));
    GTOOLS_GC_ALLOCATED("index")

    if ( st_info->debug ) {
        printf("debug 7: No special processing for singleton group; allocated index\n");
    }

    /*********************************************************************
     *                       Read in by variables                        *
     *********************************************************************/

    if ( (rc = sf_read_byvars (st_info,
                               level,
                               index)) ) goto exit;

    if ( st_info->debug ) {
        printf("debug 8: Read in by variables\n");
    }

    // The number of variables passed in start / end may not be the same
    // as the nubmer read. In particular if an if condition was passed,
    // we will need to adjust the index.

    N = st_info->N;
    if ( st_info->N < Nread ) {
        if ( st_info->N < 1 ) {
            rc = 17001;
            goto exit;
        }

        ix = calloc(st_info->N, sizeof(ix));
        if ( ix == NULL ) return (sf_oom_error("sf_hash_byvars", "ix"));
        GTOOLS_GC_ALLOCATED("ix")

        for (i = 0; i < N; i++)
            ix[i] = i;
    }
    else {
        ix = index;
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 1: Read in by variables");

    stimer = clock();

    if ( st_info->debug ) {
        printf("debug 9: Allocated second index\n");
    }

    /*********************************************************************
     *                  Check whether is id (isid only)                  *
     *********************************************************************/

    if ( level == 2 ) {
        if ( st_info->debug ) {
            printf("debug 10: isid\n");
        }

        // If the data is already sorted, checking whether we have an id
        // is faster to do pre-hash than post.

        if ( st_info->kvars_by_str > 0 ) {
            if ( st_info->debug ) {
                printf("debug 11: checking ID with string mix\n");
            }

            if ( (rc = MultiIsIDCheckMC (st_info->st_charx,
                                         st_info->N,
                                         0,
                                         st_info->kvars_by - 1,
                                         st_info->rowbytes,
                                         st_info->byvars_lens,
                                         st_info->invert,
                                         st_info->positions)) >= 0 ) {

                if ( st_info->debug ) {
                    printf("debug 12: isid checked multi-level\n");
                }

                // rc == 0 means the result from a comparison was 0, that is,
                // two elements within a group were the same. This means that
                // we do NOt have an ID. rc == 1 means ALL eements were larger
                // than the previous one, meaning they all must be different
                // AND in order, so we do have an ID.

                if ( rc == 0 ) {
                    if ( st_info->verbose )
                        sf_printf("(duplicate row found during sort check)\n");

                    rc = 17459;
                }
                else {
                    if ( st_info->verbose )
                        sf_printf("(varlist is id; data was sorted in strict order)\n");

                    rc = 0;
                }

                goto exit;
            }
            else {
                if ( st_info->debug ) {
                    printf("debug 13: isid data is not sorted\n");
                }

                if ( st_info->verbose )
                    sf_printf("Data not sorted; will hash.\n");
            }
        }
        else {
            if ( st_info->debug ) {
                printf("debug 14: checking ID with numeric data only\n");
            }

            if ( (rc = MultiIsIDCheckDbl (st_info->st_numx,
                                          st_info->N,
                                          0,
                                          st_info->kvars_by - 1,
                                          st_info->kvars_by * sizeof(ST_double),
                                          st_info->invert)) >= 0 ) {

                if ( st_info->debug ) {
                    printf("debug 15: isid checked multi-level\n");
                }

                // Ibid.
                if ( rc == 0 ) {
                    if ( st_info->verbose )
                        sf_printf("(duplicate row found during sort check)\n");

                    rc = 17459;
                }
                else {
                    if ( st_info->verbose )
                        sf_printf("(varlist is id; data was sorted in strict order)\n");

                    rc = 0;
                }

                goto exit;
            }
            else {
                if ( st_info->debug ) {
                    printf("debug 16: isid data not sorted\n");
                }

                if ( st_info->verbose )
                    sf_printf("Data not sorted; will hash.\n");
            }
        }
    }

    /*********************************************************************
     *                          Check if sorted                          *
     *********************************************************************/

    if ( st_info->debug ) {
        printf("debug 17: check if data is sorted\n");
    }

    // With hashsort, only check if skipcheck is not specified; if
    // sorted simply exit. With isid, we have already checked and we
    // need to skip this part. With all others, check if it is sorted
    // and if so set up the panel recursively.

    checksorted = (level != 2) & (level != 3);
    if ( ((level == 3) & (st_info->skipcheck == 0)) | checksorted ) {

        if ( st_info->debug ) {
            printf("debug 18: checking if input by vars are sorted\n");
        }

        if ( st_info->kvars_by_str > 0 ) {
            if ( st_info->debug ) {
                printf("debug 19: mix with strings\n");
            }

            if ( st_info->mlast ) {
                st_info->sorted = MultiSortCheckMCMlast (
                    st_info->st_charx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->rowbytes,
                    st_info->byvars_lens,
                    st_info->invert,
                    st_info->positions
                );
            }
            else {
                st_info->sorted = MultiSortCheckMC (
                    st_info->st_charx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->rowbytes,
                    st_info->byvars_lens,
                    st_info->invert,
                    st_info->positions
                );
            }
        }
        else {
            if ( st_info->debug ) {
                printf("debug 20: mix only numeric\n");
            }

            if ( st_info->mlast ) {
                st_info->sorted = MultiSortCheckDblMlast(
                    st_info->st_numx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->kvars_by * sizeof(ST_double),
                    st_info->invert
                );
            }
            else {
                st_info->sorted = MultiSortCheckDbl(
                    st_info->st_numx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->kvars_by * sizeof(ST_double),
                    st_info->invert
                );
            }
        }

        if ( st_info->debug ) {
            printf("debug 21: sorted? %d\n", st_info->sorted? 1: 0);
        }

        if ( st_info->verbose & st_info->sorted )
            sf_printf("(already sorted)\n");
    }
    else {
        st_info->sorted = 0;
        if ( st_info->debug ) {
            printf("debug 22: data not sorted or no we skipped the check\n");
        }
    }

    if ( (level == 3) & (st_info->skipcheck == 0) & st_info->sorted ) {
        if ( st_info->debug ) {
            printf("debug 23: data is sorted and we want to sort, so we exit\n");
        }
        rc = 17013;
        goto exit;
    }

    if ( st_info->debug ) {
        printf("debug 24: checkpoint outside if-else\n");
    }

    // If the data is already sorted, then we can set up the panel
    // pre-hash, which is faster than post. We care about the index
    // and info arrays; the latter notes the starting position of each
    // group. This can simply be done when a group changes. This is
    // not trivial to do with multiple variables, but it's faster than
    // hashing since we are only doing comparisons and loops.

    checksorted = checksorted & (st_info->hash_method == 0);
    if ( checksorted & st_info->sorted ) {
        if ( st_info->debug ) {
            printf("debug 25: the data is already sorted; set up the panel directly\n");
        }

        GT_size *info_largest = calloc(st_info->N + 1, sizeof *info_largest);
        if ( info_largest == NULL ) return (sf_oom_error("sf_hash_byvars", "info_largest"));

        if ( st_info->kvars_by_str > 0 ) {
            if ( st_info->debug ) {
                printf("debug 26: sorted string mix multi-level panel setup\n");
            }

            if ( st_info->mlast ) {
                st_info->J = MultiSortPanelSetupMCMlast (
                    st_info->st_charx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->rowbytes,
                    st_info->byvars_lens,
                    st_info->invert,
                    st_info->positions,
                    info_largest,
                    0
                );
            }
            else {
                st_info->J = MultiSortPanelSetupMC (
                    st_info->st_charx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->rowbytes,
                    st_info->byvars_lens,
                    st_info->invert,
                    st_info->positions,
                    info_largest,
                    0
                );
            }
        }
        else {
            if ( st_info->debug ) {
                printf("debug 27: sorted numeric only multi-level panel setup\n");
            }

            if ( st_info->mlast ) {
                st_info->J = MultiSortPanelSetupDblMlast (
                    st_info->st_numx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->kvars_by * sizeof(ST_double),
                    st_info->invert,
                    info_largest,
                    0
                );
            }
            else {
                st_info->J = MultiSortPanelSetupDbl (
                    st_info->st_numx,
                    st_info->N,
                    0,
                    st_info->kvars_by - 1,
                    st_info->kvars_by * sizeof(ST_double),
                    st_info->invert,
                    info_largest,
                    0
                );
            }
        }

        info_largest[st_info->J] = st_info->N;

        st_info->info = calloc(st_info->J + 1, sizeof st_info->info);
        if ( st_info->info == NULL ) return (sf_oom_error("sf_hash_byvars", "st_info->info"));
        GTOOLS_GC_ALLOCATED("st_info->info")
        st_info->free = 4;

        for (i = 0; i < st_info->J + 1; i++)
            st_info->info[i] = info_largest[i];

        free(info_largest);

        if ( st_info->debug ) {
            printf("debug 28: set up done (group cutpoints)\n");
        }
    }

    if ( st_info->debug ) {
        printf("debug 29: checkpoint outside if-else\n");
    }

    /*********************************************************************
     *            Check whether to hash or to use a bijection            *
     *********************************************************************/

    // It's feasible to use a bijection when all the inputs are
    // integers. If all the source variables are numeric then we check
    // whether they are all integers and whether we can biject them into
    // the natural numbers. We check for that here.

    if ( checksorted & st_info->sorted ) {
        st_info->biject = 1;
        if ( st_info->debug ) {
            printf("debug 30: hash will use bijection\n");
        }
    }
    else if ( (kstr > 0) | (st_info->hash_method == 2) ) {
        st_info->biject = 0;
        if ( st_info->debug ) {
            printf("debug 31: hash will use spooky\n");
        }
    }
    else {
        if ( (rc = gf_bijection_limits (st_info, level)) ) goto exit;
        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\tPlugin step 2.1: Determined hashing strategy");

        if ( st_info->debug ) {
            printf("debug 32: hash strategy automagically determined\n");
        }
    }

    if ( st_info->debug ) {
        printf("debug 33: checkpoint outside if-else\n");
    }

    /*********************************************************************
     *                       Panel setup and info                        *
     *********************************************************************/

    // Hash or biject, then sort
    // -------------------------

    uint64_t *ghash1;
    uint64_t *ghash2;

    if ( checksorted & st_info->sorted ) {
        ghash1 = malloc(sizeof(uint64_t));
        ghash2 = malloc(sizeof(uint64_t));

        if ( st_info->debug ) {
            printf("debug 34: Allocated dummies for hash arrays.\n");
        }
    }
    else if ( st_info->biject ) {
        ghash1 = calloc(N, sizeof *ghash1);
        ghash2 = malloc(sizeof(uint64_t));

        if ( ghash1 == NULL ) sf_oom_error("sf_hash_byvars", "ghash1");
        if ( ghash2 == NULL ) sf_oom_error("sf_hash_byvars", "ghash2");

        if ( st_info->debug ) {
            printf("debug 35: Allocated one hash array for bijection.\n");
        }
    }
    else {
        ghash1 = calloc(N, sizeof *ghash1);
        ghash2 = calloc(N, sizeof *ghash2);

        if ( ghash1 == NULL ) sf_oom_error("sf_hash_byvars", "ghash1");
        if ( ghash2 == NULL ) sf_oom_error("sf_hash_byvars", "ghash2");

        if ( st_info->debug ) {
            printf("debug 35: Allocated two arrays for 128-bit hash.\n");
        }
    }

    GTOOLS_GC_ALLOCATED("ghash1")
    GTOOLS_GC_ALLOCATED("ghash2")

    if ( checksorted & st_info->sorted ) {
        if ( st_info->debug ) {
            printf("debug 36: Data already sorted; will skip hash.\n");
        }
    }
    else {
        if ( (rc = gf_hash (ghash1, ghash2, st_info, ix, stimer)) ) goto error;
        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        stimer = clock();

        if ( st_info->debug ) {
            printf("debug 37: Hashed by variables; spooky or bijection.\n");
        }
    }

    if ( st_info->debug ) {
        printf("debug 38: checkpoint outside if-else\n");
    }

    // Level 2 is code for isid
    // ------------------------

    if ( level == 2 ) {

        rc_isid = gf_isid (ghash1, ghash2, st_info, ix, !(st_info->biject));

        if ( st_info->debug ) {
            printf("debug 39: Checked id for unsorted data.\n");
        }

        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\tPlugin step 3: Checked if group is id");

        stimer = clock();

        st_info->J = st_info->N;
        st_info->nj_min = nj_min  = 1;
        st_info->nj_max = nj_max  = 1;

        if ( (rc = sf_set_rinfo (st_info, level)) ) goto error;

        rc = rc_isid;
    }
    else {

        // Otherwise, set up panel normally
        // --------------------------------

        // It's trivial to write code to find the group starting points
        // from a single array. Once we have the hash we only need to
        // check the positions where an entry changes.
        //
        // The only slight complication is that the spooky hash is a
        // two-part hash. We check whether the groups defined by the
        // first part are unique. Within the groups that are not unique
        // we refine the cutpoints using the second part.
        //
        // Most of the time the first part will be enough, so it's much
        // faster to only use the first part if it is sufficient.

        if ( checksorted & st_info->sorted ) {
            if ( st_info->debug ) {
                printf("debug 40: no need to set up panel if sorted.\n");
            }
        }
        else {
            if ( (rc = gf_panelsetup (ghash1,
                                      ghash2,
                                      st_info,
                                      ix,
                                      !(st_info->biject))) ) goto error;

            if ( st_info->debug ) {
                printf("debug 41: panel set up using hash info.\n");
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\tPlugin step 3.1: Created group index");

        st_info->free = 4;

        info   = st_info->info;
        nj_min = info[1] - info[0];
        nj_max = info[1] - info[0];
        for (j = 1; j < st_info->J; j++) {
            if (nj_min > (info[j + 1] - info[j])) nj_min = (info[j + 1] - info[j]);
            if (nj_max < (info[j + 1] - info[j])) nj_max = (info[j + 1] - info[j]);
        }

        if ( st_info->verbose || (st_info->countonly & st_info->seecount) ) {
            if ( nj_min == nj_max )
                sf_printf ("N = "
                           GT_size_cfmt"; "
                           GT_size_cfmt" balanced groups of size "
                           GT_size_cfmt"\n",
                           st_info->N, st_info->J, nj_min);
            else
                sf_printf ("N = "
                           GT_size_cfmt"; "
                           GT_size_cfmt" unbalanced groups of sizes "
                           GT_size_cfmt" to "
                           GT_size_cfmt"\n",
                           st_info->N, st_info->J, nj_min, nj_max);
        }

        st_info->nj_min = nj_min;
        st_info->nj_max = nj_max;

        if ( (rc = sf_set_rinfo (st_info, level)) ) goto error;

        if ( st_info->debug ) {
            printf("debug 42: some panel info using group cut points.\n");
        }

        // Copy Stata index in correct order
        // ---------------------------------

        // We keep track of 3 arrays throughout that help us read and
        // write grouped data from and to stata.
        //
        //     - info[j]:  The starting position of group j in the sorted hash;
        //                 info[J] is the number of observations.
        //
        //     - index[i]: info[j] to info[j + 1] (left inclusive, right exclusive)
        //                 are the starting and ending positions of group j.
        //                 index[info[j]] to index[info[j + 1] - 1] are the
        //                 positions of each entry in the group in the unsorted
        //                 data.
        //
        //     - ix[s]:    The group in sort order s; that is, the group ix[s]
        //                 has sort order s. In other words, processing groups
        //                 ix[0], ix[1], ..., ix[J - 1] would process them in
        //                 order.

        if ( st_info->N < Nread ) {

            st_info->index = calloc(st_info->N, sizeof(st_info->index));
            st_info->ix    = calloc(st_info->N, sizeof(st_info->ix));

            if ( st_info->index == NULL ) sf_oom_error("sf_hash_byvars", "st_info->index");
            if ( st_info->ix    == NULL ) sf_oom_error("sf_hash_byvars", "st_info->index");

            GTOOLS_GC_ALLOCATED("st_info->index")
            GTOOLS_GC_ALLOCATED("st_info->ix")

            for (i = 0; i < st_info->N; i++)
                st_info->index[i] = index[st_info->ix[i] = ix[i]];

            free (ix);
            free (index);
            GTOOLS_GC_FREED("index")
            GTOOLS_GC_FREED("ix")

            if ( st_info->debug ) {
                printf("debug 43: Adjust index if any obs were skipped (if/missing)\n");
            }
        }
        else {
            // st_info->index = calloc(st_info->N, sizeof(st_info->index));
            // if ( st_info->index == NULL ) sf_oom_error("sf_hash_byvars", "st_info->index");
            // GTOOLS_GC_ALLOCATED("st_info->index")
            //
            // for (i = 0; i < st_info->N; i++)
            //     st_info->index[i] = index[i];

            st_info->index = index;
            st_info->ix = st_info->index;

            GTOOLS_GC_FREED("index")
            GTOOLS_GC_ALLOCATED("st_info->index")

            if ( st_info->debug ) {
                printf("debug 44: Copy index as is.\n");
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\tPlugin step 3.2: Normalized group index and Stata index");

        st_info->free = 5;

        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\tPlugin step 3: Set up panel");

        stimer = clock();
    }

    if ( st_info->debug ) {
        printf("debug 45: Done with hasing, indexing, and all dat!\n");
    }

error:
    free (ghash1);
    free (ghash2);

    GTOOLS_GC_FREED("ghash1")
    GTOOLS_GC_FREED("ghash2")

    /*********************************************************************
     *                              Cleanup                              *
     *********************************************************************/

exit:

    return (rc);
}

ST_retcode sf_set_rinfo(struct StataInfo *st_info, int level)
{
    ST_retcode rc = 0;

    char *results = malloc(24 * sizeof(char));
    GTOOLS_GC_ALLOCATED("results")

    memset(results, '\0', 24 * sizeof(char));
    sprintf(results, "%.15g", (double) st_info->N);
    if ( (rc = SF_macro_save("_r_N",    results)) ) goto exit;

    memset(results, '\0', 24 * sizeof(char));
    sprintf(results, "%.15g", (double) st_info->J);
    if ( (rc = SF_macro_save("_r_J",    results)) ) goto exit;

    memset(results, '\0', 24 * sizeof(char));
    sprintf(results, "%.15g", (double) st_info->nj_min);
    if ( (rc = SF_macro_save("_r_minJ", results)) ) goto exit;

    memset(results, '\0', 24 * sizeof(char));
    sprintf(results, "%.15g", (double) st_info->nj_max);
    if ( (rc = SF_macro_save("_r_maxJ", results)) ) goto exit;

exit:
    free (results);
    GTOOLS_GC_FREED("results")

    return (rc);
}

ST_retcode sf_switch_io (struct StataInfo *st_info, int level, char* fname)
{

    // Here we decide whether or not to collapse the output to disk or
    // whether it will be faster to generate the variables in memory and
    // collapse to memory. We call it switching because at this point we
    // have not generated the targets in memory, so we are assuming that
    // collapsing to disk might be faster.
    //
    // If it will not be, we switch from this path. We will store info,
    // index, and ix in Stata and generate the variables there. We pick
    // up from this point and collapse to memory.

    ST_retcode rc = 0;
    GT_size i, j;
    clock_t timer = clock();

    ST_double st_time;
    if ( (rc = SF_scal_use ("__gtools_st_time", &st_time)) ) goto exit;

    if ( st_info->debug ) {
        printf("debug 46: I/O switching code.\n");
    }

    ST_double c_rate      = gf_benchmark(fname);
    ST_double time_vars   = (ST_double) (st_info->kvars_targets - st_info->kvars_sources);
    ST_double mib_base    = time_vars * 8 / 1024 / 1024;
    ST_double time_c      = (ST_double) st_info->J * c_rate * mib_base;
    ST_double time_cstata = (ST_double) st_info->J * st_time / st_info->N;
    ST_double c_time      = time_c + time_cstata;

    GT_bool used_io;
    if ( GTOOLS_QUERY_FREE_SPACE ) {
        ST_double mib_free = gf_query_free_space(fname);
        ST_double mib_c    = st_info->J * mib_base;
        used_io            = ( (mib_c < mib_free) & (c_time < st_time) );
    }
    else {
        used_io = (c_time < st_time);
    }

    if ( st_info->debug ) {
        printf("debug 47: Determine if we will write variables to disk.\n");
    }

    if ( st_info->verbose ) {

        sf_printf("Will write "GT_size_cfmt" extra targets to disk (full data = %.1f MiB; collapsed data = ",
                  (GT_size) time_vars, st_info->N * mib_base);
        sf_printf ((st_info->J * mib_base > 1)? "%.1f": "%.2g", st_info->J * mib_base);
        sf_printf(" MiB).\n");

        sf_printf("\tAdding targets before collapse estimated to take ");
        sf_printf ((st_time > 1)? "%.1f": "%.2g", st_time);
        sf_printf(" seconds.\n");

        sf_printf("\tAdding targets after collapse estimated to take ");
        sf_printf ((time_cstata > 1)? "%.1f": "%.2g", time_cstata);
        sf_printf(" seconds.\n");

        sf_printf("\tWriting/reading targets to/from disk estimated to take ");
        sf_printf ((time_c > 1)? "%.1f": "%.2g", time_c);
        sf_printf(" seconds.\n");

        if ( used_io ) {
            sf_printf("Will write to disk and read back later to save time.\n");
        }
        else {
            sf_printf("Writing to disk too slow; will do operations in memory.\n");
        }
    }

    if ( used_io ) {
        st_info->used_io = 1;

        if ( st_info->debug ) {
            printf("debug 48: Will use I/O; read back later.\n");
        }
    }
    else {
        GT_size kvars    = st_info->kvars_by;
        GT_size ksources = st_info->kvars_sources;
        GT_size kgroup   = st_info->kvars_group;
        GT_size ipos     = kvars + kgroup + ksources + ksources + 1;

        for (i = 0; i < st_info->N; i++)
            if ( (rc = SF_vstore(ipos, i + st_info->in1, st_info->index[i])) ) goto exit;

        for (j = 0; j < st_info->J; j++) {
            if ( (rc = SF_vstore(ipos + 1, j + st_info->in1, st_info->ix[j])) ) goto exit;
            if ( (rc = SF_vstore(ipos + 2, j + st_info->in1, st_info->info[j])) ) goto exit;
        }

        j = st_info->J;
        if ( (rc = SF_vstore(ipos + 2, j + st_info->in1, st_info->info[j])) ) goto exit;

        st_info->used_io = 0;

        if ( st_info->debug ) {
            printf("debug 49: Will not use I/O; must allocate all memory from Stata.\n");
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: C vs Stata benchmark");

exit:
    return (rc);
}

ST_retcode sf_switch_mem (struct StataInfo *st_info, int level)
{

    // Read in info, index, and ix from Stata after deciding to switch
    // and collapse stats to memory.

    ST_double z;
    ST_retcode rc = 0;
    GT_size i, j;
    clock_t timer = clock();

    st_info->index = calloc(st_info->N,     sizeof(st_info->index));
    st_info->ix    = calloc(st_info->J,     sizeof(st_info->ix));
    st_info->info  = calloc(st_info->J + 1, sizeof(st_info->info));

    if ( st_info->index == NULL ) return(sf_oom_error("sf_switch_mem", "st_info->index"));
    if ( st_info->info  == NULL ) return(sf_oom_error("sf_switch_mem", "st_info->info"));
    if ( st_info->ix    == NULL ) return(sf_oom_error("sf_switch_mem", "st_info->ix"));

    GT_size kvars    = st_info->kvars_by;
    GT_size ksources = st_info->kvars_sources;
    GT_size ktargets = st_info->kvars_targets;
    GT_size kgroup   = st_info->kvars_group;
    GT_size ipos     = kvars + kgroup + ksources + ktargets + 1;

    if ( st_info->debug ) {
        printf("debug 50: Index from stata.\n");
    }

    for (i = 0; i < st_info->N; i++) {
        if ( (rc = SF_vdata(ipos, i + st_info->in1, &z)) ) goto exit;
        st_info->index[i] = (GT_size) z;
    }

    for (j = 0; j < st_info->J; j++) {
        if ( (rc = SF_vdata(ipos + 1, j + st_info->in1, &z)) ) goto exit;
        st_info->ix[j] = (GT_size) z;
        if ( (rc = SF_vdata(ipos + 2, j + st_info->in1, &z)) ) goto exit;
        st_info->info[j] = (GT_size) z;
    }

    j = st_info->J;
    if ( (rc = SF_vdata(ipos + 2, j + st_info->in1, &z)) ) goto exit;
    st_info->info[j] = (GT_size) z;

    if ( st_info->debug ) {
        printf("debug 51: Read index and info stored in stata.\n");
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 4: Read info, index from Stata");

exit:
    return (rc);
}

/**
 * @brief Clean up st_info
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Frees memory allocated to st_info objects
 */
void sf_free (struct StataInfo *st_info, int level)
{
    if ( st_info->free >= 1 ) {
        free (st_info->wselmat);
        free (st_info->invert);
        free (st_info->missval);
        free (st_info->byvars_lens);
        free (st_info->group_targets);
        free (st_info->group_init);
        free (st_info->pos_num_byvars);
        free (st_info->pos_str_byvars);
        free (st_info->pos_targets);
        free (st_info->statcode);
        free (st_info->contract_which);
        free (st_info->xtile_quantiles);
        free (st_info->xtile_cutoffs);

        GTOOLS_GC_FREED("st_info->wselmat")
        GTOOLS_GC_FREED("st_info->invert")
        GTOOLS_GC_FREED("st_info->missval")
        GTOOLS_GC_FREED("st_info->byvars_lens")
        GTOOLS_GC_FREED("st_info->group_targets")
        GTOOLS_GC_FREED("st_info->group_init")
        GTOOLS_GC_FREED("st_info->pos_num_byvars")
        GTOOLS_GC_FREED("st_info->pos_str_byvars")
        GTOOLS_GC_FREED("st_info->pos_targets")
        GTOOLS_GC_FREED("st_info->statcode")
        GTOOLS_GC_FREED("st_info->contract_which")
        GTOOLS_GC_FREED("st_info->xtile_quantiles")
        GTOOLS_GC_FREED("st_info->xtile_cutoffs")
    }
    if ( (st_info->free >= 2) & (level != 11) ) {
        free (st_info->positions);
        free (st_info->bymap_strL);
        free (st_info->byvars_mins);
        free (st_info->byvars_maxs);

        GTOOLS_GC_FREED("st_info->positions")
        GTOOLS_GC_FREED("st_info->bymap_strL")
        GTOOLS_GC_FREED("st_info->byvars_mins")
        GTOOLS_GC_FREED("st_info->byvars_maxs")
    }
    if ( (st_info->free >= 3) & (st_info->free <= 5) & (level != 11) ) {
        free (st_info->strL_bytes);
        free (st_info->st_numx);
        free (st_info->st_charx);

        GTOOLS_GC_FREED("st_info->strL_bytes")
        GTOOLS_GC_FREED("st_info->st_numx")
        GTOOLS_GC_FREED("st_info->st_charx")
    }
    if ( st_info->free >= 4 ) {
        free (st_info->info);
        GTOOLS_GC_FREED("st_info->info")
    }
    if ( st_info->free >= 5 ) {
        free (st_info->index);
        GTOOLS_GC_FREED("st_info->index")
    }
    if ( st_info->free >= 7 ) {
        free (st_info->ix);
        GTOOLS_GC_FREED("st_info->ix")
    }
    if ( (st_info->free >= 6) & (st_info->free <= 7) & (level != 11) ) {
        free (st_info->strL_bybytes);
        free (st_info->st_by_numx);
        free (st_info->st_by_charx);

        GTOOLS_GC_FREED("st_info->strL_bybytes")
        GTOOLS_GC_FREED("st_info->st_by_numx")
        GTOOLS_GC_FREED("st_info->st_by_charx")
    }
    if ( st_info->free >= 9 ) {
        free (st_info->output);
        GTOOLS_GC_FREED("st_info->output")
    }
}
