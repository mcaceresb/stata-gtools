#ifndef GTOOLSHASHINGAPI
#define GTOOLSHASHINGAPI

struct GtoolsHash {
    // Pointers to existing objects
    void    *x;
    void    *xptr;
    GT_size offset;
    GT_size nobs;
    GT_size _nobspanel;
    GT_size _nobsinit;
    GT_size kvars;
    GT_int  *types;
    GT_bool *invert;
    // Variables to be computed
    GT_bool bijectOK;
    GT_bool sorted;
    GT_bool allNumeric;
    GT_bool allInteger;
    GT_size rowbytes;
    GT_size max1;
    GT_size nlevels;
    // Aux variables to be allocated
    GT_size *sizes;
    GT_bool allocSizes;
    GT_size *positions;
    GT_bool allocPositions;
    GT_size *index;
    GT_bool allocIndex;
    GT_size *info;
    GT_bool allocInfo;
    // Hash
    uint64_t *h1ptr;
    uint64_t *h2ptr;
    uint64_t *h3ptr;
    uint64_t *hash1;
    uint64_t *hash2;
    uint64_t *hash3;
    GT_bool allocHash1;
    GT_bool allocHash2;
    GT_bool allocHash3;
    // Misc
    ST_double *hdfeBuffer;
    GT_bool   hdfeBufferAlloc;
    GT_bool   hdfeFallback;
    GT_bool   hdfeTraceIter;
    GT_size   hdfeIter;
    GT_size   hdfeFeval;
    GT_size   hdfeMaxIter;
    GT_size   hdfeRc;
};

void GtoolsHashInit (
    struct GtoolsHash *GtoolsHashInfo,
    void *x,
    GT_size nobs,
    GT_size kvars,
    GT_int  *types,
    GT_bool *invert
);

GT_int GtoolsHashSetup          (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsHashSort           (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsHashPanel          (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsHashPanelBijection (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsHashPanel128       (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsHashPanelSorted    (struct GtoolsHash *GtoolsHashInfo);

void GtoolsHashCheckNumeric (struct GtoolsHash *GtoolsHashInfo);
void GtoolsHashCheckInteger (struct GtoolsHash *GtoolsHashInfo);
void GtoolsHashCheckSorted  (struct GtoolsHash *GtoolsHashInfo);
void GtoolsHashFree         (struct GtoolsHash *GtoolsHashInfo);

void GtoolsHashCheckBijection (
    struct GtoolsHash *GtoolsHashInfo,
    GT_int  *maxs,
    GT_int  *mins,
    GT_bool *allMiss,
    GT_bool *anyMiss
);

void GtoolsHashBijection (
    struct GtoolsHash *GtoolsHashInfo,
    GT_int  *maxs,
    GT_int  *mins,
    GT_bool *allMiss,
    GT_bool *anyMiss
);

#endif
