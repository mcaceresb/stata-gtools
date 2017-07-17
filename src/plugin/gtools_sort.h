#ifndef GTOOLS_SORT
#define GTOOLS_SORT

int mf_radix_sort_index (
    uint64_t x[],
    size_t index[], 
    const size_t N,
    const size_t dshift,
    const size_t raw,
    const int verbose
);

int mf_radix_sort_index_pass (
    uint64_t x[],
    size_t index[], 
    const size_t N,
    const size_t exp,
    const size_t shift
);

int mf_counting_sort_index (
    uint64_t x[],
    size_t index[], 
    const size_t N,
    const size_t min,
    const size_t max
);

size_t * mf_panelsetup128 (
    uint64_t h1[],
    uint64_t h2[],
    size_t index[],
    const size_t N,
    size_t * J
);

size_t * mf_panelsetup (
    uint64_t h1[],
    const size_t N,
    size_t * J
);

int mf_check_allequal (uint64_t hash[], size_t start, size_t end);

#endif
