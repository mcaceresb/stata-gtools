#ifndef GTOOLS_HASH
#define GTOOLS_HASH

int sf_get_variable_bijection (
    uint64_t h1[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int maxs[],
    int mins[]
);

int sf_get_variable_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k,
    size_t in1,
    size_t in2,
    int strlen
);

int sf_get_varlist_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int karr[]
);

#endif
