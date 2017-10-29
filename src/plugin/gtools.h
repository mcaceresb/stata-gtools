#ifndef GTOOLS
#define GTOOLS

#include "spi/stplugin.h"
#include "common/gttypes.h"

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

// Largest 64-bit signed integer
#define GTOOLS_BIJECTION_LIMIT 9223372036854775807LL

// Libraries
#include <math.h>
#include <time.h>
#include <stdio.h>
#include <locale.h>
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
    //        
    GT_size   biject;
    GT_size   encode;
    GT_size   group_data;
    GT_size   group_fill;
    ST_double group_val;
    //
    GT_bool   cleanstr;
    GT_bool   init_targ;
    GT_bool   any_if;
    GT_bool   verbose;
    GT_bool   benchmark;
    GT_bool   countonly;
    GT_bool   seecount;
    GT_bool   missing;
    GT_bool   unsorted;
    GT_bool   nomiss;
    GT_bool   replace;
    GT_bool   countmiss;
    GT_bool   used_io;
    //        
    GT_size   kvars_group;
    GT_size   kvars_sources;
    GT_size   kvars_targets;
    GT_size   kvars_extra;
    GT_size   kvars_stats;
    GT_size   kvars_by;
    GT_size   kvars_by_int;
    GT_size   kvars_by_num;
    GT_size   kvars_by_str;
    //
    GT_size   *pos_targets;
    ST_double *statcode;
    //
    GT_int    *byvars_mins;
    GT_int    *byvars_maxs;
    GT_size   *byvars_lens;
    GT_size   *pos_num_byvars;
    GT_size   *pos_str_byvars;
    GT_size   *group_targets;
    GT_size   *group_init;
    GT_size   *invert;
    GT_size   *positions;
    ST_double *missval;
    //
    GT_size   *ix;
    GT_size   *index;
    GT_size   *info;
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

#endif
