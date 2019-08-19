#ifndef GTOOLSGROUPBYAPI
#define GTOOLSGROUPBYAPI

void GtoolsGroupByTransform (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *targets,
    GT_size   ktargets
);

void GtoolsGroupByTransformWeights (
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

void GtoolsTransformWeights (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

void GtoolsTransformDeMeanWeights (
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

ST_double GtoolsStatsWeights (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

ST_double GtoolsStatsMeanWeights (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N
);

ST_double GtoolsStatsQuantileWeights (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N
);

/*********************************************************************
 *                               Misc                                *
 *********************************************************************/

void GtoolsGroupByHDFE (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

void GtoolsGroupByHDFEWeights (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

#endif
