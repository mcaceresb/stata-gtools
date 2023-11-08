// NB: Look, the flow ehre is OK-ish but the organization of the API is
// EXTREMELY messed up. You continuously forger where you put functions,
// and you wrote it!

#include "groupby.h"
#include "groupby/stats.c"
#include "groupby/stats_unweighted.c"
#include "groupby/stats_weights.c"
#include "groupby/transforms.c"
#include "groupby/transforms_unweighted.c"
#include "groupby/transforms_weights.c"
#include "groupby/base.c"
#include "groupby/accelerators.c"
#include "groupby/berge.c"
#include "groupby/alphas.c"

// // basically this is egen bulk
// void GtoolsGroupByMerge (
//     struct GtoolsHash *GtoolsHashInfo,
//     ST_double *statCodes,
//     ST_double *statMaps,
//     ST_double *sources,
//     ST_double *targets)
// {
// }
// 
// // this is normal collapse
// void GtoolsGroupByCollapse (
//     struct GtoolsHash *GtoolsHashInfo,
//     ST_double *statCodes,
//     ST_double *statMaps,
//     ST_double *sources,
//     ST_double *targets)
// {
// }

void GtoolsGroupByTransform (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets)
{
    if ( weights == NULL ) {
        GtoolsGroupByTransformUnweighted(
            GtoolsHashInfo,
            statCodes,
            statMaps,
            sources,
            weights,
            targets,
            ktargets
        );
    }
    else {
        GtoolsGroupByTransformWeighted(
            GtoolsHashInfo,
            statCodes,
            statMaps,
            sources,
            weights,
            targets,
            ktargets
        );
    }
}

void GtoolsGroupByTransformUnweighted (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets)
{
    GT_size j, k, start, end;
    ST_double *srcptr, *trgptr;

    for (j = 0; j < GtoolsHashInfo->nlevels; j++) {
        start  = GtoolsHashInfo->info[j];
        end    = GtoolsHashInfo->info[j + 1];
        trgptr = targets;
        for (k = 0; k < ktargets; k++, trgptr += GtoolsHashInfo->nobs) {
            srcptr = sources + GtoolsHashInfo->nobs * statMaps[k];
            GtoolsTransformIndex(
                srcptr,
                trgptr,
                GtoolsHashInfo->index + start,
                end - start,
                statCodes[k]
            );
        }
    }
}

void GtoolsGroupByTransformWeighted (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets)
{
    GT_size j, k, start, end;
    ST_double *srcptr, *trgptr;

    for (j = 0; j < GtoolsHashInfo->nlevels; j++) {
        start  = GtoolsHashInfo->info[j];
        end    = GtoolsHashInfo->info[j + 1];
        trgptr = targets;
        for (k = 0; k < ktargets; k++, trgptr += GtoolsHashInfo->nobs) {
            srcptr = sources + GtoolsHashInfo->nobs * statMaps[k];
            GtoolsTransformIndexWeighted(
                srcptr,
                weights,
                trgptr,
                GtoolsHashInfo->index + start,
                end - start,
                statCodes[k]
            );
        }
    }
}
