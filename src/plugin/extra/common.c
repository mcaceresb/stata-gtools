#include "common.h"

int sf_parse_info_lean (struct StataInfo *st_info, int level)
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

    // Clean condition
    int clean_str;
    ST_double clean_str_double ;
    if ( (rc = SF_scal_use("__gtools_clean", &clean_str_double)) ) {
        return(rc) ;
    }
    else {
        clean_str = (int) clean_str_double;
    }

    // If condition
    int missing;
    ST_double missing_double ;
    if ( (rc = SF_scal_use("__gtools_missing", &missing_double)) ) {
        return(rc) ;
    }
    else {
        missing = (int) missing_double;
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

    // Separator length
    int colsep_len;
    ST_double colsep_len_double ;
    if ( (rc = SF_scal_use("__gtools_colsep_len", &colsep_len_double)) ) {
        return(rc) ;
    }
    else {
        colsep_len = (int) colsep_len_double;
    }

    // Separator length
    int sep_len;
    ST_double sep_len_double ;
    if ( (rc = SF_scal_use("__gtools_sep_len", &sep_len_double)) ) {
        return(rc) ;
    }
    else {
        sep_len = (int) sep_len_double;
    }

    // Whether to invert the sort order of group variables post collapse
    st_info->invert = calloc(kvars_by, sizeof st_info->invert);
    if ( st_info->invert == NULL ) return(sf_oom_error("sf_parse_info", "st_info->invert"));
    if ( level == 0 ) {
        for (k = 0; k < kvars_by; k++)
            st_info->invert[k] = 0;
    }
    else if ( level == 1 ) {
        double *invert_double = calloc(kvars_by, sizeof *invert_double);
        if ( invert_double == NULL ) return(sf_oom_error("sf_parse_info", "invert_double"));

        if ( (rc = sf_get_vector("__gtools_invert", invert_double)) ) return(rc);
        for (k = 0; k < kvars_by; k++)
            st_info->invert[k] = (int) invert_double[k];

        free (invert_double);
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
     *           Relative position of targets and by variables           *
     *********************************************************************/

    size_t strmax = byvars_maxlen > 0? byvars_maxlen + 1: 1;

    st_info->pos_num_byvars = calloc(kvars_by_num,  sizeof st_info->pos_num_byvars);
    st_info->pos_str_byvars = calloc(kvars_by_str,  sizeof st_info->pos_str_byvars);

    if ( st_info->pos_num_byvars == NULL ) return(sf_oom_error("sf_parse_info", "st_info->pos_num_byvars"));
    if ( st_info->pos_str_byvars == NULL ) return(sf_oom_error("sf_parse_info", "st_info->pos_str_byvars"));

    double *pos_str_byvars_double = calloc(kvars_by_str, sizeof *pos_str_byvars_double);
    double *pos_num_byvars_double = calloc(kvars_by_num, sizeof *pos_num_byvars_double);

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
    st_info->missing             = missing;
    st_info->clean_str           = clean_str;
    st_info->sep_len             = sep_len;
    st_info->colsep_len          = colsep_len;
    st_info->kvars_by            = kvars_by;
    st_info->kvars_by_num        = kvars_by_num;
    st_info->kvars_by_str        = kvars_by_str;
    st_info->verbose             = verbose;
    st_info->benchmark           = benchmark;
    st_info->integers_ok         = integers_ok;
    st_info->byvars_minlen       = byvars_minlen;
    st_info->byvars_maxlen       = byvars_maxlen;
    st_info->strmax              = strmax;
    st_info->sort_memory         = !integers_ok;
    st_info->kvars_targets       = 0;
    st_info->indexed             = 0;

    if ( benchmark ) sf_running_timer (&timer, "\tPlugin step 1: stata parsing done");
    return (0);
}

void sf_free_lean (struct StataInfo *st_info)
{
    free (st_info->info);
    free (st_info->index);
    free (st_info->invert);
    free (st_info->byvars_int);
    free (st_info->byvars_lens);
    free (st_info->byvars_mins);
    free (st_info->byvars_maxs);
    free (st_info->pos_num_byvars);
    free (st_info->pos_str_byvars);
}
