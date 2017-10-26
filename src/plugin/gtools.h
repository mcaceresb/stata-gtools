#ifndef GTOOLS
#define GTOOLS

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
    size_t start;
    size_t in1;
    size_t in2;
    size_t N;
    size_t Nread;
    size_t J;
    size_t nj_min;
    size_t nj_max;
    size_t strmax;
    size_t rowbytes;
    size_t free;
    size_t strbuffer;
    size_t sep_len;
    size_t colsep_len;
    //
    size_t biject;
    size_t encode;
    size_t group_data;
    size_t group_fill;
    double group_val;
    //
    short cleanstr;
    short init_targ;
    short any_if;
    short verbose;
    short benchmark;
    short countonly;
    short missing;
    short unsorted;
    short nomiss;
    short replace;
    short countmiss;
    short used_io;
    //
    size_t kvars_group;
    size_t kvars_sources;
    size_t kvars_targets;
    size_t kvars_extra;
    size_t kvars_stats;
    size_t kvars_by;
    size_t kvars_by_int;
    size_t kvars_by_num;
    size_t kvars_by_str;
    //
    size_t *pos_targets;
    double *statcode;
    //
    size_t *byvars_lens;
    int    *byvars_mins;
    int    *byvars_maxs;
    size_t *pos_num_byvars;
    size_t *pos_str_byvars;
    size_t *group_targets;
    size_t *group_init;
    size_t *invert;
    size_t *positions;
    double *missval;
    //
    size_t *ix;
    size_t *index;
    size_t *info;
    char   *st_charx;
    double *st_numx;
    char   *st_by_charx;
    double *st_by_numx;
    double *output;
    //
    char *gc_info;
};

// Check if you're actually cleaning up after yourself
#define ST_GC_INIT                                  \
    st_info->gc_info = malloc(4096 * sizeof(char)); \
    memset (st_info->gc_info, '\0', 4096 * sizeof(char));

#define ST_GC_ALLOCATED(a)                    \
    strcat (st_info->gc_info, "allocated: "); \
    strcat (st_info->gc_info, (a));           \
    strcat (st_info->gc_info, "\n");

#define ST_GC_FREED(f)                    \
    strcat (st_info->gc_info, "freed: "); \
    strcat (st_info->gc_info, (f));       \
    strcat (st_info->gc_info, "\n");

#define ST_GC_END(p)                          \
    if ( p ) printf ("%s", st_info->gc_info); \
    free (st_info->gc_info);

// Switch missing values
#define MF_SWITCH_MISSING                                                    \
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

// Formatting
#define  FMT "%lu"
#define SFMT "%lu"

// statvfs is POSIX only; repalce with dummies on windows
#define QUERY_FREE_SPACE 0
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

// Formatting
#define FMT "%'lu"
#define SFMT "%lu"

// Use statvfs to query free space in tmp drive
#define QUERY_FREE_SPACE 1
#include <sys/statvfs.h>

#endif

// Functions
void sf_free       (struct StataInfo *st_info, int level);
int sf_parse_info  (struct StataInfo *st_info, int level);
int sf_hash_byvars (struct StataInfo *st_info, int level);
int sf_check_hash  (struct StataInfo *st_info, int level);
int sf_switch_io   (struct StataInfo *st_info, int level, char* fname);
int sf_switch_mem  (struct StataInfo *st_info, int level);

#endif
