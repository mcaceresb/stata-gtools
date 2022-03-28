#include "hashing.h"
#include "hashing/utils.c"
#include "hashing/bijection.c"
#include "hashing/panelsetup.c"
#include "hashing/radix.c"

void GtoolsHashAbsorbByLoop (struct GtoolsHash *GtoolsHashInfo, GT_size K)
{
    GT_size k;
    struct GtoolsHash *ghptr = GtoolsHashInfo;
    for (k = 0; k < K; k++, ghptr++) {
        GtoolsHashFreePartial(ghptr);
        ghptr->offset += ghptr->nobs;
    }
}

GT_int GtoolsHashPanelAbsorb (struct GtoolsHash *GtoolsHashInfo, GT_size K, GT_size N)
{
    GT_size k;
    struct GtoolsHash *ghptr;
    GT_int rcpanel[K], rcmap[K], rc = 0;
    #if GTOOLSOMP
    #pragma omp parallel for \
        private(             \
            ghptr,           \
        )                    \
        shared(              \
            N,               \
            rcpanel,         \
            rcmap,           \
            GtoolsHashInfo   \
        )
    #endif
    for (k = 0; k < K; k++) {
        ghptr       = GtoolsHashInfo + k;
        ghptr->nobs = N;
        rcpanel[k]  = GtoolsHashPanel(ghptr);
        rcmap[k]    = rcpanel[k]? rcpanel[k]: GtoolsMapIndex(ghptr);
    }

    for (k = 0; k < K; k++) {
        rc = rcpanel[k];
        if (rc == 17902) return(sf_oom_error("GtoolsAPI", "GtoolsHashPanelAbsorb")); else if (rc) goto exit;
        rc = rcmap[k];
        if (rc == 17902) return(sf_oom_error("GtoolsAPI", "GtoolsMapIndexAbsorb")); else if (rc) goto exit;
    }

exit:
    return(rc);
}

GT_int GtoolsHashSetupAbsorb (
    void *FE,
    struct GtoolsHash *GtoolsHashInfo,
    GT_size N,
    GT_size K,
    GT_int  *types,
    GT_size *offsets)
{
    GT_int rc = 0;
    GT_size offset = 0, k;
    GT_bool inverse[K];
    struct GtoolsHash *ghptr = GtoolsHashInfo;
    for (k = 0; k < K; k++, ghptr++) {
        inverse[k] = 0;
        GtoolsHashInit(ghptr, FE + offset, N, 1, types + k, inverse + k);
        rc = GtoolsHashSetup(ghptr);
        if (rc == 17902) return(sf_oom_error("GtoolsAPI", "GtoolsHashSetupAbsorb")); else if (rc) goto exit;
        offset += N * offsets[k];
    }

exit:
    return(rc);
}

GT_int GtoolsHashSetup (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i;
    void *xptr;

    GT_bool *allMiss = calloc(GtoolsHashInfo->kvars, sizeof *allMiss);
    GT_bool *anyMiss = calloc(GtoolsHashInfo->kvars, sizeof *anyMiss);
    GT_int  *maxs    = calloc(GtoolsHashInfo->kvars, sizeof *maxs);
    GT_int  *mins    = calloc(GtoolsHashInfo->kvars, sizeof *mins);

    // if ( GtoolsHashInfo->allMiss == NULL ) return (17902);
    // if ( GtoolsHashInfo->anyMiss == NULL ) return (17902);
    // if ( GtoolsHashInfo->maxs    == NULL ) return (17902);
    // if ( GtoolsHashInfo->mins    == NULL ) return (17902);

    GtoolsHashInfo->positions = calloc(GtoolsHashInfo->kvars + 1, sizeof GtoolsHashInfo->positions);
    // if ( GtoolsHashInfo->positions  == NULL ) return (17902);
    GtoolsHashInfo->allocPositions = 1;

    GtoolsHashCheckNumeric(GtoolsHashInfo);
    GtoolsHashCheckSorted(GtoolsHashInfo);

    if ( !GtoolsHashInfo->sorted ) {
        GtoolsHashCheckInteger(GtoolsHashInfo);
        GtoolsHashCheckBijection(
            GtoolsHashInfo,
            maxs,
            mins,
            allMiss,
            anyMiss
        );

        if ( GtoolsHashInfo->bijectOK ) {

            GtoolsHashInfo->hash1 = calloc(GtoolsHashInfo->nobs, sizeof GtoolsHashInfo->hash1);
            if ( GtoolsHashInfo->hash1 == NULL ) return (17902);
            GtoolsHashInfo->allocHash1 = 1;

            GtoolsHashBijection (
                GtoolsHashInfo,
                maxs,
                mins,
                allMiss,
                anyMiss
            );
        }
        else if ( GtoolsHashInfo->kvars > 1 || GtoolsHashInfo->rowbytes > 16 ) {
            GtoolsHashInfo->hash1 = calloc(GtoolsHashInfo->nobs, sizeof GtoolsHashInfo->hash1);
            GtoolsHashInfo->hash2 = calloc(GtoolsHashInfo->nobs, sizeof GtoolsHashInfo->hash2);

            if ( GtoolsHashInfo->hash1 == NULL ) return (17902);
            if ( GtoolsHashInfo->hash2 == NULL ) return (17902);

            GtoolsHashInfo->allocHash1 = 1;
            GtoolsHashInfo->allocHash2 = 1;

            xptr = GtoolsHashInfo->x;
            for (i = 0; i < GtoolsHashInfo->nobs; i++, xptr += GtoolsHashInfo->rowbytes) {
                spookyhash_128(
                    xptr,
                    GtoolsHashInfo->rowbytes,
                    GtoolsHashInfo->hash1 + i,
                    GtoolsHashInfo->hash2 + i
                );
            }
        }
        else {
            GtoolsHashInfo->radixOK = 1;
        }
    }

    free(allMiss);
    free(anyMiss);
    free(maxs);
    free(mins);

    return (0);
}

