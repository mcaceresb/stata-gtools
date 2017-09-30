#ifndef GTOOLS_HASH
#define GTOOLS_HASH

int sf_get_variable_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k,
    size_t in1,
    size_t in2,
    int strmax,
    short verbose 
);

int sf_get_varlist_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int karr[],
    short verbose
);

int sf_get_variable_ashash (
    uint64_t h1[],
    size_t k,
    size_t in1,
    size_t in2,
    int min,
    int max,
    short verbose
);

int sf_get_varlist_bijection (
    uint64_t h1[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int mins[],
    int maxs[],
    short verbose
);

int sf_check_hash_index (struct StataInfo *st_info, int read_dtax);
int sf_check_hashsort (struct StataInfo *st_info);

#endif
