#ifndef GTOOLSGROUPBYAPI
#define GTOOLSGROUPBYAPI

typedef void (*GtoolsGroupByTransform)(
    struct GtoolsHash *,
    ST_double *,
    GT_size   *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size
);

void GtoolsGroupByTransformUnweighted (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets
);

void GtoolsGroupByTransformWeighted (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets
);

/*********************************************************************
 *                             Transform                             *
 *********************************************************************/

void GtoolsTransform (
    ST_double *source,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

void GtoolsTransformDeMean (
    ST_double *source,
    ST_double *target,
    GT_size   *index,
    GT_size   N
);

void GtoolsTransformWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

void GtoolsTransformDeMeanWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N
);

/*********************************************************************
 *                               Stats                               *
 *********************************************************************/

ST_double GtoolsStats (
    ST_double *source,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

ST_double GtoolsStatsMean (
    ST_double *source,
    GT_size   *index,
    GT_size   N
);

ST_double GtoolsStatsQuantile (
    ST_double *source,
    GT_size   *index,
    GT_size   N
);

ST_double GtoolsStatsWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

ST_double GtoolsStatsMeanWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N
);

ST_double GtoolsStatsQuantileWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N
);

/*********************************************************************
 *                               Misc                                *
 *********************************************************************/

typedef void (*GtoolsGroupByHDFE)(
    struct GtoolsHash *,
    GT_size,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size,
    ST_double
);

void GtoolsGroupByHDFEUnweighted (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

void GtoolsGroupByHDFEWeighted (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

#endif
