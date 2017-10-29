/*********************************************************************
 * Program: gtools.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May 13 18:12:26 EDT 2017
 * Updated: Fri Oct 27 14:00:27 EDT 2017
 * Purpose: Stata plugin for faster group operations
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.8.4
 *********************************************************************/

/**
 * @file gtools.c
 * @author Mauricio Caceres Bravo
 * @date 25 Oct 2017
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
#include "common/encode.c"

#include "hash/gtools_hash.c"
#include "extra/gisid.c"
#include "extra/glevelsof.c"
#include "extra/hashsort.c"

#include "collapse/gtools_math.c"
#include "collapse/gtools_utils.c"
#include "collapse/gegen.c"

// #if GMULTI
// #    include ""
// #else
// #    include ""
// #endif

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

    if ( strcmp(todo, "check") == 0 ) {
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
    else if ( strcmp(todo, "collapse") == 0 ) {
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
        if ( (rc = sf_parse_info   (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars  (st_info, 0)) ) goto exit;
        if ( (rc = sf_check_hash   (st_info, 2)) ) goto exit;
        if ( (rc = sf_encode       (st_info, 0)) ) goto exit;
        if ( (rc = sf_egen_bulk    (st_info, 0)) ) goto exit;
        if ( (rc = sf_write_output (st_info, 0, st_info->kvars_targets, "")) ) goto exit;
    }
    else if ( strcmp(todo, "isid") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 2)) ) goto exit;
    }
    else if ( strcmp(todo, "levelsof") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 0)) ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit;
        if ( (rc = sf_levelsof    (st_info, 0)) ) goto exit;
        if ( (rc = sf_encode      (st_info, 0)) ) goto exit;
    }
    else if ( strcmp(todo, "hashsort") == 0 ) {
        if ( (rc = sf_parse_info  (st_info, 0)) ) goto exit;
        if ( (rc = sf_hash_byvars (st_info, 3)) ) goto exit;
        if ( (rc = sf_check_hash  (st_info, 2)) ) goto exit;
        if ( (rc = sf_hashsort    (st_info, 0)) ) goto exit;
        if ( (rc = sf_encode      (st_info, 0)) ) goto exit;
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
    GT_size verbose,
            benchmark,
            countonly,
            seecount,
            missing,
            nomiss,
            unsorted,
            encode,
            cleanstr,
            colsep_len,
            sep_len,
            init_targ,
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
            kvars_by_str;

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
    if ( (rc = sf_scalar_size("__gtools_verbose",      &verbose)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_benchmark",    &benchmark)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_any_if",       &any_if)        )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_init_targ",    &init_targ)     )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_seecount",     &seecount)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_countonly",    &countonly)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_unsorted",     &unsorted)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_missing",      &missing)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_nomiss",       &nomiss)        )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_replace",      &replace)       )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_countmiss",    &countmiss)     )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_cleanstr",     &cleanstr)      )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_colsep_len",   &colsep_len)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_sep_len",      &sep_len)       )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_encode",       &encode)        )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_group_data",   &group_data)    )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_group_fill",   &group_fill)    )) goto exit;

    if ( (rc = sf_scalar_size("__gtools_k_stats",      &kvars_stats)   )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_k_vars",       &kvars_sources) )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_k_targets",    &kvars_targets) )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_k_group",      &kvars_group)   )) goto exit;

    // Value fill for group
    if ( (rc = SF_scal_use("__gtools_group_val", &(st_info->group_val))) ) return (rc);

    // Parse number of variables
    if ( (rc = sf_scalar_size("__gtools_kvars",     &kvars_by)     )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_int", &kvars_by_int) )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_num", &kvars_by_num) )) goto exit;
    if ( (rc = sf_scalar_size("__gtools_kvars_str", &kvars_by_str) )) goto exit;

    // Parse variable lengths, positions, and sort order
    st_info->byvars_lens    = calloc(kvars_by,     sizeof st_info->byvars_lens);
    st_info->invert         = calloc(kvars_by,     sizeof st_info->invert);
    st_info->pos_num_byvars = calloc(kvars_by_num, sizeof st_info->pos_num_byvars);
    st_info->pos_str_byvars = calloc(kvars_by_str, sizeof st_info->pos_str_byvars);
    st_info->group_targets  = calloc(3,            sizeof st_info->group_targets);
    st_info->group_init     = calloc(3,            sizeof st_info->group_init);

    st_info->pos_targets = calloc((kvars_targets > 1)? kvars_targets : 1, sizeof st_info->pos_targets);
    st_info->statcode    = calloc((kvars_stats   > 1)? kvars_stats   : 1, sizeof st_info->statcode);

    if ( st_info->byvars_lens    == NULL ) return (sf_oom_error("sf_parse_info", "st_info->byvars_lens"));
    if ( st_info->invert         == NULL ) return (sf_oom_error("sf_parse_info", "st_info->invert"));
    if ( st_info->pos_num_byvars == NULL ) return (sf_oom_error("sf_parse_info", "st_info->pos_num_byvars"));
    if ( st_info->pos_str_byvars == NULL ) return (sf_oom_error("sf_parse_info", "st_info->pos_str_byvars"));
    if ( st_info->group_targets  == NULL ) return (sf_oom_error("sf_parse_info", "st_info->group_targets"));
    if ( st_info->group_init     == NULL ) return (sf_oom_error("sf_parse_info", "st_info->group_init"));

    if ( st_info->pos_targets == NULL ) return (sf_oom_error("sf_parse_info", "st_info->pos_targets"));
    if ( st_info->statcode    == NULL ) return (sf_oom_error("sf_parse_info", "st_info->statcode"));

    GTOOLS_GC_ALLOCATED("st_info->byvars_lens")
    GTOOLS_GC_ALLOCATED("st_info->invert")
    GTOOLS_GC_ALLOCATED("st_info->pos_num_byvars")
    GTOOLS_GC_ALLOCATED("st_info->pos_str_byvars")
    GTOOLS_GC_ALLOCATED("st_info->group_targets")
    GTOOLS_GC_ALLOCATED("st_info->group_init")
    GTOOLS_GC_ALLOCATED("st_info->pos_targets")
    GTOOLS_GC_ALLOCATED("st_info->statcode")

    if ( (rc = sf_get_vector_size ("__gtools_bylens", st_info->byvars_lens) )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_invert", st_info->invert)      )) goto exit;

    if ( (rc = sf_get_vector     ("__gtools_stats",       st_info->statcode)    )) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_pos_targets", st_info->pos_targets) )) goto exit;

    if ( kvars_by_num > 0 ) {
        if ( (rc = sf_get_vector_size ("__gtools_numpos", st_info->pos_num_byvars)) ) goto exit;
    }

    if ( kvars_by_str > 0 ) {
        if ( (rc = sf_get_vector_size ("__gtools_strpos", st_info->pos_str_byvars)) ) goto exit;
    }

    if ( (rc = sf_get_vector_size ("__gtools_group_targets", st_info->group_targets)) ) goto exit;
    if ( (rc = sf_get_vector_size ("__gtools_group_init",    st_info->group_init))    ) goto exit;

    /*********************************************************************
     *                    Save into st_info structure                    *
     *********************************************************************/

    GTOOLS_MIN (st_info->byvars_lens, kvars_by, strmax, i)

    st_info->in1           = in1;
    st_info->in2           = in2;
    st_info->N             = N;
    st_info->Nread         = N;

    st_info->verbose       = verbose;
    st_info->benchmark     = benchmark;
    st_info->any_if        = any_if;
    st_info->init_targ     = init_targ;
    st_info->strmax        = strmax;

    st_info->unsorted      = unsorted;
    st_info->countonly     = countonly;
    st_info->seecount      = seecount;
    st_info->missing       = missing;
    st_info->nomiss        = nomiss;
    st_info->replace       = replace;
    st_info->countmiss     = countmiss;

    st_info->cleanstr      = cleanstr;
    st_info->colsep_len    = colsep_len;
    st_info->sep_len       = sep_len;

    st_info->encode        = encode;
    st_info->group_data    = group_data;
    st_info->group_fill    = group_fill;

    st_info->kvars_by      = kvars_by;
    st_info->kvars_by_int  = kvars_by_int;
    st_info->kvars_by_num  = kvars_by_num;
    st_info->kvars_by_str  = kvars_by_str;

    st_info->kvars_group   = kvars_group;
    st_info->kvars_sources = kvars_sources;
    st_info->kvars_targets = kvars_targets;
    st_info->kvars_extra   = kvars_targets - kvars_sources;
    st_info->kvars_stats   = kvars_stats;

    /*********************************************************************
     *                              Cleanup                              *
     *********************************************************************/

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
    st_info->byvars_mins = calloc(kvars,     sizeof(st_info->byvars_mins));
    st_info->byvars_maxs = calloc(kvars,     sizeof(st_info->byvars_maxs));

    if ( st_info->positions   == NULL ) return (sf_oom_error("sf_hash_byvars", "positions"));
    if ( st_info->byvars_mins == NULL ) return (sf_oom_error("sf_hash_byvars", "byvars_mins"));
    if ( st_info->byvars_maxs == NULL ) return (sf_oom_error("sf_hash_byvars", "byvars_maxs"));

    GTOOLS_GC_ALLOCATED("st_info->positions")
    GTOOLS_GC_ALLOCATED("st_info->byvars_mins")
    GTOOLS_GC_ALLOCATED("st_info->byvars_maxs")

    st_info->free = 2;

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

    /*********************************************************************
     *              Special processing for no by variables               *
     *********************************************************************/

    if ( st_info->kvars_by == 0 ) {
        st_info->st_numx  = malloc(sizeof(ST_double));
        st_info->st_charx = malloc(sizeof(char));

        st_info->index = calloc(st_info->N, sizeof(st_info->index));
        st_info->info  = calloc(2, sizeof(st_info->info));

        if ( st_info->index == NULL ) sf_oom_error("sf_hash_byvars", "st_info->index");

        GTOOLS_GC_ALLOCATED("st_info->info")
        GTOOLS_GC_ALLOCATED("st_info->index")
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

    /*********************************************************************
     *                       Read in by variables                        *
     *********************************************************************/

    if ( (rc = sf_read_byvars (st_info,
                               level,
                               index)) ) goto exit;

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

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\tPlugin step 1: Read in by variables");

    stimer = clock();

    /*********************************************************************
     *                  Check whether is id (isid only)                  *
     *********************************************************************/

    if ( level == 2 ) {
        if ( st_info->kvars_by_str > 0 ) {
            if ( (rc = MultiIsIDCheckMC (st_info->st_charx,
                                         st_info->N,
                                         0,
                                         st_info->kvars_by - 1,
                                         st_info->rowbytes,
                                         st_info->byvars_lens,
                                         st_info->invert,
                                         st_info->positions)) >= 0 ) {

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
                if ( st_info->verbose )
                    sf_printf("Data not sorted; will hash.\n");
            }
        }
        else {
            if ( (rc = MultiIsIDCheckDbl(st_info->st_numx,
                                         st_info->N,
                                         0,
                                         st_info->kvars_by - 1,
                                         st_info->kvars_by * sizeof(ST_double),
                                         st_info->invert)) >= 0 ) {

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
                if ( st_info->verbose )
                    sf_printf("Data not sorted; will hash.\n");
            }
        }
    }

    /*********************************************************************
     *                  Check if sorted (hashsort only)                  *
     *********************************************************************/

    if ( level == 3 ) {
        if ( st_info->kvars_by_str > 0 ) {
            if ( MultiSortCheckMC (st_info->st_charx,
                                   st_info->N,
                                   0,
                                   st_info->kvars_by - 1,
                                   st_info->rowbytes,
                                   st_info->byvars_lens,
                                   st_info->invert,
                                   st_info->positions) ) {
                if ( st_info->verbose )
                    sf_printf("(already sorted)\n");
                rc = 17013;
                goto exit;
            }
        }
        else {
            if ( MultiSortCheckDbl(st_info->st_numx,
                                   st_info->N,
                                   0,
                                   st_info->kvars_by - 1,
                                   st_info->kvars_by * sizeof(ST_double),
                                   st_info->invert) ) {
                if ( st_info->verbose )
                    sf_printf("(already sorted)\n");
                rc = 17013;
                goto exit;
            }
        }
    }

    /*********************************************************************
     *            Check whether to hash or to use a bijection            *
     *********************************************************************/

    if ( kstr > 0 ) {
        st_info->biject = 0;
    }
    else {
        if ( (rc = gf_bijection_limits (st_info, level)) ) goto exit;
    }

    if ( st_info->benchmark )
        sf_running_timer (&stimer, "\t\tPlugin step 2.1: Determined hashing strategy");

    /*********************************************************************
     *                       Panel setup and info                        *
     *********************************************************************/

    // Hash and sort
    // -------------

    uint64_t *ghash1;
    uint64_t *ghash2;

    if ( st_info->biject ) {
        ghash1 = calloc(N, sizeof *ghash1);
        ghash2  = malloc(sizeof(uint64_t));

        if ( ghash1 == NULL ) sf_oom_error("sf_hash_byvars", "ghash1");
        if ( ghash2 == NULL ) sf_oom_error("sf_hash_byvars", "ghash2");
    }
    else {
        ghash1 = calloc(N, sizeof *ghash1);
        ghash2 = calloc(N, sizeof *ghash2);

        if ( ghash1 == NULL ) sf_oom_error("sf_hash_byvars", "ghash1");
        if ( ghash2 == NULL ) sf_oom_error("sf_hash_byvars", "ghash2");
    }

    GTOOLS_GC_ALLOCATED("ghash1")
    GTOOLS_GC_ALLOCATED("ghash2")

    if ( (rc = gf_hash (ghash1, ghash2, st_info, ix, stimer)) ) goto error;

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

    stimer = clock();

    // Level 2 is code for isid
    // ------------------------

    if ( level == 2 ) {

        rc_isid = gf_isid (ghash1, ghash2, st_info, ix, !(st_info->biject));

        if ( st_info->benchmark )
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

        if ( (rc = gf_panelsetup (ghash1,
                                  ghash2,
                                  st_info,
                                  ix,
                                  !(st_info->biject))) ) goto error;

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
                sf_printf ("N = "GT_size_cfmt"; "GT_size_cfmt" balanced groups of size "GT_size_cfmt"\n",
                           st_info->N, st_info->J, nj_min);
            else
                sf_printf ("N = "GT_size_cfmt"; "GT_size_cfmt" unbalanced groups of sizes "GT_size_cfmt" to "GT_size_cfmt"\n",
                           st_info->N, st_info->J, nj_min, nj_max);
        }

        st_info->nj_min = nj_min;
        st_info->nj_max = nj_max;

        if ( (rc = sf_set_rinfo (st_info, level)) ) goto error;

        // Copy Stata index in correct order
        // ---------------------------------

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
            GTOOLS_GC_FREED("ix")
        }
        else {
            st_info->index = calloc(st_info->N, sizeof(st_info->index));
            if ( st_info->index == NULL ) sf_oom_error("sf_hash_byvars", "st_info->index");
            GTOOLS_GC_ALLOCATED("st_info->index")

            for (i = 0; i < st_info->N; i++)
                st_info->index[i] = index[i];

            st_info->ix = st_info->index;
        }

        st_info->free = 5;

        if ( st_info->benchmark )
            sf_running_timer (&timer, "\tPlugin step 3: Set up panel");

        stimer = clock();
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

    free (index);
    GTOOLS_GC_FREED("index")

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
    ST_retcode rc = 0;
    GT_size i, j;
    clock_t timer = clock();

    ST_double st_time;
    if ( (rc = SF_scal_use ("__gtools_st_time", &st_time)) ) goto exit;

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
    }

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\tPlugin step 5: C vs Stata benchmark");

