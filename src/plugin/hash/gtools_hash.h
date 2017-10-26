#ifndef GTOOLS_HASH
#define GTOOLS_HASH

#define RADIX_SHIFT 24

int mf_biject_varlist (uint64_t *h1, struct StataInfo *st_info);

int mf_panelsetup (
    uint64_t *h1,
    uint64_t *h2,
    struct StataInfo *st_info,
    const size_t hash_level
);

int mf_check_allequal (uint64_t *hash, size_t start, size_t end);
int mf_panelsetup_bijection (uint64_t *h1, struct StataInfo *st_info);

#endif
