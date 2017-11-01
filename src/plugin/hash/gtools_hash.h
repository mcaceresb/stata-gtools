#ifndef GTOOLS_HASH
#define GTOOLS_HASH

#define RADIX_SHIFT 24

int gf_hash (
    uint64_t *h1,
    uint64_t *h2,
    struct StataInfo *st_info,
    GT_size *ix,
    clock_t stimer
);

int gf_biject_varlist (uint64_t *h1, struct StataInfo *st_info);

int gf_panelsetup (
    uint64_t *h1,
    uint64_t *h2,
    struct StataInfo *st_info,
    GT_size *ix,
    const GT_bool hash_level
);

int gf_check_allequal (uint64_t *hash, GT_size start, GT_size end);
int gf_panelsetup_bijection (uint64_t *h1, struct StataInfo *st_info);

#endif
