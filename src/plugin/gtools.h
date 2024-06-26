#ifndef GTOOLS
#define GTOOLS

#ifndef GTOOLSOMP
#define GTOOLSOMP 0
#endif

#if GTOOLSOMP
#include "omp.h"
#endif

#include "spi/stplugin.h"
#include "common/gttypes.h"

#define GTOOLS_VERSION "1.11.8"

/*
 * Style
 * -----
 *
 * ## Prefixes
 *
 * - GTOOLS_ for misc internal macros
 * - GT_ for internal types
 * - gf_ for functions that do not interact with Stata
 * - sf_ for functions that do interact with Stata
 * - st_ for objects that store information from/for Stata
 *
 * ## Types
 *
 * All doubles that hold stata data should be ST_double to ensure consistency
 * with the Stata interface.  For this reason, all return codes should be
 * ST_retcode as well, and you should stop using 42000 codes. Move to 17000
 * codes.
 *
 * However, integers will be GT* typed because they involve a type cast to
 * interact with anything form Stata anyway, and will be used internally
 * thereafter. This gives me more control over typing. On some systems,
 * size_t and int are not defined to their 64-bit counterparts because the
 * standard only asks for at least 16 bits.
 *
 */

// Tolerance for weighted percentiles (following Stata)
#define GTOOLS_WQUANTILES_TOL 1e-6
// #define GTOOLS_WQUANTILES_TOL 1e-12

// Largest 64-bit signed integer
#define GTOOLS_BIJECTION_LIMIT 9223372036854775807LL

// Machine epsilon
#define GTOOLS_64BIT_EPSILON 2.22e-16

// Libraries
#include <math.h>
#include <time.h>
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/types.h>

