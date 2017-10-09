#ifndef GTOOLS
#define GTOOLS

// Libraries
// ---------

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

// Definitions
// -----------

// Type for mixed string and numeric arrays
typedef union {
    double dval;
    char *cval;
} MixedUnion;

// Number of bits to sort each pass of the radix sort
#define RADIX_SHIFT 16

// Container structure for Stata-provided info
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
    //
    int sort_memory;
    int any_if;
    int clean_str;
    int *invert;
    //
    int *pos_targets;
    int *pos_num_byvars;
    int *pos_str_byvars;
    //
    int kvars_targets;
    int kvars_source;
    int kvars_by;
    int kvars_by_num;
    int kvars_by_str;
    //
    int verbose;
    int benchmark;
    int checkhash;
    int missing;
    int merge;
    int indexed;
    int integers_ok;
    //
    int *byvars_lens;
    int *byvars_mins;
    int *byvars_maxs;
    int *byvars_int;
    int byvars_minlen;
    int byvars_maxlen;
    //
    size_t sep_len;
    size_t colsep_len;
    size_t strbuffer;
    int strmax;
    char *statstr;
    int group_data;
    int group_fill;
    int group_count;
    double group_val;
    //
    int read_dtax;
    char* st_charx;
    MixedUnion *st_dtax;
    double *output;
    double *st_numx;
};

// Main programs in gtools
int  sf_parse_info  (struct StataInfo *st_info, int level);
int  sf_hash_byvars (struct StataInfo *st_info);
void sf_free        (struct StataInfo *st_info);
int  sf_numsetup    ();
int  sf_anyobs_sel  ();

// Windows-specific foo
// --------------------

#if defined(_WIN64) || defined(_WIN32)

#define FMT "%lu"
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

#define FMT "%'lu"
#define SFMT "%lu"

// Use statvfs to query free space in tmp drive
#define QUERY_FREE_SPACE 1
#include <sys/statvfs.h>

#endif


#endif