GT_int GtoolsHashPanel (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i;
    uint64_t *hptr;

    GtoolsHashInfo->_nobspanel = GtoolsHashInfo->nobs;
    GtoolsHashInfo->h1ptr = GtoolsHashInfo->hash1 + GtoolsHashInfo->offset;
    GtoolsHashInfo->h2ptr = GtoolsHashInfo->hash2 + GtoolsHashInfo->offset;
    GtoolsHashInfo->xptr  = GtoolsHashInfo->x + GtoolsHashInfo->offset * GtoolsHashInfo->rowbytes;

    GtoolsHashInfo->index = calloc(GtoolsHashInfo->nobs, sizeof GtoolsHashInfo->index);
    if ( GtoolsHashInfo->index == NULL ) return (17902);
    GtoolsHashInfo->allocIndex = 1;

    if ( GtoolsHashInfo->sorted ) {
        for (i = 0; i < GtoolsHashInfo->nobs; i++) {
            GtoolsHashInfo->index[i] = i;
        }

        if ( GtoolsHashPanelSorted(GtoolsHashInfo) )
            return (17902);
    }
    else if ( GtoolsHashInfo->radixOK ) {
        for (i = 0; i < GtoolsHashInfo->nobs; i++, hptr++) {
            GtoolsHashInfo->index[i] = i;
        }

        if ( GtoolsRadixSort(GtoolsHashInfo) )
            return (17902);

        if ( GtoolsRadixPanel(GtoolsHashInfo) )
            return (17902);
    }
    else {
        hptr = GtoolsHashInfo->h1ptr;
        GtoolsHashInfo->max1 = *hptr;
        for (i = 0; i < GtoolsHashInfo->nobs; i++, hptr++) {
            GtoolsHashInfo->index[i] = i;
            if ( GtoolsHashInfo->max1 < *hptr )
                GtoolsHashInfo->max1 = *hptr;
        }

        if ( GtoolsHashSort(GtoolsHashInfo) )
            return (17902);

        if ( GtoolsHashInfo->bijectOK ) {
            if ( GtoolsHashPanelBijection(GtoolsHashInfo) )
                return (17902);

        }
        else {
            GtoolsHashInfo->hash3 = calloc(GtoolsHashInfo->nobs, sizeof GtoolsHashInfo->hash3);
            if ( GtoolsHashInfo->hash3 == NULL ) return (17902);
            GtoolsHashInfo->allocHash3 = 1;

            for (i = 0; i < GtoolsHashInfo->nobs; i++) {
                GtoolsHashInfo->hash3[i] = GtoolsHashInfo->h2ptr[GtoolsHashInfo->index[i]];
            }
            GtoolsHashInfo->h2ptr = GtoolsHashInfo->hash3;

            if ( GtoolsHashPanel128(GtoolsHashInfo) )
                return (17902);

            if ( GtoolsHashCheckCollisions(GtoolsHashInfo) )
                return (17999);
        }
    }

    return (0);
}

GT_int GtoolsMapIndex (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i, j, start, nj, *ixptr;

    GtoolsHashInfo->indexj = calloc(GtoolsHashInfo->nobs,    sizeof GtoolsHashInfo->indexj);
    GtoolsHashInfo->nj     = calloc(GtoolsHashInfo->nlevels, sizeof GtoolsHashInfo->nj);

    if ( GtoolsHashInfo->indexj == NULL ) return (17902);
    if ( GtoolsHashInfo->nj     == NULL ) return (17902);

    GtoolsHashInfo->allocIndexj = 1;
    GtoolsHashInfo->allocNj     = 1;

    for (j = 0; j < GtoolsHashInfo->nlevels; j++) {
        start  = GtoolsHashInfo->info[j];
        nj     = GtoolsHashInfo->info[j + 1] - start;
        ixptr  = GtoolsHashInfo->index + start;
        for (i = 0; i < nj; i++) {
            GtoolsHashInfo->indexj[ixptr[i]] = j;
        }

        GtoolsHashInfo->nj[j] = nj;
    }

    return (0);
}