// Container structure for Stata-provided info
struct StataInfo {
    GT_size   start;
    GT_size   in1;
    GT_size   in2;
    GT_size   N;
    GT_size   Nread;
    GT_size   J;
    GT_size   nj_min;
    GT_size   nj_max;
    GT_size   strmax;
    GT_size   rowbytes;
    GT_size   free;
    GT_size   strbuffer;
    GT_size   sep_len;
    GT_size   colsep_len;
    GT_size   numfmt_max;
    GT_size   numfmt_len;
    GT_size   ctolerance;
    GT_size   gfile_byvar;
    GT_size   gfile_bycol;
    GT_size   gfile_bynum;
    GT_size   gfile_topnum;
    GT_size   gfile_topmat;
    GT_size   gfile_gregb;
    GT_size   gfile_gregse;
    GT_size   gfile_gregvcov;
    GT_size   gfile_gregclus;
    GT_size   gfile_gregabs;
    GT_size   gfile_greginfo;
    GT_size   gfile_ghdfeabs;
    //
    GT_size   biject;
    GT_size   encode;
    GT_size   group_data;
    GT_size   group_fill;
    ST_double group_val;
    GT_size   contract_vars;
    //
    ST_double top_ntop;
    ST_double top_pct;
    ST_double top_freq;
    GT_bool   top_matasave;
    GT_bool   top_invert;
    GT_bool   top_alpha;
    GT_bool   top_other;
    GT_bool   top_miss;
    GT_bool   top_groupmiss;
    GT_size   top_lother;
    GT_size   top_lmiss;
    GT_size   top_nrows;
    //
    GT_bool   levels_return;
    GT_bool   levels_matasave;
    GT_size   levels_gen;
    GT_bool   levels_replace;
    //
    GT_size xtile_xvars;
    GT_size xtile_nq;
    GT_size xtile_nq2;
    GT_size xtile_cutvars;
    GT_size xtile_ncuts;
    GT_size xtile_qvars;
    GT_size xtile_gen;
    GT_size xtile_pctile;
    GT_size xtile_genpct;
    GT_size xtile_pctpct;
    GT_bool xtile_altdef;
    GT_bool xtile_missing;
    GT_bool xtile_strict;
    GT_bool xtile_minmax;
    GT_bool xtile_method;
    GT_bool xtile_bincount;
    GT_bool xtile__pctile;
    GT_bool xtile_dedup;
    GT_bool xtile_cutifin;
    GT_bool xtile_cutby;
    //
    GT_size   gstats_code;
    GT_bool   winsor_trim;
    ST_double winsor_cutl;
    ST_double winsor_cuth;
    GT_size   winsor_kvars;
    GT_size   hdfe_kvars;
    GT_bool   hdfe_method;
    GT_size   hdfe_maxiter;
    GT_size   hdfe_traceiter;
    GT_bool   hdfe_standard;
    ST_double hdfe_hdfetol;
    GT_size   hdfe_absorb;
    GT_bool   hdfe_matasave;
    GT_size   hdfe_absorb_bytes;
    GT_int    *hdfe_absorb_types;
    GT_size   *hdfe_absorb_offsets;
    GT_size   summarize_colvar;
    GT_size   summarize_pooled;
    GT_size   summarize_normal;
    GT_size   summarize_detail;
    GT_size   summarize_kvars;
    GT_size   summarize_kstats;
    ST_double *summarize_codes;
    //
    GT_bool   transform_greedy;
    GT_size   transform_kvars;
    GT_size   transform_ktargets;
    GT_size   transform_kgstats;
    GT_size   transform_range_k;
    GT_bool   transform_range_xs;
    GT_bool   transform_range_xb;
    GT_size   transform_cumk;
    GT_size   *transform_rank_ties;
    ST_double *transform_varfuns;
    ST_double *transform_statcode;
    GT_size   *transform_statmap;
    ST_double *transform_moving;
    ST_double *transform_moving_l;
    ST_double *transform_moving_u;
    GT_size   *transform_range_pos;
    ST_double *transform_range;
    ST_double *transform_range_l;
    ST_double *transform_range_u;
    ST_double *transform_range_ls;
    ST_double *transform_range_us;
    GT_int    *transform_cumtypes;
    GT_size   *transform_cumsum;
    GT_size   *transform_cumsign;
    GT_size   *transform_cumvars;
    GT_int    *transform_aux8_shift;
    //
    GT_size   gregress_kvars;
    GT_bool   gregress_cons;
    GT_bool   gregress_robust;
    GT_size   gregress_cluster;
    GT_size   gregress_cluster_bytes;
    GT_size   gregress_absorb;
    GT_size   gregress_absorb_bytes;
    ST_double gregress_hdfetol;
    GT_size   gregress_hdfemaxiter;
    GT_bool   gregress_hdfetraceiter;
    GT_bool   gregress_hdfestandard;
    GT_bool   gregress_hdfemethod;
    GT_bool   gregress_savemata;
    GT_bool   gregress_savemb;
    GT_bool   gregress_savemse;
    GT_bool   gregress_savegb;
    GT_bool   gregress_savegse;
    GT_bool   gregress_saveghdfe;
    GT_bool   gregress_savegresid;
    GT_bool   gregress_savegpred;
    GT_bool   gregress_savegalph;
    GT_bool   gregress_savecons;
    GT_bool   gregress_moving;
    GT_int    gregress_moving_l;
    GT_int    gregress_moving_u;
    GT_bool   gregress_range;
    ST_double gregress_range_l;
    ST_double gregress_range_u;
    ST_double gregress_range_ls;
    ST_double gregress_range_us;
    GT_bool   gregress_glmfam;
    GT_bool   gregress_glmlogit;
    GT_bool   gregress_glmpoisson;
    GT_size   gregress_glmiter;
    ST_double gregress_glmtol;
    GT_bool   gregress_ivreg;
    GT_size   gregress_ivkendog;
    GT_size   gregress_ivkexog;
    GT_size   gregress_ivkz;
    GT_int    *gregress_cluster_types;
    GT_size   *gregress_cluster_offsets;
    GT_int    *gregress_absorb_types;
    GT_size   *gregress_absorb_offsets;
    //
    GT_bool   greshape_dropmiss;
    GT_bool   greshape_code;
    GT_size   greshape_kxij;
    GT_size   greshape_kxi;
    GT_size   greshape_kout;
    GT_size   greshape_klvls;
    GT_size   greshape_str;
    GT_size   greshape_jfile;
    GT_size   greshape_anystr;
    GT_size   *greshape_types;
    GT_size   *greshape_xitypes;
    GT_size   *greshape_maplevel;
    //
    GT_bool   hash_method;
    GT_bool   wcode;
    GT_bool   nunique;
    GT_bool   sorted;
    GT_bool   cleanstr;
    GT_bool   init_targ;
    GT_bool   any_if;
    GT_bool   invertix;
    GT_bool   skipcheck;
    GT_bool   mlast;
    GT_bool   subtract;
    GT_bool   verbose;
    GT_bool   debug;
    GT_bool   benchmark;
    GT_bool   countonly;
    GT_bool   seecount;
    GT_bool   keepmiss;
    GT_bool   missing;
    GT_bool   unsorted;
    GT_bool   nomiss;
    GT_bool   replace;
    GT_bool   countmiss;
    GT_bool   used_io;
    //
    GT_size   wselective;
    GT_size   wpos;
    GT_size   kvars_group;
    GT_size   kvars_sources;
    GT_size   kvars_targets;
    GT_size   kvars_extra;
    GT_size   kvars_stats;
    GT_size   kvars_by;
    GT_size   kvars_by_int;
    GT_size   kvars_by_num;
    GT_size   kvars_by_str;
    GT_size   kvars_by_strL;
    //
    GT_size   *pos_targets;
    ST_double *statcode;
    GT_size   *contract_which;
    ST_double *xtile_quantiles;
    ST_double *xtile_cutoffs;
    //
    GT_int    *byvars_mins;
    GT_int    *byvars_maxs;
    GT_size   *byvars_lens;
    GT_bool   *byvars_strL;
    GT_int    *bymap_strL;
    GT_size   *pos_num_byvars;
    GT_size   *pos_str_byvars;
    GT_size   *group_targets;
    GT_size   *group_init;
    GT_size   *wselmat;
    GT_size   *invert;
    GT_size   *positions;
    ST_double *missval;
    //
    GT_size   *ix;
    GT_size   *index;
    GT_size   *info;
    GT_size   *strL_bytes;
    GT_size   *strL_bybytes;
    ST_double *output;
    ST_double *st_numx;
    ST_double *st_by_numx;
    char *st_charx;
    char *st_by_charx;
    //
    char *gc_info;
};


