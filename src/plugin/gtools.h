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

// Number of bits to sort each pass of the radix sort
#define RADIX_SHIFT 16

// Switch to reading data sequentially when the number of groups exceeds
// some portion of the number of observations, > N * [threshold]
//
// Switch to collapsing the data sequentially (i.e. not in parallel)
// when the number of groups is small, < [threshold].
// 
// Parallelism is tricky. On my system, running everything in parallel
// is usually faster. However, on the servers where I intend to use
// the plugin parallel execution is sometimes faster and sometimes
// slower. I'm in the process of figuring out whether being 'smart'
// about choosing parallelism is worth the hassle.

#define MULTI_SWITCH_THRESH_READ 0.1
#define MULTI_SWITCH_THRESH_COLLAPSE 1000

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
    int checkhash;
    int merge;
    int indexed;
    int integers_ok;
    int *byvars_lens;
    int *byvars_mins;
    int *byvars_maxs;
    int byvars_minlen;
    int byvars_maxlen;
    int strmax;
    int read_method;
    int read_method_multi;
    int collapse_method;
    char *statstr;
};

int  sf_parse_info  (struct StataInfo *st_info, int level);
int  sf_hash_byvars (struct StataInfo *st_info);
void sf_free        (struct StataInfo *st_info);
int  sf_numsetup    ();

#endif