exit:
    return (rc);
}

ST_retcode sf_switch_mem (struct StataInfo *st_info, int level)
{
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

    if ( st_info->benchmark )
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
        free (st_info->invert);
        free (st_info->missval);
        free (st_info->byvars_lens);
        free (st_info->group_targets);
        free (st_info->group_init);
        free (st_info->pos_num_byvars);
        free (st_info->pos_str_byvars);
        free (st_info->pos_targets);
        free (st_info->statcode);

        GTOOLS_GC_FREED("st_info->invert")
        GTOOLS_GC_FREED("st_info->missval")
        GTOOLS_GC_FREED("st_info->byvars_lens")
        GTOOLS_GC_FREED("st_info->group_targets")
        GTOOLS_GC_FREED("st_info->group_init")
        GTOOLS_GC_FREED("st_info->pos_num_byvars")
        GTOOLS_GC_FREED("st_info->pos_str_byvars")
        GTOOLS_GC_FREED("st_info->pos_targets")
        GTOOLS_GC_FREED("st_info->statcode")
    }
    if ( (st_info->free >= 2) & (level != 11) ) {
        free (st_info->positions);
        free (st_info->byvars_mins);
        free (st_info->byvars_maxs);

        GTOOLS_GC_FREED("st_info->positions")
        GTOOLS_GC_FREED("st_info->byvars_mins")
        GTOOLS_GC_FREED("st_info->byvars_maxs")
    }
    if ( (st_info->free >= 3) & (st_info->free <= 5) & (level != 11) ) {
        free (st_info->st_numx);
        free (st_info->st_charx);

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
        free (st_info->st_by_numx);
        free (st_info->st_by_charx);

        GTOOLS_GC_FREED("st_info->st_by_numx")
        GTOOLS_GC_FREED("st_info->st_by_charx")
    }
    if ( st_info->free >= 9 ) {
        free (st_info->output);
        GTOOLS_GC_FREED("st_info->output")
    }
}