// Some useful macros
#define GTOOLS_CHAR(cvar, len)                   \
    char *(cvar) = malloc(sizeof(char) * (len)); \
    memset ((cvar), '\0', sizeof(char) * (len))

#define GTOOLS_MIN(x, N, min, _i)             \
    typeof (*x) (min) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
    }                                         \

#define GTOOLS_MAX(x, N, max, _i)             \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

#define GTOOLS_MINMAX(x, N, min, max, _i)     \
    typeof (*x) (min) = *x;                   \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

#define GTOOLS_PWMAX(a, b) ( (a) > (b) ? (a) : (b) )
#define GTOOLS_PWMIN(a, b) ( (a) > (b) ? (b) : (a) )

// Check if you're actually cleaning up after yourself
#define GTOOLS_GC_INIT                              \
    st_info->gc_info = malloc(4096 * sizeof(char)); \
    memset (st_info->gc_info, '\0', 4096 * sizeof(char));

#define GTOOLS_GC_ALLOCATED(a)                \
    strcat (st_info->gc_info, "allocated: "); \
    strcat (st_info->gc_info, (a));           \
    strcat (st_info->gc_info, "\n");

#define GTOOLS_GC_FREED(f)                \
    strcat (st_info->gc_info, "freed: "); \
    strcat (st_info->gc_info, (f));       \
    strcat (st_info->gc_info, "\n");

#define GTOOLS_GC_END(p)                      \
    if ( p ) printf ("%s", st_info->gc_info); \
    free (st_info->gc_info);

