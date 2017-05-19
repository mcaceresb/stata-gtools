#ifndef GTOOLS
#define GTOOLS

// Libraries
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
    int merge;
    int indexed;
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
void sf_free        (struct StataInfo *st_info);

#endif
