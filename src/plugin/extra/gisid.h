#ifndef GISID
#define GISID

int sf_hash_byvars_isid (struct StataInfo *st_info);

int sf_isid (
    uint64_t h1[],
    struct StataInfo *st_info
);

int sf_isid128 (
    uint64_t h1[],
    uint64_t h2[],
    size_t index[],
    struct StataInfo *st_info
);

int sf_check_isid_collision (
    struct StataInfo *st_info,
    size_t obs1,
    size_t obs2
);

#endif