// Switch missing values
#define GTOOLS_SWITCH_MISSING                                                \
         if ( z <= SV_missval )             strpos += sprintf(strpos, ".");  \
    else if ( z <= 8.990660123939097e+307 ) strpos += sprintf(strpos, ".a"); \
    else if ( z <= 8.992854573566614e+307 ) strpos += sprintf(strpos, ".b"); \
    else if ( z <= 8.995049023194132e+307 ) strpos += sprintf(strpos, ".c"); \
    else if ( z <= 8.997243472821649e+307 ) strpos += sprintf(strpos, ".d"); \
    else if ( z <= 8.999437922449167e+307 ) strpos += sprintf(strpos, ".e"); \
    else if ( z <= 9.001632372076684e+307 ) strpos += sprintf(strpos, ".f"); \
    else if ( z <= 9.003826821704202e+307 ) strpos += sprintf(strpos, ".g"); \
    else if ( z <= 9.006021271331719e+307 ) strpos += sprintf(strpos, ".h"); \
    else if ( z <= 9.008215720959237e+307 ) strpos += sprintf(strpos, ".i"); \
    else if ( z <= 9.010410170586754e+307 ) strpos += sprintf(strpos, ".j"); \
    else if ( z <= 9.012604620214272e+307 ) strpos += sprintf(strpos, ".k"); \
    else if ( z <= 9.014799069841789e+307 ) strpos += sprintf(strpos, ".l"); \
    else if ( z <= 9.016993519469307e+307 ) strpos += sprintf(strpos, ".m"); \
    else if ( z <= 9.019187969096824e+307 ) strpos += sprintf(strpos, ".n"); \
    else if ( z <= 9.021382418724342e+307 ) strpos += sprintf(strpos, ".o"); \
    else if ( z <= 9.023576868351859e+307 ) strpos += sprintf(strpos, ".p"); \
    else if ( z <= 9.025771317979377e+307 ) strpos += sprintf(strpos, ".q"); \
    else if ( z <= 9.027965767606894e+307 ) strpos += sprintf(strpos, ".r"); \
    else if ( z <= 9.030160217234412e+307 ) strpos += sprintf(strpos, ".s"); \
    else if ( z <= 9.032354666861929e+307 ) strpos += sprintf(strpos, ".t"); \
    else if ( z <= 9.034549116489447e+307 ) strpos += sprintf(strpos, ".u"); \
    else if ( z <= 9.036743566116964e+307 ) strpos += sprintf(strpos, ".v"); \
    else if ( z <= 9.038938015744481e+307 ) strpos += sprintf(strpos, ".w"); \
    else if ( z <= 9.041132465371999e+307 ) strpos += sprintf(strpos, ".x"); \
    else if ( z <= 9.043326914999516e+307 ) strpos += sprintf(strpos, ".y"); \
    else if ( z <= 9.045521364627034e+307 ) strpos += sprintf(strpos, ".z"); \
    else                                    strpos += sprintf(strpos, ".");

// Windows-specific foo
#if defined(_WIN64) || defined(_WIN32)

// statvfs is POSIX only; repalce with dummies on windows
#define GTOOLS_QUERY_FREE_SPACE 0
struct statvfs {
    int f_bsize;
    int f_bfree;
};

void statvfs (char *path, struct statvfs *info);
void statvfs (char *path, struct statvfs *info)
{
    info->f_bsize = 0;
    info->f_bfree = 0;
}

char * strndup (const char *s, size_t n);
char * strndup (const char *s, size_t n)
{
  return (char *) strdup (s);
}

#else

// Use statvfs to query free space in tmp drive
#define GTOOLS_QUERY_FREE_SPACE 1
#include <sys/statvfs.h>

#endif

// Functions
void sf_free (struct StataInfo *st_info, int level);

ST_retcode sf_parse_info  (struct StataInfo *st_info, int level);
ST_retcode sf_hash_byvars (struct StataInfo *st_info, int level);
ST_retcode sf_check_hash  (struct StataInfo *st_info, int level);
ST_retcode sf_switch_io   (struct StataInfo *st_info, int level, char* fname);
ST_retcode sf_switch_mem  (struct StataInfo *st_info, int level);
ST_retcode sf_set_rinfo   (struct StataInfo *st_info, int level);

// Define dummy strl functions to use the same code with SPI 2.0
#ifndef SF_var_is_binary
#define SF_var_is_binary(i, j) 0
#endif

#ifndef SF_var_is_strl
#define SF_var_is_strl(a) 0
#endif

#ifndef SF_sdatalen
#define SF_sdatalen(i, j) 0
#endif

#ifndef SF_strldata
#define SF_strldata(i, j, s, l) -1
#endif

#endif

// Important notes!
// ----------------

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
